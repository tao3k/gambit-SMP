# GC Notification Lock Order

## Pre-Code Review

The existing single-publisher wait characterization leaves actual queue-lock
nesting open. This is a distinct refinement, not a retry of failed bootstrap or
the compiler crash. It is worth checking before a notification repair because
an added lock can create a new correctness defect. Expected runtime speedup is
unknown: this model measures neither latency nor contention. No runtime edit is
admitted by its positive result.

## Source And Paper Boundaries

GHC ISMM 2008 section 3.5 and HotSpot JVM 2001 section 3.3 require counted
scanners and completed transitive work before termination. They do not specify
Gambit's lock protocol. Candidate027 `mem.c:3428-3456` publishes under its queue
spinlock, orders payload/link and tail, releases the lock, then signals without
the termination mutex. Its remote consumer at `mem.c:6926-6948` likewise releases
the queue lock before scanning. The termination mutex is acquired at line 6955.

A proposed predicate recheck under the termination mutex may acquire a queue
lock (M -> Q). Moving the producer's protected signal *inside* its existing
queue critical section instead creates Q -> M. The new model characterizes
this explicit proposed inversion; it does not attribute it to current source.

## Finite Coverage

Two independent publishers each own a separate queue; one waiter checks both
queues. Every identity in the three-role population is explored as the waiter,
and both probe orders are enabled. A queue probe is read-only; scanning and
allocation are not performed while holding M. The positive initializer explores
current unprotected signal-after-Q-unlock and proposed M-protected signalling
after Q unlock. The control instead takes M before releasing Q.

`noLockCycle` rejects the concrete pair where the waiter holds M and wants Q,
while Q's publisher holds it and wants M. `ownersValid` also checks represented
lock owners. Progress concerns finite critical-section completion only; this is
not GC work closure, notification reliability or performance evidence.

## Still Open Before Runtime Repair

Wait registration and active-count restoration remain separate contracts. The
predicate must be bound to actual queue contents and all relevant queues, with
multiple waiters and repeated publication. This model does not prove an atomic
snapshot across queues. C visibility, other lock sites, initialization errors,
teardown, resize and full source refinement remain open. The positive lock
order alone cannot admit the proposed combined notification repair.

See `model-first-repair-admission.md` for the mandatory pre-code and native gates.

## Checked Evidence And Integration Boundary

Campaign `gc-notification-lock-order-001` produced the expected lock-cycle
counterexample (108 distinct states before failure). The positive policies
completed safety and weak-fair critical-section progress over 1,920 distinct
states, 4,200 generated and zero queued, in 26.725 seconds. Reviewed context
remained stable. Portable evidence is in
`evidence/model-results/gc-notification-lock-order/`; runtime/release admission
remain false.

Registration increased the exported checked protocol set from 29 to 31. The
count and lock-order edges are acyclic and their open obligations stay explicit.
The 22 focused model/constructor/report-link framework tests passed in 21.096
seconds using the identity-bound ASCENT API, not a Python inference fallback.

The first invocation without the selected native extension produced two import
errors, not model failures. With the selected extension, the focused suite
passed. The complete Evidence CLI query then failed with ASCENT status -1,
`scheme request rejected`; no successful complete query receipt was produced.
The backend owner is addressing the long-symbol boundary independently. Keep
this integration gate open and do not rerun the unchanged query or claim that
the full Datalog acceptance completed.

A later query with the updated ASCENT implementation passed the main query
stage, then failed in `reasoning_history.record`'s native cross-round delta query
with the same status -1 request rejection. Campaign
`gc-notification-lock-order-index-002` therefore also has no successful complete
receipt. Main inference and history persistence are distinct gates; do not
overwrite the earlier failure or substitute the backend owner's smaller-scope
success for this actual catalog run.
