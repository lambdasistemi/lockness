#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/mutations.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/Lockness/Counterexamples"
cp -R .lake/build/lib/lean/Lockness/. "$scratch/Lockness/"
export LEAN_PATH="$scratch:$PWD/.lake/build/lib/lean${LEAN_PATH:+:$LEAN_PATH}"
stage() {
  printf 'STAGE command='; printf '%q ' "$@"; printf '\n'
  local result=0
  "$@" || result=$?
  printf 'STAGE exit=%s\n' "$result"
  return "$result"
}
replace_once() {
  local before=$1 after=$2
  [[ $(grep -oF "$before" Lockness/Root.lean | wc -l) = 1 ]] || {
    echo "mutation location not unique: $before" >&2; exit 1;
  }
  local source
  source=$(cat Lockness/Root.lean)
  printf '%s\n' "${source/"$before"/"$after"}" > "$scratch/Root.lean"
  ! cmp -s Lockness/Root.lean "$scratch/Root.lean" || { echo 'mutation did not apply'; exit 1; }
  sha256sum Lockness/Root.lean "$scratch/Root.lean"
  stage lean -o "$scratch/Lockness/Root.olean" "$scratch/Root.lean"
  # Recompile every imported dependent so no stale unmutated model can be used.
  stage lean -o "$scratch/Lockness/Counterexamples/Fixtures.olean" Lockness/Counterexamples/Fixtures.lean
  stage lean -o "$scratch/Lockness/Counterexamples/TrustRefutation.olean" Lockness/Counterexamples/TrustRefutation.lean
}
# The filter still executes; only membership in the trusted set is removed.
replace_once 'decide (key ∈ policy.trustedKeys)' 'true'
cat > "$scratch/Refute.lean" <<'LEAN'
import Lockness.Counterexamples.TrustRefutation
open Lockness Lockness.Counterexamples
example : ¬ RootSafety acceptRoot :=
  emptyTrust_refutes_safety acceptRoot (by decide)
LEAN
sha256sum "$scratch/Refute.lean"
stage lean "$scratch/Refute.lean"
echo 'MUTATION subset-check: compiled production mutant; unchanged RootSafety constructively false'
# Preserve failed-proof output as additional evidence, not the semantic witness.
if stage lean Lockness/RootProofs.lean > "$scratch/failed-proof.log" 2>&1; then
  echo 'unchanged production proof survived subset mutation' >&2; exit 1
fi
cat "$scratch/failed-proof.log"
echo 'MUTATION subset-check: unchanged proof rejected after semantic refutation'
if stage lean --run Main.lean accept-root untrusted-key > "$scratch/simulator.log" 2>&1; then
  echo 'simulator accepted the unexpected production-mutant outcome' >&2; exit 1
fi
cat "$scratch/simulator.log"
grep -qF 'unexpected outcome:' "$scratch/simulator.log" || {
  echo 'simulator mutation control failed before reaching its outcome assertion'; exit 1;
}
echo 'SCENARIO-CONTROL untrusted-key: production subset mutant causes outcome failure'

# Each further fault compiles, executes a changed outcome and rejects unchanged proofs.
for fault in observation point root empty agreement refusal; do
  case "$fault" in
    observation)
      replace_once '&& policy.verify publication' '&& true'
      witness='example : acceptRoot { honestPolicy with verify := fun _ => false } [honestPublication] point = .ok root := by decide'
      witness+=$'\n'
      witness+='def badPolicy : Policy := { honestPolicy with verify := fun _ => false }
example : @ObservationSound ⟨fun _ => False⟩ badPolicy := by
  intro publication verified
  simp [badPolicy] at verified
example : ¬ (∃ keys : List Key, Candidate badPolicy keys ∧
    ∀ key ∈ keys, key ∈ badPolicy.trustedKeys ∧
      ∃ publication ∈ [honestPublication], publication.key = key ∧
        publication.point = point ∧ publication.root = root ∧
        @SigValid ⟨fun _ => False⟩ publication) := by
  intro ⟨keys, candidate, witnesses⟩
  rcases keys with _ | ⟨key, rest⟩
  · exact candidate.1 rfl
  · obtain ⟨_, publication, _, _, _, _, invalid⟩ := witnesses key (by simp)
    exact invalid'
      ;;
    point)
      replace_once 'decide (publication.point = point ∧ publication.root = root)' 'decide (publication.root = root)'
      witness='example : acceptRoot honestPolicy [{ honestPublication with point := { point with slot := 8 } }] point = .ok root := by decide'
      ;;
    root)
      replace_once 'decide (publication.point = point ∧ publication.root = root)' 'decide (publication.point = point)'
      witness='example : acceptRoot { honestPolicy with verify := fun p => decide (p.key = [1]) } [{ untrustedPublication with root := ⟨[99], [99]⟩ }, honestPublication] point = .ok ⟨[99], [99]⟩ := by decide'
      ;;
    empty)
      replace_once 'if Candidate policy (keysFor root) then' 'if (keysFor root).Nodup ∧ policy.agreement (keysFor root) = true then'
      witness='example : acceptRoot { untrustedPolicy with agreement := fun _ => true } [untrustedPublication] point = .ok root := by decide'
      ;;
    agreement)
      replace_once 'if Candidate policy (keysFor root) then' 'if (keysFor root) ≠ [] ∧ (keysFor root).Nodup then'
      witness='example : acceptRoot { honestPolicy with agreement := fun _ => false } [honestPublication] point = .ok root := by decide'
      ;;
    refusal)
      replace_once '| [] => .error (.noRoot point)' '| [] => .error (.noRoot { point with slot := point.slot + 1 })'
      witness='example : acceptRoot honestPolicy [] point = .error (.noRoot { point with slot := point.slot + 1 }) := by decide'
      witness+=$'\n'
      witness+='example : Refusal.noRoot { point with slot := point.slot + 1 } ≠ Refusal.noRoot point := by decide'
      ;;
  esac
  printf 'import Lockness.Counterexamples.Fixtures\nopen Lockness Lockness.Counterexamples\n%s\n' "$witness" > "$scratch/Witness.lean"
  sha256sum "$scratch/Witness.lean"
  stage lean "$scratch/Witness.lean"
  if stage lean Lockness/RootProofs.lean > "$scratch/failed-proof.log" 2>&1; then
    echo "unchanged proof survived: $fault" >&2; exit 1
  fi
  cat "$scratch/failed-proof.log"
  echo "MUTATION $fault: compiled changed-outcome witness; unchanged production proof rejected"
done
