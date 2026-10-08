import Lockness.Counterexamples.HistoryRefutation

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples Counterexamples.LedgerExamples
open Counterexamples.VerdictExamples Counterexamples.HistoryExamples

private def expectHistory (label : String) (actual : HistoryVerdict) (expected : HistoryVerdict)
    (accepted expectedAccept : Except Refusal HistoryClaim) : IO Bool := do
  if decide (actual = expected ∧ accepted = expectedAccept) then return true
  IO.eprintln s!"unexpected history outcome: {label} verdict {reprStr actual}; accept {reprStr accepted}; expected verdict {reprStr expected}; accept {reprStr expectedAccept}"
  return false

private def expectVariant (label : String) (actual expected : Except Refusal HistoryClaim) :
    IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected history outcome: {label} {reprStr actual}; expected {reprStr expected}"
  return false

-- Runs the real classification and acceptance on one offer.
private def run (label : String) (policy : Policy) (provider : Provider)
    (expected : HistoryVerdict) (expectedAccept : Except Refusal HistoryClaim) : IO Bool := do
  let actual := historyVerdict policy publications selected provider
  let accepted := acceptHistory policy publications selected provider
  unless ← expectHistory label actual expected accepted expectedAccept do return false
  IO.println s!"history scenario={label} verdict={reprStr actual} selected={reprStr selected}"
  return true

private def names (items : List Reconstruction) : String :=
  ", ".intercalate (items.map fun item =>
    if item = itemA then "itemA" else if item = itemB then "itemB" else if item = itemC then "itemC"
    else if item = itemPut then "itemPut" else if item = itemTake then "itemTake"
    else if item = foreignItem then "foreignItem" else reprStr item)

def historyScenario (scenario : String) : IO UInt32 := do
  -- Root provenance: root acceptance from publications alone, never from a provider.
  let .ok independentRoot := acceptRoot sequencePolicy publications selected | return 1
  unless decide (independentRoot = honestRoot selected ∧ independentRoot ≠ providerRootA) do
    return 1
  -- Expected claims come from honest semantics, never typed in or read from acceptance.
  let honest := sequenceClaim sequencePolicy
  let honestRelevant := (sequenceHistory sequencePolicy.query selected).filter sequencePolicy.relevant
  unless decide (honestDatumRoot schema entry₁.2 = some honest.appRoot) do return 1
  let refused : Except Refusal HistoryClaim := .error (.evidenceFailure selected)
  let provenance := s!"accepted-root={reprStr independentRoot} provider-root={reprStr providerRootA} checking-root=verified-state-output-datum {reprStr honest.appRoot}"
  match scenario with
  | "accepted" =>
    unless ← run scenario sequencePolicy (historyOffer [itemA, itemB]) (.verified honest) (.ok honest) do
      return 1
    IO.println s!"{provenance} honest-relevant=[{names honestRelevant}] rebuilt-root={reprStr (sequencePolicy.historyRoot honest.result.state)}"
    return 0
  | "forged-transaction" =>
    unless ← run scenario sequencePolicy (historyOffer forgedHistory)
        (.refused (.evidenceFailure selected)) refused do return 1
    IO.println s!"{provenance} offered=[{names forgedHistory}] honest-relevant=[{names honestRelevant}] rebuilt-root={reprStr (sequencePolicy.historyRoot (forgedHistory.foldl sequencePolicy.fold sequencePolicy.initial))} refused; never unverified"
    return 0
  | "missing-relevant" =>
    unless ← run scenario sequencePolicy (historyOffer shortHistory)
        (.refused (.evidenceFailure selected)) refused do return 1
    IO.println s!"{provenance} offered=[{names shortHistory}] honest-relevant=[{names honestRelevant}] refused; never unverified"
    return 0
  | "irrelevant-extras" =>
    let extras := [foreignItem, itemA, foreignItem, itemB, foreignItem]
    unless ← run scenario sequencePolicy (historyOffer extras) (.verified honest) (.ok honest) do
      return 1
    unless decide (acceptHistory sequencePolicy publications selected (historyOffer extras) =
        acceptHistory sequencePolicy publications selected (historyOffer [itemA, itemB])) do
      IO.eprintln "unexpected history outcome: extras changed the complete claim"; return 1
    IO.println s!"{provenance} offered=[{names extras}] claim and state equal to accepted"
    return 0
  | "root-comparison-removed" =>
    unless ← run scenario sequencePolicy (historyOffer forgedHistory)
        (.refused (.evidenceFailure selected)) refused do return 1
    let mutant := acceptHistoryUsing verifyHistoryWithoutRootComparison sequencePolicy publications
      selected (historyOffer forgedHistory)
    unless ← expectVariant "root-comparison-removed variant" mutant (.ok forgedClaim) do return 1
    unless decide (forgedClaim.result.transactions ≠ honestRelevant) do return 1
    IO.println s!"{provenance} root-comparison-removed accepted=[{names forgedClaim.result.transactions}] honest-relevant=[{names honestRelevant}]; unchanged HistorySequenceSoundness refuted with every premise held"
    return 0
  | "context-dependent-relevance" =>
    unless ← run scenario sequencePolicy (historyOffer paddedHistory) (.verified honest) (.ok honest) do
      return 1
    let variant := acceptHistoryUsing verifyHistoryWithContextSelection sequencePolicy publications
      selected
    unless ← expectVariant "context-dependent-relevance variant" (variant (historyOffer omittedPair))
        (.ok honest) do return 1
    unless ← expectVariant "context-dependent-relevance variant" (variant (historyOffer paddedHistory))
        refused do return 1
    unless decide (paddedHistory.filter sequencePolicy.relevant =
        omittedPair.filter sequencePolicy.relevant) do return 1
    IO.println s!"{provenance} context-dependent-relevance offered=[{names paddedHistory}] local-selection=verified context-selection=refused; equal relevant filters; unchanged HistorySupersetTolerance refuted"
    return 0
  | "cancelling-pair" =>
    let claim := cancelClaim cancelPolicy omittedPair
    let honestCancel := (cancelHistory cancelPolicy.query selected).filter cancelPolicy.relevant
    let honestState := replay cancelPolicy.initial honestCancel
    unless ← run scenario cancelPolicy (historyOffer omittedPair) (.verified claim) (.ok claim) do
      return 1
    unless decide (claim.result.state = honestState) do return 1
    unless decide (claim.result.transactions ≠ honestCancel) do return 1
    IO.println s!"cancelling-pair verified state={reprStr claim.result.state} honest-state={reprStr honestState} equal; accepted-sequence=[{names claim.result.transactions}] honest-sequence=[{names honestCancel}] unequal"
    IO.println "cancelling-pair state soundness holds under StateRootCollisionResistant; sequence soundness does not apply: HistoryCommitmentInjective fails for this fold, whose two different relevant histories reach one root"
    return 0
  | _ =>
    IO.eprintln "unknown history scenario; choose accepted, forged-transaction, missing-relevant, irrelevant-extras, root-comparison-removed, context-dependent-relevance or cancelling-pair"
    return 64

end Lockness.Sim
