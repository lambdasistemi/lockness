#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/app-mutations.XXXXXX")
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
expect_failure() {
  local log=$1 diagnostic=$2; shift 2
  if stage "$@" > "$log" 2>&1; then
    cat "$log"; echo "unchanged check survived the mutant: $*" >&2; exit 1
  fi
  cat "$log"
  grep -qF -- "$diagnostic" "$log" || { echo "failure was not the expected diagnostic: $diagnostic" >&2; exit 1; }
}

# Mutant 1: verifyApp trusts the claimed root. Guard 1 is removed; checkApp receives answer.root.
cp Lockness/App.lean "$scratch/App.lean"
mutate App.lean 'if answer.root = root then' 'if True then'
mutate App.lean 'policy.checkApp answer.proof root policy.query answer.value' \
  'policy.checkApp answer.proof answer.root policy.query answer.value'
sha256sum Lockness/App.lean "$scratch/App.lean"
rebuild App Accept Counterexamples/AppFixtures Counterexamples/AppRootMutation
cat > "$scratch/ClaimedRootWitness.lean" <<'LEAN'
import Lockness.Counterexamples.AppRootMutation
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
example : accept (appPolicy false finalQuery) publications selected providerA replacingBuilder =
    .ok forgedClaim := by decide
example : ¬ AcceptSoundness accept := replaced_root_refutes_soundness accept (by decide)
#print axioms replaced_root_refutes_soundness
#eval accept (appPolicy false finalQuery) publications selected providerA replacingBuilder
LEAN
sha256sum "$scratch/ClaimedRootWitness.lean"
stage lean "$scratch/ClaimedRootWitness.lean"
echo 'APP-MUTATION claimed-root compiled-production accepts replaced root; unchanged AcceptSoundness constructively false'
expect_failure "$scratch/claimed-root-proof.log" \
  'policy.checkApp answer.proof root policy.query answer.value = true' lean Lockness/AppProofs.lean
echo 'APP-MUTATION claimed-root unchanged application proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/App.olean" Lockness/Sim/App.lean
expect_failure "$scratch/claimed-root-simulator.log" 'unexpected app outcome:' \
  lean --run Main.lean app replaced-root
echo 'APP-SCENARIO-CONTROL claimed-root replaced-root: production mutant causes outcome failure'

# Mutant 2: the fold checks the ledger under the session's root instead of the accepted root.
rm -f "$scratch"/*.lean
cp -R .lake/build/lib/lean/Lockness/. "$scratch/Lockness/"
cp Lockness/Accept.lean "$scratch/Accept.lean"
mutate Accept.lean 'verifyLedger policy root session session.ledger' \
  'verifyLedger policy session.acceptedRoot session session.ledger'
sha256sum Lockness/Accept.lean "$scratch/Accept.lean"
rebuild Accept Counterexamples/AppFixtures Counterexamples/AppRootMutation
cat > "$scratch/SessionRootWitness.lean" <<'LEAN'
import Lockness.Counterexamples.AppRootMutation
open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
example : accept (appPolicy false finalQuery) publications selected substitutingProvider
    (honestBuilder false proofA finalQuery) = .ok substitutedClaim := by decide
example : ¬ AcceptSoundness accept := session_root_refutes_soundness accept (by decide)
#print axioms session_root_refutes_soundness
#eval accept (appPolicy false finalQuery) publications selected substitutingProvider
  (honestBuilder false proofA finalQuery)
LEAN
sha256sum "$scratch/SessionRootWitness.lean"
stage lean "$scratch/SessionRootWitness.lean"
echo 'APP-MUTATION session-root compiled-production accepts substituted ledger answer; unchanged AcceptSoundness constructively false'
expect_failure "$scratch/session-root-proof.log" \
  'verifyLedger policy root session session.ledger = Except.ok appRoot' lean Lockness/AcceptProofs.lean
echo 'APP-MUTATION session-root unchanged fold proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/App.olean" Lockness/Sim/App.lean
expect_failure "$scratch/session-root-simulator.log" 'unexpected app outcome:' \
  lean --run Main.lean app honest
echo 'APP-SCENARIO-CONTROL session-root honest: production mutant causes outcome failure'
