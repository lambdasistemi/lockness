import Lockness.Counterexamples.ActFixtures

namespace Lockness.Counterexamples.ActExamples
open AppExamples VerdictExamples

-- Only refutations live here: this module is rebuilt against every effect mutant, so it asserts
-- no concrete act outcome that a mutant changes. The settled effect at settledChain survives
-- every production mutant.

-- Parameterized by the compiled mutant without the settlement guard: an effect authorized at the
-- unsettled tip, then the admitted rollback that leaves the selected point non-canonical.
theorem settlement_dropped_refutes
    (operation : Policy → Action → Verdict → Provider → Chainpoint → Chain →
      Except Refusal Authorized)
    (authorizes : operation settledPolicy .effect (.verified oneLinkClaim) verifiedProvider selected
      tipChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩) :
    ¬ @SettlementStability fixtureConsensus operation := by
  intro stable
  unfold SettlementStability at stable
  -- Applied premise by premise, so the module also compiles against the consensus-dropped mutant.
  have reached := stable settledPolicy (.verified oneLinkClaim) verifiedProvider selected tipChain
    ⟨.effect, selected, .claim oneLinkClaim⟩ fixture_continued_ancestry authorizes rolledChain
    rolled_extends
  have kept : canonical selected rolledChain := by
    apply reached
    all_goals exact rolled_admitted
  exact absurd kept (by decide)

-- Without the consensus premise, settlement stability is false on the real act: a point settled
-- in settledChain is rolled back deeper than the fixture consensus admits (deep_not_admitted).
theorem consensus_dropped_refutes :
    ¬ (∀ (policy : Policy) (verdict : Verdict) (provider : Provider) (selectedPoint : Chainpoint)
        (chain : Chain) (authorized : Authorized), @ContinuedAncestry fixtureConsensus policy →
        act policy .effect verdict provider selectedPoint chain = .ok authorized →
        ∀ chain', Extends chain chain' → canonical selectedPoint chain') := by
  intro stable
  have kept := stable settledPolicy (.verified oneLinkClaim) verifiedProvider selected settledChain
    ⟨.effect, selected, .claim oneLinkClaim⟩ fixture_continued_ancestry (by decide) deepChain
    deep_extends
  exact absurd kept (by decide)

end Lockness.Counterexamples.ActExamples
