import Lockness.Counterexamples.VerdictFixtures

namespace Lockness.Counterexamples.VerdictExamples
open AppExamples

-- Only operation-parameterized refutations live here: this module is rebuilt against every
-- verdict mutant, so it asserts no concrete verdict or accept outcome that a mutant changes.

-- Parameterized by the compiled mutant that treats an absent witness as checked.
theorem promoted_refutes_no_promotion
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (promoted : operation policy publications selected promotingProvider builder =
      .verified substitutedClaim) :
    ¬ NoPromotion operation := by
  intro noPromotion
  obtain ⟨_, session, witness, offered, _, _, present, _⟩ :=
    noPromotion policy publications selected promotingProvider builder substitutedClaim promoted
  cases offered
  -- The only offered session carries no witness.
  exact nomatch present

-- Every VerdictSoundness premise is inhabited; the promoted datum root is not the honest one.
theorem promoted_refutes_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (promoted : operation policy publications selected promotingProvider builder =
      .verified substitutedClaim) :
    ¬ VerdictSoundness operation := by
  intro sound
  obtain ⟨_, _, _, entry, member, _, _, datum, _⟩ := sound policy publications selected
    promotingProvider builder substitutedClaim (LedgerExamples.ledgerFor false)
    LedgerExamples.honestRoot LedgerExamples.carries LedgerExamples.honestDatumRoot (treeFor false)
    honestNext (fixture_correspondence false finalQuery) (fixture_witness_sound false finalQuery)
    (fixture_encoding_faithful false finalQuery) (fixture_asset_sound false finalQuery)
    (fixture_datum_sound false finalQuery) (fixture_one_shot false finalQuery)
    (fixture_app_sound false finalQuery) (fixture_nesting false finalQuery) promoted
  simp only [LedgerExamples.ledgerFor, Bool.false_eq_true, ↓reduceIte,
    Finset.mem_singleton] at member
  subst entry
  have different : LedgerExamples.honestDatumRoot policy.schema LedgerExamples.entry₁.2 ≠
      some substitutedClaim.appRoot := by decide
  exact different datum

-- Parameterized by the compiled mutant that ignores the declared verifier.
theorem verifier_refutes_no_promotion
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (promoted : operation noVerifierPolicy publications selected verifiedProvider builder =
      .verified oneLinkClaim) :
    ¬ NoPromotion operation := by
  intro noPromotion
  obtain ⟨configured, _⟩ :=
    noPromotion noVerifierPolicy publications selected verifiedProvider builder oneLinkClaim promoted
  exact absurd configured (by decide)

end Lockness.Counterexamples.VerdictExamples
