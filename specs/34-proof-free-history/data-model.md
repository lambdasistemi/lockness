# History data contracts

Status: accepted under history-interface-v1.

| Type/field | Contract |
| --- | --- |
| Reconstruction | Existing transaction Bytes and List (TxIn × TxOut), preserved exactly. Moved before Policy only to make the field type available. |
| HistoryAnswer.transactions | List Reconstruction in provider-supplied order; untrusted; no proof or authority root. |
| HistoryState | Bytes, treated as opaque state, without an encoding contract. |
| Policy.relevant | Reconstruction → Bool, local to one item under a fixed policy. |
| Policy.fold | HistoryState → Reconstruction → HistoryState. |
| Policy.initial | HistoryState, terminal application choice. |
| Policy.historyRoot | HistoryState → Root, executable state-root observation. |
| LedgerAnswer.history | Option HistoryAnswer, acquired with the state-output answer; absence is none. |
| HistoryResult | Relevant ordered transactions and final state; excludes irrelevant material. |
| HistoryClaim | Selected point, accepted ledger root, policy query, verified datum root and HistoryResult. |
| HistoryVerdict | verified HistoryClaim, refused Refusal, unverified Reason; no new reason/refusal. |
| HistorySemantics | Independent relation HistoryState → List Reconstruction → HistoryState → Prop. |
| honestHistory | AppQuery → Chainpoint → List Reconstruction; independent ordered ground truth up to that point. |

The primary guarantee authenticates the rebuilt state; exact sequence bytes,
order and multiplicity are authenticated only by a history commitment. The checking
root comes solely from the verified state output. The old reconstruction field
is unchanged and is never substituted for the new history. No new history result
is smuggled into the existing Claim/Verdict/act types.

Neutral inherited policy values reject all relevance, preserve fold state, use
empty initial bytes and return an empty-scheme/empty-byte root. All inherited
answers gain history none. These observations are unused on inherited paths.

FoldDeterministic relates executable replay to independent functional semantics.
StateRootCollisionResistant makes roots injective on semantically reachable states.
HistoryCommitmentInjective is the stronger sequence-injectivity premise, reserved
for history commitments. HistoryCommitted binds honest history semantics to
asset-bearing state-output datum roots. These are explicit Prop parameters.
