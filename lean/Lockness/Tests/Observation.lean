import Lockness.Root

namespace Lockness.Tests

def point : Chainpoint := ⟨[0], 7, [0, 255]⟩
def root : Root := ⟨[0], [0, 255, 0]⟩
def publication : Publication := ⟨[1], point, root, [0, 255, 0], [255, 0, 255]⟩
def policy : Policy := ⟨[[1]], fun keys => keys.length >= 1, fun _ => true, [], [], fun _ => none, fun _ => [],
  fun _ _ _ => false, fun _ => none, fun _ => none, fun _ _ => none⟩

example : acceptRoot policy [publication] point = .ok root := by decide
example : acceptRoot { policy with verify := fun _ => false } [publication] point =
    .error (.noRoot point) := by decide
example : acceptRoot policy [{ publication with point := { point with slot := 8 } }]
    point = .error (.noRoot point) := by decide
example : acceptRoot policy [{ publication with point := { point with network := [1] } }]
    point = .error (.noRoot point) := by decide
example : acceptRoot policy [{ publication with point := { point with blockHash := [255, 0] } }]
    point = .error (.noRoot point) := by decide
example : acceptRoot policy
    [{ publication with message := [0, 255, 0], signature := [255, 0, 255] }] point =
    .ok root := by decide
-- Observations can inspect the original bytes: acceptance performs no normalization.
example : acceptRoot { policy with verify := (fun pub => decide (pub.message = [255, 0, 255] ∧ pub.signature = [0, 255, 0])) }
    [publication] point = .ok root := by decide
example : acceptRoot { policy with verify := (fun pub => decide (pub.message = [255, 0, 255] ∧ pub.signature = [0, 255, 0])) }
    [{ publication with signature := [255, 0, 0] }] point = .error (.noRoot point) := by decide
example : acceptRoot { policy with verify := (fun pub => decide (pub.message = [255, 0, 255] ∧ pub.signature = [0, 255, 0])) }
    [{ publication with message := [0, 255, 255] }] point = .error (.noRoot point) := by decide
-- SigValid has exactly one explicit argument; the arbitrary predicate is implicit.
example [SignatureModel] : Publication → Prop := SigValid
example : Policy → List Publication → Chainpoint → Except Refusal Root := acceptRoot

end Lockness.Tests
