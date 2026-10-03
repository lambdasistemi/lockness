# Session state and identity

As a reviewer, distinguish the chosen point, the untrusted provider offer and lifecycle availability.

- **provider:** An arbitrary function from `Chainpoint` to `Option Session`; no trust, honesty or availability restriction.
- **session-point:** A definitional accessor of frozen `Session.selectedPoint`; no second stored point. Network and block-hash byte lists plus slot define equality.
- **accepted-session:** The provider session with unchanged selected point and accepted root fields; acquisition validates selected-point equality. Root acceptance remains the predecessor's independent operation.
- **session-state:** An inductive type with requested selected point, active session, expired session, closed session and unavailable selected point. It introduces no clock, duration, token encoding or retention mechanism.
- **session-transition:** A relation representing requested acquisition success/refusal, active repeated reads, expiry and release. Expired reads return the original selected-point refusal. No abandoned-branch policy.
- **refusal:** Frozen existing three-constructor type. The session model uses `unavailablePoint` and preserves the selected point.

All byte fields and accepted root scheme/bytes remain exact. Shared Types and root proofs/fixtures remain untouched.
