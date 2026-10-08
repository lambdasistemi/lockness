# Proof-free history at the selected point

Issue: [#34](https://github.com/lambdasistemi/lockness/issues/34), parent #16.
Status: proposed interface; implementation waits for the epic owner's Q-001 ruling.
Frozen inherited base: 0676f5d8d8e8bfe47d11fb1544772ae685187421.

## User stories

As a terminal, accept transaction history without per-transaction proofs when my
application's deterministic fold over relevant transactions rebuilds the root in
the state output I verified at my selected point. As a design reviewer, run
`lake exe lockness-sim history <scenario>` to inspect that route and its failures.

| Requirement | Observable success |
| --- | --- |
| history-root-provenance | The checking application root comes from verifyLedger after context-root acceptance and exact-point acquisition. Provider root fields never supply it. |
| history-exactness | Under the explicit root, state-output, semantic replay, commitment correspondence and history-root injectivity premises, an accepted relevant sequence equals the honest relevant sequence at the selected point, including order, multiplicity and resolved-output bytes. |
| history-superset-tolerance | Adding irrelevant transactions preserves the complete acceptance result and history verdict, without cryptographic hypotheses. |
| history-refusal | After the preceding boundaries succeed, a forged or missing relevant transaction gives refused evidenceFailure at the selected point with a verifier configured; it never becomes unverified. Earlier boundary failures retain precedence. |
| history-counterexamples | Removing the real root comparison accepts a forged history. Context-dependent relevance lets an irrelevant extra change the result. Both have compiled witnesses, constructive refutations and playable controls. |
| history-evidence-separation | No per-item proof field. The state-output witness still checks. Old ledger reconstruction remains separate and its inherited verdict irrelevance theorem keeps its statement. |
| history-documentation | Model and decisions pages explain conditions, hypotheses, ordering, refusal premises and limits; curated speech matches current text and hashes. |
| inherited-preservation | Inherited statements retain their semantics; the one named constructor-literal restatement adds only neutral history none. All inherited controls remain. Full-statement inventory differences are limited to the ruled generated/neutral classes. |

## Non-goals

Concrete application folds, cryptography, transaction encoding (#17), index
implementation, #35's application-rules/catalog, #39's script query, #11's final
audit, deployment and release. No changes in component repositories. The CSMT
pause remains in force. This is design/model work, not implementation conformance.

## Conditions and evidence boundaries

History-root injectivity is stronger than hash collision resistance: applications
whose distinct relevant histories yield the same state root cannot claim exact
history from that root. Honest history and semantic replay are independent model
parameters, not provider assertions. Order comes from the answer and is checked
through this sequence-sensitive commitment hypothesis. The new history claim is
not an existing application Claim and does not enter act without a later ruling.

Repository artifacts, independent review, local gates, remote CI, readiness,
merge and deployment are separate evidence. The parent owns merge/publication.
