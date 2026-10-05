# Settlement and act functions

As a reviewer, see every new or changed signature with explicit argument names. Statements are as ruled in settlement-interface-v1 (answers/A-001); the exact frozen text is in the ticket gate.

## Changed

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `readSession` | unchanged signature | `abandoned` reads refuse with `unavailablePoint` at the session's point |
| `active_transition` | inherited binders | Conclusion gains `∨ after = .abandoned session`; the only restatement |

## New

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `tip` | `(chain : Chain) → Branch` | The canonical branch, empty for the empty chain |
| `canonical` | `(point : Chainpoint) (chain : Chain) → Prop` | Decidable |
| `rollback` | `(depth : Nat) (fork : Branch) (chain : Chain) → Chain` | Keeps the replaced branch |
| `Extends` | `Chain → Chain → Prop` | Constructors `refl` and `step` through `rollback` |
| `ContinuedAncestry` | `[ConsensusModel] (policy : Policy) → Prop` | Hypothesis; never computed |
| `act` | `(policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider) (selectedPoint : Chainpoint) (chain : Chain) → Except Refusal Authorized` | Evaluation as ruled (proposal §4.1) |
| `SettlementStability` | `[ConsensusModel] (operation : Policy → Action → Verdict → Provider → Chainpoint → Chain → Except Refusal Authorized) → Prop` | Premise `ContinuedAncestry policy`; conclusion over `Extends` and `ConsensusModel.admits` |
| `act_settlement`, `act_effect_requires`, `unverified_effect_refused`, `no_verifier_effect_refused`, `effect_no_promotion`, `unverified_construct_iff`, `construct_chain_irrelevant`, `act_action`, `act_never_adopts`, `act_refusal`, `abandoned_effect_refused`, `rollback_extends`, `extends_trans`, `rollback_canonical`, `abandoned_read`, `abandoned_terminal` | ruled statements | Axioms limited to propext, Classical.choice and Quot.sound |
| `settlement_dropped_refutes` | `(operation) (authorizes : operation <settled policy> .effect <verified> <provider> <selected> <tip chain> = .ok <authorization>) → ¬ SettlementStability operation` under the fixture consensus | Parameterized by the compiled mutant |
| `consensus_dropped_refutes` | `¬ <SettlementStability without the admits premise> act` under the fixture consensus | Witness for the statement mutant |
| `Lockness.Sim.effectScenario` | `(scenario : String) → IO UInt32` | Unknown scenario exits 64 |
