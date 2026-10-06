# Completeness proofs as a proof kind

As a design reviewer, run `lake exe lockness-sim completeness <scenario>` and observe:
- an accepted all-entries claim for an address prefix, equal to the honest entries under that prefix at the selected point;
- the unique state output proved by an asset-prefix completeness listing of one entry, with no `OneShot` premise; a terminal that requires completeness refusing an answer without one, and the `OneShot` path still verified for a terminal that does not;
- `evidenceFailure` at the selected point when a provider omits an entry or adds one;
- the empty prefix: the zero-length prefix lists the whole ledger, an absent prefix with an explicit empty listing is accepted, and an empty listing for a populated prefix is refused;
- the real model accepting an omitted entry once the completeness check is unsound, and compiled mutants reproducing each counterexample.

## Architectural contract

A completeness answer (key prefix, listed object bytes, proof bytes) travels in the ledger answer the provider offers at the selected point. It is checked only under the root bound by root acceptance, never a provider root, and only for the prefix the terminal asked, never the answer's own. The order stays frozen: context root acceptance, acquisition, ledger (with the completeness guard after the witness guard), application, verdict, act; the all-entries acceptance runs context root acceptance, acquisition, then entries verification. `CompletenessSound` is an abstract hypothesis beside `WitnessSound`, never computed. The key layout is a parameter: address prefix today, asset prefix per cardano-utxo-csmt#242, chosen by #35. Refusals stay the three constructors and carry the selected point. Present and wrong evidence is refused, never unverified.

## Requirements

| Name | Required outcome |
| --- | --- |
| completeness-interface | `CompletenessAnswer`, `LedgerAnswer.completeness`, `Policy.checkCompleteness`, `Policy.assetPrefix` and `Policy.requireCompleteness` exactly as ruled, with neutral inherited values. |
| completeness-hypothesis | `CompletenessSound`: a proof checking against the honest root at a point lists exactly the object bytes of the entries under the prefix in that point's ledger. Abstract, beside `WitnessSound`. |
| key-layout-parameter | `KeyLayout`, `UnderPrefix` (a byte prefix of a key) and `AssetKeyLayout`; no layout or encoding chosen. |
| all-entries-acceptance | `verifyEntries` and `acceptEntries` with the ruled guards, under the accepted root and the requested prefix. |
| all-entries-theorem | An accepted all-entries claim is at the selected point, under the honest root, for the requested prefix, and its entries are exactly the honest entries under that prefix. |
| ledger-completeness-guard | When a completeness answer is present, the ledger step requires it for the policy's asset prefix, listing exactly the offered object, checked under the accepted root; absent, the ledger step is unchanged. |
| uniqueness-by-completeness | With a completeness answer present, the state output is unique without `OneShot`. |
| required-completeness | `Policy.requireCompleteness`: when set, an answer without a completeness answer is refused with `evidenceFailure` at the selected point, and every accepted state output is unique without `OneShot`, whatever the provider sends. The provider never chooses which hypothesis the terminal relies on. |
| oneshot-path-preserved | `verifyLedger_sound`, `accept_sound` and `verdict_sound` keep their statements and proofs of the `OneShot` path. |
| present-never-unverified | A bound session whose answer carries a completeness answer is never unverified; a wrong one is refused with `evidenceFailure` at the selected point. |
| completeness-counterexamples | With the completeness check removed, an omitted entry is accepted; with `CompletenessSound` dropped, the all-entries theorem is false on the real model; each reproduced by the simulator. |
| further-mutants | The ruled additional mutants each break an unchanged proof and a scenario. |
| jointly-inhabited-witness | One fixture inhabits every premise of both theorems; honest, refused and duplicate outcomes are reachable. |
| runnable-completeness-scenarios | `lockness-sim completeness` runs the ruled scenarios over the real model. |
| inherited-statements-preserved | A full-statement inventory diff against fff9a77 shows only the ruled classes. |
| inherited-contract-preservation | Every inherited scenario output and check-stage outcome is unchanged; the all-source axiom inventory and hole controls are retained. |
| completeness-design-record | `docs/design/decisions.md` and `docs/model/index.md` state the proof kind, its hypothesis, the key-layout assumption, the one-root assumption, the large-prefix proof-size limit, the terminal's choice between trusting the minting policy (`OneShot`) and requiring completeness, and the out-of-model list with owners. |
| reviewable-delivery | Matching docs and speech, immutable source links, persistent independent checkpoint audit, final-head local checks, exact-head remote CI and preview all precede readiness. |

## Evidence boundary

- Proofs establish model properties under their stated premises.
- Simulator outcomes establish concrete model paths.
- Documentation and CI have separate receipts bound to their revisions.

No CSMT proof format or key encoding (#17, haskell-mts), no asset key-layout choice (#35, cardano-utxo-csmt#242), no proof-free history (#34), no audit work owned by #11, no implementation in index repositories.

## Shared-interface authority

Epic ruling completeness-interface-v1 (answers/A-001-interface-proposal.md) releases the proposal with choices P1 (the answer inside the ledger answer), K2 (an answer carrying any evidence is never unverified), E1 (all-entries claims at the accept level, no verdict arm), U1 (uniqueness stated at the ledger step) and mutants M1–M6, plus correction C1: the policy can require completeness, with its theorem and mutant M7.
