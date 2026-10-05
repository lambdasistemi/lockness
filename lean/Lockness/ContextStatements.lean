import Lockness.Verdict

namespace Lockness

-- A verified claim is in the declared context, and every endorsement counted for it is a
-- trusted key's valid signature over a message encoding exactly the claim's point and root.
def ContextConclusion [SignatureModel] [MessageModel] (policy : Policy)
    (publications : List Publication) (claim : Claim) : Prop :=
  claim.point.network = policy.context.network ∧
  claim.ledgerRoot.scheme ∈ policy.context.schemes ∧
  ∃ keys : List Key, Candidate policy keys ∧
    ∀ key ∈ keys, key ∈ policy.trustedKeys ∧
      ∃ publication ∈ publications, publication.key = key ∧
        publication.point = claim.point ∧ publication.root = claim.ledgerRoot ∧
        SigValid publication ∧
        ∀ point root, MessageModel.encodes publication.message point root ↔
          point = claim.point ∧ root = claim.ledgerRoot

-- Context soundness holds under the observation and message-binding hypotheses only.
def ContextSoundness [SignatureModel] [MessageModel]
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) : Prop :=
  ∀ policy publications selectedPoint provider builder claim,
    ObservationSound policy → MessageBinding →
    operation policy publications selectedPoint provider builder = .verified claim →
    ContextConclusion policy publications claim

end Lockness
