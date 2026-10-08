import Lockness.Counterexamples.HistoryRefutation

namespace Lockness.Tests.History
open Counterexamples Counterexamples.AppExamples Counterexamples.LedgerExamples
open Counterexamples.VerdictExamples Counterexamples.CompletenessExamples
open Counterexamples.HistoryExamples

-- Released declarations and signatures.
example (transactions : List Reconstruction) : HistoryAnswer := ⟨transactions⟩
example : HistoryState = Bytes := rfl
example (policy : Policy) : Reconstruction → Bool := policy.relevant
example (policy : Policy) : HistoryState → Reconstruction → HistoryState := policy.fold
example (policy : Policy) : HistoryState := policy.initial
example (policy : Policy) : HistoryState → Root := policy.historyRoot
example (answer : LedgerAnswer) : Option HistoryAnswer := answer.history
example (answer : LedgerAnswer) : Option Reconstruction := answer.reconstruction
example (transactions : List Reconstruction) (state : HistoryState) : HistoryResult :=
  ⟨transactions, state⟩
example (point : Chainpoint) (ledgerRoot : Root) (query : AppQuery) (appRoot : Root)
    (result : HistoryResult) : HistoryClaim := ⟨point, ledgerRoot, query, appRoot, result⟩
example (claim : HistoryClaim) (refusal : Refusal) (reason : Reason) : List HistoryVerdict :=
  [.verified claim, .refused refusal, .unverified reason]
example : Policy → HistoryAnswer → List Reconstruction := relevantHistory
example : Policy → Chainpoint → Root → HistoryAnswer → Except Refusal HistoryResult := verifyHistory
example : Policy → List Publication → Chainpoint → Provider → Except Refusal HistoryClaim :=
  acceptHistory
example : Policy → List Publication → Chainpoint → Provider → HistoryVerdict := historyVerdict
example : Option HistoryAnswer → Session → Session := Session.withHistory
example : HistorySemantics = (HistoryState → List Reconstruction → HistoryState → Prop) := rfl

-- Ruled definitions, ascribed in full so that any change to one fails here.
example (policy : Policy) (semantics : HistorySemantics) :
    FoldDeterministic policy semantics ↔
      (∀ initial items, (∀ item ∈ items, policy.relevant item = true) →
        semantics initial items (items.foldl policy.fold initial)) ∧
      ∀ initial items first second, semantics initial items first →
        semantics initial items second → first = second := Iff.rfl
example (policy : Policy) (ledger : Ledger) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (semantics : HistorySemantics)
    (honestHistory : AppQuery → Chainpoint → List Reconstruction) :
    HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory ↔
      ∀ point entry, entry ∈ ledger point → carries entry.2 policy.asset →
        ∀ appRoot, honestDatumRoot policy.schema entry.2 = some appRoot →
          ∃ state, semantics policy.initial
            ((honestHistory policy.query point).filter policy.relevant) state ∧
            policy.historyRoot state = appRoot := Iff.rfl
example (policy : Policy) (semantics : HistorySemantics) :
    StateRootCollisionResistant policy semantics ↔
      ∀ first second firstState secondState,
        (∀ item ∈ first, policy.relevant item = true) →
        (∀ item ∈ second, policy.relevant item = true) →
        semantics policy.initial first firstState → semantics policy.initial second secondState →
        policy.historyRoot firstState = policy.historyRoot secondState →
        firstState = secondState := Iff.rfl
example (policy : Policy) (semantics : HistorySemantics) :
    HistoryCommitmentInjective policy semantics ↔
      ∀ first second firstState secondState,
        (∀ item ∈ first, policy.relevant item = true) →
        (∀ item ∈ second, policy.relevant item = true) →
        semantics policy.initial first firstState → semantics policy.initial second secondState →
        policy.historyRoot firstState = policy.historyRoot secondState → first = second := Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Provider →
      Except Refusal HistoryClaim) :
    HistoryStateSoundness operation ↔
      ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
        (provider : Provider) (claim : HistoryClaim) (ledger : Ledger)
        (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
        (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
        (semantics : HistorySemantics)
        (honestHistory : AppQuery → Chainpoint → List Reconstruction),
        HonestRootCorrespondence policy publications honestRoot →
        ObjectEncodingFaithful policy → AssetObservationSound policy carries →
        DatumObservationSound policy honestDatumRoot →
        ((WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
          (CompletenessSound policy ledger honestRoot layout ∧
            AssetKeyLayout policy carries layout ∧ policy.requireCompleteness = true)) →
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
            claim.result.state = honestState ∧ policy.historyRoot honestState = claim.appRoot :=
  Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Provider →
      Except Refusal HistoryClaim) :
    HistorySequenceSoundness operation ↔
      ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
        (provider : Provider) (claim : HistoryClaim) (ledger : Ledger)
        (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
        (honestDatumRoot : Schema → TxOut → Option Root) (layout : KeyLayout)
        (semantics : HistorySemantics)
        (honestHistory : AppQuery → Chainpoint → List Reconstruction),
        HonestRootCorrespondence policy publications honestRoot →
        ObjectEncodingFaithful policy → AssetObservationSound policy carries →
        DatumObservationSound policy honestDatumRoot →
        ((WitnessSound policy ledger honestRoot ∧ OneShot ledger policy.asset carries) ∨
          (CompletenessSound policy ledger honestRoot layout ∧
            AssetKeyLayout policy carries layout ∧ policy.requireCompleteness = true)) →
        FoldDeterministic policy semantics → HistoryCommitmentInjective policy semantics →
        HistoryCommitted policy ledger carries honestDatumRoot semantics honestHistory →
        operation policy publications selectedPoint provider = .ok claim →
        claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
          claim.query = policy.query ∧
          claim.result.transactions =
            (honestHistory policy.query selectedPoint).filter policy.relevant ∧
          ∃ entry honestState, entry ∈ ledger selectedPoint ∧ carries entry.2 policy.asset ∧
            (∀ other ∈ ledger selectedPoint, carries other.2 policy.asset → other = entry) ∧
            honestDatumRoot policy.schema entry.2 = some claim.appRoot ∧
            semantics policy.initial
              ((honestHistory policy.query selectedPoint).filter policy.relevant) honestState ∧
            claim.result.state = honestState ∧ policy.historyRoot honestState = claim.appRoot :=
  Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Provider →
      Except Refusal HistoryClaim) :
    HistorySupersetTolerance operation ↔
      ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
        (provider : Provider) (first second : List Reconstruction),
        first.filter policy.relevant = second.filter policy.relevant →
        operation policy publications selectedPoint
            (fun point => (provider point).map (Session.withHistory (some ⟨first⟩))) =
          operation policy publications selectedPoint
            (fun point => (provider point).map (Session.withHistory (some ⟨second⟩))) := Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Provider → HistoryVerdict) :
    HistoryVerdictSupersetTolerance operation ↔
      ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
        (provider : Provider) (first second : List Reconstruction),
        first.filter policy.relevant = second.filter policy.relevant →
        operation policy publications selectedPoint
            (fun point => (provider point).map (Session.withHistory (some ⟨first⟩))) =
          operation policy publications selectedPoint
            (fun point => (provider point).map (Session.withHistory (some ⟨second⟩))) := Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Provider → HistoryVerdict) :
    HistoryNoPromotion operation ↔
      ∀ policy publications selectedPoint provider claim,
        operation policy publications selectedPoint provider = .verified claim →
        policy.verifier = true ∧
        ∃ root session witness, acceptContextRoot policy publications selectedPoint = .ok root ∧
          provider selectedPoint = some session ∧ session.selectedPoint = selectedPoint ∧
          session.binding = .bound selectedPoint ∧ session.ledger.witness = some witness ∧
          policy.checkWitness witness root session.ledger.object = true ∧
          acceptHistory policy publications selectedPoint provider = .ok claim := Iff.rfl

-- The counterexample composition is acceptHistory when given the real check, so each variant
-- differs from production only in its history check.
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) :
    acceptHistoryUsing verifyHistory policy publications selectedPoint provider =
      acceptHistory policy publications selectedPoint provider := rfl

-- Selection and replacement as ruled: a filter in the provider's order; only history changes.
example (policy : Policy) (answer : HistoryAnswer) :
    relevantHistory policy answer = answer.transactions.filter policy.relevant := rfl
example (history : Option HistoryAnswer) (session : Session) :
    session.withHistory history = { session with ledger := { session.ledger with history := history } } :=
  rfl

-- Fixture provenance: the checking root is accepted independently and differs from the
-- provider's root; the expected datum root is read from honest datum semantics.
example : acceptRoot sequencePolicy publications selected = .ok (honestRoot selected) := by decide
example : providerRootA ≠ honestRoot selected := by decide
example : honestDatumRoot schema entry₁.2 = some honestAppRoot := by decide
example : (sequenceHistory sequencePolicy.query selected).length = 2 := by decide
example : ∀ item ∈ sequenceHistory sequencePolicy.query selected, item.spent ≠ [] := by decide
example : [itemA, itemB, itemC].Nodup ∧ sequencePolicy.relevant foreignItem = false := by decide

-- Joint inhabitation: every sequence premise and the honest acceptance on one input, through the
-- OneShot route and through the required-completeness route.
theorem sequence_oneshot_inhabited :
    HonestRootCorrespondence sequencePolicy publications honestRoot ∧
    ObjectEncodingFaithful sequencePolicy ∧ AssetObservationSound sequencePolicy carries ∧
    DatumObservationSound sequencePolicy honestDatumRoot ∧
    WitnessSound sequencePolicy (ledgerFor false) honestRoot ∧
    OneShot (ledgerFor false) sequencePolicy.asset carries ∧
    FoldDeterministic sequencePolicy tagSemantics ∧
    HistoryCommitmentInjective sequencePolicy tagSemantics ∧
    HistoryCommitted sequencePolicy (ledgerFor false) carries honestDatumRoot tagSemantics
      sequenceHistory ∧
    acceptHistory sequencePolicy publications selected (historyOffer [itemA, itemB]) =
      .ok (sequenceClaim sequencePolicy) :=
  ⟨sequence_oneshot_premises.1, sequence_oneshot_premises.2.1, sequence_oneshot_premises.2.2.1,
    sequence_oneshot_premises.2.2.2.1, sequence_oneshot_premises.2.2.2.2.1,
    sequence_oneshot_premises.2.2.2.2.2.1, sequence_oneshot_premises.2.2.2.2.2.2.1,
    sequence_oneshot_premises.2.2.2.2.2.2.2.1, sequence_oneshot_premises.2.2.2.2.2.2.2.2,
    by decide⟩

theorem sequence_required_inhabited :
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
      sequenceHistory ∧
    acceptHistory sequenceRequiredPolicy publications selected (requiredOffer [itemA, itemB]) =
      .ok (sequenceClaim sequenceRequiredPolicy) :=
  ⟨sequence_required_premises.1, sequence_required_premises.2.1,
    sequence_required_premises.2.2.1, sequence_required_premises.2.2.2.1,
    sequence_required_premises.2.2.2.2.1, sequence_required_premises.2.2.2.2.2.1,
    sequence_required_premises.2.2.2.2.2.2.1, sequence_required_premises.2.2.2.2.2.2.2.1,
    sequence_required_premises.2.2.2.2.2.2.2.2.1, sequence_required_premises.2.2.2.2.2.2.2.2.2,
    by decide⟩

-- The cancelling fold: every state premise, and an accepted history omitting the cancelling
-- pair whose rebuilt state is the honest state although its sequence is not the honest one.
theorem cancel_oneshot_inhabited :
    HonestRootCorrespondence cancelPolicy publications honestRoot ∧
    ObjectEncodingFaithful cancelPolicy ∧ AssetObservationSound cancelPolicy carries ∧
    DatumObservationSound cancelPolicy honestDatumRoot ∧
    WitnessSound cancelPolicy (ledgerFor false) honestRoot ∧
    OneShot (ledgerFor false) cancelPolicy.asset carries ∧
    FoldDeterministic cancelPolicy replaySemantics ∧
    StateRootCollisionResistant cancelPolicy replaySemantics ∧
    HistoryCommitted cancelPolicy (ledgerFor false) carries honestDatumRoot replaySemantics
      cancelHistory ∧
    acceptHistory cancelPolicy publications selected (historyOffer omittedPair) =
      .ok (cancelClaim cancelPolicy omittedPair) ∧
    (cancelClaim cancelPolicy omittedPair).result.transactions ≠
      (cancelHistory cancelPolicy.query selected).filter cancelPolicy.relevant :=
  ⟨cancel_oneshot_premises.1, cancel_oneshot_premises.2.1, cancel_oneshot_premises.2.2.1,
    cancel_oneshot_premises.2.2.2.1, cancel_oneshot_premises.2.2.2.2.1,
    cancel_oneshot_premises.2.2.2.2.2.1, cancel_oneshot_premises.2.2.2.2.2.2.1,
    cancel_oneshot_premises.2.2.2.2.2.2.2.1, cancel_oneshot_premises.2.2.2.2.2.2.2.2,
    by decide, by decide⟩

theorem cancel_required_inhabited :
    CompletenessSound cancelRequiredPolicy (ledgerOf false) honestRoot layout ∧
    StateRootCollisionResistant cancelRequiredPolicy replaySemantics ∧
    HistoryCommitted cancelRequiredPolicy (ledgerOf false) carries honestDatumRoot replaySemantics
      cancelHistory ∧
    acceptHistory cancelRequiredPolicy publications selected (requiredOffer omittedPair) =
      .ok (cancelClaim cancelRequiredPolicy omittedPair) :=
  ⟨cancel_required_premises.2.2.2.2.1, cancel_required_premises.2.2.2.2.2.2.2.2.1,
    cancel_required_premises.2.2.2.2.2.2.2.2.2, by decide⟩

-- Classification of the honest offer and of the declared absences.
def honest : HistoryClaim := sequenceClaim sequencePolicy
def refusedAtSelected : Except Refusal HistoryClaim := .error (.evidenceFailure selected)
def offerSession (session : Session) (items : Option (List Reconstruction)) : Provider :=
  offering (session.withHistory (items.map HistoryAnswer.mk))

example : historyVerdict sequencePolicy publications selected (historyOffer [itemA, itemB]) =
    .verified honest := by decide
-- Extras before, between and after the relevant items: the same complete claim and state.
example : acceptHistory sequencePolicy publications selected
    (historyOffer [foreignItem, itemA, foreignItem, itemB, foreignItem]) = .ok honest := by decide
example : historyVerdict sequencePolicy publications selected
    (historyOffer [foreignItem, itemA, foreignItem, itemB, foreignItem]) = .verified honest := by
  decide
-- Present and wrong histories are refused at the selected point and never unverified.
example : acceptHistory sequencePolicy publications selected (historyOffer []) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer [foreignItem]) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer [itemB, itemA]) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer [itemA, itemA, itemB]) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer [itemA, itemB, itemB]) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer forgedHistory) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected (historyOffer shortHistory) =
    refusedAtSelected := by decide
example : acceptHistory sequencePolicy publications selected
    (historyOffer [{ itemA with transaction := [11, 0, 254] }, itemB]) = refusedAtSelected := by
  decide
example : acceptHistory sequencePolicy publications selected
    (historyOffer [{ itemA with spent := [([1, 0, 255], [10, 0, 254])] }, itemB]) =
    refusedAtSelected := by decide
example : historyVerdict sequencePolicy publications selected (historyOffer forgedHistory) =
    .refused (.evidenceFailure selected) := by decide
example : historyVerdict sequencePolicy publications selected (historyOffer shortHistory) =
    .refused (.evidenceFailure selected) := by decide
-- An absent history is refused once the state output checks.
example : historyVerdict sequencePolicy publications selected verifiedProvider =
    .refused (.evidenceFailure selected) := by decide
-- Earlier boundaries keep their precedence over any history.
example : historyVerdict sequencePolicy [] selected (historyOffer forgedHistory) =
    .refused (.noRoot selected) := by decide
example : historyVerdict sequencePolicy publications selected (fun _ => none) =
    .refused (.unavailablePoint selected) := by decide
example : historyVerdict sequencePolicy publications selected
    (offerSession { verifiedSession with selectedPoint := otherPoint } (some [itemA, itemB])) =
    .refused (.unavailablePoint selected) := by decide
example : historyVerdict sequencePolicy publications selected
    (offerSession misboundSession (some [itemA, itemB])) =
    .refused (.evidenceFailure selected) := by decide
example : historyVerdict sequencePolicy publications selected
    (offerSession wrongWitnessSession (some [itemA, itemB])) =
    .refused (.evidenceFailure selected) := by decide
example : historyVerdict { sequencePolicy with verifier := false } [] selected
    (historyOffer forgedHistory) = .unverified .noVerifier := by decide
example : historyVerdict { sequencePolicy with verifier := false } publications selected
    (historyOffer [itemA, itemB]) = .unverified .noVerifier := by decide
-- History alone is not evidence: no witness and no completeness stays a declared absence.
example : historyVerdict sequencePolicy publications selected
    (offerSession noWitnessSession (some [itemA, itemB])) = .unverified .noWitness := by decide
example : historyVerdict sequencePolicy publications selected
    (offerSession unboundSession (some [itemA, itemB])) = .unverified .unboundSession := by decide
-- The required-completeness route refuses a witnessed answer without completeness.
example : historyVerdict sequenceRequiredPolicy publications selected (historyOffer [itemA, itemB]) =
    .refused (.evidenceFailure selected) := by decide
example : historyVerdict sequenceRequiredPolicy publications selected
    (requiredOffer [itemA, itemB]) = .verified (sequenceClaim sequenceRequiredPolicy) := by decide
-- The legacy reconstruction is not read by the history path.
example : historyVerdict sequencePolicy publications selected
    (fun point => (historyOffer [itemA, itemB] point).map (Session.withReconstruction none)) =
    .verified honest := by decide
-- The history field is not read by the inherited verdict.
example : verdict sequencePolicy publications selected (historyOffer forgedHistory) builder =
    verdict sequencePolicy publications selected verifiedProvider builder := by decide

-- Each in-model variant changes its witness outcome and refutes its unchanged guarantee.
example : acceptHistoryUsing verifyHistoryWithoutRootComparison sequencePolicy publications selected
    (historyOffer forgedHistory) = .ok forgedClaim := by decide
theorem withoutRootComparison_refutes :
    ¬ HistorySequenceSoundness (acceptHistoryUsing verifyHistoryWithoutRootComparison) :=
  forged_history_refutes_sequence_soundness _ (by decide)
theorem contextSelection_refutes :
    ¬ HistorySupersetTolerance (acceptHistoryUsing verifyHistoryWithContextSelection) :=
  context_selection_refutes_tolerance _ (by decide) (by decide)
theorem comparingScheme_refutes :
    ¬ HistoryStateSoundness (acceptHistoryUsing verifyHistoryComparingScheme) :=
  weaker_projection_refutes_state_soundness _ (by decide)
-- The real path refuses every witness input that a variant accepts.
example : acceptHistory sequencePolicy publications selected (historyOffer paddedHistory) =
    .ok honest := by decide
example : acceptHistory cancelPolicy publications selected (historyOffer shortHistory) =
    refusedAtSelected := by decide

end Lockness.Tests.History
