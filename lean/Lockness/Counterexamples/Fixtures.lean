import Lockness.Root

namespace Lockness.Counterexamples

def point : Chainpoint := ⟨[0], 7, [0, 255]⟩
def root : Root := ⟨[0], [0, 255, 0]⟩
def honestPublication : Publication := ⟨[1], point, root, [0, 255, 0], [255, 0, 255]⟩
def secondPublication : Publication := { honestPublication with key := [2] }
def untrustedPublication : Publication := { honestPublication with key := [9] }
def honestPolicy : Policy := ⟨[[1]], fun keys => keys.length >= 1, fun _ => true, [], [], fun _ => none, fun _ => [],
  fun _ _ _ => false, fun _ => none, fun _ => none, fun _ _ => none, ⟨[], [], []⟩, fun _ _ _ _ => false,
  fun _ => none, 0, true, ⟨[0], [[0]]⟩, fun _ _ => false, fun _ => false,
  fun _ _ _ _ => false, fun _ => [], false, fun _ => false, fun state _ => state, [], fun _ => ⟨[], []⟩⟩
def twoKeyPolicy : Policy := ⟨[[1], [2]], fun keys => keys.length >= 2, fun _ => true, [], [], fun _ => none, fun _ => [],
  fun _ _ _ => false, fun _ => none, fun _ => none, fun _ _ => none, ⟨[], [], []⟩, fun _ _ _ _ => false,
  fun _ => none, 0, true, ⟨[0], [[0]]⟩, fun _ _ => false, fun _ => false,
  fun _ _ _ _ => false, fun _ => [], false, fun _ => false, fun state _ => state, [], fun _ => ⟨[], []⟩⟩
def untrustedPolicy : Policy := ⟨[], fun keys => keys.length >= 1, fun _ => true, [], [], fun _ => none, fun _ => [],
  fun _ _ _ => false, fun _ => none, fun _ => none, fun _ _ => none, ⟨[], [], []⟩, fun _ _ _ _ => false,
  fun _ => none, 0, true, ⟨[0], [[0]]⟩, fun _ _ => false, fun _ => false,
  fun _ _ _ _ => false, fun _ => [], false, fun _ => false, fun state _ => state, [], fun _ => ⟨[], []⟩⟩

-- Same search and agreement: remove only trusted-set filtering.
def acceptRootWithoutSubsetCheck (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) : Except Refusal Root :=
  selectRoot policy (observedKeys policy publications selectedPoint) selectedPoint
    (publications.map Publication.root)

end Lockness.Counterexamples
