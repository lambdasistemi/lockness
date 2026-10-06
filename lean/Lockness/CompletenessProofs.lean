import Lockness.Completeness
import Lockness.AcceptProofs
import Lockness.VerdictProofs

namespace Lockness

-- Inversion records every entries guard: point, binding, the offered answer for the requested
-- prefix, its check under the given root, and the decoded entries re-encoding to the listing.
theorem verifyEntries_observations (policy : Policy) (acceptedRoot : Root) (session : Session)
    (keyPrefix : Bytes) (decoded : List (TxIn × TxOut))
    (success : verifyEntries policy acceptedRoot session keyPrefix = .ok decoded) :
    session.ledger.point = session.selectedPoint ∧
    session.binding = .bound session.selectedPoint ∧
    ∃ answer, session.ledger.completeness = some answer ∧ answer.keyPrefix = keyPrefix ∧
      policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries = true ∧
      answer.entries.mapM policy.decodeObject = some decoded ∧
      decoded.map policy.objectBytes = answer.entries := by
  unfold verifyEntries at success
  split at success
  · rename_i pointEq
    split at success
    · rename_i bound
      split at success
      · cases success
      · rename_i answer offered
        split at success
        · rename_i prefixEq
          split at success
          · rename_i checked
            split at success
            · cases success
            · rename_i listed mapped
              split at success
              · rename_i encoded
                cases success
                exact ⟨pointEq, bound, answer, offered, prefixEq, checked, mapped, encoded⟩
              · cases success
          · cases success
        · cases success
    · cases success
  · cases success

theorem verifyEntries_refusal (policy : Policy) (acceptedRoot : Root) (session : Session)
    (keyPrefix : Bytes) (refusal : Refusal)
    (failure : verifyEntries policy acceptedRoot session keyPrefix = .error refusal) :
    refusal = .evidenceFailure session.selectedPoint := by
  unfold verifyEntries at failure
  repeat' split at failure
  all_goals first | (cases failure; rfl) | cases failure

theorem acceptEntries_observations (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (keyPrefix : Bytes) (provider : Provider) (claim : EntriesClaim)
    (success : acceptEntries policy publications selectedPoint keyPrefix provider = .ok claim) :
    ∃ root session, acceptRoot policy publications selectedPoint = .ok root ∧
      acquire selectedPoint provider = .ok session ∧
      verifyEntries policy root session keyPrefix = .ok claim.entries ∧
      claim = ⟨selectedPoint, root, keyPrefix, claim.entries⟩ := by
  unfold acceptEntries at success
  split at success
  · cases success
  · rename_i root inContext
    -- The context guard only refuses; an accepted root in context is acceptRoot's root.
    have accepted : acceptRoot policy publications selectedPoint = .ok root := by
      unfold acceptContextRoot at inContext
      split at inContext
      · cases inContext
      · exact inContext
    split at success
    · cases success
    · rename_i session acquired
      split at success
      · cases success
      · rename_i entries verified
        cases success
        exact ⟨root, session, accepted, acquired, verified, rfl⟩

theorem acceptEntries_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (keyPrefix : Bytes) (provider : Provider) (refusal : Refusal)
    (failure : acceptEntries policy publications selectedPoint keyPrefix provider = .error refusal) :
    refusal.selectedPoint = selectedPoint := by
  unfold acceptEntries at failure
  split at failure
  · rename_i rejected
    cases failure
    -- The context guard refuses with evidenceFailure; acceptRoot only with noRoot.
    unfold acceptContextRoot at rejected
    split at rejected
    · cases rejected
      rfl
    · have same := acceptRoot_refusal policy publications selectedPoint _ rejected
      subst same
      rfl
  · split at failure
    · rename_i unavailable
      cases failure
      have same := acquire_refusal selectedPoint provider _ unavailable
      subst same
      rfl
    · rename_i session acquired
      split at failure
      · rename_i rejected
        cases failure
        have same := verifyEntries_refusal policy _ session keyPrefix _ rejected
        subst same
        exact acquire_no_substitution selectedPoint provider session acquired
      · cases failure

theorem acceptEntries_never_adopts (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (keyPrefix : Bytes) (provider : Provider) (claim : EntriesClaim)
    (success : acceptEntries policy publications selectedPoint keyPrefix provider = .ok claim) :
    claim.point = selectedPoint := by
  obtain ⟨_, _, _, _, _, claimEq⟩ :=
    acceptEntries_observations policy publications selectedPoint keyPrefix provider claim success
  exact congrArg EntriesClaim.point claimEq

-- An accepted all-entries claim lists exactly the honest entries under the requested prefix.
-- The guards are read from verifyEntries inside this proof, so a mutant guard breaks it here.
theorem accept_entries_sound : EntriesSoundness acceptEntries := by
  intro policy publications selectedPoint keyPrefix provider claim ledger honestRoot layout
    correspondence complete faithful accepted
  obtain ⟨root, session, rootAccepted, _, verified, claimEq⟩ :=
    acceptEntries_observations policy publications selectedPoint keyPrefix provider claim accepted
  have honest : root = honestRoot selectedPoint :=
    acceptRoot_honest policy publications selectedPoint root honestRoot rootAccepted correspondence
  unfold verifyEntries at verified
  split at verified
  · split at verified
    · split at verified
      · cases verified
      · rename_i answer _
        split at verified
        · split at verified
          · rename_i checked
            split at verified
            · cases verified
            · split at verified
              · rename_i encoded
                cases verified
                -- The listing checks under the accepted root for the requested prefix.
                have listing := complete selectedPoint answer.proof root keyPrefix answer.entries
                  honest checked
                rw [claimEq]
                refine ⟨rfl, honest, rfl, ?_⟩
                intro entry
                constructor
                · intro member
                  have inList : policy.objectBytes entry ∈ answer.entries := by
                    rw [← encoded]; exact List.mem_map_of_mem member
                  obtain ⟨other, otherMember, under, same⟩ := (listing _).1 inList
                  rw [faithful same] at otherMember under
                  exact ⟨otherMember, under⟩
                · rintro ⟨member, under⟩
                  have inList := (listing (policy.objectBytes entry)).2 ⟨entry, member, under, rfl⟩
                  rw [← encoded] at inList
                  obtain ⟨other, otherMember, same⟩ := List.mem_map.1 inList
                  rw [← faithful same]; exact otherMember
              · cases verified
          · cases verified
        · cases verified
    · cases verified
  · cases verified

-- A successful ledger step with a completeness answer records the whole completeness guard.
theorem verifyLedger_completeness (policy : Policy) (acceptedRoot : Root) (session : Session)
    (answer : LedgerAnswer) (appRoot : Root) (completeness : CompletenessAnswer)
    (offered : answer.completeness = some completeness)
    (success : verifyLedger policy acceptedRoot session answer = .ok appRoot) :
    completeness.keyPrefix = policy.assetPrefix policy.asset ∧
    completeness.entries = [answer.object] ∧
    policy.checkCompleteness completeness.proof acceptedRoot completeness.keyPrefix
      completeness.entries = true := by
  unfold verifyLedger at success
  split at success
  · split at success
    · split at success
      · cases success
      · split at success
        · split at success
          · split at success
            · rename_i holds
              rw [offered] at holds
              simpa [Option.all, and_assoc] using holds
            · cases success
          · cases success
        · cases success
    · cases success
  · cases success

-- A successful ledger step under a policy requiring completeness had a completeness answer.
theorem verifyLedger_required (policy : Policy) (acceptedRoot : Root) (session : Session)
    (answer : LedgerAnswer) (appRoot : Root) (required : policy.requireCompleteness = true)
    (success : verifyLedger policy acceptedRoot session answer = .ok appRoot) :
    ∃ completeness, answer.completeness = some completeness := by
  cases offered : answer.completeness with
  | some completeness => exact ⟨completeness, rfl⟩
  | none =>
    exfalso
    unfold verifyLedger at success
    split at success
    · split at success
      · split at success
        · cases success
        · split at success
          · split at success
            · split at success
              · rename_i holds
                simp [offered, required] at holds
              · cases success
            · cases success
          · cases success
      · cases success
    · cases success

-- Uniqueness of the state output by completeness of the asset prefix, with no OneShot and no
-- WitnessSound premise. The guard is read from verifyLedger inside this proof.
theorem verifyLedger_complete_sound : CompleteLedgerSoundness verifyLedger := by
  intro policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot
    completeness faithful assetSound datumSound complete layoutSound correspondence offered accepted
  have guard : completeness.keyPrefix = policy.assetPrefix policy.asset ∧
      completeness.entries = [answer.object] ∧
      policy.checkCompleteness completeness.proof acceptedRoot completeness.keyPrefix
        completeness.entries = true := by
    unfold verifyLedger at accepted
    split at accepted
    · split at accepted
      · split at accepted
        · cases accepted
        · split at accepted
          · split at accepted
            · split at accepted
              · rename_i holds
                rw [offered] at holds
                simpa [Option.all, and_assoc] using holds
              · cases accepted
            · cases accepted
          · cases accepted
      · cases accepted
    · cases accepted
  obtain ⟨prefixEq, listed, checked⟩ := guard
  obtain ⟨_, _, entry, _, _, encoded, _, asset, observed, parsed⟩ :=
    verifyLedger_observations policy acceptedRoot session answer appRoot accepted
  -- The checked listing is exactly the honest object bytes under the asset prefix.
  have listing := complete session.selectedPoint completeness.proof acceptedRoot
    completeness.keyPrefix completeness.entries correspondence checked
  rw [listed, prefixEq] at listing
  have member : entry ∈ ledger session.selectedPoint := by
    obtain ⟨other, otherMember, _, same⟩ := (listing answer.object).1 (List.mem_singleton_self _)
    rw [← encoded] at same
    rw [← faithful same]; exact otherMember
  have carried := assetSound entry.2 policy.asset asset
  refine ⟨entry, member, carried, datumSound _ _ _ _ observed parsed, ?_⟩
  intro other otherMember otherCarried
  have inList := (listing (policy.objectBytes other)).2
    ⟨other, otherMember, layoutSound other otherCarried, rfl⟩
  rw [List.mem_singleton, ← encoded] at inList
  exact faithful inList

-- The terminal's requirement in place of the offered answer: whatever the provider sends, an
-- accepted state output is unique without OneShot. The requirement is read from verifyLedger
-- inside this proof.
theorem verifyLedger_required_complete_sound : RequiredCompleteLedgerSoundness verifyLedger := by
  intro policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot
    faithful assetSound datumSound complete layoutSound correspondence required accepted
  have present : ∃ completeness, answer.completeness = some completeness := by
    cases offered : answer.completeness with
    | some completeness => exact ⟨completeness, rfl⟩
    | none =>
      exfalso
      unfold verifyLedger at accepted
      split at accepted
      · split at accepted
        · split at accepted
          · cases accepted
          · split at accepted
            · split at accepted
              · split at accepted
                · rename_i holds
                  simp [offered, required] at holds
                · cases accepted
              · cases accepted
            · cases accepted
        · cases accepted
      · cases accepted
  obtain ⟨completeness, offered⟩ := present
  exact verifyLedger_complete_sound policy ledger honestRoot carries honestDatumRoot layout
    acceptedRoot session answer appRoot completeness faithful assetSound datumSound complete
    layoutSound correspondence offered accepted

-- K2: a session bound to the selected point that carries a completeness answer is never
-- unverified.
theorem completeness_never_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (completeness : CompletenessAnswer) (configured : policy.verifier = true)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.completeness = some completeness) :
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
  · split at unverified
    · cases unverified
    · simp [noReason] at unverified

-- Present and wrong completeness evidence is refused at the selected point, never unverified.
theorem completeness_wrong_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (completeness : CompletenessAnswer) (root : Root) (configured : policy.verifier = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.completeness = some completeness)
    (wrong : ¬ (completeness.keyPrefix = policy.assetPrefix policy.asset ∧
      completeness.entries = [session.ledger.object] ∧
      policy.checkCompleteness completeness.proof root completeness.keyPrefix
        completeness.entries = true)) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have ledgerFails : ∃ refusal, verifyLedger policy root session session.ledger = .error refusal := by
    cases verified : verifyLedger policy root session session.ledger with
    | ok appRoot =>
      exact absurd (verifyLedger_completeness policy root session session.ledger appRoot
        completeness present verified) wrong
    | error refusal => exact ⟨refusal, rfl⟩
  obtain ⟨refusal, failed⟩ := ledgerFails
  have isFailure := verifyLedger_refusal policy root session session.ledger refusal failed
  rw [samePoint] at isFailure
  subst isFailure
  have rejected : accept policy publications selectedPoint provider builder =
      .error (.evidenceFailure selectedPoint) := by
    simp [accept, rootAccepted, acquired, failed]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, bound, present]
  unfold verdict
  rw [if_pos configured, rejected]
  simp [noReason]

-- C1: a witnessed answer missing the completeness a policy requires is refused, never
-- unverified.
theorem required_absent_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (session : Session)
    (root : Root) (witness : Witness) (configured : policy.verifier = true)
    (required : policy.requireCompleteness = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (absent : session.ledger.completeness = none)
    (witnessed : session.ledger.witness = some witness) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have ledgerFails : ∃ refusal, verifyLedger policy root session session.ledger = .error refusal := by
    cases verified : verifyLedger policy root session session.ledger with
    | ok appRoot =>
      obtain ⟨_, present⟩ := verifyLedger_required policy root session session.ledger appRoot
        required verified
      rw [absent] at present; cases present
    | error refusal => exact ⟨refusal, rfl⟩
  obtain ⟨refusal, failed⟩ := ledgerFails
  have isFailure := verifyLedger_refusal policy root session session.ledger refusal failed
  rw [samePoint] at isFailure
  subst isFailure
  have rejected : accept policy publications selectedPoint provider builder =
      .error (.evidenceFailure selectedPoint) := by
    simp [accept, rootAccepted, acquired, failed]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, bound, witnessed]
  unfold verdict
  rw [if_pos configured, rejected]
  simp [noReason]

end Lockness
