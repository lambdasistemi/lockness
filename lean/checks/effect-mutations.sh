#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/effect-mutations.XXXXXX")
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
# already occur elsewhere or inside the fragment itself (the shortened premise list), so its
# expected count after the edit is computed rather than required to be zero beforehand.
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
  # The extent ends just before the next top-level declaration.
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
dependents=(Counterexamples/ActFixtures Counterexamples/SettlementRollback)
opens='open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.VerdictExamples Lockness.Counterexamples.ContextExamples
open Lockness.Counterexamples.ActExamples'
witness_marker='-- The jointly inhabited witness'

# Mutant 1: the settlement guard always passes; an effect is authorized at an unsettled point.
cp Lockness/Act.lean "$scratch/Act.lean"
mutate Act.lean 'if policy.settlement selectedPoint chain then' 'if true then'
sha256sum Lockness/Act.lean "$scratch/Act.lean"
rebuild Act
# The jointly inhabited witness asserts the unmet condition this mutant removes, so the unchanged
# fixture module is rejected inside it; the fixture definitions before it are then rebuilt alone.
expect_rejected "$scratch/settlement-fixture.log" Lockness/Counterexamples/ActFixtures.lean \
  settled_effect_inhabited 'error'
[[ $(grep -cFx -- "$witness_marker" Lockness/Counterexamples/ActFixtures.lean) = 1 ]] || {
  echo "fixture witness marker not unique" >&2; exit 1;
}
fixtures=$(cat Lockness/Counterexamples/ActFixtures.lean)
printf '%s\n\nend Lockness.Counterexamples.ActExamples\n' "${fixtures%%"$witness_marker"*}" \
  > "$scratch/ActFixtures.lean"
! grep -qF 'settled_effect_inhabited' "$scratch/ActFixtures.lean" || {
  echo "fixture definitions still carry the witness" >&2; exit 1;
}
sha256sum Lockness/Counterexamples/ActFixtures.lean "$scratch/ActFixtures.lean"
stage lean -o "$scratch/Lockness/Counterexamples/ActFixtures.olean" "$scratch/ActFixtures.lean"
stage lean -o "$scratch/Lockness/Counterexamples/SettlementRollback.olean" \
  Lockness/Counterexamples/SettlementRollback.lean
cat > "$scratch/SettlementWitness.lean" <<LEAN
import Lockness.Counterexamples.SettlementRollback
$opens
example : act settledPolicy .effect (.verified oneLinkClaim) verifiedProvider selected tipChain =
    .ok ⟨.effect, selected, .claim oneLinkClaim⟩ := by decide
example : act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
    verifiedProvider selected tipChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩ := by decide
example : ¬ @SettlementStability fixtureConsensus act := settlement_dropped_refutes act (by decide)
example : Extends tipChain rolledChain := rolled_extends
example : @ConsensusModel.admits fixtureConsensus tipChain rolledChain := rolled_admitted
example : canonical selected tipChain ∧ ¬ canonical selected rolledChain := by decide
#print axioms settlement_dropped_refutes
#eval act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
  verifiedProvider selected tipChain
LEAN
sha256sum "$scratch/SettlementWitness.lean"
stage lean "$scratch/SettlementWitness.lean"
echo 'EFFECT-MUTATION settlement-dropped compiled-production authorizes an effect at the unsettled tip; an admitted rollback leaves the point non-canonical; unchanged SettlementStability constructively false'
expect_rejected "$scratch/settlement-proof.log" Lockness/ActProofs.lean act_settlement 'error'
expect_rejected "$scratch/settlement-requires-proof.log" Lockness/ActProofs.lean act_effect_requires 'error'
echo 'EFFECT-MUTATION settlement-dropped unchanged act_settlement and act_effect_requires proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Effect.olean" Lockness/Sim/Effect.lean
expect_failure "$scratch/settlement-simulator.log" 'unexpected effect outcome:' \
  lean --run Main.lean effect rolled-back
echo 'EFFECT-SCENARIO-CONTROL settlement-dropped rolled-back: production mutant causes outcome failure'

# Mutant 2: an unverified effect is authorized on the offer, as construction is.
reset
cp Lockness/Act.lean "$scratch/Act.lean"
mutate Act.lean '| .effect => .error (.evidenceFailure selectedPoint)' \
  '| .effect => (match acquire selectedPoint provider with | .error refusal => .error refusal | .ok session => .ok ⟨.effect, selectedPoint, .offer reason session⟩)'
sha256sum Lockness/Act.lean "$scratch/Act.lean"
rebuild Act "${dependents[@]}"
cat > "$scratch/UnverifiedWitness.lean" <<LEAN
import Lockness.Counterexamples.SettlementRollback
$opens
example : verdict settledPolicy publications selected noWitnessProvider builder =
    .unverified .noWitness := by decide
example : act settledPolicy .effect (verdict settledPolicy publications selected noWitnessProvider builder)
    noWitnessProvider selected settledChain =
      .ok ⟨.effect, selected, .offer .noWitness noWitnessSession⟩ := by decide
#eval act settledPolicy .effect (verdict settledPolicy publications selected noWitnessProvider builder)
  noWitnessProvider selected settledChain
LEAN
sha256sum "$scratch/UnverifiedWitness.lean"
stage lean "$scratch/UnverifiedWitness.lean"
echo 'EFFECT-MUTATION unverified-effect-allowed compiled-production authorizes an effect on an unverified noWitness verdict'
expect_rejected "$scratch/unverified-proof.log" Lockness/ActProofs.lean unverified_effect_refused 'error'
expect_rejected "$scratch/no-verifier-proof.log" Lockness/ActProofs.lean no_verifier_effect_refused 'error'
echo 'EFFECT-MUTATION unverified-effect-allowed unchanged unverified_effect_refused and no_verifier_effect_refused proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Effect.olean" Lockness/Sim/Effect.lean
expect_failure "$scratch/unverified-simulator.log" 'unexpected effect outcome:' \
  lean --run Main.lean effect unverified-effect
echo 'EFFECT-SCENARIO-CONTROL unverified-effect-allowed unverified-effect: production mutant causes outcome failure'

# Mutant 3: the bound-session check always passes; an unbound offer carries an effect.
reset
cp Lockness/Act.lean "$scratch/Act.lean"
mutate Act.lean 'if session.binding = .bound selectedPoint then' 'if true then'
sha256sum Lockness/Act.lean "$scratch/Act.lean"
rebuild Act "${dependents[@]}"
cat > "$scratch/BoundWitness.lean" <<LEAN
import Lockness.Counterexamples.SettlementRollback
$opens
example : unboundSession.binding ≠ .bound selected := by decide
example : act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
    unboundProvider selected settledChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩ := by decide
#eval act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
  unboundProvider selected settledChain
LEAN
sha256sum "$scratch/BoundWitness.lean"
stage lean "$scratch/BoundWitness.lean"
echo 'EFFECT-MUTATION bound-check-removed compiled-production authorizes an effect with an offer bound to no point'
expect_rejected "$scratch/bound-proof.log" Lockness/ActProofs.lean act_effect_requires 'error'
echo 'EFFECT-MUTATION bound-check-removed unchanged act_effect_requires proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Effect.olean" Lockness/Sim/Effect.lean
expect_failure "$scratch/bound-simulator.log" 'unexpected effect outcome:' \
  lean --run Main.lean effect settled-effect
echo 'EFFECT-SCENARIO-CONTROL bound-check-removed settled-effect: production mutant causes outcome failure'

# Mutant 4: the action rule is ignored; every unverified reason allows construction.
reset
cp Lockness/Act.lean "$scratch/Act.lean"
mutate Act.lean 'if policy.constructUnverified reason then' 'if true then'
sha256sum Lockness/Act.lean "$scratch/Act.lean"
rebuild Act "${dependents[@]}"
cat > "$scratch/RuleWitness.lean" <<LEAN
import Lockness.Counterexamples.SettlementRollback
$opens
example : noVerifierSettledPolicy.constructUnverified .noVerifier = false := by decide
example : act noVerifierSettledPolicy .construct
    (verdict noVerifierSettledPolicy publications selected verifiedProvider builder)
    verifiedProvider selected tipChain = .ok ⟨.construct, selected, .offer .noVerifier verifiedSession⟩ := by
  decide
#eval act noVerifierSettledPolicy .construct
  (verdict noVerifierSettledPolicy publications selected verifiedProvider builder)
  verifiedProvider selected tipChain
LEAN
sha256sum "$scratch/RuleWitness.lean"
stage lean "$scratch/RuleWitness.lean"
echo 'EFFECT-MUTATION action-rule-ignored compiled-production constructs on a noVerifier verdict the rule denies'
expect_rejected "$scratch/rule-proof.log" Lockness/ActProofs.lean unverified_construct_iff 'error'
echo 'EFFECT-MUTATION action-rule-ignored unchanged unverified_construct_iff proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Effect.olean" Lockness/Sim/Effect.lean
expect_failure "$scratch/rule-simulator.log" 'unexpected effect outcome:' \
  lean --run Main.lean effect unverified-construct
echo 'EFFECT-SCENARIO-CONTROL action-rule-ignored unverified-construct: production mutant causes outcome failure'

# Mutant 5: settlement stability without the consensus premise, a statement mutant.
reset
cat > "$scratch/ConsensusWitness.lean" <<LEAN
import Lockness.Counterexamples.SettlementRollback
$opens
-- Typechecks only when SettlementStability has no consensus premise.
example : ¬ @SettlementStability fixtureConsensus act := fun stable => consensus_dropped_refutes stable
example : act settledPolicy .effect (.verified oneLinkClaim) verifiedProvider selected settledChain =
    .ok ⟨.effect, selected, .claim oneLinkClaim⟩ := by decide
example : Extends settledChain deepChain := deep_extends
example : ¬ @ConsensusModel.admits fixtureConsensus settledChain deepChain := deep_not_admitted
example : canonical selected settledChain ∧ ¬ canonical selected deepChain := by decide
#print axioms consensus_dropped_refutes
LEAN
sha256sum "$scratch/ConsensusWitness.lean"
# Control: against the unchanged statement the witness must not typecheck.
expect_failure "$scratch/consensus-witness-control.log" 'type mismatch' lean "$scratch/ConsensusWitness.lean"
if setup_failure "$scratch/consensus-witness-control.log"; then
  echo 'consensus witness control failed for setup instead of the premise' >&2; exit 1
fi
echo 'EFFECT-WITNESS-CONTROL consensus-dropped witness rejected by the unchanged SettlementStability'
cp Lockness/Act.lean "$scratch/Act.lean"
mutate Act.lean "∀ chain', Extends chain chain' → ConsensusModel.admits chain chain' →" \
  "∀ chain', Extends chain chain' →"
sha256sum Lockness/Act.lean "$scratch/Act.lean"
rebuild Act "${dependents[@]}"
stage lean "$scratch/ConsensusWitness.lean"
echo 'EFFECT-MUTATION consensus-dropped a settled point rolled back deeper than consensus admits; mutated SettlementStability constructively false on the real act'
expect_rejected "$scratch/consensus-proof.log" Lockness/ActProofs.lean act_settlement 'error'
echo 'EFFECT-MUTATION consensus-dropped unchanged act_settlement proof rejected on the mutated statement'
echo 'EFFECT-SCENARIO-CONTROL consensus-dropped none: statement mutant, no executable changes'
echo 'EFFECT-MUTATIONS mutants=5 witnesses=5 witness-controls=1 proof-rejections=7 fixture-rejections=1 scenario-controls=4'
