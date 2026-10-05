import Lockness.Counterexamples.ContextRefutation

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples
open Counterexamples.ContextExamples

private def expectContext (actual expected : Verdict) (accepted expectedAccept : Except Refusal Claim) :
    IO Bool := do
  if decide (actual = expected ∧ accepted = expectedAccept) then return true
  IO.eprintln s!"unexpected context outcome: verdict {reprStr actual}; accept {reprStr accepted}; expected verdict {reprStr expected}; accept {reprStr expectedAccept}"
  return false

-- Runs the real verdict and accept on one offer at the selected point.
private def observe (policy : Policy) (offered : List Publication) (provider : Provider)
    (expected : Verdict) (expectedAccept : Except Refusal Claim) :
    IO (Option (Verdict × Except Refusal Claim)) := do
  let actual := verdict policy offered selected provider builder
  let accepted := accept policy offered selected provider builder
  if ← expectContext actual expected accepted expectedAccept then return some (actual, accepted)
  return none

private def report (label : String) (policy : Policy) (actual : Verdict)
    (accepted : Except Refusal Claim) (extra : String) : IO UInt32 := do
  IO.println s!"context scenario={label} verdict={reprStr actual} accept={reprStr accepted} selected={reprStr selected} context={reprStr policy.context}{extra}"
  return 0

def contextScenario (scenario : String) : IO UInt32 := do
  -- Expected claims are evaluated from honest semantics, never typed in or read from accept.
  let some honest := semanticClaim false LedgerExamples.entry₁ finalQuery
    | IO.eprintln "honest semantics produced no claim"; return 1
  let refused : Verdict := .refused (.evidenceFailure selected)
  let refusedAccept : Except Refusal Claim := .error (.evidenceFailure selected)
  match scenario with
  | "honest" =>
    unless decide (honest.point.network = contextPolicy.context.network ∧
        honest.ledgerRoot.scheme ∈ contextPolicy.context.schemes) do return 1
    let some (actual, accepted) ← observe contextPolicy publications verifiedProvider
      (.verified honest) (.ok honest) | return 1
    report scenario contextPolicy actual accepted
      s!" network={reprStr honest.point.network} scheme={reprStr honest.ledgerRoot.scheme}"
  | "wrong-network-point" =>
    unless decide (selected.network ≠ wrongNetworkPolicy.context.network) do return 1
    let some (actual, accepted) ← observe wrongNetworkPolicy publications verifiedProvider
      refused refusedAccept | return 1
    -- The same selection with an unbound session: still refused, never unverified.
    let some (unbound, unboundAccepted) ← observe wrongNetworkPolicy publications unboundProvider
      refused refusedAccept | return 1
    report scenario wrongNetworkPolicy actual accepted
      s!" unbound-verdict={reprStr unbound} unbound-accept={reprStr unboundAccepted}"
  | "wrong-network-publication" =>
    unless decide (foreignPublication.key ∈ contextPolicy.trustedKeys ∧
        contextPolicy.verify foreignPublication = true ∧
        foreignPublication.point.slot = selected.slot ∧
        foreignPublication.point.blockHash = selected.blockHash ∧
        foreignPublication.point.network ≠ contextPolicy.context.network) do return 1
    unless decide (∀ publication ∈ onlyForeign, publication.key ∈ contextPolicy.trustedKeys ∧
        contextPolicy.verify publication = true ∧
        publication.point.network ≠ contextPolicy.context.network) do return 1
    -- A trusted foreign publication appended to the honest ones is ignored.
    let some (actual, accepted) ← observe contextPolicy (publications ++ [foreignPublication])
      verifiedProvider (.verified honest) (.ok honest) | return 1
    -- Foreign endorsements alone select no root for this context.
    let some (foreign, foreignAccepted) ← observe contextPolicy onlyForeign verifiedProvider
      (.refused (.noRoot selected)) (.error (.noRoot selected)) | return 1
    report scenario contextPolicy actual accepted
      s!" only-foreign-verdict={reprStr foreign} only-foreign-accept={reprStr foreignAccepted}"
  | "unaccepted-scheme" =>
    unless decide (honest.ledgerRoot.scheme ∉ unacceptedSchemePolicy.context.schemes) do return 1
    let some (actual, accepted) ← observe unacceptedSchemePolicy publications verifiedProvider
      refused refusedAccept | return 1
    report scenario unacceptedSchemePolicy actual accepted ""
  | "unbound-message" =>
    -- Every offered message names one point, on a network other than the context's.
    let some first := unboundMessagePublications.head? | return 1
    let some (named, _) := decodeMessage first.message | return 1
    unless decide (named.network ≠ signatureOnlyPolicy.context.network ∧
        ∀ publication ∈ unboundMessagePublications, publication.point = selected ∧
          (decodeMessage publication.message).map Prod.fst = some named) do return 1
    let some (actual, accepted) ← observe signatureOnlyPolicy unboundMessagePublications
      verifiedProvider (.verified honest) (.ok honest) | return 1
    report scenario signatureOnlyPolicy actual accepted s!" message-encodes={reprStr named}"
  | _ =>
    IO.eprintln "unknown context scenario; choose honest, wrong-network-point, wrong-network-publication, unaccepted-scheme or unbound-message"
    return 64

end Lockness.Sim
