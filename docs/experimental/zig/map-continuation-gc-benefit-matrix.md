# Map Continuation GC: Work Eliminated and Work Added

Research quantities and conditions, not benchmark results. Scope is the
[source-composed map history](map-continuation-gc-design.md), including captured,
shared, possibly mutated frames. No implementation/native experiment, labor
forecast or architectural generation naming is introduced.

CB01. The benefit is narrower and more defensible than “modern GC makes map
faster.” An unchanged mature saved continuation can avoid repeated evacuation
and complete minor traversal, while active stack roots, first materialization,
promotion, major tracing and actual replay remain real work. The source has
lazy capture and restore-by-copy mechanisms worth retaining. Learning from
OCaml helps expose the associated barriers and scan/activation races; its
measured performance is not a Gambit prediction. [CG02–CG13; CL01–CL05]

## Benefit and Overhead Matrix

| Work / capability | Current selected source mechanism | Conditional elimination in the proposed runtime | Added or retained runtime burden | Positive region / falsifier |
| --- | --- | --- | --- | --- |
| Repeated movable object/frame copying | Full collection flips/copies reachable movable data; heap frames participate | Mature nonmoving payload avoids subsequent whole-copy events | First promotion, mature allocation/mark/sweep, fragmentation and forwarding metadata | Same live payload survives several baseline copies; short survival or early forced promotion can erase the gain |
| Saved mature frame minor traversal | Full continuation/frame traversal with normal/internal maps | Unchanged mature saved graph need not be recursively scanned at every minor; inspect roots plus dirty sources | Complete remembered frame/denv/alias writes, stable source leases, dirty dedup/drain/reset | Large retained graph, few dirty slots; frequently mutated graph or conservative fallback scan yields little saving |
| Capture fast path | Stack-backed capture with later GC materialization | Preserve deferred frame copying; no general new elimination credited | Capture/segment ownership and stabilization debt; possible earlier materialization at major/handoff cuts | Many captures die or return without forced stabilization; eager copying can regress that case |
| Continuation sharing | GC forwarding shares frame instances; shell copy shares frame/denv | Preserve one materialized identity for aliased dynamic frames | Dynamic identity/forwarding metadata and mutation/scan coordination | Repeated captures share live frames; equal static layouts alone cannot justify coalescing |
| Ordinary replay | Break handler copies saved frame to active stack | No blanket removal of frame restoration or repeated output construction | Root handoff, denv/cache barriers, wind/reentry checkpoints, destination capacity | Keeps general Scheme behavior; one-shot consumption or destructive result reuse fails semantics |
| Managed mutation | Selected direct pair/global/continuation/frame writes and inactive SSB | Classify private init, immediate/nonpointer and proven already-remembered/snapshotted cases | Young-edge remembering, major deletion protection, atomic/access protocol, retries and bounded queues | Read/allocate-heavy workload with limited published mutation; write-heavy cases may lose |
| Active root scanning | Register/saved arrays, active/break frames and native roots | No assumed elimination of active/restored root scans each minor | Acknowledgement, descriptors, native carriers and major root-value snapshots | Many minor cuts with little live active stack; deep retained active map frames may dominate |
| Mature major marking | Current full trace has no selected concurrent mature phase | Move some mature work off mutator pauses when a qualified concurrent algorithm permits | Mark traffic, root snapshot/close cuts, locks/epochs, pacing, weak processing and floating garbage | Sufficient overlap and bounded producer debt; no finite pause improvement follows merely from concurrency |
| FFI / blocking | RC/still/markers and current ownership couplings | Stable protected mature values can avoid movement, under a real lifetime contract | Root adoption/write/withdraw, blocking participation, native copies/pinning and owner restoration | Long-lived rooted payload benefits; raw pointers or uncooperative native work keep the profile unresolved |
| Peak space | Sectioned copying plus still/permanent storage | May reduce repeated-copy reserve for admitted mature data | Young promotion reserve, mature fragmentation, snapshots/logs, stack leases and retained code/tasks | Must compare total retained capacity; nonmoving is not automatically smaller |

## Quantification Without Invented Workload Numbers

CB02. Fix a declared semantic history H, object identities, retained roots and
the same valid language behavior. Current and candidate GC trigger schedules
can differ; do not equate their collection counts. For object/frame payload i,
let b_i be bytes in the declared accounting convention, k_i(H) its actual
baseline copy count and p_i(H) its candidate promotion-copy count. In the
selected direct-promotion/nonmoving-mature design, p_i is at most one **for
that object identity**, excluding execution-stack restoration copies.

`payload copy bytes avoided = sum_i b_i * (k_i - p_i)`.

For a cohort known to be copied k_i≥1 times in the baseline and promoted once,
this reduces to `sum_i b_i*(k_i-1)`. Objects forced into mature storage while
k_i=0 contribute a negative term. First stack-to-frame materialization,
restore copies, headers, padding, rejected parallel destinations and metadata
are separate terms unless explicitly included in both sides. Never count the
same frame materialization again as an extra baseline evacuation saving.
[CE02–CE04, CE07; CG05–CG08]

CB03. Let F_j be mature saved-frame/root-slot visits that a full traversal
would perform at minor event j for the declared comparison, D_j the distinct
dirty/remembered saved-frame slots visited by the candidate, and N_j the newly
materialized/promoted-frame slots processed. The local traversal opportunity
is `sum_j (F_j - D_j - N_j)`, with baseline/candidate event correspondence
declared rather than assumed. Add active/restored root visits separately.
No captured-frame writes and no new frames imply D_j=N_j=0, so an existing
mature graph can contribute zero **recursive minor frame visits**. Its root
classification, major visits and any subsequent activation still cost work.
If full fallback scanning is required, the selective-scan saving is zero.
This is a counterfactual traversal budget at declared cuts unless an actual
baseline schedule is matched; it is not automatically the old runtime's total
scan count. Slot visits also exclude per-frame/dirty-entry access overhead,
which must be charged separately.

CB04. For the selected header template, normal map RETN fs=5 produces a
captured FRAME body of fs+1=6 words plus one header: 7 words, while the
aligned execution-frame space is 8 words. A map RETI encoded caller size 8
decodes to fs=17: captured body 18 plus header 1, versus stack space 20 words.
These are bounded source arithmetic examples, assuming the supported
no-handles representation at that materialization path. They are not native
ABI/word-width observations or a fixed size for every captured callback frame.
They demonstrate why logical frame count, stack reserve and copied bytes must
have separate ledgers. [CE03–CE04, CE06; RD01]

CB05. Use a time model that charges every new mechanism. Over H, define:

`G = avoided_copy_time + avoided_full_traversal_time + other_admitted_savings`.

`A = added_promotion/materialization_time + barrier/access_time + log/root_time
     + phase/wait_time + added_major_time + added_restore_time
     + other_measured_runtime_cost`.

Theoretical positive total-time condition is `G > A`, with no double-counted
terms. Use one explicit ledger: G contains gross eliminated baseline work and A
contains incremental candidate work. If CB02's already-net copy-byte difference
is converted to a net time contribution instead, do not charge that same
promotion again in A. Separate byte movement from field classification/tracing,
and retained baseline restoration from extra candidate restoration. An interval
argument is robust only if `lower(G) > upper(A)` under its
declared workload, capacity, scheduler and native participation assumptions.
With no such bounded inputs the positive region is a condition, not an admitted
whole-runtime result. For a normalized whole-program form, old GC fraction f,
candidate GC ratio q and net extra non-GC work a give `Tnew/Told = 1-f+f*q+a`;
time gain requires `a < f*(1-q)`. Byte savings alone cannot determine q or a.

CB06. Serial time, pause distribution, parallel throughput and peak memory are
independent admission coordinates. A lower total GC work count can still have
a longer start-cut pause; a shorter pause can require more CPU/space. Queue
contention, outstanding work/lease debt, publication rates and foreign response
must support a progress bound before claiming predictable latency. This source
study supplies no positive numeric runtime lower bound or finite-pause theorem.

## Workload Regions and Research Decision

| Region | Expected mechanism-level result | What would refute the benefit claim |
| --- | --- | --- |
| Small map, trivial callback, little retained data | Few repeated baseline copies to remove; barriers/metadata can dominate | Claiming an unconditional speedup or constant-space conversion |
| Long-lived captured map frames across many allocations/minors, few frame mutations | Strong opportunity to eliminate repeated mature copying and minor graph traversal | Missing frame/denv/native writer, repeated forced full scan, or excessive major/snapshot/access costs |
| Mostly dead young allocation with modest live roots | Bump allocation and young-only tracing can avoid full mature work | Promotion too aggressive, root scans dominate or collector triggering differs enough to reverse total work |
| Deep active map stack retained through many cuts | Saved mature graph benefits may coexist with expensive repeated active root scans | Crediting removal of O(n) pending Scheme work or all roots |
| Heavy frame/heap mutation, serialization, frequent replay | Dirty/root/access work and restore copies are substantial | Treating shared frames as immutable or making their real writers free |
| Blocking/raw foreign callbacks | Benefits depend on complete root/owner/participation rules | Reclaiming young storage or finishing a major phase before the native producer is safe |

CB07. Proceed with the full generational/runtime contract as a serious research
direction, while preserving Gambit's own lazy/multi-shot/FFI strengths. Generated
C makes the semantic/native seam concrete; it does not itself deliver G or
erase A. Zig or LLVM can realize some products later under the same obligations.
Implementation-agent availability changes how work may be produced; runtime
overhead, semantic completeness and capability value determine this decision.

## Caller-Specific Break-Even Refinement

The [writer benefit matrix](continuation-writer-benefit-matrix.md) charges
path-dependent parameter-cache updates, generic binding writes, reconstruction,
scheduler transfers and native root policy. It gives a conditional cut-count
threshold with per-family write rates and separate root-cell savings; no
frequency is inferred from source counts. The
[caller matrix](continuation-writer-caller-matrix.md) preserves active,
reader-commented, conditional and unknown domains.
