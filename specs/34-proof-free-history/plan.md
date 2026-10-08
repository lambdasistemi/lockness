# Delivery plan

Status: accepted under history-interface-v1 with correction C1 applied.
The versioned ruling releases implementation. The three-seat roster is approved.

## Strategy and boundaries

History is a separate application check composed after the inherited state-output
verification. Its material is carried in the acquired ledger answer as an optional
HistoryAnswer, distinct from the legacy reconstruction field. The original
accept/verdict/act behavior stays fixed. See the data and functions models for
successor contracts and the runtime interface question for exact theorem statements.

Policy owns relevant, fold, initial state and state-root observation. Independent
semantic replay, determinism/observation fidelity and honest-history commitment
supply shared premises. Reachable-state root injectivity gives primary state
soundness; HistoryCommitmentInjective gives secondary sequence soundness.
Whole-result tolerance requires only equal local relevant subsequences.

## Ordered slices

| Slice | Deliverable | Prerequisite |
| --- | --- | --- |
| plan-history | These compact planning records, baseline and full reader/inventory proposal | current release |
| model-history | Successor types, executable history path, both soundness theorems, tolerance, three mutants and seven simulator journeys | accepted ruling; frozen statements, file fence, gate table and budgets |
| document-history | Conditions/limits and curated speech on the two pages; immutable source pins | locally green audited model commit pushed and exact-head CI green |
| deliver-history | Final tree audit, clean exact-head local gates, CI/preview, finalization and handoff | all artifact tasks accepted |

No published commit is rewritten. Every commit has a body checked sentence by
sentence against actual theorem premises. A moved main is integrated with a
history-preserving merge; Lean conflicts return to the parent before repair.

## Verification and staffing

The TO prepares the gate table, without extra seats. The commit owner is Claude
claude-opus-5-5 high. The persistent commit auditor is Codex gpt-6.1-sol high in
its detached worktree, source/receipt-only. Both launch in this ticket's tmux
window only after the ruling and acknowledge their actual pane/CLI/model.

CI invokes ./tools/check-model.sh and ./tools/check-docs.sh. Local gates use only
nix/bash/dirname on the outer PATH; cold dependency setup is separately labelled.
Preserve full-source hole/axiom inventory and inherited mutants. A mutation's
compile failure must be paired with a reachable compiled semantic witness.
Full declaration records are joined through their AXIOMS terminator for diffing.

Accepted phase-2 ceilings: 40 expensive and 250 cheap tool invocations, counted
from receipts before execution, including failures/setup. Reserve 8 expensive and
20 cheap for TO finalization. Expensive means Nix/full gate/hosted workflow;
cheap means one-file Lean/scenario/inventory. Nested stages are recorded, not
double-charged. Overrun or contract drift requires a question before proceeding.

Final delivery requires exact-head Build Gate, Docs build and preview success,
live source/speech/render checks, finalization-audit, final handoff and verified
retirement of both children. The parent owns ticket acceptance and merge.
