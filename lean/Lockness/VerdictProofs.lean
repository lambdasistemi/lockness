import Lockness.Verdict
import Lockness.AcceptProofs

namespace Lockness

-- Accept never succeeds without a session bound to the selected point and a witness.
theorem accept_bound_witnessed (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (claim : Claim)
    (success : accept policy publications selectedPoint provider builder = .ok claim) :
    ∃ session witness, provider selectedPoint = some session ∧
      session.selectedPoint = selectedPoint ∧ session.binding = .bound selectedPoint ∧
      session.ledger.witness = some witness := by
  obtain ⟨root, session, appRoot, _, _, _, acquired, verified, _, _⟩ :=
    accept_observations policy publications selectedPoint provider builder claim success
  have samePoint : session.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider session acquired
  obtain ⟨_, bound, _, _, _, _, ⟨witness, present, _⟩, _⟩ :=
    verifyLedger_observations policy root session session.ledger appRoot verified
  exact ⟨session, witness, acquire_preserves_offer selectedPoint provider session acquired,
    samePoint, by rw [bound, samePoint], present⟩

theorem verdict_verified_iff (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (claim : Claim) :
    verdict policy publications selectedPoint provider builder = .verified claim ↔
      policy.verifier = true ∧ accept policy publications selectedPoint provider builder = .ok claim := by
  unfold verdict
  cases configured : policy.verifier
  · simp
  · cases accept policy publications selectedPoint provider builder with
    | ok found => simp
    | error refusal =>
      cases outOfContext policy publications selectedPoint <;>
        cases unverifiedReason selectedPoint provider <;> simp

theorem verdict_no_promotion : NoPromotion verdict := by
  intro policy publications selectedPoint provider builder claim verified
  obtain ⟨configured, accepted⟩ :=
    (verdict_verified_iff policy publications selectedPoint provider builder claim).mp verified
  obtain ⟨session, witness, offered, samePoint, bound, present⟩ :=
    accept_bound_witnessed policy publications selectedPoint provider builder claim accepted
  exact ⟨configured, session, witness, offered, samePoint, bound, present, accepted⟩

-- Soundness applies unchanged to every verified claim: no promotion, then accept_sound.
theorem verdict_sound : VerdictSoundness verdict := by
  intro policy publications selectedPoint provider builder claim ledger honestRoot carries
    honestDatumRoot tree honestNext correspondence witnessSound encodingFaithful assetSound
    datumSound oneShot appSound nesting verified
  obtain ⟨_, _, _, _, _, _, _, accepted⟩ :=
    verdict_no_promotion policy publications selectedPoint provider builder claim verified
  exact accept_sound policy publications selectedPoint provider builder claim ledger honestRoot
    carries honestDatumRoot tree honestNext correspondence witnessSound encodingFaithful assetSound
    datumSound oneShot appSound nesting accepted

theorem verdict_provider_invariant : VerdictProviderInvariance verdict := by
  intro policy publications selectedPoint provider₁ provider₂ builder₁ builder₂ claim₁ claim₂
    ledger honestRoot carries honestDatumRoot tree correspondence witnessSound encodingFaithful
    assetSound datumSound oneShot appSound functional verified₁ verified₂
  obtain ⟨_, _, _, _, _, _, _, accepted₁⟩ :=
    verdict_no_promotion policy publications selectedPoint provider₁ builder₁ claim₁ verified₁
  obtain ⟨_, _, _, _, _, _, _, accepted₂⟩ :=
    verdict_no_promotion policy publications selectedPoint provider₂ builder₂ claim₂ verified₂
  exact accept_provider_invariant policy publications selectedPoint provider₁ provider₂ builder₁
    builder₂ claim₁ claim₂ ledger honestRoot carries honestDatumRoot tree correspondence
    witnessSound encodingFaithful assetSound datumSound oneShot appSound functional accepted₁
    accepted₂

-- Every refused verdict is accept's own refusal under a configured verifier.
theorem verdict_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (refusal : Refusal)
    (refused : verdict policy publications selectedPoint provider builder = .refused refusal) :
    policy.verifier = true ∧ accept policy publications selectedPoint provider builder = .error refusal := by
  unfold verdict at refused
  split at refused
  · rename_i configured
    split at refused
    · cases refused
    · rename_i failure accepted
      split at refused
      · cases refused
        exact ⟨configured, accepted⟩
      · split at refused
        · cases refused
        · cases refused
          exact ⟨configured, accepted⟩
  · cases refused

theorem verdict_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (refusal : Refusal)
    (refused : verdict policy publications selectedPoint provider builder = .refused refusal) :
    refusal.selectedPoint = selectedPoint :=
  accept_refusal policy publications selectedPoint provider builder refusal
    (verdict_refused policy publications selectedPoint provider builder refusal refused).2

-- An unverified verdict arises only from a declared absence and never hides a claim.
theorem verdict_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (reason : Reason)
    (unverified : verdict policy publications selectedPoint provider builder = .unverified reason) :
    (reason = .noVerifier ∧ policy.verifier = false) ∨
    (policy.verifier = true ∧
      (∃ refusal, accept policy publications selectedPoint provider builder = .error refusal) ∧
      ∃ session, provider selectedPoint = some session ∧ session.selectedPoint = selectedPoint ∧
        ((reason = .unboundSession ∧ session.binding = .unbound) ∨
         (reason = .noWitness ∧ session.binding = .bound selectedPoint ∧
           session.ledger.witness = none))) := by
  unfold verdict at unverified
  split at unverified
  · rename_i configured
    split at unverified
    · cases unverified
    · rename_i failure accepted
      split at unverified
      · cases unverified
      · split at unverified
        · rename_i found reasonEq
          cases unverified
          refine Or.inr ⟨configured, ⟨failure, accepted⟩, ?_⟩
          unfold unverifiedReason at reasonEq
          split at reasonEq
          · cases reasonEq
          · rename_i session acquired
            refine ⟨session, acquire_preserves_offer selectedPoint provider session acquired,
              acquire_no_substitution selectedPoint provider session acquired, ?_⟩
            split at reasonEq
            · rename_i unbound
              cases reasonEq
              exact Or.inl ⟨rfl, unbound⟩
            · split at reasonEq
              · rename_i bound
                split at reasonEq
                · rename_i absent
                  cases reasonEq
                  exact Or.inr ⟨rfl, bound, absent⟩
                · cases reasonEq
              · cases reasonEq
        · cases unverified
  · rename_i unconfigured
    cases unverified
    exact Or.inl ⟨rfl, by simpa using unconfigured⟩

-- A present witness on a bound session is never unverified: wrong evidence is refused.
theorem witnessed_never_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (witness : Witness) (configured : policy.verifier = true)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.witness = some witness) :
    ∀ reason, verdict policy publications selectedPoint provider builder ≠ .unverified reason := by
  intro reason unverified
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, bound, present]
  unfold verdict at unverified
  rw [if_pos configured] at unverified
  split at unverified
  · cases unverified
  · simp [noReason] at unverified

-- In context, a session offered at the selected point and declared unbound yields only unverified.
theorem unbound_only_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (unbound : session.binding = .unbound)
    (inContext : outOfContext policy publications selectedPoint = false) :
    (∃ reason, verdict policy publications selectedPoint provider builder = .unverified reason) ∧
      ∀ claim, accept policy publications selectedPoint provider builder ≠ .ok claim := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have reasonUnbound : unverifiedReason selectedPoint provider = some .unboundSession := by
    simp [unverifiedReason, acquired, unbound]
  have neverOk : ∀ claim, accept policy publications selectedPoint provider builder ≠ .ok claim := by
    intro claim accepted
    obtain ⟨found, _, offeredFound, _, bound, _⟩ :=
      accept_bound_witnessed policy publications selectedPoint provider builder claim accepted
    rw [offered] at offeredFound
    cases offeredFound
    simp [unbound] at bound
  refine ⟨?_, neverOk⟩
  unfold verdict
  cases configured : policy.verifier
  · exact ⟨.noVerifier, by simp⟩
  · cases accepted : accept policy publications selectedPoint provider builder with
    | ok claim => exact absurd accepted (neverOk claim)
    | error refusal => exact ⟨.unboundSession, by simp [reasonUnbound, inContext]⟩

-- With the root accepted, a session bound to another point is refused as evidence failure.
theorem misbound_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (point : Chainpoint) (root : Root) (configured : policy.verifier = true)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (bound : session.binding = .bound point)
    (distinct : point ≠ selectedPoint)
    (rootAccepted : acceptRoot policy publications selectedPoint = .ok root) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, bound, distinct]
  have ledgerRefused : verifyLedger policy root session session.ledger =
      .error (.evidenceFailure selectedPoint) := by
    cases verified : verifyLedger policy root session session.ledger with
    | ok appRoot =>
      obtain ⟨_, boundHere, _⟩ :=
        verifyLedger_observations policy root session session.ledger appRoot verified
      rw [bound, samePoint] at boundHere
      exact absurd (Binding.bound.inj boundHere) distinct
    | error refusal =>
      rw [verifyLedger_refusal policy root session session.ledger refusal verified, samePoint]
  have accepted : accept policy publications selectedPoint provider builder =
      .error (.evidenceFailure selectedPoint) := by
    -- Out of context, the guard refuses with the same evidenceFailure before acquisition.
    cases outside : outOfContext policy publications selectedPoint
    · simp [accept, acceptContextRoot, outside, rootAccepted, acquired, ledgerRefused]
    · simp [accept, acceptContextRoot, outside]
  simp [verdict, configured, accepted, noReason]

-- Without a root premise, a misbound session is still refused, never unverified.
theorem misbound_never_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (point : Chainpoint) (configured : policy.verifier = true)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint) (bound : session.binding = .bound point)
    (distinct : point ≠ selectedPoint) :
    ∃ refusal, verdict policy publications selectedPoint provider builder = .refused refusal ∧
      accept policy publications selectedPoint provider builder = .error refusal := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, bound, distinct]
  have neverOk : ∀ claim, accept policy publications selectedPoint provider builder ≠ .ok claim := by
    intro claim accepted
    obtain ⟨found, _, offeredFound, _, boundFound, _⟩ :=
      accept_bound_witnessed policy publications selectedPoint provider builder claim accepted
    rw [offered] at offeredFound
    cases offeredFound
    rw [bound] at boundFound
    exact distinct (Binding.bound.inj boundFound)
  cases accepted : accept policy publications selectedPoint provider builder with
  | ok claim => exact absurd accepted (neverOk claim)
  | error refusal => exact ⟨refusal, by simp [verdict, configured, accepted, noReason], rfl⟩

-- Reconstruction is read by no guard: replacing it leaves accept and the reason unchanged.
theorem withReconstruction_ledger_verified (policy : Policy) (root : Root) (session : Session)
    (reconstruction : Option Reconstruction) :
    verifyLedger policy root (session.withReconstruction reconstruction)
        (session.withReconstruction reconstruction).ledger =
      verifyLedger policy root session session.ledger := rfl

theorem verdict_reconstruction_irrelevant (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (reconstruction : Option Reconstruction) :
    verdict policy publications selectedPoint
        (fun point => (provider point).map (Session.withReconstruction reconstruction)) builder =
      verdict policy publications selectedPoint provider builder := by
  have samePointField : ∀ session : Session,
      (session.withReconstruction reconstruction).selectedPoint = session.selectedPoint :=
    fun _ => rfl
  have sameBinding : ∀ session : Session,
      (session.withReconstruction reconstruction).binding = session.binding := fun _ => rfl
  have sameWitness : ∀ session : Session,
      (session.withReconstruction reconstruction).ledger.witness = session.ledger.witness :=
    fun _ => rfl
  have sameAccept : accept policy publications selectedPoint
      (fun point => (provider point).map (Session.withReconstruction reconstruction)) builder =
      accept policy publications selectedPoint provider builder := by
    cases rooted : acceptContextRoot policy publications selectedPoint with
    | error refusal => simp [accept, rooted]
    | ok root =>
      cases offered : provider selectedPoint with
      | none => simp [accept, rooted, acquire, offered]
      | some session =>
        by_cases same : session.selectedPoint = selectedPoint
        · simp [accept, rooted, acquire, offered, Session.point, samePointField, same,
            withReconstruction_ledger_verified]
        · simp [accept, rooted, acquire, offered, Session.point, samePointField, same]
  have sameReason : unverifiedReason selectedPoint
      (fun point => (provider point).map (Session.withReconstruction reconstruction)) =
      unverifiedReason selectedPoint provider := by
    cases offered : provider selectedPoint with
    | none => simp [unverifiedReason, acquire, offered]
    | some session =>
      by_cases same : session.selectedPoint = selectedPoint
      · simp [unverifiedReason, acquire, offered, Session.point, samePointField, same,
          sameBinding, sameWitness]
      · simp [unverifiedReason, acquire, offered, Session.point, samePointField, same]
  simp only [verdict, sameAccept, sameReason]

end Lockness
