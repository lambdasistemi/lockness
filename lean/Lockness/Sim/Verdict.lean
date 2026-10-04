import Lockness.Counterexamples.VerdictPromotion

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples

private def expectVerdict (actual expected : Verdict) (accepted expectedAccept : Except Refusal Claim) :
    IO Bool := do
  if decide (actual = expected ∧ accepted = expectedAccept) then return true
  IO.eprintln s!"unexpected verdict outcome: verdict {reprStr actual}; accept {reprStr accepted}; expected verdict {reprStr expected}; accept {reprStr expectedAccept}"
  return false

-- Runs the real verdict and accept on one offer and prints both with the selected point.
private def run (label : String) (policy : Policy) (provider : Provider)
    (expected : Verdict) (expectedAccept : Except Refusal Claim) : IO UInt32 := do
  let actual := verdict policy publications selected provider builder
  let accepted := accept policy publications selected provider builder
  unless ← expectVerdict actual expected accepted expectedAccept do return 1
  IO.println s!"verdict scenario={label} verdict={reprStr actual} accept={reprStr accepted} selected={reprStr selected}"
  return 0

def verdictScenario (scenario : String) : IO UInt32 := do
  -- Root provenance comes from root acceptance, separately from every provider.
  let .ok independentRoot := acceptRoot policy publications selected | return 1
  unless decide (independentRoot = LedgerExamples.honestRoot selected) do return 1
  -- Expected claims are evaluated from honest semantics, never typed in or read from accept.
  let some honest := semanticClaim false LedgerExamples.entry₁ finalQuery
    | IO.eprintln "honest semantics produced no claim"; return 1
  let refused : Except Refusal Claim := .error (.evidenceFailure selected)
  match scenario with
  | "verified" =>
    unless decide (verifiedSession.ledger.reconstruction.isSome) do return 1
    run scenario policy verifiedProvider (.verified honest) (.ok honest)
  | "no-witness" => run scenario policy noWitnessProvider (.unverified .noWitness) refused
  | "unbound-session" => run scenario policy unboundProvider (.unverified .unboundSession) refused
  | "no-verifier" => run scenario noVerifierPolicy verifiedProvider (.unverified .noVerifier) (.ok honest)
  | "wrong-witness" => run scenario policy wrongWitnessProvider (.refused (.evidenceFailure selected)) refused
  | "misbound" =>
    unless decide (otherPoint ≠ selected) do return 1
    run scenario policy misboundProvider (.refused (.evidenceFailure selected)) refused
  | "promoted" =>
    -- The impostor's honest claim exists; a promoted verdict would carry it.
    let some impostor := semanticClaim false LedgerExamples.impostor finalQuery | return 1
    unless decide (impostor ≠ honest) do return 1
    run scenario policy promotingProvider (.unverified .noWitness) refused
  | _ =>
    IO.eprintln "unknown verdict scenario; choose verified, no-witness, unbound-session, no-verifier, wrong-witness, misbound or promoted"
    return 64

end Lockness.Sim
