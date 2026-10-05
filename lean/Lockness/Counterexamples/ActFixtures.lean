import Lockness.Act
import Lockness.Counterexamples.ContextFixtures

namespace Lockness.Counterexamples.ActExamples
open AppExamples VerdictExamples ContextExamples

-- Fixture chains around the selected point. The depths and the consensus model below are a
-- witness of the hypotheses, never a parameter of the model.
def b₁ : Chainpoint := { selected with slot := selected.slot + 1, blockHash := [201] }
def b₂ : Chainpoint := { selected with slot := selected.slot + 2, blockHash := [202] }
def f₁ : Chainpoint := { selected with slot := selected.slot + 1, blockHash := [211] }
def f₂ : Chainpoint := { selected with slot := selected.slot + 2, blockHash := [212] }
def f₃ : Chainpoint := { selected with slot := selected.slot + 3, blockHash := [213] }

-- The selected point is the newest block; then two blocks are built on it.
def tipChain : Chain := [[selected]]
def settledChain : Chain := [[selected, b₁, b₂]]
-- The selected block is rolled back, the fork grows, and a settled point is rolled back deeper
-- than the fixture consensus admits.
def rolledChain : Chain := rollback 1 [f₁] tipChain
def regrownChain : Chain := rollback 0 [f₂, f₃] rolledChain
def deepChain : Chain := rollback 3 [f₁] settledChain

-- The canonical branch without its newest two points.
def buried (chain : Chain) : Branch := (tip chain).take ((tip chain).length - 2)

-- A common-prefix consensus: a future is admitted when it keeps every buried point in order.
@[reducible] def fixtureConsensus : ConsensusModel :=
  ⟨fun chain chain' => (buried chain).isPrefixOf (tip chain') = true⟩

-- The #28 policy observing buried points as settled and allowing construction without a witness.
def settledPolicy : Policy :=
  { VerdictExamples.policy with
    settlement := fun point chain => decide (point ∈ buried chain),
    constructUnverified := fun reason => decide (reason = .noWitness) }

def noVerifierSettledPolicy : Policy := { settledPolicy with verifier := false }

-- The terminal configured for network [1] with no verifier; the selected point is on network [0].
def outOfContextNoVerifierPolicy : Policy :=
  { noVerifierSettledPolicy with context := ContextExamples.wrongNetworkPolicy.context }

-- The fixture futures are reachable by Extends.
theorem rolled_extends : Extends tipChain rolledChain := rollback_extends 1 [f₁] tipChain

theorem regrown_extends : Extends tipChain regrownChain :=
  extends_trans rolled_extends (rollback_extends 0 [f₂, f₃] rolledChain)

theorem deep_extends : Extends settledChain deepChain := rollback_extends 3 [f₁] settledChain

-- The fixture consensus admits the shallow rollback, each chain from itself, and not the deep one.
theorem rolled_admitted : @ConsensusModel.admits fixtureConsensus tipChain rolledChain :=
  show (buried tipChain).isPrefixOf (tip rolledChain) = true by decide

theorem rolled_self_admitted : @ConsensusModel.admits fixtureConsensus rolledChain rolledChain :=
  show (buried rolledChain).isPrefixOf (tip rolledChain) = true by decide

theorem deep_not_admitted : ¬ @ConsensusModel.admits fixtureConsensus settledChain deepChain :=
  show ¬ (buried settledChain).isPrefixOf (tip deepChain) = true by decide

-- A point buried in a chain stays in every future the fixture consensus admits.
theorem fixture_continued_ancestry : @ContinuedAncestry fixtureConsensus settledPolicy := by
  intro point chain chain' settled _ admitted
  have buriedPoint : point ∈ buried chain := by
    simpa [settledPolicy] using settled
  have kept : buried chain <+: tip chain' := by
    change (buried chain).isPrefixOf (tip chain') = true at admitted
    simpa [List.isPrefixOf_iff_prefix] using admitted
  exact kept.subset buriedPoint

-- The jointly inhabited witness
-- The hypothesis, the real verified verdict, the settled effect and the unmet condition hold
-- together.
theorem settled_effect_inhabited :
    @ContinuedAncestry fixtureConsensus settledPolicy ∧
    verdict settledPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩ ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected tipChain = .error (.evidenceFailure selected) :=
  ⟨fixture_continued_ancestry, by decide, by decide, by decide⟩

end Lockness.Counterexamples.ActExamples
