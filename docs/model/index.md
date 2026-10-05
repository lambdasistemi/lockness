# Inspect roots, sessions, ledger answers, application claims, verdicts and the operating context

As a design reviewer, run a terminal's root choice against trusted and untrusted publications. An honest scenario returns the accepted root and selected chainpoint. A publication from an untrusted key returns `no-root` at that same point, even when signature validity is assumed. Removing the trusted-set check demonstrates why that refusal matters.

A terminal also acquires exactly its selected point, repeats reads from that session, and receives the original-point refusal when the provider is absent, offers another point, or the session expires.

A terminal then verifies the ledger answer against its independently accepted root. An honest answer returns the application root in the witnessed output's datum. A witness valid only under a provider root refuses at the selected point. Two honest outputs carrying the same asset show why a separate uniqueness assumption is needed.

Finally, a terminal accepts an application claim only after root acceptance, exact-point acquisition, ledger verification and every application link have succeeded. An honest builder yields a verified claim. A builder that claims another root is refused at the selected point, even with a proof valid under that root. A two-link chain is checked link by link, and a failure at the second link rejects the whole claim. Under the stated root, ledger and application soundness premises plus functional application content, two providers and two builders cannot make the terminal accept two different claims for the same policy, publications and point; without functional content they can.

Around all of this, the terminal classifies every outcome as verified, refused or unverified. A verified verdict carries exactly the claim that acceptance returned. A refused verdict carries acceptance's own refusal at the selected point. Unverified traffic is a first-class case for a declared absence only: no verifier configured, a session declared unbound, or a session bound to the selected point offering no witness. With a verifier configured, a present but wrong witness, or a session bound to another point, is refused, and in every case an answer without a witness can never be promoted to verified.

All of it happens inside one declared operating context: the network the terminal runs on and the commitment schemes it accepts. A selected point on another network, or a root under a scheme the terminal does not accept, is refused at the selected point, never reported as unverified. A publication from another network is ignored: it neither endorses a root here nor blocks one.

This is an executable project model and simulator. Component implementations, cryptography, deployment and live-chain behavior require separate evidence. Review the model and this page from the same Git revision. Inherited session links retain their published source branch. Ledger source links reference the published ledger model revision, application source links reference the published application model revision, verdict source links reference the published verdict model revision, and operating context source links reference the published context model revision. Its model bytes must match the reviewed candidate. Acceptance and source publication are separate evidence.

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
./lean/env lake exe lockness-sim ledger honest
./lean/env lake exe lockness-sim ledger substituted-root
./lean/env lake exe lockness-sim ledger duplicate-asset
./lean/env lake exe lockness-sim app honest
./lean/env lake exe lockness-sim app replaced-root
./lean/env lake exe lockness-sim app nested
./lean/env lake exe lockness-sim app ambiguous-value
./lean/env lake exe lockness-sim verdict verified
./lean/env lake exe lockness-sim verdict no-witness
./lean/env lake exe lockness-sim verdict unbound-session
./lean/env lake exe lockness-sim verdict no-verifier
./lean/env lake exe lockness-sim verdict wrong-witness
./lean/env lake exe lockness-sim verdict misbound
./lean/env lake exe lockness-sim verdict promoted
./lean/env lake exe lockness-sim context honest
./lean/env lake exe lockness-sim context wrong-network-point
./lean/env lake exe lockness-sim context wrong-network-publication
./lean/env lake exe lockness-sim context unaccepted-scheme
./lean/env lake exe lockness-sim context unbound-message
./tools/check-model.sh
./tools/check-docs.sh
just ci
```

`lean/env` enters the `lean/` directory with revision-pinned Lean 4.29.0 and its C compiler, and rejects a different Lean version. For an interactive pinned environment, run `./lean/env bash`; there the commands are `lake build` and `lake exe lockness-sim accept-root <scenario>`. The [toolchain file](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/lean-toolchain) also supports standard Elan workflows. Ledger sets use Mathlib `Finset` at revision `8a178386ffc0f5fef0b77738bb5449d50efeea95`, with narrow finite-set imports and every transitive Lake revision recorded in the [manifest](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/lake-manifest.json). Lean and Nix pins are unchanged. The environment supplies pinned Git, Curl and Zstd and rehydrates the required Mathlib cache from the committed dependency graph when needed. Dependency and cache acquisition are setup, not proof evidence.

| Scenario | Observable result |
| --- | --- |
| Honest publications | `accepted-root`, full selected point, exact root scheme and bytes, two distinct endorsers despite a duplicate publication |
| Untrusted key | `no-root`, full selected point, signature validity explicitly labelled an abstract assumption |
| Removed trusted-set check | Production refuses; the mutation accepts the untrusted root and has a compiled refutation of the unchanged safety statement |
| Honest session | Exact point and independently obtained root; two unchanged active reads, expiry refusal and release to closed |
| Absent point | `unavailablePoint` at the selected point |
| Newer point | `unavailablePoint` at the selected point; same-slot alternate hash and alternate network also refuse |
| Honest ledger answer | Application root of the authenticated output; independent root acceptance is executed first, provider root fields are ignored |
| Substituted root | Witness succeeds under the answer's root and fails under the independent accepted root; verifier returns selected-point `evidenceFailure` |
| Duplicate asset | Two distinct finite honest members carrying the same asset both verify, returning different datum roots; OneShot and the unique-output conclusion are false |
| Honest application claim | Claim at the selected point with the accepted ledger root, the application root and the final value; two providers with different untrusted roots and two builders with different proof bytes yield the same claim in a fixture that satisfies every premise |
| Replaced application root | The answer claims another root with a proof valid there and passes every other check; the proof fails under the trusted root, and accept returns selected-point `evidenceFailure` |
| Nested application root | Both links are checked and the inner root is reported; a bad proof, replaced root or missing answer at the second link, or fuel 1 or 0, refuses the whole claim |
| Ambiguous value | Two values are committed for one query under one root; two builders make accept return two different claims, so invariance needs the separate functional premise |
| Verified verdict | A session bound to the selected point offers the honest witness and carries reconstruction material; the verdict is verified with exactly the claim accept returns |
| No witness | The bound session offers the honest object without a witness; the verdict is unverified with reason no witness, and accept refuses with selected-point `evidenceFailure` |
| Unbound session | The session declares no binding while offering a valid witness; the verdict is unverified with reason unbound session, accept refuses, and the terminal adopts no point |
| No verifier | The policy declares no verifier; the verdict is unverified with reason no verifier, although accept on the same offer would succeed |
| Wrong witness | The bound session offers a witness that fails under the accepted root; the verdict is refused with selected-point `evidenceFailure`, never unverified |
| Misbound session | The session declares a binding to another point and is otherwise honest; the verdict is refused with selected-point `evidenceFailure`, never unverified |
| Promotion attempt | The impostor object from the root-substitution witness is offered bound but without a witness; the verdict stays unverified with reason no witness and accept refuses |
| Context honest | The terminal runs on network `[0]` and accepts scheme `[0]`; the honest offer is verified with the same claim accept returns, and the claim's network and scheme are printed from the claim |
| Wrong-network point | The terminal is configured for network `[1]` while the selected point is on network `[0]`; with a bound, witnessed session and with an unbound session alike, the verdict is refused with selected-point `evidenceFailure`, never unverified |
| Wrong-network publication | A trusted key's verified publication of the honest root at the same slot and block hash on network `[1]` is appended to the honest publications, and the verdict is the same verified claim; when the only endorsements are on network `[1]`, the verdict and accept are `noRoot` at the selected point, never unverified |
| Unaccepted scheme | The terminal accepts only scheme `[1]` and the honest root uses scheme `[0]`; the verdict is refused with selected-point `evidenceFailure` |
| Unbound message | Under a policy that checks signatures only, publications at the selected point on network `[0]` are signed over messages that name a point on network `[1]`; the verdict is verified, which only the message-binding hypothesis excludes |

An unexpected scenario outcome exits nonzero. Unknown commands, missing scenario arguments and unknown root, session, ledger, app, verdict or context scenarios exit with usage code 64. Each verdict scenario prints the verdict, accept's own outcome and the selected point; each context scenario also prints the terminal's context, and the two-observation scenarios print their second verdict and accept beside the first. These are executable model observations, without a network, ledger provider or signature implementation.

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

The [acceptance definition](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Root.lean) returns `noRoot selectedPoint` when no proposal qualifies. The shared refusal type has exactly three constructors: `noRoot`, `unavailablePoint` and `evidenceFailure`, each carrying the selected point. Root acceptance only emits `noRoot`; session acquisition emits `unavailablePoint`. Ledger and application verification emit `evidenceFailure`; all three retain the selected point.

| Design choice | Alternative | Reason |
| --- | --- | --- |
| Policy supplies arbitrary executable observations | Compute an arbitrary validity proposition | Arbitrary propositions are not generally executable; signature soundness stays an explicit hypothesis |
| Distinct keys endorse the exact point and root | Count publication copies | Repeated messages cannot invent independent endorsement |
| Filter trusted members before agreement | Let irrelevant untrusted publications prevent acceptance | Trust belongs to the terminal's selected policy |
| Require nonempty endorsement | Let a permissive agreement accept no evidence | Agreement alone cannot authorize an empty set |
| Separate honest-root correspondence | Infer ledger correctness from signatures and agreement | Trusted publishers can endorse a wrong ledger root |

## Read the model contracts

The [shared types](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Types.lean) preserve exact byte sequences. Network and root scheme are explicit byte identities, slot is a natural number, and every equality includes all fields. There is no normalization, serialization, hashing or signing algorithm. The [verdict successor of the shared types](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Types.lean) adds the declared binding, the optional witness, reconstruction material, the declared verifier and the verdict itself. The [operating context successor](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Types.lean) adds the terminal's declared context to the policy and the abstract message model with its binding hypothesis.

| Surface | Contract in this slice |
| --- | --- |
| `Bytes`, `Chainpoint`, `Root`, `Publication` | Original byte sequences, exact point/root identities and original message/signature evidence |
| `Policy` | Trusted keys, agreement and publication observations; selected asset/schema and explicit byte decoding, witness, asset and datum observations; the fixed application query, application proof check, nested-root reading and link fuel; whether the terminal has a verifier, read only by the verdict; the operating context its trusted keys are trusted in |
| `Context` | The network identifier and the accepted commitment scheme identifiers; a scheme identifier carries its version |
| `MessageModel`, `MessageBinding` | What a signed message encodes, an arbitrary hypothesis like signature validity; binding assumes a valid signature's message encodes exactly its publication's point and root and nothing else |
| `Refusal` | Exactly the three selected-point refusals |
| `Session` | Selected point, provider root, the provider's untrusted answer to the policy's ledger query and the provider's declared binding; acquisition and lifecycle in the session module, described below |
| `LedgerAnswer` | Point, exact object bytes, an optional witness, untrusted provider root and optional reconstruction material; verification is described below |
| `Binding` | Either bound to a chainpoint or unbound, as the provider declares for its session |
| `Reconstruction` | Transaction bytes and resolved spent outputs, its own type distinct from every evidence type; carried, never read as evidence |
| `Reason`, `Verdict` | The terminal's classification: verified with a claim, refused with a refusal, or unverified with one of three payload-free reasons, no witness, unbound session or no verifier; never a wire object |
| `AppAnswer` | Application identity, context, point, claimed root, claim, exact value and proof bytes; untrusted until application verification, described below |
| `AppQuery`, `AppProof`, `AppValue` | The terminal's fixed application, context and claim bytes; uninterpreted proof bytes; exact value bytes |
| `Claim` | Selected point, accepted ledger root, query, application root, checked nested roots and final value; no proof bytes or provider roots |

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

## Verify ledger answers

As a terminal, use a provider's answer to identify the application root carried by an asset's honest ledger output. Supply the root independently accepted for the selected network, slot and block hash. The [ledger verifier](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/Lockness/Ledger.lean) checks answer-point equality, decodes the object to exact input/output bytes, and requires re-encoding to reproduce the witnessed object unchanged. It checks the witness against the independent root argument and those original object bytes. It then checks the asset on that same decoded output, extracts its datum, and parses those bytes under the policy schema. Every failed observation returns `evidenceFailure session.selectedPoint`.

The [verdict revision of the verifier](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Ledger.lean) adds two refusals, also at the selected point. Right after the point check, it refuses a session whose declared binding is not its own selected point. And the witness check now fails when the answer offers no witness; a present witness is still checked only under the independently accepted root. The observation lemma records both: a successful answer comes from a session bound to its selected point and carries a witness that passed under the accepted root. Every other ledger statement on this page is unchanged.

```lean
verifyLedger : Policy → Root → Session → LedgerAnswer → Except Refusal Root
Ledger := Chainpoint → Finset (TxIn × TxOut)
```

The provider's `answer.root` and `session.acceptedRoot` are neither authorities nor required equality conditions. An honest answer can succeed when both disagree with the accepted root. Acquisition only establishes point coherence; it cannot create root endorsement or honest-root correspondence. Root acceptance's trusted endorsement and the separate selected-point correspondence hypothesis remain distinct.

```mermaid
flowchart TD
    A[Independent accepted root] -->|checks witness under this root| W[Witnessed object bytes]
    P[Selected full chainpoint] -->|requires exact answer identity| W
    W -->|decode and reproduce exact bytes| O[Same input and output pair]
    O -->|observe policy asset| D[Same output datum]
    D -->|parse under policy schema| R[Returned application root]
    W -->|failed observation| F[Evidence failure at selected point]
    O -->|failed observation| F
    D -->|failed observation| F
```

The [soundness proof](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/Lockness/LedgerProofs.lean) quantifies arbitrary policies, finite ledgers, roots, sessions, answers and interpretations. Under all the following premises, successful verification identifies a member at the selected point which actually carries the policy asset, has the returned honest datum root, and equals every other member carrying that asset.

| Explicit premise | What it supplies |
| --- | --- |
| Selected-point honest-root correspondence | Independent accepted root equals the honest commitment for this exact selected point |
| `WitnessSound` | A successful witness check under the honest root implies membership of the exact input/output pair |
| `ObjectEncodingFaithful` | The policy's representation is injective on exact input/output byte pairs; this is an external representation assumption |
| `AssetObservationSound` | A successful asset observation implies that the same output actually carries that asset |
| `DatumObservationSound` | Extraction and parsing of that same output's bytes under the selected schema agree with its honest datum root |
| `OneShot` | At every point, any two member pairs carrying the selected asset are equal |

`verifyLedger_observations` exposes the full successful path, including exact bytes and every interpretation observation. `verifyLedger_refusal` proves the selected-point evidence refusal for every error. `verifyLedger_sound : LedgerSoundness verifyLedger` proves the complete member, asset, honest datum-root and unique-pair conclusion under those premises. Encoding injectivity remains an explicit premise of the frozen contract; byte binding itself uses the executable re-encoding equality. These predicates do not implement cryptography, a datum format, CSMT internals or Cardano serialization.

The [honest fixtures](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/Lockness/Counterexamples/LedgerFixtures.lean) inhabit all premises together with selected-point correspondence and acceptance. Their reversible framing preserves zero bytes, order and `255`, and its injectivity is proved for arbitrary byte pairs. This framing is only an example of an abstract representation. The honest ledger has one member; the unrestricted ledger type also admits two different outputs carrying the same asset. No uniqueness restriction is hidden in its type.

The [root-substitution witness](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/Lockness/Counterexamples/LedgerRootMutation.lean) passes point, decoding, byte binding, asset and datum conditions. Its unchanged witness succeeds under the provider root and fails at the real accepted-root boundary. A compiled mutation of the actual verifier, checking either the answer root or session root, accepts the impostor and constructively falsifies the unchanged `LedgerSoundness` statement. The original proof and actual simulator outcome assertion then reject that mutation.

The [duplicate-asset refutation](https://github.com/lambdasistemi/lockness/blob/3b88416def14c9d2da0d04ab0d595e5de7b91493/lean/Lockness/Counterexamples/LedgerUniqueness.lean) has two distinct honest finite members, the same asset, different datum roots and two successful answers under one independent root. Witness, encoding, asset and datum assumptions and selected-point correspondence all hold. Only OneShot is false. Removing exactly that premise from the universal statement leaves its complete conclusion unchanged; a constructive proof negates the resulting guarantee. A failed tactic is not used as the counterexample.

| Choice | Alternative | Why |
| --- | --- | --- |
| Genuine finite sets | Unrestricted lists | Ground truth has finite-set membership and equality semantics |
| Independently accepted root argument | Check under provider answer/session root | A provider cannot endorse its own evidence |
| Preserve and bind the same object bytes | Observe a separately decoded or normalized output | Membership must authenticate the output whose asset and datum are interpreted |
| Explicit executable callbacks and soundness predicates | Treat Boolean success as semantic truth | Witness correctness and interpretation correspondence remain separately assumed |
| Separate OneShot premise | Forbid duplicate assets in every ledger value | Membership and unique state are different claims; the counterexample stays reachable |

## Verify application claims

As a terminal, accept an application claim only when every root it rests on has been checked by you. The ledger step yields an application root; an application answer then binds a value under that root, and the value may carry a further root that needs its own answer. Providers and builders are arbitrary functions: a builder answers `Root → Option AppAnswer` with no honesty restriction. The [application step](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/App.lean) and the [whole fold](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Accept.lean) are:

```lean
verifyApp : Policy → Chainpoint → Root → AppAnswer → Except Refusal AppValue
verifyChain : Policy → Chainpoint → Builder → Nat → Root → Except Refusal (List Root × AppValue)
accept : Policy → List Publication → Chainpoint → Provider → Builder → Except Refusal Claim
```

The issue promised `verifyApp : Root → AppAnswer → Except Refusal AppValue`. The model takes the policy and the selected point first, so `verifyApp policy selectedPoint` has exactly that type. This is a stated deviation: with only a root and an answer, the proof checker would have to be a hidden global, and a refusal could carry only the answer's untrusted point. Passing both explicitly keeps the checker visible and makes every refusal carry the caller's selected point.

`verifyApp` checks, in this order, that the answer's claimed root equals the trusted root, that its point is the selected point, that its application, context and claim equal the policy's fixed query, and that the policy's proof check succeeds for the answer's proof, the trusted root, the policy query and the value. The claimed root is compared and never adopted, and the proof is never checked under the answer's root or query fields. Every failure is `evidenceFailure` at the selected point. `verifyChain` counts checked links with its fuel: when the policy reads no further root from a value, that value is final; otherwise the next root is checked with one less fuel. Running out of fuel with a root still pending, a missing answer, or a failure at any link refuses the whole claim. No partial claim is ever returned.

`accept` runs root acceptance, acquisition at the selected point, ledger verification of the session's ledger answer under the root returned by root acceptance, and then the chain from the ledger's application root with the policy's fuel. The provider's session root, its ledger answer root and every answer's claimed root are data, never checking authority. The accepted `Claim` holds the selected point, the accepted ledger root, the query, the application root, the nested roots in order and the final value.

The [proofs](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/AcceptProofs.lean) state their conclusions over arbitrary policies, publications, points, providers and builders. `holds` is the semantic claim: the claim's query is the policy query, a unique asset-bearing member of the selected point's ledger has the claim's application root as its honest datum root, and the claimed chain holds in the honest application content. It is defined from that content, never from `accept` or a guard.

| Explicit premise | What it supplies | Used by |
| --- | --- | --- |
| Honest-root correspondence and the five ledger premises | The ledger guarantee described above | Soundness and invariance |
| `AppSound` | A successful proof check under a root implies that the query and value pair is committed under that root | Soundness and invariance |
| `NestingInterpretationFaithful` | The policy reads a further root from a value exactly when the value honestly carries it, so a final value is honestly final | Soundness |
| `AppFunctional` | One root commits at most one value for one query | Invariance only |

| Declaration | Established model guarantee |
| --- | --- |
| `accept_sound : AcceptSoundness accept` | Under honest-root correspondence, the five ledger premises, `AppSound` and faithful nesting, an accepted claim is at the selected point, its ledger root is the honest root, and `holds` its claim over the selected point's ledger |
| `accept_provider_invariant : ProviderInvariance accept` | Under honest-root correspondence, the five ledger premises, `AppSound` and `AppFunctional`, two successful accepts with arbitrary providers and builders return equal claims; availability and refusals may still differ |
| `accept_refusal` | Every refusal from any step carries the selected point; root, acquisition and evidence refusals keep their constructors |
| `verifyApp_claimed_root_first` | For every policy and proof check, a claimed root other than the trusted root is refused |

The [application fixture](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Counterexamples/AppFixtures.lean) inhabits every premise of both statements together with successful one-link and two-link acceptance. Two providers offer different untrusted session and ledger answer roots, and two builders return different valid proof bytes; both yield the identical claim. Every expected claim is evaluated from the honest content, never typed in or read from `accept`.

The [root counterexamples](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Counterexamples/AppRootMutation.lean) are parameterized by the operation. The gate compiles a copy of the real verifier with the claimed-root comparison removed and the proof checked under the claimed root. That mutant accepts a value committed only under another root and constructively refutes the unchanged soundness statement; the original proofs then fail, and the real replaced-root scenario rejects the changed outcome. A second compiled mutant checks the ledger answer under the session's own root. It accepts the substituted ledger answer and refutes the same statement, and the real honest scenario fails because untrusted provider roots become authority. The [ambiguity refutation](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Counterexamples/AppAmbiguity.lean) keeps every invariance premise except `AppFunctional` and shows two different accepted claims. That statement is copied by hand from `ProviderInvariance`; its faithfulness is a residual for review in issue #11.

| Choice | Alternative | Why |
| --- | --- | --- |
| Policy and selected point before root and answer | The literal two-argument verifier | No hidden checker, and refusals carry the selected point |
| Compare the claimed root first | Check the proof under the answer's root | A builder cannot choose the root its own proof is judged against |
| Count links with fuel and refuse on exhaustion | Return the links checked so far | A partial chain is not the claim the terminal asked for |
| Separate `AppFunctional` premise | Assume soundness implies a unique value | Membership alone admits two values for one query; the counterexample stays reachable |
| Session carries the provider's ledger answer | A second provider operation or builder-supplied ledger evidence | Keeps acquisition and its proofs unchanged and the ledger and application roles separate |

Two limits are deliberate. Every link is checked against the same policy query; per-link queries, or different queries in nested trees, are not modelled and are reviewed in issue #11. A session carries one answer, to the policy's single ledger query; several ledger queries per session belong to later wire contracts. Proof formats, application validators, transition binding and transaction construction are not modelled.

## Classify verdicts

As a terminal, tell apart three situations that look alike from outside: data you verified, data you checked and found wrong, and data nobody offered evidence for. A provider without witnesses, or a terminal without a verifier, is still useful traffic, but it must never be mistaken for a verified fact. The [verdict layer](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Verdict.lean) wraps the unchanged `accept`:

```lean
unverifiedReason : Chainpoint → Provider → Option Reason
verdict : Policy → List Publication → Chainpoint → Provider → Builder → Verdict
```

The verdict is decided in a fixed order. First, a policy that declares no verifier gives unverified with reason no verifier, and nothing else is consulted. Next, when accept returns a claim, the verdict is verified with that same claim. When accept refuses a selection outside the terminal's operating context, described below, the verdict is refused. Otherwise, when accept refuses, the verdict is unverified only if the offered session declares an absence: unbound gives reason unbound session, and bound to the selected point without a witness gives reason no witness. Every other refusal is passed on unchanged as refused. The reason reads only the session that acquisition accepts, so a provider offering another point is refused by acquisition exactly as before.

With a verifier configured, root acceptance succeeding and a session offered at the selected point, the outcomes are:

| Offered session | Accept | Verdict |
| --- | --- | --- |
| Bound to the selected point, witness passes under the accepted root, every other check passes | the claim | verified, same claim |
| Bound to the selected point, no witness | evidence failure | unverified, no witness |
| Declared unbound, witness present or not | evidence failure | unverified, unbound session |
| Bound to the selected point, witness present but wrong | evidence failure | refused, evidence failure |
| Bound to a different point | evidence failure | refused, evidence failure |

When root acceptance refuses, accept returns that no-root refusal before reading the provider. The verdict is then unverified if the offered session declares an absence, and otherwise refused with the no-root refusal. With no verifier configured, every row is unverified with reason no verifier.

The [verdict proofs](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/VerdictProofs.lean) hold for every policy, provider and builder unless a premise is named:

| Declaration | Established model guarantee |
| --- | --- |
| `verdict_no_promotion : NoPromotion verdict` | With no hypothesis, a verified claim implies a configured verifier, a session offered at and bound to the selected point, a present witness, and accept returning that exact claim |
| `verdict_verified_iff` | The verdict is verified with a claim exactly when the verifier is configured and accept returns that claim |
| `accept_bound_witnessed` | Accept itself never succeeds without a session offered at the selected point, bound to it, whose answer carries a witness |
| `verdict_sound`, `verdict_provider_invariant` | Soundness and provider invariance hold for every verified claim under exactly the premises of the acceptance statements, proved from no promotion and the unchanged acceptance proofs |
| `verdict_refused`, `verdict_refusal` | A refused verdict implies a configured verifier and that accept returned that same refusal, so it carries the selected point |
| `verdict_unverified` | An unverified verdict comes either from no verifier configured, or, with a verifier configured, from accept refusing while the session offered at the selected point is declared unbound or is bound to that point without a witness |
| `witnessed_never_unverified` | With a verifier configured, a session offered at the selected point, bound to it and carrying a witness is never unverified: wrong evidence is refused |
| `unbound_only_unverified` | Inside the operating context, whether or not a verifier is configured, a session offered at the selected point and declared unbound yields only unverified, and accept never succeeds on it; out of context, with a verifier, the selection is refused instead |
| `misbound_refused`, `misbound_never_unverified` | With a verifier configured, a session offered at the selected point but bound to a different point is refused, never unverified, with accept's own refusal; when root acceptance also succeeds, that refusal is exactly evidence failure at the selected point |
| `verdict_reconstruction_irrelevant` | Replacing every offered reconstruction never changes the verdict |

The [verdict fixtures](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Counterexamples/VerdictFixtures.lean) reuse the application fixture's policy, publications, selected point and honest builder. One jointly inhabited input proves every acceptance soundness premise together with a verified verdict and the no-promotion conclusion at that input. Every expected claim is evaluated from the honest content, never typed in or read from accept.

The [promotion refutations](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Counterexamples/VerdictPromotion.lean) are parameterized by the operation. The gate compiles a copy of the real ledger verifier that lets an absent witness pass. That mutant verifies the witness-less impostor, whose datum root is absent from the honest ledger, and constructively refutes both the unchanged no-promotion and the unchanged verified-soundness statements; the unchanged ledger observation proof then fails, and the real promotion scenario rejects the changed outcome. Three more compiled mutants alter the verdict itself. Ignoring the declared verifier refutes no promotion and breaks the verified-iff proof and the no-verifier scenario. Reading a present wrong witness as absent breaks the wrong-witness proof and scenario. Reading any other binding as unbound breaks both misbound proofs and the misbound scenario.

| Choice | Alternative | Why |
| --- | --- | --- |
| The verdict is a terminal classification around an unchanged accept | Put a verdict on the wire, or change accept's result type | Acceptance and its proofs stay intact; the verdict is the terminal's judgement, not a provider claim |
| Unverified only for a declared absence | Treat any refusal caused by missing or contradictory evidence as unverified | A provider could otherwise downgrade a refusal by lying, for example by declaring a binding to another point |
| Both new guards inside the ledger verifier | Guard binding in acquisition, or wrap the witness in a second offer type | Acquisition, acceptance and their statements stay byte-identical; only the ledger step changes |
| An absent witness always fails the witness check | Let a policy accept an absent witness | That would be promotion by configuration |
| No verifier is decided first, consulting nothing | Refuse an unavailable point before reporting no verifier | A terminal without a verifier makes no evidence claim at all, so nothing is refused on evidence grounds |
| Reconstruction is its own optional type | Reuse witness or proof bytes | It cannot be mistaken for evidence, and irrelevance is proved |

The limits are named. With the verifier off the verdict is unverified with reason no verifier even when the provider offers nothing. A reason carries no payload, so any material an unverified offer might supply must be taken from the offer itself by a later step. A witness on an unbound session is never checked. Reconstruction is carried and never checked or used as evidence. A session still carries one ledger answer. The exact evidence-failure refusal for a misbound session depends on root acceptance succeeding; without it the refusal is root acceptance's own. The verified soundness and invariance statements are hand copies of the acceptance statements with only the success premise changed, and their faithfulness is reviewed in issue #11. The action step and its policy belong to issue #10, and the wire encoding of the binding, witness and reconstruction to issue #17.

## Bind the operating context

As a terminal operator, run the terminal on one network and accept roots only under the commitment schemes you chose. Evidence from elsewhere must never pass, and it must never be softened into unverified traffic: a selected point on another network is present and wrong. A provider cannot change this, because the context is the terminal's own policy, not something the provider declares.

The [context guard](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Context.lean) reads only the terminal's facts: the selected point's network and the scheme of the root that root acceptance would select. It never reads a publication's network, a provider or a builder.

```lean
outOfContext : Policy → List Publication → Chainpoint → Bool
acceptContextRoot : Policy → List Publication → Chainpoint → Except Refusal Root
```

A selection is out of context when the selected point's network differs from the context network, or when the root that root acceptance selects has a scheme outside the accepted schemes. Root acceptance in context refuses an out-of-context selection with `evidenceFailure` at the selected point and otherwise returns exactly what root acceptance returns. The [whole fold](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Accept.lean) binds its root through it, so the context is checked before acquisition and every later step is unchanged. The [verdict](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Verdict.lean) keeps the verifier switch first; after accept refuses, an out-of-context selection is refused before any declared absence is considered.

Trust in keys is exercised only inside the context. A policy carries one context, so its trusted keys are trusted for that network and those schemes. A publication on another network cannot endorse a point on this one, because root acceptance compares the whole point. It cannot veto either: the publication list is untrusted input, and refusing a selection because of one foreign entry would let anyone able to add such an entry refuse every selection.

That a signature's message says which point and root it is about is a separate hypothesis. `MessageBinding` assumes that a valid signature's message encodes its publication's point and root, and that a message encodes at most one point and root. Without its second half, a model that lets every message encode everything would satisfy it vacuously. Nothing computes it, exactly as nothing computes signature validity; its concrete encoding belongs to issue #17.

The [context proofs](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/ContextProofs.lean) hold for every policy, publication list, point, provider and builder, with the [statements](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/ContextStatements.lean) as written. Root acceptance in context refuses only as root acceptance does, with `noRoot`, or as the guard does, with `evidenceFailure`; a root it accepts is the root acceptance root, on the context network and under an accepted scheme, and so is every claim accept returns. An out-of-context selection makes accept refuse with selected-point `evidenceFailure`, and with a verifier configured the verdict is that refusal, whatever the provider offers; this holds in particular for a selected point on another network and for a selected root under an unaccepted scheme. Appending publications whose points are on another network changes neither root acceptance in context, nor accept, nor the verdict. Under `ObservationSound` and `MessageBinding`, a verified claim is on the context network, under an accepted scheme, and endorsed by a nonempty agreeing set of trusted keys, each with a publication at the claim's point and root whose signature is valid and whose message encodes exactly that point and root.

| Declaration | Established model guarantee |
| --- | --- |
| `acceptContextRoot_refusal`, `acceptContextRoot_in_context` | Refusals are `noRoot` or `evidenceFailure` at the selected point; an accepted root is root acceptance's own root, in context |
| `accept_in_context` | Every accepted claim's point is on the context network and its ledger root's scheme is accepted |
| `out_of_context_refused` | Out of context, accept refuses with selected-point `evidenceFailure` before reading the provider or builder |
| `out_of_context_never_unverified`, `wrong_network_refused`, `unaccepted_scheme_refused` | With a verifier configured, an out-of-context selection, a selected point on another network, or a selected root under an unaccepted scheme is refused with selected-point `evidenceFailure`, never unverified |
| `foreign_publication_ignored` | Appending publications on another network changes neither root acceptance in context, nor accept, nor the verdict |
| `verdict_context_sound : ContextSoundness verdict` | Under observation soundness and message binding, every verified claim is in context and endorsed only by trusted keys whose valid signatures cover messages encoding exactly its point and root |

The five context scenarios show these guarantees on the real verdict and accept. In the honest scenario the terminal runs on network `[0]` with scheme `[0]` accepted, and the honest offer is verified with the claim accept returns. In the wrong-network-point scenario the terminal is configured for network `[1]` while the selected point is on network `[0]`; both a bound, witnessed session and an unbound one are refused with selected-point `evidenceFailure`. In the wrong-network-publication scenario a trusted key's verified publication on network `[1]`, appended to the honest ones, leaves the same verified claim, and endorsements on network `[1]` alone give `noRoot` at the selected point. In the unaccepted-scheme scenario a terminal accepting only scheme `[1]` refuses the honest root under scheme `[0]`. In the unbound-message scenario signatures over messages naming network `[1]` make the verdict verified under a policy that checks signatures only, which is exactly what the message-binding hypothesis excludes.

The [context fixtures](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Counterexamples/ContextFixtures.lean) reuse the verdict fixture's publications, selected point, provider and builder. A finite decoder table gives each fixture message one point and root, and a signature table gives each trusted key's signature; both are fixture framing, not an encoding. One policy observes exactly the signatures that are valid in this honest model, so observation soundness, message binding, a verified verdict and the context conclusion are inhabited together by one input. The [refutations](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Counterexamples/ContextRefutation.lean) are parameterized by the operation. Without the network guard, the terminal configured for network `[1]` verifies the honest root endorsed on network `[0]` and refutes the unchanged context soundness; without the scheme guard, a root under scheme `[0]` is verified by a terminal accepting only scheme `[1]`, which refutes the unchanged context soundness as well. The statement with the message-binding premise removed is false on the real verdict, while the unchanged statement, which keeps the premise, is not refuted: signatures checked against the table alone, over messages naming network `[1]`, endorse the selected point on network `[0]`, and the unbound-message scenario reproduces that verified outcome on the real model.

Each choice keeps the inherited model intact. The guard wraps root acceptance instead of changing it, and an out-of-context selection reuses the selected-point `evidenceFailure` refusal rather than adding a constructor. The verifier switch stays first, because a terminal without a verifier consults nothing. One context per policy scopes the trusted keys without moving them, and a scheme identifier carries its version, so no inherited root changes shape.

| Choice | Alternative | Why |
| --- | --- | --- |
| A foreign publication is ignored | Refuse the whole selection when any fetched publication is on another network | The publication list is untrusted; a veto would let one junk entry refuse every selection, and one key may honestly publish on two networks |
| The guard wraps the unchanged root acceptance | Change root acceptance itself | Every root acceptance statement and scenario stays unchanged; the context check is one named step before acquisition |
| Out of context is selected-point `evidenceFailure` | A new refusal constructor, or `noRoot` | Refusals keep their three constructors and the selected point; the evidence is present and wrong, not absent |
| The verifier switch stays first | Check the selected network before the verifier switch | Without a verifier nothing is consulted; the scheme condition reads evidence and would stay unverified anyway, and the refusal theorem would need restating |
| One context per policy scopes its trusted keys | Move the trusted keys into the context | With one context per policy the meaning is the same, and the root acceptance definitions stay unchanged |
| A scheme identifier carries its version | A separate version field on the root | Every inherited root and its printed form stay unchanged; how scheme and version are split on the wire is issue #17's |

The limits are named. With no verifier configured, an out-of-context selection is unverified with reason no verifier, like every other outcome; what an unverified fact may drive is issue #10's action policy. Foreign publications are proved ignored when appended; the order of the untrusted publication list can still decide which of several roots endorsed inside the context is selected, an inherited root acceptance property reviewed in issue #11. `MessageBinding` is assumed, never checked.

The model does not cover genesis or era identity: concrete network identifiers belong to issue #17. Protocol parameters are not modelled; transaction construction belongs to issue #10 and every other use to the implementation milestones. Validator script hashes belong to the implementation milestones.

## Assess the evidence

`check-model` builds every model module, inventories every stored theorem including private proofs, and reports its axiom dependencies. It permits only Lean's standard `propext`, `Classical.choice` and `Quot.sound`; holes and custom escape axioms fail. Lean checks anonymous examples during compilation but does not retain them in the declaration inventory: strict compiler warnings and a source hole policy reject their holes. Deliberate named and anonymous `sorry`, `admit` and unused custom-axiom controls must reach the relevant rejection, rather than fail because a tool or import is missing.

The gate executes the root, session, ledger, application, verdict and context scenarios, runs the permanent lifecycle check, and compiles the root, session, ledger, application, verdict and context counterexamples. It also records the types and axiom dependencies of every stored named model declaration, rather than selecting only the main proofs. Ledger tests cover each network/slot/hash mismatch, decode and byte-binding failures, witness/asset/schema/datum refusals, ignored provider roots and jointly inhabited acceptance premises. In temporary build directories it removes the production trust filter, compiles the mutated definition, proves the unchanged universal safety statement false, and separately retains the failed unchanged proof output. It also checks compiled changed outcomes and proof rejection for observation, point/root binding, nonempty endorsement, agreement and refusal-point faults. The untrusted-key simulator must reject the unexpected result of the production subset mutation. This is a finite collection of negative controls, not a claim of exhaustive mutation coverage.

The session control copies the actual production acquisition definition into an isolated build directory, removes only its point-equality guard, then recompiles the session counterexample module and session simulator against that mutated module. The existing unchanged root dependencies are copied as compiled inputs; this control does not rebuild the full dependent closure. The compiled mutant executes newer-point acceptance and constructively refutes the unchanged `NoSubstitution` proposition. The exact unchanged `acquire_no_substitution` proof then fails at its point-equality conclusion, and the real newer-point simulator rejects the changed outcome. The general refutation helper applies to any operation with that acceptance witness, rather than only a separate fake acquisition copy.

The application controls work the same way. The [application tests](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/Lockness/Tests/App.lean) check each first-link point, application, context, claim and proof refusal, each second-link failure, fuel exhaustion, and the root, acquisition and ledger refusals of the fold. The [mutation script](https://github.com/lambdasistemi/lockness/blob/c341bd9e77c0a7586826597429bcadb50da4d77e/lean/checks/app-mutations.sh) verifies that each edit to the production source applied, recompiles the dependent fixtures and simulator, executes the mutant's acceptance by evaluation, applies the refutation, and requires the unchanged proofs to fail on the trusted-root or accepted-root observation rather than on a setup error.

The [verdict tests](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/Lockness/Tests/Verdict.lean) restate every verdict guarantee in full, so a changed statement fails to compile, and evaluate the verdict and accept outcome of each of the seven offers. The [verdict mutation script](https://github.com/lambdasistemi/lockness/blob/6dfe20f49d7133019d0758fb2327e427b8a8d535/lean/checks/verdict-mutations.sh) applies each production edit once and proves it applied, recompiles the modules on the witness path, evaluates the mutant's changed verdict, applies the refutation where one exists, and requires each unchanged proof to fail inside that proof's own lines rather than at an import or setup step.

The [context tests](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/Lockness/Tests/Context.lean) restate every context definition and guarantee in full, including the restated `unbound_only_unverified`, and evaluate the verdict and accept outcome of each context offer, including the unverified no-verifier outcome out of context. The [context mutation script](https://github.com/lambdasistemi/lockness/blob/d9039c14e3105bdd512f9bb9d7e7c409f498de24/lean/checks/context-mutations.sh) removes the network guard, the scheme guard and the verdict's context branch from compiled copies of the production modules, and the message-binding premise from a copy of the soundness statement. Without the network guard, the compiled witness verifies the honest root for a terminal configured for another network and refutes the unchanged context soundness; the unchanged context soundness and wrong-network proofs fail inside their own lines, and the wrong-network-point scenario rejects the changed outcome. Without the scheme guard, the witness verifies a root under an unaccepted scheme and refutes the unchanged context soundness; the unchanged context soundness and unaccepted-scheme proofs fail, and the unaccepted-scheme scenario rejects the changed outcome. Without the verdict's context branch, an unbound offer at a selected point on another network is classified unverified; the unchanged never-unverified proof fails, and the wrong-network-point scenario rejects the changed outcome. Removing the message-binding premise changes the statement, not an executable: the binding-free witness refutes only the statement without the premise, it is first compiled against the unchanged statement and must fail there, and the unchanged context soundness proof fails once the premise is gone; no scenario can change, and the unbound-message scenario reproduces the endorsement on the real model.

Run `./lean/env lake env lean Lockness/Tests/Session.lean` or `./lean/env lake env lean Lockness/Counterexamples/SessionMutation.lean` for session checks and the [generic refutation](https://github.com/lambdasistemi/lockness/blob/feat/7-session-acquisition/lean/Lockness/Counterexamples/SessionMutation.lean). Run `./lean/env lake env lean Lockness/Counterexamples/SubsetMutation.lean` to inspect the constructive counterexample independently. Record `git rev-parse HEAD` alongside command output when assessing a candidate. CI invokes the same model and documentation commands; the source workflow alone is not evidence that remote CI has passed.

| Evidence layer | Limit |
| --- | --- |
| Design | Records the project trust boundary and open contracts |
| Model and simulator | Kernel-checked properties of this root, session, ledger, application, verdict and operating context model and concrete executable paths |
| Documentation checks | Presentation, speech freshness and strict site construction |
| Independent acceptance and remote CI | Require revision-bound review and actual successful workflow results |
| Component implementation, deployment and live chain | Not established by this model |

The Lean kernel remains part of the trust base. Observation soundness and honest-root correspondence are external assumptions. The executable guard and statement share the definition of a qualifying candidate; the mutation checks preserve that statement while altering execution, and do not independently prove specification fidelity. Concrete ledger witness construction, application proof formats and validators, effects, canonicality, freshness, settlement and abandoned-branch session policy remain later work. Ledger soundness additionally assumes honest commitment correspondence, witness and interpretation soundness, faithful representation and OneShot; application soundness adds `AppSound` and faithful nesting, invariance adds `AppFunctional`, and context soundness adds `MessageBinding`. No model proof establishes these for a deployed system, and no implementation of a terminal, builder or proof checker is evidenced by this model. Consume model and documentation by reviewed revision; a tagged binary distribution pipeline remains future implementation work.

Continue to [design decisions and remaining guarantees](../design/decisions.md) and the [project architecture](../architecture/system.md).
