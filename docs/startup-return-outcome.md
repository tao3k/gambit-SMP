# Startup Return Outcome

## Requirement and Source Audit

A newly created processor must not report successful startup when its thunk
returns without publishing scheduler readiness. Publishing failed status alone
does not satisfy this requirement: `OP_PROCESSOR_0_THROW_ERROR` forwards the C
return code, and a zero code is ignored by the resize error accumulator.

The collective startup acknowledgement candidate had exactly this gap. Its
pending status became failed, but a normally returning custom startup thunk
still dispatched `___NO_ERR`. This is a source audit finding, not a native
reproduction of that particular thunk.

## Model and Repair

`models/gambit/resize_startup_return_outcome.qnt` separates readiness, status,
the input C error, and the dispatched error. The missing-ready control violates
the admission invariant. The fixed bounded Rust simulation checked 80 samples
of 20 steps with seed 1 and found no invariant violation. The model also checks
that processor-zero normal exit, existing errors, and ready success retain
their original outcomes. These bounded checks alone are not exhaustive temporal
verification.

The subsequent source-bound TLC contract reproduced the old admission failure
in three distinct states. The fixed contract exhausted 24 distinct states
(32 generated), including all eight initial root/readiness/error combinations,
and passed safety and temporal completion. The published receipt is
`evidence/model-results/fixtures/collective-startup-return-outcome/startup-return-contract/receipt.json`.
It is registered as finite protocol evidence, not physical source refinement
or native runtime acceptance. Available CPU/memory capacity selected the
checker workers; no fixed runtime processor limit follows from the model.

`evidence/model-results/fixtures/collective-startup-ack/startup-return-controls.json`
contains the raw observations. Simulation threads are explicitly selected from
available host CPUs, not a fixed model cardinality.

The new semantic fixture `collective-startup-return-outcome` changes only
`lib/setup.c` relative to `collective-startup-ack`: after an unready non-root
processor returns zero, dispatch `___UNKNOWN_ERR`. Existing errors are retained;
processor zero is excluded. The VM lookup uses the existing
`___VMSTATE_FROM_PSTATE` abstraction.

Authority is the pinned submodule plus
`evidence/fixtures/collective-startup-return-outcome/source.lock.json` and
`patches/fixtures/collective-startup-return-outcome.patch`, not the execution
cache. The cumulative overlay passes apply-check against the pinned revision.
GNU GCC syntax checking passed using the configured parent header with all
three SMP/multiple-VM flags enabled. The initial syntax invocation accidentally
omitted the local include argument; its DENY is retained separately, and the
corrected invocation is recorded in
`evidence/source-results/fixtures/collective-startup-return-outcome/syntax.json`.

## Remaining Requirements

This fixture has no admitted native runtime. The parent mixed-header-consumer
incremental runtime exited 71 on both host-population and single-processor
startup. Its all-consumer rebuild timed out at 180.116 seconds within a fixed
180-second budget. Neither observation proves the new protocol correct, and
the timeout must not be relabeled as successful ABI qualification.

Required next evidence is a fully coherent header-consumer build, processor
population admission, custom startup-return/error regressions, repeated
resize/still/RC/GC checks, and startup failure rollback/quarantine. Full
bootstrap, upstream suites and Gerbil build/test remain open. No release or
performance admission follows from these model and syntax results.
