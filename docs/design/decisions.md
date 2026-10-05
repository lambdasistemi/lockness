# Design direction and unresolved guarantees

As a contributor, distinguish the project's agreed direction from decisions still requiring a concrete contract and evidence.

## Recorded direction

The following direction was established in the project discussion on 3 October 2026. These are design inputs, not claims of implemented or formally verified behavior.

| Direction | Earlier alternative | Why it changed |
| --- | --- | --- |
| Work at project level in Lockness | Extend one repository's asset endpoint in isolation | Trust publication, retained views and terminal verification cross component boundaries. |
| Terminals are lightweight Web2 applications with cryptographic capabilities | Require application adoption to include operating chain infrastructure | Purpose and risk guide verification policy; the user can build transactions or consume verified data off-chain. |
| Terminals consume anchored data before acting | Accept the data provider's answer as authoritative | Verification connects the answer to an independently accepted root; data providers and proof builders remain replaceable. |
| Own anchor is the optimal deal for trust independence | Equate independent verification with running every data service locally | Keep local root establishment while outsourcing ledger capacity. |
| Institutional publications are a first-class operational offer | Require each terminal operator to maintain an anchor | Obtain roots at low local operating cost under explicit institutional trust. |
| Applications purchase provider availability | Bundle correctness authority with purchased data capacity | Price delivery while terminals verify claims independently. |
| Require provider interoperability and switching evidence | Claim an optimal market from the architecture alone | Market-driven scaling needs practical substitution and measurable service commitments. |
| Anchors emit signed commitments for every block | Anchors choose and retain terminal query sessions | Publication and data-serving availability are independent responsibilities. |
| Terminals use a selected published chainpoint | Terminals ask anchors to coordinate each query | Signed streams supply commitments independently of data retrieval. |
| Chainpoint-bound proof-bearing API | Duplicate Koios response shapes as the governing contract | Query compatibility alone does not establish coherent multi-query reads. |
| Serve complete transaction CBOR as reconstruction material | Define a smaller application-neutral transaction projection now | Sufficiency is application dependent; preserving information precedes optimization. |
| Optional application proof services | Either trust an application backend or do everything locally | Proof construction can be delegated and checked locally. |

<!-- diagram: decisions -->
<div class="diagram"><a href="../diagrams/decisions.png?v=36575202590b3327"><img src="../diagrams/decisions.png?v=36575202590b3327" alt="Design inputs lead through model and review to implementation; later stages remain uncompleted." width="276" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/decisions.png?v=36575202590b3327">Open full size</a> · <a href="../diagrams/decisions.mmd?v=ff6e120929c51800">Mermaid source</a></p>

## Named deployment roles

The project names the roles `lockness-anchors` and `lockness-ledgers`, plural because any number of instances is expected. Anchors run nodes and serve signed roots. Ledgers run nodes and serve data and proofs. The `lockness-applications` role serves application proofs using retrieved ledger history. The `lockness-terminals` role consumes roots, proofs and data, verifies them, and builds transactions or drives real-world effects from verified facts. These are component boundaries, not a command to create separate repositories now.

## Words that constrain the design

Project rulings, paraphrased for readability:

- Separate immutable, hash-addressed content from chainpoint indexes.
- Anchors publish a signed root for every block independently of query sessions.
- The API is governed by chainpoint coherence and evidence sufficient for verification, rather than Koios response compatibility.

The later discussion refined the last statement: historical transactions can be untrusted reconstruction material, while claims used as authoritative ledger or application facts need verification. The precise endpoint claim inventory is still open.

Ledger and application proofs have distinct destinations: ledger witnesses are verified off-chain by terminals and are not carried into transactions. Application proofs are carried in redeemers and checked by application validators. Cardano enforces transaction validity against its own ledger state. This distinction does not stop anchors publishing signed roots.

The temporal distinction is an explicit project ruling:

> "the ledger proofs are about on-chain validity (present), application proofs are about on-chain validation (future)"

Here the present is the selected chainpoint. For the UTxO commitment, the proof establishes output membership under the accepted root, not an independent execution of transaction-validity rules. An application proof is intended for checking a proposed transition on-chain; its availability is not a promise of future transaction acceptance.

## The verdict layer

The terminal classifies each outcome as verified, refused or unverified. The verdict is the terminal's own classification around acceptance, never a wire object, and it carries no payload of its own. Verified carries exactly the claim acceptance returned. Refused carries acceptance's own refusal at the selected point. Unverified carries only a reason.

The weakest and the strongest deployments are instances of the same types. At the weakest end, an unbound provider offers data without witnesses, and the terminal labels everything it receives unverified. At the strongest end, a session bound to the selected point offers witnesses that the terminal checks against independently accepted anchors, and only then is a claim verified. Nothing in between needs a different interface: the provider declares its binding and whether it offers a witness, and the policy declares whether the terminal has a verifier.

Unverified arises only from a declared absence: no verifier configured, a session declared unbound, or a session bound to the selected point without a witness. With a verifier configured, anything present and wrong is refused, including a witness that fails under the accepted root and a session declaring a binding to a point other than the one it offers. Otherwise a provider could turn a refusal into a softer outcome by misdeclaring. An answer without a witness is never promoted to verified; the model proves this for every policy, provider and builder, and a compiled mutant that lets an absent witness pass refutes it.

| Decision | Alternative | Why |
| --- | --- | --- |
| Classify around the unchanged acceptance | Change acceptance's result or put the verdict on the wire | Acceptance and its guarantees stay intact; providers make offers, terminals judge them |
| Unverified only for a declared absence | Treat every evidence failure as unverified | A misdeclared binding or a wrong witness must not soften a refusal |
| Reconstruction material is its own type, carried and never evidence | Reuse witness bytes or check reconstruction | It cannot be confused with evidence, and replacing it never changes a verdict |

The action step and its action policy belong to issue #10, which consumes the verdict. The wire encoding of the binding, the witness and the reconstruction belongs to issue #17. The [verdict model page](../model/index.md#classify-verdicts) lists the guarantees, the seven scenarios and the named limits.

## The operating context

A terminal runs in one declared operating context: a network identifier and the commitment schemes it accepts, each scheme identifier carrying its version. The context is the terminal's policy, not something the provider declares, and the terminal's trusted keys are trusted only inside it. A selected point on another network, or a root under a scheme the context does not accept, is present and wrong evidence, so the terminal refuses it at the selected point and never reports it as unverified. A publication from another network is ignored, never a veto: it cannot endorse a point on this network, and because the publication list is untrusted input it must not be able to block a selection either. That a signed message encodes its publication's point and root is a hypothesis, exactly as signature validity is; the concrete message encoding, and with it the encoding of network identifiers, belongs to issue #17.

| Decision | Alternative | Why |
| --- | --- | --- |
| One context per terminal policy, scoping its trusted keys | Let the provider declare the network, or keep trust independent of the network | The terminal decides what it trusts; a provider's declaration is untrusted data |
| Out of context is refused, never unverified | Report a mismatch as unverified | The evidence is present and wrong; a softer outcome would let a provider downgrade a refusal |
| A foreign publication is ignored | Refuse the whole selection when any fetched publication is on another network | One junk entry in an untrusted list would otherwise refuse every selection, and one key may honestly publish on two networks |
| Message binding is an assumed hypothesis | Compute it from a concrete message format now | The wire encoding is not yet agreed; the model states exactly what it needs from it |

The model covers network and scheme membership only. It does not cover genesis or era identity; concrete network identifiers belong to issue #17. It does not model protocol parameters: their use in transaction construction belongs to issue #10 and every other use to the implementation milestones. Validator script hashes belong to the implementation milestones. With no verifier configured an out-of-context selection is unverified with reason no verifier, and issue #10's action policy decides what such a fact may do. The [operating context model section](../model/index.md#bind-the-operating-context) lists the guarantees, the five scenarios and the named limits.

## Claims and evidence boundaries

| Design claim | Evidence boundary |
| --- | --- |
| Terminals verify data against independently accepted ledger roots | Executable [root acceptance, session, ledger, application verification, verdict and operating context model](../model/index.md) with explicit verification and correspondence hypotheses; no full-system verifier or end-to-end deployment |
| Terminals accept application claims only through checked nested roots | The model proves claim soundness for the whole fold under honest-root correspondence, the ledger premises, application proof soundness and faithful nesting, and provider invariance under the same root, ledger and application proof premises plus functional application content; without functional content two builders can yield different accepted claims; no proof format, validator or implemented terminal |
| Terminals act only inside their declared operating context | The model proves that every accepted or verified claim is on the context network under an accepted scheme, that a mismatch is refused and never unverified with a verifier configured, and that appended foreign publications change nothing; context soundness assumes message binding; compiled mutants without the network guard or the scheme guard verify an out-of-context claim and refute the unchanged context soundness; one without the verdict's context branch reports an out-of-context unbound offer as unverified and breaks the never-unverified proof; removing the binding premise yields a statement that is false on the real verdict, while the unchanged statement rejects that counterexample, and no executable changes; no concrete network identifier, message encoding or implemented terminal |
| Terminals never present unverified data as verified | The model proves no promotion without hypotheses and soundness and provider invariance of verified claims under the acceptance premises; a compiled absent-witness mutant refutes both; no implemented terminal, verifier or witness format |
| Own anchors preserve trust independence; institutional publications reduce local infrastructure | These are trust and operating choices, not measured price rankings; no institution is claimed to participate today |
| Providers compete on computation and availability | No interoperable provider market or globally optimal pricing demonstrated |
| CSMT-UTXO supplies existing commitment machinery | Retained views, history coverage, leases and publication contracts require additional work; see [existing projects](../projects.md) |
| Ledger proofs authenticate their stated claims at a chainpoint | The ledger model proves unique-output/datum-root soundness under separate honest-root, witness, encoding, asset/datum and OneShot premises; membership alone does not establish uniqueness, completeness, canonicality or settlement |
| Application services can reconstruct state and build proofs | Transaction-CBOR replay and dependency coverage still need application-specific evidence |

## What remains unproved

- Anchor operating cost and the additional cost of ledger archives, retained views and proof-serving capacity need separate measurements.
- Provider switching, evidence interoperability and observable availability commitments need concrete contracts and acceptance evidence; market efficiency is a design thesis.
- The full commitment inventory: live UTxOs, asset sets and any historical indexes need separately stated proof guarantees.
- Completeness and absence require explicit proof contracts; inclusion proofs alone do not establish a full result set.
- [Archive coverage](chainpoints.md#history-coverage-before-costing) must be selected before cost commitments; referenced-output retrieval must cover every dependency of a real application replay.
- The root model makes trusted-key membership and agreement explicit. Concrete anchor policy selection, key rotation, signed message encodings, freshness and rollback notices remain unspecified.
- Active-session behavior on fork abandonment and bounded retention remain unresolved.
- The ledger model binds the asset and exact witnessed-output datum to a selected-point accepted root under explicit assumptions. The application model binds the application, context, claim, point and nested roots abstractly; concrete proof formats, application replay and transition bindings still need their own contracts.
- Every application link is checked against one fixed query, and a session carries one ledger answer. Per-link queries are reviewed in issue #11; several ledger queries per session belong to later wire contracts.
- The invariance statement with the functional-content premise removed is copied by hand for its counterexample; its faithfulness is reviewed in issue #11.
- The verdict carries no payload, and acting on verified or unverified data is issue #10's action step and policy. A witness offered on an unbound session is never checked, and a terminal without a verifier reports unverified even when nothing is offered. The verified soundness and invariance statements are hand copies of the acceptance statements, reviewed in issue #11.
- External effects require an explicit settlement policy and evidence of continued ancestry; signatures or same-point anchor agreement alone do not establish settlement.

## Evidence available today

The [root acceptance, session, ledger, application verification, verdict and operating context model and simulator](../model/index.md) compile with a pinned Lean toolchain. Their proofs establish nonempty distinct trusted endorsement, exact point/root binding and selected-point refusal. Signature validity requires an explicit observation-soundness hypothesis; honest-ledger-root equality separately requires correspondence. Compiled counterexamples show untrusted-key refusal and failure of the general safety theorem after removing trusted-set checking. Session acquisition separately proves full-point no substitution for arbitrary providers and preserves the offered session unchanged; lifecycle scenarios show repeated reads, expiry refusal and release. A compiled production substitution mutation accepts a newer session and refutes the unchanged guarantee. Root trust is not established by acquisition. The ledger verifier checks the witness against the independently accepted root argument and binds the original object bytes to every asset and datum observation. Its universal proof identifies an honest member, actual asset, honest datum root and unique asset-bearing pair under separate selected-point correspondence, witness, encoding, interpretation and OneShot premises. Nontrivial honest fixtures inhabit all premises and acceptance together. A compiled provider-root substitution accepts an impostor and constructively refutes the unchanged guarantee; a two-member same-asset ledger refutes the complete unique-output guarantee when only OneShot is removed. All three ledger scenarios run through the real verifier. The application fold accepts a claim only after root acceptance, acquisition, ledger verification under the accepted root and every nested application link; the claimed root is compared before the proof is checked under the trusted root. Under honest-root correspondence, the ledger premises, application proof soundness and faithful nesting, its proofs show an accepted claim holds over the selected point's ledger; under the same root, ledger and application proof premises plus functional content, two providers and two builders cannot yield different claims. Compiled mutants that trust the claimed root or the session's root refute the unchanged soundness statement, and two values for one query refute invariance without the functional premise. The verdict layer classifies every outcome as verified, refused or unverified around that fold: a verified verdict requires a configured verifier, a session bound to the selected point, a present witness and acceptance's own claim, proved without hypotheses; unverified arises only from a declared absence; with a verifier configured, wrong evidence and misdeclared bindings are refused. A compiled mutant that lets an absent witness pass promotes an impostor and refutes the unchanged no-promotion and verified-soundness statements, and three further mutants each break an unchanged proof and a scenario. All seven verdict scenarios run through the real verdict and acceptance. The operating context guard refuses, at the selected point, a selected point on another network and a selected root under an unaccepted scheme, before acquisition and never as unverified with a verifier configured; appended publications from another network change nothing, and under observation soundness and message binding every verified claim is in context. Compiled mutants without the network guard or the scheme guard verify an out-of-context claim and refute the unchanged context soundness; a mutant without the verdict's context branch reports an out-of-context unbound offer as unverified and breaks the unchanged never-unverified proof. Removing the message-binding premise changes no executable: the statement without it is false on the real verdict, the unchanged statement rejects that counterexample, and its unchanged proof fails once the premise is gone. All five context scenarios run through the real verdict and acceptance. Branch abandonment and lease/retention policy remain open. This is model evidence; independent acceptance, remote CI, implementation and deployment need their own revision-bound results.

[MPFS's facts verifier](https://github.com/lambdasistemi/cardano-mpfs-offchain/blob/0f82465f5f828c2ab987a166e9e24c2368228d01/cardano-mpfs-verify/lib/Cardano/MPFS/Client/Verify/Read.hs) already anchors a state output and checks the root reconstructed from returned facts. It is useful prior implementation, not evidence that the proposed transaction-retrieval architecture is delivered.

The inspected [Koios asset query](https://github.com/cardano-community/koios-artifacts/blob/2e2eb57933e1e2528de5ca36ee961759841cf389/files/grest/rpc/assets/asset_utxos.sql) and [Blockfrost API](https://github.com/blockfrost/openapi/blob/05c6d61311f2d4d5c701d029ba702be86d36da69/openapi.json) do not expose the required shared chainpoint session contract for the relevant UTxO queries. This is a finding about those published interfaces, not their internal database capabilities.

[CSMT root-signing work](https://github.com/lambdasistemi/cardano-utxo-csmt/pull/231) is related work. Its existence does not establish an accepted anchor publication protocol.
