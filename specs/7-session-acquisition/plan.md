# Session model delivery

As a reviewer, inspect one bounded session-model change after the accepted root model, with independently reviewed evidence and reproducible commands.

## Design and authority

The existing chainpoint session design and epic release govern behavior. This ticket creates the executable model and its simulator; it does not translate it into component code. Apply code-the-design at the scoped model journey and named invariant level; higher-rung implementation conformance is outside this model ticket.

One behavior slice owns acquisition, lifecycle, proofs, semantic controls, simulator integration and matching prose. Planning precedes that slice. Local RED/GREEN checkpoint commits remain provenance until the accepted tree and task stamp are consolidated into a bisect-safe final behavior commit.

## Ownership

TO owns these planning artifacts, frozen runtime acceptance map, checkpoint routing, acceptance, task stamps, PR metadata and pushes. CO owns Lean/source/check/documentation changes and local commits. Persistent CA independently reviews committed checkpoints in a detached worktree and runs no gates. Only the three approved ticket seats participate; no draft or gate-author seats.

## Checks and delivery

The runtime frozen map binds each requirement to `./tools/check-model.sh` or `./tools/check-docs.sh`, the actual Build Gate commands, plus pinned Lake scenario and constructive witness receipts. `just ci` runs both local gates. Keep whole-source inventory and predecessor controls. Every evidence receipt records command, cwd, SHA/tree, cleanliness, exit and output hash. The parent release allocates named verification modules and optional production mutation script.

Final readiness requires all checkpoint approvals, final stamped-head checks, exact pushed SHA, remote Build Gate/Docs build success, live reviewer preview with meaningful bytes bound to that head, completed task/history audit and durable handoff. Epic owner owns merge and later publication/release.

## Constitution check

Full point equality and unrestricted providers preserve trust/data separation; session reads never substitute points. Bytes and accepted root are preserved. Open branch, retention and physical-storage policies remain visible under their existing owners. No shared type or dependency change is authorized.

Planning artifact ceiling: each file 8 KiB / 100 lines; compiled role packet ceiling 20 KiB / 220 lines. Runtime records remain outside Git.
