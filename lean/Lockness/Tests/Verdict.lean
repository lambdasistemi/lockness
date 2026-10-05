import Lockness.VerdictProofs
import Lockness.Counterexamples.VerdictPromotion

namespace Lockness.Tests.Verdict
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples

-- Released declarations and signatures.
example : Binding → Binding → Bool := fun first second => decide (first = second)
example (point : Chainpoint) : Binding := .bound point
example : Binding := .unbound
example (transaction : Bytes) (spent : List (TxIn × TxOut)) : Reconstruction := ⟨transaction, spent⟩
example (policy : Policy) : Bool := policy.verifier
example (answer : LedgerAnswer) : Option Witness := answer.witness
example (answer : LedgerAnswer) : Option Reconstruction := answer.reconstruction
example (session : Session) : Binding := session.binding
example : List Reason := [.noWitness, .unboundSession, .noVerifier]
example (claim : Claim) (refusal : Refusal) (reason : Reason) : List Verdict :=
  [.verified claim, .refused refusal, .unverified reason]
example : Chainpoint → Provider → Option Reason := unverifiedReason
example : Policy → List Publication → Chainpoint → Provider → Builder → Verdict := verdict
example : Option Reconstruction → Session → Session := Session.withReconstruction
example : NoPromotion verdict := verdict_no_promotion
example : VerdictSoundness verdict := verdict_sound
example : VerdictProviderInvariance verdict := verdict_provider_invariant

-- Ruled statements, ascribed in full so that any change to a statement fails here.
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (claim : Claim) :
    verdict policy publications selectedPoint provider builder = .verified claim ↔
      policy.verifier = true ∧ accept policy publications selectedPoint provider builder = .ok claim :=
  verdict_verified_iff policy publications selectedPoint provider builder claim
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (claim : Claim)
    (success : accept policy publications selectedPoint provider builder = .ok claim) :
    ∃ session witness, provider selectedPoint = some session ∧
      session.selectedPoint = selectedPoint ∧ session.binding = .bound selectedPoint ∧
      session.ledger.witness = some witness :=
  accept_bound_witnessed policy publications selectedPoint provider builder claim success
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (refusal : Refusal)
    (refused : verdict policy publications selectedPoint provider builder = .refused refusal) :
    policy.verifier = true ∧ accept policy publications selectedPoint provider builder = .error refusal :=
  verdict_refused policy publications selectedPoint provider builder refusal refused
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (refusal : Refusal)
    (refused : verdict policy publications selectedPoint provider builder = .refused refusal) :
    refusal.selectedPoint = selectedPoint :=
  verdict_refusal policy publications selectedPoint provider builder refusal refused
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (reason : Reason)
    (unverified : verdict policy publications selectedPoint provider builder = .unverified reason) :
    (reason = .noVerifier ∧ policy.verifier = false) ∨
    (policy.verifier = true ∧
      (∃ refusal, accept policy publications selectedPoint provider builder = .error refusal) ∧
      ∃ session, provider selectedPoint = some session ∧ session.selectedPoint = selectedPoint ∧
        ((reason = .unboundSession ∧ session.binding = .unbound) ∨
         (reason = .noWitness ∧ session.binding = .bound selectedPoint ∧
           session.ledger.witness = none))) :=
  verdict_unverified policy publications selectedPoint provider builder reason unverified
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session) (witness : Witness)
    (configured : policy.verifier = true) (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.witness = some witness) :
    ∀ reason, verdict policy publications selectedPoint provider builder ≠ .unverified reason :=
  witnessed_never_unverified policy publications selectedPoint provider builder session witness
    configured offered samePoint bound present
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (unbound : session.binding = .unbound)
    (inContext : outOfContext policy publications selectedPoint = false) :
    (∃ reason, verdict policy publications selectedPoint provider builder = .unverified reason) ∧
      ∀ claim, accept policy publications selectedPoint provider builder ≠ .ok claim :=
  unbound_only_unverified policy publications selectedPoint provider builder session offered
    samePoint unbound inContext
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session) (point : Chainpoint) (root : Root)
    (configured : policy.verifier = true) (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (bound : session.binding = .bound point)
    (distinct : point ≠ selectedPoint)
    (rootAccepted : acceptRoot policy publications selectedPoint = .ok root) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  misbound_refused policy publications selectedPoint provider builder session point root
    configured offered samePoint bound distinct rootAccepted
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session) (point : Chainpoint)
    (configured : policy.verifier = true) (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (bound : session.binding = .bound point)
    (distinct : point ≠ selectedPoint) :
    ∃ refusal, verdict policy publications selectedPoint provider builder = .refused refusal ∧
      accept policy publications selectedPoint provider builder = .error refusal :=
  misbound_never_unverified policy publications selectedPoint provider builder session point
    configured offered samePoint bound distinct
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (reconstruction : Option Reconstruction) :
    verdict policy publications selectedPoint
        (fun point => (provider point).map (Session.withReconstruction reconstruction)) builder =
      verdict policy publications selectedPoint provider builder :=
  verdict_reconstruction_irrelevant policy publications selectedPoint provider builder reconstruction

-- Finite outcomes of the seven offers, each evaluated by the real verdict and accept.
theorem verified_outcome :
    verdict policy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    accept policy publications selected verifiedProvider builder = .ok oneLinkClaim ∧
    verifiedSession.ledger.reconstruction = some reconstruction := by decide

theorem no_witness_outcome :
    verdict policy publications selected noWitnessProvider builder = .unverified .noWitness ∧
    accept policy publications selected noWitnessProvider builder =
      .error (.evidenceFailure selected) := by decide

theorem unbound_outcome :
    verdict policy publications selected unboundProvider builder = .unverified .unboundSession ∧
    accept policy publications selected unboundProvider builder =
      .error (.evidenceFailure selected) ∧
    unboundSession.ledger.witness = verifiedSession.ledger.witness := by decide

theorem no_verifier_outcome :
    verdict noVerifierPolicy publications selected verifiedProvider builder =
      .unverified .noVerifier ∧
    accept noVerifierPolicy publications selected verifiedProvider builder = .ok oneLinkClaim := by
  decide

-- With the verifier off nothing is consulted, even when the provider offers nothing.
theorem no_verifier_without_offer :
    verdict noVerifierPolicy publications selected (fun _ => none) builder =
      .unverified .noVerifier := by decide

theorem wrong_witness_outcome :
    verdict policy publications selected wrongWitnessProvider builder =
      .refused (.evidenceFailure selected) ∧
    accept policy publications selected wrongWitnessProvider builder =
      .error (.evidenceFailure selected) := by decide

theorem misbound_outcome :
    verdict policy publications selected misboundProvider builder =
      .refused (.evidenceFailure selected) ∧
    accept policy publications selected misboundProvider builder =
      .error (.evidenceFailure selected) ∧
    otherPoint ≠ selected := by decide

theorem promoted_outcome :
    verdict policy publications selected promotingProvider builder = .unverified .noWitness ∧
    accept policy publications selected promotingProvider builder =
      .error (.evidenceFailure selected) := by decide

-- The verified claim is accept's claim and the honest semantic claim, not a fallback.
theorem verified_claim_semantic :
    semanticClaim false LedgerExamples.entry₁ finalQuery = some oneLinkClaim := by decide

-- The impostor's honest claim exists and differs from the honest one.
theorem promoted_claim_semantic :
    semanticClaim false LedgerExamples.impostor finalQuery = some substitutedClaim ∧
    substitutedClaim ≠ oneLinkClaim := by decide

-- Replacing the offered reconstruction leaves each fixture's verdict unchanged.
theorem reconstruction_replaced :
    verdict policy publications selected
      (fun point => (verifiedProvider point).map (Session.withReconstruction none)) builder =
      .verified oneLinkClaim := by decide

end Lockness.Tests.Verdict
