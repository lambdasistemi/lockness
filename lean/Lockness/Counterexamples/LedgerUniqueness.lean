import Lockness.Counterexamples.LedgerFixtures

namespace Lockness.Counterexamples.LedgerExamples

-- The frozen universal statement with exactly the OneShot premise removed.
def LedgerSoundnessWithoutOneShot
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) : Prop :=
  ∀ policy ledger honestRoot carries honestDatumRoot acceptedRoot session answer appRoot,
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    acceptedRoot = honestRoot session.selectedPoint →
    operation policy acceptedRoot session answer = .ok appRoot →
    ∃ entry : TxIn × TxOut,
      entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
      honestDatumRoot policy.schema entry.2 = some appRoot ∧
      ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry

theorem duplicate_members : entry₁ ∈ ledgerFor true point ∧ entry₂ ∈ ledgerFor true point := by
  simp [ledgerFor]

theorem duplicate_assets : carries entry₁.2 asset ∧ carries entry₂.2 asset := by decide

theorem duplicate_distinct : entry₁ ≠ entry₂ ∧ appRoot₁ ≠ appRoot₂ := by decide

theorem duplicate_roots : honestDatumRoot schema entry₁.2 = some appRoot₁ ∧
    honestDatumRoot schema entry₂.2 = some appRoot₂ := by decide

theorem duplicate_acceptance :
    verifyLedger (policyFor true) acceptedRoot session answer₁ = .ok appRoot₁ ∧
    verifyLedger (policyFor true) acceptedRoot session answer₂ = .ok appRoot₂ := by decide

theorem duplicate_not_one_shot : ¬ OneShot (ledgerFor true) asset carries := by
  intro unique
  exact duplicate_distinct.1 (unique point entry₁ duplicate_members.1 duplicate_assets.1
    entry₂ duplicate_members.2 duplicate_assets.2)

theorem duplicate_retained_premises :
    WitnessSound (policyFor true) (ledgerFor true) honestRoot ∧
    ObjectEncodingFaithful (policyFor true) ∧
    AssetObservationSound (policyFor true) carries ∧
    DatumObservationSound (policyFor true) honestDatumRoot ∧
    acceptedRoot = honestRoot session.selectedPoint :=
  ⟨fixture_witness_sound true, fixture_encoding_faithful true,
    fixture_asset_sound true, fixture_datum_sound true, rfl⟩

-- Constructive contradiction of the exact intended unique-output conclusion.
theorem duplicate_refutes_soundness_without_one_shot :
    ¬ LedgerSoundnessWithoutOneShot verifyLedger := by
  intro sound
  obtain ⟨entry, _, _, _, unique⟩ := sound (policyFor true) (ledgerFor true)
    honestRoot carries honestDatumRoot acceptedRoot session answer₁ appRoot₁
    (fixture_witness_sound true) (fixture_encoding_faithful true)
    (fixture_asset_sound true) (fixture_datum_sound true) rfl duplicate_acceptance.1
  have first := unique entry₁ duplicate_members.1 duplicate_assets.1
  have second := unique entry₂ duplicate_members.2 duplicate_assets.2
  exact duplicate_distinct.1 (first.trans second.symm)

end Lockness.Counterexamples.LedgerExamples
