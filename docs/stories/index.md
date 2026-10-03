# Project stories

As a reader, judge Lockness by the operations it enables and the failures it exposes before judging an implementation choice.

## Verify before using ledger facts

A client accepts a commitment under its own publisher policy, selects its chain point and verifies an NFT output before reading the application root from its datum. Altered output bytes, a wrong root, wrong asset identity or wrong network must not become accepted facts. The exact validation contract still needs a model and executable evidence.

## Keep dependent reads coherent

A client reads several assets and pages through their outputs under one session. New blocks do not change the selected view. Unavailable or expired checkpoints produce explicit refusals. Fork handling is an open ruling rather than an assumed success path.

## Add an application without another chain follower

An application builder retrieves transactions and required historical inputs, interprets its protocol and reconstructs a tree. The client checks the result against the application root in the authenticated state output. Missing reconstruction data remains an explicit failure; a matching final state root is not proof of every historical event.

## Delegate proof construction

A client requests an application proof from a service and verifies it locally. It can instead construct the proof itself from checked state. Neither route changes which root is authoritative.

## Publish trust without serving queries

A publisher follows a trusted ledger feed, computes commitments and signs each block's publication. It need not retain historical query views. The client selects trusted keys; no named organization is assumed to participate.

## Act on verified facts

A terminal consumes roots, proofs and data, verifies the claims needed for its application and uses them to build a transaction or drive an external effect. For transaction construction, application proofs become redeemer data; ledger witnesses remain off-chain. Cardano and the application validators enforce the submitted transaction against actual ledger and application state. The terminal owns the policy that authorizes that action. Verification at a checkpoint alone does not promise the external action will succeed or remain appropriate indefinitely.

## Evidence status

All stories are proposed acceptance targets. No Lockness formal model, simulation, production conformance result or end-to-end delivery is claimed yet.
