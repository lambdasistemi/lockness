import Lockness.AcceptProofs
import Lockness.Counterexamples.AppRootMutation
import Lockness.Counterexamples.AppAmbiguity

namespace Lockness.Tests.App
open Counterexamples Counterexamples.AppExamples

-- Released signatures; partial application of verifyApp has the issue's promised type.
example : Policy → Chainpoint → Root → AppAnswer → Except Refusal AppValue := verifyApp
example (policy : Policy) (selectedPoint : Chainpoint) :
    Root → AppAnswer → Except Refusal AppValue := verifyApp policy selectedPoint
example : Policy → Chainpoint → Builder → Nat → Root → Except Refusal (List Root × AppValue) :=
  verifyChain
example : Policy → List Publication → Chainpoint → Provider → Builder → Except Refusal Claim :=
  accept
example : Builder = (Root → Option AppAnswer) := rfl
example : AppTree = (Root → Set (AppQuery × AppValue)) := rfl
example : AcceptSoundness accept := accept_sound
example : ProviderInvariance accept := accept_provider_invariant
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (refusal : Refusal)
    (failure : accept policy publications selectedPoint provider builder = .error refusal) :
    refusal.selectedPoint = selectedPoint :=
  accept_refusal policy publications selectedPoint provider builder refusal failure
example (policy : Policy) (selectedPoint : Chainpoint) (root : Root) (answer : AppAnswer)
    (claimed : answer.root ≠ root) :
    verifyApp policy selectedPoint root answer = .error (.evidenceFailure selectedPoint) :=
  verifyApp_claimed_root_first policy selectedPoint root answer claimed

def onePolicy : Policy := appPolicy false finalQuery
def twoPolicy : Policy := appPolicy false nestedQuery

-- Every expected claim is evaluated from honest semantics, and none is the fallback.
theorem semantic_claims_defined :
    (semanticClaim false LedgerExamples.entry₁ finalQuery).isSome ∧
    (semanticClaim false LedgerExamples.entry₁ nestedQuery).isSome ∧
    (semanticClaim false LedgerExamples.impostor finalQuery).isSome ∧
    (semanticClaim true LedgerExamples.entry₁ finalQuery).isSome := by decide

theorem claim_shapes : oneLinkClaim.links.length = 0 ∧ nestedClaim.links.length = 1 := by decide

-- Untrusted roots and proof bytes differ; none is the independently accepted root.
theorem untrusted_inputs_differ :
    providerRootA ≠ providerRootB ∧ providerRootA ≠ LedgerExamples.acceptedRoot ∧
    providerRootB ≠ LedgerExamples.acceptedRoot ∧ proofA ≠ proofB := by decide

theorem honest_one_link :
    accept onePolicy publications selected providerA (honestBuilder false proofA finalQuery) =
      .ok oneLinkClaim ∧
    accept onePolicy publications selected providerB (honestBuilder false proofB finalQuery) =
      .ok oneLinkClaim := by decide

theorem honest_nested :
    accept twoPolicy publications selected providerA (honestBuilder false proofA nestedQuery) =
      .ok nestedClaim ∧
    accept twoPolicy publications selected providerB (honestBuilder false proofB nestedQuery) =
      .ok nestedClaim := by decide

-- One fixture inhabits every premise of both statements together with successful acceptance.
theorem jointly_inhabited (query : AppQuery) :
    HonestRootCorrespondence (appPolicy false query) publications LedgerExamples.honestRoot ∧
    WitnessSound (appPolicy false query) (LedgerExamples.ledgerFor false)
      LedgerExamples.honestRoot ∧
    ObjectEncodingFaithful (appPolicy false query) ∧
    AssetObservationSound (appPolicy false query) LedgerExamples.carries ∧
    DatumObservationSound (appPolicy false query) LedgerExamples.honestDatumRoot ∧
    OneShot (LedgerExamples.ledgerFor false) (appPolicy false query).asset
      LedgerExamples.carries ∧
    AppSound (appPolicy false query) (treeFor false) ∧ AppFunctional (treeFor false) ∧
    NestingInterpretationFaithful (appPolicy false query) honestNext :=
  ⟨fixture_correspondence false query, fixture_witness_sound false query,
    fixture_encoding_faithful false query, fixture_asset_sound false query,
    fixture_datum_sound false query, fixture_one_shot false query,
    fixture_app_sound false query, fixture_app_functional, fixture_nesting false query⟩

theorem one_link_sound :
    oneLinkClaim.point = selected ∧ oneLinkClaim.ledgerRoot = LedgerExamples.honestRoot selected ∧
    holds onePolicy LedgerExamples.carries LedgerExamples.honestDatumRoot (treeFor false)
      honestNext (LedgerExamples.ledgerFor false selected) oneLinkClaim := by
  obtain ⟨c, w, e, a, d, o, s, _, n⟩ := jointly_inhabited finalQuery
  exact accept_sound onePolicy publications selected providerA
    (honestBuilder false proofA finalQuery) oneLinkClaim (LedgerExamples.ledgerFor false)
    LedgerExamples.honestRoot LedgerExamples.carries LedgerExamples.honestDatumRoot
    (treeFor false) honestNext c w e a d o s n honest_one_link.1

theorem nested_sound :
    nestedClaim.point = selected ∧ nestedClaim.ledgerRoot = LedgerExamples.honestRoot selected ∧
    holds twoPolicy LedgerExamples.carries LedgerExamples.honestDatumRoot (treeFor false)
      honestNext (LedgerExamples.ledgerFor false selected) nestedClaim := by
  obtain ⟨c, w, e, a, d, o, s, _, n⟩ := jointly_inhabited nestedQuery
  exact accept_sound twoPolicy publications selected providerB
    (honestBuilder false proofB nestedQuery) nestedClaim (LedgerExamples.ledgerFor false)
    LedgerExamples.honestRoot LedgerExamples.carries LedgerExamples.honestDatumRoot
    (treeFor false) honestNext c w e a d o s n honest_nested.2

-- Invariance is applied to two providers and two builders with every premise inhabited.
theorem nested_invariant : nestedClaim = nestedClaim := by
  obtain ⟨c, w, e, a, d, o, s, f, _⟩ := jointly_inhabited nestedQuery
  exact accept_provider_invariant twoPolicy publications selected providerA providerB
    (honestBuilder false proofA nestedQuery) (honestBuilder false proofB nestedQuery)
    nestedClaim nestedClaim (LedgerExamples.ledgerFor false) LedgerExamples.honestRoot
    LedgerExamples.carries LedgerExamples.honestDatumRoot (treeFor false) c w e a d o s f
    honest_nested.1 honest_nested.2

-- Replaced root: the real verifier refuses, whatever proof is valid under the claimed root.
theorem replaced_root_refusal :
    accept onePolicy publications selected providerA replacingBuilder =
      .error (.evidenceFailure selected) := by decide

theorem replaced_root_first :
    verifyApp onePolicy selected LedgerExamples.appRoot₁ replacedAnswer =
      .error (.evidenceFailure selected) :=
  verifyApp_claimed_root_first onePolicy selected LedgerExamples.appRoot₁ replacedAnswer
    replaced_root_surrounding_conditions.2.1

theorem true_root_forged_refusal :
    accept onePolicy publications selected providerA trueRootForgedBuilder =
      .error (.evidenceFailure selected) := by decide

-- Session root: the real fold checks the ledger under the accepted root and refuses.
theorem substituted_ledger_refusal :
    accept onePolicy publications selected substitutingProvider
      (honestBuilder false proofA finalQuery) = .error (.evidenceFailure selected) := by decide

-- First-link guards: each changes one field of an otherwise honest answer.
def firstLink (change : AppAnswer → AppAnswer) : Builder := fun root =>
  (honestBuilder false proofA finalQuery root).map change

theorem point_guard : accept onePolicy publications selected providerA
    (firstLink fun answer => { answer with point := { selected with slot := selected.slot + 1 } }) =
    .error (.evidenceFailure selected) := by decide

theorem application_guard : accept onePolicy publications selected providerA
    (firstLink fun answer => { answer with application := [99] }) =
    .error (.evidenceFailure selected) := by decide

theorem context_guard : accept onePolicy publications selected providerA
    (firstLink fun answer => { answer with context := [99] }) =
    .error (.evidenceFailure selected) := by decide

theorem claim_guard : accept onePolicy publications selected providerA
    (firstLink fun answer => { answer with claim := [99] }) =
    .error (.evidenceFailure selected) := by decide

theorem proof_guard : accept onePolicy publications selected providerA
    (firstLink fun answer => { answer with proof := badProof }) =
    .error (.evidenceFailure selected) := by decide

theorem absent_builder_refusal :
    accept onePolicy publications selected providerA (fun _ => none) =
      .error (.evidenceFailure selected) := by decide

-- Second-link failures reject the whole claim; no partial claim is returned.
theorem second_link_bad_proof : accept twoPolicy publications selected providerA
    (secondLinkBuilder fun answer => some { answer with proof := badProof }) =
    .error (.evidenceFailure selected) := by decide

theorem second_link_replaced_root : accept twoPolicy publications selected providerA
    (secondLinkBuilder fun answer => some { answer with root := otherRoot, value := forgedValue }) =
    .error (.evidenceFailure selected) := by decide

theorem second_link_absent : accept twoPolicy publications selected providerA
    (secondLinkBuilder fun _ => none) = .error (.evidenceFailure selected) := by decide

theorem second_link_point : accept twoPolicy publications selected providerA
    (secondLinkBuilder fun answer =>
      some { answer with point := { selected with blockHash := [99] } }) =
    .error (.evidenceFailure selected) := by decide

theorem second_link_claim : accept twoPolicy publications selected providerA
    (secondLinkBuilder fun answer => some { answer with claim := finalQuery.claim }) =
    .error (.evidenceFailure selected) := by decide

theorem second_link_proof_valid_alone :
    (secondLinkBuilder fun answer => some { answer with root := otherRoot, value := forgedValue })
      innerRoot = some (answerFor proofA nestedQuery otherRoot forgedValue) ∧
    twoPolicy.checkApp proofA otherRoot nestedQuery forgedValue = true := by decide

-- Fuel counts checked links: exhaustion with a further root pending refuses the claim.
theorem fuel_one_refusal : accept { twoPolicy with fuel := 1 } publications selected providerA
    (honestBuilder false proofA nestedQuery) = .error (.evidenceFailure selected) := by decide

theorem fuel_zero_refusal : accept { twoPolicy with fuel := 0 } publications selected providerA
    (honestBuilder false proofA nestedQuery) = .error (.evidenceFailure selected) := by decide

theorem fuel_one_suffices_for_one_link : accept { onePolicy with fuel := 1 } publications selected
    providerA (honestBuilder false proofA finalQuery) = .ok oneLinkClaim := by decide

-- Root and session refusals keep their constructors and the selected point.
theorem no_root_refusal :
    accept onePolicy [] selected providerA (honestBuilder false proofA finalQuery) =
      .error (.noRoot selected) := by decide

theorem unavailable_refusal :
    accept onePolicy publications selected (fun _ => none) (honestBuilder false proofA finalQuery) =
      .error (.unavailablePoint selected) := by decide

theorem chain_links_checked :
    verifyChain twoPolicy selected (honestBuilder false proofA nestedQuery) 2
      LedgerExamples.appRoot₁ = .ok (nestedClaim.links, nestedClaim.value) := by decide

end Lockness.Tests.App
