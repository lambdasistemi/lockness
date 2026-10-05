import Lockness.ContextStatements
import Lockness.Counterexamples.VerdictFixtures

namespace Lockness.Counterexamples.ContextExamples
open AppExamples VerdictExamples

-- The #28 offers, read through two abstract signature models and one abstract message model.
-- The decoder and the signature table are fixture framing, not a message or signature format.

-- The selected point's slot and block hash on network [1].
def foreignPoint : Chainpoint := { selected with network := [1] }
def honestMessage : Bytes := honestPublication.message
def foreignMessage : Bytes := [255, 1, 255]
def foreignSignature : Bytes := [1, 255, 1]

-- Each fixture message names one point and one root; every other message names nothing.
def decodeMessage (message : Bytes) : Option (Chainpoint × Root) :=
  if message = honestMessage then some (honestPublication.point, honestPublication.root)
  else if message = foreignMessage then some (foreignPoint, honestPublication.root)
  else none

-- The signature each trusted fixture key gives each fixture message.
def signatures : List (Key × Bytes × Bytes) :=
  [([1], honestMessage, honestPublication.signature), ([2], honestMessage, honestPublication.signature),
   ([1], foreignMessage, foreignSignature), ([2], foreignMessage, foreignSignature)]

def signed (publication : Publication) : Bool :=
  decide ((publication.key, publication.message, publication.signature) ∈ signatures)

-- A message encodes exactly what the fixture decoder gives for it.
@[reducible] def fixtureMessages : MessageModel := ⟨fun message point root => decodeMessage message = some (point, root)⟩

-- A valid signature is in the table, over a message naming its publication's own point and root.
@[reducible] def honestSignatures : SignatureModel :=
  ⟨fun publication => signed publication = true ∧
    decodeMessage publication.message = some (publication.point, publication.root)⟩

-- A valid signature is in the table; what the message names is not read.
@[reducible] def signatureOnly : SignatureModel := ⟨fun publication => signed publication = true⟩

-- The #28 policy observing exactly honestSignatures, in the neutral context.
def contextPolicy : Policy :=
  { policy with
    verify := fun publication => signed publication &&
      decide (decodeMessage publication.message = some (publication.point, publication.root)) }

-- The #28 policy observing signatures only.
def signatureOnlyPolicy : Policy := { policy with verify := signed }

-- The terminal configured for network [1]; the selected point stays on network [0].
def wrongNetworkPolicy : Policy :=
  { contextPolicy with context := { contextPolicy.context with network := foreignPoint.network } }

-- The terminal accepting only scheme [1]; the honest root uses scheme [0].
def unacceptedSchemePolicy : Policy :=
  { contextPolicy with context := { contextPolicy.context with schemes := [[1]] } }

-- A trusted key's verified publication of the honest root at the selected slot and block hash,
-- on network [1].
def foreignPublication : Publication :=
  { honestPublication with point := foreignPoint, message := foreignMessage,
                           signature := foreignSignature }

-- The honest publications moved to network [1]: the only endorsements are foreign.
def onlyForeign : List Publication := publications.map fun publication =>
  { publication with point := foreignPoint, message := foreignMessage,
                     signature := foreignSignature }

-- At the selected point on network [0], signed over messages that name network [1].
def unboundMessagePublications : List Publication := publications.map fun publication =>
  { publication with message := foreignMessage, signature := foreignSignature }

theorem contextPolicy_observation_sound (context : Context) :
    @ObservationSound honestSignatures { contextPolicy with context := context } := by
  intro publication verified
  simp only [contextPolicy, Bool.and_eq_true, decide_eq_true_eq] at verified
  exact verified

theorem signatureOnly_observation_sound : @ObservationSound signatureOnly signatureOnlyPolicy :=
  fun _ verified => verified

theorem fixture_message_binding : @MessageBinding honestSignatures fixtureMessages := by
  unfold MessageBinding
  refine ⟨fun _ valid => valid.2, ?_⟩
  intro message point root point' root' first second
  have same : some (point, root) = some (point', root') :=
    (show decodeMessage message = some (point, root) from first).symm.trans second
  cases same
  exact ⟨rfl, rfl⟩

-- A message the decoder maps to one point and root encodes exactly that point and root.
theorem encodes_exactly (message : Bytes) (point : Chainpoint) (root : Root)
    (decoded : decodeMessage message = some (point, root)) (point' : Chainpoint) (root' : Root) :
    @MessageModel.encodes fixtureMessages message point' root' ↔ point' = point ∧ root' = root := by
  show decodeMessage message = some (point', root') ↔ _
  rw [decoded]
  constructor
  · intro same
    cases same
    exact ⟨rfl, rfl⟩
  · rintro ⟨rfl, rfl⟩
    rfl

-- Both honest publications carry a valid signature over a message naming their own point and root.
theorem honest_signatures_valid (publication : Publication) (member : publication ∈ publications) :
    @SigValid honestSignatures publication := by
  simp only [publications, List.mem_cons, List.not_mem_nil, or_false] at member
  show signed publication = true ∧
    decodeMessage publication.message = some (publication.point, publication.root)
  rcases member with rfl | rfl <;> exact ⟨by decide, by decide⟩

-- The jointly inhabited honest input: both abstract premises, the verified verdict and the
-- context conclusion at that input.
theorem context_honest_witness :
    @ObservationSound honestSignatures contextPolicy ∧
    @MessageBinding honestSignatures fixtureMessages ∧
    verdict contextPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    @ContextConclusion honestSignatures fixtureMessages contextPolicy publications oneLinkClaim := by
  refine ⟨contextPolicy_observation_sound contextPolicy.context, fixture_message_binding,
    by decide, ?_⟩
  have decoded : decodeMessage honestMessage = some (oneLinkClaim.point, oneLinkClaim.ledgerRoot) := by
    decide
  unfold ContextConclusion
  refine ⟨by decide, by decide, [[1], [2]], by decide, ?_⟩
  intro key member
  simp only [List.mem_cons, List.not_mem_nil, or_false] at member
  rcases member with rfl | rfl
  · exact ⟨by decide, honestPublication, by decide, rfl, by decide, by decide,
      honest_signatures_valid honestPublication (by decide), encodes_exactly honestMessage _ _ decoded⟩
  · exact ⟨by decide, secondPublication, by decide, rfl, by decide, by decide,
      honest_signatures_valid secondPublication (by decide), encodes_exactly honestMessage _ _ decoded⟩

end Lockness.Counterexamples.ContextExamples
