# Map Continuation GC Evidence

Selected working-source review, 2026-10-21. Research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; vendor HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact bytes/spans are bound by
the [trace](map-continuation-gc-traceability.json). No executed Scheme/GVM,
loaded native runtime, implemented collector or measured performance is claimed.

| ID | Gambit source anchor / spans | Observation and boundary |
| --- | --- | --- |
| CE01 | [public map](../../../vendor/gambit/lib/gambit/list/list.scm#L850), 735–816, 850–929; [stored C](../../../vendor/gambit/lib/_std.c#L74716), 74716–74992, 146100–146123 | Real callback-before-cdr, pending recursive result, post-CONS check and multi-list helper/sentinel paths. Stored C is not a reproduced current build. |
| CE02 | [capture](../../../vendor/gambit/include/gambit.h.in#L6589), 6589–6618; [graft](../../../vendor/gambit/include/gambit.h.in#L6654), 6654–6668; [return](../../../vendor/gambit/include/gambit.h.in#L6716), 6716–6742; [completion](../../../vendor/gambit/gsc/_t-c-2.scm#L4275), 4275–4320 | Stack continuation header/frame/denv, break frontier, thread denv/cache writes and native emission/control-context changes. This is not always an immediate full heap copy. |
| CE03 | [materialization](../../../vendor/gambit/lib/mem.c#L3667), 3667–3815; [active and heap readers](../../../vendor/gambit/lib/mem.c#L3817), 3817–3966, 4096–4148 | Stack-backed capture copying, forwarding sharing, FRAME allocation and GC map readers. Current STW copying code is a reference, not a concurrent major scanner. |
| CE04 | [break restoration](../../../vendor/gambit/lib/_kernel.scm#L1115), 1115–1280; [internal restoration](../../../vendor/gambit/lib/_kernel.scm#L1281), 1281–1346 | Stack/heap frame cases, heap-to-execution-stack copying, link replacement and RETN/RETI decoding. Saved-frame reuse differs from one-shot consumption. |
| CE05 | [continuation fields](../../../vendor/gambit/include/gambit.h.in#L5906), 5906–5931; [setters](../../../vendor/gambit/lib/_kernel.scm#L3145), 3145–3163, 3439–3558; [construct/copy/next](../../../vendor/gambit/lib/_kernel.scm#L3562), 3562–3727; [frame reconstruction](../../../vendor/gambit/lib/_io.scm#L11690), 11690–11727; [emission](../../../vendor/gambit/gsc/_t-c-2.scm#L4263), 4263–4273 | Real mutable fields/frame slots, shallow continuation shell copying, destructive cursor advance and serializer frame writer. Existing comments about link slots do not prove safe arbitrary structural edits. |
| CE06 | [frame construction](../../../vendor/gambit/gsc/_t-c-2.scm#L823), 823–916; [physical maps](../../../vendor/gambit/gsc/_t-c-3.scm#L471), 471–522; [header decoding](../../../vendor/gambit/include/gambit.h.in#L9206), 9206–9319, 1381 | Normal/internal root map construction, internal saved registers, frame reserve/alignment. Source arithmetic is not an observed native layout. |
| CE07 | [allocation classes](../../../vendor/gambit/lib/mem.c#L60), 60–86; [section flip](../../../vendor/gambit/lib/mem.c#L3410), 3410–3469; [copying](../../../vendor/gambit/lib/mem.c#L3490), 3490–3665; [phases](../../../vendor/gambit/lib/mem.c#L6990), 6990–7085; [pair/global stores](../../../vendor/gambit/include/gambit.h.in#L5328), 5328–5329, 6764–6771; [inactive SSB](../../../vendor/gambit/gsc/_t-c-2.scm#L3356), 3356–3365 | Selected full movable copying, still/permanent distinction, coordinated phases and real raw writers. Broader current-mechanism audit remains RD02; no active generational algorithm inferred from tags. |
| CE08 | [call/cc](../../../vendor/gambit/lib/_thread.scm#L4623), 4623–4706; [dynamic transfer/value delivery](../../../vendor/gambit/lib/_thread.scm#L4908), 4908–5078 | Actual continuation closure and wind/value operations; callbacks can reenter Scheme and allocate. Threaded implementation branches need their own configured admission. |
| CE09 | [root carriers](../../../vendor/gambit/lib/mem.c#L674), 674–829, 3969–3996, 6511–6650; [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562; [coordination](../../../vendor/gambit/lib/setup.c#L1049), 1049–1115; [existing patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), 3160–3234, 3433–3452, 4362–4385 | Actual roots, per-processor registration/scan concerns, pre-allocation marker TODO, synchronization and existing donor/per-processor work. Credit prior C work; patch text is not loaded-runtime evidence. |

| ID | Primary research or selected upstream source | Lesson and limit |
| --- | --- | --- |
| LP01 | [Retrofitting Parallelism onto OCaml](https://anil.recoil.org/papers/2020-icfp-retropar.pdf), §§1.2–1.3, 4, 5.4 | Study sequential/parallel/pause requirements, C-interface constraints and fiber scan/activation coordination. Historical collector alternatives are not both asserted as current OCaml. |
| LP02 | [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), one-shot continuation and stack implementation discussions | An explicit restricted control choice; Gambit's multi-shot contract needs its own restoration/lifetime proof. |
| LP03 | [R7RS](https://small.r7rs.org/attachment/r7rs.pdf), §§3.5, 6.10 | Repeated continuation invocation, dynamic-wind and no implementation mutation of prior map results on multiple returns; input mutation is outside valid map domain. |
| LP04 | [Selected OCaml memory.c](https://github.com/ocaml/ocaml/blob/5.3/runtime/memory.c#L161), write_barrier/caml_modify and atomic operations; [minor_gc.c](https://github.com/ocaml/ocaml/blob/5.3/runtime/minor_gc.c#L255), Cont_tag and remembered/local-root traversal | Concrete separation of old referent protection, young-source remembering, continuation promotion and root processing. Exact orders/representation are not transplanted into Gambit. |
| LP05 | [Selected OCaml major_gc.c](https://github.com/ocaml/ocaml/blob/5.3/runtime/major_gc.c#L1071), caml_darken_cont | Claimed continuation scanning with acquire/release coordination; special stack references require a protocol. Not proof of our proposed frame leases. |
| LP06 | [OCaml C interface](https://ocaml.org/manual/5.3/intfc.html), §12.2; [parallel GC manual](https://ocaml.org/manual/5.3/parallelism.html), §3 | Blocking/reacquire/heap access and parallel-GC boundaries provoke concrete Gambit FFI questions. Selected release documentation/source is not a local binary observation. |
| LP07 | [Feeley/Miller PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §2 | Front/back negotiation and logical object/frame abstraction motivate explicit compiler/runtime products, not duplicated semantics hidden in emitters. No historical speedup imported. |

| ID | Prior local design | Use / status |
| --- | --- | --- |
| RD01 | [Map generated C path](map-generated-c-design.md), [point inventory](map-generated-c-points.json) | Actual stored 22 return descriptors and proposed semantic/module path; no new backend implementation |
| RD02 | [Current mechanism audit](gc-current-mechanism-audit.md), [full collector candidate](gc-native-runtime-design.md) | Existing GC facts and proposed young/mature/worker/store/root policy; this study refines capture/mutation/snapshot choices |
| RD03 | [Native generated C contract](generated-c-native-contract.md), [shared services](native-service-support-design.md) | Scheme semantic authority, C policy implementation, RootRegistry/BarrierLog/ReleaseCoordinator responsibilities; labor estimates do not decide value |

The selected OCaml release tag and paper sections are external provenance, not
architectural version names for this project. Web source review supplies no
native admission. Source-composed scenarios, formulas and diagrams are inert
design reasoning; no solver or research engine was evaluated.
