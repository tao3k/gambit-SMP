# Simultaneous Performance, Reliability And Stability Model

## Decision Before Implementation

The existing callback, cleanup and recursive-GC models qualify local protocol
properties, not the simultaneous three-dimensional design contract. This model
adds a bounded reference work/retirement protocol, not another speculative
runtime patch. Its benefit is rejecting invalid repair strategies before native
experiments. No runtime speedup estimate is justified by this model alone.

Two workers and two generations are semantic coverage bounds, not a machine
thread limit. Each worker owns one abstract independent copy/scan task. Both
tasks are published before execution; individual copy/scan actions interleave.
This witnesses overlapping outstanding work, not physical CPU parallelism,
scalability, cache behavior or a claim about Gambit's current scheduler.

## Joint Obligations

| Dimension | Executable properties | Negative controls |
| --- | --- | --- |
| Performance | All three requested feature flags remain enabled; the reviewed copy budget is immutable; at most one copy per task; both tasks are outstanding before execution. | Serialized publication, duplicate copying, disabled SMP, relaxed budget. |
| Reliability | Borrowed resources retain roots until join acknowledgement; successful results carry the current generation; success requires complete useful work and no error, including an earlier generation's error. | Premature reclamation, false success after a worker failure. |
| Stability | Reuse requires no outstanding borrower; repeated-generation results remain current; every nonterminal state has a enabled transition; weakly fair protocol schedules eventually terminate. | Second-generation stale reuse, a nonterminal deadlock. |

`simultaneous` conjoins all dimensions. No individual passing property can
replace it. The positive model explores no-fault and either-worker error cases,
errors before or after copying, all enabled worker interleavings, and a second
generation after acknowledged join. An observed error is retained across reuse:
eventual termination does not turn a failed campaign into success.

The copy budget is two abstract copies for two tasks, not two seconds or a
performance threshold replacement. Copy/scan actions stand for potentially
different-cost operations. Cost attribution, instructions, synchronization,
wakeups, memory traffic and actual useful-work inventory need source-specific
refinement; this model does not prove lower elapsed time.

## Source And Paper Boundaries

The context binds the pinned Gambit source, current callback candidate, its
qualified local ownership model, the saved-stack retirement design, and the
repository's GHC parallel-GC notes. These are audit references, **not formal
composition**. No imported transition or source-refinement certificate is
implied. The reference `join` assumes successful acknowledgement; real join
failure, cancellation, processor membership, C-frame lifetime, nested callbacks,
atomic memory ordering and whole GC phase interaction remain open.

The GHC discussion of load balance and false sharing motivates counting work
without equating that count with speed. Private queues, task sizes, stealing,
shared counters and placement must be evaluated in the actual design. Neither
a global lock around copying nor disabling SMP is an acceptable implementation
of this contract. The model does not prescribe serializing all launches behind
a new runtime barrier.

## Native Admission Remains Required

Use exact source/configuration and a host-derived shared CPU capacity. Keep
startup, complete cold build, complete tests, correctness and repeated lifecycle
runs separate. Preserve existing numeric gates and inventories; never increase
a timeout or discard failed schedules to obtain acceptance. Full bootstrap,
Gerbil tests and production performance/stability are not admitted by this
bounded model or by callback atomic controls.

Further closure requires source-shaped integration with the existing GC and
retirement models, real native resource/failure witnesses, operation-count
instrumentation and repeated same-identity performance receipts. The source
candidate remains unchanged by this modeling work.
