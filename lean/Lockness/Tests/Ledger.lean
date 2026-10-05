import Lean
import Lockness.LedgerProofs
import Lockness.Counterexamples.LedgerRootMutation
import Lockness.Counterexamples.LedgerUniqueness

namespace Lockness.Tests.Ledger
open Counterexamples.LedgerExamples

example : Policy → Root → Session → LedgerAnswer → Except Refusal Root := verifyLedger
example : LedgerSoundness verifyLedger := verifyLedger_sound

theorem honest_acceptance : verifyLedger (policyFor false) acceptedRoot session answer₁ =
    .ok appRoot₁ := by decide

theorem provider_roots_ignored :
    verifyLedger (policyFor false) acceptedRoot
      { session with acceptedRoot := providerRoot }
      { answer₁ with root := providerRoot } = .ok appRoot₁ := by decide

theorem selected_network_refusal : verifyLedger (policyFor false) acceptedRoot session
    { answer₁ with point := { point with network := [99] } } =
    .error (.evidenceFailure point) := by decide

theorem selected_slot_refusal : verifyLedger (policyFor false) acceptedRoot session
    { answer₁ with point := { point with slot := point.slot + 1 } } =
    .error (.evidenceFailure point) := by decide

theorem selected_hash_refusal : verifyLedger (policyFor false) acceptedRoot session
    { answer₁ with point := { point with blockHash := [99] } } =
    .error (.evidenceFailure point) := by decide

theorem decode_refusal : verifyLedger (policyFor false) acceptedRoot session
    { answer₁ with object := [99] } = .error (.evidenceFailure point) := by decide

theorem binding_refusal : verifyLedger
    { policyFor false with objectBytes := fun _ => [99] }
    acceptedRoot session answer₁ = .error (.evidenceFailure point) := by decide

theorem witness_refusal : verifyLedger (policyFor false) acceptedRoot session
    { answer₁ with witness := some [99] } = .error (.evidenceFailure point) := by decide

theorem asset_refusal : verifyLedger { policyFor false with asset := [99] }
    acceptedRoot session answer₁ = .error (.evidenceFailure point) := by decide

theorem schema_refusal : verifyLedger { policyFor false with schema := [99] }
    acceptedRoot session answer₁ = .error (.evidenceFailure point) := by decide

theorem datum_refusal : verifyLedger { policyFor false with datumOf := fun _ => none }
    acceptedRoot session answer₁ = .error (.evidenceFailure point) := by decide

theorem parse_refusal : verifyLedger { policyFor false with parseDatum := fun _ _ => none }
    acceptedRoot session answer₁ = .error (.evidenceFailure point) := by decide

theorem sound_honest_premises :
    WitnessSound (policyFor false) (ledgerFor false) honestRoot ∧
    ObjectEncodingFaithful (policyFor false) ∧
    AssetObservationSound (policyFor false) carries ∧
    DatumObservationSound (policyFor false) honestDatumRoot ∧
    OneShot (ledgerFor false) asset carries ∧
    acceptedRoot = honestRoot session.selectedPoint ∧
    verifyLedger (policyFor false) acceptedRoot session answer₁ = .ok appRoot₁ :=
  ⟨fixture_witness_sound false, fixture_encoding_faithful false,
    fixture_asset_sound false, fixture_datum_sound false, honest_one_shot, rfl,
    honest_acceptance⟩

theorem substituted_root_refusal : verifyLedger (policyFor false) acceptedRoot session
    substitutedAnswer = .error (.evidenceFailure point) := by decide

end Lockness.Tests.Ledger

open Lean Elab Command

-- The gate invokes this after importing every model source, including orphans.
elab "#inventory_lockness_declarations" : command => do
  let environment ← getEnv
  let mut count := 0
  for (name, info) in environment.constants.toList do
    let owned := match environment.getModuleIdxFor? name with
      | some index => (environment.header.moduleNames[index.toNat]!).toString.startsWith "Lockness"
      | none => (name.toString.splitOn "Lockness").length > 1
    if owned then
      count := count + 1
      let axioms ← collectAxioms name
      logInfo m!"DECLARATION {name}: {info.type}; AXIOMS {axioms.toList}"
  if count == 0 then throwError "empty model declaration inventory"
  logInfo m!"DECLARATION-INVENTORY named={count}"
