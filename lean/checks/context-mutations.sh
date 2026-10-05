#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/context-mutations.XXXXXX")
trap 'rm -rf "${scratch:?}"' EXIT
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
# A fragment with no occurrence counts zero; grep's no-match status must not stop the script.
count() { { grep -oF -- "$1" || true; } | wc -l; }
# Replace each exact production fragment once and prove the edit applied. The replacement may
# already occur elsewhere (false) or inside the fragment itself (the shortened premise list), so
# its expected count after the edit is computed rather than required to be zero beforehand.
mutate() {
  local file=$1 before=$2 after=$3 source expected
  [[ $(count "$before" < "$scratch/$file") = 1 ]] || {
    echo "mutation location not unique: $before" >&2; exit 1;
  }
  expected=$(( $(count "$after" < "$scratch/$file") - $(count "$after" <<< "$before") + 1 ))
  source=$(cat "$scratch/$file")
  printf '%s\n' "${source/"$before"/"$after"}" > "$scratch/$file.next"
  mv "$scratch/$file.next" "$scratch/$file"
  [[ $(count "$before" < "$scratch/$file") = 0 ]] || { echo "mutation did not apply: $before" >&2; exit 1; }
  [[ $(count "$after" < "$scratch/$file") = "$expected" ]] || {
    echo "mutation did not apply: $after" >&2; exit 1;
  }
  ! cmp -s "Lockness/$file" "$scratch/$file" || { echo "mutation left the source unchanged: $file" >&2; exit 1; }
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
  rm -f "${scratch:?}"/*.lean
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
setup_failure() {
  grep -qE 'object file|unknown module|bad import|failed to read|unknown package' "$1"
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
  if setup_failure "$log"; then
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
guard_dependents=(Accept Counterexamples/AppFixtures Verdict Counterexamples/VerdictFixtures
  ContextStatements Counterexamples/ContextFixtures Counterexamples/ContextRefutation)
verdict_dependents=(Counterexamples/VerdictFixtures ContextStatements Counterexamples/ContextFixtures
  Counterexamples/ContextRefutation)
opens='open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples Lockness.Counterexamples.ContextExamples'

# Mutant 1: the network guard is removed; a terminal configured for network [1] trusts network [0].
cp Lockness/Context.lean "$scratch/Context.lean"
mutate Context.lean 'decide (selectedPoint.network ≠ policy.context.network)' 'false'
sha256sum Lockness/Context.lean "$scratch/Context.lean"
rebuild Context "${guard_dependents[@]}"
cat > "$scratch/NetworkWitness.lean" <<LEAN
import Lockness.Counterexamples.ContextRefutation
$opens
example : verdict wrongNetworkPolicy publications selected verifiedProvider builder =
    .verified oneLinkClaim := by decide
example : selected.network ≠ wrongNetworkPolicy.context.network := by decide
example : ¬ @ContextSoundness honestSignatures fixtureMessages verdict :=
  guard_removed_refutes_context_soundness verdict (by decide)
#print axioms guard_removed_refutes_context_soundness
#eval verdict wrongNetworkPolicy publications selected verifiedProvider builder
LEAN
sha256sum "$scratch/NetworkWitness.lean"
stage lean "$scratch/NetworkWitness.lean"
echo 'CONTEXT-MUTATION network-guard-removed compiled-production verifies a root endorsed on another network; unchanged ContextSoundness constructively false'
expect_rejected "$scratch/network-sound-proof.log" Lockness/ContextProofs.lean verdict_context_sound 'error'
expect_rejected "$scratch/network-refused-proof.log" Lockness/ContextProofs.lean wrong_network_refused 'error'
echo 'CONTEXT-MUTATION network-guard-removed unchanged verdict_context_sound and wrong_network_refused proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Context.olean" Lockness/Sim/Context.lean
expect_failure "$scratch/network-simulator.log" 'unexpected context outcome:' \
  lean --run Main.lean context wrong-network-point
echo 'CONTEXT-SCENARIO-CONTROL network-guard-removed wrong-network-point: production mutant causes outcome failure'

# Mutant 2: context soundness without the MessageBinding premise, a statement mutant.
reset
cat > "$scratch/BindingWitness.lean" <<LEAN
import Lockness.Counterexamples.ContextRefutation
$opens
-- Typechecks only when ContextSoundness has no MessageBinding premise.
example : ¬ @ContextSoundness signatureOnly fixtureMessages verdict :=
  fun sound => unbound_message_refutes sound
example : verdict signatureOnlyPolicy unboundMessagePublications selected verifiedProvider builder =
    .verified oneLinkClaim := by decide
#print axioms unbound_message_refutes
LEAN
sha256sum "$scratch/BindingWitness.lean"
# Control: against the unchanged statement the witness must not typecheck.
expect_failure "$scratch/binding-witness-control.log" 'type mismatch' lean "$scratch/BindingWitness.lean"
if setup_failure "$scratch/binding-witness-control.log"; then
  echo 'binding witness control failed for setup instead of the premise' >&2; exit 1
fi
echo 'CONTEXT-WITNESS-CONTROL binding-dropped witness rejected by the unchanged ContextSoundness'
cp Lockness/ContextStatements.lean "$scratch/ContextStatements.lean"
mutate ContextStatements.lean 'ObservationSound policy → MessageBinding →' 'ObservationSound policy →'
sha256sum Lockness/ContextStatements.lean "$scratch/ContextStatements.lean"
rebuild ContextStatements Counterexamples/ContextFixtures Counterexamples/ContextRefutation
stage lean "$scratch/BindingWitness.lean"
echo 'CONTEXT-MUTATION binding-dropped valid signatures over messages naming another network endorse this network; mutated ContextSoundness constructively false'
expect_rejected "$scratch/binding-sound-proof.log" Lockness/ContextProofs.lean verdict_context_sound 'error'
echo 'CONTEXT-MUTATION binding-dropped unchanged verdict_context_sound proof rejected after witness'
echo 'CONTEXT-SCENARIO-CONTROL binding-dropped none: statement mutant, no executable changes'

# Mutant 3: the scheme guard is removed; a root under an unaccepted scheme is verified.
reset
cp Lockness/Context.lean "$scratch/Context.lean"
mutate Context.lean 'decide (root.scheme ∉ policy.context.schemes)' 'false'
sha256sum Lockness/Context.lean "$scratch/Context.lean"
rebuild Context "${guard_dependents[@]}"
cat > "$scratch/SchemeWitness.lean" <<LEAN
import Lockness.Counterexamples.ContextRefutation
$opens
example : verdict unacceptedSchemePolicy publications selected verifiedProvider builder =
    .verified oneLinkClaim := by decide
example : oneLinkClaim.ledgerRoot.scheme ∉ unacceptedSchemePolicy.context.schemes := by decide
example : ¬ @ContextSoundness honestSignatures fixtureMessages verdict :=
  scheme_unchecked_refutes_context_soundness verdict (by decide)
#print axioms scheme_unchecked_refutes_context_soundness
#eval verdict unacceptedSchemePolicy publications selected verifiedProvider builder
LEAN
sha256sum "$scratch/SchemeWitness.lean"
stage lean "$scratch/SchemeWitness.lean"
echo 'CONTEXT-MUTATION scheme-guard-removed compiled-production verifies a root under an unaccepted scheme; unchanged ContextSoundness constructively false'
expect_rejected "$scratch/scheme-sound-proof.log" Lockness/ContextProofs.lean verdict_context_sound 'error'
expect_rejected "$scratch/scheme-refused-proof.log" Lockness/ContextProofs.lean unaccepted_scheme_refused 'error'
echo 'CONTEXT-MUTATION scheme-guard-removed unchanged verdict_context_sound and unaccepted_scheme_refused proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Context.olean" Lockness/Sim/Context.lean
expect_failure "$scratch/scheme-simulator.log" 'unexpected context outcome:' \
  lean --run Main.lean context unaccepted-scheme
echo 'CONTEXT-SCENARIO-CONTROL scheme-guard-removed unaccepted-scheme: production mutant causes outcome failure'

# Mutant 4: verdict no longer classifies an out-of-context refusal before declared absences.
reset
cp Lockness/Verdict.lean "$scratch/Verdict.lean"
mutate Verdict.lean 'if outOfContext policy publications selectedPoint then .refused refusal' \
  'if false then .refused refusal'
sha256sum Lockness/Verdict.lean "$scratch/Verdict.lean"
rebuild Verdict "${verdict_dependents[@]}"
cat > "$scratch/BranchWitness.lean" <<LEAN
import Lockness.Counterexamples.ContextRefutation
$opens
example : verdict wrongNetworkPolicy publications selected unboundProvider builder =
    .unverified .unboundSession := by decide
example : outOfContext wrongNetworkPolicy publications selected = true := by decide
#eval verdict wrongNetworkPolicy publications selected unboundProvider builder
LEAN
sha256sum "$scratch/BranchWitness.lean"
stage lean "$scratch/BranchWitness.lean"
echo 'CONTEXT-MUTATION context-branch-removed compiled-production downgrades an out-of-context selection to unverified'
expect_rejected "$scratch/branch-proof.log" Lockness/ContextProofs.lean \
  out_of_context_never_unverified 'error'
echo 'CONTEXT-MUTATION context-branch-removed unchanged out_of_context_never_unverified proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Context.olean" Lockness/Sim/Context.lean
expect_failure "$scratch/branch-simulator.log" 'unexpected context outcome:' \
  lean --run Main.lean context wrong-network-point
echo 'CONTEXT-SCENARIO-CONTROL context-branch-removed wrong-network-point: production mutant causes outcome failure'
echo 'CONTEXT-MUTATIONS mutants=4 witnesses=4 witness-controls=1 proof-rejections=6 scenario-controls=3'
