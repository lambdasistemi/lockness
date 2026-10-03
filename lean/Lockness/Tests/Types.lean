import Lockness.Types

namespace Lockness.Tests

example : (show Bytes from [0, 255, 0]) ≠ [255, 0] := by decide
example : (show Bytes from [0, 255, 0]) ≠ [0, 0, 255] := by decide
example : (Chainpoint.mk [0] 5 [0, 255]) ≠ Chainpoint.mk [1] 5 [0, 255] := by decide
example : (Chainpoint.mk [0] 5 [0, 255]) ≠ Chainpoint.mk [0] 6 [0, 255] := by decide
example : (Chainpoint.mk [0] 5 [0, 255]) ≠ Chainpoint.mk [0] 5 [255, 0] := by decide
example : (Root.mk [0] [0, 255]) ≠ Root.mk [1] [0, 255] := by decide
example : (Root.mk [0] [0, 255]) ≠ Root.mk [0] [255, 0] := by decide
example (refusal : Refusal) :
    refusal = .noRoot refusal.selectedPoint ∨
    refusal = .unavailablePoint refusal.selectedPoint ∨
    refusal = .evidenceFailure refusal.selectedPoint := by
  cases refusal <;> simp [Refusal.selectedPoint]
example (point : Chainpoint) : (Refusal.noRoot point).selectedPoint = point := rfl
example (point : Chainpoint) : (Refusal.unavailablePoint point).selectedPoint = point := rfl
example (point : Chainpoint) : (Refusal.evidenceFailure point).selectedPoint = point := rfl
example (key message signature : Bytes) (point : Chainpoint) (root : Root) :
    (Publication.mk key point root signature message).message = message ∧
    (Publication.mk key point root signature message).signature = signature := ⟨rfl, rfl⟩

end Lockness.Tests
