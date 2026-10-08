# Intake findings

Source baseline: 0676f5d8d8e8bfe47d11fb1544772ae685187421.
Issue #34 and parent #16 are open; no PR existed for feat/34-proof-free-history at
intake. Live #35 and #39 were read to preserve their ownership boundaries.
The initial roster release permitted planning/baseline. history-interface-v1 now
releases code with the primary state and secondary sequence guarantees below.

## Binding inherited contracts

- A-013/A-015: unverified is a declared absence; exact evidenceFailure for a
  misbound offer needs root acceptance success because root evaluation comes first.
- A-017: terminal context is checked before acquisition; foreign publications
  are ignored. With the verifier off, classification remains noVerifier.
- A-019: act receives offer material separately and settlement remains conditional.
  This history slice does not alter action authorization.
- A-021: the terminal chooses required completeness; any witness/completeness
  evidence on a bound selected offer prevents downgrading to unverified.
- Reconstruction is currently one optional transaction-plus-resolved-outputs value
  on LedgerAnswer. The old verdict ignores that field for every policy/provider.
  A dedicated history list field/path preserves that universal theorem.

## Reader sweep

The full source census includes lean/ core, proofs, fixtures, tests, simulator,
mutation scripts, dispatch and documentation/speech. The discovered explicit
constructor changes are four Policy literals in Counterexamples/Fixtures.lean
and Tests/Observation.lean; seven LedgerAnswer literals in
Counterexamples/LedgerFixtures.lean, Counterexamples/SessionMutation.lean,
Tests/Session.lean and Sim/Session.lean. All remaining inherited offers/policies
use record updates. The named Tests.Session.root_and_bytes_unchanged theorem
contains one such literal and needs exactly one neutral history-none argument.

No inherited proof body needs repair in the successor-only compile probe. All
other named handwritten statements retain their source text. Generated declarations
and elaborated record expansions are checked separately in the complete inventory.
The effect unverified-construct prints the offer and therefore gains a neutral
history-none field in its representation; its classification/authorization stays
unchanged. Existing mutation targets stay in the unchanged production modules.

## Design risks and accepted correction

The initial proposal authenticated exact relevant sequences through a root
injective over histories. The ruling corrects this as the secondary guarantee:
ordinary trie state commitments permit cancellation and overwrite without a hash
collision. Primary state soundness instead requires roots injective over reachable
states. Both guarantees require independent semantic replay and correspondence
between the honest history and the selected point's committed state output.

A cancelling-pair fixture must satisfy the state premises and accept an alternative
sequence with the same state while refuting history commitment injectivity. A
separate fixture inhabits sequence soundness. A third compiled mutant compares a
weaker state projection and constructively refutes unchanged state soundness.
The application-rules owner consumes the distinction between commitment kinds.

A separate history verdict exhibits the never-unverified requirement without
changing the existing Claim, Verdict or act. Root/no-provider refusals keep their
precedence; exact history failure theorems name successful preceding boundaries.
Policy fold fidelity and semantic functionality are explicit hypotheses. The
new material has no per-item witness and cannot replace the state-output witness.

## Evidence location

Detailed baseline, constructor probes, complete statement inventories and their
hashes live in the ticket runtime's proposal-evidence handoff and under
/code/lockness-issue-34-evidence. Disposable probes are proposal evidence only;
no history theorem, independent audit or implementation completion is claimed.
Cold-PATH tar failure and the resulting partial ProofWidgets extraction were
setup incidents. The source baseline remained clean throughout recovery.
