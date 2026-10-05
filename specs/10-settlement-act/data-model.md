# Settlement and act data

As a reviewer, see every new or changed shared declaration, its validation and the invariants the act step relies on.

## Shared successor (Types)

| Declaration | Fields | Meaning |
| --- | --- | --- |
| `Branch` | `List Chainpoint` | One branch's points, oldest first |
| `Chain` | `List Branch` | Ground truth: the canonical branch first, then the branches it replaced, most recent first |
| `Reason` | unchanged constructors, moved before `Policy` | The type a policy field needs |
| `Policy.settlement` | `Chainpoint → Chain → Bool`, appended after `context` | The executable settlement observation on the terminal's chain view |
| `Policy.constructUnverified` | `Reason → Bool`, appended after `settlement` | The action rule: which unverified reasons still allow construction |

## Act data (Act, not Types)

| Declaration | Fields | Meaning |
| --- | --- | --- |
| `Action` | `construct`, `effect` | What is asked of the terminal |
| `Basis` | `claim (claim : Claim)`, `offer (reason : Reason) (session : Session)` | What an authorization rests on; an offer is construction material, never evidence |
| `Authorized` | `action : Action`, `point : Chainpoint`, `basis : Basis` | A granted action at the selected point |

## Chain data (Chain)

| Declaration | Kind | Meaning |
| --- | --- | --- |
| `Extends` | inductive relation | Every possible future: growth, rollback and forks of any depth |
| `ConsensusModel` | class, `admits : Chain → Chain → Prop` | Which possible futures consensus admits; an arbitrary hypothesis, never computed |
| `ContinuedAncestry` | `[ConsensusModel] (policy : Policy) → Prop` | A point the observation accepts stays canonical in every admitted possible future |

## Session successor (Session)

`SessionState.abandoned (session : Session)` and `SessionTransition.abandon (session) (chain) (gone : ¬ canonical session.point chain)` from `active` only.

## Neutral values for inherited constructions

`settlement := fun _ _ => false`, `constructUnverified := fun _ => false`. Nothing is settled and no unverified construction is allowed. No inherited declaration reads either field.

## Invariants

- The chain argument is the terminal's view, derived for a light terminal from accepted anchor publications; no provider, builder or publication supplies it or reaches `policy.settlement`.
- `act` reads the provider only through `acquire` at the selected point.
- Every refusal is `noRoot`, `unavailablePoint` or `evidenceFailure` at the selected point; every authorization is at the selected point and keeps the asked action.
- An effect needs `verified` at the selected point, a session bound to the selected point and the settlement observation; an unverified effect is always refused.
- Construction never reads the chain or the settlement observation.
- An abandoned session's reads are refused at its own point; it has no outgoing transition.
- No numeric depth or anchor count exists outside the fixture.
