import Lockness.Counterexamples.LedgerFixtures

namespace Lockness.Counterexamples.LedgerExamples

-- Every surrounding observation succeeds. Only the checking-root choice discriminates.
theorem substituted_surrounding_conditions :
    substitutedAnswer.point = session.selectedPoint ∧
    session.binding = .bound session.selectedPoint ∧
    (policyFor false).decodeObject substitutedAnswer.object = some impostor ∧
    (policyFor false).objectBytes impostor = substitutedAnswer.object ∧
    (policyFor false).assetOf impostor.2 = some asset ∧
    (policyFor false).datumOf impostor.2 = some appRoot₃.bytes ∧
    (policyFor false).parseDatum schema appRoot₃.bytes = some appRoot₃ ∧
    substitutedAnswer.witness = some witness ∧
    (policyFor false).checkWitness witness
      substitutedAnswer.root substitutedAnswer.object = true ∧
    (policyFor false).checkWitness witness
      acceptedRoot substitutedAnswer.object = false := by decide

-- Parameterized by the real compiled production mutant, preserving LedgerSoundness.
theorem substituted_root_refutes_soundness
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root)
    (accepted : operation (policyFor false) acceptedRoot session substitutedAnswer = .ok appRoot₃) :
    ¬ LedgerSoundness operation := by
  intro sound
  obtain ⟨entry, member, _, datum, _⟩ := sound (policyFor false) (ledgerFor false)
    honestRoot carries honestDatumRoot acceptedRoot session substitutedAnswer appRoot₃
    (fixture_witness_sound false) (fixture_encoding_faithful false)
    (fixture_asset_sound false) (fixture_datum_sound false) honest_one_shot rfl accepted
  simp only [ledgerFor, Bool.false_eq_true, ↓reduceIte, Finset.mem_singleton] at member
  subst entry
  have different : honestDatumRoot schema entry₁.2 ≠ some appRoot₃ := by decide
  exact different datum

end Lockness.Counterexamples.LedgerExamples
