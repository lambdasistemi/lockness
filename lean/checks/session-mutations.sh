#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/session-mutations.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/Lockness/Counterexamples" "$scratch/Lockness/Sim"
cp -R .lake/build/lib/lean/Lockness/. "$scratch/Lockness/"
export LEAN_PATH="$scratch:$PWD/.lake/build/lib/lean"
stage() {
  printf 'STAGE command='; printf '%q ' "$@"; printf '\n'
  local result=0
  "$@" || result=$?
  printf 'STAGE exit=%s\n' "$result"
  return "$result"
}
# Separate the executable law/unchanged proposition from the proofs of that law.
# The copied prefix is production source, with one equality guard removed.
[[ $(grep -cFx -- '-- Acquisition proofs' Lockness/Session.lean) = 1 ]]
[[ $(grep -cF 'if session.point = point then' Lockness/Session.lean) = 1 ]]
sed '/^-- Acquisition proofs/,$d' Lockness/Session.lean > "$scratch/Original.lean"
printf '\nend Lockness\n' >> "$scratch/Original.lean"
sed 's/if session.point = point then/if True then/' "$scratch/Original.lean" > "$scratch/Session.lean"
if cmp -s "$scratch/Original.lean" "$scratch/Session.lean"; then
  echo "mutation did not apply" >&2; exit 1
fi
sha256sum Lockness/Session.lean "$scratch/Original.lean" "$scratch/Session.lean"
stage lean -o "$scratch/Lockness/Session.olean" "$scratch/Session.lean"
# Every imported dependent is rebuilt against the mutated production module.
stage lean -o "$scratch/Lockness/Counterexamples/SessionMutation.olean" Lockness/Counterexamples/SessionMutation.lean
cat > "$scratch/Witness.lean" <<'LEAN'
import Lockness.Counterexamples.SessionMutation
open Lockness Lockness.Counterexamples Lockness.Counterexamples.SessionExamples
example : acquire point newerProvider = .ok newer := by decide
example : ¬ NoSubstitution acquire := newer_refutes_no_substitution acquire (by decide)
#eval acquire point newerProvider
#print axioms newer_refutes_no_substitution
LEAN
sha256sum "$scratch/Witness.lean"
stage lean "$scratch/Witness.lean"
echo 'SESSION-MUTATION compiled-production accepts-newer; unchanged NoSubstitution constructively refuted'
# Check the full unchanged proof text only after successful semantic execution.
printf 'import Lockness.Session\nnamespace Lockness\n' > "$scratch/FailedProof.lean"
sed -n '/^theorem acquire_no_substitution/,/^-- Inverting/{ /^-- Inverting/!p; }' Lockness/Session.lean >> "$scratch/FailedProof.lean"
printf '\nend Lockness\n' >> "$scratch/FailedProof.lean"
sha256sum "$scratch/FailedProof.lean"
if stage lean "$scratch/FailedProof.lean" > "$scratch/failed-proof.log" 2>&1; then
  echo 'unchanged acquisition proof survived' >&2; exit 1
fi
cat "$scratch/failed-proof.log"
if ! grep -qF 'error: Type mismatch' "$scratch/failed-proof.log" ||
    ! grep -qF 'session.point = point' "$scratch/failed-proof.log"; then
  echo 'proof failed without the required semantic contradiction diagnostic'; exit 1
fi
echo 'SESSION-MUTATION unchanged acquire_no_substitution proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Session.olean" Lockness/Sim/Session.lean
if stage lean --run Main.lean session newer-point > "$scratch/simulator.log" 2>&1; then
  echo 'simulator accepted unexpected newer point' >&2; exit 1
fi
cat "$scratch/simulator.log"
grep -qF 'unexpected session outcome:' "$scratch/simulator.log" || {
  echo 'scenario control failed before model outcome'; exit 1;
}
echo 'SESSION-SCENARIO-CONTROL newer-point: production mutant causes outcome failure'
