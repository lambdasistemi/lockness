import Lockness.Types

namespace Lockness

-- The canonical branch, empty for the empty chain.
def tip (chain : Chain) : Branch := chain.headD []

def canonical (point : Chainpoint) (chain : Chain) : Prop := point ∈ tip chain

instance (point : Chainpoint) (chain : Chain) : Decidable (canonical point chain) :=
  inferInstanceAs (Decidable (point ∈ tip chain))

-- Replaces the newest `depth` points of the canonical branch with `fork`; the replaced branch is
-- kept behind it. Growth is a rollback of depth zero.
def rollback (depth : Nat) (fork : Branch) (chain : Chain) : Chain :=
  ((tip chain).take ((tip chain).length - depth) ++ fork) :: chain

-- Every possible future: growth, rollback and forks of any depth.
inductive Extends : Chain → Chain → Prop
  | refl (chain : Chain) : Extends chain chain
  | step {chain later : Chain} (depth : Nat) (fork : Branch) :
      Extends chain later → Extends chain (rollback depth fork later)

-- A hypothesis about which possible futures the network's consensus admits, never computed.
-- Each instance is arbitrary: it is not a consensus protocol and fixes no depth.
class ConsensusModel where
  admits : Chain → Chain → Prop

-- The hypothesis behind the settlement observation, never computed and fixing no depth: a point
-- the observation accepts in a chain stays canonical in every possible future consensus admits.
def ContinuedAncestry [ConsensusModel] (policy : Policy) : Prop :=
  ∀ point chain chain', policy.settlement point chain = true → Extends chain chain' →
    ConsensusModel.admits chain chain' → canonical point chain'

theorem rollback_extends (depth : Nat) (fork : Branch) (chain : Chain) :
    Extends chain (rollback depth fork chain) :=
  .step depth fork (.refl chain)

theorem extends_trans {first second third : Chain} (one : Extends first second)
    (two : Extends second third) : Extends first third := by
  induction two with
  | refl => exact one
  | step depth fork _ earlier => exact .step depth fork earlier

theorem rollback_canonical (point : Chainpoint) (depth : Nat) (fork : Branch) (chain : Chain) :
    canonical point (rollback depth fork chain) ↔
      point ∈ (tip chain).take ((tip chain).length - depth) ∨ point ∈ fork := by
  show point ∈ (tip chain).take ((tip chain).length - depth) ++ fork ↔ _
  exact List.mem_append

end Lockness
