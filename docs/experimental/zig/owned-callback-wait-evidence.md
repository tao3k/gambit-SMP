# Owned Callback / Participating Wait Evidence

Reviewed: 2026-10-20. Research HEAD b67da6262a973a0ae898002d5c7f5be2d8b5a90d;
Gambit HEAD 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882. Working-copy hashes
are bound by the research view and design-update-11 receipt. Baseline vendor
source, overlays, installed SDKs and historical native receipts are distinct.
No implementation, native/compiler test, timing or engine run.

## 1. Gambit Source Reads

| ID | Source anchor | Fact and bounded implication |
| --- | --- | --- |
| OW01 | [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm):2902-2955,3144-3222; [header](../../../vendor/gambit/include/gambit.h.in):10043-10067 | Generator passes MLBL for c-define and FAL for converter; three SFUN result variants initialize marker before conversions. Family count is not a user-site census. Static label representation/module lifetime and raw Scheme arguments need independent profile proof. |
| OW02 | [mem.c](../../../vendor/gambit/lib/mem.c):278-306,674-827 | RC list belongs to ps.mem; alloc_rc_no_register initializes native refcount=1/data=FAL; register links into current ps list; release/addref and data writes are plain operations. RC payload bytes are not a declared Scheme-root array. |
| OW03 | [mem.c](../../../vendor/gambit/lib/mem.c):3490-3600,3969-3986,6839-6863 | mark_rc updates header.data through mark_array; strong phase calls it only in P0 block, followed by each processor's ordinary roots. Bounded function-name search found only this mark_rc definition/call; no all-list walk or rehome established. This is not a whole-program nonzero-caller failure proof. |
| OW04 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1630-1668,2887-2940,3220-3245; [os_dyn.c](../../../vendor/gambit/lib/os_dyn.c):744-769 | String/function conversions use RC for different payloads. Dynamic closure allocates under implicit PSTATE and puts proc in header.data; the conversion's explicit ps does not itself prove that implicit selector matches. Require agreement, not universal byte-payload tracing. |
| OW05 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6562; [mem.c](../../../vendor/gambit/lib/mem.c):1487-1502,1563-1727,1778-1817 | Nonnull-ps marker vector uses still allocation; slow/frequent-GC branch calls garbage_collect before marker fields are filled. Direct proc/thunk may survive only via another root whose slot is updated; the local copy still needs reload. TODO is an obligation, not a reproduced failure. |
| OW06 | [os_dyn.c](../../../vendor/gambit/lib/os_dyn.c):637-675,744-791,1045-1059; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6533-6539 | Architecture-guarded trampoline writes global c_closure_self; source TODO requests TLS; marker reads it after allocation. No arm64 branch in this generator. No claim that GC itself reenters here; other processors/global identity and platform support remain independent concerns. |
| OW07 | [header](../../../vendor/gambit/include/gambit.h.in):8622-8627,8692-8784; [os_thread.c](../../../vendor/gambit/lib/os_thread.c):697-709; [setup.c](../../../vendor/gambit/lib/setup.c):805-825,6380-6407 | Single-thread selector/explicit args/TLS binding depend on profile. thread_set_pstate sets optional self binding, real PSTATE and affinity at startup/setup. Bounded vendor search found BEGIN/END_PSTATE_BIND definitions and field/init, no macro call sites; no nested-entry restoration proof. |
| OW08 | [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1019-1071; [header](../../../vendor/gambit/include/gambit.h.in):9979-10002,10043-10060 | call builds fp/R0/marker return frame; configured trampoline/host TRY catches; unmatched destination/error rethrows. Kernel checks processor and marker validity; SFUN error handler can call Scheme again; lexical cleanup cannot assume all transfers are ordinary returns. |
| OW09 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):4505-4524,1428-1475; [mem.c](../../../vendor/gambit/lib/mem.c):6511-6538 | Select and sync-op wrappers both materialize RA/W_ALL and reload; interrupt-vector[0] selects sync-op service. Existing register/saved root scanners are reusable under a real nesting/liveness plan. |
| OW10 | [setup.c](../../../vendor/gambit/lib/setup.c):65-91,1012-1150; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):245-301 | Request sets flag/stack trip and aborts select. Stack handler routes to Scheme interrupt handler; collective service loop executes GC/resize, resets sync flag in protocol and can throw P0 error. Not a generic no-throw lock helper. |
| OW11 | [os_io.c](../../../vendor/gambit/lib/os_io.c):930-1040,1146-1168,1468-1555,11493-11584; [header](../../../vendor/gambit/include/gambit.h.in):6221-6237,6256-6299; [os.h](../../../vendor/gambit/lib/os.h):755-778 | Native wait monitors abort endpoint in selected branches, drains and returns EINTR after readiness checks. os_condvar_select has cached Scheme arrays/raw device pointers and queue unlock/relock; ticket locks spin. No complete virtual-device/fdset/OS/lock closure or latency bound established. |
| OW12 | [_thread.scm](../../../vendor/gambit/lib/_thread.scm):2530-2547,6230-6245,6886-6891 | wait! maintains VM wait queue; thread-check-devices has processor queue lock/broadcast; startup idle loop enables interrupts. First two declare not-interrupts-enabled, so later checkpoint closure is still required. Wait queue is not collective membership. |
| OW13 | [mem.c](../../../vendor/gambit/lib/mem.c):6667-6755; [core evidence](runtime-root-participation-evidence.md):RG12 | Parallel mark queues/termination and prior root/entry/retirement designs constrain proposed per-processor RC scanning. Source change is not a one-line qualification and historical repaired fixtures do not qualify baseline. |
| OW14 | [os_io.c](../../../vendor/gambit/lib/os_io.c):856-904,3383-3421; [setup.c](../../../vendor/gambit/lib/setup.c):1204-1230 | Selected select/poll add_fd bodies set fd bits/poll entries without resizing or entering collective service. A pipe constructor instead invokes fdset_resize; that function can enter on_all_processors when capacity is insufficient. Device construction and descriptor admission therefore need an effect boundary; no claim that every add_fd services GC. Full virtual-method closure remains open. |

Search scopes were vendor/gambit/lib, include and gsc for named definitions,
callers and selector use; the binding search covered vendor/gambit. These are
bounded textual observations, not compiler-preprocessed/configured call graphs.
Opaque FFI bodies, client code, alternate overlays and installed libraries remain
outside this census. Source-backed risk is stronger than the earlier TODO-only
finding but is not current native reproduction.

## 2. OCaml 5 and Primary Literature

Local OCaml HEAD 46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91; VERSION file
5.5.1. Published manual below is 5.3. These identify separate readings, not one
coherent installed binary. Upstream web pages/PDFs were read, not executed or
captured as pinned source bytes.

| ID | Evidence | Transferable lesson and limit |
| --- | --- | --- |
| OO01 | [globroots.c](../../../vendor/ocaml/runtime/globroots.c):28-100,116-178 | Stable slot address, root-list mutation, scan/deletion and generational classification need coordinated rules. Plain refcount is insufficient; Gambit need not adopt a skip list or OCaml write barrier. |
| OO02 | [callback.c](../../../vendor/ocaml/runtime/callback.c):387-431 | CAMLparam protects values before named-value lock; old string address is discarded, then String_val is recomputed; root update/register occurs through dedicated helpers. Reuse the ordering principle, not the runtime layout. |
| OO03 | [threads.h](../../../vendor/ocaml/otherlibs/systhreads/caml/threads.h):31-73; [platform.h](../../../vendor/ocaml/runtime/caml/platform.h):80-108 | Domain lock and C-thread registration differ. Lock helper choice has STW/domain restrictions; root mutex deliberately uses a special helper. Neither all locks nor all callbacks are automatic release points. |
| OO04 | [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html), sections 5.1,5.3,7,12 | Updateable roots protect live values; released code must avoid managed access, and release/acquire can execute pending callbacks/asynchronous exceptions. Ordinary allocation is separately specified not to run OCaml code since 4.10. Do not infer callback effects from allocation or import these guarantees into Gambit. |
| OO05 | [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), sections 1.2-1.4,4.4 | C API memory-access assumptions constrain collector choices. Serial behavior, serial cost/pause and parallel pause/throughput are separate objectives. Design inference: change Gambit's semantic boundary explicitly, price migration, and do not borrow OCaml benchmark gains. |
| OO06 | [Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/), tagged union, exhaustive switching, error union, defer and lifetime | Private typed products/ordinary-return cleanup can reduce support expression. Pointer lifetime, GC slots and foreign nonlocal control still need design; modern C generated/opaque APIs and strict enum diagnostics are valid controls. See [paired language evidence](zig-vs-modern-c-evidence.md):P01-P04. |

OW/OO support the explicit obligations and alternative designs. The CS/OU/OM/OR/
OS identifiers in accompanying documents are proposed accounting/design units,
not automatically verified statements or counts of native coverage. The next
receipt records declaration hashes; no DSL evaluation, theoretical acceptance,
retirement or execution authority follows.

## 3. RC / Marker Follow-Up

[RC01-RC16 and RL01-RL05](rc-marker-caller-evidence.md) bind the existing cumulative patch, actual RC byte/closure/Tcl callers, saved-root primitives, direct run and retained retirement fixture. Earlier bounded baseline findings remain correct for B0; B1 already contains per-processor RC marking, RC/still transfer and target save/reload. Failed-join storage retention is kept separate from next-GC scan coverage. No old receipt is reissued, no duplicate implementation/model/native test is introduced.
