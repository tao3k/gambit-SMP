# Processor Scan Lock Ownership

## Source-Bound Review

Candidate027 `lib/mem.c:4776` initializes `heap_chunks_to_scan_lock` without
checking the result. `___cleanup_mem_pstate` at 5095 frees still objects and
reference-counted storage but does not destroy this lock. The configured default
is a ticket lock, whose initialization/destruction has no modeled OS allocation.
The mutex backend is selected by `___USE_MUTEX_FOR_SPINLOCK`; its POSIX init
result and owned OS resource require a different contract. Do not classify this
as an observed default-ticket leak or the reported compiler-crash root cause.

This was an explicit open obligation in the VM spinlock model, not a previously
failed native route. The benefit sought is configuration-correct initialization
and cleanup, with remote GC queue users included in retirement. No performance
improvement is claimed or estimated. The model does not impose worker counts:
one queue user is a finite interleaving witness, not a runtime CPU limit.

## Model Evidence

`pstate_spinlock_initialization` rejects ignored POSIX initialization failure,
missing owned destruction, blind destruction after failed init, and destruction
before a queue user completes. These four controls explored 2, 7, 3 and 9 distinct
states respectively; these are search counts, not shortest-trace lengths.

The checked candidate explores 80 distinct states, 114 generated, 0 queued in
30.903 seconds and passes safety plus weak-fair progress. Campaign
`.data/pstate-spin-model-001` retained stable source/model/framework inputs.
Portable evidence: `evidence/model-results/pstate-spinlock-initialization-model/`.

## Composition Still Required

The candidate closes queue admission and waits for the admitted user before
destruction. That contract is not yet implemented or refined to Gambit's actual
processor stop/join and GC phase transitions. Those users include remote scans
in `mark_reachable_from_marked`, not only the owning processor's local queue.
It must remain an explicit source-correspondence obligation, including C memory
ordering. A ticket-lock destroy no-op does not establish processor storage
lifetime safety.

The source distinguishes resource lifetimes: a shrinking worker calls
`___cleanup_pstate` before `___thread_exit` (`setup.c:940`); processor 0 joins
retired workers later. Consequently a generic "destroy every processor resource
after join" edit is not justified by this model. Establish whether the resize
barrier already drains GC queue users, while synchronous-message users still
need their separate retirement contract. Inspect `BARRIER` and
`OP_SET_PROCESSOR_COUNT` together with GC work closure before choosing the
destruction site. `___thread_join` can also return an error; a returned join call
is not itself proof of successful retirement.

Activity-log setup precedes this lock. Adding a new lock-init error return must
unwind that already-owned log state without dumping an unreadied processor or
duplicating helper cleanup. `pstate_mem_actlog_rollback` remains open. No source
repair, rebuilt binary, native suite, bootstrap or performance gate is admitted.
