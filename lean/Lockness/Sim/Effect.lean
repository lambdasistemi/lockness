import Lockness.Counterexamples.ActFixtures

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples
open Counterexamples.ContextExamples Counterexamples.ActExamples

-- One line per value, whatever its size.
private def line {α : Type} [Repr α] (value : α) : String := (repr value).pretty 1000000

private def expectEffect (label : String) (actual expected : Except Refusal Authorized) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected effect outcome: {label} {line actual}; expected {line expected}"
  return false

private def expectVerdict (label : String) (actual expected : Verdict) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected effect outcome: {label} verdict {line actual}; expected {line expected}"
  return false

private def expectFact (label : String) (holds : Bool) : IO Bool := do
  if holds then return true
  IO.eprintln s!"unexpected effect outcome: {label} does not hold"
  return false

def effectScenario (scenario : String) : IO UInt32 := do
  -- Expected claims are evaluated from honest semantics, never typed in or read from act.
  let some honest := semanticClaim false LedgerExamples.entry₁ finalQuery
    | IO.eprintln "honest semantics produced no claim"; return 1
  let refused : Except Refusal Authorized := .error (.evidenceFailure selected)
  -- The real verdict on the honest offer, then the real act on the terminal's chain view.
  let honestVerdict := verdict settledPolicy publications selected verifiedProvider builder
  match scenario with
  | "construct" =>
    unless ← expectVerdict "honest" honestVerdict (.verified honest) do return 1
    let atTip := act settledPolicy .construct honestVerdict verifiedProvider selected tipChain
    let atSettled := act settledPolicy .construct honestVerdict verifiedProvider selected settledChain
    let effect := act settledPolicy .effect honestVerdict verifiedProvider selected tipChain
    unless ← expectEffect "construct at tipChain" atTip (.ok ⟨.construct, selected, .claim honest⟩) do
      return 1
    unless ← expectEffect "construct at settledChain" atSettled (.ok ⟨.construct, selected, .claim honest⟩) do
      return 1
    unless ← expectEffect "effect at tipChain" effect refused do return 1
    IO.println s!"effect scenario=construct verdict={line honestVerdict} construct-at-tip={line atTip} construct-at-settled={line atSettled} effect-at-tip={line effect} selected={line selected}"
    return 0
  | "settled-effect" =>
    unless ← expectVerdict "honest" honestVerdict (.verified honest) do return 1
    let settled := settledPolicy.settlement selected settledChain
    unless ← expectFact "settlement at settledChain" settled do return 1
    let effect := act settledPolicy .effect honestVerdict verifiedProvider selected settledChain
    -- The same verdict handed to act with an offer that declares no binding.
    let unbound := act settledPolicy .effect honestVerdict unboundProvider selected settledChain
    unless ← expectEffect "effect at settledChain" effect (.ok ⟨.effect, selected, .claim honest⟩) do
      return 1
    unless ← expectEffect "effect with an unbound offer" unbound refused do return 1
    IO.println s!"effect scenario=settled-effect settlement={settled} effect={line effect} unbound-offer={line unbound} selected={line selected}"
    return 0
  | "rolled-back" =>
    unless ← expectVerdict "honest" honestVerdict (.verified honest) do return 1
    let before := act settledPolicy .effect honestVerdict verifiedProvider selected tipChain
    unless ← expectEffect "effect at tipChain" before refused do return 1
    -- The rollback is a possible future the fixture consensus admits.
    let _reached : Extends tipChain rolledChain := rolled_extends
    let _admitted : @ConsensusModel.admits fixtureConsensus tipChain rolledChain := rolled_admitted
    let admitted := (buried tipChain).isPrefixOf (tip rolledChain)
    unless ← expectFact "fixture admission of rolledChain" admitted do return 1
    unless ← expectFact "selected canonical in tipChain" (decide (canonical selected tipChain)) do
      return 1
    unless ← expectFact "selected gone from rolledChain" (decide (¬ canonical selected rolledChain)) do
      return 1
    -- The session at the rolled-back point is abandoned; its reads are refused at its own point.
    unless ← expectFact "session at selected" (decide (verifiedSession.point = selected)) do return 1
    let _abandon : SessionTransition (.active verifiedSession) (.abandoned verifiedSession) :=
      .abandon verifiedSession rolledChain (by decide)
    let read := readSession (.abandoned verifiedSession)
    unless decide (read = .error (.unavailablePoint selected)) do
      IO.eprintln s!"unexpected effect outcome: abandoned read {line read}"
      return 1
    let rolled := act settledPolicy .effect honestVerdict verifiedProvider selected rolledChain
    let regrown := act settledPolicy .effect honestVerdict verifiedProvider selected regrownChain
    unless ← expectEffect "effect at rolledChain" rolled refused do return 1
    unless ← expectEffect "effect at regrownChain" regrown refused do return 1
    IO.println s!"effect scenario=rolled-back effect-at-tip={line before} canonical-before={decide (canonical selected tipChain)} admitted={admitted} canonical-after={decide (canonical selected rolledChain)} abandoned-read={line read} effect-rolled={line rolled} effect-regrown={line regrown} selected={line selected}"
    return 0
  | "unverified-construct" =>
    let noWitness := verdict settledPolicy publications selected noWitnessProvider builder
    let noVerifier := verdict noVerifierSettledPolicy publications selected verifiedProvider builder
    let unboundVerdict := verdict settledPolicy publications selected unboundProvider builder
    unless ← expectVerdict "no witness" noWitness (.unverified .noWitness) do return 1
    unless ← expectVerdict "no verifier" noVerifier (.unverified .noVerifier) do return 1
    unless ← expectVerdict "unbound session" unboundVerdict (.unverified .unboundSession) do return 1
    let offered := act settledPolicy .construct noWitness noWitnessProvider selected tipChain
    unless ← expectEffect "construct on no witness" offered
        (.ok ⟨.construct, selected, .offer .noWitness noWitnessSession⟩) do return 1
    let denied := act noVerifierSettledPolicy .construct noVerifier verifiedProvider selected tipChain
    unless ← expectEffect "construct on no verifier" denied refused do return 1
    let unbound := act settledPolicy .construct unboundVerdict unboundProvider selected tipChain
    unless ← expectEffect "construct on unbound session" unbound refused do return 1
    -- The offer's reconstruction is construction material, never evidence.
    let material := match offered with
      | .ok ⟨_, _, .offer _ session⟩ => session.ledger.reconstruction
      | _ => none
    IO.println s!"effect scenario=unverified-construct no-witness={line offered} material={line material} no-verifier={line denied} unbound-session={line unbound} selected={line selected}"
    return 0
  | "unverified-effect" =>
    let noWitness := verdict settledPolicy publications selected noWitnessProvider builder
    let unboundVerdict := verdict settledPolicy publications selected unboundProvider builder
    let noVerifier := verdict noVerifierSettledPolicy publications selected verifiedProvider builder
    let outside :=
      verdict outOfContextNoVerifierPolicy publications selected verifiedProvider builder
    unless ← expectVerdict "no witness" noWitness (.unverified .noWitness) do return 1
    unless ← expectVerdict "unbound session" unboundVerdict (.unverified .unboundSession) do return 1
    unless ← expectVerdict "no verifier" noVerifier (.unverified .noVerifier) do return 1
    unless ← expectVerdict "no verifier out of context" outside (.unverified .noVerifier) do return 1
    unless ← expectFact "selection outside the declared network"
        (decide (selected.network ≠ outOfContextNoVerifierPolicy.context.network)) do return 1
    let first := act settledPolicy .effect noWitness noWitnessProvider selected settledChain
    let second := act settledPolicy .effect unboundVerdict unboundProvider selected settledChain
    let third := act noVerifierSettledPolicy .effect noVerifier verifiedProvider selected settledChain
    let fourth := act outOfContextNoVerifierPolicy .effect outside verifiedProvider selected settledChain
    unless ← expectEffect "effect on no witness" first refused do return 1
    unless ← expectEffect "effect on unbound session" second refused do return 1
    unless ← expectEffect "effect on no verifier" third refused do return 1
    unless ← expectEffect "effect on no verifier out of context" fourth refused do return 1
    IO.println s!"effect scenario=unverified-effect no-witness={line first} unbound-session={line second} no-verifier={line third} out-of-context-no-verifier={line fourth} context-network={line outOfContextNoVerifierPolicy.context.network} selected={line selected}"
    return 0
  | _ =>
    IO.eprintln "unknown effect scenario; choose construct, settled-effect, rolled-back, unverified-construct or unverified-effect"
    return 64

end Lockness.Sim
