# Collective Startup Acknowledgement Candidate

## Review Before Repair

The original repeated reuse regression still fails on the collective heap-guard
runtime. A source-bound stack maps the requester to the pinned processor ticket
wait. A separate diagnostic runtime shows the reused processor requesting GC
during Scheme startup, before entering the collector. These are different runs;
the source-consistent wait-cycle explanation is not a fabricated full trace.

The candidate addresses that protocol boundary, not a package-specific workaround
or a performance claim. It is a WIP source repair, not release admission.

## Design and Source

The old grow cohort stays inside `execute_sync_op_loop` until all new slots have
settled their startup outcome for the current epoch. While it waits, it remains
a participant in synchronous GC; it does not spin on a queue lock with Scheme
interrupts disabled. New startup calls and their nested GC calls must still
leave their own completed collective loop so Scheme initialization can continue.

Each new slot receives an epoch after successful C setup and before pthread
creation, with pending status reset at setup. Scheme startup initializes its
queues, unlocks the processor, and publishes ready with release ordering. Old
members read status with acquire ordering and compare the slot epoch against
the recorded grow epoch. Both SMP and non-SMP scheduler branches have explicit
completion calls. SMP reacquires its processor lock before entering the existing
scheduler-with-acquired-lock path.

Ready publication uses a distinct, non-NOOP synchronous operation. Publishing
ready followed by a NOOP first round is insufficient: old callers could leave
while the newly entering caller still needs its second flag-reset round. The
READY round keeps all participants aligned before final NOOP exit.

If the startup C run unwinds while status is still pending, it marks failure
before using the existing processor-zero error dispatch. The resize requester
also retains that dispatched error. This is actual failure publication, but
complete cancellation/rollback and quarantine are not established. A custom
startup thunk that returns normally without publishing ready is a further
explicit source-admission obligation; it must not be admitted as successful
scheduler startup merely because its C error code is zero.

## Model Boundary

`resize_startup_collective_ack.qnt` retains early-return/GC-lock and mistaken
first-NOOP controls. The controls were observed in bounded Rust simulation;
the fixed design found no invariant violation in 80 samples of 20 steps. The
earlier generation/failure model covers stale-ready and missing-failure controls.
These are complementary finite design abstractions, not a formally proven
composition of physical stacks, queues, C atomics and collector phases.

The runtime does not use model cardinalities as worker limits. Available CPUs
select the shared make/child-compiler budget and native VM population.

## Reproduction and Remaining Gates

Source authority is the pinned `vendor/gambit` revision plus
`evidence/fixtures/collective-startup-ack/source.lock.json` and its cumulative
overlay. Only `include/gambit.h.in`, `lib/setup.c` and `lib/_thread.scm` differ
from the collective heap-guard parent. No Python framework files were changed.

The new C fields and global API entry require rebuilding every consumer against
the same header; old dynamic C modules must not be treated as ABI-qualified.
Configured-header regeneration and actual Scheme-to-C regeneration are required
before interpreting any native result. Full two-pass bootstrap and Gerbil
rebuild/tests remain necessary.

Open gates include original reuse/GC regressions, custom startup success/error
semantics, failed-join reuse prevention, epoch wrap/overlap/cancellation, VM idle
queue unlink, recursive GC/barrier composition, full upstream suites and toolchain
acceptance. Runtime/release admission stays false until those gates are resolved.
