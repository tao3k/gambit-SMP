# GC Architecture Evidence Ledger

Selected working-source/configuration review and primary literature only.
Source/configuration hashes and exact spans are bound by
[traceability](gc-native-runtime-traceability.json).
Paths are relative to vendor/gambit unless an external materialized sample is
explicitly named. No source expansion, preprocessor or native execution.

| ID | Anchors / spans | What they support |
| --- | --- | --- |
| GC-S01 | [mem.c allocation classes](../../../vendor/gambit/lib/mem.c#L60), 60–86, 141–147; [limits](../../../vendor/gambit/lib/mem.h#L10), 10–79 | Permanent closure invariant, movable/still distinction, section/fudge/size limits. |
| GC-S02 | [mem.c section layout](../../../vendor/gambit/lib/mem.c#L395), 395–430, 2194–2198; [flip/setup](../../../vendor/gambit/lib/mem.c#L3410), 3410–3469 | Split sections and destination setup for current copying algorithm. |
| GC-S03 | [header generation constants](../../../vendor/gambit/include/gambit.h.in#L2951), 2951–2971, 3256–3257; [mark_array](../../../vendor/gambit/lib/mem.c#L3490), 3490–3665 | Only MOVABLE0 constructor use in these paths; copying preserves header. Bounded vendor text inventory separately records MOVABLE1/2 declaration-only matches. |
| GC-S04 | [direct stores](../../../vendor/gambit/include/gambit.h.in#L4231), 4231–4231, 5328–5329, 5452–5452, 5480–5485, 5838–5838, 5953–5958, 6758–6769, 8337–8349; [SSB](../../../vendor/gambit/gsc/_t-c-2.scm#L3356), 3356–3365, 3735–3738, 3839–3844, 4107–4110 | Selected mutation and CAS routes, inactive SSB reservation. Queue memory ordering is not a generational writer barrier. |
| GC-S05 | [kernel allocation/init](../../../vendor/gambit/lib/_kernel.scm#L43), 43–115; [native allocators](../../../vendor/gambit/lib/mem.c#L1487), 1487–1500, 1556–1738, 1744–1810 | Small/large and permanent/still routes, initialized refcount, caller initialization and native nonmovable-input restrictions. |
| GC-S06 | [sync operation](../../../vendor/gambit/lib/setup.c#L1012), 1012–1042, 1049–1115, 1130–1204; [barrier macro](../../../vendor/gambit/lib/setup.h#L63), 63–67; [GC phases](../../../vendor/gambit/lib/mem.c#L6990), 6990–7085 | Coordinated operation entry, stop/phase/resume protocol and conditional single-thread versus parallel branches. |
| GC-S07 | [forwarding](../../../vendor/gambit/lib/mem.c#L3536), 3536–3610; [queue publication](../../../vendor/gambit/lib/mem.c#L3251), 3251–3310; [work/termination](../../../vendor/gambit/lib/mem.c#L6667), 6667–6773 | Actual collector parallelism mechanisms; no independent-worker profile or native scalability result. |
| GC-S08 | [roots](../../../vendor/gambit/lib/mem.c#L6511), 6511–6650; [strong phase](../../../vendor/gambit/lib/mem.c#L6813), 6813–6870; [PSTATE roots](../../../vendor/gambit/include/gambit.h.in#L11607), 11607–11644 | Active root families and per-processor versus special ownership. |
| GC-S09 | [captured-frame copy](../../../vendor/gambit/lib/mem.c#L3667), 3667–3805; [active/frame scan](../../../vendor/gambit/lib/mem.c#L3898), 3898–3955, 4096–4148; [weak phase](../../../vendor/gambit/lib/mem.c#L6872), 6872–6910; [Scheme transfer](../../../vendor/gambit/lib/_thread.scm#L4623), 4623–4706, 4908–5078 | Current continuation representations, maps, movement and dynamic transfer. |
| GC-S10 | [still scan](../../../vendor/gambit/lib/mem.c#L4210), 4210–4250; [still cleanup](../../../vendor/gambit/lib/mem.c#L4387), 4387–4452; [wills](../../../vendor/gambit/lib/mem.c#L4997), 4997–5120; [foreign release](../../../vendor/gambit/lib/c_intf.c#L1683), 1683–1727; [foreign contract](../../../vendor/gambit/doc/gambit.txi#L19006), 19006–19045 | Weak/finalization and at-most-once foreign-object release intent, not native thread/effect safety or per-resource exactly-once proof. |
| GC-S11 | [RC ownership](../../../vendor/gambit/lib/mem.c#L278), 278–306, 675–743, 815–828, 3969–3996; [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562 | PSTATE-local RC registration versus processor-0 scan; unbarriered data assignment; pre-allocation protection TODO. Actual caller closure remains open. |
| GC-S12 | [materialized header](../../../../ci-source-patch-check/src/gambit/include/gambit.h#L1451), 1451–1506; [config.status](../../../../ci-source-patch-check/src/gambit/config.status#L1114), 1114–1116; [prior lineage ledger](darwin-configured-input-evidence.md) | Concrete sample defaults and separate lineage, not current vendor compilation/loaded archive. Bindings include header/config.status/config.log/gambuild-C.unix hashes. |
| GC-S13 | [PSTATE memory](../../../vendor/gambit/include/gambit.h.in#L11340), 11340–11449; [VM accounting](../../../vendor/gambit/include/gambit.h.in#L11478), 11478–11565; [GC entry](../../../vendor/gambit/lib/mem.c#L6938), 6938–6990; [resume](../../../vendor/gambit/lib/mem.c#L7428), 7428–7505 | Coupled collector/context state and capacity/rebase obligations. Reuse the prior CollectorWorkContext/RootTransfer/InitSpec research, not a new proof from field names. |
| GC-S14 | [real map](../../../vendor/gambit/lib/gambit/list/list.scm#L850), 850–929; [frame meaning](../../../vendor/gambit/gsc/_gvm.scm#L78), 78–105; [completion/checks](../../../vendor/gambit/gsc/_t-c-2.scm#L344), 344–448, 1318–1420 | Actual higher-order/suspended-root users and semantic completion versus C emission. |

| ID | Primary reference / locator | Bounded use |
| --- | --- | --- |
| GC-P01 | [Chez storage management](https://cisco.github.io/ChezScheme/csug10.0/smgmt.html), §13.1 | Generations/promotion policy and documented rendezvous. Not a complete Chez parallel collector implementation audit. |
| GC-P02 | [OCaml parallel runtime](https://ocaml.org/manual/5.3/parallelism.html), §3 | Domain-local allocation, parallel minor, concurrent major design; no benchmark transfer. |
| GC-P03 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§1.1–1.3, 3.2, 4.4, 5.4 | Collector/barrier/participation and fiber invariants motivate explicit obligations. Project design below is not the paper's verified algorithm or an inherited termination theorem. |
| GC-P04 | [OCaml C interface](https://ocaml.org/manual/5.3/intfc.html), §§4–5, 12 | Initialization versus mutation, registered roots and released/acquired runtime participation; Gambit must define its own contract. |
| GC-P05 | [LLVM GC integration](https://www.llvm.org/docs/GarbageCollection.html), Abstract/Goals; [statepoints](https://www.llvm.org/docs/Statepoints.html), relocation concepts | Compiler metadata/barrier hooks help, while runtime GC/roots/registration remain project work. No stock-Zig automatic moving-GC integration. |
| GC-P06 | [Gambit PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §2 | Bidirectional representation/call feedback supports common contracts; does not describe or qualify this current collector. |
| GC-P07 | [Zig ownership reference](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership), ownership/allocator and error-cleanup sections | Native support can use explicit ownership, compile-time construction and local cleanup; no root/epoch/memory-model theorem. |

## References With Incomplete Content Access

The [IU record for Don't Stop the BIBOP](https://scholarworks.iu.edu/dspace/items/bcc807ca-2087-4917-b246-7f00471fea1d)
confirms the 1994 Dybvig/Eby/Bruggeman report. The PDF was reachable, but text
extraction was corrupted and requested interior-page screenshots failed.
Its detailed barrier algorithm is therefore **not adopted as reviewed evidence**;
Chez claims above use the readable official manual.
The Gambit inside-out PDF returned access-denied HTML, and a historical
maintainer mail fetch failed. Search snippets are not used to qualify the
current implementation. These gaps do not block the source audit.

All new architecture choices, conditional arguments and cost formulas are
project proposals. Selected source spans/hashes and papers do not establish
native correctness, complete writer/foreign closure, finite pause/progress,
runtime admission or positive net benefit.
