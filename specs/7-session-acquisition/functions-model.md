# Session operation contracts

As a reviewer, read the public session operations and universal guarantees separately from their implementation.

| Name | Explicit arguments | Result and constraint |
| --- | --- | --- |
| `Session.point` | `session : Session` | `Chainpoint`; definitionally the stored selected point |
| `acquire` | `point : Chainpoint`, `provider : Provider` | `Except Refusal Session`; successful full point equality, absent/mismatched selected-point refusal, returned root preservation |
| `NoSubstitution` | `operation : Chainpoint → Provider → Except Refusal Session` | `Prop`; for every point, provider and successful session, its point equals the selected point |
| `acquire_no_substitution` | Universal point/provider/session and successful-acquisition premise | Proof of full point equality; no honesty hypothesis |
| `acquire_absent` | `point : Chainpoint`, `provider : Provider`, premise that provider at point is absent | Proof that acquisition equals selected-point unavailable refusal |
| `readSession` | `state : SessionState` | `Except Refusal Session`; active reads return the same session; expired reads refuse at its point |
| `SessionTransition` | `before : SessionState`, `after : SessionState` | `Prop`; only declared lifecycle transitions |
| `sessionScenario` | `scenario : String` | `IO UInt32`; real model assertions; unknown scenario is usage failure |

Supporting named proofs and test declarations may refine these guarantees within the released modules. A public signature or placement conflict returns to TO before implementation.
