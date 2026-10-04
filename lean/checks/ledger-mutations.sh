#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/ledger-mutations.XXXXXX")
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
original='policy.checkWitness · acceptedRoot answer.object'
[[ $(grep -cF "$original" Lockness/Ledger.lean) = 1 ]]
for checkingRoot in answer.root session.acceptedRoot; do
  sed "s/$original/policy.checkWitness · $checkingRoot answer.object/" \
    Lockness/Ledger.lean > "$scratch/Ledger.lean"
  ! cmp -s Lockness/Ledger.lean "$scratch/Ledger.lean" || { echo 'ledger mutation did not apply'; exit 1; }
  [[ $(grep -cF "policy.checkWitness · $checkingRoot answer.object" "$scratch/Ledger.lean") = 1 ]]
  sha256sum Lockness/Ledger.lean "$scratch/Ledger.lean"
  stage lean -o "$scratch/Lockness/Ledger.olean" "$scratch/Ledger.lean"
  stage lean -o "$scratch/Lockness/Counterexamples/LedgerFixtures.olean" Lockness/Counterexamples/LedgerFixtures.lean
  stage lean -o "$scratch/Lockness/Counterexamples/LedgerRootMutation.olean" Lockness/Counterexamples/LedgerRootMutation.lean
  cat > "$scratch/Witness.lean" <<'LEAN'
import Lockness.Counterexamples.LedgerRootMutation
open Lockness Lockness.Counterexamples.LedgerExamples
example : verifyLedger (policyFor false) acceptedRoot session substitutedAnswer = .ok appRoot₃ := by decide
example : ¬ LedgerSoundness verifyLedger := substituted_root_refutes_soundness verifyLedger (by decide)
#print axioms substituted_root_refutes_soundness
#eval verifyLedger (policyFor false) acceptedRoot session substitutedAnswer
LEAN
  sha256sum "$scratch/Witness.lean"
  stage lean "$scratch/Witness.lean"
  echo "LEDGER-MUTATION checking-root=$checkingRoot compiled-production acceptance; unchanged LedgerSoundness constructively false"
  if stage lean Lockness/LedgerProofs.lean > "$scratch/failed-proof.log" 2>&1; then
    echo 'unchanged ledger proof survived root substitution'; exit 1
  fi
  cat "$scratch/failed-proof.log"
  grep -qF 'policy.checkWitness witness acceptedRoot answer.object = true' "$scratch/failed-proof.log" || {
    echo 'ledger proof failed without accepted-root observation contradiction'; exit 1;
  }
  # Scenario code checks the actual executable result, even under production substitution.
  stage lean -o "$scratch/Lockness/Sim/Ledger.olean" Lockness/Sim/Ledger.lean
  if stage lean --run Main.lean ledger substituted-root > "$scratch/simulator.log" 2>&1; then
    echo 'ledger scenario accepted substituted-root mutant'; exit 1
  fi
  cat "$scratch/simulator.log"
  grep -qF 'unexpected ledger outcome:' "$scratch/simulator.log" || {
    echo 'ledger scenario control failed before outcome assertion'; exit 1;
  }
  echo "LEDGER-SCENARIO-CONTROL checking-root=$checkingRoot changed outcome rejected"
done
