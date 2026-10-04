# Verdict layer data

As a reviewer, see every new or changed shared field, its validation and the state invariants the verdict relies on.

## Shared successor (Types)

| Declaration | Fields or constructors | Meaning |
| --- | --- | --- |
| `Binding` | `bound (point : Chainpoint)`, `unbound` | The provider's declared commitment for its session |
| `Reconstruction` | `transaction : Bytes`, `spent : List (TxIn × TxOut)` | Transaction bytes plus resolved spent outputs; never evidence |
| `Policy.verifier` | `Bool`, appended after `fuel` | Whether the terminal checks evidence; read only by `verdict` |
| `LedgerAnswer.witness` | `Option Witness` (was `Bytes`) | Absent means no evidence was offered |
| `LedgerAnswer.reconstruction` | `Option Reconstruction`, appended | Material for rebuilding, carried and never checked |
| `Session.binding` | `Binding`, appended | Declared binding; `selectedPoint` unchanged |
| `Reason` | `noWitness`, `unboundSession`, `noVerifier` | Why a fact is unverified; no payload |
| `Verdict` | `verified (claim : Claim)`, `refused (refusal : Refusal)`, `unverified (reason : Reason)` | The terminal classification; never a wire object |

`Refusal` keeps exactly three constructors, each carrying the selected point. The other inherited declarations are unchanged.

## Neutral values for inherited constructions

`binding := .bound <its own selectedPoint>`, `witness := some <old bytes>`, `reconstruction := none`, `verifier := true`. Each passes the new guards, so every inherited outcome is preserved.

## Invariants

- A session is evidence for the selected point only when `binding = .bound selectedPoint` and its `selectedPoint` equals the selected point.
- Only `binding = .unbound` is a declared absence; `.bound q` with `q ≠ selectedPoint` is a contradiction in the offer and is refused.
- A witness is checked only when present and only under the independently accepted root.
- A `verified` claim exists only when accept returned it.
- `refused` holds only accept's refusals.
- `unverified` carries no claim and no point.
- Reconstruction contents never change a verdict.
