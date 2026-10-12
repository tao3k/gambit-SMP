# Continuation Scanner Lock Placement

## Decision Review

This audits a conditional repair alternative, not a native diagnosis. Prior
`continuation_link_handoff` proved an abstract delayed-publication contract but
did not implement bounded pending-chunk storage. This new model asks whether
the existing producer lock could instead cover the frame scanner's conflicting
read/mask/restore interval. It does not rerun the old native failure.

Expected value is eliminating a conditional ownership race without retaining
an unbounded continuation-sized pending list. No speedup estimate is justified:
serializing frame scans may cost performance and must be measured after native
correctness. Native queue eligibility remains an explicit open prerequisite.

## Exact Source Slice

Candidate027 `lib/mem.c` has SHA-256
`c84658583ec03c77b30c3ec5d3ac9d85999ab7e3ede7081ba0ae676b131ba750`.

| Source | Observation And Constraint |
| --- | --- |
| `mem.c:3847-3961` | The copier owns MISC across frame copying, rollover, queue publication and final link completion. |
| `mem.c:3402` | `end_heap_chunk` acquires the chunk queue lock, then releases it. Existing nesting is MISC -> queue. |
| `mem.c:4286-4294` | The frame scanner reads, masks and restores the continuation link without MISC. Protecting only one read or write cannot cover the interval. |
| `mem.c:4411`, `4439`, `6883` | Local dequeue and stealing release their queue lock before `scan_complete_heap_chunk`. Preserve this order if a scanner lock is added. |
| `mem.c:3974`, `3625` | `mark_frame` calls `mark_array`, which may allocate and publish chunks but does not directly invoke `mark_captured_continuation`. Do not lock all of `scan`: its continuation case would re-enter MISC. |
| `mem.c:3533`, `3217` | Allocation takes ALLOC; the default section allocator does not take MISC. `custom_msection_alloc` is called under ALLOC, however, so callback reentrancy is NOT proved safe by this audit. |

All six ALLOC lock sites in this file were checked. The default paths release
ALLOC before requesting a GC or returning to scanning. This is not a whole
program lock-graph proof or a claim about custom callbacks.

Header source at SHA-256
`7f1a3abdd1323c504ab79269bb6a9625f38abc4c3a8d1f773313142d05497a58`
adds an important separate obligation: the non-debug ticket-lock wait at
`gambit.h.in:6222` has no explicit post-wait acquire barrier. MISC maps to this
spinlock unless mutex mode is selected. A sequentially consistent QNT lock is
not a proof of GNU GCC/ARM memory ordering. Reuse the existing ticket/acquire
models; do not declare a bare MISC insertion sufficient or silently broaden
this model to certify the implementation.

## Model Evidence

`continuation_scan_lock_order.qnt` tracks actual abstract lock owners and
producer/scanner phases, not an injected success variable. There are two actor
roles and one subsequent queue publication, not a fixed host CPU count.

The rejected placement holds the dequeue lock while waiting for MISC. TLC
finds a **three-state deadlock trace**: producer owns MISC and needs queue;
scanner owns queue and needs MISC. This control is a rejected proposed repair,
not a claim that the current source has that added lock.

The release-before-MISC variant completes **17 distinct / 23 generated states,
zero queued**, with safety and progress checked in **23.218 seconds**. The
negative control took **19.616 seconds**. Receipt and trace are under
`evidence/model-results/continuation-scan-lock-order/`. `runtimeAdmitted` is false.

Assumptions: an eligible chunk exists; both actors run in one GC phase; finite
copy/scan work; correct lock exclusion/visibility; weak fairness. Excluded:
arbitrary worker counts, recursive/custom allocators, duplicate scan ownership,
physical stack layout, weak-memory refinement, whole-GC termination and native
failure reachability. No runtime patch or build was performed for this model.

## Paper And Engineering Handoff

GHC sections 3.4-3.5 separate allocation, exported scan work and termination.
They support treating lock-blocked workers as unfinished work, not as idle
termination participants. They do not establish Gambit's frame-link ownership.

Before selecting this repair, obtain a source-bound native observation proving
eligible chunk ownership while the previous frame link remains unfinished.
Then compare frame-only locking (including visibility) with bounded deferred
publication. A lock patch must preserve dequeue unlock, avoid reentrant scan
coverage, account for allocator callbacks and keep waiting scanners active in
termination accounting. Same-candidate GC, all-three-flags bootstrap and full
Gerbil tests are still mandatory; this model grants none of those passes.
