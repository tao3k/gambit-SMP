# Reporter-Preservation Source Candidate

## Change and Boundaries

This successor inherits every entry of the twenty-file global-cleanup source
lock unchanged. It adds only `tests/unit-tests/13-modules/#.scm`, correcting
the comparator's missing `##failed-check` call to the existing
`##failed-test` function. The equality predicate, compared values, mismatch
message and sticky failure flag are unchanged. This corrects reporting; it
does not assert that the earlier port behavior difference is repaired.

The cumulative patch and all base/candidate hashes are retained in
`patches/fixtures/vm-reporter-preservation.patch` and
`evidence/fixtures/vm-reporter-preservation/source.lock.json`. The source is
reconstructed from the pinned Gambit submodule, not from cached source paths.
Do not bind this source to the older twenty-file producer: completed producer
reuse requires exact complete source-tree identity.

## Model and Native Chain

`test_reporter_failure_preservation.qnt` models equal and unequal comparisons,
the missing reporter's exception, sticky failure, completion, and rejection
of a false successful result. Suppressed failure is a negative control. The
model is conditional and does not prove Scheme resolution or port semantics.

The recipe `smp-test-reporter-failure-preservation-model` first materializes
the locked source, then checks the model, negative control and three concrete
trajectories through the shared QNT/ASCENT framework. An initial patch-context
error was denied before model execution; its receipt is retained. After the
context correction, the changed-input successor passed in 16.789034458
seconds. The safe invariant check covered seven distinct states. This does
not qualify the runtime or prove source refinement.

`vm-reporter-preservation-bazel-bootstrap` retains the original Bazel GNU
profile, all three concurrency flags, all inherited model checks and source
reviews, full two-pass bootstrap, and original 600-second whole budget.
It adds reporter safety and suppression checks before configure. CPU
capacity is detected by the framework; no new fixed CPU count is configured.

Only after that complete producer is verified and exported may
`smp-reporter-preservation-complete-interpreted-grid` run. It preserves the
same 379-file inventory, original whole/file limits, five inherited PR
fixtures, and causal review. The diagnostic reporter wrapper is not selected
in this complete inventory. Any printed comparison mismatch is still a
failure. A passing wrapper or model cannot replace this run.

## Remaining Milestone

The new source completed full two-pass bootstrap in **298.076858249995
seconds** (whole observation 298.9214069590016 seconds), with phases one
through four each observed twice. The actual from-scratch command took
144.15465704200324 seconds, exited zero, and was reaped and quiescent. The
exported producer reference is
`evidence/research/vm-registry-reader-lease/reporter-preservation-completed-producer.json`.

The complete interpreted recipe then passed **379/379 files and 9/9 groups**
in **58.831643083001836 seconds** (whole observation 59.30163545799587
seconds). Every suite command exited zero without timeout and was reaped
and quiescent. The overall read check reports CURRENT/PASS; runtime and
source-refinement admission remain false. This is the complete declared
interpreted inventory, not the one-file wrapper result. It is not a matched
performance improvement claim and does not explain the previous mismatch.

Complete compiled tests,
repeated 2-5 VM lifecycle progress, fault recovery, GC/FFI, Gerbil correctness,
and matched release performance remain separate open obligations. The
previous 378/379 result and all long-run timeouts remain retained evidence.
