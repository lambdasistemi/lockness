# Delivery roadmap

As a project maintainer, build shared chain-following capabilities and demonstrate one complete application journey before widening the service surface.

## Delivery dependencies

Define the contracts and acceptance journey first, assign the components and measurement prototypes needed to satisfy them, then run the journey against those implementations. The journey is the acceptance gate for delivery.

<!-- diagram: roadmap -->
<div class="diagram"><a href="diagrams/roadmap.png?v=372061a0db52dc61"><img src="diagrams/roadmap.png?v=372061a0db52dc61" alt="Contracts define the journey before component and prototype assignment. Measured implementations then pass the journey before service expansion and independent interoperability testing." width="647" loading="lazy"></a></div>
<p class="diagram-links"><a href="diagrams/roadmap.png?v=372061a0db52dc61">Open full size</a> · <a href="diagrams/roadmap.mmd?v=542604030d6e947d">Mermaid source</a></p>

The three contract workstreams can proceed together. Their specifications, executable Lean model, proofs and simulation belong in this repository; component code belongs in the implementation repositories selected at assignment. The existing engine can supply an early anchor baseline. Ledger-provider measurements require a new archive and retained-view prototype.

| Workstream | Concrete deliverable | Ready to advance when |
| --- | --- | --- |
| [Roots and proof composition](#specify-roots-reconstruction-and-settlement) | Root scopes, proof encodings, NFT state authority, nested roots, reconstruction coverage, publication rollback and effect settlement contracts | Every required claim, history dependency and root-acceptance decision has a specified success and refusal case |
| [Chainpoint sessions](#settle-the-chainpoint-contract) | Discovery, acquisition, reads, leases, retention and abandoned-branch behavior, with an executable session model | Model statements are reviewed and cryptographic assumptions explicit. Counterexamples and a playable simulation show success and refusal |
| [Availability and substitution](#specify-the-trust-and-availability-offers) | Observable service dimensions, coverage reporting and a provider-switching contract | Switching preserves anchor policy, chainpoint and claim strength; availability failures are observable |

Availability defines what to measure. Measured costs then constrain advertised retention, lease and capacity limits; concrete commercial offers follow those results.

## Specify roots, reconstruction and settlement

The roots workstream owns the claim inventory: ledger and application root scopes, exact encodings, NFT unique-state assumptions and nested-root interpretation. It also owns the application-reconstruction requirement that determines [history coverage](design/chainpoints.md#history-coverage-before-costing). Select full-chain or generic filtered coverage, with starting chainpoint, backfill and the required reference dependencies, before sizing the archive. The sessions workstream makes that coverage available coherently; it does not silently decide what history an application needs.

Specify per-block publication, branch correction and how a terminal recognizes that a previously accepted chainpoint was abandoned. Define the evidence needed to establish continued ancestry and an explicit [settlement condition for irreversible effects](architecture/system.md#external-effects-and-settlement). Several anchors agreeing at one point does not supply settlement.

Exit evidence: a reviewed claim and coverage contract, application replay cases covering all required inputs, and explicit acceptance, deferral and refusal rules for root publication and effects. Archive sufficiency must subsequently be demonstrated by replay in the prototype and complete journey.

## Settle the chainpoint contract

Create a small executable Lean model, review its statements, and use proofs and a playable simulation to expose conflicting guarantees. Model discovery, acquisition, reads, expiry, eviction and abandoned branches. Cryptography remains an explicit assumption, outside the session model's proof claim.

Separate **behavior** from **limits**. The model specifies refusal, lease obligations, bounded retention and no silent chainpoint substitution for declared parameters. Measurement selects viable window sizes, lease durations and concurrency limits; a model cannot determine operating capacity.

Exit evidence: reviewed statements and counterexamples showing the promised behavior, including discovery/acquisition races, rollback and expired views. Sessions bind the coverage contract from the roots workstream to one network and chainpoint.

## Specify the trust and availability offers

Describe own-anchor operation for maximum trust independence and chosen institutional publications for low local infrastructure under explicit institutional trust. Root acceptance and purchased data delivery remain separate. The [evidence record](design/decisions.md#claims-and-evidence-boundaries) owns current participation and implementation claims.

Turn the [availability dimensions](design/trust-and-availability.md#what-applications-buy) into observable contracts: compatible evidence, provider-local sessions, discoverable views, missing coverage and switching without changing anchor policy. Discovery of a usable view is required; marketplace discovery, billing and remedies are integration choices. No on-chain marketplace is needed.

Exit evidence: root-acceptance and data-delivery contracts for both trust choices, with both ledger providers and application services explicitly untrusted for correctness. Define measurement methods now; set numerical service offers from the prototype results.

<a id="demonstrate-one-complete-journey"></a>

## Define the acceptance journey

Specify this journey before assigning implementation. Use one NFT, a selected chainpoint and independently configured test anchor keys. The terminal must authenticate the NFT output, obtain complete reconstruction inputs, match the reconstructed application root and verify an application proof before constructing a transaction. Include a nested application root with every link checked.

<!-- diagram: roadmap-journey -->
<div class="diagram"><a href="diagrams/roadmap-journey.png?v=e7d7917fc7c4b93f"><img src="diagrams/roadmap-journey.png?v=e7d7917fc7c4b93f" alt="The terminal verifies claims from two provider instances and an untrusted application builder. Transaction construction and external effects have separate policies; effects require settlement and authorization." width="770" loading="lazy"></a></div>
<p class="diagram-links"><a href="diagrams/roadmap-journey.png?v=e7d7917fc7c4b93f">Open full size</a> · <a href="diagrams/roadmap-journey.mmd?v=d90ef91725ec5551">Mermaid source</a></p>

The first run uses **two separately operated instances of one ledger-provider implementation**. This tests provider-local sessions, switching, equivalent claims and refusals. It does not establish interoperability between independent implementations. That later claim requires a second implementation passing the same claim and encoding contract.

Define cases for chain advance, unavailable views, expired sessions, missing history, altered data, wrong roots, wrong NFT identity and provider root substitution. Define an effect case in which a verified chainpoint is abandoned before its settlement condition is met: the terminal must defer or refuse the effect. A verified fact alone must never bypass that policy. Residual rollback after an effect was authorized remains a risk governed by the declared settlement assumptions and application recovery policy.

Exit evidence: a runnable acceptance specification with expected outcomes and required observations, including own-anchor and test institutional policies. This definition does not claim a completed run.

## Assign implementation work

Reconcile the [internal-index epic](https://github.com/lambdasistemi/cardano-utxo-csmt/issues/240) and [HTTP epic](https://github.com/lambdasistemi/cardano-utxo-csmt/issues/246) with the agreed contracts and acceptance specification. These are the canonical references to the earlier CSMT work, including their linked milestones. Updating this roadmap does not change their status.

Assign an owning implementation repository and deliverables for each role, including an explicitly scoped ledger archive/view prototype for measurement. The prototype needs working retention, reference retrieval and session operations. Treat it as experimental evidence, not a production service; decide whether to retain or replace it after measurement.

| Role | Work to assign | Acceptance boundary |
| --- | --- | --- |
| Anchors | Independent commitment computation and signed publication, including branch corrections | Network, chainpoint, scheme and root bindings match terminal policy |
| Ledger providers | Archive/view prototype, then retained views, references, indexes, sessions and proofs | Coverage and session behavior satisfy the contract at measured limits |
| Applications | Deterministic replay and proof construction | Reconstructed state and proofs match the authenticated application root |
| Terminals | Root policy, discovery, verification, switching and effect settlement | Required evidence and action conditions are checked before use |

Exit evidence: assigned repositories and issues for component delivery and the prototype, traceable to the acceptance cases. Existing CSMT epics are explicitly reconciled before implementation starts.

## Measure the ledger engine

Produce two distinct bodies of evidence. **Existing-engine baseline:** benchmark [CSMT-UTXO](projects.md#csmt-utxo-the-existing-engine) ingestion, current commitment maintenance and storage growth, including the node's costs. Existing insertion and deserialization benchmarks are starting points; KV-only baselines must remain distinguishable from commitment maintenance.

**Ledger-provider prototype and benchmark:** first implement the assigned archive and retained-view prototype under the chosen coverage contract. Demonstrate reconstruction-input sufficiency, then measure history/reference retrieval, chainpoint acquisition, concurrent sessions, query/proof latency, storage growth and recovery behavior. These are new prototype capabilities, not existing-engine benchmark switches.

Exit evidence: working prototype source and reproducible measurements bound to revision, hardware, network or replay input, initial state size, coverage and query load. Use results to select the production storage mechanism and numerical retention, lease and capacity limits. Recheck model assumptions if the proposed limits change behavior. Cost results alone do not establish a completed anchor publication service or negligible anchor costs.

## Pass the acceptance journey

Run the previously defined journey once the assigned anchor, ledger-provider, application and terminal implementations exist. Switch between the two provider instances at the same network and chainpoint, acquiring new provider-local sessions without changing root policy. Check equivalent claims; proof bytes need not be identical.

Exercise every refusal and substitution case, the nested-root case, and the abandoned-chainpoint effect case. Repeat with locally established roots and a test institutional policy; identify test anchors as such. Bind observations to component revisions and distinguish simulated effect authorization from an actual external action.

Exit evidence: the terminal accepts valid claims and rejects invalid evidence, refuses missing coverage and incompatible views, and defers or refuses the effect when settlement fails. Report locally verified transaction construction separately from actual Cardano validation. Successful switching closes the two-instance target; independent-implementation interoperability remains a later acceptance target.

## Delivery status

Lockness-specific implementation has not started. Existing CSMT-UTXO and MPFS code provides the [starting evidence](projects.md). No product release pipeline is defined until a releasable artifact and its owning repository are selected.
