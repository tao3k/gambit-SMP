# Still Construction and Tail Handoff: Evidence Ledger

Reviewed: 2026-10-20. Static selected-source and primary-literature research.
Read the [design](still-construction-tail-design.md),
[cost matrix](still-construction-tail-cost-matrix.md) and
[trace map](still-construction-tail-traceability.json). No implementation,
preprocessing/regeneration, native test, model/engine/solver/prover execution,
checked proof, measured speedup or memory result is adopted.

## Selected Source and Actual Caller Ledger

| ID | Source anchors and exact selected spans | Observation / limit |
| --- | --- | --- |
| SC-S01 | [API](../../../vendor/gambit/lib/mem.c#L1487), [allocator](../../../vendor/gambit/lib/mem.c#L1554). mem.c 1487--1500/1554--1705. | Caller must initialize still body before next allocation. Demand is STILL_BODY+rounded payload words. Small actual allocations defer accounting; larger paths precharge or invoke GC, then may fail native allocation and undo charge. Still list link precedes remaining metadata/body readiness. Existing synchronous/processor participation must not be replaced by an unproved concurrent scanner. |
| SC-S02 | [Refcount](../../../vendor/gambit/lib/mem.c#L1443), [public wrapper/release](../../../vendor/gambit/lib/mem.c#L1712). mem.c 1443--1481/1712--1739. | Increment/decrement operate on a count; release_scmobj calls decrement. Neither function physically frees the still block or refunds VM quota. ps=NULL selects permanent allocation and is outside the proposed still cohort. |
| SC-S03 | [Scan registration](../../../vendor/gambit/lib/mem.c#L4210), [sweep/force free](../../../vendor/gambit/lib/mem.c#L4387), [reduction](../../../vendor/gambit/lib/mem.c#L6259), [deferred flush](../../../vendor/gambit/lib/mem.c#L6794). mem.c 4210--4249/4387--4453/6259--6300/6794--6807. | Nonzero-refcount entries seed scanning; sweep frees unmarked storage, invokes FOREIGN release and recomputes surviving words. Force cleanup does not preserve refcount-pinned entries. Processor reductions/flushes describe actual storage; they do not carry asynchronous dormant grants. |
| SC-S04 | [String converters](../../../vendor/gambit/lib/c_intf.c#L5420). c_intf.c 5420--5495. | ISO-8859-1 allocation is followed by payload writes; UTF-8's second pass has a post-allocation error path that releases the construction reference and returns an encoding error. This is selected real failure evidence for distinguishing decrement from unused-credit refund, not a reproduced malformed-input test. |
| SC-S05 | [UDP result construction](../../../vendor/gambit/lib/os_io.c#L11085). os_io.c 11085--11142. | The absent-buffer path reads native bytes, allocates a U8VECTOR, copies bytes, releases its construction reference and returns it. Native input effects and storage publication are distinct; this source does not prove external cancellation is reversible. |
| SC-S06 | [Weak-table construction](../../../vendor/gambit/lib/_system.scm#L1370). _system.scm 1370--1441. | Large objects allocate still storage with W_ALL/R_ALL, decrement before flags/counters/unused-slot initialization; small objects take a different movable path. This caller requires a subtype-specific initialization endpoint, not a generic allocator-return hook. |
| SC-S07 | [Subtype scan](../../../vendor/gambit/lib/mem.c#L4008). mem.c 4008--4148. | FOREIGN/string/unboxed numeric payloads are skipped. Weak scan reads flags, selected key/value fields and list metadata. Frame/continuation scanning has structure. Garbage body bytes cannot universally be scanned; no change to existing FOREIGN tracing is inferred. |
| SC-S08 | [Foreign release](../../../vendor/gambit/lib/c_intf.c#L1683), [pointer constructor](../../../vendor/gambit/lib/c_intf.c#L5148). c_intf.c 1683--1715/5148--5197. | Constructor writes tags/function/pointer before result; release clears function/pointer before invoking native code. Destructor arming and unknown side effects need real ownership and all-exit disposition. Source clearing fields alone proves neither idempotent external effects nor affinity safety. |
| SC-S09 | [Pair/vector constructors](../../../vendor/gambit/lib/mem.c#L1744), [still-copy](../../../vendor/gambit/lib/_kernel.scm#L2365), [statistics](../../../vendor/gambit/lib/_kernel.scm#L3995), [numeric conversion](../../../vendor/gambit/lib/c_intf.c#L4350). mem.c 1744--1818; _kernel.scm 2365--2428/3995--4035; c_intf.c 4350--4410. | Pair/vector helpers restrict movable inputs; still-copy saves/reloads then copies from the restored source and decrements. Pointer-free numeric/statistics constructors still require semantic completion. A source Scheme declaration does not automatically make a raw native temporary GC-safe. |
| SC-S10 | [Aligned allocator/free](../../../vendor/gambit/lib/mem.c#L559). mem.c 559--671. | Extra alignment/container-pointer storage and a recovered underlying container distinguish native allocation identity from still body/base. Logical word accounting cannot be reported as RSS. Deallocator pairing must be retained across private abort and later sweep. |
| SC-S11 | [Candidate donor transfer](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160). Patch 3160--3242. | Existing C splices actual still/RC chains, transfers counters, resets donor accounting and destroys source queue facilities after stated join/drain conditions. Credit actual support; this is not an implemented independent-worker interval transfer or a native receipt adopted by this study. |
| SC-S12 | [Chunk closure](../../../vendor/gambit/lib/mem.c#L3250), [marker reserve](../../../vendor/gambit/lib/mem.c#L3388), [copy alignment](../../../vendor/gambit/lib/mem.c#L3495), [chunk parser](../../../vendor/gambit/lib/mem.c#L4250). mem.c 3250--3313/3388--3410/3495--3568/4250--4386. | FORW chunk links, two end-marker slots, word-width-sensitive copy alignment and partial scan cursors are real layout facts. Tail reuse must retain chunk parser/borrower semantics or replace the adapter explicitly. A gap is not a valid object merely because it is unused. |
| SC-S13 | [Section selection](../../../vendor/gambit/lib/mem.c#L3066), [stack/heap sharing](../../../vendor/gambit/lib/mem.c#L3314), [resume preparation](../../../vendor/gambit/lib/mem.c#L4525). mem.c 3066--3128/3314--3387/4525--4571. | Whole-section selection, stack fallback/sharing and approximate limits assume processor-owned cursors. They cannot remain authoritative for arbitrary nonoverlapping interval grants without a new bounds/layout mapping. |
| SC-S14 | [Constants](../../../vendor/gambit/lib/mem.h#L12), [occupancy](../../../vendor/gambit/lib/mem.c#L360), [policy capacity](../../../vendor/gambit/lib/mem.c#L488), [initial assignment](../../../vendor/gambit/lib/mem.c#L3410). mem.h 12--79; mem.c 360--370/488--509/3410--3464. | M=131072, active halves M/2, F=8193+SUBTYPED_BODY, allocation-check/fudge description and doubled movable policy charge have different roles. Native extent, policy charge, useful tail and reserve are not interchangeable quantities. |
| SC-S15 | [GC phases/preparation](../../../vendor/gambit/lib/mem.c#L6813), [still demand policy](../../../vendor/gambit/lib/mem.c#L6368). mem.c 6813--7086/6368--6472. | Strong tracing is followed by weak/continuation/cleanup/policy/resume work; still requested words can remain charged on success or be removed on recoverable overflow. The proposed credit/recount service replaces implicit synchronous lifetime assumptions, not copying/weak policy semantics. |

Selected bindings cover mem.c/mem.h, c_intf.c, os_io.c, _kernel.scm,
_system.scm and the candidate fixture. The fixture is a selected working-source
artifact, not an applied configured build. Constructor queries included the
explicit public/native call spellings in these files and os_dyn.c/_num.scm;
the ledger binds only the ranges used above. No transitive/generated/external
caller census is claimed. The trace binds exact current selected hashes.

## Primary Literature and Platform/Language Evidence

| ID | Primary reference | Narrow support / excluded inference |
| --- | --- | --- |
| SC-P01 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §5.1.2.4. | Release/acquire synchronization can order initialized stores before consumer reads. Volatile/list-pointer stores and data-layout resemblance alone do not qualify C/Zig cross-language publication. One opaque service ABI or a proven native mapping is required. |
| SC-P02 | [Marlow et al., Parallel Generational-Copying Garbage Collection with a Block-Structured Heap](https://simonmar.github.io/bib/papers/parallel-gc.pdf), §§3.1--3.3, Figure 2. | Forwarding/copy claims, private tospace allocation blocks and incomplete scan work are distinct responsibilities. Motivates explicit worker tails and borrowers; neither GHC block layout nor its performance transfers to Gambit. |
| SC-P03 | [OCaml manual, Interfacing C](https://ocaml.org/manual/5.3/intfc.html), §§4.4, 5.1. | Safe high-level allocation initializes traced fields; low-level allocation requires legal initialization before another allocation. Local/parameter roots are explicit. This supports separate scan-safe and semantic initialization, not importing OCaml tags, generations, barriers or macros into Gambit. |
| SC-P04 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §4.4. | Root coordination, stop-the-world entry and copying races are separate modernization duties. Runtime GC changes must preserve language/FFI behavior; switching the systems language does not discharge them. No OCaml collector or benchmark claim is adopted. |
| SC-P05 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts). | Compiler relocation/root support needs a runtime protocol and correct use of relocated references. It does not manage still credits, constructor effects, heap intervals or shutdown. LLVM/MLIR compiler benefits are available to both modern C and Zig service implementations. |
| SC-P06 | [Zig lifetime/ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership), [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer). | Explicit allocators and local error cleanup may reduce private builder support; pointer lifetime remains programmer responsibility. errdefer cannot legally refund a Consumed grant, free a published root, cancel a live native writer or replace GC rooting. |

Links include actual publication/manual identities for reproducible evidence;
these are not architectural generation names. Paraphrases support design
premises only. No timing, speedup, pause, RSS or maintenance-hour number is
imported from a paper into the net-benefit conclusion.

## Qualification Boundary

SCU observations are source facts in the selected slice. SCP implications and
SCX counterexamples are handwritten logical reasoning, not machine-checked
proofs or executed failure witnesses. Source arithmetic distinguishes possible
tail reuse from a guarantee that actual sections can be removed. Raw allocator
effects, final safepoints, external clients, generated allocation checks,
mixed-language ABI visibility, exact segment parser and all-exit progress remain
unresolved. Historical receipts, registered research declarations/views and
unrelated staged/dirty work are neither rewritten nor adopted.
