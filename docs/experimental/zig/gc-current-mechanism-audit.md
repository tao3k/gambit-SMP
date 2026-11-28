# Current Gambit GC: Source-Mechanism Audit

Design-only source/configuration review. No configure, preprocessor, Scheme,
compiler, native test, model or performance execution. Exact selected files,
configuration artifacts and references are in the
[evidence ledger](gc-native-runtime-evidence.md) and
[trace map](gc-native-runtime-traceability.json).
Research checkout HEAD: 1a2d8612f2065387c62858e10baf63ce369cc48c.
Vendor Gambit HEAD: 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882.

**Finding: the reviewed C runtime path is a nongenerational full tracing
collector for movable objects, using sectioned semispaces and copying, together
with mark-and-sweep for still objects. Its multi-threaded-VM branch implements
coordinated stop-the-world collection with parallel copying/scanning. Header
generation tags and C-target SSB hooks do not establish an active young/old
generational algorithm.** This is a conclusion about the selected source, not
an observation of a loaded runtime binary or every historical Gambit variant.

## Mechanisms Actually Present

| ID | Source observation | Mechanism / conclusion and limit |
| --- | --- | --- |
| CA01 | mem.c documents permanent, still and movable objects [GC-S01] | Permanent objects are neither moved nor reclaimed and may reference only permanent objects; still objects do not move and are mark/swept; movable objects are copied/compacted. Still/permanent are not synonymous with an old generation. |
| CA02 | Msections are split into halves; fromspace_offset derives from tospace_offset, and setup flips them [GC-S02] | Small heap allocation and Scheme stack/frame allocation use section space. At collection the destination half is rebuilt; this is not age-based promotion. |
| CA03 | MAKE_HD_WORDS/BYTES create MOVABLE0; mark_array copies the original header and follows/publishes forwarding [GC-S03] | Reachable movable objects stay in the same effective generation class when copied. MOVABLE1/2 occur only in header declarations/comments in the searched vendor C/header/template/Scheme domain. No survivor aging or selective older-generation collection is implemented by these paths. |
| CA04 | Pair/vector/box/closure/global mutation macros perform direct stores; C simplifier explicitly disables its SSB reservation branch with if #f [GC-S04] | These inspected writes have no generational remembered-set barrier. This is appropriate to the reviewed full trace, not proof of a remembered-set implementation. Queue memory-order barriers and GC forwarding CAS have different purposes. |
| CA05 | Inline dynamic constructors choose small movable allocation versus alloc_scmobj; alloc_scmobj chooses permanent when ps=NULL and still otherwise [GC-S05] | Native API allocations differ from generated Scheme fast allocation. Still refcounts temporarily keep native-held objects reachable; that does not make Scheme memory reference-counted. Body initialization remains the caller's obligation. |
| CA06 | garbage_collect calls on_all_processors; the sync loop executes the operation before returning to Scheme; GC phases have BARRIER cuts [GC-S06] | Participating Scheme mutators rendezvous, perform setup/strong/weak/cleanup/resize and resume. Parallel collector workers here are processors participating in the stop, not an independent collector pool running alongside those mutators. Foreign/parked-thread completeness is a separate obligation. |
| CA07 | Parallel mark_array uses forwarding CAS; completed chunk FIFOs can be stolen; scan_workers_count and a condition variable detect scan completion [GC-S07] | Parallel GC machinery exists in source. It is incorrect to say Gambit has no multicore GC support at all. Correctness, scalability and qualification of a configured native profile are not established by this audit. |
| CA08 | Every strong phase calls global, continuation, register, saved, type-cache and processor scans; VM/symbol/RC scans are assigned specially [GC-S08] | This is full-root tracing each collection, not a young-only root/remembered-set pass. PSTATE register/saved storage is explicit root storage, not automatic native-stack discovery. |
| CA09 | Captured stack frames may be copied to heap frames; active/captured scanners distinguish RETN and RETI; weak phase moves continuations [GC-S09] | Continuation frame links, saved values and descriptors are collector inputs. A new collector cannot replace this by scanning Zig call stacks or only following procedure closure environments. |
| CA10 | still setup roots externally referenced objects, strong/weak phases process wills, cleanup frees unmarked still objects and invokes foreign release [GC-S10] | Weak/will/foreign-finalization semantics are part of GC. Invoking an arbitrary destructor on a new independent worker is not automatically legal. |
| CA11 | rc_head is PSTATE-local; register_rc uses that head; strong phase calls mark_rc only in processor-0 branch; marker creation has an explicit protect-proc TODO [GC-S11] | Complete cross-owner root custody cannot be presumed. Resolve actual caller/ownership closure and redesign registration/scanning/protection; this audit does not reproduce an actual lost-root crash. |
| CA12 | Current selected materialized Darwin header/config.status default to MULTIPLE_VMS, SINGLE_THREADED_VMS and MAX_PROCESSORS=1 [GC-S12] | Independent VM capability, same-VM parallel participation and SMP scheduler capability are separate. Header defaults can be overridden by compilation definitions. The sample is another materialized source lineage and does not identify the loaded runtime or qualify vendor SMP branches. |

The negative generational conclusion is not based only on a missing keyword.
CA02/03 establish destination rebuilding and unchanged survivor headers;
CA04 establishes inspected writers; CA08 establishes collection root/phase
selection. Together they support the reviewed source algorithm classification.
The bounded literal search covers vendor/gambit C, headers, .in templates and
Scheme sources for MOVABLE1/2; external modules, unreviewed alternative runtimes
and actual compiler defines remain outside its conclusion.

## Concrete Configuration Evidence Boundary

The inspected sample is
`../ci-source-patch-check/src/gambit/` relative to this research checkout.
Its header SHA-256 remains
`c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58`.
config.status lines 1114–1116 name the three defaults above; the header's
conditional defaults are at 1451–1506. No preprocessing or build was performed.
The earlier [Darwin ledger](darwin-configured-input-evidence.md) records its
different materialized Git lineage; these bytes must not be relabeled as a build
of the current vendor HEAD. Runtime archive identity, actual defines, installed
binary, loaded module and native behavior remain unresolved.

## Chez and OCaml Comparison

| ID / axis | Reviewed Gambit source | Chez reference | OCaml reference | Design consequence |
| --- | --- | --- | --- | --- |
| CC01 Allocation and generations | Sectioned movable heap plus still/permanent strategies; no active aging shown | Age-based generations and configurable collection/promotion schedule [GC-P01] | Domain-local minor allocation and shared major heap [GC-P02] | Define actual young/mature boundaries and promotion policy, not just header constants. |
| CC02 Survivor treatment | Copy preserves header class | Older objects can be collected less frequently [GC-P01] | Minor survivors evacuate to major [GC-P02] | Select one explicit candidate policy; do not call current section flipping promotion. |
| CC03 Mutation | Inspected direct stores and inactive SSB branch | Generation-aware storage policy needs inter-generation tracking; manual is not a complete barrier implementation proof | Mutation/initialization rules and runtime APIs are explicit [GC-P04] | Establish complete writer closure, including FFI, bulk and CAS paths. |
| CC04 Parallelism | Parallel STW source path, processor-associated work | Documented thread rendezvous suspends other active threads; do not infer concurrent mutators or parallel collector scalability from this manual [GC-P01] | Parallel STW minor and concurrent major [GC-P02/P03] | Generation, parallelism and concurrency are distinct choices. |
| CC05 Control and roots | Active/captured frames plus explicit roots and dynamic-state semantics | General Scheme control must remain valid; this comparison imports no binary frame model | Fiber switching participates in major-mark invariants [GC-P03] | Specify continuation activation/root epochs and scanner ownership. |
| CC06 Foreign interface | Still protection, RC payloads, native markers and native-control boundaries | Foreign integration cannot be inferred from generation count | Local/global roots, mutation and acquire/release rules are documented [GC-P04] | Make foreign participation and root-write semantics first-class. |
| CC07 Engineering cost | Existing algorithms and interfaces are real assets; couplings and selected coverage gaps are real work | Mature reference, not a drop-in implementation | Explicit compatibility/latency/throughput tradeoffs [GC-P03] | Compare full modernization paths in C and Zig; neither gets the algorithm for free. |

The [proposed architecture](gc-native-runtime-design.md) selects a full
generational/multicore candidate. It does not implement that candidate or claim
the current collector is inferior on every workload.
