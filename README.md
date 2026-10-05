# Lockness

As an application developer, verify the data behind a transaction or real-world action without trusting the server that supplies it or running a chain follower for every application. A [**terminal**](docs/concepts.md#terminals-lightweight-web2-applications) is a lightweight Web2 application with cryptographic capabilities: it chooses a chainpoint according to the application's purpose and risk, retrieves untrusted data and independently accepted anchor evidence, verifies the assets, then lets the user build a blockchain transaction or consume the verified data off-chain.

**Web2 scaling with explicit trust management.** Applications buy data and computation; terminals choose their anchors and verify provider answers. Removing correctness trust from data provision lets providers compete on availability, capacity, speed and price.

**Status: project design with an executable root acceptance, session, ledger, application verification and verdict model.** Start at the [published design](https://lambdasistemi.github.io/lockness/) or the [evidence and open contracts](docs/design/decisions.md).

## User stories

- A terminal verifies an NFT state output before using its application root to check an application proof and build a transaction.
- A ledger provider serves data and proofs at a selected chainpoint, or explicitly refuses an unavailable view.
- An untrusted application service builds proofs using ledger history, without another chain follower.
- An anchor runs a node and publishes signed roots for every block, without hosting the ledger provider's archive or query capacity.
- A terminal labels data as unverified only for a declared absence: no verifier, a session declared unbound, or no witness on a session bound to its selected point. With a verifier configured, it refuses a session that declares a binding to another point. In every case it never presents unverified data as verified.

<!-- diagram: roles -->
<div class="diagram"><a href="docs/diagrams/roles.png?v=6037a7ad1f213151"><img src="docs/diagrams/roles.png?v=6037a7ad1f213151" alt="Anchors supply accepted roots; ledgers and application builders supply evidence to terminals." width="523" loading="lazy"></a></div>
<p class="diagram-links"><a href="docs/diagrams/roles.png?v=6037a7ad1f213151">Open full size</a> · <a href="docs/diagrams/roles.mmd?v=2cd71c9403daeccb">Mermaid source</a></p>

The [architecture](docs/architecture/system.md) owns proof composition and the trust boundary. Ledger proofs stay off-chain; application proofs can enter transaction redeemers.

## Choose trust and buy availability

Running your own anchor is the optimal deal for trust independence. Observing chosen institutional publications is an exceptionally attractive operational deal under explicit institutional trust. Both let applications buy ledger capacity while terminals verify the results. The [trust and availability model](docs/design/trust-and-availability.md) explains the assumptions and purchased service commitments.

## Read the design

- [Executable root acceptance, session, ledger, application and verdict scenarios](docs/model/index.md)
- [Concepts and standard vocabulary](docs/concepts.md)
- [Trust choices and availability](docs/design/trust-and-availability.md)
- [Architecture and proof composition](docs/architecture/system.md)
- [Chainpoint sessions](docs/design/chainpoints.md)
- [Existing projects: CSMT-UTXO, MPFS and Singular](docs/projects.md)
- [User stories](docs/stories/index.md), [open contracts](docs/design/decisions.md) and [delivery roadmap](docs/roadmap.md)

## Repository scope

This repository owns cross-project design and acceptance. Component implementations belong in their own repositories. CSMT-UTXO supplies existing commitment machinery; the proposed ledger provider needs substantial additional storage and query capabilities. See [reuse and remaining work](docs/projects.md#csmt-utxo-the-existing-engine).

## Check the documentation

Install Nix with flakes enabled, then run `./tools/check-docs.sh`. It checks presentation and speech companions and builds MkDocs in strict mode using the pinned shared documentation environment. `./tools/check-model.sh` checks the pinned Lean model, proofs, counterexamples and simulator scenarios. `just ci` runs both gates when Just is installed.

Diagrams use source-bound rendered assets. Run the documentation environment with `python3 tools/render_diagrams.py --render docs/diagrams/manifest.json` to regenerate them, then review every render and refresh the affected speech companions before running the gate. The checker verifies source, renderer, image and embed freshness; visual and semantic review remain necessary.

Run the [model scenarios](docs/model/index.md) with `./lean/env lake exe lockness-sim accept-root honest` or `untrusted-key`. Session journeys are `./lean/env lake exe lockness-sim session honest`, `absent-point` and `newer-point`: acquisition preserves the selected point, repeated reads retain it, and expiry or unavailable offers refuse at that point. Ledger journeys are `./lean/env lake exe lockness-sim ledger honest`, `substituted-root` and `duplicate-asset`: the verifier uses an independently accepted root and exact witnessed object bytes; provider-root substitution refuses, while two honest same-asset outputs expose the separate OneShot assumption. Application journeys are `./lean/env lake exe lockness-sim app honest`, `replaced-root`, `nested` and `ambiguous-value`: a claim is accepted only after every root it rests on is checked, a claimed root other than the trusted one is refused, a failure at a nested link rejects the whole claim, and two values for one query show why provider invariance needs a separate functional premise. Verdict journeys are `./lean/env lake exe lockness-sim verdict verified`, `no-witness`, `unbound-session`, `no-verifier`, `wrong-witness`, `misbound` and `promoted`: on the fixture, whose root acceptance succeeds, a bound session with a checked witness is verified with the same claim as acceptance; a missing witness, an unbound session or a missing verifier is unverified with that reason; with the verifier configured, a wrong witness or a binding to another point is refused at the selected point; and a witness-less impostor is never promoted to verified. Honest unique-output and datum-root soundness requires explicit commitment, witness, encoding, interpretation and OneShot premises. The finite ledger uses pinned Mathlib with transitive dependency revisions. Model checks establish properties of the model under explicit hypotheses. Documentation checks establish only that the design record builds. They do not establish the correctness or delivery of the proposed system.

## License

Apache License 2.0. See [LICENSE](LICENSE).
