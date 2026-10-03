#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
stage() {
  printf 'STAGE command='; printf '%q ' "$@"; printf '\n'
  local result=0
  "$@" || result=$?
  printf 'STAGE exit=%s\n' "$result"
  return "$result"
}
stage lean --version
mapfile -t modules < <(find Lockness -type f -name '*.lean' | sort)
(( ${#modules[@]} > 0 )) || { echo 'empty model source inventory'; exit 1; }
# This lexical rule enforces source policy; the axiom audit checks stored proofs.
if grep -Enw 'sorry|admit' "${modules[@]}" Lockness.lean Main.lean; then
  echo 'source hole policy rejected the model' >&2; exit 1
fi
stage lake build
scratch=$(mktemp -d "$PWD/.lake/model-gate.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
# Import every module, including orphans, before inspecting elaborated declarations.
for file in "${modules[@]}"; do
  module=${file%.lean}; module=${module//\//.}
  printf 'import %s\n' "$module"
done > "$scratch/Inventory.lean"
printf '\n#audit_lockness\n#inventory_lockness_declarations\n' >> "$scratch/Inventory.lean"
stage lake env lean "$scratch/Inventory.lean"
for hole in sorry admit axiom anonymous; do
  if [[ $hole = axiom ]]; then
    declaration='axiom escape : False'
    diagnostic='custom model axiom'
  elif [[ $hole = anonymous ]]; then
    declaration='example : True := by sorry'
    diagnostic='declaration uses `sorry`'
  else
    declaration="theorem escape : True := by $hole"
    diagnostic='unapproved axiom sorryAx'
  fi
  printf 'import Lockness.Axioms\nnamespace Lockness.HoleControl\n%s\nend Lockness.HoleControl\n#audit_lockness\n' "$declaration" > "$scratch/Hole.lean"
  flags=()
  [[ $hole != anonymous ]] || flags=(-DwarningAsError=true)
  if stage lake env lean "${flags[@]}" "$scratch/Hole.lean" > "$scratch/hole.log" 2>&1; then
    echo "hole policy accepted $hole" >&2; exit 1
  fi
  cat "$scratch/hole.log"
  grep -qF "$diagnostic" "$scratch/hole.log" || { echo 'hole control failed for setup instead of policy'; exit 1; }
  echo "HOLE-POLICY rejected=$hole"
done
stage lake exe lockness-sim accept-root honest
stage lake exe lockness-sim accept-root untrusted-key
stage lake exe lockness-sim accept-root subset-mutation
stage lake env lean Lockness/Counterexamples/SubsetMutation.lean
stage lake env bash checks/mutations.sh
stage lake env lean Lockness/Tests/Session.lean
stage lake env lean Lockness/Counterexamples/SessionMutation.lean
stage lake exe lockness-sim session honest
stage lake exe lockness-sim session absent-point
stage lake exe lockness-sim session newer-point
stage lake env bash checks/session-mutations.sh
usage_failure() {
  local diagnostic=$1 result=0
  shift
  stage lake exe lockness-sim "$@" > "$scratch/usage.log" 2>&1 || result=$?
  cat "$scratch/usage.log"
  [[ $result = 64 ]] || { echo "expected usage64, got $result" >&2; exit 1; }
  grep -qF "$diagnostic" "$scratch/usage.log"
  echo "USAGE-CONTROL exit=$result args=$*"
}
stage lake env lean Lockness/Tests/Ledger.lean
stage lake env lean Lockness/Counterexamples/LedgerRootMutation.lean
stage lake env lean Lockness/Counterexamples/LedgerUniqueness.lean
stage lake exe lockness-sim ledger honest
stage lake exe lockness-sim ledger substituted-root
stage lake exe lockness-sim ledger duplicate-asset
stage lake env bash checks/ledger-mutations.sh
usage_failure 'unknown ledger scenario' ledger unknown
usage_failure 'usage: lockness-sim' ledger
usage_failure 'unknown session scenario'  session unknown
usage_failure 'usage: lockness-sim' unknown
usage_failure 'usage: lockness-sim' session
usage_failure 'unknown accept-root scenario' accept-root unknown
# An unknown scenario must be a usage failure, never an accepted root outcome.
if stage lake exe lockness-sim accept-root unknown > "$scratch/scenario.log" 2>&1; then
  echo 'unknown scenario accepted' >&2; exit 1
fi
cat "$scratch/scenario.log"
grep -qF 'unknown accept-root scenario' "$scratch/scenario.log"
echo "MODEL-GATE passed sources=${#modules[@]} proofs=kernel-checked scenarios=root-session-ledger lifecycle=repeated-expiry-release signatures=abstract deployment=unestablished"
