# Root and Resource Closure: Source and Primary Evidence

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact working-file digests appear
in the trace map and design receipt. These are selected source reads, not an
installed Darwin profile, implementation qualification or executed proof.

## Source Ledger

| ID | Source / inspected anchors | Finding and limitation |
| --- | --- | --- |
| RC-S01 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):85-149 | Frame holds slots/regs/closed/live; closure-env liveness depends on captured variables. Reuse semantic representation; no proof of upstream liveness algorithm. |
| RC-S02 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):123-237,344-452,1038-1165,1320-1365 | CFUN args/frame/all-live map; heap/SSB/poll checks, dirty live materialization; branch/switch/jump check paths. Jump inline path exists; family coverage is not exhaustive primitive/helper coverage. |
| RC-S03 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):282-289,825-905; [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-532; [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1934-2014; [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9205-9318 | Logical bitmap -> normal/task/internal return -> IFD/OFD chunks -> header decode, RETI expansion. Supports explicit commuting-layout obligation; not every target's checked packing result. |
| RC-S04 | [mem.c](../../../vendor/gambit/lib/mem.c):3670-3815,3817-3991,6511-6541; [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):8059-8086 | Captured continuation copying, active frame bitmap scan, RC data-only scan, register/saved arrays. Save/restore reloads then clears temporary roots. Moving frame coordinates cannot be assumed immutable. |
| RC-S05 | [mem.c](../../../vendor/gambit/lib/mem.c):6573-6667,6777-6940,6998-7044 | VM/symbol/key/global/local root families; P0 RC in baseline; processor-index global partition; strong/weak/cleanup/resize phases. Target SSB code does not establish a current generational profile. |
| RC-S06 | [mem.c](../../../vendor/gambit/lib/mem.c):3255-3310,3408-3465,6255-6308,6667-6775 | Chunk publication with two ordered barriers, per-processor msections/queues, both scan counts=np, theft and idle termination; occupied-word reduction over processors. Cannot substitute worker count for every processor count; actual section membership must finalize after mutator acknowledgement. |
| RC-S07 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):2887-2942,6511-6565; [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1019-1071 | Static c-define host vs dynamic closure conversion; marker allocation before proc storage, explicit rooting TODO; native frame/return marker and foreign unwind matching. Source TODO is not a reproduced failure in the cumulative candidate. |
| RC-S08 | [mem.c](../../../vendor/gambit/lib/mem.c):674-827,3969-3991,4389-4450,4928-4937; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1715,1729-1810; [setup.c](../../../vendor/gambit/lib/setup.c):5900-5922 | RC register/data/refcount/cleanup; native strings and list release; still-object collector/shutdown calls arbitrary foreign release_fn, clearing fields before callback; public API function pointers prevent a closed downstream census. No atomic lifetime or successful-finalization guarantee follows. |
| RC-S09 | [tcltk.scm](../../../vendor/gambit/examples/tcltk/tcltk.scm):138-196,294-344 | Real retained Scheme vector in RC `data`, command invocation/deletion and Tcl-owned result-string release. Code registers a deletion callback; registration-NULL rollback, reentrant deletion and all native callers are not proved here. |
| RC-S10 | [os_dyn.c](../../../vendor/gambit/lib/os_dyn.c):636-675,744-794,913-930,1047-1058 | Architecture-gated dynamic C closure, RC-managed proc slot, global self pointer/thread-local TODO, explicit closure release. Static c-define and unsupported architecture combinations need separate treatment; no Darwin arm64 dynamic trampoline qualification. |
| RC-S11 | [os_io.c](../../../vendor/gambit/lib/os_io.c):3948-3973,4144-4158,4549-4565,6050-6066,6107-6122,10861-10922; [_io.scm](../../../vendor/gambit/lib/_io.scm):8318-8339,8487-8510,8582-8605; [_io#.scm](../../../vendor/gambit/lib/_io%23.scm):659-674,821-861 | TLS foreign wrapper/release cascade, server raw wrapper pointer, accept dereference; Scheme server port retains psettings containing tls-context. This is real normal-path retention, not native borrower closure or proof of use-after-free. Installed OpenSSL/custom release effects unqualified. |
| RC-S12 | [os_dyn.c](../../../vendor/gambit/lib/os_dyn.c):408-453,1067-1087; [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):6032-6044 | Dynamic module cleanup unloads tracked handles; foreign object stores raw release function/pointer. Neither is a record of all executing callbacks, suspended returns or decoder readers. Per-image reclaim is a new responsibility, not an existing qualified capability. |
| RC-S13 | [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3160-3234,3439-3465,4352-4395; [setup.c](../../../vendor/gambit/lib/setup.c):544-719,1014-1110 | Joined donor + borrower-drain precondition, RC/still-list transfer and nonzero processor scan repair; pending joins retained; existing collective priority/combining. Credit these repairs. No inference that retained failed-join storage is safe to enumerate or that this study reproduced native behavior. |

The local symbol census used alloc/register/data/addref/release RC, function
conversion/release, foreign release, dynamic module cleanup and TLS server uses
in the listed source trees. It identifies real path families, not every textual
caller or every downstream host. A complete release claim requires a declared
cohort and independent issuer/call-graph closure. Definitions exported through
`setup.c` are particularly explicit evidence that local grep cannot establish
closed-world completeness.

## Primary Readings

| ID | Reading / inspected scope | Evidence used and non-transfer boundary |
| --- | --- | --- |
| RC-P01 | [Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation, LFP 1990](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), abstract and section 2 | Front/back communication conveys register, call, closure and primitive information; motivates preserving semantic information at the boundary. Historical architecture, not today's full runtime law or a benchmark for this proposal. |
| RC-P02 | [LLVM Statepoints](https://llvm.org/docs/Statepoints.html), explicit relocation, base/derived pointers, stack maps and GC transitions | Root/relocation correspondence must include later SSA uses and bases. LLVM supplies mechanisms, not Gambit safepoint enrollment, collector or continuation proofs. Rolling reference, no installed adapter qualification. |
| RC-P03 | [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html), rules for local/global roots, custom finalizers and section 22.12.2 | Root registration must bracket collecting operations; runtime acquire/release can run callbacks; released intervals exclude managed access; custom finalizers have strict effects. Use as design evidence for explicit root/effect boundaries, not Gambit API equivalence. |
| RC-P04 | [Sivaramakrishnan et al., Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), section 4.4 | Synchronizing mutators, parallel promotion/forwarding and root work sharing are separate; balanced root counts do not ensure balanced reachable graphs. No GC policy or measured performance is transferred. |
| RC-P05 | [Official Tcl_CreateCommand manual](https://www.tcl-lang.org/man/tcl8.2.3/TclLib/CrtCommand.htm), clientData/deleteProc, replacement/deletion and NULL creation | Documents registration/deletion ownership edges used by the example. Historical API documentation matches source family, not local installed Tcl identity or a proof that deletion drains all active/reentrant aliases. |
| RC-P06 | [LLVM ORC resource removal](https://llvm.org/docs/ORCv2.html#how-to-remove-code) | ResourceTracker removes tracked code; the described API does not enumerate Gambit continuation/native-return/finalizer users. Runtime last-use must precede provider release. |
| RC-P07 | [Zig language reference](https://ziglang.org/documentation/0.15.1/), errdefer and Lifetime and Ownership | Ordinary error exits can share lexical cleanup; pointer lifetime remains programmer responsibility. No automatic affine handles, callback drain, GC roots, cross-thread memory proof or cleanup across arbitrary longjmp. Version identifies the inspected reference, not a proposed architecture name. |
| RC-P08 | [OpenSSL SSL_CTX_free manual](https://docs.openssl.org/3.4/man3/SSL_CTX_free/), description/warnings | Library refcount release can call configured session-removal callbacks. It does not retain an enclosing Gambit `___tls_context` allocation or establish its selected library effects. The local library/configuration is unqualified. |

The OOPSLA Float Self-Tagging paper search result was not used: the opened author
PDF endpoint returned an access-challenge page. Henderson's publication landing
page was reachable but its paper download failed; no new argument is attributed
to unseen paper contents. Source/other inspected primary evidence suffices for
this slice. Public pages remain read-time references, separate from local tool
and runtime identities.

## Evidence Classification

Source facts: RC-S01--S13. Literature/platform constraints: RC-P01--P08.
SC/UC/GW tables, local bitmap induction, resource pin-transfer argument,
worker-role architecture and economics are project deductions/proposals.
The trace map records those dependencies without issuing an engine witness.
Nine source families are not nine proven safepoints; eight user families are not
an exhaustive external ABI; eight worker duties are not an implemented scheduler.
No theorem checker, SysML parser/executor, ASCENT evaluation or native test ran.
