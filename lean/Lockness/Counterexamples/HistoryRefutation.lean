import Lockness.Counterexamples.HistoryFixtures

namespace Lockness.Counterexamples.HistoryExamples
open AppExamples LedgerExamples VerdictExamples CompletenessExamples

-- The acceptance composition with its history check as a parameter. Only the counterexamples
-- use it; Tests.History proves that with verifyHistory it is acceptHistory.
def acceptHistoryUsing
    (check : Policy → Chainpoint → Root → HistoryAnswer → Except Refusal HistoryResult)
    (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) : Except Refusal HistoryClaim :=
  match acceptContextRoot policy publications selectedPoint with
  | .error refusal => .error refusal
  | .ok root =>
    match acquire selectedPoint provider with
    | .error refusal => .error refusal
    | .ok session =>
      match verifyLedger policy root session session.ledger with
      | .error refusal => .error refusal
      | .ok appRoot =>
        match session.ledger.history with
        | none => .error (.evidenceFailure selectedPoint)
        | some answer =>
          match check policy selectedPoint appRoot answer with
          | .error refusal => .error refusal
          | .ok result =>
            .ok { point := selectedPoint, ledgerRoot := root, query := policy.query,
                  appRoot := appRoot, result := result }

-- M1: the rebuilt root is never compared.
def verifyHistoryWithoutRootComparison (policy : Policy) (_selectedPoint : Chainpoint)
    (_appRoot : Root) (answer : HistoryAnswer) : Except Refusal HistoryResult :=
  let transactions := relevantHistory policy answer
  .ok ⟨transactions, transactions.foldl policy.fold policy.initial⟩

-- M2: an item is kept only if the whole answer is relevant, so the enclosing answer decides.
def contextRelevantHistory (policy : Policy) (answer : HistoryAnswer) : List Reconstruction :=
  answer.transactions.filter fun item => policy.relevant item && answer.transactions.all policy.relevant

def verifyHistoryWithContextSelection (policy : Policy) (selectedPoint : Chainpoint)
    (appRoot : Root) (answer : HistoryAnswer) : Except Refusal HistoryResult :=
  let transactions := contextRelevantHistory policy answer
  let state := transactions.foldl policy.fold policy.initial
  if policy.historyRoot state = appRoot then .ok ⟨transactions, state⟩
  else .error (.evidenceFailure selectedPoint)

-- M3: only the root's scheme, a projection of the state root, is compared.
def verifyHistoryComparingScheme (policy : Policy) (selectedPoint : Chainpoint) (appRoot : Root)
    (answer : HistoryAnswer) : Except Refusal HistoryResult :=
  let transactions := relevantHistory policy answer
  let state := transactions.foldl policy.fold policy.initial
  if (policy.historyRoot state).scheme = appRoot.scheme then .ok ⟨transactions, state⟩
  else .error (.evidenceFailure selectedPoint)

-- Witness inputs. The forged history replaces the honest itemB by itemC; the missing history
-- drops itemB; the padded history adds a foreign item before the relevant ones.
def forgedHistory : List Reconstruction := [itemA, itemC]
def paddedHistory : List Reconstruction := [foreignItem, itemA, itemB]
def omittedPair : List Reconstruction := [itemA, itemB]
def shortHistory : List Reconstruction := [itemA]

-- What an operation accepting the forged history claims: the forged relevant items and the state
-- they rebuild, under the honest roots.
def forgedClaim : HistoryClaim :=
  ⟨selected, honestRoot selected, sequencePolicy.query, honestAppRoot,
    ⟨forgedHistory, sequencePolicy.initial ++ forgedHistory.map tag⟩⟩
-- What an operation accepting the short cancelling history claims: the state it rebuilds.
def projectedClaim : HistoryClaim :=
  ⟨selected, honestRoot selected, cancelPolicy.query, honestAppRoot,
    ⟨shortHistory, replay cancelPolicy.initial shortHistory⟩⟩

-- Any operation accepting the forged history, with every sequence premise held, is not sequence
-- sound: the accepted relevant list differs from the honest one.
theorem forged_history_refutes_sequence_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim)
    (accepted : operation sequencePolicy publications selected (historyOffer forgedHistory) =
      .ok forgedClaim) :
    ¬ HistorySequenceSoundness operation := by
  intro sound
  obtain ⟨correspondence, faithful, assetSound, datumSound, witnessSound, oneShot, deterministic,
    injective, committed⟩ := sequence_oneshot_premises
  obtain ⟨_, _, _, transactions, _⟩ := sound sequencePolicy publications selected
    (historyOffer forgedHistory) forgedClaim (ledgerFor false) honestRoot carries honestDatumRoot
    layout tagSemantics sequenceHistory correspondence faithful assetSound datumSound
    (Or.inl ⟨witnessSound, oneShot⟩) deterministic injective committed accepted
  exact absurd transactions (by decide)

-- Any operation accepting the honest history and refusing the same history behind a foreign
-- item is not superset tolerant: both lists have the same relevant subsequence.
theorem context_selection_refutes_tolerance
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim)
    (accepted : operation sequencePolicy publications selected (historyOffer omittedPair) =
      .ok (sequenceClaim sequencePolicy))
    (refused : operation sequencePolicy publications selected (historyOffer paddedHistory) =
      .error (.evidenceFailure selected)) :
    ¬ HistorySupersetTolerance operation := by
  intro tolerant
  have same := tolerant sequencePolicy publications selected verifiedProvider paddedHistory
    omittedPair (by decide)
  have contradiction : (Except.error (.evidenceFailure selected) : Except Refusal HistoryClaim) =
      .ok (sequenceClaim sequencePolicy) := by
    rw [← refused, ← accepted]
    exact same
  cases contradiction

-- Any operation accepting a short cancelling history whose state differs from the honest state,
-- with every state premise held, is not state sound.
theorem weaker_projection_refutes_state_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim)
    (accepted : operation cancelPolicy publications selected (historyOffer shortHistory) =
      .ok projectedClaim) :
    ¬ HistoryStateSoundness operation := by
  intro sound
  obtain ⟨correspondence, faithful, assetSound, datumSound, witnessSound, oneShot, deterministic,
    resistant, committed⟩ := cancel_oneshot_premises
  obtain ⟨_, _, _, _, honestState, _, _, _, _, reached, state, _⟩ := sound cancelPolicy publications
    selected (historyOffer shortHistory) projectedClaim (ledgerFor false) honestRoot carries
    honestDatumRoot layout replaySemantics cancelHistory correspondence faithful assetSound
    datumSound (Or.inl ⟨witnessSound, oneShot⟩) deterministic resistant committed accepted
  have honest : honestState = replay cancelPolicy.initial
      ((cancelHistory cancelPolicy.query selected).filter cancelPolicy.relevant) := reached
  rw [honest] at state
  exact absurd state (by decide)

-- The cancelling fold is a state commitment, not a history commitment: the honest history and
-- the one omitting the cancelling pair are both relevant and reach one root.
theorem cancelling_not_injective : ¬ HistoryCommitmentInjective cancelPolicy replaySemantics := by
  intro injective
  have same := injective omittedPair [itemA, itemPut, itemTake, itemB]
    (replay cancelPolicy.initial omittedPair) (replay cancelPolicy.initial [itemA, itemPut, itemTake, itemB])
    (by decide) (by decide) rfl rfl (by decide)
  exact absurd same (by decide)

end Lockness.Counterexamples.HistoryExamples
