# Classify every outcome as verified, refused or unverified

As a design reviewer, run `lake exe lockness-sim verdict <scenario>` and observe:
- `unverified` with its reason for an answer without a witness, for an unbound session and for a policy without a verifier;
- `verified` with the same claim as `accept` for a bound session with a checked witness;
- `refused` with the selected chainpoint for a present but wrong witness and for a session bound to another point;
- that the attempt to promote a witness-less answer to `verified` fails.

## Architectural contract

The verdict is the terminal's classification around `accept`, never a wire object. Unverified traffic is a first-class case: neither a refusal nor a claim. A session's binding and an answer's witness are declared data. A missing verifier is a declared policy value. Reconstruction material is a type distinct from every evidence type and is never read as evidence. Refusals stay exactly the three constructors carrying the selected point. The terminal never adopts a point it did not select.

## Requirements

| Name | Required outcome |
| --- | --- |
| declared-binding | `Session.binding` is `bound Chainpoint` or `unbound`, declared by the provider. |
| optional-witness | `LedgerAnswer.witness` is optional; an answer without one is a well-formed object. |
| distinct-reconstruction | `Reconstruction` (transaction bytes plus resolved spent outputs) is its own type, carried optionally by the ledger answer; replacing it never changes a verdict. |
| declared-verifier | `Policy.verifier` declares whether the terminal checks evidence; only `verdict` reads it. |
| accept-requires-binding-and-witness | `accept` never returns `.ok` for a session not bound to the selected point or an answer without a witness. |
| inherited-statements-unchanged | The statements of NoSubstitution, LedgerSoundness, AcceptSoundness, ProviderInvariance, the refusal lemmas and every root/app theorem are unchanged; only the ruled supporting restatements differ. |
| verdict-wraps-accept | `verdict` follows the ruled classification order: a missing verifier, then accept, then declared absences, then accept's refusal. |
| refused-is-accept-refusal | Every `refused` verdict carries accept's refusal, so it is one of the three refusals at the selected point. |
| unverified-only-from-declared-absence | `unverified` arises only from a declared absence (no verifier, `unbound`, no witness). It never hides a claim that accept made. Anything present and wrong is `refused`. |
| wrong-witness-refused | A present but wrong witness on a bound session with a verifier is `refused evidenceFailure`, never `unverified`. |
| unbound-only-unverified | A session offered at the selected point and declared `unbound` yields only `unverified`. |
| misbound-refused | A session declaring a binding to another point is never `unverified`: it is refused with accept's refusal at the selected point, and with `evidenceFailure` whenever root acceptance succeeds. Only a declared absence is unverified. |
| no-promotion | `verdict … = .verified c` implies the verifier is configured, the offered session is bound to the selected point, its answer carries a witness and `accept … = .ok c`. |
| verified-claims-sound-and-invariant | Soundness and provider invariance hold for every verified claim under exactly the inherited hypotheses. |
| promotion-refutation | A compiled mutant treating an absent witness as checked promotes a witness-less answer whose datum root is absent from the honest ledger. It constructively refutes the unchanged no-promotion and verified-soundness statements, the unchanged proofs fail, and the real `verdict promoted` scenario fails. |
| runnable-verdict-scenarios | `lockness-sim verdict verified`, `no-witness`, `unbound-session`, `no-verifier`, `wrong-witness`, `misbound` and `promoted` run the real verdict. |
| inherited-contract-preservation | Every inherited scenario output and check-stage outcome is unchanged. The all-source axiom inventory and the hole controls are retained. |
| verdict-design-record | decisions.md records the verdict layer: weakest and strongest instances of the same types, and the verdict as a classification, never a wire object. |
| reviewable-delivery | Matching docs and speech, immutable source links, persistent independent checkpoint audit, final-head local checks, exact-head remote CI and preview all precede readiness. |

## Evidence boundary

- Proofs establish model properties, under the stated premises where there are any.
- Simulator outcomes establish concrete model paths.
- Documentation and CI have separate receipts bound to their revisions.

The `act` step and the action policy belong to #10. The wire encoding of the binding, the witness and the reconstruction belongs to #17. Concrete verifiers and witness formats are out of scope.

## Shared-interface authority

Epic ruling verdict-interface-v1.2 (answers/A-001 with correction C1, A-002, A-003) releases the Types successor, the ledger guards and restatements, the classification order and the file fence.
