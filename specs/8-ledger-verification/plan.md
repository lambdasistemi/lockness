# Deliver the ledger verification model

As a reviewer, inspect one ledger verification slice with an explicit shared contract, constructive counterexamples and reproducible evidence.

## Authority and sequence

The accepted predecessor is `bdca4460bd7f0bd900d16398453a855f354b96b0`, tree `609eeb042741965e95d00e5bff1428acc1bb523b`. Baseline model, documentation and `just ci` checks passed on that clean predecessor. The epic owner's ledger-interface-v1 response releases the concrete interface proposal and its exact fence; inherited behavior remains frozen.

Planning precedes one behavior slice comprising shared interface adaptation, ledger model/proofs, counterexamples, simulator integration and matching documentation. Local checkpoint commits remain provenance. After acceptance, CO consolidates the accepted tree and TO planning/task delta into a bisect-safe behavior commit. Parent ruling A-002-immutable-source-delivery prospectively adds one forward documentation commit in the same PR: after the approved behavior commit is published to the draft PR and its immutable source bytes are verified, CO pins ledger source links to that revision and updates matching speech/hash metadata. Inherited session source links retain their existing publication obligation.

The behavior commit maps the first six model tasks. Documentation publication and final handoff stay open for the forward documentation commit. The persistent auditor approves exact planning/task and documentation deltas; all seven clean-head checks converge separately on the intermediate behavior head and final documentation head. Intermediate publication is not readiness. Parent preserves the published behavior commit through merge ancestry; its linked model bytes must equal final-head model bytes. Do not rewrite published history or delete source reachability without a revised ruling. Original gate/model statements and their frozen hashes remain unchanged.

## Released architectural choices

| Choice | Alternative | Reason |
| --- | --- | --- |
| Pinned Mathlib Finset | Unrestricted ledger lists | Finite-set membership and extensional set semantics match the required ground truth. |
| Policy callbacks on preserved bytes | Concrete codecs or witness construction | This project owns abstract verification contracts. |
| Independent accepted root argument | Trust provider answer/session root | Provider data cannot endorse itself. |
| Separate OneShot premise | Forbid duplicate assets in Ledger | The duplicate-asset falsification must remain reachable. |
| Explicit observation correspondence | Infer semantic truth from Boolean success | Computable observations and logical soundness are distinct. |

## Ownership

TO owns planning, runtime frozen requirements/check matrix, child mandates, checkpoint routing, task stamps, final verification, push and PR metadata. CO owns implementation, fixtures, tests, dependency/build adaptations, documentation/speech and local commits. Persistent CA reviews committed checkpoints independently, stays mute toward CO and runs no gates. Approved seats are TO/CO Codex gpt-6.1-sol high and CA Claude claude-opus-5-5 high. No extra seat or draft tool.

## Checks and finalization

Freeze the requirement-to-command matrix before implementation. Existing CI invokes `./tools/check-model.sh` and `./tools/check-docs.sh`; local `just ci` runs both. The model gate must execute all ledger scenarios, constructive counterexamples, inherited scenarios/lifecycle, named and anonymous hole controls and all-source theorem inventory. Exact argv/cwd/SHA/tree, before/after cleanliness, exit, start/end and log hashes bind every invocation.

Acceptance requires all checkpoint approvals, task-to-commit mapping, complete final stamped-head checks, exact pushed SHA and green Build Gate/Docs build, current reviewer preview and reachable source/speech links. Parent owns acceptance, merge and publication. Source consumed by revision is the model delivery artifact; tagged binaries are future implementation work.

## Constitution and scope

Trust/data separation, exact bytes/point identity and explicit assumptions govern the slice. No component repositories or paused lanes are touched. Mathlib is pinned to `8a178386ffc0f5fef0b77738bb5449d50efeea95`, matching the existing Lean 4.29.0; transitive Lake revisions are committed. Use narrow finite-set imports. Existing Nix/Lean pins stay unchanged; dependency/cache setup is separately accounted build setup.

The released fence comprises `Types.lean`, `Ledger.lean`, `LedgerProofs.lean`, `Tests/Ledger.lean`, `Counterexamples/LedgerFixtures.lean`, `Counterexamples/LedgerRootMutation.lean`, `Counterexamples/LedgerUniqueness.lean` and `Sim/Ledger.lean` under `lean/Lockness/`; mechanical Policy adaptations in `Counterexamples/Fixtures.lean` and `Tests/Observation.lean`; `lean/Lockness.lean`, `lean/Main.lean`, `lean/lakefile.toml`, `lean/lake-manifest.json`, `lean/env`, optional `lean/setup-deps.sh`, `lean/checks/model.sh`, optional `lean/checks/ledger-mutations.sh`; mechanical dependency adaptation only in `lean/checks/mutations.sh` and `session-mutations.sh`; `README.md`/speech, `docs/model/index.md`/speech and `docs/design/decisions.md`/speech. TO owns this planning directory. Root/session behavior and CI workflows are outside the change fence.

Planning ceiling: each file 8 KiB/100 lines. Compiled role packet ceiling: 20 KiB/220 lines. Runtime command/output limits and actual execution accounting are frozen before child launch; they do not narrow the full goal.
