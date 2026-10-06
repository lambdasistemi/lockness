#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "$PWD/.lake/completeness-mutations.XXXXXX")
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
# already occur elsewhere or contain the fragment itself (M3 prefixes the check), so both expected
# counts after the edit are computed rather than required to be zero.
mutate() {
  local file=$1 before=$2 after=$3 source expected_after expected_before
  [[ $(count "$before" < "$scratch/$file") = 1 ]] || {
    echo "mutation location not unique: $before" >&2; exit 1;
  }
  expected_after=$(( $(count "$after" < "$scratch/$file") - $(count "$after" <<< "$before") + 1 ))
  expected_before=$(count "$before" <<< "$after")
  source=$(cat "$scratch/$file")
  printf '%s\n' "${source/"$before"/"$after"}" > "$scratch/$file.next"
  mv "$scratch/$file.next" "$scratch/$file"
  [[ $(count "$before" < "$scratch/$file") = "$expected_before" ]] || {
    echo "mutation did not apply: $before" >&2; exit 1;
  }
  [[ $(count "$after" < "$scratch/$file") = "$expected_after" ]] || {
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
# The real simulator, rebuilt against the mutant, must reject the scenario's outcome.
expect_scenario_failure() {
  local log=$1 scenario=$2
  expect_failure "$log" 'unexpected completeness outcome:' lean --run Main.lean completeness "$scenario"
  if setup_failure "$log"; then
    echo "scenario control failed for setup instead of the outcome: $scenario" >&2; exit 1
  fi
}
proofs=Lockness/CompletenessProofs.lean
refutation_marker="-- The refutations below consume the frozen statements' premise lists."
# Modules on the witness and scenario path, by the production module each mutant edits.
completeness_dependents=(Counterexamples/CompletenessFixtures Counterexamples/CompletenessRefutation)
# The inherited modules between a mutated module and the completeness modules (Accept, Verdict
# and their fixtures) keep their compiled form: none asserts an outcome a mutant changes, the
# kernel and the interpreter resolve the mutated definition by name, and each scenario control
# shows the mutant reaching the executable. Rebuilding them adds about ten seconds per module.
ledger_dependents=(Completeness "${completeness_dependents[@]}")
verdict_dependents=("${completeness_dependents[@]}")
opens='open Lockness Lockness.Counterexamples Lockness.Counterexamples.AppExamples
open Lockness.Counterexamples.LedgerExamples Lockness.Counterexamples.VerdictExamples
open Lockness.Counterexamples.CompletenessExamples'

# M1: the completeness check of the all-entries acceptance always passes.
cp Lockness/Completeness.lean "$scratch/Completeness.lean"
mutate Completeness.lean \
  'if policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries = true then' \
  'if true then'
sha256sum Lockness/Completeness.lean "$scratch/Completeness.lean"
rebuild Completeness "${completeness_dependents[@]}"
cat > "$scratch/CheckWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ := by
  decide
example : ¬ EntriesSoundness acceptEntries := omitted_refutes_entries acceptEntries (by decide)
#print axioms omitted_refutes_entries
#eval acceptEntries (completePolicy false) publications selected prefixA (offer (answerOf prefixA [entry₁]))
LEAN
sha256sum "$scratch/CheckWitness.lean"
stage lean "$scratch/CheckWitness.lean"
echo 'COMPLETENESS-MUTATION M1 check-removed compiled-production accepts the listing omitting entry₃ as all of prefixA; unchanged EntriesSoundness constructively false'
expect_rejected "$scratch/check-proof.log" "$proofs" accept_entries_sound 'error'
echo 'COMPLETENESS-MUTATION M1 check-removed unchanged accept_entries_sound proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/check-omitted.log" omitted-entry
echo 'COMPLETENESS-SCENARIO-CONTROL M1 check-removed omitted-entry: production mutant causes outcome failure'
expect_scenario_failure "$scratch/check-extra.log" extra-entry
echo 'COMPLETENESS-SCENARIO-CONTROL M1 check-removed extra-entry: production mutant causes outcome failure'

# M2: EntriesSoundness without the CompletenessSound premise, a statement mutant.
reset
cat > "$scratch/HypothesisWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
-- Typechecks only when EntriesSoundness has no CompletenessSound premise.
example : ¬ EntriesSoundness acceptEntries := fun sound => unsound_refutes sound
example : acceptEntries permissivePolicy publications selected prefixA
    (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ := by
  decide
example : entry₃ ∈ ledgerOf false selected ∧ UnderPrefix layout prefixA entry₃ :=
  ⟨by decide, (under_iff _ _).1 (by decide)⟩
#print axioms unsound_refutes
LEAN
sha256sum "$scratch/HypothesisWitness.lean"
# Control: against the unchanged statement the witness must not typecheck.
expect_failure "$scratch/hypothesis-witness-control.log" 'type mismatch' lean "$scratch/HypothesisWitness.lean"
if setup_failure "$scratch/hypothesis-witness-control.log"; then
  echo 'hypothesis witness control failed for setup instead of the premise' >&2; exit 1
fi
echo 'COMPLETENESS-WITNESS-CONTROL M2 hypothesis-dropped witness rejected by the unchanged EntriesSoundness'
cp Lockness/Completeness.lean "$scratch/Completeness.lean"
mutate Completeness.lean 'CompletenessSound policy ledger honestRoot layout → ObjectEncodingFaithful policy →' \
  'ObjectEncodingFaithful policy →'
sha256sum Lockness/Completeness.lean "$scratch/Completeness.lean"
rebuild Completeness Counterexamples/CompletenessFixtures
# The refutations after the marker consume EntriesSoundness's premise list, so the unchanged
# module is rejected inside the first of them; the part before the marker is then rebuilt alone.
refutation_file=Lockness/Counterexamples/CompletenessRefutation.lean
expect_rejected "$scratch/hypothesis-refutation.log" "$refutation_file" omitted_refutes_entries 'error'
[[ $(grep -cFx -- "$refutation_marker" "$refutation_file") = 1 ]] || {
  echo "refutation marker not unique" >&2; exit 1;
}
refutations=$(cat "$refutation_file")
printf '%s\n\nend Lockness.Counterexamples.CompletenessExamples\n' "${refutations%%"$refutation_marker"*}" \
  > "$scratch/CompletenessRefutation.lean"
! grep -qF 'omitted_refutes_entries' "$scratch/CompletenessRefutation.lean" || {
  echo "refutation head still carries the premise-list refutations" >&2; exit 1;
}
grep -qF 'theorem unsound_refutes' "$scratch/CompletenessRefutation.lean" || {
  echo "refutation head lacks unsound_refutes" >&2; exit 1;
}
sha256sum "$refutation_file" "$scratch/CompletenessRefutation.lean"
stage lean -o "$scratch/Lockness/Counterexamples/CompletenessRefutation.olean" \
  "$scratch/CompletenessRefutation.lean"
stage lean "$scratch/HypothesisWitness.lean"
echo 'COMPLETENESS-MUTATION M2 hypothesis-dropped the real acceptEntries under a check violating CompletenessSound accepts the omitting listing; mutated EntriesSoundness constructively false'
expect_rejected "$scratch/hypothesis-proof.log" "$proofs" accept_entries_sound 'error'
echo 'COMPLETENESS-MUTATION M2 hypothesis-dropped unchanged accept_entries_sound proof and omitted_refutes_entries refutation rejected on the mutated statement'
echo 'COMPLETENESS-SCENARIO-CONTROL M2 hypothesis-dropped none: statement mutant, no executable changes; unsound-proof reproduces it on the real model'

# M3: the completeness proof check of the ledger step always passes.
reset
cp Lockness/Ledger.lean "$scratch/Ledger.lean"
mutate Ledger.lean 'policy.checkCompleteness completeness.proof acceptedRoot completeness.keyPrefix' \
  'true || policy.checkCompleteness completeness.proof acceptedRoot completeness.keyPrefix'
sha256sum Lockness/Ledger.lean "$scratch/Ledger.lean"
rebuild Ledger "${ledger_dependents[@]}"
cat > "$scratch/LedgerCheckWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : verifyLedger (completePolicy true) acceptedRoot (offerVia providerRootA) omittingAnswer =
    .ok appRoot₁ := by decide
example : ¬ CompleteLedgerSoundness verifyLedger := omitted_asset_refutes verifyLedger (by decide)
#print axioms omitted_asset_refutes
#eval verifyLedger (completePolicy true) acceptedRoot (offerVia providerRootA) omittingAnswer
LEAN
sha256sum "$scratch/LedgerCheckWitness.lean"
stage lean "$scratch/LedgerCheckWitness.lean"
echo 'COMPLETENESS-MUTATION M3 ledger-check-removed compiled-production accepts the asset listing omitting entry₂ on the duplicate ledger; unchanged CompleteLedgerSoundness constructively false'
expect_rejected "$scratch/ledger-check-proof.log" "$proofs" verifyLedger_complete_sound 'error'
echo 'COMPLETENESS-MUTATION M3 ledger-check-removed unchanged verifyLedger_complete_sound proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/ledger-check-simulator.log" asset-unique
echo 'COMPLETENESS-SCENARIO-CONTROL M3 ledger-check-removed asset-unique: production mutant causes outcome failure'

# M4: the prefix is taken from the answer, not the terminal's request.
reset
cp Lockness/Completeness.lean "$scratch/Completeness.lean"
mutate Completeness.lean 'if answer.keyPrefix = keyPrefix then' 'if True then'
mutate Completeness.lean 'policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries' \
  'policy.checkCompleteness answer.proof acceptedRoot answer.keyPrefix answer.entries'
sha256sum Lockness/Completeness.lean "$scratch/Completeness.lean"
rebuild Completeness "${completeness_dependents[@]}"
cat > "$scratch/PrefixWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf narrowPrefix [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ := by
  decide
example : ¬ EntriesSoundness acceptEntries := narrowed_refutes_entries acceptEntries (by decide)
#print axioms narrowed_refutes_entries
#eval acceptEntries (completePolicy false) publications selected prefixA
  (offer (answerOf narrowPrefix [entry₁]))
LEAN
sha256sum "$scratch/PrefixWitness.lean"
stage lean "$scratch/PrefixWitness.lean"
echo 'COMPLETENESS-MUTATION M4 prefix-from-answer compiled-production accepts a proof for the narrower prefix as all of prefixA; unchanged EntriesSoundness constructively false'
expect_rejected "$scratch/prefix-proof.log" "$proofs" accept_entries_sound 'error'
echo 'COMPLETENESS-MUTATION M4 prefix-from-answer unchanged accept_entries_sound proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/prefix-simulator.log" address-prefix
echo 'COMPLETENESS-SCENARIO-CONTROL M4 prefix-from-answer address-prefix: production mutant causes outcome failure'

# M5: the all-entries proof is checked under the provider's answer root.
reset
cp Lockness/Completeness.lean "$scratch/Completeness.lean"
mutate Completeness.lean 'policy.checkCompleteness answer.proof acceptedRoot keyPrefix' \
  'policy.checkCompleteness answer.proof session.ledger.root keyPrefix'
sha256sum Lockness/Completeness.lean "$scratch/Completeness.lean"
rebuild Completeness "${completeness_dependents[@]}"
cat > "$scratch/RootWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : (offerVia providerRootA).ledger.root = providerRoot := by decide
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ := by
  decide
example : ¬ EntriesSoundness acceptEntries := omitted_refutes_entries acceptEntries (by decide)
#eval acceptEntries (completePolicy false) publications selected prefixA (offer (answerOf prefixA [entry₁]))
LEAN
sha256sum "$scratch/RootWitness.lean"
stage lean "$scratch/RootWitness.lean"
echo 'COMPLETENESS-MUTATION M5 provider-root compiled-production accepts the listing valid only under the provider root; unchanged EntriesSoundness constructively false'
expect_rejected "$scratch/root-proof.log" "$proofs" accept_entries_sound 'error'
echo 'COMPLETENESS-MUTATION M5 provider-root unchanged accept_entries_sound proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/root-simulator.log" address-prefix
echo 'COMPLETENESS-SCENARIO-CONTROL M5 provider-root address-prefix: production mutant causes outcome failure'

# M6: the classification ignores the completeness answer (K2 reverted).
reset
cp Lockness/Verdict.lean "$scratch/Verdict.lean"
mutate Verdict.lean 'if session.ledger.completeness = none then some .noWitness else none' \
  'some .noWitness'
sha256sum Lockness/Verdict.lean "$scratch/Verdict.lean"
rebuild Verdict "${verdict_dependents[@]}"
cat > "$scratch/ClassificationWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : verdict (completePolicy false) publications selected wrongWithoutWitness builder =
    .unverified .noWitness := by decide
#eval verdict (completePolicy false) publications selected wrongWithoutWitness builder
LEAN
sha256sum "$scratch/ClassificationWitness.lean"
stage lean "$scratch/ClassificationWitness.lean"
echo 'COMPLETENESS-MUTATION M6 classification-reverted compiled-production classifies a wrong asset listing without a witness as unverified noWitness'
expect_rejected "$scratch/classification-never-proof.log" "$proofs" completeness_never_unverified 'error'
expect_rejected "$scratch/classification-wrong-proof.log" "$proofs" completeness_wrong_refused 'error'
echo 'COMPLETENESS-MUTATION M6 classification-reverted unchanged completeness_never_unverified and completeness_wrong_refused proofs rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/classification-simulator.log" asset-unique
echo 'COMPLETENESS-SCENARIO-CONTROL M6 classification-reverted asset-unique: production mutant causes outcome failure'

# M7: the policy's requirement is ignored; an answer without completeness passes.
reset
cp Lockness/Ledger.lean "$scratch/Ledger.lean"
mutate Ledger.lean '!policy.requireCompleteness' 'true'
sha256sum Lockness/Ledger.lean "$scratch/Ledger.lean"
rebuild Ledger "${ledger_dependents[@]}"
cat > "$scratch/RequirementWitness.lean" <<LEAN
import Lockness.Counterexamples.CompletenessRefutation
$opens
example : (requiredPolicy true).requireCompleteness = true ∧
    (offerVia providerRootA).ledger.completeness = none := by decide
example : verifyLedger (requiredPolicy true) acceptedRoot (offerVia providerRootA)
    (offerVia providerRootA).ledger = .ok appRoot₁ := by decide
example : ¬ RequiredCompleteLedgerSoundness verifyLedger :=
  bare_required_refutes verifyLedger (by decide)
#print axioms bare_required_refutes
#eval verifyLedger (requiredPolicy true) acceptedRoot (offerVia providerRootA) (offerVia providerRootA).ledger
LEAN
sha256sum "$scratch/RequirementWitness.lean"
stage lean "$scratch/RequirementWitness.lean"
echo 'COMPLETENESS-MUTATION M7 requirement-ignored compiled-production accepts an answer without completeness under a policy requiring it, on the duplicate ledger; unchanged RequiredCompleteLedgerSoundness constructively false'
expect_rejected "$scratch/requirement-proof.log" "$proofs" verifyLedger_required_complete_sound 'error'
echo 'COMPLETENESS-MUTATION M7 requirement-ignored unchanged verifyLedger_required_complete_sound proof rejected after witness'
stage lean -o "$scratch/Lockness/Sim/Completeness.olean" Lockness/Sim/Completeness.lean
expect_scenario_failure "$scratch/requirement-simulator.log" asset-unique
echo 'COMPLETENESS-SCENARIO-CONTROL M7 requirement-ignored asset-unique: production mutant causes outcome failure'
echo 'COMPLETENESS-MUTATIONS mutants=7 witnesses=7 witness-controls=1 proof-rejections=8 refutation-rejections=1 scenario-controls=7'
