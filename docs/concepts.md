# Concepts behind a verified answer

As a reader following the MPFS or Singular example, identify what the terminal verifies at each step and follow the links to the component that supplies it.

## Standard vocabulary

| Term | Meaning |
| --- | --- |
| Anchor | The role that follows the chain and publishes independently computed, signed ledger roots |
| Ledger provider | The `lockness-ledgers` role that serves data and ledger proofs; distinct from the Cardano ledger |
| Application service | The `lockness-applications` role that interprets history and constructs application proofs |
| Terminal | The consuming role that chooses anchors, verifies evidence and authorizes actions |
| Ledger root | An application-independent commitment to the ledger quantities covered by its scheme at a chainpoint |
| Application root | A commitment to application state, authenticated through a ledger output or another verified application value |

“Commitment” describes the cryptographic construction; “root” names its result. “Ledger proof” is the standard term here; a witness is the evidence carried by that proof.

## Assets and NFT state outputs

A Cardano asset is identified by its minting policy and asset name. An NFT can identify a particular application's state output. In the Lockness integration described here, the terminal needs the exact unspent output carrying that NFT, including its datum. Finding an asset name alone does not authenticate the output or its state.

Using the NFT as a unique state identifier requires an application invariant: its minting policy limits this exact asset identity to one unit, and the state-transition rules preserve the authoritative state output. An inclusion proof establishes that the supplied output is present; it does not prove unique supply or authority. The terminal must know the expected policy, asset identity and state rules. If those rules permit multiple candidate outputs, the application contract must define and justify which is authoritative.

[MPFS and Singular](projects.md#application-consumers) give these outputs application-specific meaning. A [ledger proof](#ledger-and-application-proofs) binds the output to an accepted ledger root; the application decides how to interpret the datum. Follow the [worked verification sequence](architecture/system.md#proof-composition).

## Two roots with different scopes

The **ledger root** commits to the indexed ledger quantities at a [chainpoint](design/chainpoints.md#session-contract). An [anchor](architecture/system.md#components-and-chain-following) establishes that root from its chain view. The terminal accepts roots according to its [trust choice](design/trust-and-availability.md#two-attractive-trust-deals).

The **application root** commits to an application's own tree. In the NFT example it is contained in the state output's datum. The terminal first verifies that output against the ledger root, then uses the application root to check application evidence. The two roots are neither interchangeable nor endorsements of the same claim.

## Ledger and application proofs

A ledger proof establishes its stated claim about the indexed ledger at the selected chainpoint. Terminals consume it off-chain. An application proof establishes its application-specific claim against the application root; it may be included in a transaction redeemer for the application validator to check.

These are the project's [present-validity and future-validation proof values](architecture/system.md#proof-composition). Inclusion alone does not establish completeness of a result set or the freshness required for an action.

## Transaction CBOR, datums and redeemers

The [chain of application roots](#a-chain-of-application-roots) depends on exact datum interpretation as well as cryptographic checks.

Transaction CBOR preserves the transaction's encoded information. A datum describes application data associated with an output; a redeemer supplies data to script execution. Parsing the transaction envelope and interpreting its Plutus data are separate tasks.

The [ledger provider](architecture/system.md#service-boundary) retains transaction information and required references. Application libraries decide how those fields update application state. Historical transactions can be reconstruction inputs whose resulting tree is checked against an authenticated application root; they are not automatically proved historical claims.

## Chainpoints, views and sessions

A chainpoint identifies genesis or a slot and block-header hash. A view exposes state there; a session retains access to that view under a lease. Network is separate context. Read the [session contract and lifecycle](design/chainpoints.md) for retention, expiry and unresolved rollback behavior.

## A chain of application roots

A verified application value may carry a further application root. Each descendant claim requires its own proof and the expected interpretation of that root. The [architecture and root-chain diagram](architecture/system.md#proof-composition) define the verification order.

## Untrusted application services

`lockness-applications` services are untrusted for correctness, just like ledger providers. They can reconstruct trees and construct proofs on behalf of terminals. Terminals accept the result by checking the required claim against the authenticated application root, not by trusting the service's interpretation or its chosen root. The [trust boundary](architecture/system.md#data-and-trust-are-separate) and [delegation story](stories/index.md#delegate-proof-construction) describe what must be rejected.

## Follow the example

Start with the [MPFS/Singular project links](projects.md#application-consumers), then follow [proof composition](architecture/system.md#proof-composition). For the existing ledger engine and measurement starting point, use [CSMT-UTXO](projects.md#csmt-utxo-the-existing-engine). For a provider's delivery obligations, use [what applications buy](design/trust-and-availability.md#what-applications-buy).
