# Settlement and act plan

As a reviewer, see how the chain ground truth, the settlement observation and its hypothesis, and the act step enter the model after the verdict. Behaviour changes only where the ruling names it.

## Strategy

1. Extend the shared types exactly as ruled: `Branch`, `Chain`, the moved `Reason`, `Policy.settlement` and `Policy.constructUnverified`.
2. Add the chain ground truth: `tip`, `canonical`, `rollback`, the possible-futures relation `Extends`, the abstract consensus model and the continued-ancestry hypothesis.
3. Add `act` after the verdict, reading the offer through `acquire` and the chain view only for settlement.
4. Add the abandoned session state, its read refusal and its transition; restate only the ruled inversion.
5. Adapt the four positional inherited policies with neutral values, so every inherited outcome is unchanged.
6. Add the act theorems, the settlement theorem, the fixtures inhabiting the hypothesis, the refutations and the finite tests.
7. Add the compiled mutation script, the five `effect` scenarios, the usage text and the model-gate stages.
8. Update the reader-facing documentation, diagram and curated speech. Publish an immutable model commit, then a forward source-pin documentation commit.

## Constraints

- Fence as ruled; every other file stays byte-identical to df7cda8.
- An elaborated-statement inventory diff against df7cda8 shows exactly the ruled restatements, generated declarations, compiler auxiliaries and neutral-value text.
- Every inherited scenario's stdout line and every inherited stage outcome is unchanged.
- No numeric depth or anchor count, rollback notices on the wire, lease, retention, eviction or storage mechanics, protocol-parameter semantics, or #11 audit work.
- Every local gate runs with CI's restricted PATH (nix, bash and dirname only) on a warmed dependency cache.

## Slices

| Slice | Content | Commits |
| --- | --- | --- |
| settlement-model | Types successor, chain module, act, abandoned session, adaptations, proofs, fixtures, refutations, tests, simulator, mutation script, gate wiring | RED bundle, GREEN candidate, squashed to one immutable model commit |
| settlement-docs | chainpoints (with the session diagram), decisions and model index with speech companions; source links pinned to the model commit | one forward docs commit |

## Evidence and limits

The required checks are the CI commands `./tools/check-model.sh` and `./tools/check-docs.sh`, the Docs build job and the PR preview, all on the exact pushed head.

Invocations are counted from receipts and checked before each run. Limits: expensive tier 40 (Nix, full check-model, check-docs, CI), cheap tier 250 (single-file lean, single scenario); 900 s per command. Phase 1 baseline, setup and probe receipts are counted separately.

Remote main is refreshed before the final verification cycle and before readiness. A moved base is integrated by a history-preserving merge.
