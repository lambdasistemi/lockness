# Operating context data

As a reviewer, see every new or changed shared declaration, its validation and the invariants the guard relies on.

## Shared successor (Types)

| Declaration | Fields | Meaning |
| --- | --- | --- |
| `Context` | `network : Bytes`, `schemes : List Bytes` | The terminal's declared operating context. A scheme identifier is compared with `Root.scheme` and carries the scheme's version; its encoding is #17's. |
| `Policy.context` | `Context`, appended after `verifier` | The context the policy's trusted keys are trusted for |
| `MessageModel` | class, `encodes : Bytes → Chainpoint → Root → Prop` | Arbitrary abstract meaning of signed message bytes; never computed |
| `MessageBinding` | `[SignatureModel] [MessageModel] → Prop` | Every `SigValid` publication's message encodes its own point and root, and a message encodes at most one point and root |

`Publication`, `Chainpoint`, `Root`, `Refusal`, `Verdict` and every other inherited declaration are unchanged. `Publication.point` (network, slot, block hash) and `Publication.root` (scheme, bytes) are the fields `MessageBinding` speaks about; `message` stays opaque bytes.

## Executable versus abstract

Executable: `Context`, `Policy.context`, the guard and the context-checked root acceptance. Abstract: `MessageModel.encodes` and `MessageBinding`, beside `SignatureModel.valid`, `SigValid` and `ObservationSound`.

## Neutral value for inherited constructions

`context := ⟨[0], [[0]]⟩`: the network and scheme every inherited accept-level fixture already uses. Every inherited outcome is preserved.

## Invariants

- The guard reads only the policy, the selected point and the root that root acceptance selects; never a provider or builder.
- Out of context means: the selected point's network differs from the context network, or the root that root acceptance selects has a scheme outside `schemes`. Publications are never read for their network (ruling C1): one on another network cannot endorse a point on this one, by #6's full-point equality, and cannot veto.
- An out-of-context selection is refused with `evidenceFailure` at the selected point and is never `unverified` under a configured verifier.
- An accepted root has an accepted scheme and was endorsed only by publications on the context network.
- `MessageBinding` is a premise, never derived from `verify`.
