# Bind the terminal to its operating context

As a design reviewer, run `lake exe lockness-sim context <scenario>` and observe:
- a verified claim on the configured network;
- `evidenceFailure` at the selected point when the selected point belongs to another network, never `unverified`;
- a publication from another network ignored: it neither vetoes an in-context root nor endorses one (`noRoot` when it is the only endorsement);
- `evidenceFailure` at the selected point when the endorsed root uses a commitment scheme the policy does not accept;
- a valid signature over another network's message endorsing this network's point, which only the message-binding hypothesis excludes.

## Architectural contract

The terminal operates in one declared context: a network identifier and the commitment schemes it accepts. The context is the terminal's policy, not the provider's. Key trust is exercised only inside it. A context mismatch is present and wrong, so it is refused with `evidenceFailure` at the selected point, never `unverified`. That a signed message encodes its publication's point and root is an abstract hypothesis beside `SigValid`; it is never computed. Refusals stay the three constructors carrying the selected point. The frozen evaluation order is kept: root acceptance (now in context) precedes acquisition, then ledger, application and verdict.

## Requirements

| Name | Required outcome |
| --- | --- |
| declared-context | `Policy.context : Context` holds the network identifier and the accepted scheme identifiers; a scheme identifier carries its version. |
| context-scoped-trust | Every endorsement that counts towards an accepted root is a trusted key's publication at a point on the context network, for a root under an accepted scheme. |
| message-binding-hypothesis | `MessageBinding`: a valid signature's message encodes exactly its publication's point (network, slot, block hash) and root (scheme, bytes). Abstract, beside `SigValid`, never computed. |
| context-guard | Root acceptance in context refuses with `evidenceFailure` at the selected point when the selected point is on another network, or when the root that root acceptance selects has a scheme the context does not accept. The guard reads no provider or builder and precedes acquisition. |
| foreign-publication-ignored | Appending publications whose points are on another network never changes context-checked root acceptance, `accept` or `verdict`: untrusted input from another network cannot veto a selection. |
| out-of-context-never-unverified | With a verifier configured, an out-of-context selection is refused with `evidenceFailure` at the selected point, never `unverified`, whatever the provider offers. |
| context-soundness | A verified claim's point is on the context network, its ledger root's scheme is accepted, and its endorsing publications' messages encode exactly that point and root, under `ObservationSound` and `MessageBinding`. |
| guard-removal-refutation | A compiled mutant without the network guard verifies a root endorsed by a trusted key on another network. It constructively refutes the unchanged context soundness, the unchanged proof fails and the real scenario fails. |
| binding-removal-refutation | Without the `MessageBinding` premise, context soundness is constructively false: a valid signature over another network's message endorses this network's point. The unchanged proof fails on the mutated statement. The real simulator reproduces the endorsement. |
| runnable-context-scenarios | `lockness-sim context honest`, `wrong-network-point`, `wrong-network-publication`, `unaccepted-scheme` and `unbound-message` run the real verdict and accept. |
| inherited-statements-preserved | Every #6–#9 and #28 statement is unchanged, except the restatements the ruling lists; proven by an elaborated-statement inventory diff against acbde08. |
| inherited-contract-preservation | Every inherited scenario output and check-stage outcome is unchanged; inherited fixtures gain only a neutral context. The all-source axiom inventory and hole controls are retained. |
| context-design-record | `docs/model/index.md` and `docs/design/decisions.md` state the operating context and the out-of-model list with owners: genesis and era identity, protocol parameters (#10 for transaction construction, implementation milestones otherwise), validator script hashes. |
| reviewable-delivery | Matching docs and speech, immutable source links, persistent independent checkpoint audit, final-head local checks, exact-head remote CI and preview all precede readiness. |

## Evidence boundary

- Proofs establish model properties under their stated premises.
- Simulator outcomes establish concrete model paths.
- Documentation and CI have separate receipts bound to their revisions.

Concrete network identifiers and signature or message encodings belong to #17. Protocol-parameter semantics, fee computation and key rotation are out of scope. `act` and settlement belong to #10.

## Shared-interface authority

Epic ruling context-interface-v1 (answers/A-001, with correction C1: a foreign publication is ignored, never a veto) releases the Types successor, the guard, the classification branch, the single restatement and the file fence.
