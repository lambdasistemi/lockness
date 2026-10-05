import Lockness.ContextProofs
import Lockness.Counterexamples.ContextRefutation

namespace Lockness.Tests.Context
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples
open Counterexamples.ContextExamples

-- Released declarations and signatures.
example (network : Bytes) (schemes : List Bytes) : Context := ⟨network, schemes⟩
example (context : Context) : Bytes × List Bytes := (context.network, context.schemes)
example : Context → Context → Bool := fun first second => decide (first = second)
example (policy : Policy) : Context := policy.context
example (policy : Policy) : Bool := policy.verifier
example [MessageModel] : Bytes → Chainpoint → Root → Prop := MessageModel.encodes
example : Policy → List Publication → Chainpoint → Bool := outOfContext
example : Policy → List Publication → Chainpoint → Except Refusal Root := acceptContextRoot

-- Ruled definitions, ascribed in full so that any change to a definition fails here.
example [SignatureModel] [MessageModel] : MessageBinding ↔
    ((∀ publication, SigValid publication →
      MessageModel.encodes publication.message publication.point publication.root) ∧
    ∀ message point root point' root', MessageModel.encodes message point root →
      MessageModel.encodes message point' root' → point = point' ∧ root = root') := Iff.rfl
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint) :
    outOfContext policy publications selectedPoint =
      (decide (selectedPoint.network ≠ policy.context.network) ||
        match acceptRoot policy publications selectedPoint with
        | .ok root => decide (root.scheme ∉ policy.context.schemes)
        | .error _ => false) := rfl
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint) :
    acceptContextRoot policy publications selectedPoint =
      if outOfContext policy publications selectedPoint then .error (.evidenceFailure selectedPoint)
      else acceptRoot policy publications selectedPoint := rfl
example [SignatureModel] [MessageModel] (policy : Policy) (publications : List Publication)
    (claim : Claim) :
    ContextConclusion policy publications claim ↔
      (claim.point.network = policy.context.network ∧
        claim.ledgerRoot.scheme ∈ policy.context.schemes ∧
        ∃ keys : List Key, Candidate policy keys ∧
          ∀ key ∈ keys, key ∈ policy.trustedKeys ∧
            ∃ publication ∈ publications, publication.key = key ∧
              publication.point = claim.point ∧ publication.root = claim.ledgerRoot ∧
              SigValid publication ∧
              ∀ point root, MessageModel.encodes publication.message point root ↔
                point = claim.point ∧ root = claim.ledgerRoot) := Iff.rfl
example [SignatureModel] [MessageModel]
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) :
    ContextSoundness operation ↔
      ∀ policy publications selectedPoint provider builder claim,
        ObservationSound policy → MessageBinding →
        operation policy publications selectedPoint provider builder = .verified claim →
        ContextConclusion policy publications claim := Iff.rfl

-- Ruled statements, ascribed in full.
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (refusal : Refusal)
    (failure : acceptContextRoot policy publications selectedPoint = .error refusal) :
    refusal = .noRoot selectedPoint ∨ refusal = .evidenceFailure selectedPoint :=
  acceptContextRoot_refusal policy publications selectedPoint refusal failure
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (root : Root) (success : acceptContextRoot policy publications selectedPoint = .ok root) :
    acceptRoot policy publications selectedPoint = .ok root ∧
      outOfContext policy publications selectedPoint = false ∧
      selectedPoint.network = policy.context.network ∧ root.scheme ∈ policy.context.schemes :=
  acceptContextRoot_in_context policy publications selectedPoint root success
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (claim : Claim)
    (success : accept policy publications selectedPoint provider builder = .ok claim) :
    claim.point.network = policy.context.network ∧
      claim.ledgerRoot.scheme ∈ policy.context.schemes :=
  accept_in_context policy publications selectedPoint provider builder claim success
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder)
    (outside : outOfContext policy publications selectedPoint = true) :
    accept policy publications selectedPoint provider builder =
      .error (.evidenceFailure selectedPoint) :=
  out_of_context_refused policy publications selectedPoint provider builder outside
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (configured : policy.verifier = true)
    (outside : outOfContext policy publications selectedPoint = true) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  out_of_context_never_unverified policy publications selectedPoint provider builder configured
    outside
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (configured : policy.verifier = true)
    (other : selectedPoint.network ≠ policy.context.network) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  wrong_network_refused policy publications selectedPoint provider builder configured other
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (configured : policy.verifier = true) (root : Root)
    (rootAccepted : acceptRoot policy publications selectedPoint = .ok root)
    (unaccepted : root.scheme ∉ policy.context.schemes) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  unaccepted_scheme_refused policy publications selectedPoint provider builder configured root
    rootAccepted unaccepted
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (others : List Publication)
    (foreign : ∀ other ∈ others, other.point.network ≠ policy.context.network) :
    acceptContextRoot policy (publications ++ others) selectedPoint =
        acceptContextRoot policy publications selectedPoint ∧
      accept policy (publications ++ others) selectedPoint provider builder =
        accept policy publications selectedPoint provider builder ∧
      verdict policy (publications ++ others) selectedPoint provider builder =
        verdict policy publications selectedPoint provider builder :=
  foreign_publication_ignored policy publications selectedPoint provider builder others foreign
example [SignatureModel] [MessageModel] : ContextSoundness verdict := verdict_context_sound
-- The single restated inherited statement.
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (unbound : session.binding = .unbound)
    (inContext : outOfContext policy publications selectedPoint = false) :
    (∃ reason, verdict policy publications selectedPoint provider builder = .unverified reason) ∧
      ∀ claim, accept policy publications selectedPoint provider builder ≠ .ok claim :=
  unbound_only_unverified policy publications selectedPoint provider builder session offered
    samePoint unbound inContext

-- Fixture statements and refutations.
example :
    @ObservationSound honestSignatures contextPolicy ∧
    @MessageBinding honestSignatures fixtureMessages ∧
    verdict contextPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    @ContextConclusion honestSignatures fixtureMessages contextPolicy publications oneLinkClaim :=
  context_honest_witness
example (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (accepted : operation wrongNetworkPolicy publications selected verifiedProvider builder =
      .verified oneLinkClaim) :
    ¬ @ContextSoundness honestSignatures fixtureMessages operation :=
  guard_removed_refutes_context_soundness operation accepted
example (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (accepted : operation unacceptedSchemePolicy publications selected verifiedProvider builder =
      .verified oneLinkClaim) :
    ¬ @ContextSoundness honestSignatures fixtureMessages operation :=
  scheme_unchecked_refutes_context_soundness operation accepted
example (sound : ∀ policy publications selectedPoint provider builder claim,
      @ObservationSound signatureOnly policy →
      verdict policy publications selectedPoint provider builder = .verified claim →
      @ContextConclusion signatureOnly fixtureMessages policy publications claim) : False :=
  unbound_message_refutes sound

-- The fixture contracts the scenarios rely on, each evaluated.
theorem fixture_contexts :
    contextPolicy.context = ⟨[0], [[0]]⟩ ∧ selected.network = contextPolicy.context.network ∧
    wrongNetworkPolicy.context.network ≠ selected.network ∧
    oneLinkClaim.ledgerRoot.scheme ∉ unacceptedSchemePolicy.context.schemes ∧
    signatureOnlyPolicy.context = contextPolicy.context := by decide

theorem foreign_publication_trusted_and_verified :
    foreignPublication.key ∈ contextPolicy.trustedKeys ∧
    contextPolicy.verify foreignPublication = true ∧
    foreignPublication.point.slot = selected.slot ∧
    foreignPublication.point.blockHash = selected.blockHash ∧
    foreignPublication.point.network ≠ contextPolicy.context.network := by decide

theorem only_foreign_trusted_and_verified :
    ∀ publication ∈ onlyForeign, publication.key ∈ contextPolicy.trustedKeys ∧
      contextPolicy.verify publication = true ∧
      publication.point.network ≠ contextPolicy.context.network := by decide

theorem unbound_messages_name_another_network :
    ∀ publication ∈ unboundMessagePublications, publication.point = selected ∧
      signatureOnlyPolicy.verify publication = true ∧
      contextPolicy.verify publication = false ∧
      decodeMessage publication.message = some (foreignPoint, oneLinkClaim.ledgerRoot) ∧
      foreignPoint.network ≠ contextPolicy.context.network := by decide

-- Finite outcomes of the five scenarios, each evaluated by the real verdict and accept.
theorem honest_outcome :
    verdict contextPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    accept contextPolicy publications selected verifiedProvider builder = .ok oneLinkClaim := by
  decide

theorem wrong_network_point_outcome :
    verdict wrongNetworkPolicy publications selected verifiedProvider builder =
      .refused (.evidenceFailure selected) ∧
    accept wrongNetworkPolicy publications selected verifiedProvider builder =
      .error (.evidenceFailure selected) ∧
    verdict wrongNetworkPolicy publications selected unboundProvider builder =
      .refused (.evidenceFailure selected) ∧
    accept wrongNetworkPolicy publications selected unboundProvider builder =
      .error (.evidenceFailure selected) := by decide

theorem wrong_network_publication_outcome :
    verdict contextPolicy (publications ++ [foreignPublication]) selected verifiedProvider builder =
      .verified oneLinkClaim ∧
    accept contextPolicy (publications ++ [foreignPublication]) selected verifiedProvider builder =
      .ok oneLinkClaim ∧
    verdict contextPolicy onlyForeign selected verifiedProvider builder = .refused (.noRoot selected) ∧
    accept contextPolicy onlyForeign selected verifiedProvider builder = .error (.noRoot selected) := by
  decide

theorem unaccepted_scheme_outcome :
    verdict unacceptedSchemePolicy publications selected verifiedProvider builder =
      .refused (.evidenceFailure selected) ∧
    accept unacceptedSchemePolicy publications selected verifiedProvider builder =
      .error (.evidenceFailure selected) := by decide

theorem unbound_message_outcome :
    verdict signatureOnlyPolicy unboundMessagePublications selected verifiedProvider builder =
      .verified oneLinkClaim ∧
    accept signatureOnlyPolicy unboundMessagePublications selected verifiedProvider builder =
      .ok oneLinkClaim ∧
    verdict contextPolicy unboundMessagePublications selected verifiedProvider builder =
      .refused (.noRoot selected) := by decide

-- Named limit: with the verifier off, an out-of-context selection is unverified noVerifier.
theorem no_verifier_out_of_context :
    verdict { wrongNetworkPolicy with verifier := false } publications selected verifiedProvider
      builder = .unverified .noVerifier := by decide

-- The verified claim is the honest semantic claim.
theorem context_claim_semantic :
    semanticClaim false LedgerExamples.entry₁ finalQuery = some oneLinkClaim := by decide

end Lockness.Tests.Context
