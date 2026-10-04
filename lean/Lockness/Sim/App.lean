import Lockness.Counterexamples.AppFixtures
import Lockness.Counterexamples.AppAmbiguity

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples

private def expectClaim (actual expected : Except Refusal Claim) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected app outcome: {reprStr actual}; expected {reprStr expected}"
  return false

-- Expected claims are evaluated from honest semantics, never typed in or read from accept.
private def semantic (ambiguous : Bool) (entry : TxIn × TxOut) (query : AppQuery) :
    IO (Option Claim) := do
  let some claim := semanticClaim ambiguous entry query
    | IO.eprintln "honest semantics produced no claim"; return none
  return some claim

def appScenario (scenario : String) : IO UInt32 := do
  -- Root provenance comes from root acceptance, separately from every provider and builder.
  let endorsed := acceptRoot (appPolicy false finalQuery) publications selected
  let .ok independentRoot := endorsed | return 1
  unless decide (independentRoot = LedgerExamples.honestRoot selected) do return 1
  match scenario with
  | "honest" =>
    let policy := appPolicy false finalQuery
    let some expected ← semantic false LedgerExamples.entry₁ finalQuery | return 1
    for (provider, builder) in [(providerA, honestBuilder false proofA finalQuery),
        (providerB, honestBuilder false proofB finalQuery)] do
      unless ← expectClaim (accept policy publications selected provider builder) (.ok expected) do
        return 1
    unless decide (providerRootA ≠ providerRootB ∧ providerRootA ≠ independentRoot ∧
        providerRootB ≠ independentRoot ∧ proofA ≠ proofB) do return 1
    IO.println s!"verified-claim point={reprStr expected.point} ledger-root={reprStr expected.ledgerRoot} app-root={reprStr expected.appRoot} links={expected.links.length} value={reprStr expected.value} providers=2 builders=2 provider-roots=ignored proof-bytes=distinct assumptions=root-witness-encoding-asset-datum-one-shot-app-sound-nesting"
    return 0
  | "replaced-root" =>
    let policy := appPolicy false finalQuery
    let some appRoot := LedgerExamples.honestDatumRoot LedgerExamples.schema
      LedgerExamples.entry₁.2 | return 1
    let some claimed := replacingBuilder appRoot | return 1
    -- Every other guard passes and the proof is valid under the claimed root only.
    unless decide (claimed.root ≠ appRoot ∧ claimed.point = selected ∧
        claimed.application = finalQuery.application ∧ claimed.context = finalQuery.context ∧
        claimed.claim = finalQuery.claim) do return 1
    unless policy.checkApp claimed.proof claimed.root finalQuery claimed.value do return 1
    if policy.checkApp claimed.proof appRoot finalQuery claimed.value then return 1
    unless ← expectClaim (accept policy publications selected providerA replacingBuilder)
        (.error (.evidenceFailure selected)) do return 1
    unless ← expectClaim (accept policy publications selected providerA trueRootForgedBuilder)
        (.error (.evidenceFailure selected)) do return 1
    IO.println s!"evidence-failure point={reprStr selected} claimed-root={reprStr claimed.root} trusted-root={reprStr appRoot} proof-under-claimed-root=true proof-under-trusted-root=false surrounding-checks=true true-root-forged-value=refused"
    return 0
  | "nested" =>
    let policy := appPolicy false nestedQuery
    let some expected ← semantic false LedgerExamples.entry₁ nestedQuery | return 1
    unless decide (expected.links.length = 1) do return 1
    for (provider, builder) in [(providerA, honestBuilder false proofA nestedQuery),
        (providerB, honestBuilder false proofB nestedQuery)] do
      unless ← expectClaim (accept policy publications selected provider builder) (.ok expected) do
        return 1
    let refused : Except Refusal Claim := .error (.evidenceFailure selected)
    let secondLink := [
      ("bad-proof", secondLinkBuilder fun answer => some { answer with proof := badProof }),
      ("replaced-root", secondLinkBuilder fun answer =>
        some { answer with root := otherRoot, value := forgedValue }),
      ("absent", secondLinkBuilder fun _ => none)]
    for (_, builder) in secondLink do
      unless ← expectClaim (accept policy publications selected providerA builder) refused do
        return 1
    for fuel in [1, 0] do
      unless ← expectClaim (accept { policy with fuel := fuel } publications selected providerA
          (honestBuilder false proofA nestedQuery)) refused do return 1
    IO.println s!"verified-claim point={reprStr expected.point} app-root={reprStr expected.appRoot} links={reprStr expected.links} value={reprStr expected.value} checked-links=2 second-link-bad-proof=refused second-link-replaced-root=refused second-link-absent=refused fuel-1=refused fuel-0=refused partial-claim=none"
    return 0
  | "ambiguous-value" =>
    let policy := appPolicy true finalQuery
    unless decide (ambiguousValues.length = 2 ∧ firstValue ≠ secondValue) do return 1
    let first := accept policy publications selected providerA (choosingBuilder proofA firstValue)
    let second := accept policy publications selected providerB (choosingBuilder proofB secondValue)
    unless ← expectClaim first (.ok (ambiguousClaim firstValue)) do return 1
    unless ← expectClaim second (.ok (ambiguousClaim secondValue)) do return 1
    unless decide (first ≠ second) do return 1
    IO.println s!"ambiguous-value point={reprStr selected} first-value={reprStr firstValue} second-value={reprStr secondValue} accepted-claims=2 claims-differ=true app-functional=false provider-invariance=refuted"
    return 0
  | _ =>
    IO.eprintln "unknown app scenario; choose honest, replaced-root, nested or ambiguous-value"
    return 64

end Lockness.Sim
