# History function signatures and statement boundaries

Status: accepted under history-interface-v1. No implementation bodies are specified here.

| Function | Arguments | Result |
| --- | --- | --- |
| relevantHistory | policy : Policy; answer : HistoryAnswer | List Reconstruction |
| verifyHistory | policy : Policy; selectedPoint : Chainpoint; appRoot : Root; answer : HistoryAnswer | Except Refusal HistoryResult |
| acceptHistory | policy : Policy; publications : List Publication; selectedPoint : Chainpoint; provider : Provider | Except Refusal HistoryClaim |
| historyVerdict | policy : Policy; publications : List Publication; selectedPoint : Chainpoint; provider : Provider | HistoryVerdict |
| Session.withHistory | history : Option HistoryAnswer; session : Session | Session |

The low-level checker takes a checking root; the composed acceptance establishes
its provenance through the existing verified state output. Errors retain the
selected point. The classifier uses the same verifier/context/declared-absence
contract as the inherited verdict, but returns a history claim.

HistoryStateSoundness quantifies arbitrary providers and concludes correct
point/query/ledger root, unique honest state output, matching datum root and
equality to the independently committed semantic state. It has no sequence
conclusion. HistorySequenceSoundness adds exact relevant-sequence equality under
HistoryCommitmentInjective. Both support OneShot or required-completeness
provenance. The provider never chooses the terminal's trust assumption.

HistorySupersetTolerance compares full results for any two lists with equal
normative policy.relevant filters. The analogous classifier statement compares
full HistoryVerdict values. Neither assumes cryptography. The append corollary
covers every list of rejected extras; equality of filters covers interleaving.

Inversions, no-promotion, selected-point refusal, exact wrong/missing-history
refusal under successful earlier boundaries and legacy-reconstruction irrelevance
are separate obligations. Exact quantified statements and mutant targets live in
the versioned parent ruling and its frozen runtime statement manifest. Only Tests.Session.root_and_bytes_unchanged gains a neutral history-none
constructor argument; no inherited premise or guarantee changes.
