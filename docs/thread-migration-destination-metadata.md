# Migration Destination Metadata Candidate

## Source Changes and Review

This candidate extends the resume-gate source fixture, not a different
baseline. Its authority is `vendor/gambit` at the revision in
`evidence/fixtures/thread-migration-destination-metadata/source.lock.json`
plus the cumulative 17-file patch. Mechanical overlay reproduction verifies
all candidate byte hashes against immutable submodule blobs.

Only two files differ from the parent: `_thread.scm` and `_thread#.scm`.
The latter adds `migration-target` at the end of the SMP thread structure.
Prior C field offsets are unchanged. The non-SMP thread definition and
processor definition are unchanged. New constructors initialize the field
to false. Source searches found thread construction/type-extension macro
consumers in these two files, but shared Scheme-header dependencies require
regeneration of other runtime modules too; a partial old binary is not evidence
for the changed layout.

The scheduler now uses the pending target as an independent steal gate.
Interrupt queue reinsertion chooses that target before consulting public
affinity. On owner resume, the target is checked and consumed before pending
interrupt handlers run. A stale captured resume action therefore does not
clear a destination installed by a later handoff. The public pin, specific
data and last-processor execution history are not overloaded.

Model guidance is the interrupt-requeue counterexample and the previously
checked independent resume-gate design. This candidate closes only the
destination-preservation path by source intent; it does not implement the
retirement-borrow/rollback design. No platform performance claim follows.
SMP correctness is not restricted to Darwin, unlike Darwin-only performance
patches; the new field is scoped to the existing SMP type definition.

The generic source-slice exporter currently accepts fewer than the inherited
16 authority files, and not this appended Scheme header. No framework
allowlist was bypassed or edited. The cumulative patch and lock are generated
mechanically and validated with `apply_untracked_patch` over immutable blobs.
Framework integration of the expanded inventory remains an open requirement.

## Native Validation Boundary

The isolated core build uses the parent's actual GNU GCC configuration with
SMP, multiple VMs and multiple threaded VMs enabled. The host-adaptive plan
requested a shared make/compiler budget and a 180-second whole-core cap.
The result was DENY: exit -9 and timeout at 180.018733 seconds. The retained
observation is `evidence/source-results/fixtures/thread-migration-destination-metadata/core-build.json`.
An inherited runtime identity is not valid after source/layout changes; no
native tests were run against this incomplete build.

An initial diagnosis incorrectly inferred that omission of `p1` from the
printed `gsc-boot` command meant the compiler ignored the exported `GAMBOPT`.
Existing `docs/build-shared-cpu-budget.md` and `lib/main.c` contradict that
inference: runtime option sources accumulate unless a source starts with a
comma. An unchanged-parent probe with environment `GAMBOPT=p1` and only
directory options on the command line reported one processor.

The cumulative `thread-migration-shared-regeneration-budget` fixture adds
explicit propagation in eight recipes, but this is redundant for the existing
shared-budget invocation. Its completed core is useful only as an identified
component build for the migration metadata changes. It does not establish a
fix for the parent timeout or a performance improvement. Do not repeat or
promote the explicit-option route as an optimization.

The unchanged compiled `thread_migration_target.scm` is the first regression.
`thread_migration_interrupts.scm` additionally checks repeated unpinned worker
migrations with concurrent sender threads and reports actual delivered
interrupts. It is scheduling coverage, not a deterministic pre-claim
reinsertion proof. Its forms were accepted by the parent Gambit reader.

Open before full admission: actual queued-interrupt regression, nested handler
migration/cancellation, target retirement/drain, generated-layout parity,
all roots and continuation storage, full two-pass bootstrap, complete upstream
suites and Gerbil acceptance. Build and native observations must retain DENY
and timeout outcomes without widening their budgets.
