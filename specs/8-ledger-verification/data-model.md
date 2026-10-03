# Ledger evidence and honest state

As a reviewer, distinguish untrusted provider bytes, terminal observations and the hypotheses that connect acceptance to an honest ledger.

## Released successor contract

Byte aliases `TxIn`, `TxOut`, `Asset`, `Schema` and uninterpreted `Witness` each denote unchanged `Bytes`. Ledger maps full chainpoints to Mathlib finite sets of exact input/output byte pairs. These opaque identities introduce no serialization or witness construction.

Policy preserves its original `trustedKeys`, `agreement` and `verify` fields and appends exactly:

| Field | Type |
| --- | --- |
| `asset` | `Asset` |
| `schema` | `Schema` |
| `decodeObject` | `Bytes → Option (TxIn × TxOut)` |
| `objectBytes` | `(TxIn × TxOut) → Bytes` |
| `checkWitness` | `Witness → Root → Bytes → Bool` |
| `assetOf` | `TxOut → Option Asset` |
| `datumOf` | `TxOut → Option Bytes` |
| `parseDatum` | `Schema → Bytes → Option Root` |

LedgerAnswer preserves `point`, `object` and `witness` and appends `root : Root`, untrusted provider data. Session and its root field remain unchanged; the verifier receives independently accepted root evidence separately. Publication, AppAnswer, Bytes, Chainpoint, Root and Refusal stay unchanged. Existing positional Policy fixtures receive explicit unused neutral fields while preserving their first three fields and every inherited outcome.

## Soundness premises

| Premise | Meaning |
| --- | --- |
| root-endorsement | Existing root acceptance establishes the terminal's policy endorsement at the selected point. |
| honest-root-correspondence | Independently connects that accepted root to the honest ledger commitment; endorsement alone is insufficient. |
| witness-soundness | A successful check under the honest root implies membership of the exact witnessed input/output pair at that point. |
| faithful-object-binding | Decoded bytes identify the same object authenticated by the witness; representation correspondence stays explicit. |
| asset-observation-soundness | A successful observation implies the witnessed output actually carries the policy asset. |
| datum-interpretation-soundness | Exact witnessed-output datum extraction and schema parsing correspond to its honest application root. |
| one-shot | At every point, at most one member pair carries the policy asset; Ledger itself imposes no such restriction. |

Successful acceptance identifies an honest member and its datum root; OneShot separately makes that output unique. A duplicate-asset finite set with two different datum roots violates OneShot while keeping membership and interpretation premises inhabited. Full point equality includes network/slot/hash; Refusal retains exactly its inherited three selected-point constructors.
