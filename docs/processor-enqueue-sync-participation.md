# Processor Enqueue Sync Participation

## Decision And Evidence

This is a correctness candidate, not a measured package speedup. Historical
`startup-gc-lock-cycle.md` already records an enqueue ticket wait with peers in
collective synchronization. Do not claim that rediscovering this cycle is a new
root cause, or repeat the already implemented queues-before-ready repair.

The current retirement candidate's unchanged reuse test had two full passes
and a third timeout. Two diagnostic fixtures then separated thread creation,
pinning, starting and worker execution. Creation and pinning completed; start
did not. A distinct source overlay used static POSIX writes, without Scheme
allocation or lock-order changes, to locate the blocked operation:

```text
TRACE:start-lock-enter
TRACE:start-lock-return
TRACE:pinned-lock-enter
```

No target-lock return, queue publication or VM-lock acquisition followed. The
diagnostic does not identify the target lock's owner or its actual GC round.
It is not a release repair. The diagnostic identities, exact fixture bytes and
receipts are in `evidence/source-results/fixtures/idle-processor-thread-start-lock-trace/`.

## QNT Extension

The earlier startup model made unlock monotonic. Readiness cannot establish that
a processor will never reacquire its lock or request collective work later.
`ready_processor_lock_gc_participation.qnt` covers that additional state.
Its blocking-wait control produces a counterexample (9 distinct states,
3.684 seconds); the sync-participating design checks safety and temporal
completion (14 distinct states, 3.725 seconds). This is finite protocol evidence,
not arbitrary heap, weak-memory or source-refinement proof. The contract and
portable receipt are registered in `evidence/protocol-bundles.json`.

## Source Candidate

`processor-enqueue-sync-participation` inherits the clean retirement candidate,
not the diagnostic overlay. In the two SMP pinned-enqueue helpers only, a
blocking processor lock becomes a trylock loop. The loop dispatches the existing
`##sync-op-interrupt!` only when the sync flag is set; it does not dispatch ordinary
user callbacks while the thread publication transaction holds its thread lock.
The target processor object is permanent.

Generated C preserves the processor argument and return address in stack slots
across the sync call. The existing sync primitive stores RA, spills registers,
services the collective, restores registers and RA. These are audited source
facts, not complete proof of moving-root ownership or exception rollback.

The cumulative patch independently reconstructs all 17 locked source hashes
from the pinned submodule. GNU GCC 16.2.0 incremental core build passed in
11.677 seconds with all three SMP/VM flags enabled. Host-selected available
processors determine make jobs; compiler children share that budget with p1.
There are no trace writes in this candidate.

## Native Qualification

| Unchanged fixture | Native result |
| --- | --- |
| Compiled migration target | PASS, 0.479 s |
| Compiled strict interrupt delivery | PASS x3, 0.464 / 0.014 / 0.014 s; 1152 interrupts each |
| Interpreted processor reuse / still survival | PASS x3, 0.491 / 0.048 / 0.038 s |
| Mixed-key forced GC | PASS, 0.036 s |
| Compiled processor reuse / still survival | PASS x3, 0.494 / 0.035 / 0.035 s |
| Interpreted still-object retirement survival | PASS, 0.012 s |
| Compiled reference-counted-object retirement survival | PASS, 0.460 s |
| Interpreted complete resize/GC lifecycle | DENY, 30.005 s, exit -9 |

Every invocation retained its original compile/process budget. The final
lifecycle run stops here:

```text
(resize-enter 12 1 caller 0)
(resize-return 1)
(resize-enter 1 12 caller 0)
(resize-return 12)
(resize-enter 12 1 caller 5)
```

This is the previously documented retired-requester boundary, now observed on
the current exact source and binary identity. The fixture was not pinned to P0
to hide it. A completed P0 reuse campaign does not qualify a requester that is
itself removed. The current C resize path still exits retired processors without
establishing requester continuation handoff before that exit. Preserve the
missing handoff as a requirement; last-line timing alone is not a full stack
proof or a reason to repeat this unchanged failure.

The base regression receipt passes, but the aggregate candidate is DENY because
the broader lifecycle receipt fails. No full bootstrap, upstream suite, Gerbil
or release admission follows. Bootstrap was not launched after fail-fast.
Receipts are under `evidence/source-results/fixtures/processor-enqueue-sync-participation/`.

## Remaining Requirements

- Transfer a requester to a retained processor before a shrink can remove it;
  preserve API behavior and exactly-once result delivery, rather than pin tests.
- Compose that handoff with migration locks, saved continuations and roots.
- Prove sync flag reset, barrier-round identity and generation membership.
- Model exception unwinding and failure rollback while the thread lock is held.
- Admit full native suites, fresh two-pass bootstrap and Gerbil build/test.

The native result supports continued investigation of sync-aware acquisition;
it does not uniquely isolate the target owner's GC request or prove full SMP green.
