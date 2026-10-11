# Papers To Source Obligations

These are selected by protocol similarity, not language popularity. The exact
pinned Gambit source remains authoritative. Similarity does not establish source
refinement, performance benefit or complete collector correctness.

## Parallel Collection Framework

[Flood, Detlefs, Shavit and Zhang, JVM 2001](https://www.usenix.org/event/jvm01/full_papers/flood/flood.pdf)
describes stop-the-world parallel semispace and compacting collectors. Its
sections 3.1-3.3 separate root distribution, graph traversal and termination
detection. The important transferable obligation is that a worker remains
counted while it can produce or acquire scanning work. Queue emptiness alone
does not establish completed transitive closure. This informs a bounded
source-characterization model, not adoption of their deque implementation.

Gambit paths: `end_heap_chunk`, `mark_reachable_from_marked`,
`garbage_collect_mark_strong_phase`, `garbage_collect_mark_weak_phase`.
Publication already uses two memory barriers and the chunk lock. Termination
uses a mutex-protected activity count and condition wait; the waiter's count is
restored on waking unless termination was declared. Audit the source's own
local scanning and queue ownership before changing that counting protocol.

Model: `gc_scan_termination.qnt`, two workers, one produced chunk per phase,
two phases, coherent queues and acknowledged phase barrier. The detached
publisher is an explicit fault control, not an observed Gambit bug. The
positive protocol is characterization, not a proposed patch. C weak memory,
forwarding, spurious wakes and scheduler fairness are outside this bound.

## Block-Structured Parallel Copying

[Marlow, Harris, James and Peyton Jones, ISMM 2008](https://simonmar.github.io/bib/papers/parallel-gc.pdf)
describes parallel copying while mutators are paused, using blocks to distribute
work. It treats work imbalance, allocation contention and duplicate copying as
distinct concerns. This is a closer architectural comparison than a collector
that runs concurrently with mutators. Its generational and Haskell-specific
policies are not Gambit repair recommendations.

Gambit has processor-local stack/heap sections and queued scan chunks. Transfer
the questions, not its block size: who owns a chunk, when is it published, who
may allocate the next section, and does GC leave usable allocation headroom?
`heap_allocation_headroom` already checks an observed small-heap admission
failure. It does not establish general sizing, max-heap behavior or scalability.
Contention/performance changes await correctness and measured native evidence.

### Thread And SMP Protocols, Not Just Heap Layout

The cached ISMM 2008 paper contains concrete collector-thread protocols in
sections 3.1-3.6. The correspondence below was checked against the selected
runtime 026 `lib/mem.c`; it is not a claim that Gambit implements GHC's collector.

| Paper protocol | Gambit source boundary | QNT obligation and current gap |
| --- | --- | --- |
| 3.1: one evacuation winner; claim, copy, then install forwarding | `mark_array` instead installs forwarding before its copy loop | `gc_forward_publication` distinguishes canonical identity from payload readiness. Audit every special reader; the GHC header-lock protocol cannot be assumed here. |
| 3.2: a private allocation block per collector thread | `setup_stack_heap_vmstate`, processor-local allocation pointers, `next_heap_msection` | Preserve exclusive allocation ownership across section acquisition and publication. Existing one-object modeling does not establish ownership for a recursively discovered graph. |
| 3.3-3.4: pending blocks, scan/allocation cursors, already-scanned prefix | `end_heap_chunk`, `scan_movable_objs_to_scan`, `scan_complete_heap_chunk` | A published chunk must contain complete objects; a consumer must not rescan a completed prefix or treat forwarding identity as scan permission. Local scanning and shared stealing need one composed state machine. |
| 3.5: an empty work set does not imply global termination | `mark_reachable_from_marked`, `scan_workers_count`, termination mutex/condition variable | `gc_scan_termination` checks counted producers and phase closure; `ticket_queue_handoff` checks acquisition. Their individual positives do not prove the interaction with copying or condition-variable wakes. |
| 3.6: export partial blocks when work is scarce | Gambit's existing chunk-ending and local-scan paths, not an equivalent GHC policy | Before tuning granularity, model transfer of the unscanned region without double ownership, lost work or prematurely idle producers. This is an audit/performance hypothesis, not a source defect finding. |

The composition must retain private unfinished work in the global work
accounting, even when every shared queue is empty. Its state needs an owner,
copy-ready versus scan-ready status, local/shared work, active/waiting workers
and collection phase. Required safety properties are unique ownership, no
scan before payload visibility, no lost reachable work, and no phase advance
while an earlier-phase producer or scanner can still act. Strong-to-weak and
cleanup transitions must correspond to the actual `BARRIER()` calls in
`garbage_collect_pstate`, not merely to an abstract queue-empty predicate.

Controls should independently inject early publication, early idleness,
duplicate acquisition and premature phase advance. A counterexample to an
injected control tests the model; it is not evidence that current C permits
that schedule. Existing modeled native failures must remain separately mapped
to their source and receipts, rather than being attributed to this paper.

Progress requires additional assumptions: a runnable worker eventually runs,
published work becomes visible, and waiters can be awakened. Safety exploration
alone does not establish these liveness properties or prove C memory ordering.
The composition should explicitly expose those assumptions and then bind its
publication/acquisition transitions to the source barriers and lock semantics.

`gc_work_closure.qnt` now checks these combined bounded safety obligations for
two workers and a two-object cyclic graph in two abstract phases. All four
fault controls produce counterexamples; the positive protocol exhausts 254
distinct states. See `docs/gc-work-closure.md` for its assumptions and receipt.
This does not close the C correspondence or progress obligations above.

`gc_sync_membership.qnt` additionally checks the assumed entry boundary:
mutator parking, complete roots, old population during nested pre-resize GC,
and new-thread rendezvous before Scheme execution. Both grow2to3 and shrink2to1
are explored; four independent faults are rejected and the positive protocol
exhausts 129 distinct states. See `docs/gc-sync-membership.md`. Its tree-round
and scan-closure assumptions are explicit Datalog contract edges, not a claim
that the separately checked models constitute a source refinement proof.

Section 3.7 also reports an early implementation with balanced instruction
counts but no wall-clock speedup, traced to false sharing of block descriptors.
This is a concrete reason to inspect metadata cache-line placement after
correctness. It neither proves a Darwin-specific cause nor supplies an expected
Gambit speedup. Collector-worker cooperation also does not replace separate
models for VM creation, Scheme thread scheduling, interrupt delivery or I/O.

## Forwarding Identity Is Not Scan Permission

HotSpot section 4 installs the speculative forwarding address with CAS before
copying; the loser redirects its reference and retracts its reservation. GHC
section 3.1 instead describes claiming, copying, then forwarding. These are
different protocols, not interchangeable fixes.

Pinned Gambit's `mark_array` also installs the address before its payload loop.
The loser updates `*cell` and continues; it does not scan the destination there.
The winning copy loop completes before the post-copy `end_heap_chunk` call.
That function orders content/link before queue-tail publication, using existing
barriers and the chunk lock. `scan_complete_heap_chunk` consumes completed
chunks. The pre-allocation `end_heap_chunk` publishes the prior chunk, not the
new speculative object. A CAS barrier cannot order later copy stores by itself.

`gc_forward_publication.qnt` separates canonical identity, copied payload,
queue-visible payload, scan permission and counted producer lifetime. Its two
independent faults are early chunk publication and premature producer idleness;
neither is attributed to the source. Special object/continuation readers, local
tail scanning, recursive graphs and C weak-memory refinement remain open.
This model justifies auditing those readers before adding a per-object lock,
not declaring the whole collector safe or promising a speedup.

Use the local cache described in `docs/paper-cache.md` for subsequent research.

## Algorithm Versus Implementation Proof

[Sandberg Ericsson, Myreen and Aman Pohjola, ITP 2017](https://www.cl.cam.ac.uk/~mom22/itp17.pdf)
separates a copying collector's algorithm proof from its implementation proof.
The relevant lesson is the evidence boundary, not copying CakeML's generational
policy. A checked abstract protocol still needs correspondence to actual roots,
object representation, allocation, generated code and linkage.

Our QNT result is bounded algorithm evidence. `source_binding.py` is a lexical
guard, not an implementation proof. The extracted-function C harness checks
the actual rollback loop with mocked dependencies; it does not exercise real
GC, OS-thread cleanup or partial initialization. The selected runtime's real
resize test adds a separate, narrower native success-path check. Complete
bootstrap and Gerbil correctness remain open; neither source guard nor fixture
success is substituted for them.

## Concrete Closed And Open Boundaries

| Boundary | Current evidence | Remaining obligation |
| --- | --- | --- |
| Failed grow rollback | QNT independent cleanup/target negatives; extracted current C reproduces wrong pointer; candidate passes all four source-unit paths | Partial setup resource cleanup, real allocation-failure injection, VM shrink and thread-create failure |
| Normal grow 1/2/4 | Candidate 008 selected interpreter passed actual processor-count assertions, 1.091 s | Compiled path and complete self-bootstrap |
| Scan work publication/termination | Source audit and new bounded composed protocol | Collector graph/forwarding composition, memory ordering and native root-cause evidence |
| PR1038 forced decode/GC | Prior p4 interpreter passed on candidate 007; compiler SIGBUS remains | Uninstrumented compiler failure cause, compiled regressions and complete suites |

Do not reclassify an uninstrumented failure as repaired because an LLDB run
with different scheduling completes. Do not repeat an unchanged failed route
without a new source-backed hypothesis.
