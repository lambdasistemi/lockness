#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/verdict-mutations.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/Lockness/Counterexamples" "$scratch/Lockness/Sim"
cp -R .lake/build/lib/lean/Lockness/. "$scratch/Lockness/"
export LEAN_PATH="$scratch:$PWD/.lake/build/lib/lean${LEAN_PATH:+:$LEAN_PATH}"
stage() {
  printf 'STAGE command='; printf '%q ' "$@"; printf '\n'
  local result=0
  "$@" || result=$?
  printf 'STAGE exit=%s\n' "$result"
  return "$result"
}
# Replace each exact production fragment once and prove the edit applied.
mutate() {
  local file=$1 before=$2 after=$3 source
  [[ $(grep -oF -- "$before" "$scratch/$file" | wc -l) = 1 ]] || {
    echo "mutation location not unique: $before" >&2; exit 1;
  }
  [[ $(grep -oF -- "$after" "$scratch/$file" | wc -l) = 0 ]] || {
    echo "mutation result already present: $after" >&2; exit 1;
  }
  source=$(cat "$scratch/$file")
  printf '%s\n' "${source/"$before"/"$after"}" > "$scratch/$file.next"
  mv "$scratch/$file.next" "$scratch/$file"
  [[ $(grep -oF -- "$after" "$scratch/$file" | wc -l) = 1 ]] || { echo "mutation did not apply: $after" >&2; exit 1; }
}
# Recompile the mutated module and every dependent on the witness and scenario path.
rebuild() {
  local mutated=$1; shift
  stage lean -o "$scratch/Lockness/$mutated.olean" "$scratch/$mutated.lean"
  for module in "$@"; do
    stage lean -o "$scratch/Lockness/$module.olean" "Lockness/$module.lean"
  done
}
reset() {
  rm -f "$scratch"/*.lean
  cp -R .lake/build/lib/lean/Lockness/. "$scratch/Lockness/"
}
expect_failure() {
  local log=$1 diagnostic=$2; shift 2
  if stage "$@" > "$log" 2>&1; then
    cat "$log"; echo "unchanged check survived the mutant: $*" >&2; exit 1
  fi
  cat "$log"
  grep -qF -- "$diagnostic" "$log" || { echo "failure was not the expected diagnostic: $diagnostic" >&2; exit 1; }
}
# The unchanged proof file must fail inside the named theorem, not at an import or elsewhere.
expect_rejected() {
  local log=$1 file=$2 theorem=$3 diagnostic=$4 start end= found=0 number rest line
  start=$(grep -nE "^theorem $theorem( |$)" "$file" | cut -d: -f1)
  [[ $(grep -cE "^theorem $theorem( |$)" "$file") = 1 ]] || { echo "theorem not unique: $theorem" >&2; exit 1; }
  # The extent ends just before the next top-level declaration; only bash and grep are used,
  # because the model environment provides no other text tools.
  while IFS=: read -r number rest; do
    if (( number > start )); then end=$((number - 1)); break; fi
  done < <(grep -nE '^(theorem|def|private|lemma|example|end) ' "$file")
  [[ -n $end ]] || { echo "theorem extent not found: $theorem" >&2; exit 1; }
  expect_failure "$log" "$diagnostic" lean "$file"
  if grep -qE 'object file|unknown module|bad import|failed to read' "$log"; then
    echo "proof check failed for setup instead of semantics: $theorem" >&2; exit 1
  fi
  while IFS= read -r line; do
    if [[ $line =~ ^"$file":([0-9]+):[0-9]+:\ error ]] &&
        (( BASH_REMATCH[1] >= start && BASH_REMATCH[1] <= end )); then
      found=1; break
    fi
  done < "$log"
  (( found )) || { echo "no error inside $theorem (lines $start-$end of $file)" >&2; exit 1; }
  echo "PROOF-REJECTED theorem=$theorem lines=$start-$end"
}

# Mutant 1: an absent witness passes the ledger witness gate (Option.all is true on none).
cp Lockness/Ledger.lean "$scratch/Ledger.lean"
mutate Ledger.lean 'answer.witness.any' 'answer.witness.all'
sha256sum Lockness/Ledger.lean "$scratch/Ledger.lean"
rebuild Ledger Counterexamples/LedgerFixtures Accept Counterexamples/AppFixtures Verdict \
  Counterexamples/VerdictFixtures Counterexamples/VerdictPromotion
cat > "$scratch/PromotionWitness.lean" <<'LEAN'
import Lockness.Counterexamples.VerdictPromotion
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples
example : verdict policy publications selected promotingProvider builder =
    .verified substitutedClaim := by decide
example : promotingProvider selected = some promotedSession ∧
    promotedSession.ledger.witness = none := by decide
example : ¬ NoPromotion verdict := promoted_refutes_no_promotion verdict (by decide)
example : ¬ VerdictSoundness verdict := promoted_refutes_soundness verdict (by decide)
#print axioms promoted_refutes_no_promotion
#print axioms promoted_refutes_soundness
#eval verdict policy publications selected promotingProvider builder
LEAN
sha256sum "$scratch/PromotionWitness.lean"
stage lean "$scratch/PromotionWitness.lean"
echo 'VERDICT-MUTATION absent-witness compiled-production verifies witness-less impostor; unchanged NoPromotion and VerdictSoundness constructively false'
# The proof chain of verdict_no_promotion starts at the ledger inversion; it is rejected there.
expect_rejected "$scratch/absent-witness-proof.log" Lockness/LedgerProofs.lean \
  verifyLedger_observations 'Missing cases:'
echo 'VERDICT-MUTATION absent-witness unchanged no-promotion proof chain rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Verdict.olean" Lockness/Sim/Verdict.lean
expect_failure "$scratch/absent-witness-simulator.log" 'unexpected verdict outcome:' \
  lean --run Main.lean verdict promoted
echo 'VERDICT-SCENARIO-CONTROL absent-witness promoted: production mutant causes outcome failure'

# Mutant 2: verdict ignores the declared verifier.
reset
cp Lockness/Verdict.lean "$scratch/Verdict.lean"
mutate Verdict.lean 'if policy.verifier then' 'if true then'
sha256sum Lockness/Verdict.lean "$scratch/Verdict.lean"
rebuild Verdict Counterexamples/VerdictFixtures Counterexamples/VerdictPromotion
cat > "$scratch/VerifierWitness.lean" <<'LEAN'
import Lockness.Counterexamples.VerdictPromotion
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples
example : verdict noVerifierPolicy publications selected verifiedProvider builder =
    .verified oneLinkClaim := by decide
example : noVerifierPolicy.verifier = false := by decide
example : ¬ NoPromotion verdict := verifier_refutes_no_promotion verdict (by decide)
#print axioms verifier_refutes_no_promotion
#eval verdict noVerifierPolicy publications selected verifiedProvider builder
LEAN
sha256sum "$scratch/VerifierWitness.lean"
stage lean "$scratch/VerifierWitness.lean"
echo 'VERDICT-MUTATION verifier-ignored compiled-production verifies without a verifier; unchanged NoPromotion constructively false'
# The proof chain of verdict_no_promotion classifies through verdict_verified_iff; it is rejected there.
expect_rejected "$scratch/verifier-proof.log" Lockness/VerdictProofs.lean verdict_verified_iff 'error'
echo 'VERDICT-MUTATION verifier-ignored unchanged no-promotion proof chain rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Verdict.olean" Lockness/Sim/Verdict.lean
expect_failure "$scratch/verifier-simulator.log" 'unexpected verdict outcome:' \
  lean --run Main.lean verdict no-verifier
echo 'VERDICT-SCENARIO-CONTROL verifier-ignored no-verifier: production mutant causes outcome failure'

# Mutant 3: unverifiedReason ignores the offered witness, so a wrong witness reads as absent.
reset
cp Lockness/Verdict.lean "$scratch/Verdict.lean"
mutate Verdict.lean 'if session.ledger.witness = none then' 'if True then'
sha256sum Lockness/Verdict.lean "$scratch/Verdict.lean"
rebuild Verdict Counterexamples/VerdictFixtures Counterexamples/VerdictPromotion
cat > "$scratch/WrongWitness.lean" <<'LEAN'
import Lockness.Counterexamples.VerdictPromotion
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples
example : verdict policy publications selected wrongWitnessProvider builder =
    .unverified .noWitness := by decide
#eval verdict policy publications selected wrongWitnessProvider builder
LEAN
sha256sum "$scratch/WrongWitness.lean"
stage lean "$scratch/WrongWitness.lean"
echo 'VERDICT-MUTATION wrong-witness-reclassified compiled-production reports a present wrong witness as unverified'
expect_rejected "$scratch/wrong-witness-proof.log" Lockness/VerdictProofs.lean \
  witnessed_never_unverified 'error'
echo 'VERDICT-MUTATION wrong-witness-reclassified unchanged witnessed_never_unverified proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Verdict.olean" Lockness/Sim/Verdict.lean
expect_failure "$scratch/wrong-witness-simulator.log" 'unexpected verdict outcome:' \
  lean --run Main.lean verdict wrong-witness
echo 'VERDICT-SCENARIO-CONTROL wrong-witness-reclassified wrong-witness: production mutant causes outcome failure'

# Mutant 4: unverifiedReason reads any binding other than the selected point as unbound.
reset
cp Lockness/Verdict.lean "$scratch/Verdict.lean"
mutate Verdict.lean 'if session.binding = .unbound then' 'if session.binding ≠ .bound selectedPoint then'
sha256sum Lockness/Verdict.lean "$scratch/Verdict.lean"
rebuild Verdict Counterexamples/VerdictFixtures Counterexamples/VerdictPromotion
cat > "$scratch/Misbound.lean" <<'LEAN'
import Lockness.Counterexamples.VerdictPromotion
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples
example : verdict policy publications selected misboundProvider builder =
    .unverified .unboundSession := by decide
#eval verdict policy publications selected misboundProvider builder
LEAN
sha256sum "$scratch/Misbound.lean"
stage lean "$scratch/Misbound.lean"
echo 'VERDICT-MUTATION misbound-as-unbound compiled-production downgrades a misbound session to unverified'
expect_rejected "$scratch/misbound-proof.log" Lockness/VerdictProofs.lean misbound_refused 'error'
expect_rejected "$scratch/misbound-never-proof.log" Lockness/VerdictProofs.lean \
  misbound_never_unverified 'error'
echo 'VERDICT-MUTATION misbound-as-unbound unchanged misbound_refused and misbound_never_unverified proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Verdict.olean" Lockness/Sim/Verdict.lean
expect_failure "$scratch/misbound-simulator.log" 'unexpected verdict outcome:' \
  lean --run Main.lean verdict misbound
echo 'VERDICT-SCENARIO-CONTROL misbound-as-unbound misbound: production mutant causes outcome failure'
echo 'VERDICT-MUTATIONS mutants=4 witnesses=4 proof-rejections=5 scenario-controls=4'
