# Lockness

As an application developer, check the data behind a transaction or off-chain use without trusting its server. A [**terminal**](concepts.md#terminals-lightweight-web2-applications) is a lightweight Web2 application with cryptographic capabilities. Its purpose and risk policy guide chainpoint selection; it retrieves untrusted data and anchor evidence for that point, verifies the assets, then lets the user build a blockchain transaction or consume the data off-chain.

## Web2 scaling with explicit trust management

Applications buy data and computation from competing providers. Terminals choose anchors that establish trusted ledger roots, then check provider answers against those roots. This separation makes data provision a computational business whose capacity can scale through ordinary servers, caches and replicas.

Running your own anchor is the optimal deal for trust independence; observing chosen institutional publications is an exceptionally attractive operational deal under explicit institutional trust. The [trust and availability model](design/trust-and-availability.md) owns these choices and the delivery commitments applications purchase.

## Find your path

- **Assess the proposition:** [trust choices and the availability market](design/trust-and-availability.md).
- **Build a terminal:** [the lightweight Web2 application](concepts.md#terminals-lightweight-web2-applications) → [proof composition](architecture/system.md#proof-composition) → [chainpoint sessions](design/chainpoints.md).
- **Explore existing work:** [CSMT-UTXO, MPFS and Singular](projects.md) → [evidence](design/decisions.md#evidence-available-today) → [delivery roadmap](roadmap.md).

## Why terminals should consume anchored data

**Anchored data** is data whose required claim the terminal has verified against an independently accepted root. Both ledger providers and application services remain untrusted for correctness.

A ledger proof can authenticate an NFT state output and its datum. That datum carries an application root used to verify application proofs, including links to further trees. Follow [proof composition](architecture/system.md#proof-composition) for the complete chain and [the verification boundary](architecture/system.md#why-data-should-travel-with-proofs) for the claims an action needs.

## User stories

Lockness separates who provides data from who endorses ledger commitments. A terminal finds a chainpoint with both an accepted root and an available provider view, acquires a session, and verifies the evidence it uses. Application-specific proof construction can happen locally or at an optional service.

<!-- diagram: overview -->
<div class="diagram"><a href="diagrams/overview.png?v=1bfbbb4803ee0708"><img src="diagrams/overview.png?v=1bfbbb4803ee0708" alt="Chosen roots and untrusted ledger and application services meet at terminal verification; both services remain outside the trust boundary." width="620" loading="lazy"></a></div>
<p class="diagram-links"><a href="diagrams/overview.png?v=1bfbbb4803ee0708">Open full size</a> · <a href="diagrams/overview.mmd?v=f245f91dd708b05b">Mermaid source</a></p>

## Current state

This is a design-stage project. The [decision record](design/decisions.md#claims-and-evidence-boundaries) states what exists, what is proposed and what remains unproved. The [roadmap](roadmap.md) turns those gaps into deliverables and acceptance criteria.
