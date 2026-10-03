# Trust choices and the availability market

As an application operator, choose where your terminals obtain trusted roots and buy the data capacity your users need. Increase or replace that capacity without changing the evidence your terminals accept.

## The project proposition

**Web2 scaling with explicit trust management.** Proofs connect provider answers to roots accepted independently of those providers. This lets data provision become a computational business: providers sell storage, indexing, reconstruction, proof generation and delivery capacity. Applications buy availability; terminals verify the claims behind their actions.

The economic thesis is that interchangeable, verifiable providers enable efficient market-driven scaling. Cloud capacity, caches and replicas can serve demand under the same verification contract. The project must demonstrate interoperability and practical switching before claiming that outcome; it has no evidence of globally optimal pricing or scaling.

## Two attractive trust deals

**Running your own anchor is the optimal deal for trust independence.** Your node validates the chain and your anchor establishes the roots your terminals accept. You can buy all required ledger queries and proofs from outside providers. You retain the chain-validation, software and cryptographic assumptions of your own infrastructure, without adding a provider's assertion as the authority for an answer.

An anchor is still real infrastructure; [CSMT-UTXO is the existing engine and measurement starting point](../projects.md#csmt-utxo-the-existing-engine). It follows the chain, maintains the state needed to compute current commitments and handles rollback. Outsourcing ledger services removes the need to operate their archive, retained query views and query-serving capacity; it does not eliminate the anchor's own computational cost.

**Observing institutional root publications is an exceptionally attractive operational deal.** Institutions operate anchors and publish signed roots for every block. Terminals verify publications from institutions selected by their policy and consume provider data against those commitments. This avoids operating an anchor locally while making institutional trust explicit. No institution is claimed to participate today.

| Choice | Who establishes the accepted roots | Local operational burden | Trust decision |
| --- | --- | --- | --- |
| Run your own anchor | Your independently operated node and anchor | Chain following, validation and commitment maintenance | Retain your own source of ledger assurance |
| Observe institutional publications | Institutions whose endorsements your terminal accepts | Publication monitoring and signature/proof verification | Accept the selected institutions under an explicit policy |

Both choices use the same independent data-provider boundary. Institutional publication is a first-class deployment choice, not a promise of identical trust assumptions to running your own anchor. Which institutions, agreement rules and freshness conditions to accept remains terminal policy.

<!-- diagram: market -->
<div class="diagram"><a href="../diagrams/market.png?v=76008422a68e2c0b"><img src="../diagrams/market.png?v=76008422a68e2c0b" alt="Trust selection and the availability agreement are separate; accepted roots and purchased evidence meet at terminal verification." width="653" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/market.png?v=76008422a68e2c0b">Open full size</a> · <a href="../diagrams/market.mmd?v=a1789611aa6e614a">Mermaid source</a></p>

## What applications buy

An application operator is the buyer of service capacity. It may run or use a `lockness-applications` proof builder; that component role does not prescribe who signs a commercial agreement. Ledger providers sell generic data and ledger proofs. Application providers can separately sell interpretation, reconstruction and application proofs.

Availability is a provider's service commitment to the application. Cryptographic evidence lets the terminal check delivered claims against accepted roots; commercial terms govern whether and when the provider delivers. A proof cannot make an unavailable provider answer.

| Commitment | What the agreement must make observable |
| --- | --- |
| Data and history coverage | Supported networks, query families, transaction history and referenced-input coverage; explicit missing-coverage responses |
| Chainpoint retention | Which views are offered, how availability is discovered, and the retention window |
| Session lease | How long a pinned view is retained and which expiry or branch-abandonment outcomes apply |
| Capacity and latency | Request/proof limits, concurrency, response-time targets and overload behavior |
| Uptime and recovery | Availability measurement, outage reporting and recovery expectations |
| Price and accounting | Billable operations or resources, quotas and the agreed treatment of failed requests |

These are contract dimensions, not fixed tariffs or implemented guarantees. Rollback behavior must be settled in the [chainpoint contract](chainpoints.md) before an availability offer can promise it. Discovery, billing, measurement and remedies for missed commitments remain open design choices. The architecture does not require them to be enforced on-chain.

## Switching must preserve verification

A terminal moving from one provider to another keeps its accepted network, chainpoint, commitment scheme and required claims. It acquires a new provider-local session for that chainpoint; session tokens need not be portable. Compatible proof formats and unambiguous claim bindings make the evidence independently checkable.

If the second provider lacks that view or the required history, it reports the limitation. Fallback must not silently choose a new chainpoint, root authority or weaker proof contract. Selecting another chainpoint requires an explicit terminal decision. Caches and replicas inherit the same bindings and freshness requirements.

The acceptance journey must show two providers serving the same accepted claims, a successful switch without changing anchor policy, and a refusal when compatible coverage is absent. It must also show rejection of altered data and a provider attempting to substitute its own root. Equivalent claims need not have byte-identical proofs.

## Design decisions

| Chosen direction | Alternative | Reason |
| --- | --- | --- |
| Separate trust choice from purchased data capacity | Couple every provider change to a new trust authority | Let the application change capacity while preserving terminal policy |
| Own anchor for maximum trust independence; institutional publications as a first-class operational offer | Require everyone to run all infrastructure locally | Permit extensive offloading with an explicit choice of root authority |
| Price observable availability commitments | Treat valid proofs as an uptime guarantee | Correctness of delivered evidence and delivery obligations have different foundations |
| Make interoperability and switching acceptance requirements | Assume competition follows from publishing an API | A usable provider market depends on practical substitution |

## Evidence and next step

This page records the project proposition and design requirements. No availability contract, provider market, cost advantage or interoperable deployment has been demonstrated. Next, specify the service and proof contracts, measure anchor and ledger costs separately, and exercise the switching journey described here.
