# InitSpec and Next-GC Layout: Source and Literature Ledger

Reviewed: 2026-10-20. Selected source/literature correspondence only. See the
[design](init-spec-segment-layout-design.md),
[constructor inventory](init-spec-constructor-inventory.json),
[net-benefit matrix](init-spec-segment-layout-cost-matrix.md) and
[trace map](init-spec-segment-layout-traceability.json). No implementation,
native test, compiler regeneration, model/engine/solver/prover execution,
checked proof or measured economic result.

## Selected Source Evidence

| ID | Anchors / selected spans | Observation and boundary |
| --- | --- | --- |
| IS-S01 | [C pair/vector builders](../../../vendor/gambit/lib/mem.c#L1744). mem.c 1744--1818. | Helpers initialize actual CAR/CDR or every vector slot after allocation and before return. Inputs have explicit nonmovable/still-reference restrictions. Helper return can finish this safe data structure without finishing a wrapper-specific protocol. |
| IS-S02 | [Inline allocate/init macros](../../../vendor/gambit/lib/_kernel.scm#L44), [Scheme vector/string/U8 builders](../../../vendor/gambit/lib/_kernel.scm#L2419). _kernel.scm 44--115/2419--2515. | Allocation and fill macros are separate. Large branch decrefs before fill; vector saves/restores fill and normalizes absent to fixnum zero. String/U8 omit fill when absent. Small alignment may advance hp without writing a filler header. GC scan safety and native no-fill representation are separate questions. |
| IS-S03 | [Weak table builder](../../../vendor/gambit/lib/_system.scm#L1366), [weak scanner](../../../vendor/gambit/lib/mem.c#L4039). _system.scm 1366--1441; mem.c 4039--4092. | Builder initializes flags/counts/slots only after allocation; its small branch tentatively advances hp before a possible GC. Scanner reads flags and mutates weak-list links. A provisional hp reservation is not a valid initialized object, and fields need their actual subtype rules. |
| IS-S04 | [Bignum builder](../../../vendor/gambit/lib/_num.scm#L7893). _num.scm 7893--8047. | Saves k/x/complement in PSTATE saved slots before potentially collecting, reloads them afterward, then fills actual target-width digits/sign extension. Small path has tentative hp/check behavior. Pointer-free scan policy does not erase semantic completion. |
| IS-S05 | [Still-copy](../../../vendor/gambit/lib/_kernel.scm#L2365), [statistics](../../../vendor/gambit/lib/_kernel.scm#L3995). _kernel.scm 2365--2407/3995--4055. | still-copy reloads ARG1 after allocation, copies full body, then decrefs. Statistics fills 20 F64 fields before decref/RESULT. Generic subtype/native-copy qualification and effects of metric queries are not proved by either endpoint. |
| IS-S06 | [Foreign builder](../../../vendor/gambit/lib/c_intf.c#L5148), [foreign release](../../../vendor/gambit/lib/c_intf.c#L1683). c_intf.c 5148--5197/1683--1715. | Header allocation, native tags/function/pointer stores, result publication and release callback are separate stages. Fields are cleared before invoking release_fn; this is not proof of exactly-once external effects or any new GC tracing of tags. |
| IS-S07 | [S64 conversion](../../../vendor/gambit/lib/c_intf.c#L4350), [F64 conversion](../../../vendor/gambit/lib/c_intf.c#L4627). c_intf.c 4350--4410/4627--4681. | Allocated numeric branches fill payload before *obj; immediate/self-tagged alternatives do not allocate. Size/target/configuration and error mapping belong to InitSpec, not a fixed one-size native builder. |
| IS-S08 | [String conversion](../../../vendor/gambit/lib/c_intf.c#L5409), [composite string list](../../../vendor/gambit/lib/c_intf.c#L5733). c_intf.c 5409--5689/5733--5807. | Encoding-specific success stores *obj after fill; several paths release construction reference on postallocation encoding failure. List creates a string, completes a pair, then releases str/old lst. Native input storage must remain valid across reads; no arbitrary input mutation is admitted. |
| IS-S09 | [UDP builder/result](../../../vendor/gambit/lib/os_io.c#L11085). os_io.c 11085--11133. | Absent-buffer path reads native bytes, allocates, memmoves, decrefs and returns the object. Existing-buffer path mutates and returns a count. No input-effect rollback follows from allocation failure. |
| IS-S10 | [Stack-marker wrapper](../../../vendor/gambit/lib/c_intf.c#L6511). c_intf.c 6511--6562. | make_vector safely fills #f; wrapper then stores closure/proc and processor ID before publishing marker. Source TODO explicitly identifies proc_or_false protection across allocation. Invalidation clears field then decrefs. This is an unclosed root obligation, not a newly reproduced fault. |
| IS-S11 | [Target constants](../../../vendor/gambit/gsc/_t-c-1.scm#L108), [reserve/check construction](../../../vendor/gambit/gsc/_t-c-2.scm#L344), [cons emitter](../../../vendor/gambit/gsc/_t-c-2.scm#L2607), [vector emitter](../../../vendor/gambit/gsc/_t-c-2.scm#L2728). _t-c-1.scm 108--120; _t-c-2.scm 344--417/2607--2635/2728--2847. | Target reserves words including float-cache materialization, schedules checks and emits vector BEGIN/ADD/END/GET. Compiler threshold is 4096 source words. This supports exporting check/completion semantics from Scheme; it is not a proved universal maximum write span. |
| IS-S12 | [Allocation macros](../../../vendor/gambit/include/gambit.h.in#L3133), [pair/vector macros](../../../vendor/gambit/include/gambit.h.in#L5316), [heap check](../../../vendor/gambit/include/gambit.h.in#L8542), [saved roots](../../../vendor/gambit/include/gambit.h.in#L8059). gambit.h.in 3133--3168/5316--5326/8542--8565/8059--8086. | ___ALLOC increments hp; pair macros write header/fields before END. CHECK_HEAP tests strict hp>limit; the inspected m argument is unused. Saved-root macros write/read actual PSTATE cells. C macro spelling alone provides neither runtime reservation nor independent root authority. |
| IS-S13 | [Allocator body obligation](../../../vendor/gambit/lib/mem.c#L1487), [still allocation](../../../vendor/gambit/lib/mem.c#L1554). mem.c 1487--1500/1554--1739. | Caller initializes body before next allocation. Still allocation links before final metadata/body; release decrements. Raw allocation return has no universal semantic endpoint and cannot qualify unseen external clients. |
| IS-S14 | [Copy/forward](../../../vendor/gambit/lib/mem.c#L3495), [chunk closure](../../../vendor/gambit/lib/mem.c#L3240), [destination scanning](../../../vendor/gambit/lib/mem.c#L4250). mem.c 3495--3665/3240--3313/3388--3410/4250--4386. | mark_array reads a pointed-to old header, CASes forwarding before body copy in the inspected parallel branch, fills destination and publishes chunk work later. Word-width padding and FORW links are real grammar. Forwarding visibility alone is not copy-completion proof. |
| IS-S15 | [Half definitions](../../../vendor/gambit/lib/mem.c#L2194), [flip/setup](../../../vendor/gambit/lib/mem.c#L3410), [GC body](../../../vendor/gambit/lib/mem.c#L6938). mem.c 2194--2198/3410--3464/6938--7086. | Setup flips perprocessor half offsets and resets copy state; GC captures old hp/fp/statistics before setup and subtracts new occupancy after phases. Independent persistent workers/contexts require VM epoch/layout authority replacing those ownership assumptions. |
| IS-S16 | [RC roots](../../../vendor/gambit/lib/mem.c#L3969), [register/saved roots](../../../vendor/gambit/lib/mem.c#L6511), [GC setup/strong/weak/cleanup](../../../vendor/gambit/lib/mem.c#L6776). mem.c 3969--3986/6511--6538/6776--6935. | Strong phase traces actual roots, then reachable work; selected vendor mark_rc is P0-only. Weak/wills, continuation move and cleanup follow. There is no unconditional old-prefix-as-root loop in this selected path. Full root domain remains governed by prior adapter/worker studies. |
| IS-S17 | [Runtime fudge constants](../../../vendor/gambit/lib/mem.h#L12), [resume limits](../../../vendor/gambit/lib/mem.c#L4525), [heap slow path](../../../vendor/gambit/lib/mem.c#L7415), [heap handler](../../../vendor/gambit/lib/_kernel.scm#L301). mem.h 12--79; mem.c 4525--4571/7415--7505; _kernel.scm 301--341. | Runtime F=8193+SUBTYPED_BODY, whole-section fallback and approximate trigger limits differ from compiler scheduling threshold. Handler preserves continuation/register state and routes to check-heap. Bounds exceptions alone do not preserve these Scheme semantics. |
| IS-S18 | [Occupancy](../../../vendor/gambit/lib/mem.c#L360), [capacity macros](../../../vendor/gambit/lib/mem.c#L488), [shrink](../../../vendor/gambit/lib/mem.c#L956), [GC reduction](../../../vendor/gambit/lib/mem.c#L6259). mem.c 360--370/488--509/956--997/6259--6300. | Movable charge doubles cursor occupancy; reductions use processor ownership; free-space and assigned-section counters are policy views. Shrink physically frees list-tail sections. Neither arbitrary interval liveness nor percontext allocation attribution is supplied by replacing a processor count. |

Ten selected working-source files are bound by exact hash. The constructor
inventory records source positions and proposed completion obligations; its
JSON is document metadata, not a generated executable verifier or runtime
descriptor. Selected literal/macro families are not full preprocessing/build/
external-client closure. Current vendor and research HEAD metadata are retained
in the immutable design-artifact record; unrelated staged/dirty changes are
preserved.

## Primary Sources

| ID | Reference | Narrow support / limit |
| --- | --- | --- |
| IS-P01 | [Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §2, frontend/backend discussion. | PVM carries source meaning while the backend supplies target representation/primitive/calling details. Supports explicit semantic/native separation and target negotiation; does not specify new InitSpec, segment or modern GC protocols. |
| IS-P02 | [Marlow et al., Parallel Generational-Copying Garbage Collection with a Block-Structured Heap](https://simonmar.github.io/bib/papers/parallel-gc.pdf), §§2.1, 3.1--3.3. | Root evacuation, forwarding, private destination allocation and pending destination scans have distinct roles. Supports not equating old region membership with reachability. Paper layout/ordering choices and measured gains do not transfer to Gambit. |
| IS-P03 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§1.3, 4.4. | Safe-point/C-interface choices constrain collector design; coordinated movement and parallel forwarding require explicit protocols. Motivates preserving Gambit's participant/FFI contracts rather than importing OCaml generations/barriers or benchmarks. |
| IS-P04 | [OCaml C interface manual](https://ocaml.org/manual/5.3/intfc.html), §§4.4, 5.1--5.2. | Distinguishes initialized allocation from low-level fill-before-allocation, registered roots and postallocation mutation. Supports constructor-specific readiness/roots; its tags and mutation rules are not Gambit specifications. |
| IS-P05 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts), relocation sequences and derived pointers. | Root maps and relocated values must be used coherently with the chosen collector. Compiler support does not define object-start validity, initialization completion, segment lifetime or a maximum allocation burst. |
| IS-P06 | [Zig undefined](https://ziglang.org/documentation/0.15.1/#undefined), [lifetime/ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership). | undefined is not a language mechanism for readable unspecified Scheme data; programmer still owns pointer lifetimes. Typed local construction can reduce support, but cannot establish roots, complete callbacks or reclaim public storage automatically. |
| IS-P07 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §5.1.2.4. | Actual native synchronization orders producer initialization/metadata before consumer reads. A struct copy, volatile cursor or assumed mixed-language atomic representation is not such evidence. Use a qualified opaque ABI or establish the native mapping. |

Actual publication/manual versions in source URLs identify evidence, not an
architectural generation. No benchmark, pause/RSS saving or maintenance-hour
number is imported from these references.

## Interpretation Boundary

Current source does not implement InitSpec/SegmentLayout or prove their full
producer/check domain. Marker TODO, no-fill semantics, generic still-copy,
target bounds, copied-work publication, diagnostic traversal, exact public
counter refinement and all exceptional exits remain admission gaps. The design
provides conditional implications and logical counterexamples only. Static
JSON/trace/hash/link/span review and D2 rendering are document checks; registered
research declarations/views, runtime/model/proof results and historical failures
are not rewritten or adopted.
