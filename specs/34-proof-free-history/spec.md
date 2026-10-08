# Proof-free history at the selected point

Issue: [#34](https://github.com/lambdasistemi/lockness/issues/34), parent #16.
Status: accepted under history-interface-v1, including the state/sequence split.
Frozen inherited base: 0676f5d8d8e8bfe47d11fb1544772ae685187421.

## User stories

As a terminal, accept transaction history without per-transaction proofs when my
application's deterministic fold over relevant transactions rebuilds the root in
the state output I verified at my selected point. As a design reviewer, run
`lake exe lockness-sim history <scenario>` to inspect that route and its failures.

| Requirement | Observable success |
| --- | --- |
| history-root-provenance | The checking application root comes from verifyLedger after context-root acceptance and exact-point acquisition. Provider root fields never supply it. |
| history-state-soundness | Under the root, state-output, semantic replay, commitment correspondence and reachable-state root collision resistance premises, the accepted rebuilt state equals the honest committed state at the selected point. No transaction-list equality follows. |
| history-sequence-soundness | Under the stronger HistoryCommitmentInjective premise, the accepted relevant sequence also equals the honest relevant sequence, including order, multiplicity and resolved-output bytes. |
| history-superset-tolerance | Adding irrelevant transactions preserves the complete acceptance result and history verdict, without cryptographic hypotheses. |
| history-refusal | After the preceding boundaries succeed, a history reaching a different state gives refused evidenceFailure under state soundness premises. A sequence mismatch gives that refusal under the stronger history commitment premise. Earlier boundary failures retain precedence. |
| history-counterexamples | Removing the root comparison accepts a forged history; context-dependent relevance lets an irrelevant extra change the result; comparing only a weaker state projection accepts a different state. All have compiled witnesses and constructive refutations. The cancelling-pair journey accepts an alternative sequence with the same honest state. |
| history-evidence-separation | No per-item proof field. The state-output witness still checks. Old ledger reconstruction remains separate and its inherited verdict irrelevance theorem keeps its statement. |
| history-documentation | Model and decisions pages explain conditions, hypotheses, ordering, refusal premises and limits; curated speech matches current text and hashes. |
| inherited-preservation | Inherited statements retain their semantics; the one named constructor-literal restatement adds only neutral history none. All inherited controls remain. Full-statement inventory differences are limited to the ruled generated/neutral classes. |

## Non-goals

Concrete application folds, cryptography, transaction encoding (#17), index
implementation, #35's application-rules/catalog, #39's script query, #11's final
audit, deployment and release. No changes in component repositories. The CSMT
pause remains in force. This is design/model work, not implementation conformance.

## Conditions and evidence boundaries

State commitments, including trie state roots, give state soundness even when
transactions cancel or overwrite. History commitments, such as transaction
accumulators or hash chains, can additionally give sequence soundness under
HistoryCommitmentInjective. Honest history and semantic replay are independent
model parameters. Order comes from the answer; the fold checks its resulting
state. Only the stronger premise authenticates the exact relevant sequence.
The new history claim does not enter act without a later ruling. Issue #35
consumes the requirement to declare the application's commitment kind.

Repository artifacts, independent review, local gates, remote CI, readiness,
merge and deployment are separate evidence. The parent owns merge/publication.
