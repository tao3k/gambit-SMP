# Abandonment Composition Model Observation

The figures below are the retained acceptance of model
`407646d402e608ebecc1d02ee549b7fb0c314de2319c73716b31b382b600d19f` and patch
`5b22a3468c26917d46b5af7f988ed3e6b4e7f35ce298954e7408118b7f453b15`.
That `initEither` delayed the end-condvar clear. The current patch keeps the
clear before abandon and adds the thread-group, lock-3, and signal acquires.
Those retained figures do not qualify the current bytes. A later verifier run
uses a new output directory and does not replace this table.

The existing `gambit-smp verify` framework accepted all eleven checks with
`contextStable=true` in 71.303 seconds. Quint was 0.33.0. Scheduling was
host-auto: 12 available processors, two concurrent control jobs with six TLC
workers each, and twelve TLC workers for the positive check. These are observed
host values, not configured worker constants. No timeout was expanded.

## Bound Inputs

| Input | SHA-256 |
| --- | --- |
| `models/gambit/abandonment_gc_publication.qnt` | `407646d402e608ebecc1d02ee549b7fb0c314de2319c73716b31b382b600d19f` |
| `model.manifest.json` | `25d743faabb15654ad51895fae84db7cecb1cef45ae9ea39d3eda58756ba45fd` |
| `source-audit.md` | `4eed57a38673e7965cde0a3c60b578f473167229d4c2ffb27d2a79eb12edcb01` |
| `patches/fixtures/abandonment-gc-publication.patch` | `5b22a3468c26917d46b5af7f988ed3e6b4e7f35ce298954e7408118b7f453b15` |
| Foundation source lock | `405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37` |

The original raw receipt identity is
`204c013d2cbdb2d69e0adb544faf51af92a3cd7f80f91e7c4a51662ea36fb10f`.
It remains a local attempt artifact, including generated checker configurations;
this portable observation does not invent a new raw receipt or native pass.

## Results

| Initializer | Property | Expected result observed | Distinct states |
| --- | --- | --- | --- |
| `initEarlyDrop` | `joinSafe` | Counterexample | 25 |
| `initNoRecheck` | `foreignSafe` | Counterexample | 127 |
| `initEndAdmit` | `admissionSafe` | Counterexample | 36 |
| `initRetainRaw` | `collectiveSafe` | Counterexample | 71 |
| `initDropRaw` | `rawDropSafe` | Counterexample | 6 |
| `initEntryOnly` | `boundarySafe` | Counterexample | 6 |
| `initParticipateOnly` | `progressSafe` | Counterexample | 6 |
| `initInverseStale` | `revalidateSafe` | Counterexample | 6 |
| `initUnlockHold` | `unlockSafe` | Counterexample | 47 |
| `initUnlockStale` | `unlockRecheck` | Counterexample | 59 |
| `initEither` | `safe`, temporal `completion` | Exhaustive PASS, exit 0 | 346 |

Negative controls exited 1 with decoded expected counterexamples. Every check
reported accepted, source-stable and no timeout. The positive explored 544
generated states and completed with zero queued states.

Reproduce with the command in `source-audit.md`, through the existing verifier
and unchanged manifest. Cached checker state is disposable; source bindings and
the observation above are not derived from its continued availability.

## Open Boundary

This is finite protocol characterization, not source refinement, a native GC
repair or proof of the TFIB/pipe timeout cause. The source audit still identifies
unmodeled signal/tgroup interactions and starvation obligations. Runtime and
release admission remain false; no bootstrap/stress was repeated or claimed by
this verification. Cumulative SMP qualification remains 6/12.

## Reader-Repaired Source Context

A later source-bound verification completed all eleven declared checks in
63.722 seconds with `accepted=true` and `contextStable=true`. Its ten negative
controls and healthy finite protocol check retained their original limits.
Receipt digest:
`0b28c2865672e95687f51db408e85fc57a4ba38f770e8576023483d9d3a7fb77`.
The manifest now binds the reader-repaired lock
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`
and its source/audit context. The previous table and receipt are historical,
not transferred acceptance of the changed bytes.

The native reader and failed stress observations are recorded separately in
`native-reader-bootstrap-observation.md`. The sampled C interrupt-publication
ticket wait is outside this model, as described in
`interrupt-publication-barrier-source-audit.md`. This finite PASS closes none
of those unmodeled source obligations and grants no native or release admission.
