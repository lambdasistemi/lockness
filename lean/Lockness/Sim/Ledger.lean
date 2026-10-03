import Mathlib.Data.Finset.Card
import Lockness.Counterexamples.LedgerRootMutation

namespace Lockness.Sim
open Counterexamples.LedgerExamples

private def expectLedger (actual expected : Except Refusal Root) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected ledger outcome: {reprStr actual}; expected {reprStr expected}"
  return false

def ledgerScenario (scenario : String) : IO UInt32 := do
  -- Root provenance is produced by root acceptance, separately from session data.
  let endorsed := acceptRoot Counterexamples.twoKeyPolicy
    [Counterexamples.honestPublication, Counterexamples.secondPublication] point
  let .ok independentRoot := endorsed | return 1
  let offered := session
  match scenario with
  | "honest" =>
    let result := verifyLedger (policyFor false) independentRoot offered answer₁
    let expected := honestDatumRoot schema entry₁.2
    let some root := expected | return 1
    unless ← expectLedger result (.ok root) do return 1
    unless decide ((ledgerFor false point).card = 1) do return 1
    IO.println s!"verified-ledger point={reprStr point} application-root={reprStr root} honest-members=1 provider-roots=ignored assumptions=witness-encoding-asset-datum-one-shot"
    return 0
  | "substituted-root" =>
    let policy := policyFor false
    unless policy.checkWitness substitutedAnswer.witness substitutedAnswer.root
        substitutedAnswer.object do return 1
    unless decide (policy.decodeObject substitutedAnswer.object = some impostor ∧
        policy.objectBytes impostor = substitutedAnswer.object ∧
        policy.assetOf impostor.2 = some asset ∧
        policy.datumOf impostor.2 = some appRoot₃.bytes ∧
        policy.parseDatum schema appRoot₃.bytes = some appRoot₃) do return 1
    if policy.checkWitness substitutedAnswer.witness independentRoot substitutedAnswer.object then return 1
    unless ← expectLedger (verifyLedger policy independentRoot offered substitutedAnswer)
        (.error (.evidenceFailure point)) do return 1
    IO.println s!"evidence-failure point={reprStr point} provider-root-witness=true accepted-root-witness=false surrounding-checks=true"
    return 0
  | "duplicate-asset" =>
    let policy := policyFor true
    let some firstRoot := honestDatumRoot schema entry₁.2 | return 1
    let some secondRoot := honestDatumRoot schema entry₂.2 | return 1
    unless ← expectLedger (verifyLedger policy independentRoot offered answer₁) (.ok firstRoot) do return 1
    unless ← expectLedger (verifyLedger policy independentRoot offered answer₂) (.ok secondRoot) do return 1
    unless decide (entry₁ ≠ entry₂ ∧ firstRoot ≠ secondRoot ∧
        (ledgerFor true point).card = 2 ∧ carries entry₁.2 asset ∧ carries entry₂.2 asset) do return 1
    IO.println s!"duplicate-asset point={reprStr point} honest-members=2 first-root={reprStr firstRoot} second-root={reprStr secondRoot} one-shot=false unique-output-guarantee=refuted"
    return 0
  | _ =>
    IO.eprintln "unknown ledger scenario; choose honest, substituted-root or duplicate-asset"
    return 64

end Lockness.Sim
