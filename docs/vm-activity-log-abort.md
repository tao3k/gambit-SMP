# Activity Log Constructor Abort

## Route Review

The missing protocol is constructor abort versus normal VM shutdown. This is a
source-backed ownership/readiness prerequisite, not a measured performance
optimization or attribution to the historical compiler crash. Existing processor
and VM models treat logging as an atomic callee and do not prove this boundary.
No unchanged failed native route is rerun.

## Source Facts

`___setup_actlog_vmstate` allocates the VM activities array, initializes its mutex
without checking the POSIX boolean result, and enables `auto_dump`. It records
`max_processor_count` before P0 logging is initialized. Normal
`___cleanup_actlog_vmstate` stops P0 and dumps its transition buffer before freeing
the VM activities array and destroying its mutex. `___actlog_dump` derives a
cursor from P0's buffer and reads entries. It is not an abort primitive for an
uninitialized P0.

`___setup_actlog_pstate` allocates transitions and stack separately. A failed stack
allocation already frees the temporary transitions before returning, so an outer
rollback must not free them again. Success publishes both and starts P0 logging.
The inspected `___cleanup_mem_pstate` only frees still objects and reference-counted
memory; it does not invoke `___cleanup_actlog_pstate`. Thus invoking the normal VM
log cleanup alone does not release P0 log buffers after a later constructor error.

These statements apply to the inspected activity-log-enabled source branch.
Candidate027's normal configuration does not thereby become an activity-log native
qualification. Enabled/disabled logging and POSIX boolean/void mutex interfaces
are separate branches in the model; a void initializer is assumed to return
normally, not proved exception-free.

## Model And Evidence Boundary

`vm_activity_log_abort.qnt` tracks four resources and P0 started/readable status.
Independent controls cover using normal dump cleanup before P0 readiness,
retaining P0 buffers, ignored POSIX mutex initialization, and a proposed double
cleanup after the helper already released its temporary allocation. Only the
ignored initializer and buffer-ownership facts characterize source boundaries;
normal-cleanup and double-cleanup controls audit possible repairs and do not prove
that a historical native failure followed that route.

The positive abort protocol checks initializer failure, owns only successful
resources, releases P0 resources before VM resources, and never dumps P0.
Progress assumes weak fairness and returning allocations/destructors. Successful
shutdown, dumping I/O, concurrent logging users, repeated start/stop, thread
retirement and C representation/ABI refinement remain outside this model.

The handoff now references this real protocol model, rather than an unmodeled
name. A model edge is not proof of source correspondence or native correctness;
Datalog continues to expose those missing acceptance layers.

Campaign001 stopped at Quint parsing because a local parameter shadowed the
built-in `enabled` operation. Its original failed receipt/log remain unchanged;
the parameter rename does not alter the protocol. It is neither a runtime
failure nor an expected protocol counterexample.

Campaign002 completed all four expected counterexamples and positive safety plus
temporal progress: 107 distinct / 131 generated states, zero queued, 23.363
seconds for the positive check. Inputs and model stayed stable. Portable proof
material is under `evidence/model-results/vm-activity-log-abort-model/`. This
qualifies only the bounded abort protocol, not implemented C, runtime flags or
native startup/shutdown. The accompanying framework regression passed 210 tests
in 33.008 seconds; those tests do not count as Gambit native acceptance.

## Source031 Implementation Boundary

`patches/candidate-vm-actlog-abort.patch` checks the POSIX initializer before
publishing the activities pointer and adds a VM-resource-only abort helper.
Normal shutdown is unchanged. The helper requires successful initialization,
no live logging users and exactly one call; it is not a repeated-call API.
It does not release P0 buffers or implement constructor caller rollback.

The source031-bound model campaign retains all four counterexamples and the
bounded safety/progress result in
`evidence/model-results/vm-activity-log-abort-source031/`. Its context uses the
pinned submodule, source lock and reviewed patch, not cache source paths.

`evidence/source-results/vm-actlog-abort-source031/archive.json` binds the actual
source fixture, three positive branches, a real exit-1 ignored-initializer
control and complete enabled/disabled `actlog.c` object compilation. These are
GNU GCC source-unit observations, not linked-runtime or native pthread proof.

The generic `vm-actlog-abort-native-controls` Recipe completed all eight steps
with stable inputs and a CURRENT identity. Its negative control retained exit 1;
the Recipe PASS means the expected failure was observed, not repaired away.
The original source-unit v2 configuration-binding failure remains DENY with a
retrospective failure receipt. Later runs use the actual `include/config.h`;
they do not rewrite the failed run. Historical dedicated CLI receipts remain
available; new experiments use typed Recipe capabilities.

Reflection links this observation to the still-partial VM-lifetime requirement.
P0 rollback, caller ownership, live-slot retirement, failed joins and complete
native/bootstrap/Gerbil acceptance remain mandatory, unclosed conditions.
