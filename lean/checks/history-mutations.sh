#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/history-mutations.XXXXXX")
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
# Mutate the actual production source once, prove the edit applied, then recompile every history
# dependent so no stale unmutated model can be used.
mutate() {
  local before=$1 after=$2
  [[ $(grep -oF "$before" Lockness/History.lean | wc -l) = 1 ]] || {
    echo "mutation location not unique: $before" >&2; exit 1;
  }
  local source
  source=$(cat Lockness/History.lean)
  printf '%s\n' "${source/"$before"/"$after"}" > "$scratch/History.lean"
  ! cmp -s Lockness/History.lean "$scratch/History.lean" || { echo 'mutation did not apply' >&2; exit 1; }
  [[ $(grep -oF "$after" "$scratch/History.lean" | wc -l) = 1 ]] || {
    echo "mutation text not present once: $after" >&2; exit 1;
  }
  sha256sum Lockness/History.lean "$scratch/History.lean"
  stage lean -o "$scratch/Lockness/History.olean" "$scratch/History.lean"
  stage lean -o "$scratch/Lockness/Counterexamples/HistoryFixtures.olean" Lockness/Counterexamples/HistoryFixtures.lean
  stage lean -o "$scratch/Lockness/Counterexamples/HistoryRefutation.olean" Lockness/Counterexamples/HistoryRefutation.lean
  stage lean -o "$scratch/Lockness/Sim/History.olean" Lockness/Sim/History.lean
}
# The compiled witness executes against the mutant: acceptance by evaluation, then the
# constructive refutation of the unchanged guarantee.
witness() {
  printf 'import Lockness.Counterexamples.HistoryRefutation\nopen Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples Lockness.Counterexamples.HistoryExamples\n%s\n' "$1" > "$scratch/Witness.lean"
  sha256sum "$scratch/Witness.lean"
  stage lean "$scratch/Witness.lean"
}
# The unchanged proof must fail, with an error inside the named theorem's own lines.
unchanged_proof_fails() {
  local theorem=$1 first last line
  first=$(grep -n "^theorem $theorem " Lockness/HistoryProofs.lean | cut -d: -f1)
  [[ $(grep -c "^theorem $theorem " Lockness/HistoryProofs.lean) = 1 ]] || {
    echo "theorem not found once: $theorem" >&2; exit 1;
  }
  last=
  while read -r line; do
    if (( line > first )); then last=$((line - 1)); break; fi
  done < <(grep -nE '^(theorem|end) ' Lockness/HistoryProofs.lean | cut -d: -f1)
  [[ -n $last ]] || { echo "no end of theorem: $theorem" >&2; exit 1; }
  if stage lean Lockness/HistoryProofs.lean > "$scratch/failed-proof.log" 2>&1; then
    echo "unchanged history proof survived the mutation: $theorem" >&2; exit 1
  fi
  cat "$scratch/failed-proof.log"
  while read -r line; do
    if (( line >= first && line <= last )); then
      echo "UNCHANGED-PROOF-REJECTED theorem=$theorem lines=$first-$last error-line=$line"
      return 0
    fi
  done < <(grep -oE 'HistoryProofs\.lean:[0-9]+:[0-9]+: error' "$scratch/failed-proof.log" | cut -d: -f2)
  echo "no error inside $theorem (lines $first-$last); failure was elsewhere" >&2; exit 1
}
# The real scenario asserts its outcome, so the mutant must make it report an unexpected one.
scenario_fails() {
  if stage lean --run Main.lean history "$1" > "$scratch/simulator.log" 2>&1; then
    echo "history scenario accepted the mutant: $1" >&2; exit 1
  fi
  cat "$scratch/simulator.log"
  grep -qF 'unexpected history outcome:' "$scratch/simulator.log" || {
    echo 'history scenario control failed before its outcome assertion' >&2; exit 1;
  }
  echo "HISTORY-SCENARIO-CONTROL scenario=$1 changed outcome rejected"
}

# M1: the rebuilt root is never compared with the verified datum root.
mutate 'if policy.historyRoot state = appRoot then' 'if true then'
witness 'example : acceptHistory sequencePolicy publications selected (historyOffer [itemA, itemB]) =
    .ok (sequenceClaim sequencePolicy) := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer forgedHistory) =
    .ok forgedClaim := by decide
example : ¬ HistorySequenceSoundness acceptHistory :=
  forged_history_refutes_sequence_soundness acceptHistory (by decide)
#print axioms forged_history_refutes_sequence_soundness
#eval acceptHistory sequencePolicy publications selected (historyOffer forgedHistory)'
echo 'HISTORY-MUTATION root-comparison-removed: compiled production mutant accepts the forged history; unchanged HistorySequenceSoundness constructively false'
unchanged_proof_fails accept_history_sequence_sound
scenario_fails forged-transaction

# M2: selection reads the enclosing answer; the real root comparison remains.
mutate 'answer.transactions.filter policy.relevant' 'answer.transactions.filter fun item => policy.relevant item && answer.transactions.all policy.relevant'
witness 'example : acceptHistory sequencePolicy publications selected (historyOffer omittedPair) =
    .ok (sequenceClaim sequencePolicy) := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer forgedHistory) =
    .error (.evidenceFailure selected) := by decide
example : paddedHistory.filter sequencePolicy.relevant = omittedPair.filter sequencePolicy.relevant := by
  decide
example : acceptHistory sequencePolicy publications selected (historyOffer paddedHistory) =
    .error (.evidenceFailure selected) := by decide
example : ¬ HistorySupersetTolerance acceptHistory :=
  context_selection_refutes_tolerance acceptHistory (by decide) (by decide)
#print axioms context_selection_refutes_tolerance
#eval acceptHistory sequencePolicy publications selected (historyOffer paddedHistory)'
echo 'HISTORY-MUTATION context-dependent-relevance: compiled production mutant refuses a padded history with equal relevant filters; unchanged HistorySupersetTolerance constructively false'
unchanged_proof_fails history_superset_tolerant
scenario_fails irrelevant-extras

# M3: only a projection of the state root, its scheme, is compared.
mutate 'if policy.historyRoot state = appRoot then' 'if (policy.historyRoot state).scheme = appRoot.scheme then'
witness 'example : acceptHistory cancelPolicy publications selected (historyOffer omittedPair) =
    .ok (cancelClaim cancelPolicy omittedPair) := by decide
example : acceptHistory cancelPolicy publications selected (historyOffer shortHistory) =
    .ok projectedClaim := by decide
example : projectedClaim.result.state ≠ (cancelClaim cancelPolicy omittedPair).result.state := by decide
example : ¬ HistoryStateSoundness acceptHistory :=
  weaker_projection_refutes_state_soundness acceptHistory (by decide)
#print axioms weaker_projection_refutes_state_soundness
#eval acceptHistory cancelPolicy publications selected (historyOffer shortHistory)'
echo 'HISTORY-MUTATION state-root-projection: compiled production mutant accepts a different state sharing the root scheme; unchanged HistoryStateSoundness constructively false'
unchanged_proof_fails accept_history_state_sound
scenario_fails forged-transaction
