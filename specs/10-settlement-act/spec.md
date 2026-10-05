# Rollback, settlement and the act step

As a design reviewer, run `lake exe lockness-sim effect <scenario>` and observe:
- transaction construction allowed at an accepted point, before any settlement;
- an external effect refused at the selected point until the policy's settlement observation holds, then authorized;
- after the point is rolled back, the session abandoned, its reads refused at the same point, and the effect still refused;
- construction on an unverified verdict only when the policy's action rule admits its reason;
- an effect on an unverified verdict always refused, for every reason, including a terminal without a verifier on another network.

## Architectural contract

`act` is the last step of the frozen order: context root acceptance, acquisition, ledger, application, verdict, then act. It consumes the verdict and receives the provider's offer separately, through `acquire`, never from the verdict. The chain it reads is the terminal's own chain view; no provider, builder or publication supplies it. Settlement is an executable observation on that view. Its connection to permanent canonicality is the explicit continued-ancestry hypothesis over the futures a consensus model admits. The model proves nothing unconditional about future canonicality and fixes no depth. Refusals stay the three constructors and carry the selected point.

## Requirements

| Name | Required outcome |
| --- | --- |
| chain-ground-truth | `Chain := List Branch`, canonical branch first; `canonical`, `rollback` and the possible-futures relation `Extends`, which admits rollback of any depth. |
| rollback-reachable | A rollback reachable under `Extends` leaves a previously canonical point non-canonical. |
| settlement-observation | `Policy.settlement` is an executable observation on the terminal's chain view. |
| continued-ancestry-hypothesis | `ContinuedAncestry` connects the observation to canonicality in every possible future the consensus model admits; it is a hypothesis, never computed. |
| action-rule | `Policy.constructUnverified` decides which unverified reasons still allow construction. |
| act-step | `act` over the verdict, with the offer received separately; construction needs `verified`, or `unverified` with the rule; an effect needs `verified`, a session bound to the selected point and settlement; an effect on `unverified` is always refused. |
| refusal-point | Every `act` refusal is one of the three constructors and carries the selected point; every authorization is at the selected point. |
| construction-no-finality | Construction never reads the chain and never authorizes an effect. |
| no-verifier-effect-refused | With the verifier off, an effect is refused whatever the context, closing the #30 residual. |
| settlement-theorem | Under `ContinuedAncestry`, a successful effect at the selected point keeps it canonical in every admitted possible future. |
| settlement-counterexample | A compiled mutant without the settlement guard authorizes an effect at an unsettled point; an admitted rollback then leaves it non-canonical and constructively refutes the unchanged theorem; the unchanged proof fails; the rolled-back scenario fails. |
| consensus-premise-load-bearing | Without the consensus premise the statement is false on the real `act`: a settled point is rolled back deeper than the fixture admits. |
| further-mutants | Mutants allowing an unverified effect, removing the bound-session check and ignoring the action rule each break an unchanged proof and a scenario. |
| jointly-inhabited-witness | A fixture policy and consensus model inhabit `ContinuedAncestry` together with a settled effect, and the unmet condition is reachable. |
| abandoned-session | A session whose selected point is no longer canonical transitions to the named state `abandoned`; its reads are refused at its own point; it has no outgoing transition; its point never settles under the hypothesis. |
| runnable-effect-scenarios | `lockness-sim effect construct`, `settled-effect`, `rolled-back`, `unverified-construct` and `unverified-effect` run the real verdict and act. |
| inherited-statements-preserved | Every inherited statement is unchanged except the ruled restatement, proven by an elaborated-statement inventory diff against df7cda8. |
| inherited-contract-preservation | Every inherited scenario output and check-stage outcome is unchanged; inherited fixtures gain only neutral values; the all-source axiom inventory and hole controls are retained. |
| chainpoint-design-record | `docs/design/chainpoints.md` records the abandoned state in place of the unresolved note, with the session diagram and speech. |
| settlement-design-record | `docs/design/decisions.md` and `docs/model/index.md` state the act step and the conditional settlement guarantee. They state that a light terminal derives its chain view from accepted anchor publications establishing continued ancestry, an open contract owned by #17 and the implementation milestones, and that nothing a provider returns enters the view or the settlement observation. They give the no-veto and no-promotion argument, the limit that an unsettled effect and wrong evidence share `evidenceFailure` (owned by #11 and #17), protocol parameters in construction reassigned to the implementation milestones, and the out-of-model list with owners. |
| reviewable-delivery | Matching docs and speech, immutable source links, persistent independent checkpoint audit, final-head local checks, exact-head remote CI and preview all precede readiness. |

## Evidence boundary

- Proofs establish model properties under their stated premises.
- Simulator outcomes establish concrete model paths.
- Documentation and CI have separate receipts bound to their revisions.

No numeric depth or anchor count, rollback notices on the wire, lease, retention, eviction or storage mechanics, protocol-parameter semantics, or audit work owned by #11.

## Shared-interface authority

Epic ruling settlement-interface-v1 (answers/A-001-interface-proposal.md) releases sections 1–12 of the proposal with choices V1 (the terminal-owned chain view), R (`evidenceFailure` for an unsettled effect), C1 (construction ignores the chain), A (abandon from `active` only) and P (protocol parameters outside the model), and three clarifications on the chain view, the shared refusal and protocol parameters.
