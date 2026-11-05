# Repair-9 TFIB: verified producer/crash binding and GC refinement envelope

2026-10-22, Asia/Shanghai. Research only; native acceptance remains **8/12**. This supersedes the *unbound identity frontier* in [the initial TFIB note](smp-repair9-tfib-sigsegv.md), without changing that historical observation. It does not supersede the native DENY or establish a runtime fix. No gsi execution, compilation, full-inventory retry, runtime/framework edit, debugger attachment, signal, peer operation or push occurred.

## The failing generation is now identified

| Link | Verified identity / evidence |
| --- | --- |
| Failed inventory | `.cache/tasks/repair-9-12/fixtures/bazel-profile-gc-ffi-inventory-vector-inc-1`; outer receipt SHA256 `a7a82f57d46e2ecb56819873bcc59a9099c5f42588b869f1fc389a8676804bce`; actual child receipt retains candidate/runtime/numeric/official PASS, stress-gsi TIMEOUT, stress-gsc/PR BLOCKED and aggregate DENY |
| Completed producer | `bazel-profile-numeric-host-vector-inc-build-4`, `source-core` successful checkpoint; outer SHA256 `863d68a9801082f65f64e86b14b528a9152898796356d8bd38aad627821a9ea1`, child SHA256 `e7c7b40b451573fe5798de0a570b33272379d4a84193c0a5d4d31de0a61ed898`; both bytes rehashed |
| Engine | `07dcb21b9892f1763c60173372a5b0af5306a290230de607b6ddb78c3ca0f34c`; runtime step records a pinned completed generation, not a new build |
| Imported runtime archive | SHA256 `e78a85b19fa32f67fcd40cb886c550b170b421eca11c984b82b60f2a14080a97`; archive checkpoint equals consumer runtime checkpoint; embedded outer/child receipts and runtime identity agree with the retained completion records |
| Actual gsi bytes | SHA256 `5620dd70a28f46765551c07742bfc4b5877096008900f9addd486d90de1bf5ad`; archive member matches recorded runtime identity and member manifest |
| Mach-O image UUID | `c823a9d8-418b-35f6-88bf-1330cef04de5`, parsed directly from those binary bytes; matches the crashed image UUID |
| Crash report | `gsi-2026-10-22-220949.ips`, SHA256 `e9bb6cef875592274760fac02afa5645023a68309cc49a11dd874f46a3bda413`; retained exact-byte copy in audit output |
| Process correlation | Crashed PID **66761**, parent **66760**. The retained finished shard process record has PID 66760 and the exact original TFIB-first argv. Crash launch **22:08:15.4931**, capture **22:09:49.1350** (+08:00), approximately 93.642 seconds. The child signal and 93.6-second suite boundary agree. The eventual killed shard is a separate -9 observation. |

`research --read` reports CURRENT identity/binding and VERIFIED history for the failed run while retaining DENY. The workspace key `4463d6b5…` is a location shared by generations; it is **not** a binary identity and does not identify the older failed gsi `1e0e62b0…`. Investigation uses selected immutable archive members copied into the audit output, not the currently mutable producer checkout. Source-lock SHA256 is `5bae9868fb9c8598003424582dc4b963fafbff8d2ae263ae3339f4cf3b1dd80f`, patch SHA256 `22f484851632b7b086c8d0a31a7c8fddc6a94ea99f465f1eb87ec61bb721da3d`.

The retained processor probe says **11**. The parent test driver used `-:p1` for the driver, while `run-unit-tests.scm` starts its gsi test child with its own original settings. Neither this report nor the model changes native topology. The crash contains ten reported native thread records; do not substitute either that count or the model's two abstract workers for the producer configuration.

Machine-readable [binding and provenance](../evidence/research/smp-retirement-study/tfib-crash-binding.json) contains the complete SHA identities and immutable reference paths. Original captured material: `.cache/tasks/repair-9-12/processes/audit/runs/f41ad62f11d049ee96c824b3a4587878/outputs/tfib-crash-binding/`.

## Exact fault: invalid object-header read inside mark_array

The report identifies `EXC_BAD_ACCESS / SIGSEGV`, faulting thread index 5, `mark_array +104`. Image base `0x1005d4000` + image offset `0xfd50` gives actual PC **`0x1005e3d50`**. Offline disassembly of the matching gsi gives link PC `0x10000fd50`:

| Link address | Instruction | Source meaning |
| --- | --- | --- |
| `0x10000fd40` | `ldr x0, [x0]` | Read the selected scan cell's word |
| `0x10000fd48` | `tbz w0, #0, …` | Skip values not considered memory allocated by this compiled tag test |
| `0x10000fd4c` | `and x0, x0, #0xfffffffffffffff8` | Remove the low three tag bits |
| `0x10000fd50` | **`ldr x25, [x0]`** | Read the presumed object's header; this is the fault |

Captured x0 and FAR both equal **`0x3f947ae147ae1478`**. This maps semantically to the bound `lib/mem.c:3685–3686`, `body = ___BODY0(obj); head = body[-1]`, through the actual header macros. It is not a TFIB arithmetic fault, a demonstrated join failure, or the previous generated-stack-store crash. The object's old header cannot have been inspected at this point: the dereference itself failed.

The valid IEEE-754 bit pattern of **0.02** is `0x3f947ae147ae147b`; clearing its low three bits gives exactly the captured address. This is a **mask-equivalence witness**, not proof that the missing scan cell contained that exact double or that its origin was the quantum field. Four odd-tagged preimages share that address. The report does not retain the selected cell, enclosing heap object, scanner extent, original pointer word or Scheme frame memory. The OS's generic “possible pointer authentication failure” text does not establish a PAC mechanism defect; arbitrary high bits used as a pointer can produce that wording.

The reported stack is `mark_array +104`, `mark_array +780`, `thread_start +8`. It is incomplete optimized unwind information. In this exact disassembly the +780 address follows a call to `end_heap_chunk`; it cannot be promoted into a proven recursive mark_array caller or an identified root category. Other thread records show GC mark/scan work and chunk-publication waits, supporting the GC context without identifying the bad word's original writer. Bound `mem.o` has text/constant/unwind sections and no DWARF sections; no new compiler or symbol-generation build was run.

Checked existing locations: no core at `/cores/core.66761`, `/cores/66761` or `/cores/core`; the failed-run tree has no matching retained `.core`/`.ips`/`core.*` file. This is a bounded negative search, not a claim that every host/archive was searched. Exact crash-report bytes and available registers/stacks were retained. No live process was inspected.

## Source chain: established guards versus remaining premises

All line references below are to the **archive-bound source**, not the moving checkout. The correspondence is semantic/source inspection plus binary instruction identity, not a full DWARF proof.

| Mechanism | Actual source and established local property | Remaining premise / consequence |
| --- | --- | --- |
| Thread construction | Generated `_thread.c:14119–14157` writes a 37-word structure's fields, then advances the allocator; defaults include safe immediates. `_thread#.scm` describes those defaults. | The direct generated constructor is not simply publishing an uninitialized list of thread fields. Correct reservation, current allocation generation and absence of an earlier escaped write remain separate obligations. Thirty-seven body words plus header require **38 words**. |
| Thread floats | Generated C:14165–14175 allocates a 7-element **F64** vector, fills raw double values and installs its *tagged object reference* in thread slot 16. `gambit.h:8475–8478` emits the F64 subtype and raw elements. | Double payload words are not Scheme references. A structurally valid typed scan must not pass these raw words to mark_array. The saved report does not identify this vector as the offending container. |
| Type-directed heap scan | `mem.c:4188–4189` explicitly excludes F64 vectors/flonums from pointer-field scanning; generic structure/vector references are scanned separately. | An intact F64 header with correct object boundaries already skips payload. Adding the same skip again is not a causal repair. Wrong/stale header, wrong boundary, or an earlier overwrite could violate the premise; none is identified yet. |
| Frame scan | `mark_continuation -> mark_frame` uses frame size/link/GC map; `mem.c:4012/4034` passes only selected contiguous pointer-slot runs to mark_array. Register/saved/type-cache/RC roots also independently call mark_array. | A bad GC map, stale frame/return descriptor or wrong saved root can route a non-reference to the same fault. No retained caller frame selects one of these routes. |
| Collective entry | `setup.c:execute_sync_op`, OP_GARBAGE_COLLECT -> `___garbage_collect_pstate`; strong-root phase visits VM roots, RC, globals, continuation, registers, saved/type-cache and processor object. | A valid full cohort and correct current root ownership must cover the interval, not just the instant of a call. |
| Root copying and work publication | `mem.c:7290ff` already has a root-copy completion barrier before `mark_reachable_from_marked`. In mark_array, forwarding CAS precedes body copy; `end_heap_chunk:3402ff` writes the marker, publishes FIFO links under lock with explicit barriers; consumers lock/barrier before taking chunks. | Early forwarding is legal if no consumer scans incomplete payload. Adding a generic barrier or moving CAS blindly is not justified; establish the first publication/scan ordering violation if this branch is implicated. C/assembly memory-order and all alias paths remain refinement obligations. |
| Last scanner and root consumers | `mark_reachable_from_marked:7073ff` manages active scan ownership/work; Scheme save/restore, wakeup and join consume frames/results after queue operations. | Queue empty is not “scanner returned.” Frame/result roots must remain current until their last actual consumer, including the next GC epoch. Existing retirement models concern a related lifetime cut but do not certify this native TFIB path. |

This narrows the failure to **a non-dereferenceable value accepted at a GC object-header read**, with raw-scalar provenance a strong but unproved lead. It does not yet locate the first corrupting write or prove a particular GC algorithm defect. Existing pointer-field values could have been overwritten, a frame/map could be stale, or a scanner extent/header could be wrong. Source-correct guards do not rule out earlier memory corruption.

## Source-corresponding QNT and what it proves

[The finite GC/handoff model](../models/gambit/tfib_gc_handoff.qnt) and [importing trajectories](../models/gambit/tfib_gc_handoff_tests.qnt) represent a pointer-bearing thread/frame, a non-pointer scalar payload, constructor safe defaults, the concrete 38-word write footprint, allocation generation, parked/handoff/caller root owners, forwarding-before-copy, scan-work publication, in-flight scanner completion, unique execution ownership and **two real GC epochs**. The two workers are an abstraction of cohort participation, not a reduced native test. No arithmetic is performed on the full 64-bit float in TLC; the exact host-side bit calculation binds the symbolic raw-scalar class to the observed mask witness.

All **19 checks accepted**: typecheck; normal two-epoch safety/conditional completion (63 distinct states); allocation-failure retention (2 states); **12 decoded mutation counterexamples**; four explicitly selected TypeScript trajectories. The model's weak-fairness premise is explicit. Retained allocation failure is not normal success. Original 30-second combined limits/check, 12 TLC workers, 1 GiB heap, 8 MiB stack and compiler/capture limits remain unchanged.

| Negative initializer | Distinguishing missing condition |
| --- | --- |
| initWrongMask | A raw scalar is selected for an object-header load |
| initPublishedUninitialized | An exposed object's scan-visible fields lack safe defaults |
| initEarlyChunk | A scanner starts on a forwarded but uncopied destination |
| initLostRoot | Parked work has no remaining GC-visible owner |
| initStaleFrame | A real second epoch leaves the frame's reference version stale |
| initQueueEmptyIsDone | Completion is declared while the final scanner has not returned |
| initStaleEpoch | First-epoch acknowledgement is accepted for the second epoch |
| initDuplicateExecutor | Both workers become the frame's execution owner |
| initLostResultRoot | The caller/result handoff loses its last root before consumption |
| initWrongHeader | Exposure uses metadata that does not preserve typed scanning |
| initUnreservedBurst | The actual 38-word constructor burst exceeds its reservation |
| initStaleAllocation | Numeric bounds fit, but allocation generation belongs to another writer |

These controls state **necessary protocol premises**, not twelve discovered native bugs. Several, such as correct F64 dispatch and default initialization, are already locally visible in source. Others, particularly actual scan-cell provenance, reservation ownership, frame/map validity and complete memory-order correspondence, are not established by the crash report. The positive model assumes these premises; it does not prove all existing C paths implement them. Constructor write bounds are represented explicitly; arbitrary GC to-space sizing, C integer overflow, full frame-map decoding, every object subtype, native memory races and 11-worker refinement are outside this finite envelope. It reuses the source/last-consumer concepts of the retirement work without claiming a composed proof of the large shutdown model whose IR compilation remained blocked.

The allocation-generation control rejects a stale writer even when numeric bounds fit. This also constrains repair review: blindly ignoring an unknown tagged value can lose a reachable reference; that is not modeled as a successful recovery. A range test alone cannot establish current allocation ownership. Neither shortcut supplies a fundamental fix. A real repair must restore the object's type/extent or root/frame/allocation ownership before the invalid value reaches the header load.

## Minimal next decision and root-cause closure boundary

The existing crash report cannot recover missing heap/frame memory. The next **implementation-lane** diagnostic, if separately authorized there, should retain the first rejected header-read context, using the existing GC diagnostic context rather than introducing a new framework: pstate/GC epoch; root category/call site; scan start/length/current cell; containing object's old header/type/length or frame/RA/GC-map; original tagged word; allocation/section identity/generation; forwarding and chunk-publish/scanner-owner state. Failure remains failure; do not clamp/skip/retry or relabel it PASS. No such runtime edit or run is performed here.

Choose the small refactor only after that witness identifies the broken edge:

* Incorrect field mask/extent/GC map: correct the specific layout descriptor or scan interval, preserving raw F64 versus Scheme-pointer types.
* Stale frame/root/allocation: repair the exact save/restore/publication ownership and lifetime cut; a range test or global lock alone does not establish current generation.
* Scan before copy/root closure: close the specific work-publication/last-scanner ordering gap; existing CAS, root barrier and FIFO barriers must be accounted for rather than replaced by assumption.

The first writer and this branch selection remain **open**. The production gate requires the original TFIB and interrupt2, the declared stress modes and remaining inventory under unchanged budgets, plus preservation of the first eight and Gerbil qualification. This research provides an identified failure, a narrower source frontier and executable controls for repair review; it does not promote 8/12.


## 2026-10-23 Entry-level diagnostic refinement

The [mark_array entry and first-fault contract](smp-repair9-mark-array-origin.md) now enumerates all 29 direct calls plus the implicit copy-tail cursor transition. The pair fast path bypasses scan(), and goto again may leave the original root while scanning a copied heap field; old category/line/body fields cannot resolve these alone. Pre-cell and pre-header committed records, frame/map intervals, independent original/current provenance, a bounded crash-surviving carrier and conditional writer-generation/range/order correlation are specified at concrete functions. No collector or diagnostic implementation is changed. The new observation QNT passes 29 checks (three positives, eighteen decoded controls, seven named trajectories, typecheck), while the prior 19-check runtime-envelope evidence stays on its own hash. The actual missing TFIB scan cell and first writer remain unresolved; native stays 8/12.
