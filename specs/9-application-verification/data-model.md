# Application verification data

As a reviewer, check the released shared declarations and the model-only semantic parameters separately.

## Shared successor in `Lockness.Types`

| Declaration | Shape | Meaning and validation |
| --- | --- | --- |
| `AppProof` | `Bytes` alias | Uninterpreted application proof bytes; no format. |
| `AppValue` | `Bytes` alias | Authenticated value bytes, unchanged. |
| `AppQuery` | `application : Bytes`, `context : Bytes`, `claim : Bytes`; DecidableEq, Repr | The terminal's fixed application query. |
| `Policy` appended fields | `query : AppQuery`, `checkApp : AppProof → Root → AppQuery → AppValue → Bool`, `nextRoot : AppValue → Option Root`, `fuel : Nat` | Appended after the eight ledger fields; arbitrary executable observations and a link bound chosen by the terminal; no default endorses evidence. |
| `LedgerAnswer` | unchanged four fields | Declared above `Session`. |
| `Session` appended field | `ledger : LedgerAnswer` | Provider's untrusted answer to the policy's fixed ledger query at the offered point; one query per session in this model. |
| `Claim` | `point : Chainpoint`, `ledgerRoot : Root`, `query : AppQuery`, `appRoot : Root`, `links : List Root`, `value : AppValue`; DecidableEq, Repr | Accepted claim: every field is caller-selected or determined by the verified chain; no proof bytes, provider roots or answer points. |

`AppAnswer`, `Refusal` (exactly three constructors), `Publication`, `Root`, `Chainpoint` and `Bytes` are unchanged. No other Types change is released.

## Model-only semantics (`Lockness.App`, `Lockness.Accept`)

| Name | Shape | Meaning |
| --- | --- | --- |
| `Builder` | `Root → Option AppAnswer` | Arbitrary application evidence supplier. |
| `AppTree` | `Root → Set (AppQuery × AppValue)` | Honest application content committed by each root; may contain several values for one query. |
| `honestNext` | `AppValue → Option Root` | Honest interpretation of a value carrying a further root. |
| `ChainHolds` | inductive over root, link list and final value | Final: the pair is in the root's tree and the value honestly carries no root. Link: the carrier value is in the tree, honestly carries the next root, and the rest of the chain holds from it. |
| `holds` | Prop over policy, ledger and application semantics, a finite entry set and a claim | Semantic claim: query equals policy query; a unique asset-bearing entry exists whose honest datum root is the claim's application root; the claim's chain holds. Never defined from accept or a guard. |

## State invariants

- The selected point is the only point a claim or refusal ever carries.
- The root returned by root acceptance is the only ledger checking root.
- The trusted root at each link is the root the previous link (or the ledger) produced; a claimed root is compared, never adopted.
- Links in a claim are exactly the further roots traversed, in order; the claim's value is the final link's value.
