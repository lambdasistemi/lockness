# Public interface

| Surface | Explicit arguments | Result and contract |
| --- | --- | --- |
| acceptRoot | policy : Policy; publications : List Publication; selectedPoint : Chainpoint | Except Refusal Root; exact three-argument interface |
| SigValid | publication : Publication | Prop, abstract uncomputed signature validity |
| Verification observation | publication : Publication, supplied by policy | Bool from arbitrary external interface; no cryptographic implementation |
| Agreement | distinct endorsing key set, supplied by policy | Executable decision with exact proof relationship |
| Endorsement theorem | policy, publications, selectedPoint, acceptedRoot, successful equality | Nonempty endorsing keys contained in trustedKeys, agreement and exact point/root binding; signature validity only under explicit hypothesis |
| Correspondence boundary | acceptedRoot, selectedPoint, endorsement, separate trusted-root hypothesis | Honest-root equality for downstream consumers only under that hypothesis |
| Simulator | accept-root command, scenario | IO output/exit, unexpected outcomes fail |

Required signature: `acceptRoot : Policy → List Publication → Chainpoint → Except Refusal Root`. Names beyond acceptRoot and SigValid are implementation details within these responsibilities. No algorithm is prescribed.
