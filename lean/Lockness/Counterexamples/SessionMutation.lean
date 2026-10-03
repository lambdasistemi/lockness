import Lockness.Session
import Lockness.Counterexamples.Fixtures

namespace Lockness.Counterexamples.SessionExamples

-- Root provenance comes from the independently evaluated root operation.
def acceptedRoot : Root :=
  match acceptRoot twoKeyPolicy [honestPublication, secondPublication] point with
  | .ok value => value
  | .error _ => root

def offered : Session := ⟨point, acceptedRoot⟩
def honestProvider : Provider := fun _ => some offered
def absentProvider : Provider := fun _ => none
def newer : Session := { offered with selectedPoint := { point with slot := point.slot + 1 } }
def newerProvider : Provider := fun _ => some newer

-- The operation argument can be the actual compiled production mutation.
theorem newer_refutes_no_substitution
    (operation : Chainpoint → Provider → Except Refusal Session)
    (accepted : operation point newerProvider = .ok newer) :
    ¬ NoSubstitution operation := by
  intro safe
  have equality := safe point newerProvider newer accepted
  have different : newer.point ≠ point := by decide
  exact different equality

end Lockness.Counterexamples.SessionExamples
