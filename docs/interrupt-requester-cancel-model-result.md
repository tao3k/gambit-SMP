# Requester Cancellation Model Result

The source-bound cancellation composition passed safety and explicit weak-fair
completion over 192 distinct states, 441 generated states and zero queued.
Three fault controls produced required counterexamples for lost result lifetime,
wake after waiter unlink, and mistaken receiver ownership. The complete campaign
took 15.327 seconds with the unchanged 90-second per-check limit. Six local
trajectories also passed, including wake before unlink and the detached-waiter
window before termination commits.

Portable checked evidence is at
`evidence/model-results/research/interrupt-requester-cancel`.
Its receipt SHA-256 is
`97f1ec357b6735c1e06cb4f4f7e6f60331dae19d50b244535bcd9790b7d5a5c0`.

The first conversion attempt failed with QNT409 before TLC exploration because
multiple initializers reused the imported initialization action. The corrected
initializers assign the same imported pure initial state directly; no protocol
action, fairness condition or safety assertion was removed. The denied attempt
and its original model snapshot are retained separately at
`evidence/model-results/research/interrupt-requester-cancel-conversion-denial`.
It is not admitted and is not a native SMP counterexample.

## Remaining Boundary

Waiter unlink and mutex ownership remain atomic source projections. Successful
physical tracing, primitive termination and weak-fair scheduling are premises,
not properties established by this finite model. Arbitrary request graphs,
processor retirement, collector phases and low-level memory ordering remain
open. Subsequent compiled native diagnostics passed cancellation with GC before
and after requester termination. Their exact scope and remaining limits are in
`interrupt-requester-cancel-native-result.md`.
Full native suites, same-candidate bootstrap, Gerbil and production performance
are not qualified by this result.

This independent evidence is not yet registered in the owner-frozen shared
graph. No canonical failures, historical receipts or shared Python were changed.
