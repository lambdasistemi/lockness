import Lockness.History
import Lockness.CompletenessProofs
import Lockness.ContextProofs

namespace Lockness

-- Replacing the history changes no field the ledger check or the absence classification reads.
theorem withHistory_ledger_verified (policy : Policy) (root : Root) (session : Session)
    (history : Option HistoryAnswer) :
    verifyLedger policy root (session.withHistory history) (session.withHistory history).ledger =
      verifyLedger policy root session session.ledger := rfl

-- Inversion: success is exactly the filter, its fold from the initial state and an equal root.
theorem verifyHistory_observations (policy : Policy) (selectedPoint : Chainpoint) (appRoot : Root)
    (answer : HistoryAnswer) (result : HistoryResult)
    (success : verifyHistory policy selectedPoint appRoot answer = .ok result) :
    result.transactions = answer.transactions.filter policy.relevant ∧
      result.state = (answer.transactions.filter policy.relevant).foldl policy.fold policy.initial ∧
      policy.historyRoot result.state = appRoot := by
  simp only [verifyHistory, relevantHistory] at success
  split at success
  · rename_i equal
    cases success
    exact ⟨rfl, rfl, equal⟩
  · cases success

theorem verifyHistory_refusal (policy : Policy) (selectedPoint : Chainpoint) (appRoot : Root)
    (answer : HistoryAnswer) (refusal : Refusal)
    (failure : verifyHistory policy selectedPoint appRoot answer = .error refusal) :
    refusal = .evidenceFailure selectedPoint := by
  simp only [verifyHistory, relevantHistory] at failure
  split at failure
  · cases failure
  · cases failure
    rfl

-- Inversion: every accepted history claim records the steps, in order, and the roots they bound.
theorem acceptHistory_observations (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (claim : HistoryClaim)
    (success : acceptHistory policy publications selectedPoint provider = .ok claim) :
    ∃ root session appRoot answer result,
      acceptContextRoot policy publications selectedPoint = .ok root ∧
      acquire selectedPoint provider = .ok session ∧
      verifyLedger policy root session session.ledger = .ok appRoot ∧
      session.ledger.history = some answer ∧
      verifyHistory policy selectedPoint appRoot answer = .ok result ∧
      claim = ⟨selectedPoint, root, policy.query, appRoot, result⟩ := by
  unfold acceptHistory at success
  split at success
  · cases success
  · rename_i root rooted
    split at success
    · cases success
    · rename_i session acquired
      split at success
      · cases success
      · rename_i appRoot verified
        split at success
        · cases success
        · rename_i answer present
          split at success
          · cases success
          · rename_i result checked
            cases success
            exact ⟨root, session, appRoot, answer, result, rooted, acquired, verified, present,
              checked, rfl⟩

-- Every refusal is one of the inherited constructors at the selected point.
theorem acceptHistory_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (refusal : Refusal)
    (failure : acceptHistory policy publications selectedPoint provider = .error refusal) :
    refusal = .noRoot selectedPoint ∨ refusal = .unavailablePoint selectedPoint ∨
      refusal = .evidenceFailure selectedPoint := by
  unfold acceptHistory at failure
  split at failure
  · rename_i rejected
    cases failure
    rcases acceptContextRoot_refusal policy publications selectedPoint _ rejected with same | same
    · exact Or.inl same
    · exact Or.inr (Or.inr same)
  · split at failure
    · rename_i unavailable
      cases failure
      exact Or.inr (Or.inl (acquire_refusal selectedPoint provider _ unavailable))
    · rename_i session acquired
      split at failure
      · rename_i rejected
        cases failure
        have same := verifyLedger_refusal policy _ session session.ledger _ rejected
        have samePoint : session.selectedPoint = selectedPoint :=
          acquire_no_substitution selectedPoint provider session acquired
        rw [samePoint] at same
        exact Or.inr (Or.inr same)
      · split at failure
        · cases failure
          exact Or.inr (Or.inr rfl)
        · split at failure
          · rename_i rejected
            cases failure
            exact Or.inr (Or.inr (verifyHistory_refusal policy selectedPoint _ _ _ rejected))
          · cases failure

theorem acceptHistory_never_adopts (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) :
    (∀ claim, acceptHistory policy publications selectedPoint provider = .ok claim →
      claim.point = selectedPoint) ∧
    ∀ refusal, acceptHistory policy publications selectedPoint provider = .error refusal →
      refusal.selectedPoint = selectedPoint := by
  refine ⟨fun claim success => ?_, fun refusal failure => ?_⟩
  · obtain ⟨_, _, _, _, _, _, _, _, _, _, rfl⟩ :=
      acceptHistory_observations policy publications selectedPoint provider claim success
    rfl
  · rcases acceptHistory_refusal policy publications selectedPoint provider refusal failure with
      rfl | rfl | rfl <;> rfl

-- The state output an accepted history rests on: the honest ledger root and the unique
-- asset-carrying member whose datum root checked, through either provenance route.
theorem history_state_output (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout) (root appRoot : Root)
    (session : Session)
    (correspondence : HonestRootCorrespondence policy publications honestRoot)
    (faithful : ObjectEncodingFaithful policy) (assetSound : AssetObservationSound policy carries)
    (datumSound : DatumObservationSound policy honestDatumRoot)
    (provenance : (WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
      (CompletenessSound policy ledger honestRoot layout ∧ AssetKeyLayout policy carries layout ∧
        policy.requireCompleteness = true))
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (acquired : acquire selectedPoint provider = .ok session)
    (verified : verifyLedger policy root session session.ledger = .ok appRoot) :
    root = honestRoot selectedPoint ∧
      ∃ entry, entry ∈ ledger selectedPoint ∧ carries entry.2 policy.asset ∧
        (∀ other ∈ ledger selectedPoint, carries other.2 policy.asset → other = entry) ∧
        honestDatumRoot policy.schema entry.2 = some appRoot := by
  have honest : root = honestRoot selectedPoint :=
    acceptRoot_honest policy publications selectedPoint root honestRoot
      (acceptContextRoot_in_context policy publications selectedPoint root rootAccepted).1
      correspondence
  have samePoint : session.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider session acquired
  have honestAt : root = honestRoot session.selectedPoint := by rw [samePoint]; exact honest
  obtain ⟨entry, member, carried, datum, unique⟩ : ∃ entry : TxIn × TxOut,
      entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
      honestDatumRoot policy.schema entry.2 = some appRoot ∧
      ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry := by
    rcases provenance with ⟨witnessSound, oneShot⟩ | ⟨complete, layoutSound, required⟩
    · exact verifyLedger_sound policy ledger honestRoot carries honestDatumRoot root session
        session.ledger appRoot witnessSound faithful assetSound datumSound oneShot honestAt verified
    · exact verifyLedger_required_complete_sound policy ledger honestRoot carries honestDatumRoot
        layout root session session.ledger appRoot faithful assetSound datumSound complete
        layoutSound honestAt required verified
  rw [samePoint] at member unique
  exact ⟨honest, entry, member, carried, unique, datum⟩

-- The primary guarantee. The root comparison is read from verifyHistory inside this proof.
theorem accept_history_state_sound : HistoryStateSoundness acceptHistory := by
  intro policy publications selectedPoint provider claim ledger honestRoot carries honestDatumRoot
    layout semantics honestHistory correspondence faithful assetSound datumSound provenance
    deterministic resistant committed accepted
  obtain ⟨root, session, appRoot, answer, result, rooted, acquired, verified, _, checked, rfl⟩ :=
    acceptHistory_observations policy publications selectedPoint provider claim accepted
  obtain ⟨honest, entry, member, carried, unique, datum⟩ := history_state_output policy
    publications selectedPoint provider ledger honestRoot carries honestDatumRoot layout root appRoot
    session correspondence faithful assetSound datumSound provenance rooted acquired verified
  obtain ⟨honestState, reached, honestStateRoot⟩ :=
    committed selectedPoint entry member carried appRoot datum
  simp only [verifyHistory, relevantHistory] at checked
  split at checked
  · rename_i rootEqual
    cases checked
    have rebuilt := deterministic.1 policy.initial (answer.transactions.filter policy.relevant)
      (fun _ kept => List.of_mem_filter kept)
    have sameState := resistant _ _ _ _ (fun _ kept => List.of_mem_filter kept)
      (fun _ kept => List.of_mem_filter kept) rebuilt reached (rootEqual.trans honestStateRoot.symm)
    exact ⟨rfl, honest, rfl, entry, honestState, member, carried, unique, datum, reached, sameState,
      honestStateRoot⟩
  · cases checked

-- The secondary guarantee, under the stronger history commitment premise.
theorem accept_history_sequence_sound : HistorySequenceSoundness acceptHistory := by
  intro policy publications selectedPoint provider claim ledger honestRoot carries honestDatumRoot
    layout semantics honestHistory correspondence faithful assetSound datumSound provenance
    deterministic injective committed accepted
  obtain ⟨root, session, appRoot, answer, result, rooted, acquired, verified, _, checked, rfl⟩ :=
    acceptHistory_observations policy publications selectedPoint provider claim accepted
  obtain ⟨honest, entry, member, carried, unique, datum⟩ := history_state_output policy
    publications selectedPoint provider ledger honestRoot carries honestDatumRoot layout root appRoot
    session correspondence faithful assetSound datumSound provenance rooted acquired verified
  obtain ⟨honestState, reached, honestStateRoot⟩ :=
    committed selectedPoint entry member carried appRoot datum
  simp only [verifyHistory, relevantHistory] at checked
  split at checked
  · rename_i rootEqual
    cases checked
    have rebuilt := deterministic.1 policy.initial (answer.transactions.filter policy.relevant)
      (fun _ kept => List.of_mem_filter kept)
    have sameHistory := injective _ _ _ _ (fun _ kept => List.of_mem_filter kept)
      (fun _ kept => List.of_mem_filter kept) rebuilt reached (rootEqual.trans honestStateRoot.symm)
    have rebuiltHonest : semantics policy.initial
        ((honestHistory policy.query selectedPoint).filter policy.relevant)
        ((answer.transactions.filter policy.relevant).foldl policy.fold policy.initial) := by
      rw [← sameHistory]
      exact rebuilt
    exact ⟨rfl, honest, rfl, sameHistory, entry, honestState, member, carried, unique, datum, reached,
      deterministic.2 _ _ _ _ rebuiltHonest reached, honestStateRoot⟩
  · cases checked

-- Under the state premises, after the preceding boundaries succeed, a history whose rebuilt state
-- is no honest state is refused at the selected point.
theorem history_state_mismatch_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
    (semantics : HistorySemantics) (honestHistory : AppQuery → Chainpoint → List Reconstruction)
    (root appRoot : Root) (session : Session) (answer : HistoryAnswer)
    (correspondence : HonestRootCorrespondence policy publications honestRoot)
    (faithful : ObjectEncodingFaithful policy) (assetSound : AssetObservationSound policy carries)
    (datumSound : DatumObservationSound policy honestDatumRoot)
    (provenance : (WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
      (CompletenessSound policy ledger honestRoot layout ∧ AssetKeyLayout policy carries layout ∧
        policy.requireCompleteness = true))
    (deterministic : FoldDeterministic policy semantics)
    (resistant : StateRootCollisionResistant policy semantics)
    (committed : HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (acquired : acquire selectedPoint provider = .ok session)
    (verified : verifyLedger policy root session session.ledger = .ok appRoot)
    (present : session.ledger.history = some answer)
    (different : ∀ honestState, semantics policy.initial
      ((honestHistory policy.query selectedPoint).filter policy.relevant) honestState →
      (answer.transactions.filter policy.relevant).foldl policy.fold policy.initial ≠ honestState) :
    acceptHistory policy publications selectedPoint provider =
      .error (.evidenceFailure selectedPoint) := by
  cases checkedEq : verifyHistory policy selectedPoint appRoot answer with
  | error refusal =>
    have same := verifyHistory_refusal policy selectedPoint appRoot answer refusal checkedEq
    subst same
    simp [acceptHistory, rootAccepted, acquired, verified, present, checkedEq]
  | ok result =>
    exfalso
    have accepted : acceptHistory policy publications selectedPoint provider =
        .ok ⟨selectedPoint, root, policy.query, appRoot, result⟩ := by
      simp [acceptHistory, rootAccepted, acquired, verified, present, checkedEq]
    obtain ⟨_, _, _, _, honestState, _, _, _, _, reached, sameState, _⟩ :=
      accept_history_state_sound policy publications selectedPoint provider _ ledger honestRoot
        carries honestDatumRoot layout semantics honestHistory correspondence faithful assetSound
        datumSound provenance deterministic resistant committed accepted
    obtain ⟨_, rebuilt, _⟩ :=
      verifyHistory_observations policy selectedPoint appRoot answer result checkedEq
    exact different honestState reached (rebuilt.symm.trans sameState)

-- Under the sequence premises, after the preceding boundaries succeed, a history whose relevant
-- sequence is not the honest one is refused at the selected point.
theorem history_sequence_mismatch_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
    (semantics : HistorySemantics) (honestHistory : AppQuery → Chainpoint → List Reconstruction)
    (root appRoot : Root) (session : Session) (answer : HistoryAnswer)
    (correspondence : HonestRootCorrespondence policy publications honestRoot)
    (faithful : ObjectEncodingFaithful policy) (assetSound : AssetObservationSound policy carries)
    (datumSound : DatumObservationSound policy honestDatumRoot)
    (provenance : (WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
      (CompletenessSound policy ledger honestRoot layout ∧ AssetKeyLayout policy carries layout ∧
        policy.requireCompleteness = true))
    (deterministic : FoldDeterministic policy semantics)
    (injective : HistoryCommitmentInjective policy semantics)
    (committed : HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (acquired : acquire selectedPoint provider = .ok session)
    (verified : verifyLedger policy root session session.ledger = .ok appRoot)
    (present : session.ledger.history = some answer)
    (different : answer.transactions.filter policy.relevant ≠
      (honestHistory policy.query selectedPoint).filter policy.relevant) :
    acceptHistory policy publications selectedPoint provider =
      .error (.evidenceFailure selectedPoint) := by
  cases checkedEq : verifyHistory policy selectedPoint appRoot answer with
  | error refusal =>
    have same := verifyHistory_refusal policy selectedPoint appRoot answer refusal checkedEq
    subst same
    simp [acceptHistory, rootAccepted, acquired, verified, present, checkedEq]
  | ok result =>
    exfalso
    have accepted : acceptHistory policy publications selectedPoint provider =
        .ok ⟨selectedPoint, root, policy.query, appRoot, result⟩ := by
      simp [acceptHistory, rootAccepted, acquired, verified, present, checkedEq]
    obtain ⟨_, _, _, sameHistory, _⟩ :=
      accept_history_sequence_sound policy publications selectedPoint provider _ ledger honestRoot
        carries honestDatumRoot layout semantics honestHistory correspondence faithful assetSound
        datumSound provenance deterministic injective committed accepted
    obtain ⟨transactions, _, _⟩ :=
      verifyHistory_observations policy selectedPoint appRoot answer result checkedEq
    exact different (transactions.symm.trans sameHistory)

-- Replacing the history keeps every other session and answer field.
theorem withHistory_fields (history : Option HistoryAnswer) (session : Session) :
    (session.withHistory history).selectedPoint = session.selectedPoint ∧
    (session.withHistory history).binding = session.binding ∧
    (session.withHistory history).ledger.witness = session.ledger.witness ∧
    (session.withHistory history).ledger.completeness = session.ledger.completeness ∧
    (session.withHistory history).ledger.history = history :=
  ⟨rfl, rfl, rfl, rfl, rfl⟩

-- The absence classification reads no history.
theorem withHistory_reason (selectedPoint : Chainpoint) (provider : Provider)
    (history : Option HistoryAnswer) :
    unverifiedReason selectedPoint (fun point => (provider point).map (Session.withHistory history)) =
      unverifiedReason selectedPoint provider := by
  cases offered : provider selectedPoint with
  | none => simp [unverifiedReason, acquire, offered]
  | some session =>
    obtain ⟨samePoint, sameBinding, sameWitness, sameCompleteness, _⟩ :=
      withHistory_fields history session
    by_cases same : session.selectedPoint = selectedPoint
    · simp [unverifiedReason, acquire, offered, Session.point, samePoint, same, sameBinding,
        sameWitness, sameCompleteness]
    · simp [unverifiedReason, acquire, offered, Session.point, samePoint, same]

-- Full-outcome tolerance. Selection is read from relevantHistory inside this proof.
theorem history_superset_tolerant : HistorySupersetTolerance acceptHistory := by
  intro policy publications selectedPoint provider first second sameFilter
  have sameCheck : ∀ appRoot, verifyHistory policy selectedPoint appRoot ⟨first⟩ =
      verifyHistory policy selectedPoint appRoot ⟨second⟩ := by
    intro appRoot
    simp only [verifyHistory, relevantHistory, sameFilter]
  have sameAnswer : ∀ (items : List Reconstruction) (session : Session),
      (session.withHistory (some ⟨items⟩)).ledger.history = some ⟨items⟩ := fun _ _ => rfl
  have samePoint : ∀ (items : List Reconstruction) (session : Session),
      (session.withHistory (some ⟨items⟩)).selectedPoint = session.selectedPoint := fun _ _ => rfl
  cases rooted : acceptContextRoot policy publications selectedPoint with
  | error refusal => simp [acceptHistory, rooted]
  | ok root =>
    cases offered : provider selectedPoint with
    | none => simp [acceptHistory, rooted, acquire, offered]
    | some session =>
      by_cases same : session.selectedPoint = selectedPoint
      · simp [acceptHistory, rooted, acquire, offered, Session.point, samePoint, same,
          withHistory_ledger_verified, sameAnswer, sameCheck]
      · simp [acceptHistory, rooted, acquire, offered, Session.point, samePoint, same]

theorem historyVerdict_superset_tolerant : HistoryVerdictSupersetTolerance historyVerdict := by
  intro policy publications selectedPoint provider first second sameFilter
  have sameAccept := history_superset_tolerant policy publications selectedPoint provider first
    second sameFilter
  simp only [historyVerdict, sameAccept, withHistory_reason]

-- Appending items the policy rejects changes neither the acceptance nor the classification.
theorem history_append_irrelevant (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (items extras : List Reconstruction)
    (rejected : ∀ extra ∈ extras, policy.relevant extra = false) :
    acceptHistory policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨items ++ extras⟩))) =
      acceptHistory policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨items⟩))) ∧
    historyVerdict policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨items ++ extras⟩))) =
      historyVerdict policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨items⟩))) := by
  have sameFilter : (items ++ extras).filter policy.relevant = items.filter policy.relevant := by
    have noExtras : extras.filter policy.relevant = [] :=
      List.filter_eq_nil_iff.mpr fun extra member => by simp [rejected extra member]
    rw [List.filter_append, noExtras, List.append_nil]
  exact ⟨history_superset_tolerant policy publications selectedPoint provider _ _ sameFilter,
    historyVerdict_superset_tolerant policy publications selectedPoint provider _ _ sameFilter⟩

theorem history_verified_iff (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (claim : HistoryClaim) :
    historyVerdict policy publications selectedPoint provider = .verified claim ↔
      policy.verifier = true ∧ acceptHistory policy publications selectedPoint provider = .ok claim := by
  unfold historyVerdict
  cases configured : policy.verifier
  · simp
  · cases acceptHistory policy publications selectedPoint provider with
    | ok found => simp
    | error refusal =>
      cases outOfContext policy publications selectedPoint <;>
        cases unverifiedReason selectedPoint provider <;> simp

theorem history_no_promotion : HistoryNoPromotion historyVerdict := by
  intro policy publications selectedPoint provider claim verified
  obtain ⟨configured, accepted⟩ :=
    (history_verified_iff policy publications selectedPoint provider claim).mp verified
  obtain ⟨root, session, appRoot, _, _, rooted, acquired, checked, _, _, _⟩ :=
    acceptHistory_observations policy publications selectedPoint provider claim accepted
  have samePoint : session.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider session acquired
  obtain ⟨_, bound, _, _, _, _, ⟨witness, witnessed, witnessChecks⟩, _⟩ :=
    verifyLedger_observations policy root session session.ledger appRoot checked
  exact ⟨configured, root, session, witness, rooted,
    acquire_preserves_offer selectedPoint provider session acquired, samePoint,
    by rw [bound, samePoint], witnessed, witnessChecks, accepted⟩

-- Every refused classification is acceptHistory's own refusal at the selected point.
theorem historyVerdict_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (refusal : Refusal)
    (refused : historyVerdict policy publications selectedPoint provider = .refused refusal) :
    policy.verifier = true ∧
      acceptHistory policy publications selectedPoint provider = .error refusal ∧
      refusal.selectedPoint = selectedPoint := by
  unfold historyVerdict at refused
  split at refused
  · rename_i configured
    split at refused
    · cases refused
    · rename_i failure accepted
      have samePoint :=
        (acceptHistory_never_adopts policy publications selectedPoint provider).2 failure accepted
      split at refused
      · cases refused
        exact ⟨configured, accepted, samePoint⟩
      · split at refused
        · cases refused
        · cases refused
          exact ⟨configured, accepted, samePoint⟩
  · cases refused

-- A witness or a completeness answer on a session bound to the selected point is evidence, so
-- the classification is never unverified. A history alone is not evidence.
theorem history_evidence_never_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (session : Session)
    (configured : policy.verifier = true) (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (evidence : session.ledger.witness ≠ none ∨ session.ledger.completeness ≠ none) :
    ∀ reason, historyVerdict policy publications selectedPoint provider ≠ .unverified reason := by
  intro reason unverified
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    rcases evidence with witnessed | completed
    · cases offeredWitness : session.ledger.witness with
      | none => exact absurd offeredWitness witnessed
      | some _ => simp [unverifiedReason, acquired, bound, offeredWitness]
    · cases offeredCompleteness : session.ledger.completeness with
      | none => exact absurd offeredCompleteness completed
      | some _ => simp [unverifiedReason, acquired, bound, offeredCompleteness]
  unfold historyVerdict at unverified
  rw [if_pos configured] at unverified
  split at unverified
  · cases unverified
  · split at unverified
    · cases unverified
    · simp [noReason] at unverified

-- After the preceding boundaries succeed, a present history whose rebuilt root differs from the
-- verified datum root is refused at the selected point.
theorem history_wrong_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (session : Session) (root appRoot : Root)
    (answer : HistoryAnswer) (configured : policy.verifier = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (verified : verifyLedger policy root session session.ledger = .ok appRoot)
    (present : session.ledger.history = some answer)
    (wrong : policy.historyRoot
      ((answer.transactions.filter policy.relevant).foldl policy.fold policy.initial) ≠ appRoot) :
    acceptHistory policy publications selectedPoint provider =
        .error (.evidenceFailure selectedPoint) ∧
      historyVerdict policy publications selectedPoint provider =
        .refused (.evidenceFailure selectedPoint) := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have checkFails : verifyHistory policy selectedPoint appRoot answer =
      .error (.evidenceFailure selectedPoint) := by
    simp [verifyHistory, relevantHistory, wrong]
  have rejected : acceptHistory policy publications selectedPoint provider =
      .error (.evidenceFailure selectedPoint) := by
    simp [acceptHistory, rootAccepted, acquired, verified, present, checkFails]
  refine ⟨rejected, ?_⟩
  obtain ⟨_, bound, _, _, _, _, ⟨_, witnessed, _⟩, _⟩ :=
    verifyLedger_observations policy root session session.ledger appRoot verified
  have boundSelected : session.binding = .bound selectedPoint := by rw [bound, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, boundSelected, witnessed]
  have inside := (acceptContextRoot_in_context policy publications selectedPoint root rootAccepted).2.1
  simp [historyVerdict, configured, rejected, inside, noReason]

-- After the preceding boundaries succeed, an absent history is refused at the selected point.
theorem history_missing_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (session : Session) (root appRoot : Root)
    (configured : policy.verifier = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (verified : verifyLedger policy root session session.ledger = .ok appRoot)
    (absent : session.ledger.history = none) :
    acceptHistory policy publications selectedPoint provider =
        .error (.evidenceFailure selectedPoint) ∧
      historyVerdict policy publications selectedPoint provider =
        .refused (.evidenceFailure selectedPoint) := by
  have acquired : acquire selectedPoint provider = .ok session := by
    simp [acquire, offered, Session.point, samePoint]
  have rejected : acceptHistory policy publications selectedPoint provider =
      .error (.evidenceFailure selectedPoint) := by
    simp [acceptHistory, rootAccepted, acquired, verified, absent]
  refine ⟨rejected, ?_⟩
  obtain ⟨_, bound, _, _, _, _, ⟨_, witnessed, _⟩, _⟩ :=
    verifyLedger_observations policy root session session.ledger appRoot verified
  have boundSelected : session.binding = .bound selectedPoint := by rw [bound, samePoint]
  have noReason : unverifiedReason selectedPoint provider = none := by
    simp [unverifiedReason, acquired, boundSelected, witnessed]
  have inside := (acceptContextRoot_in_context policy publications selectedPoint root rootAccepted).2.1
  simp [historyVerdict, configured, rejected, inside, noReason]

-- The legacy reconstruction is read by no history step.
theorem history_legacy_reconstruction_irrelevant (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (reconstruction : Option Reconstruction) :
    acceptHistory policy publications selectedPoint
        (fun point => (provider point).map (Session.withReconstruction reconstruction)) =
      acceptHistory policy publications selectedPoint provider ∧
    historyVerdict policy publications selectedPoint
        (fun point => (provider point).map (Session.withReconstruction reconstruction)) =
      historyVerdict policy publications selectedPoint provider := by
  have samePointField : ∀ session : Session,
      (session.withReconstruction reconstruction).selectedPoint = session.selectedPoint :=
    fun _ => rfl
  have sameBinding : ∀ session : Session,
      (session.withReconstruction reconstruction).binding = session.binding := fun _ => rfl
  have sameWitness : ∀ session : Session,
      (session.withReconstruction reconstruction).ledger.witness = session.ledger.witness :=
    fun _ => rfl
  have sameCompleteness : ∀ session : Session,
      (session.withReconstruction reconstruction).ledger.completeness =
        session.ledger.completeness := fun _ => rfl
  have sameHistory : ∀ session : Session,
      (session.withReconstruction reconstruction).ledger.history = session.ledger.history :=
    fun _ => rfl
  have sameAccept : acceptHistory policy publications selectedPoint
      (fun point => (provider point).map (Session.withReconstruction reconstruction)) =
      acceptHistory policy publications selectedPoint provider := by
    cases rooted : acceptContextRoot policy publications selectedPoint with
    | error refusal => simp [acceptHistory, rooted]
    | ok root =>
      cases offered : provider selectedPoint with
      | none => simp [acceptHistory, rooted, acquire, offered]
      | some session =>
        by_cases same : session.selectedPoint = selectedPoint
        · simp [acceptHistory, rooted, acquire, offered, Session.point, samePointField, same,
            withReconstruction_ledger_verified, sameHistory]
        · simp [acceptHistory, rooted, acquire, offered, Session.point, samePointField, same]
  have sameReason : unverifiedReason selectedPoint
      (fun point => (provider point).map (Session.withReconstruction reconstruction)) =
      unverifiedReason selectedPoint provider := by
    cases offered : provider selectedPoint with
    | none => simp [unverifiedReason, acquire, offered]
    | some session =>
      by_cases same : session.selectedPoint = selectedPoint
      · simp [unverifiedReason, acquire, offered, Session.point, samePointField, same,
          sameBinding, sameWitness, sameCompleteness]
      · simp [unverifiedReason, acquire, offered, Session.point, samePointField, same]
  exact ⟨sameAccept, by simp only [historyVerdict, sameAccept, sameReason]⟩

end Lockness
