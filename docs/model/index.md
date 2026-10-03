# Inspect root acceptance and sessions

As a design reviewer, run a terminal's root choice against trusted and untrusted publications. An honest scenario returns the accepted root and selected chainpoint. A publication from an untrusted key returns `no-root` at that same point, even when signature validity is assumed. Removing the trusted-set check demonstrates why that refusal matters.

A terminal also acquires exactly its selected point, repeats reads from that session, and receives the original-point refusal when the provider is absent, offers another point, or the session expires.

This is an executable project model and simulator. Component implementations, cryptography, deployment and live-chain behavior require separate evidence. Review the model and this page from the same Git revision. Source links below follow the session feature branch so the new modules are available to pull-request reviewers before merge. Record that branch head when assessing the model.

## Run the scenarios

From the repository root, with Nix flakes enabled:

```bash
./lean/env lake build
./lean/env lake exe lockness-sim accept-root honest
./lean/env lake exe lockness-sim accept-root untrusted-key
./lean/env lake exe lockness-sim accept-root subset-mutation
./lean/env lake exe lockness-sim session honest
./lean/env lake exe lockness-sim session absent-point
./lean/env lake exe lockness-sim session newer-point
./tools/check-model.sh
./tools/check-docs.sh
just ci
```

`lean/env` enters the `lean/` directory with revision-pinned Lean 4.29.0 and its C compiler, and rejects a different Lean version. For an interactive pinned environment, run `./lean/env bash`; there the commands are `lake build` and `lake exe lockness-sim accept-root <scenario>`. The [toolchain file](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/lean-toolchain) also supports standard Elan workflows. The library uses core and Std, with no mathlib or external Lake packages.

| Scenario | Observable result |
| --- | --- |
| Honest publications | `accepted-root`, full selected point, exact root scheme and bytes, two distinct endorsers despite a duplicate publication |
| Untrusted key | `no-root`, full selected point, signature validity explicitly labelled an abstract assumption |
| Removed trusted-set check | Production refuses; the mutation accepts the untrusted root and has a compiled refutation of the unchanged safety statement |
| Honest session | Exact point and independently obtained root; two unchanged active reads, expiry refusal and release to closed |
| Absent point | `unavailablePoint` at the selected point |
| Newer point | `unavailablePoint` at the selected point; same-slot alternate hash and alternate network also refuse |

An unexpected scenario outcome exits nonzero. Unknown commands, missing scenario arguments and unknown root or session scenarios exit with usage code 64. These are executable model observations, without a network, ledger provider or signature implementation.

## Follow the acceptance boundary

```mermaid
flowchart TD
    P[Selected chainpoint] -->|binds exact identity| O[Original publications]
    O -->|policy observation is true| K[Distinct observed keys]
    K -->|keep trusted members| T[Trusted endorsers]
    T -->|nonempty and policy agreement| A[Accepted exact root]
    T -->|no qualifying root| R[No root at selected point]
    A -->|separate correspondence hypothesis| H[Honest ledger root]
```

The terminal supplies its policy and selected point. For each proposed root, `acceptRoot` finds publications at the exact network, slot and block hash, with that root's exact scheme and bytes. It passes the original publication, including unchanged signature and message sequences, to an arbitrary Boolean observation supplied by the policy. It deduplicates keys, keeps trusted members, and accepts the first root whose nonempty distinct endorsement satisfies the supplied agreement. Untrusted publications cannot manufacture agreement or prevent qualifying trusted publications from being considered.

```lean
acceptRoot : Policy → List Publication → Chainpoint → Except Refusal Root
```

The [acceptance definition](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Root.lean) returns `noRoot selectedPoint` when no proposal qualifies. The shared refusal type has exactly three constructors: `noRoot`, `unavailablePoint` and `evidenceFailure`, each carrying the selected point. Root acceptance only emits `noRoot`; session acquisition emits `unavailablePoint`. Evidence verification remains later behavior.

| Design choice | Alternative | Reason |
| --- | --- | --- |
| Policy supplies arbitrary executable observations | Compute an arbitrary validity proposition | Arbitrary propositions are not generally executable; signature soundness stays an explicit hypothesis |
| Distinct keys endorse the exact point and root | Count publication copies | Repeated messages cannot invent independent endorsement |
| Filter trusted members before agreement | Let irrelevant untrusted publications prevent acceptance | Trust belongs to the terminal's selected policy |
| Require nonempty endorsement | Let a permissive agreement accept no evidence | Agreement alone cannot authorize an empty set |
| Separate honest-root correspondence | Infer ledger correctness from signatures and agreement | Trusted publishers can endorse a wrong ledger root |

## Read the model contracts

The [shared types](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Types.lean) preserve exact byte sequences. Network and root scheme are explicit byte identities, slot is a natural number, and every equality includes all fields. There is no normalization, serialization, hashing or signing algorithm.

| Surface | Contract in this slice |
| --- | --- |
| `Bytes`, `Chainpoint`, `Root`, `Publication` | Original byte sequences, exact point/root identities and original message/signature evidence |
| `Policy` | Trusted keys, agreement on distinct keys and arbitrary publication observations |
| `Refusal` | Exactly the three selected-point refusals |
| `Session` | Selected point and root; acquisition and lifecycle in the session module, described below |
| `LedgerAnswer` | Point, exact ledger object and witness bytes; no verification behavior |
| `AppAnswer` | Application identity, context, point, root, claim, exact value and proof; no application verification behavior |

`SigValid publication` is an uncomputed proposition supplied by an implicit, arbitrary `SignatureModel`. The project defines no global instance fixing validity. `ObservationSound policy` explicitly assumes that a true observation implies this predicate. Neither an observation nor the model simulator implements signature verification. Signature encodings, key rotation and cryptographic correctness remain external contracts.

The [general proofs](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/RootProofs.lean) state their guarantees over arbitrary policies, publications and selected points:

| Declaration | Established model guarantee |
| --- | --- |
| `acceptRoot_safe` | Successful acceptance has nonempty distinct trusted endorsers satisfying agreement, with original publication witnesses at the exact point and root |
| `acceptRoot_valid` | The same witnesses have abstract signature validity under the explicit observation-soundness hypothesis |
| `acceptRoot_refusal` | Any refusal from this function is exactly `noRoot` at the selected point |
| `acceptRoot_honest` | Accepted root equals the downstream honest root only under separate `HonestRootCorrespondence` |

The [counterexamples](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Counterexamples/SubsetMutation.lean) give an inhabited abstract validity hypothesis for an untrusted publication, prove its refusal, constructively refute safety after removing trusted-set checking, and show that endorsement alone does not establish an honest ledger root.

## Acquire the selected session

As a terminal, retain one selected ledger identity while the provider follows new blocks. The [session model](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Session.lean) treats a provider as an arbitrary `Chainpoint → Option Session`, with no honesty restriction. `Session.point` is definitionally its stored `selectedPoint`. Acquisition checks complete network, slot and block-hash equality and returns the entire offered session unchanged; it never rewrites an offer to look like the requested point.

```lean
acquire : Chainpoint → Provider → Except Refusal Session
NoSubstitution : (Chainpoint → Provider → Except Refusal Session) → Prop
```

Successful acquisition establishes point coherence and preservation of the offered root and bytes. It does not establish that the provider's `acceptedRoot` was independently accepted. Root acceptance remains a separate terminal operation; cryptographic observation soundness and honest-root correspondence remain separate hypotheses. The honest simulator obtains its root by executing `acceptRoot` before offering the session. Other arbitrary providers can offer any root at that point.

<!-- diagram: session -->
<div class="diagram"><a href="../diagrams/session.png?v=42c240417184fe73"><img src="../diagrams/session.png?v=42c240417184fe73" alt="Requested sessions become active or unavailable; active reads repeat, expiry refuses, release closes, and branch policy remains unresolved." width="784" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/session.png?v=42c240417184fe73">Open full size</a> · <a href="../diagrams/session.mmd?v=814064504407234d">Mermaid source</a></p>

The diagram preserves the [session design](../design/chainpoints.md). The executable inductive `SessionState` and `SessionTransition` model requested acquisition as active or unavailable, active reads as active again, expiry as expired, and release as closed. `readSession` returns the same active session; expired and closed reads return `unavailablePoint` at its original point. Requested and unavailable reads also refuse their selected point. Closed and unavailable states have no outgoing transitions; an expired-read observation retains the expired state. Expiry is an event, with no duration or scheduler. The diagram's unresolved branch path is deliberately absent from the transition relation and remains a separate design question. The model does not implement pagination, token encodings, leases, storage retention or physical view release.

| Declaration | Model guarantee |
| --- | --- |
| `acquire_no_substitution` | For every point, arbitrary provider and successful session, the full session point equals the requested point |
| `acquire_preserves_offer` | Every successful session is exactly the provider's original offer, including all root fields and bytes |
| `acquire_absent` | Every provider absent at the selected point yields that point's unavailable refusal |
| `acquire_mismatch`, `acquire_refusal` | Any differing full point refuses; every acquisition error is precisely the selected-point unavailable refusal |
| `active_read`, `expired_read`, `closed_read` | Active reads preserve the session; expiry and closed reads refuse its point |
| `requested_transition`, `active_transition`, `expired_transition` | Inversions constrain every transition to the declared lifecycle destinations |
| `closed_terminal`, `unavailable_terminal` | Those states have no outgoing transition |

| Choice | Alternative | Reason |
| --- | --- | --- |
| Check the entire chainpoint | Compare only slots or accept the latest offer | Network and competing block hashes identify different ledger states |
| Return the unchanged provider session | Relabel its point after acceptance | Relabelling would conceal substitution and break evidence binding |
| Declare lifecycle events and observations | Introduce lease durations and retention machinery | Those service policies have no agreed implementation contract yet |

The [session tests](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Tests/Session.lean) prove concrete honest, absent, newer-slot, alternate-hash and alternate-network outcomes. Their permanent executable check obtains a successful session, performs two active reads, and requires expiry and closed-state refusal. These checks exercise the abstract session value rather than a ledger read service.

## Assess the evidence

`check-model` builds every model module, inventories every stored theorem including private proofs, and reports its axiom dependencies. It permits only Lean's standard `propext`, `Classical.choice` and `Quot.sound`; holes and custom escape axioms fail. Lean checks anonymous examples during compilation but does not retain them in the declaration inventory: strict compiler warnings and a source hole policy reject their holes. Deliberate named and anonymous `sorry`, `admit` and unused custom-axiom controls must reach the relevant rejection, rather than fail because a tool or import is missing.

The gate executes all three root scenarios and all three session scenarios, runs the permanent lifecycle check, and compiles both counterexample modules. In temporary build directories it removes the production trust filter, compiles the mutated definition, proves the unchanged universal safety statement false, and separately retains the failed unchanged proof output. It also checks compiled changed outcomes and proof rejection for observation, point/root binding, nonempty endorsement, agreement and refusal-point faults. The untrusted-key simulator must reject the unexpected result of the production subset mutation. This is a finite collection of negative controls, not a claim of exhaustive mutation coverage.

The session control copies the actual production acquisition definition into an isolated build directory, removes only its point-equality guard, then recompiles the session counterexample module and session simulator against that mutated module. The existing unchanged root dependencies are copied as compiled inputs; this control does not rebuild the full dependent closure. The compiled mutant executes newer-point acceptance and constructively refutes the unchanged `NoSubstitution` proposition. The exact unchanged `acquire_no_substitution` proof then fails at its point-equality conclusion, and the real newer-point simulator rejects the changed outcome. The general refutation helper applies to any operation with that acceptance witness, rather than only a separate fake acquisition copy.

Run `./lean/env lake env lean Lockness/Tests/Session.lean` or `./lean/env lake env lean Lockness/Counterexamples/SessionMutation.lean` for session checks and the [generic refutation](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Counterexamples/SessionMutation.lean). Run `./lean/env lake env lean Lockness/Counterexamples/SubsetMutation.lean` to inspect the constructive counterexample independently. Record `git rev-parse HEAD` alongside command output when assessing a candidate. CI invokes the same model and documentation commands; the source workflow alone is not evidence that remote CI has passed.

| Evidence layer | Limit |
| --- | --- |
| Design | Records the project trust boundary and open contracts |
| Model and simulator | Kernel-checked properties of this root and session model and concrete executable paths |
| Documentation checks | Presentation, speech freshness and strict site construction |
| Independent acceptance and remote CI | Require revision-bound review and actual successful workflow results |
| Component implementation, deployment and live chain | Not established by this model |

The Lean kernel remains part of the trust base. Observation soundness and honest-root correspondence are external assumptions. The executable guard and statement share the definition of a qualifying candidate; the mutation checks preserve that statement while altering execution, and do not independently prove specification fidelity. Ledger witness checks, application proofs, effects, canonicality, freshness, settlement and abandoned-branch session policy remain later work. Consume model and documentation by reviewed revision; a tagged binary distribution pipeline remains future implementation work.

Continue to [design decisions and remaining guarantees](../design/decisions.md) and the [project architecture](../architecture/system.md).
