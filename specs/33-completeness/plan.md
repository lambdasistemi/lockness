# Completeness plan

As a reviewer, see how the completeness proof kind enters the model: a new answer in the ledger answer, one guard in the ledger step, one classification change, and a separate all-entries acceptance.

## Strategy

1. Extend the shared types exactly as ruled: `CompletenessAnswer`, `LedgerAnswer.completeness`, `Policy.checkCompleteness`, `Policy.assetPrefix`, `Policy.requireCompleteness`.
2. Add the proof kind: key layout, prefix relation, `CompletenessSound`, `AssetKeyLayout`, `EntriesClaim`, `verifyEntries`, `acceptEntries`.
3. Add the completeness guard to `verifyLedger` after the witness guard, including the policy's requirement, and the ruled classification change to `unverifiedReason`.
4. Adapt the positional inherited literals with neutral values and the four inherited proof bodies the guard and classification touch, keeping every statement.
5. Add the theorems, the fixtures inhabiting every premise, the refutations and the finite tests.
6. Add the compiled mutation script, the `completeness` scenarios, the usage text and the model-gate stages.
7. Update the reader-facing documentation and curated speech. Publish an immutable model commit, then a forward source-pin documentation commit.

## Constraints

- Fence as ruled; every other file stays byte-identical to fff9a77.
- A full-statement inventory diff against fff9a77 shows exactly the ruled classes.
- Every inherited scenario's stdout line and every inherited stage outcome is unchanged.
- No CSMT proof format, key encoding, asset layout choice, proof-free history or #11 audit work.
- Every local gate runs with CI's restricted PATH (nix, bash and dirname only) on a warmed dependency cache.

## Slices

| Slice | Content | Commits |
| --- | --- | --- |
| completeness-model | Types successor, completeness module, ledger guard, classification, adaptations, proofs, fixtures, refutations, tests, simulator, mutation script, gate wiring | RED bundle, GREEN candidate, squashed to one immutable model commit |
| completeness-docs | decisions and model index with speech companions; source links pinned to the model commit | one forward docs commit |

## Evidence and limits

The required checks are the CI commands `./tools/check-model.sh` and `./tools/check-docs.sh`, the Docs build job and the PR preview, all on the exact pushed head.

Invocations are counted from receipts and checked before each run. Limits: expensive tier 40 (Nix, full `lake build`, full check-model, check-docs, CI), cheap tier 250 (single-file lean, single scenario). Phase 1 baseline, setup and probe receipts are counted in the same ledger.

Remote main is refreshed before the final verification cycle and before readiness. A moved base is integrated by a history-preserving merge.
