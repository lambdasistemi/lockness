import Lockness.Counterexamples.SessionMutation

namespace Lockness.Tests.Session
open Counterexamples Counterexamples.SessionExamples

theorem root_from_acceptance :
    acceptRoot twoKeyPolicy [honestPublication, secondPublication] point = .ok acceptedRoot := by decide

theorem honest_acquisition : acquire point honestProvider = .ok offered := by decide
theorem root_and_bytes_unchanged :
    (acquire point honestProvider).toOption = some ⟨point, acceptedRoot, ⟨point, [], [], acceptedRoot⟩⟩ := by decide

theorem absent_acquisition :
    acquire point absentProvider = .error (.unavailablePoint point) := by decide

theorem newer_refusal :
    acquire point newerProvider = .error (.unavailablePoint point) := by decide

theorem alternate_hash_refusal :
    acquire point (fun _ => some { offered with selectedPoint := { point with blockHash := [255, 0] } }) =
      .error (.unavailablePoint point) := by decide

theorem alternate_network_refusal :
    acquire point (fun _ => some { offered with selectedPoint := { point with network := [0, 255] } }) =
      .error (.unavailablePoint point) := by decide

theorem active_reads_repeat :
    readSession (.active offered) = .ok offered ∧
    SessionTransition (.active offered) (.active offered) :=
  ⟨by decide, .read offered⟩

theorem acquisition_reachable : SessionTransition (.requested point) (.active offered) :=
  .acquired point honestProvider offered honest_acquisition

theorem absence_reachable : SessionTransition (.requested point) (.unavailable point) :=
  .refused point absentProvider absent_acquisition

theorem expiry_reachable : SessionTransition (.active offered) (.expired offered) := .expire offered

theorem expiry_read_refusal :
    readSession (.expired offered) = .error (.unavailablePoint point) := by decide

theorem expired_read_observable : SessionTransition (.expired offered) (.expired offered) :=
  .expiredRead offered

theorem release_reachable : SessionTransition (.active offered) (.closed offered) := .release offered

theorem closed_read_refusal :
    readSession (.closed offered) = .error (.unavailablePoint point) := by decide

def lifecycleCheck : IO Unit := do
  let acquired := acquire point honestProvider
  unless decide (acquired = .ok offered) do throw (IO.userError "acquisition outcome changed")
  let .ok session := acquired | throw (IO.userError "active session unreachable")
  for _ in [0, 1] do
    unless decide (readSession (.active session) = .ok session) do
      throw (IO.userError "active read changed session")
  unless decide (readSession (.expired session) = .error (.unavailablePoint point)) do
    throw (IO.userError "expired read did not refuse original point")
  unless decide (readSession (.closed session) = .error (.unavailablePoint point)) do
    throw (IO.userError "closed read did not refuse original point")
  IO.println "SESSION-LIFECYCLE acquisition=active repeated-reads=2 expiry-read=unavailablePoint release=closed"

#eval lifecycleCheck

end Lockness.Tests.Session
