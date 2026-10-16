# Chapter-Level Paper And Source Audit

## Method And Evidence

Engineering acceptance, not paper conformance, is the decision criterion.
Papers propose mechanisms and assumptions; current source determines implemented
behavior, and community reports plus identity-bound native failures constrain
what the model must represent. Source behavior may itself be incorrect. Neither
a published design nor a passing finite model overrides a reproducible failure.

For each proposed repair, trace the actual build configuration, call graph,
ownership transfers and failure paths before admitting it. A helper that already
rolls back OS resources on memory-setup failure changes the caller's cleanup
obligation; a generic transactional model that omits that helper is incomplete.
Record a paper/source disagreement as a refinement obligation, not a reason to
discard the source observation or import the paper's algorithm wholesale.

Final acceptance requires the same identified GNU GCC candidate, all three VM
and SMP switches enabled, the real Bazel build path, GC and lifecycle regressions,
complete bootstrap, and Gerbil build/full tests. Native correctness precedes
performance acceptance. Partial successes remain scoped to their actual checks;
no model, mock, source-unit fixture or paper grants a native PASS.

Read status is separate from source correspondence, model checking and native
acceptance. A cached PDF or abstract is not a completed reading. For each section
record its protocol, assumptions, exact source difference, model obligation,
repair applicability and native evidence still needed. Consult
`model-no-special-cases.md` before proposing changes.

Source references below are candidate026, pinned by the protocol manifests.
They are not assertions about current upstream master. No section below grants
runtime acceptance or an end-to-end speedup.

Use the integrity-checked `.cache/papers/<id>/` cache. New primary sources are
listed in `evidence/papers-audit-expansion.json`; existing sources remain in
`evidence/papers.json`. New IDs are separate to avoid changing Working's paper
inventory concurrently. Publication metadata is confirmed through the Gambit
research page and authors' publication lists, not search-engine date snippets.

## GHC Parallel Copying GC (2008)

### Sections 2.1-2.3: Heap And Representation

Read, with relevant local source inspected. Generation/step descriptors are not
Gambit msections. Compare `mem.c:set_heap_msection`, `prepare_heap_msection`,
`start_heap_chunk` and `include/gambit.h.in` object tags. Model allocation class,
address generation and copy readiness separately. Do not import historical block
sizes, generation counts or pointer-layout constants into a runtime patch.
Remaining: source-bound reuse/alias cases across collection epochs.

### Sections 3.1-3.3: Claiming And Pending Work

Read and source-correlated. GHC's described claim/copy/unlock sequence differs
from candidate026 `mark_array:3722-3773`: Gambit CAS-publishes a destination
address before copying its payload. Therefore forwarding identity must not imply
scan readiness. Local allocation and pending work require separate invariants.
Reuse `gc_forward_publication` and `gc_scan_claim_transfer`; do not replace the
forwarding protocol on the strength of GHC's assumptions.
Remaining: verify every consumer of a forwarded reference and publication point.

### Section 3.4: Scanning And Export

Read, source-correlated and newly modeled. Exported work must respect the scan
frontier and completed data. Candidate026 already excludes its locally scanned
allocation chunk in `end_heap_chunk:3416-3417`. However continuation frames have
an additional producer-owned link: `mark_captured_continuation:3941-3943` retains
a later rewrite; `scan:4286-4294` reads, masks and restores the same field.
`continuation_link_handoff` finds a conditional lost-update schedule. Full body
copy completion alone is insufficient as the export condition.
Repair gate: establish actual queue eligibility and source-enforced ownership;
do not merely switch the allocation threshold guard or add a duplicate fence.

### Section 3.5: Termination

Read and source-correlated. `mark_reachable_from_marked:6883-6985` retains active
workers while scanning local/queued work; `garbage_collect_*` has phase barriers.
`gc_epoch_work_bridge` and `gc_work_closure` model those obligations. Empty queues
alone do not establish that producers are finished. Do not equate one observed
wait stack with deadlock. Remaining: source refinement of producer admission,
population resize and all potential pending-work sources.

### Section 3.5 / HotSpot Section 3.3: Resize Retirement Follow-Up

Re-read both cached sections against candidate027 `mem.c:6883-6987` and
`setup.c:650-717,930-980`. Source and paper hashes still match the new
`gc-resize-resource-retirement.json` context. Status: sections read and source
checked; a concurrent Working Session owns the new composition model; no native
acceptance follows from this review.

The papers count active scanners, including resumed/stealing workers, rather
than using queue emptiness as termination. Gambit exhausts local still/movable
work, releases a stolen queue lock before scanning the chunk, and only then
decrements `workers_count` under the termination mutex (`mem.c:6955`). A waiting
worker observing nonzero count increments before returning to the steal loop
(`mem.c:6982`). The zero-count conclusion depends on that closed work-producing
population; it does not prove unrelated synchronization senders have returned.
The source's later downward resize messages at `setup.c:700,707` and joins at
`setup.c:979` have a different lifetime obligation. Neither paper licenses
destroying their mutexes/conditions merely because GC work has terminated.

Audit of the initial `gc_resize_resource_retirement` model found a role-coverage
restriction: `arriveGC` assigns the only outstanding scanner to processor 0,
while `queueOwner` is always the last processor. Varying population and retained
prefix does not vary those roles. The actual source runs the scan protocol on
each processor. Requested correction: parameterize scanner and queue owner over
the declared finite population, or supply and state a valid symmetry reduction;
include retained-nonroot and retired scanner roles. This is a model coverage
obligation, not an observed runtime counterexample or evidence of a native fix.

Expected benefit is preventing an overbroad reclamation proof. Additional model
roles increase finite exploration cost; no speedup is claimed. Preserve separate
queue-operation completion, sender unlock/signal completion and processor-storage
retirement predicates. Native gates remain source-bound GC exit/resize schedules,
join-error ownership and all-three-flags artifact/bootstrap/full-test acceptance.
No unchanged failed native route was rerun; this audit was sent to Working before
editing its owned model or accepting any new model receipt.

### Section 3.5 / HotSpot Section 3.3: Outer-Round Source Refinement

Re-read both cached termination sections and candidate027 `setup.c:526-535,
550-717,878-1008,1059-1125`. Status: sections read, source checked, bounded
source-shaped model checked; no native acceptance. The preceding role-coverage
request is now implemented by Working: its separate campaign002 explores every
scanner/owner pair within populations 2..5 (94,386 distinct states). That result
does not itself refine the abstract retained-next-round admission to source.

The new `sync_retirement_round_closure` follows each old downward send through
publish/unlock/signal, retired exits/joins, and the actual retained-tree upward
aggregation in the next outer `barrier_sync_op` call. Root receives a child's
aggregate only after that child received its descendants' aggregates. Thus the
model derives old retained-sender completion from source-shaped convergence;
it does not assume all retained senders are already drained. The old-root
inner-barrier return and successful joins alone are insufficient.

Campaign002: ten population/prefix initial configurations, 4,695 distinct
states, 14,872 generated, zero queued; safety and weak-fair progress pass in
24.830 seconds. Joins-only reclamation produces a 16-state counterexample.
Campaign001 had a map-domain evaluation error, preserved as a rejected model
run, not presented as a protocol defect. Receipt/source context is bound in
`evidence/model-results/sync-retirement-round-closure/`.

The candidate repair point is root convergence in the next outer round, before
downward propagation, with explicitly tracked pending-retirement ownership.
Expected benefit is a justified location for cleanup, not a claimed speedup.
Cost includes pending state, round identity and failed-join handling. The papers
do not supply those engineering details. Repeated resize, failed initialization,
nested GC and C memory ordering remain unproved and must constrain any runtime
edit. See `sync-retirement-round-closure.md`; no unmatched barrier or unconditional
destruction hook is authorized, and no unchanged native failure was rerun.

### Sections 3.4-3.5: Saved-Thread Root Coverage Follow-Up

Re-read against candidate027 (same memory/header bytes as candidate026).
`THREAD_SAVE:6314` and `THREAD_RESTORE:6377` preserve a suspended thread's saved
frame while changing the currently rooted break chain. `mem.c:4049` scans that
current chain; `mark_array:3753` does not eagerly chase a CONTINUATION frame,
whose subtype differs from BOXVALUES (`gambit.h.in:2923,2929`). The dedicated
frame traversal occurs at `mem.c:4247`, potentially after the strong-root barrier.

Source-correlated characterization `continuation_saved_stack_origin` passes
42 distinct states with progress. It models a retained-stack save/restore slice,
not full scheduler/physical-stack refinement. Native acceptance is **not run**.
Remaining: prove preserved physical stack range and actual rollover/nonlocal
consumer overlap, then select a minimal source repair. See
`continuation-saved-stack-origin.md`. GHC's root discussion is design context,
not proof that Gambit's saved continuations were all handled before the barrier.

### Sections 3.6-3.7: Scarce Work And Prototype Lessons

Read; not a qualified optimization. Smaller exported batches are a hypothesis
only after ownership safety. The continuation local-frontier observation does
not measure the workload share or imbalance. Descriptor traffic is a separate
performance hypothesis, not evidence for changing Gambit's cache layout.
Required evidence: per-worker useful scanning and publication delay, plus matched
whole build/test timings. Do not trade correctness for an earlier first log.

### Sections 4-4.2: Generations And Promotion

Read; transferability limited. Eager promotion relies on semantics that are not
established for Gambit's mutable Scheme objects. No generational retrofit is
proposed. This remains context, not a new runtime route or an SMP repair.

### Remaining Chapters

Sections 1 and 2 introductions are read. Sections 5-5.7 measurements, 6 related
work and 7-7.2 conclusions/future work still require systematic chapter-to-source
review; prior spot reads are not recorded as completed. Prioritize section 5's
measurement controls before any performance claim from a new publication policy.

### Section 3.6: Scarce Work And Partial-Block Export

Read in the cached text (lines 294-326), then checked against candidate027
`mem.c:end_heap_chunk:3402`, both chunk consumers (`4496`, `6926`) and captured
continuation copying (`3898`, `3948`). Status: chapter read and relevant source
checked; existing models cover component obligations only; no new model run or
native performance acceptance.

The paper's motivation is delayed parallel work exposure for narrow object
graphs. Its partial-block policy depends on pending-work availability, enough
useful exported work, and enough work retained by the exporting scanner. A
thread-local partly-free list recovers remaining capacity after those blocks
have been scanned. These are coupled scheduling/allocation decisions, not a
portable numeric threshold or an unconditional instruction to export earlier.

Gambit's FIFO export writes an end marker, excludes the currently scanned
allocation range, publishes the tail with barriers, then wakes an idle scanner.
Consumers release the queue lock before traversing a complete chunk; the local
scanner subsequently resumes its incomplete allocation chunk. Captured-frame
copying additionally retains a producer-owned continuation-link rewrite across
iterations. Physical capacity, bytes copied, scan ownership and link readiness
therefore are distinct frontiers. Lowering `alloc_heap_chunk_limit` or adding an
idle-triggered export without preserving those frontiers is not admitted by this
paper or by an empty-queue observation.

Reuse `gc_scan_claim_transfer`, `gc_work_closure`, `continuation_link_handoff`
and the saved-stack/export-origin audits rather than recreating their negative
controls. Any future partial-export experiment must establish an actual
source-eligible handoff, transferred scan interval, producer-link readiness,
allocation-generation identity and the retained local-work invariant first.
Possible benefit is reduced idle time for scarce-work graphs; extra publications,
synchronization and fragmentation are explicit costs. No local workload evidence
currently establishes that benefit or connects it to the compiler residual.
Current source-fix priority remains ownership/rollback, not threshold tuning.

## HotSpot Parallel GC (2001)

### Cross-Paper Lock-Placement Follow-Up

Re-read GHC 3.4-3.5 against `mem.c` copier, frame scanner, queue dequeue and
termination accounting. Added `continuation_scan_lock_order`: a three-state
counterexample rejects taking MISC while retaining a queue lock; the bounded
release-before-MISC candidate has 17 distinct states with safety/progress.
This is not a native repair. Default allocation paths were inspected, but
custom allocator reentrancy and the ticket lock's post-wait memory ordering
remain open. See `continuation-scan-lock-order.md` for source identity and gates.

### Sections 3.1-3.4: Work And Termination

Read; source mapping partial. Root tasks, local work, stealing and overflow must
all participate in termination. Gambit's chunk FIFO is not the paper's bounded
object deque or class-header overflow list. `scan_still_objs_to_scan` and movable
scanning both feed `mark_reachable_from_marked`; verify this combined closure.
Do not copy the overflow encoding into Gambit's headers. Existing closure models
are the starting point; native producer/termination races remain unqualified.

### Section 4: Parallel Semispaces

Read and compared to `mark_array`. Speculative destination reservation followed
by CAS and winner copying is closer to Gambit's sequence than GHC section 3.1.
This does not prove that every Gambit consumer waits for ready contents. Local
allocation rollback and shared scan publication must remain separate obligations.
Avoid adding redundant copying or treating a forwarding address as a ready bit.

### Section 4: Eager Field Ownership Refinement

Re-read the cached semispace/LAB/CAS discussion, then inspected candidate027
`mem.c:3720-3803,4323-4356,5180-5185,7090-7125,7239-7247`. Status: chapter
read, these source paths checked, bounded partition model checked; native
acceptance remains absent. Other forwarding consumers remain unaudited.

`mark_array` copies the full body, can export its chunk, then eagerly marks
field zero for nonempty movable default subtypes through BOXVALUES. Both the
ordinary scanner and pair fast path skip that field. Producer work overlapping
an exported object's scan is therefore not itself a duplicate ownership defect:
ownership belongs to disjoint field intervals. Whole-object exclusion is too
strong for this source path. The producer must remain active until its eager
work, including any recursive allocations, completes. Forwarding CAS losers
only redirect references; weak-phase will consumers dereference payloads under
a separate strong-closure/barrier premise. These distinctions are not supplied
by a generic forwarding-ready Boolean.

New `eager_tail_scan_partition` covers 1..4 fields and legal overlapping work.
Campaign002 passes safety/progress: 74 distinct states, 114 generated, zero
queued in 28.396 seconds. Six- and seven-state controls reject scanning field
zero twice and retiring the eager producer on export. A first-run builtin-name
parse error is retained as rejected tooling/model input, not protocol evidence.
Source/paper identity and receipts are in
`evidence/model-results/eager-tail-scan-partition/`.

This closes a local abstraction gap, not diagnostic014's duplicate vector-body
origin. Do not add a to-space skip, global lock or unconditional export delay.
Next obligations: recursive eager-chain allocation/termination composition,
allocation-generation/claim identity for the observed repeated body, and actual
C release/acquire. No measured speedup, runtime repair or native retry follows
from this result. Details: `eager-tail-scan-partition.md`.

### Remaining Chapters

Sections 1-2, 5-5.2 and 6-8 are queued for systematic review. Some introductory
and result excerpts were consulted previously, not fully source-audited.

## Gambit Continuations (2000)

All six sections read; both scanned PDF pages visually checked after OCR.

| Section | Reflection And Source/Model Consequence |
| --- | --- |
| 1: Mixed frame lifetimes | Distinguish Scheme reachability from C stack lifetime. Current `mark_captured_continuation` is not by itself an FFI lifetime proof. |
| 2: Copying C stacks | Reject a generic stack-copy repair without preserving address and mutation semantics. Not a shortcut for the current frame-link race. |
| 3: Lazy C-stack deallocation | Frame retention and resumption order need explicit ownership states. Reuse the existing FFI-frame protocol rather than assuming all stacks are independently reclaimable. |
| 4: C-thread proposal | This is independent C-stack storage, not a proof of parallel collector correctness. Do not infer current multiple-VM behavior from it. |
| 5: Practicality | The paper explicitly states the proposal was not implemented in Gambit-C. No historical implementation result or measured modern benefit may be claimed. |
| 6: Related work | Hieb/Dybvig/Bruggeman on continuation representation is a targeted next source, not permission for an unrelated threading rewrite. |

Current FFI source correspondence beyond the known frame-copy sites remains
pending. OCR is provenance-marked; its recognition errors are not code evidence.

## Gambit Incremental GC (1998)

Sections 1-2 and 3-3.4 read. The historical stack cache, allocation classes,
still-object reference roots and copying/sweeping closure explain useful design
lineage. Compare current `setup_still_objs_to_scan`, `mark_continuation`,
`mark_registers`, `scan_still_objs_to_scan` and strong-phase root scanning.
Historical sizes/tag widths are not current runtime constants. The incremental
collector and its mutator barriers are not a drop-in parallel-GC repair.
Sections 4-4.6 are now read in cached extracted text and compared with
candidate027 `mem.c` (SHA-256
`c84658583ec03c77b30c3ec5d3ac9d85999ab7e3ede7081ba0ae676b131ba750`).
Extraction interleaves columns and damages equations; no numeric scheduling
formula is admitted from this reading. Section 5 and later still require
systematic review. The local PDF is a revised version noting a measurement
correction, which matters for later review.

| Section | Protocol, Source Difference And Engineering Obligation |
| --- | --- |
| 4 / 4.1 | Historical incremental mark/slide uses nonmoving handles and whole movable sections. Handle storage retains historical peak capacity. Current representation branches are at `mem.c:520,533`; GNU GCC preprocessing of the actual configured header leaves `___USE_HANDLES` undefined. This is not an implemented current collector switch. |
| 4.2 / 4.3 | Gray-list metadata, backpointers and stable indirection support the historical compactor. Current copying paths still contain handle-allocation TODOs at `3691,3905`. Enabling a macro is not a correct representation migration; roots, FFI references and every allocation/copy path would need qualification. No such rewrite is proposed. |
| 4.4 | Atomic roots and precompaction rescans close mutations made between incremental parcels. Current `___garbage_collect_pstate:7159` instead sequences setup, strong, weak, cleanup and resize with barriers (`7223-7264`). Reuse phase/closure models; do not assume a mutator interleaving absent from this implementation. |
| 4.5 | Gray-source rescanning deliberately revisits a mutated vector prefix; repeated mutation can prevent progress without workload assumptions. This does not justify duplicate relocated-body scanning in the current copying protocol. Diagnostic012-015 retain their input/ownership failures; reuse scan-claim and eager-tail-partition models instead of masking them with a to-space skip. |
| 4.6 | Allocation-driven word-bank progress assumes a live-space bound and controlled mutation. Current `compute_free_heap_space_approximately:494`, `resize_heap:6525-6546` and `___heap_limit:7653` use section ownership, reserve and post-copy headroom. Reuse the source-bound headroom model/receipts; do not substitute historical parcel constants, increase test deadlines, or claim modern Darwin throughput from the old results. |

Status: textual chapter reading and scoped source check, not a new model proof
or native acceptance. Representation migration would add indirection/metadata
and write-barrier costs; no local evidence predicts a worthwhile gain. The
actionable conclusion is an applicability boundary, not another failed-route
rerun. Next: verify damaged equations visually only if a concrete incremental
collector proposal requires them, then audit section 5's measurement controls.

## Boehm: Benign Races (2011)

Sections 1, 2.1-2.5 and 3 read. The concrete obligation is source-level
synchronization, not merely a plausible machine interleaving. Map publication
to `SYNC_SEND_MSG`, fast `SYNC_GET_MSG`, the two continuation-link writers and
GNU CAS/barrier definitions. A fence or `volatile` declaration alone does not
establish portable exclusion. Same-value writes and disjoint-bit assumptions
also need an actual protocol. This is not proof that GCC16 miscompiled Gambit;
inspect its selected primitives and generated code before such a claim.

### Shared Allocation Cursor Follow-Up

Source/code-generation follow-up to the already-read race/publication material:
candidate027 `mem.c:327-328,383,3217-3278,3533-3535` and
`gambit.h.in:6222-6227,11025-11037`. No new paper chapter is marked read here.
The queue consumers' added post-wait acquire is not present in ALLOC, which
protects the VM-shared next-msection cursor and assignment count. Reservation
before a previous holder finishes cannot supply acquisition of that holder's
later updates. MISC has a related but separately scoped obligation.

Inspected actual configured-header code generation with GNU GCC 16.2: the
unmodified fixture uses `ldaddal` reservation followed by an `ldr/cmp/bne` wait
and an ordinary protected-data `ldr`; adding the existing barrier macro inserts
`dmb ish` after the wait. Compilation exited zero. The standalone fixture is
not the whole optimized runtime and did not execute a race or reproduce GC.
Identity-bound receipt/assembly: `evidence/codegen/ticket-acquire/`.

Reuse `ticket_queue_handoff` for the ordering obligation rather than repeating
its known negative search. Current GCC volatile/sync documentation was checked
as language/compiler guidance; it is not a C memory proof for the legacy lock.
The proposed scoped acquire versus shared-primitive repair must still account
for ownership, initialization, callbacks and all native gates. Potential
duplicate assignment is a hypothesis, not an attribution of diagnostic014/015;
candidate018's later source-bound progress must remain visible. Expected benefit
is correctness, with barrier cost unmeasured. See `allocator-ticket-acquire.md`.

### Retirement Error-Path Source Refinement

Reviewed Working's new two-generation retirement model against candidate027
`os_thread.c:462-554`, `os_base.c:1063-1076` and
`setup.c:974-1015,1111-1116`. No additional paper chapter is marked read.
The model's failed-join ownership contract remains necessary, but source
semantics distinguish error identity from successful retirement: pthread's
returned error is discarded, yet zero ambient errno yields UNKNOWN_ERR, not
NO_ERR. The ignored join result in the resize caller is the independent
admission failure. `thread_init_common` currently cannot fail after creation.
Creation failure is post-population-publication and fatal; replacing it with
unilateral local return would require a new participant/rollback proof.

These are now hash-bound research-audit obligations, together with the allocator
acquire observation; the existing Datalog audit query lists eight blockers and
all five native gate categories pending in
`.data/allocator-pthread-audit-001/receipt.json`. This query result is not a QNT
run or native acceptance. No retirement model was edited during Working's
verification. See `pthread-error-source-audit.md` for the concrete correction
boundaries and `research-audit.json` for inputs that must remain current.

### GHC 3.4-3.5 / HotSpot 3.3: Recursive Progress Follow-Up

Re-read these cached sections against the locked candidate027 overlay; both PDF
pins, extracted-text hashes, overlay and all three source-slice hashes match.
Status: sections read and exact source checked; enabledness, unbounded fairness
and source refinement remain open; no native acceptance. No additional paper
chapter is marked read and no unchanged failed route was repeated.

Both papers revisit shared work while other scanners remain active. Candidate
`mem.c:3455-3456,6910-6918,6955-6984` instead has finite repeated steal probes,
Q-unlock/signal without M, and a count-decrement/condition-wait protocol without
the model's combined M-held queue recheck. The bounded rank also consumes a
once-per-worker spurious-wakeup allowance absent from the source contract.

Next obligations are original-action feasibility, repeated-probe stuttering,
wait/notification correspondence and explicit per-worker/lock/environment
fairness. Aggregate fairness of the action disjunction cannot alone justify
the unbounded-wakeup abstraction. This is an audit argument, not a decoded
counterexample or a native failure. See
`gc-recursive-progress-source-obligations.md` for precise locations, assumptions,
controls, repair costs and the unchanged same-candidate native gate list.

## Gambit Parallel VM (1990)

Cached and introduction/architecture excerpts screened, not chapter-complete.
Useful for PVM storage and frame abstractions; too old to certify the present
SMP/VM implementation. Source mapping and its remaining chapters are pending.

## Literature Selection Queue

Admit original papers with a concrete current obligation, explicit assumptions
and inspectable mechanisms/evaluation. Record proposal-only work as such.
Discard irrelevant search results without inventing a quality verdict. Follow
primary citations for continuation representation and memory-order protocols;
search beyond the current inventory when those obligations remain unanswered.

First new completed artifact is `continuation_link_handoff`: two negative
counterexamples, six positive reachable states with progress checked. It is
finite contract evidence only; no new runtime patch, native GC pass, bootstrap
pass or performance improvement is claimed in this reading ledger.
