import Lockness.Verdict
import Lockness.Chain

namespace Lockness

-- What is asked of the terminal: build a transaction, or perform an external effect.
inductive Action where
  | construct
  | effect
  deriving DecidableEq, Repr

-- What an authorization rests on: a verified claim, or an unverified offer whose reconstruction
-- material the action rule admits for construction; that material is never evidence.
inductive Basis where
  | claim (claim : Claim)
  | offer (reason : Reason) (session : Session)
  deriving DecidableEq, Repr

-- A granted action at the selected point.
structure Authorized where
  action : Action
  point : Chainpoint
  basis : Basis
  deriving DecidableEq, Repr

-- The last step after the verdict. The chain is the terminal's own view, never supplied by a
-- provider, builder or publication; the provider is read only through acquire at the selected
-- point. Construction reads neither the chain nor the settlement observation; an effect needs a
-- verified claim, an offer bound to the selected point and the policy's settlement observation.
def act (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) : Except Refusal Authorized :=
  match verdict with
  | .refused refusal =>
    .error (if refusal.selectedPoint = selectedPoint then refusal else .evidenceFailure selectedPoint)
  | .verified claim =>
    if claim.point ≠ selectedPoint then .error (.evidenceFailure selectedPoint) else
    match action with
    | .construct => .ok ⟨.construct, selectedPoint, .claim claim⟩
    | .effect =>
      match acquire selectedPoint provider with
      | .error refusal => .error refusal
      | .ok session =>
        if session.binding = .bound selectedPoint then
          if policy.settlement selectedPoint chain then .ok ⟨.effect, selectedPoint, .claim claim⟩
          else .error (.evidenceFailure selectedPoint)
        else .error (.evidenceFailure selectedPoint)
  | .unverified reason =>
    match action with
    | .effect => .error (.evidenceFailure selectedPoint)
    | .construct =>
      if policy.constructUnverified reason then
        match acquire selectedPoint provider with
        | .error refusal => .error refusal
        | .ok session => .ok ⟨.construct, selectedPoint, .offer reason session⟩
      else .error (.evidenceFailure selectedPoint)

-- Under the continued-ancestry hypothesis, a successful effect keeps the selected point canonical
-- in every possible future the consensus model admits.
def SettlementStability [ConsensusModel]
    (operation : Policy → Action → Verdict → Provider → Chainpoint → Chain →
      Except Refusal Authorized) : Prop :=
  ∀ policy verdict provider selectedPoint chain authorized, ContinuedAncestry policy →
    operation policy .effect verdict provider selectedPoint chain = .ok authorized →
    ∀ chain', Extends chain chain' → ConsensusModel.admits chain chain' →
      canonical selectedPoint chain'

end Lockness
