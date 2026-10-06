# Completeness data

As a reviewer, see every new or changed shared declaration, its validation and the invariants the completeness checks rely on.

## Shared successor (Types)

| Declaration | Fields | Meaning |
| --- | --- | --- |
| `CompletenessAnswer` | `keyPrefix : Bytes`, `entries : List Bytes`, `proof : Bytes` | The provider's answer: the prefix, every object stored under it as exact object bytes, and the proof |
| `LedgerAnswer.completeness` | `Option CompletenessAnswer`, appended last | Optional; absent is the neutral value |
| `Policy.checkCompleteness` | `Bytes → Root → Bytes → List Bytes → Bool`, appended after `constructUnverified` | The executable observation: proof, checking root, prefix, listed objects |
| `Policy.assetPrefix` | `Asset → Bytes`, appended after `checkCompleteness` | The index key prefix of an asset; an observation of the layout, no encoding chosen |
| `Policy.requireCompleteness` | `Bool`, appended after `assetPrefix` | Whether the terminal requires completeness for the state output instead of trusting `OneShot` |

## Proof-kind data (Completeness, not Types)

| Declaration | Kind | Meaning |
| --- | --- | --- |
| `IndexKey`, `KeyLayout` | `Bytes`; `(TxIn × TxOut) → Set IndexKey` | The keys under which the honest index stores each entry |
| `UnderPrefix` | `KeyLayout → Bytes → (TxIn × TxOut) → Prop` | Some key of the entry has the prefix as a byte prefix |
| `CompletenessSound` | hypothesis | A proof checking under the honest root lists exactly the entries under the prefix; never computed |
| `AssetKeyLayout` | hypothesis | Every output carrying the policy's asset is stored under its asset prefix |
| `EntriesClaim` | `point`, `ledgerRoot`, `keyPrefix`, `entries : List (TxIn × TxOut)` | An accepted all-entries claim |

## Neutral values for inherited constructions

`checkCompleteness := fun _ _ _ _ => false`, `assetPrefix := fun _ => []`, `requireCompleteness := false`, `completeness := none`. No inherited declaration reads them; every inherited outcome is unchanged.

## Invariants

- The completeness proof is checked only under the root bound by root acceptance; `answer.root` and `session.acceptedRoot` stay unread.
- It is checked only for the terminal's prefix: the requested one for all-entries, the policy's asset prefix for the state output.
- Listed objects are exact bytes, bound by decoding and re-encoding equality.
- When the policy requires completeness, an answer without one is refused; the provider never chooses the hypothesis.
- Present and wrong is `evidenceFailure` at the selected point; a bound answer carrying any evidence is never unverified.
- The model bounds no listing size and chooses no key encoding or layout.
