# Lockness

As an application developer, let terminals consume anchored data before building transactions or driving real-world effects, without maintaining a chain follower for each application.

## Why terminals should consume anchored data

The value of Lockness is a checkable basis for action. A terminal receives data and proof from a provider, accepts a root under its independent anchor policy, and verifies the claim at a selected chainpoint before consuming the data. It can change data providers or delegate proof construction while retaining control over which evidence it accepts.

A wallet uses this evidence to check the state from which it constructs a transaction. An integration uses it to establish a ledger fact before applying its policy for a real-world effect. Both can share generic ledger infrastructure without inheriting the data server's authority.

The proof must establish the claim the action needs. A membership proof alone cannot establish query completeness, and a valid proof at an old chainpoint cannot establish freshness. Historical transactions may be untrusted material used to reconstruct state that is then checked against an anchored application root. Read [why data should travel with proofs](architecture/system.md#why-data-should-travel-with-proofs) for the boundary between evidence, trust and action.

## User stories

Lockness separates who provides data from who endorses ledger commitments. A client selects a commitment at a chainpoint, obtains a read session for that point, and verifies the evidence it uses. Application-specific proof construction can happen locally or at an optional service.

```mermaid
flowchart LR
    N[Validated chain feed] -->|Blocks and rollbacks| P[Independent anchor]
    N -->|Blocks and rollbacks| L[Lockness ledger]
    P -->|Signed root stream| C[Terminal trust policy]
    L -->|Pinned data and witnesses| V[Terminal verification]
    C -->|Accepted commitment| V
    L -->|Historical reconstruction data| A[Lockness application]
    A -->|Application proofs| V
```

## Current state

This is a design-stage project. The architecture direction is recorded; chainpoint behavior during rollback, authenticated history, proof formats and acceptance rules remain to be specified and tested. There is no production Lockness service or accepted formal model yet. No institution is claimed to operate a publisher.

Start with the [architecture](architecture/system.md), then the [chainpoint contract](design/chainpoints.md) and [delivery roadmap](roadmap.md).
