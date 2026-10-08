import Lockness.Verdict
import Lockness.Completeness

namespace Lockness

-- The relevant transactions, in the provider's order, and the state the fold rebuilds from them.
-- Irrelevant items never appear here.
structure HistoryResult where
  transactions : List Reconstruction
  state : HistoryState
  deriving DecidableEq, Repr

structure HistoryClaim where
  point : Chainpoint
  ledgerRoot : Root
  query : AppQuery
  appRoot : Root
  result : HistoryResult
  deriving DecidableEq, Repr

-- The terminal classification of a history outcome; never a wire object.
inductive HistoryVerdict where
  | verified (claim : HistoryClaim)
  | refused (refusal : Refusal)
  | unverified (reason : Reason)
  deriving DecidableEq, Repr

-- Replaces only the offered answer's history.
def Session.withHistory (history : Option HistoryAnswer) (session : Session) : Session :=
  { session with ledger := { session.ledger with history := history } }

-- Selection reads one item at a time under the fixed policy, keeping order and multiplicity.
def relevantHistory (policy : Policy) (answer : HistoryAnswer) : List Reconstruction :=
  answer.transactions.filter policy.relevant

-- The checking root is an argument here; only acceptHistory gives it provenance.
def verifyHistory (policy : Policy) (selectedPoint : Chainpoint) (appRoot : Root)
    (answer : HistoryAnswer) : Except Refusal HistoryResult :=
  let transactions := relevantHistory policy answer
  let state := transactions.foldl policy.fold policy.initial
  if policy.historyRoot state = appRoot then .ok ⟨transactions, state⟩
  else .error (.evidenceFailure selectedPoint)

-- The frozen order: root acceptance in context, acquisition, the state output under the accepted
-- root, then the history from that same session against the state output's datum root.
def acceptHistory (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
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
          match verifyHistory policy selectedPoint appRoot answer with
          | .error refusal => .error refusal
          | .ok result =>
            .ok { point := selectedPoint, ledgerRoot := root, query := policy.query,
                  appRoot := appRoot, result := result }

-- The inherited classification around acceptHistory: a missing verifier first, consulting nothing;
-- then the claim; then an out-of-context refusal; then a declared absence; else the refusal.
def historyVerdict (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) : HistoryVerdict :=
  if policy.verifier then
    match acceptHistory policy publications selectedPoint provider with
    | .ok claim => .verified claim
    | .error refusal =>
      if outOfContext policy publications selectedPoint then .refused refusal
      else match unverifiedReason selectedPoint provider with
      | some reason => .unverified reason
      | none => .refused refusal
  else .unverified .noVerifier

-- An application's meaning of a relevant history: the states it reaches from an initial state.
-- Independent of the terminal's executable fold and never computed by the terminal.
abbrev HistorySemantics := HistoryState → List Reconstruction → HistoryState → Prop

-- The executable fold realises the semantics on relevant histories, and the semantics reaches one
-- state per history.
def FoldDeterministic (policy : Policy) (semantics : HistorySemantics) : Prop :=
  (∀ initial items, (∀ item ∈ items, policy.relevant item = true) →
    semantics initial items (items.foldl policy.fold initial)) ∧
  ∀ initial items first second, semantics initial items first → semantics initial items second →
    first = second

-- The honest history at each point reaches a state whose root is the datum root of the state
-- output carrying the asset there.
def HistoryCommitted (policy : Policy) (ledger : Ledger) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (semantics : HistorySemantics)
    (honestHistory : AppQuery → Chainpoint → List Reconstruction) : Prop :=
  ∀ point entry, entry ∈ ledger point → carries entry.2 policy.asset →
    ∀ appRoot, honestDatumRoot policy.schema entry.2 = some appRoot →
      ∃ state, semantics policy.initial ((honestHistory policy.query point).filter policy.relevant)
        state ∧ policy.historyRoot state = appRoot

-- A state commitment: equal roots of reachable states are equal states. Histories may differ.
def StateRootCollisionResistant (policy : Policy) (semantics : HistorySemantics) : Prop :=
  ∀ first second firstState secondState,
    (∀ item ∈ first, policy.relevant item = true) → (∀ item ∈ second, policy.relevant item = true) →
    semantics policy.initial first firstState → semantics policy.initial second secondState →
    policy.historyRoot firstState = policy.historyRoot secondState → firstState = secondState

-- A history commitment, such as an accumulator or hash chain: equal roots of reachable states
-- are equal relevant histories.
def HistoryCommitmentInjective (policy : Policy) (semantics : HistorySemantics) : Prop :=
  ∀ first second firstState secondState,
    (∀ item ∈ first, policy.relevant item = true) → (∀ item ∈ second, policy.relevant item = true) →
    semantics policy.initial first firstState → semantics policy.initial second secondState →
    policy.historyRoot firstState = policy.historyRoot secondState → first = second

-- The primary guarantee: an accepted history rebuilds the honest committed state at the selected
-- point. It says nothing about the accepted transaction list.
def HistoryStateSoundness
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim) :
    Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (claim : HistoryClaim) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
    (semantics : HistorySemantics) (honestHistory : AppQuery → Chainpoint → List Reconstruction),
    HonestRootCorrespondence policy publications honestRoot →
    ObjectEncodingFaithful policy → AssetObservationSound policy carries →
    DatumObservationSound policy honestDatumRoot →
    ((WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
      (CompletenessSound policy ledger honestRoot layout ∧ AssetKeyLayout policy carries layout ∧
        policy.requireCompleteness = true)) →
    FoldDeterministic policy semantics → StateRootCollisionResistant policy semantics →
    HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory →
    operation policy publications selectedPoint provider = .ok claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      claim.query = policy.query ∧
      ∃ entry honestState, entry ∈ ledger selectedPoint ∧ carries entry.2 policy.asset ∧
        (∀ other ∈ ledger selectedPoint, carries other.2 policy.asset → other = entry) ∧
        honestDatumRoot policy.schema entry.2 = some claim.appRoot ∧
        semantics policy.initial
          ((honestHistory policy.query selectedPoint).filter policy.relevant) honestState ∧
        claim.result.state = honestState ∧ policy.historyRoot honestState = claim.appRoot

-- The secondary guarantee: HistoryStateSoundness with HistoryCommitmentInjective in place of
-- StateRootCollisionResistant, adding the exact relevant sequence.
def HistorySequenceSoundness
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim) :
    Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (claim : HistoryClaim) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
    (semantics : HistorySemantics) (honestHistory : AppQuery → Chainpoint → List Reconstruction),
    HonestRootCorrespondence policy publications honestRoot →
    ObjectEncodingFaithful policy → AssetObservationSound policy carries →
    DatumObservationSound policy honestDatumRoot →
    ((WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
      (CompletenessSound policy ledger honestRoot layout ∧ AssetKeyLayout policy carries layout ∧
        policy.requireCompleteness = true)) →
    FoldDeterministic policy semantics → HistoryCommitmentInjective policy semantics →
    HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory →
    operation policy publications selectedPoint provider = .ok claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      claim.query = policy.query ∧
      claim.result.transactions = (honestHistory policy.query selectedPoint).filter policy.relevant ∧
      ∃ entry honestState, entry ∈ ledger selectedPoint ∧ carries entry.2 policy.asset ∧
        (∀ other ∈ ledger selectedPoint, carries other.2 policy.asset → other = entry) ∧
        honestDatumRoot policy.schema entry.2 = some claim.appRoot ∧
        semantics policy.initial
          ((honestHistory policy.query selectedPoint).filter policy.relevant) honestState ∧
        claim.result.state = honestState ∧ policy.historyRoot honestState = claim.appRoot

-- Two histories with the same relevant subsequence, offered on every session of one provider,
-- give the same complete outcome. No cryptographic or semantic premise.
def HistorySupersetTolerance
    (operation : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim) :
    Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (first second : List Reconstruction),
    first.filter policy.relevant = second.filter policy.relevant →
    operation policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨first⟩))) =
      operation policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨second⟩)))

-- HistorySupersetTolerance for the classification.
def HistoryVerdictSupersetTolerance
    (operation : Policy → List Publication → Chainpoint → Provider → HistoryVerdict) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (first second : List Reconstruction),
    first.filter policy.relevant = second.filter policy.relevant →
    operation policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨first⟩))) =
      operation policy publications selectedPoint
        (fun point => (provider point).map (Session.withHistory (some ⟨second⟩)))

-- A verified history claim exists only when the verifier is configured, the offered session is
-- bound to the selected point and its witness checks under the root accepted in context.
def HistoryNoPromotion
    (operation : Policy → List Publication → Chainpoint → Provider → HistoryVerdict) : Prop :=
  ∀ policy publications selectedPoint provider claim,
    operation policy publications selectedPoint provider = .verified claim →
    policy.verifier = true ∧
    ∃ root session witness, acceptContextRoot policy publications selectedPoint = .ok root ∧
      provider selectedPoint = some session ∧ session.selectedPoint = selectedPoint ∧
      session.binding = .bound selectedPoint ∧ session.ledger.witness = some witness ∧
      policy.checkWitness witness root session.ledger.object = true ∧
      acceptHistory policy publications selectedPoint provider = .ok claim

end Lockness
