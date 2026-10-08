# Module contracts

Status: accepted under history-interface-v1. Data and functions models own their respective
signatures; this file names responsibilities and dependency direction only.

| Module | Responsibility | Dependencies |
| --- | --- | --- |
| shared-history-types | Types.lean owns Reconstruction, HistoryAnswer, opaque HistoryState and the policy/ledger-answer extensions. | Existing byte/root/query vocabulary only |
| history-check | History.lean owns the explicit history path, result/claim/classification, semantic hypotheses and operation-parameterized guarantees. | Context root acceptance, Session acquisition, Ledger verification, unchanged absence classification |
| history-proofs | HistoryProofs.lean proves primary state and secondary sequence soundness through either declared state-output provenance route, full-outcome tolerance, refusal and no promotion. | History contracts, inherited root/session/ledger/completeness proofs |
| history-witnesses | HistoryFixtures/HistoryRefutation supply separate cancelling-state and injective-history joint inhabitants and three constructive counterexamples independent of acceptance's returned values. | History plus inherited fixture foundations |
| history-reviewer-journey | Sim/History and Main expose seven real journeys including cancelling-pair; Tests/History restates obligations; history-mutations and model.sh enforce all three controls in CI. | Production history path and witness contracts |
| history-design-record | Two model/design pages and their curated speech explain conditions and evidence limits, linking immutable model source. | Accepted model and its separate receipts |

No new generic framework or component implementation repository is introduced.
Original application/verdict/act modules remain outside the behavioral fence.
