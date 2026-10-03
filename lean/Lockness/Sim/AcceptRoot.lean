import Lockness.Counterexamples.SubsetMutation

namespace Lockness.Sim
open Counterexamples

private def expect (actual expected : Except Refusal Root) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected outcome: {reprStr actual}; expected {reprStr expected}"
  return false

def acceptRootScenario (scenario : String) : IO UInt32 := do
  match scenario with
  | "honest" =>
    let publications := [honestPublication, secondPublication, honestPublication]
    let result := acceptRoot twoKeyPolicy publications point
    unless ← expect result (.ok root) do return 1
    let keys := endorsingKeys twoKeyPolicy publications point root
    unless decide (keys.length = 2) do return 1
    IO.println s!"accepted-root point={reprStr point} root={reprStr root} distinct-endorsers={keys.length}"
    return 0
  | "untrusted-key" =>
    let result := acceptRoot untrustedPolicy [untrustedPublication] point
    unless ← expect result (.error (.noRoot point)) do return 1
    IO.println s!"no-root point={reprStr point} signature-validity=abstract-assumption key=untrusted"
    return 0
  | "subset-mutation" =>
    let publications := [untrustedPublication]
    unless ← expect (acceptRoot untrustedPolicy publications point) (.error (.noRoot point)) do return 1
    unless ← expect (acceptRootWithoutSubsetCheck untrustedPolicy publications point) (.ok root) do return 1
    let keys := observedKeys untrustedPolicy publications point root
    if keys.all (fun key => decide (key ∈ untrustedPolicy.trustedKeys)) then return 1
    IO.println s!"subset-mutation accepted-untrusted-root point={reprStr point} root={reprStr root}; unchanged RootSafety refuted"
    return 0
  | _ =>
    IO.eprintln "unknown accept-root scenario; choose honest, untrusted-key or subset-mutation"
    return 64

end Lockness.Sim
