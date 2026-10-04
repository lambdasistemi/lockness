# Verify an application claim through nested roots

As a design reviewer, run `lake exe lockness-sim app <scenario>` and observe a terminal accept an application claim only after root acceptance, exact-point acquisition, ledger verification and every application link have been checked. An honest builder yields a verified claim; a builder that replaces the claimed root yields `evidenceFailure` at the selected point; a two-link chain is verified link by link and a failure at the second link rejects the whole claim. Two providers and two builders cannot make the terminal accept two different claims for the same policy, publications and selected point.

## Architectural contract

Providers and builders are arbitrary functions. The root bound by root acceptance is the only checking root for the ledger step; `Session.acceptedRoot`, `LedgerAnswer.root` and `AppAnswer.root` are untrusted data. Application proof soundness, application-tree functionality, nesting interpretation, honest-root correspondence, witness soundness and OneShot are separate explicit hypotheses. Every refusal carries the caller-selected chainpoint.

## Requirements

| Name | Required outcome |
| --- | --- |
| abstract-app-proof | Proof bytes are uninterpreted; `AppSound` connects a successful policy check under a root to membership of the query/value pair in that root's tree. |
| arbitrary-builder | `Builder := Root → Option AppAnswer` with no restriction. |
| claimed-root-first | `verifyApp` refuses a claimed root different from the trusted root before, and independently of, proof checking. |
| trusted-root-proof-check | The proof is checked under the trusted root and the policy query, never the answer's root or query fields. |
| link-binding | Every link checks the selected point and the same application, context and claim of the policy query. |
| fueled-nesting | `verifyChain` follows a value's further root while fuel remains; exhaustion with a root pending or an absent builder refuses the whole claim; no partial claim. |
| second-link-rejection | A failure at the second of two links rejects the whole claim with selected-point `evidenceFailure`. |
| whole-fold | `accept : Policy → List Publication → Chainpoint → Provider → Builder → Except Refusal Claim` composes acceptRoot, acquire, verifyLedger with the independently accepted root, and verifyChain. |
| selected-point-refusals | Every accept refusal is one of the three constructors carrying the selected point. |
| claim-soundness | Under the stated premises, an accepted claim is at the selected point, its ledger root is the honest root, and `holds` its semantic claim over the selected point's ledger. |
| provider-invariance | Under the soundness premises plus `AppFunctional`, two successful accepts with arbitrary providers and builders return equal claims. |
| nonvacuous-honest-witness | One finite fixture inhabits every premise together with successful one-link and two-link acceptance. |
| replaced-root-refutation | A proof valid under another root is refused by the real verifier; a compiled mutant trusting the claimed root accepts it and constructively refutes the unchanged soundness statement and the real simulator scenario. |
| session-root-refutation | A compiled fold mutant checking the ledger under `Session.acceptedRoot` accepts a substituted ledger answer and constructively refutes the unchanged soundness statement. |
| ambiguous-value-refutation | Without `AppFunctional`, two builders make accept return two different claims, constructively refuting the invariance statement with only that premise removed. |
| runnable-app-scenarios | `lockness-sim app honest`, `replaced-root`, `nested` and `ambiguous-value` run the real fold. |
| inherited-contract-preservation | Root, session and ledger sources and every inherited scenario output and check-stage outcome are unchanged; all-source axiom inventory and hole controls retained. |
| reviewable-delivery | Matching docs and speech, immutable source links, persistent independent checkpoint audit, final-head local checks, exact-head remote CI and preview precede readiness. |

## Evidence boundary

Proofs establish model properties under stated premises; simulator outcomes establish concrete model paths; documentation and CI have separate revision-bound receipts. Proof formats, wire encodings, transaction construction, redeemers, validators, CSMT, storage, settlement and deployment are outside this ticket.

## Shared-interface authority

Epic ruling app-interface-v1 releases the shared Types successor, the curried `verifyApp` deviation, the uniform-query modelling choice, the fourth scenario and the exact file fence.
