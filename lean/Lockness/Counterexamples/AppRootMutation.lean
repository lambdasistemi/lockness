import Lockness.Counterexamples.AppFixtures

namespace Lockness.Counterexamples.AppExamples

-- Every guard except the claimed-root comparison passes; the proof is valid only there.
theorem replaced_root_surrounding_conditions :
    replacingBuilder LedgerExamples.appRoot₁ = some replacedAnswer ∧
    replacedAnswer.root ≠ LedgerExamples.appRoot₁ ∧
    replacedAnswer.point = selected ∧
    replacedAnswer.application = finalQuery.application ∧
    replacedAnswer.context = finalQuery.context ∧
    replacedAnswer.claim = finalQuery.claim ∧
    (appPolicy false finalQuery).checkApp replacedAnswer.proof replacedAnswer.root finalQuery
      replacedAnswer.value = true ∧
    (appPolicy false finalQuery).checkApp replacedAnswer.proof LedgerExamples.appRoot₁ finalQuery
      replacedAnswer.value = false := by decide

-- The ledger answer is valid only under the provider's own root.
theorem substituted_ledger_conditions :
    substitutingProvider selected =
      some ⟨selected, LedgerExamples.providerRoot, LedgerExamples.substitutedAnswer⟩ ∧
    LedgerExamples.providerRoot ≠ LedgerExamples.acceptedRoot ∧
    verifyLedger (appPolicy false finalQuery) LedgerExamples.providerRoot
      ⟨selected, LedgerExamples.providerRoot, LedgerExamples.substitutedAnswer⟩
      LedgerExamples.substitutedAnswer = .ok LedgerExamples.appRoot₃ ∧
    verifyLedger (appPolicy false finalQuery) LedgerExamples.acceptedRoot
      ⟨selected, LedgerExamples.providerRoot, LedgerExamples.substitutedAnswer⟩
      LedgerExamples.substitutedAnswer = .error (.evidenceFailure selected) := by decide

-- Parameterized by the real compiled production mutant, preserving AcceptSoundness.
theorem replaced_root_refutes_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder →
      Except Refusal Claim)
    (accepted : operation (appPolicy false finalQuery) publications selected providerA
      replacingBuilder = .ok forgedClaim) :
    ¬ AcceptSoundness operation := by
  intro sound
  obtain ⟨_, _, _, _, _, _, _, _, chain⟩ := sound (appPolicy false finalQuery) publications
    selected providerA replacingBuilder forgedClaim (LedgerExamples.ledgerFor false)
    LedgerExamples.honestRoot LedgerExamples.carries LedgerExamples.honestDatumRoot
    (treeFor false) honestNext (fixture_correspondence false finalQuery)
    (fixture_witness_sound false finalQuery) (fixture_encoding_faithful false finalQuery)
    (fixture_asset_sound false finalQuery) (fixture_datum_sound false finalQuery)
    (fixture_one_shot false finalQuery) (fixture_app_sound false finalQuery)
    (fixture_nesting false finalQuery) accepted
  have final : forgedClaim.links = [] := by decide
  rw [final] at chain
  obtain ⟨member, _⟩ := chainHolds_nil chain
  have absent : (forgedClaim.appRoot, forgedClaim.query, forgedClaim.value) ∉ contents false := by
    decide
  exact absent member

-- Parameterized by the compiled fold mutant that checks the ledger under the session's root.
theorem session_root_refutes_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder →
      Except Refusal Claim)
    (accepted : operation (appPolicy false finalQuery) publications selected substitutingProvider
      (honestBuilder false proofA finalQuery) = .ok substitutedClaim) :
    ¬ AcceptSoundness operation := by
  intro sound
  obtain ⟨_, _, _, entry, member, _, _, datum, _⟩ := sound (appPolicy false finalQuery)
    publications selected substitutingProvider (honestBuilder false proofA finalQuery)
    substitutedClaim (LedgerExamples.ledgerFor false) LedgerExamples.honestRoot
    LedgerExamples.carries LedgerExamples.honestDatumRoot (treeFor false) honestNext
    (fixture_correspondence false finalQuery) (fixture_witness_sound false finalQuery)
    (fixture_encoding_faithful false finalQuery) (fixture_asset_sound false finalQuery)
    (fixture_datum_sound false finalQuery) (fixture_one_shot false finalQuery)
    (fixture_app_sound false finalQuery) (fixture_nesting false finalQuery) accepted
  simp only [LedgerExamples.ledgerFor, Bool.false_eq_true, ↓reduceIte,
    Finset.mem_singleton] at member
  subst entry
  have different : LedgerExamples.honestDatumRoot (appPolicy false finalQuery).schema
      LedgerExamples.entry₁.2 ≠ some substitutedClaim.appRoot := by decide
  exact different datum

end Lockness.Counterexamples.AppExamples
