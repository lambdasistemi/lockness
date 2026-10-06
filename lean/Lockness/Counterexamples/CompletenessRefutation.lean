import Lockness.Counterexamples.CompletenessFixtures

namespace Lockness.Counterexamples.CompletenessExamples
open AppExamples LedgerExamples VerdictExamples

-- The operation-parameterized refutations are rebuilt unchanged against every executable mutant,
-- where their premise is discharged by evaluating the mutated production. The statement mutant
-- that drops CompletenessSound rejects them, so only the part before the marker is rebuilt there.

-- The frozen EntriesSoundness with exactly the CompletenessSound premise removed.
def EntriesSoundnessWithoutCompleteness
    (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim) : Prop :=
  ∀ policy publications selectedPoint keyPrefix provider claim (ledger : Ledger) honestRoot layout,
    HonestRootCorrespondence policy publications honestRoot →
    ObjectEncodingFaithful policy →
    operation policy publications selectedPoint keyPrefix provider = .ok claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      claim.keyPrefix = keyPrefix ∧
      ∀ entry, entry ∈ claim.entries ↔
        entry ∈ ledger selectedPoint ∧ UnderPrefix layout keyPrefix entry

-- The real acceptEntries under a check that violates CompletenessSound accepts the listing
-- omitting entry₃, so the statement without that premise is false.
theorem unsound_refutes : ¬ EntriesSoundnessWithoutCompleteness acceptEntries := by
  intro sound
  obtain ⟨_, _, _, exact⟩ := sound permissivePolicy publications selected prefixA
    (offer (answerOf prefixA [entry₁])) ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ (ledgerOf false)
    honestRoot layout (complete_correspondence false) (complete_faithful false) (by decide)
  have missing := (exact entry₃).2 ⟨by decide, (under_iff _ _).1 (by decide)⟩
  exact absurd missing (by decide)

-- The refutations below consume the frozen statements' premise lists.

-- An operation that accepts the listing omitting entry₃ as all of prefixA is unsound.
theorem omitted_refutes_entries
    (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim)
    (accepted : operation (completePolicy false) publications selected prefixA
      (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩) :
    ¬ EntriesSoundness operation := by
  intro sound
  obtain ⟨_, _, _, exact⟩ := sound (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁])) _ (ledgerOf false) honestRoot layout
    (complete_correspondence false) (fixture_completeness_sound false) (complete_faithful false)
    accepted
  have missing := (exact entry₃).2 ⟨by decide, (under_iff _ _).1 (by decide)⟩
  exact absurd missing (by decide)

-- An operation that accepts a proof for the narrower prefix as all of prefixA is unsound.
theorem narrowed_refutes_entries
    (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim)
    (accepted : operation (completePolicy false) publications selected prefixA
      (offer (answerOf narrowPrefix [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩) :
    ¬ EntriesSoundness operation := by
  intro sound
  obtain ⟨_, _, _, exact⟩ := sound (completePolicy false) publications selected prefixA
    (offer (answerOf narrowPrefix [entry₁])) _ (ledgerOf false) honestRoot layout
    (complete_correspondence false) (fixture_completeness_sound false) (complete_faithful false)
    accepted
  have missing := (exact entry₃).2 ⟨by decide, (under_iff _ _).1 (by decide)⟩
  exact absurd missing (by decide)

-- An operation that accepts the asset listing omitting entry₂ on the duplicate ledger is unsound.
theorem omitted_asset_refutes
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root)
    (accepted : operation (completePolicy true) acceptedRoot (offerVia providerRootA) omittingAnswer =
      .ok appRoot₁) :
    ¬ CompleteLedgerSoundness operation := by
  intro sound
  obtain ⟨entry, _, _, _, unique⟩ := sound (completePolicy true) (ledgerOf true) honestRoot carries
    honestDatumRoot layout acceptedRoot (offerVia providerRootA) omittingAnswer appRoot₁
    (answerOf (assetKeyPrefix asset) [entry₁]) (complete_faithful true) (complete_asset_sound true)
    (complete_datum_sound true) (fixture_completeness_sound true) (fixture_asset_layout true) rfl rfl
    accepted
  have first := unique entry₁ (by decide) (by decide)
  have second := unique entry₂ (by decide) (by decide)
  exact absurd (first.trans second.symm) (by decide)

-- An operation that accepts an answer without completeness under a policy requiring it, on the
-- duplicate ledger, is unsound.
theorem bare_required_refutes
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root)
    (accepted : operation (requiredPolicy true) acceptedRoot (offerVia providerRootA)
      (offerVia providerRootA).ledger = .ok appRoot₁) :
    ¬ RequiredCompleteLedgerSoundness operation := by
  intro sound
  obtain ⟨entry, _, _, _, unique⟩ := sound (requiredPolicy true) (ledgerOf true) honestRoot carries
    honestDatumRoot layout acceptedRoot (offerVia providerRootA) (offerVia providerRootA).ledger
    appRoot₁ (complete_faithful true) (complete_asset_sound true) (complete_datum_sound true)
    (fixture_completeness_sound true) (fixture_asset_layout true) rfl rfl accepted
  have first := unique entry₁ (by decide) (by decide)
  have second := unique entry₂ (by decide) (by decide)
  exact absurd (first.trans second.symm) (by decide)

end Lockness.Counterexamples.CompletenessExamples
