import Lockness.History
import Lockness.Counterexamples.CompletenessFixtures

namespace Lockness.Counterexamples.HistoryExamples
open AppExamples LedgerExamples VerdictExamples CompletenessExamples

-- History items with resolved spent outputs. Three belong to the sequence application, two more
-- to the cancelling one; the foreign item belongs to neither.
def itemA : Reconstruction := ⟨[11, 0, 255], [([1, 0, 255], [10, 0, 255])]⟩
def itemB : Reconstruction := ⟨[12, 0, 255], [([2, 0, 255], [20, 0, 255])]⟩
def itemC : Reconstruction := ⟨[13, 0, 255], [([3, 0, 255], [30, 0, 255])]⟩
def itemPut : Reconstruction := ⟨[14, 0, 255], [([4, 0, 255], [40, 0, 255])]⟩
def itemTake : Reconstruction := ⟨[15, 0, 255], [([5, 0, 255], [50, 0, 255])]⟩
def foreignItem : Reconstruction := ⟨[99, 0, 255], [([9, 0, 255], [90, 0, 255])]⟩

-- Both applications start from the same state and expose its bytes as the root, under the
-- scheme of the ledger fixture's application roots.
def initialState : HistoryState := [1]
def stateRoot (state : HistoryState) : Root := ⟨[1], state⟩

-- The root the honest state output's datum carries, read from honest datum semantics.
def honestAppRoot : Root :=
  match honestDatumRoot schema entry₁.2 with
  | some root => root
  | none => honestRoot selected

def withHistoryFields (base : Policy) (relevant : Reconstruction → Bool)
    (fold : HistoryState → Reconstruction → HistoryState) : Policy :=
  { base with relevant := relevant, fold := fold, initial := initialState, historyRoot := stateRoot }

-- The history commitment: each relevant item appends its own tag, so the state records the
-- relevant sequence. A fixture, not a proposed accumulator.
def tag (item : Reconstruction) : UInt8 :=
  if item = itemA then 0 else if item = itemB then 255 else if item = itemC then 9 else 42
def appendTag (state : HistoryState) (item : Reconstruction) : HistoryState := state ++ [tag item]
def sequenceRelevant (item : Reconstruction) : Bool := decide (item = itemA ∨ item = itemB ∨ item = itemC)
-- Independent semantics: the initial bytes followed by every item's tag.
def tagSemantics : HistorySemantics := fun initial items state => state = initial ++ items.map tag
-- Honest application history at every point, in application order.
def sequenceHistory : AppQuery → Chainpoint → List Reconstruction := fun _ _ => [itemA, itemB]

-- The OneShot route (#9 policy) and the required-completeness route (#33 policy).
def sequencePolicy : Policy := withHistoryFields VerdictExamples.policy sequenceRelevant appendTag
def sequenceRequiredPolicy : Policy :=
  withHistoryFields (requiredPolicy false) sequenceRelevant appendTag

-- The state commitment: taking right after putting restores the earlier state, so two
-- different histories reach one state. A fixture, not a proposed trie.
def cancelStep (state : HistoryState) (item : Reconstruction) : HistoryState :=
  if item = itemA then state ++ [0]
  else if item = itemB then state ++ [255]
  else if item = itemPut then state ++ [7]
  else if item = itemTake then (if state.getLast? = some 7 then state.dropLast else state ++ [8])
  else state
def cancelRelevant (item : Reconstruction) : Bool :=
  decide (item = itemA ∨ item = itemB ∨ item = itemPut ∨ item = itemTake)
-- Independent semantics: replay item by item.
def replay : HistoryState → List Reconstruction → HistoryState
  | state, [] => state
  | state, item :: rest => replay (cancelStep state item) rest
def replaySemantics : HistorySemantics := fun initial items state => state = replay initial items
def cancelHistory : AppQuery → Chainpoint → List Reconstruction :=
  fun _ _ => [itemA, itemPut, itemTake, itemB]

def cancelPolicy : Policy := withHistoryFields VerdictExamples.policy cancelRelevant cancelStep
def cancelRequiredPolicy : Policy :=
  withHistoryFields (requiredPolicy false) cancelRelevant cancelStep

-- Offers: the #9 verified session, and for the completeness route the same session with the
-- honest asset listing; only the history differs between offers.
def requiredSession : Session :=
  withCompleteness (some (answerOf (assetKeyPrefix asset) [entry₁])) verifiedSession
def historyOffer (items : List Reconstruction) : Provider :=
  fun point => (verifiedProvider point).map (Session.withHistory (some ⟨items⟩))
def requiredOffer (items : List Reconstruction) : Provider :=
  fun point => (offering requiredSession point).map (Session.withHistory (some ⟨items⟩))

-- Expected claims come from honest semantics: the honest ledger root, the state output's honest
-- datum root and the semantic state of the honest relevant history. None is read from acceptance.
def sequenceClaim (policy : Policy) : HistoryClaim :=
  let transactions := (sequenceHistory policy.query selected).filter policy.relevant
  ⟨selected, honestRoot selected, policy.query, honestAppRoot,
    ⟨transactions, policy.initial ++ transactions.map tag⟩⟩
-- The cancelling claim carries the offered relevant sequence and the honest semantic state.
def cancelClaim (policy : Policy) (offered : List Reconstruction) : HistoryClaim :=
  ⟨selected, honestRoot selected, policy.query, honestAppRoot,
    ⟨offered.filter policy.relevant,
      replay policy.initial ((cancelHistory policy.query selected).filter policy.relevant)⟩⟩

theorem every_relevant_tagged (items : List Reconstruction)
    (relevant : ∀ item ∈ items, sequenceRelevant item = true) :
    ∀ item ∈ items, item = itemA ∨ item = itemB ∨ item = itemC := by
  intro item member
  simpa [sequenceRelevant] using relevant item member

-- Distinct relevant items have distinct tags, so the tags determine an all-relevant history.
theorem tags_injective : ∀ (first second : List Reconstruction),
    (∀ item ∈ first, sequenceRelevant item = true) →
    (∀ item ∈ second, sequenceRelevant item = true) →
    first.map tag = second.map tag → first = second
  | [], [], _, _, _ => rfl
  | [], _ :: _, _, _, equal => by simp at equal
  | _ :: _, [], _, _, equal => by simp at equal
  | head :: rest, head' :: rest', relevant, relevant', equal => by
    simp only [List.map_cons, List.cons.injEq] at equal
    have sameHead : head = head' := by
      rcases every_relevant_tagged _ relevant head (by simp) with h | h | h <;>
        rcases every_relevant_tagged _ relevant' head' (by simp) with h' | h' | h' <;>
        subst h h' <;> first | rfl | (exact absurd equal.1 (by decide))
    rw [sameHead, tags_injective rest rest' (fun item member => relevant item (by simp [member]))
      (fun item member => relevant' item (by simp [member])) equal.2]

theorem appendTag_foldl (initial : HistoryState) (items : List Reconstruction) :
    items.foldl appendTag initial = initial ++ items.map tag := by
  induction items generalizing initial with
  | nil => simp
  | cons item rest ih => simp [List.foldl, ih, appendTag]

theorem sequence_fold_deterministic (policy : Policy) (fold : policy.fold = appendTag) :
    FoldDeterministic policy tagSemantics := by
  refine ⟨fun initial items _ => ?_, fun _ _ _ _ first second => first.trans second.symm⟩
  show items.foldl policy.fold initial = initial ++ items.map tag
  rw [fold, appendTag_foldl]

theorem sequence_commitment_injective (policy : Policy) (relevant : policy.relevant = sequenceRelevant)
    (root : policy.historyRoot = stateRoot) : HistoryCommitmentInjective policy tagSemantics := by
  intro first second firstState secondState firstRelevant secondRelevant firstReached
    secondReached sameRoot
  rw [relevant] at firstRelevant secondRelevant
  rw [root] at sameRoot
  have sameState : firstState = secondState := congrArg Root.bytes sameRoot
  have firstEq : firstState = policy.initial ++ first.map tag := firstReached
  have secondEq : secondState = policy.initial ++ second.map tag := secondReached
  rw [firstEq, secondEq] at sameState
  exact tags_injective first second firstRelevant secondRelevant (List.append_cancel_left sameState)

theorem stateRoot_injective (policy : Policy) (semantics : HistorySemantics)
    (root : policy.historyRoot = stateRoot) : StateRootCollisionResistant policy semantics := by
  intro _ _ firstState secondState _ _ _ _ sameRoot
  rw [root] at sameRoot
  exact congrArg Root.bytes sameRoot

-- The only asset-carrying member of either fixture ledger is entry₁.
theorem carrying_member (point : Chainpoint) (entry : TxIn × TxOut)
    (member : entry ∈ ledgerFor false point ∨ entry ∈ ledgerOf false point)
    (carried : carries entry.2 asset) : entry = entry₁ := by
  rcases member with member | member
  · simpa [ledgerFor] using member
  · simp only [ledgerOf, ledgerList, Bool.false_eq_true, ↓reduceIte, List.mem_toFinset,
      List.mem_cons, List.not_mem_nil, or_false] at member
    rcases member with rfl | rfl | rfl
    · rfl
    · exact absurd carried (by decide)
    · exact absurd carried (by decide)

theorem honest_datum_root : honestDatumRoot schema entry₁.2 = some honestAppRoot := by decide

theorem sequence_committed (policy : Policy) (ledger : Ledger)
    (onLedger : ∀ point entry, entry ∈ ledger point → carries entry.2 policy.asset → entry = entry₁)
    (schemaEq : policy.schema = schema) (initial : policy.initial = initialState)
    (relevant : policy.relevant = sequenceRelevant) (root : policy.historyRoot = stateRoot) :
    HistoryCommitted policy ledger carries honestDatumRoot tagSemantics sequenceHistory := by
  intro point entry member carried appRoot datum
  have same := onLedger point entry member carried
  subst same
  rw [schemaEq, honest_datum_root] at datum
  cases datum
  refine ⟨initialState ++ [0, 255], ?_, ?_⟩
  · show initialState ++ [0, 255] = policy.initial ++ _
    rw [initial, relevant]
    simp only [sequenceHistory]
    decide
  · rw [root]
    decide

theorem cancelStep_foldl (initial : HistoryState) (items : List Reconstruction) :
    items.foldl cancelStep initial = replay initial items := by
  induction items generalizing initial with
  | nil => rfl
  | cons item rest ih => exact ih (cancelStep initial item)

theorem cancel_fold_deterministic (policy : Policy) (fold : policy.fold = cancelStep) :
    FoldDeterministic policy replaySemantics := by
  refine ⟨fun initial items _ => ?_, fun _ _ _ _ first second => first.trans second.symm⟩
  show items.foldl policy.fold initial = replay initial items
  rw [fold, cancelStep_foldl]

theorem cancel_committed (policy : Policy) (ledger : Ledger)
    (onLedger : ∀ point entry, entry ∈ ledger point → carries entry.2 policy.asset → entry = entry₁)
    (schemaEq : policy.schema = schema) (initial : policy.initial = initialState)
    (relevant : policy.relevant = cancelRelevant) (root : policy.historyRoot = stateRoot) :
    HistoryCommitted policy ledger carries honestDatumRoot replaySemantics cancelHistory := by
  intro point entry member carried appRoot datum
  have same := onLedger point entry member carried
  subst same
  rw [schemaEq, honest_datum_root] at datum
  cases datum
  refine ⟨initialState ++ [0, 255], ?_, ?_⟩
  · show initialState ++ [0, 255] = replay policy.initial _
    rw [initial, relevant]
    simp only [cancelHistory]
    decide
  · rw [root]
    decide

-- Every premise shared by both guarantees, for each fixture policy, on its route's ledger.
theorem sequence_oneshot_premises :
    HonestRootCorrespondence sequencePolicy publications honestRoot ∧
    ObjectEncodingFaithful sequencePolicy ∧ AssetObservationSound sequencePolicy carries ∧
    DatumObservationSound sequencePolicy honestDatumRoot ∧
    WitnessSound sequencePolicy (ledgerFor false) honestRoot ∧
    OneShot (ledgerFor false) sequencePolicy.asset carries ∧
    FoldDeterministic sequencePolicy tagSemantics ∧
    HistoryCommitmentInjective sequencePolicy tagSemantics ∧
    HistoryCommitted sequencePolicy (ledgerFor false) carries honestDatumRoot tagSemantics
      sequenceHistory :=
  ⟨AppExamples.fixture_correspondence false finalQuery, AppExamples.fixture_encoding_faithful false finalQuery,
    AppExamples.fixture_asset_sound false finalQuery, AppExamples.fixture_datum_sound false finalQuery,
    AppExamples.fixture_witness_sound false finalQuery, AppExamples.fixture_one_shot false finalQuery,
    sequence_fold_deterministic sequencePolicy rfl,
    sequence_commitment_injective sequencePolicy rfl rfl,
    sequence_committed sequencePolicy (ledgerFor false)
      (fun point entry member carried => carrying_member point entry (Or.inl member) carried)
      rfl rfl rfl rfl⟩

theorem sequence_required_premises :
    HonestRootCorrespondence sequenceRequiredPolicy publications honestRoot ∧
    ObjectEncodingFaithful sequenceRequiredPolicy ∧
    AssetObservationSound sequenceRequiredPolicy carries ∧
    DatumObservationSound sequenceRequiredPolicy honestDatumRoot ∧
    CompletenessSound sequenceRequiredPolicy (ledgerOf false) honestRoot layout ∧
    AssetKeyLayout sequenceRequiredPolicy carries layout ∧
    sequenceRequiredPolicy.requireCompleteness = true ∧
    FoldDeterministic sequenceRequiredPolicy tagSemantics ∧
    HistoryCommitmentInjective sequenceRequiredPolicy tagSemantics ∧
    HistoryCommitted sequenceRequiredPolicy (ledgerOf false) carries honestDatumRoot tagSemantics
      sequenceHistory :=
  ⟨complete_correspondence false, complete_faithful false, complete_asset_sound false,
    complete_datum_sound false, fixture_completeness_sound false, fixture_asset_layout false, rfl,
    sequence_fold_deterministic sequenceRequiredPolicy rfl,
    sequence_commitment_injective sequenceRequiredPolicy rfl rfl,
    sequence_committed sequenceRequiredPolicy (ledgerOf false)
      (fun point entry member carried => carrying_member point entry (Or.inr member) carried)
      rfl rfl rfl rfl⟩

theorem cancel_oneshot_premises :
    HonestRootCorrespondence cancelPolicy publications honestRoot ∧
    ObjectEncodingFaithful cancelPolicy ∧ AssetObservationSound cancelPolicy carries ∧
    DatumObservationSound cancelPolicy honestDatumRoot ∧
    WitnessSound cancelPolicy (ledgerFor false) honestRoot ∧
    OneShot (ledgerFor false) cancelPolicy.asset carries ∧
    FoldDeterministic cancelPolicy replaySemantics ∧
    StateRootCollisionResistant cancelPolicy replaySemantics ∧
    HistoryCommitted cancelPolicy (ledgerFor false) carries honestDatumRoot replaySemantics
      cancelHistory :=
  ⟨AppExamples.fixture_correspondence false finalQuery, AppExamples.fixture_encoding_faithful false finalQuery,
    AppExamples.fixture_asset_sound false finalQuery, AppExamples.fixture_datum_sound false finalQuery,
    AppExamples.fixture_witness_sound false finalQuery, AppExamples.fixture_one_shot false finalQuery,
    cancel_fold_deterministic cancelPolicy rfl, stateRoot_injective cancelPolicy replaySemantics rfl,
    cancel_committed cancelPolicy (ledgerFor false)
      (fun point entry member carried => carrying_member point entry (Or.inl member) carried)
      rfl rfl rfl rfl⟩

theorem cancel_required_premises :
    HonestRootCorrespondence cancelRequiredPolicy publications honestRoot ∧
    ObjectEncodingFaithful cancelRequiredPolicy ∧ AssetObservationSound cancelRequiredPolicy carries ∧
    DatumObservationSound cancelRequiredPolicy honestDatumRoot ∧
    CompletenessSound cancelRequiredPolicy (ledgerOf false) honestRoot layout ∧
    AssetKeyLayout cancelRequiredPolicy carries layout ∧
    cancelRequiredPolicy.requireCompleteness = true ∧
    FoldDeterministic cancelRequiredPolicy replaySemantics ∧
    StateRootCollisionResistant cancelRequiredPolicy replaySemantics ∧
    HistoryCommitted cancelRequiredPolicy (ledgerOf false) carries honestDatumRoot replaySemantics
      cancelHistory :=
  ⟨complete_correspondence false, complete_faithful false, complete_asset_sound false,
    complete_datum_sound false, fixture_completeness_sound false, fixture_asset_layout false, rfl,
    cancel_fold_deterministic cancelRequiredPolicy rfl,
    stateRoot_injective cancelRequiredPolicy replaySemantics rfl,
    cancel_committed cancelRequiredPolicy (ledgerOf false)
      (fun point entry member carried => carrying_member point entry (Or.inr member) carried)
      rfl rfl rfl rfl⟩

end Lockness.Counterexamples.HistoryExamples
