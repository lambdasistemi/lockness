import Lockness.Types

namespace Lockness

-- A provider offer carries no correctness or availability assumption.
abbrev Provider := Chainpoint → Option Session

def Session.point (session : Session) : Chainpoint := session.selectedPoint

def NoSubstitution (operation : Chainpoint → Provider → Except Refusal Session) : Prop :=
  ∀ point provider session, operation point provider = .ok session → session.point = point

def acquire (point : Chainpoint) (provider : Provider) : Except Refusal Session :=
  match provider point with
  | none => .error (.unavailablePoint point)
  | some session =>
    if session.point = point then .ok session else .error (.unavailablePoint point)

inductive SessionState where
  | requested (point : Chainpoint)
  | active (session : Session)
  | expired (session : Session)
  | closed (session : Session)
  | unavailable (point : Chainpoint)
  deriving DecidableEq, Repr

def readSession : SessionState → Except Refusal Session
  | .active session => .ok session
  | .requested point | .unavailable point => .error (.unavailablePoint point)
  | .expired session | .closed session => .error (.unavailablePoint session.point)

-- The relation names observations without choosing a clock, lease or branch policy.
inductive SessionTransition : SessionState → SessionState → Prop where
  | acquired (point : Chainpoint) (provider : Provider) (session : Session)
      (success : acquire point provider = .ok session) :
      SessionTransition (.requested point) (.active session)
  | refused (point : Chainpoint) (provider : Provider)
      (failed : acquire point provider = .error (.unavailablePoint point)) :
      SessionTransition (.requested point) (.unavailable point)
  | read (session : Session) : SessionTransition (.active session) (.active session)
  | expire (session : Session) : SessionTransition (.active session) (.expired session)
  | release (session : Session) : SessionTransition (.active session) (.closed session)
  | expiredRead (session : Session) : SessionTransition (.expired session) (.expired session)

-- Acquisition proofs

theorem acquire_no_substitution : NoSubstitution acquire := by
  intro point provider session success
  unfold acquire at success
  split at success
  · cases success
  · rename_i offered offer
    split at success
    · rename_i same
      cases success
      exact same
    · cases success

-- Inverting success preserves the entire offer, including exact root and byte fields.
theorem acquire_preserves_offer (point : Chainpoint) (provider : Provider) (session : Session)
    (success : acquire point provider = .ok session) : provider point = some session := by
  unfold acquire at success
  split at success
  · cases success
  · rename_i offered offer
    split at success
    · cases success
      exact offer
    · cases success

theorem acquire_absent (point : Chainpoint) (provider : Provider)
    (absent : provider point = none) : acquire point provider = .error (.unavailablePoint point) := by
  simp [acquire, absent]

theorem acquire_mismatch (point : Chainpoint) (provider : Provider) (session : Session)
    (offered : provider point = some session) (different : session.point ≠ point) :
    acquire point provider = .error (.unavailablePoint point) := by
  simp [acquire, offered, different]

theorem acquire_refusal (point : Chainpoint) (provider : Provider) (refusal : Refusal)
    (failed : acquire point provider = .error refusal) : refusal = .unavailablePoint point := by
  unfold acquire at failed
  split at failed
  · cases failed
    rfl
  · split at failed
    · cases failed
    · cases failed
      rfl

theorem active_read (session : Session) : readSession (.active session) = .ok session := rfl

theorem expired_read (session : Session) :
    readSession (.expired session) = .error (.unavailablePoint session.point) := rfl

theorem closed_read (session : Session) :
    readSession (.closed session) = .error (.unavailablePoint session.point) := rfl

theorem requested_transition (point : Chainpoint) (after : SessionState)
    (transition : SessionTransition (.requested point) after) :
    (∃ provider session, acquire point provider = .ok session ∧ after = .active session) ∨
      after = .unavailable point := by
  cases transition with
  | acquired _ provider session success => exact Or.inl ⟨provider, session, success, rfl⟩
  | refused => exact Or.inr rfl

theorem active_transition (session : Session) (after : SessionState)
    (transition : SessionTransition (.active session) after) :
    after = .active session ∨ after = .expired session ∨ after = .closed session := by
  cases transition with
  | read => exact Or.inl rfl
  | expire => exact Or.inr (Or.inl rfl)
  | release => exact Or.inr (Or.inr rfl)

theorem expired_transition (session : Session) (after : SessionState)
    (transition : SessionTransition (.expired session) after) : after = .expired session := by
  cases transition
  rfl

theorem closed_terminal (session : Session) (after : SessionState) :
    ¬ SessionTransition (.closed session) after := by
  intro transition
  cases transition

theorem unavailable_terminal (point : Chainpoint) (after : SessionState) :
    ¬ SessionTransition (.unavailable point) after := by
  intro transition
  cases transition

end Lockness
