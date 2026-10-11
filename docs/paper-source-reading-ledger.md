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

Use the integrity-checked `.data/papers/<id>/` cache. New primary sources are
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

## HotSpot Parallel GC (2001)

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
Sections 4-4.5 and 5 onward are not yet systematically read; do not attribute
their algorithms or measurements to the selected source. The local PDF is a
revised version noting a measurement correction, which matters for later review.

## Boehm: Benign Races (2011)

Sections 1, 2.1-2.5 and 3 read. The concrete obligation is source-level
synchronization, not merely a plausible machine interleaving. Map publication
to `SYNC_SEND_MSG`, fast `SYNC_GET_MSG`, the two continuation-link writers and
GNU CAS/barrier definitions. A fence or `volatile` declaration alone does not
establish portable exclusion. Same-value writes and disjoint-bit assumptions
also need an actual protocol. This is not proof that GCC16 miscompiled Gambit;
inspect its selected primitives and generated code before such a claim.

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
