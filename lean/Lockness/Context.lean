import Lockness.Root

namespace Lockness

-- Present and wrong: the selected point on another network, or the root that root acceptance
-- selects under a scheme the context does not accept. A publication's network is never read: one
-- on another network cannot endorse this point (full-point equality) and must not veto it.
def outOfContext (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) : Bool :=
  decide (selectedPoint.network ≠ policy.context.network) ||
  match acceptRoot policy publications selectedPoint with
  | .ok root => decide (root.scheme ∉ policy.context.schemes)
  | .error _ => false

-- Root acceptance in context: the guard, then the unchanged acceptRoot.
def acceptContextRoot (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) : Except Refusal Root :=
  if outOfContext policy publications selectedPoint then .error (.evidenceFailure selectedPoint)
  else acceptRoot policy publications selectedPoint

end Lockness
