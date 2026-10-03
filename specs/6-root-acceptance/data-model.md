# Protocol data

| Type | Fields and relationships |
| --- | --- |
| Bytes | Exact UInt8 sequence, no normalization or re-encoding |
| Chainpoint | Network, slot, block hash bytes; full equality |
| Root | Scheme and exact bytes |
| Publication | Key, point, root and exact signature/message evidence bytes |
| Policy | trustedKeys, agreement on distinct endorsing keys, abstract executable verification observations |
| Refusal | Exactly noRoot, unavailablePoint, evidenceFailure; each carries selected Chainpoint |
| Session | Selected point and accepted root; shared lifecycle interface only |
| LedgerAnswer | Point, exact ledger object bytes and witness bytes; no verification behavior |
| AppAnswer | Bound application claim/context, exact value and proof bytes; supports later nested roots without verification behavior |

Acceptance binds exact point, root scheme and bytes. Agreement counts keys, not duplicate publications, and cannot accept empty endorsement. SigValid stays separate from computable observations; validity claims require explicit observation-soundness hypothesis. Honest-root correspondence is separately assumed downstream. Providers/builders/untrusted anchors remain arbitrary. Later field changes require epic ruling.
