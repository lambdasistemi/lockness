import Lockness.Counterexamples.SessionMutation

namespace Lockness.Sim
open Counterexamples Counterexamples.SessionExamples

private def expectSession (actual expected : Except Refusal Session) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected session outcome: {reprStr actual}; expected {reprStr expected}"
  return false

def sessionScenario (scenario : String) : IO UInt32 := do
  match scenario with
  | "honest" =>
    -- Independently obtain the root before offering any session to acquisition.
    let rootResult := acceptRoot twoKeyPolicy [honestPublication, secondPublication] point
    let .ok chosenRoot := rootResult | return 1
    let offer : Session := ⟨point, chosenRoot, ⟨point, [], some [], chosenRoot, none⟩, .bound point⟩
    let result := acquire point (fun _ => some offer)
    unless ← expectSession result (.ok offer) do return 1
    let .ok session := result | return 1
    for _ in [0, 1] do
      unless ← expectSession (readSession (.active session)) (.ok session) do return 1
    unless ← expectSession (readSession (.expired session)) (.error (.unavailablePoint point)) do return 1
    unless ← expectSession (readSession (.closed session)) (.error (.unavailablePoint point)) do return 1
    IO.println s!"active-session point={reprStr session.point} root={reprStr session.acceptedRoot} repeated-reads=2 expiry-read=unavailablePoint release=closed"
    return 0
  | "absent-point" =>
    let result := acquire point absentProvider
    unless ← expectSession result (.error (.unavailablePoint point)) do return 1
    IO.println s!"unavailable-point selected={reprStr point} provider=absent"
    return 0
  | "newer-point" =>
    let result := acquire point newerProvider
    unless ← expectSession result (.error (.unavailablePoint point)) do return 1
    let alternateHash : Session := { offered with selectedPoint := { point with blockHash := [255, 0] } }
    let alternateNetwork : Session := { offered with selectedPoint := { point with network := [0, 255] } }
    for alternative in [alternateHash, alternateNetwork] do
      unless ← expectSession (acquire point (fun _ => some alternative))
          (.error (.unavailablePoint point)) do return 1
    IO.println s!"unavailable-point selected={reprStr point} offered={reprStr newer.point} substitution=refused alternate-hash=refused alternate-network=refused"
    return 0
  | _ =>
    IO.eprintln "unknown session scenario; choose honest, absent-point or newer-point"
    return 64

end Lockness.Sim
