import Lockness.Types
import Mathlib.Data.Set.Defs

namespace Lockness

-- An application evidence supplier carries no correctness or availability assumption.
abbrev Builder := Root → Option AppAnswer

-- Honest application content committed by each root; one query may have several values.
abbrev AppTree := Root → Set (AppQuery × AppValue)

def AppSound (policy : Policy) (tree : AppTree) : Prop :=
  ∀ proof root query value, policy.checkApp proof root query value = true →
    (query, value) ∈ tree root

-- The binding premise, separate from AppSound: membership alone is not uniqueness.
def AppFunctional (tree : AppTree) : Prop :=
  ∀ root query first second, (query, first) ∈ tree root → (query, second) ∈ tree root →
    first = second

-- Both directions: a value the policy reads as final is honestly final.
def NestingInterpretationFaithful (policy : Policy) (honestNext : AppValue → Option Root) :
    Prop :=
  ∀ value, policy.nextRoot value = honestNext value

inductive ChainHolds (tree : AppTree) (honestNext : AppValue → Option Root) (query : AppQuery) :
    Root → List Root → AppValue → Prop where
  | final (root : Root) (value : AppValue) (member : (query, value) ∈ tree root)
      (last : honestNext value = none) : ChainHolds tree honestNext query root [] value
  | link (root next : Root) (carrier : AppValue) (rest : List Root) (value : AppValue)
      (member : (query, carrier) ∈ tree root) (carries : honestNext carrier = some next)
      (tail : ChainHolds tree honestNext query next rest value) :
      ChainHolds tree honestNext query root (next :: rest) value

theorem chainHolds_nil {tree : AppTree} {honestNext : AppValue → Option Root} {query : AppQuery}
    {root : Root} {value : AppValue} (chain : ChainHolds tree honestNext query root [] value) :
    (query, value) ∈ tree root ∧ honestNext value = none := by
  cases chain with
  | final _ _ member last => exact ⟨member, last⟩

-- The trusted root is compared first and is the only root the proof is checked under.
def verifyApp (policy : Policy) (selectedPoint : Chainpoint) :
    Root → AppAnswer → Except Refusal AppValue := fun root answer =>
  if answer.root = root then
    if answer.point = selectedPoint then
      if answer.application = policy.query.application ∧ answer.context = policy.query.context ∧
          answer.claim = policy.query.claim then
        if policy.checkApp answer.proof root policy.query answer.value = true then .ok answer.value
        else .error (.evidenceFailure selectedPoint)
      else .error (.evidenceFailure selectedPoint)
    else .error (.evidenceFailure selectedPoint)
  else .error (.evidenceFailure selectedPoint)

-- Fuel counts checked links; a pending root with no fuel left refuses the whole claim.
def verifyChain (policy : Policy) (selectedPoint : Chainpoint) (builder : Builder) :
    Nat → Root → Except Refusal (List Root × AppValue)
  | 0, _ => .error (.evidenceFailure selectedPoint)
  | fuel + 1, root =>
    match builder root with
    | none => .error (.evidenceFailure selectedPoint)
    | some answer =>
      match verifyApp policy selectedPoint root answer with
      | .error refusal => .error refusal
      | .ok value =>
        match policy.nextRoot value with
        | none => .ok ([], value)
        | some next =>
          match verifyChain policy selectedPoint builder fuel next with
          | .error refusal => .error refusal
          | .ok (links, final) => .ok (next :: links, final)

end Lockness
