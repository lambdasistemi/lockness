# Project stories

As a reader, judge Lockness by the operations it enables and the failures it exposes before judging an implementation choice.

## Verify before using ledger facts

A client accepts a commitment under its own publisher policy, selects its chainpoint and verifies an NFT output before reading the application root from its datum. Altered output bytes, a wrong root, wrong asset identity or wrong network must not become accepted facts. The exact validation contract still needs a model and executable evidence.

Changing the data provider must not change the accepted claim when the commitment and evidence agree. A provider's self-selected root must not substitute for the terminal's independently accepted anchor. A membership proof must not be accepted as evidence that a result set is complete. These are acceptance targets for the core value: terminals consume anchored data while retaining control over trust.

## Keep dependent reads coherent

A client reads several assets and pages through their outputs under one session. New blocks do not change the selected view. Unavailable or expired chainpoints produce explicit refusals. Fork handling is an open ruling rather than an assumed success path.

## Run an anchor and buy ledger capacity

An operator seeking maximum trust independence runs a node and anchor that compute the roots its terminals accept. It buys archive access, retained chainpoint views and proof generation from a provider without operating its own ledger service. The terminal rejects provider data that fails verification against the locally established root. Anchor validation and commitment maintenance remain the operator's responsibility.

## Observe institutional publications

An operator seeking low local infrastructure cost selects institutional publishers under an explicit trust policy. Its terminals verify signed publications and use the accepted roots to check provider answers. Unknown keys, wrong networks, incompatible schemes and publications that fail the chosen freshness policy must not become accepted roots. The exact acceptance policy remains to be specified; no institution is claimed to participate today.

## Buy availability and switch providers

An application operator buys defined coverage, retention, session leases, throughput, latency and uptime. A provider reports missing coverage, expiry or overload explicitly. The commercial commitment makes delivery observable; it does not change the terminal's verification requirements.

The terminal can acquire a session from another compatible provider at the same accepted chainpoint and verify the same claims without changing anchor policy. Session tokens are provider-local. If the replacement cannot serve that view, fallback reports unavailability instead of silently weakening the claim or selecting a newer chainpoint. Interoperability, refusal and switching are acceptance targets for market-driven scaling.

## Add an application without another chain follower

An application builder retrieves transactions and required historical inputs, interprets its protocol and reconstructs a tree. The client checks the result against the application root in the authenticated state output. Missing reconstruction data remains an explicit failure; a matching final state root is not proof of every historical event.

## Delegate proof construction

A client requests an application proof from a service and verifies it locally. It can instead construct the proof itself from checked state. Neither route changes which root is authoritative.

The application service is untrusted for correctness. Replacing the application root, proving a different NFT or application claim, returning an invalid proof, or omitting required evidence must not produce an accepted result. A verified parent datum or tree value may introduce another root; the terminal verifies every subsequent application proof in that chain before consuming its claim.

## Publish trust without serving queries

A publisher follows a trusted ledger feed, computes commitments and signs each block's publication. It need not retain historical query views. The client selects trusted keys; no named organization is assumed to participate.

## Act on verified facts

A terminal consumes roots, proofs and data, verifies the claims needed for its application and uses them to build a transaction or drive an external effect. For transaction construction, application proofs become redeemer data; ledger witnesses remain off-chain. Cardano and the application validators enforce the submitted transaction against actual ledger and application state. The terminal owns the policy that authorizes that action. Verification at a chainpoint alone does not promise the external action will succeed or remain appropriate indefinitely.

## Evidence status

All stories are proposed acceptance targets. No Lockness formal model, simulation, production conformance result or end-to-end delivery is claimed yet.
