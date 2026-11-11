# Real Function Backend Evidence Ledger

Reviewed: 2026-10-20. Selected working-source evidence and primary literature.
Paths below are relative to `vendor/gambit/`; exact file SHA-256 identities and
source spans are bound in [traceability](scheme-function-zig-traceability.json).
The checked-in generated C is a historical artifact, not newly reproduced
output or proof of the current configured target. Claims use selected spans,
not a declaration of whole-source closure.

| ID | Source anchors | What the bytes support / limit |
| --- | --- | --- |
| SF-S01 | [list.scm](../../../vendor/gambit/lib/gambit/list/list.scm#L384), lines 384–403; [_std.scm](../../../vendor/gambit/lib/_std.scm#L26), 26–46; [list namespace](../../../vendor/gambit/lib/gambit/list/list%23.scm#L9), 9–96 | Actual public versus primitive reverse, include context and public namespace. Public source is not the unchecked primitive. |
| SF-S02 | [_gambit#.scm](../../../vendor/gambit/lib/_gambit%23.scm#L223), 223–270, 400–452, 550–615, 794–834 | Definition/name expansion, parameter force wrapping and feature-controlled force/check macros. Full macro evaluation was not run. |
| SF-S03 | [_std#.scm](../../../vendor/gambit/lib/_std%23.scm#L51), 51–66 | Proper-list input defers checks; terminal null/original identity selects list or proper-list failure. |
| SF-S04 | [_std.c public body](../../../vendor/gambit/lib/_std.c#L71222), 71222–71286; [global name](../../../vendor/gambit/lib/_std.c#L8982), 8982–8983; [frame/point table](../../../vendor/gambit/lib/_std.c#L145810), 145810–145816 | Stored C public host, six dispatchable labels, five return descriptor rows, four textual POLLs, post-cons CHECK_HEAP, two failure targets, original argument and incoming return preserved. No compiler invocation or artifact/source/config reproducibility assertion. |
| SF-S05 | [_front.scm](../../../vendor/gambit/gsc/_front.scm#L225), 225–252, 415–451; [_back.scm](../../../vendor/gambit/gsc/_back.scm#L197), 197–235 | Frontend module/tree/env/c-intf flow, target.dump call and backend feedback seam. Doesn't supply completed runtime export automatically. |
| SF-S06 | [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm#L28), 28–40; [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm#L78), 78–105 | Current normalization order and semantic frame/live fields. Proposed graph is handwritten, not observed GVM. |
| SF-S07 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm#L344), 344–448, 1120–1142, 2524–2575, 2607–2635 | Current C scanner reserves space, creates checks and resume labels, flushes frames/float cache and lowers cons. These semantic decisions need extraction, not textual translation. |
| SF-S08 | [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm#L471), 471–520; [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm#L337), 337–382, 1286–1360 | Maps/internal-frame sizing, old c-intf consumption, module supply/demand/global metadata output. Physical packing versus semantic liveness must have distinct owners. |
| SF-S09 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in#L3102), 3102–3153, 5309–5326, 8542–8565; [mem.c roots](../../../vendor/gambit/lib/mem.c#L6511), 6511–6538; [heap limit](../../../vendor/gambit/lib/mem.c#L7428), 7428–7505 | Conditional no-handles pair extent=3, actual stores and cursor advance, post-check predicate/unused m, current root arrays, section change versus GC request. No whole-program B or automatic root in Zig. |
| SF-S10 | [setup.c trampoline/call](../../../vendor/gambit/lib/setup.c#L3214), 3214–3380, 3426–3448; [host macros](../../../vendor/gambit/include/gambit.h.in#L6810), 6810–6850, 6888–6978 | Existing trampoline and native control/label conventions. New dispatch ABI or required-tail Zig ABI is not admitted by resemblance. |
| SF-S11 | [setup.c module fixup](../../../vendor/gambit/lib/setup.c#L1522), 1522–1712; [descriptor/setup](../../../vendor/gambit/lib/setup.c#L1925), 1925–2058 | Actual label/constant/global fixup, early flag, representation-size checks, multi-VM atomicity TODO, descriptors and setup_mod. Retain effects/owners; old state flag does not prove transactional completion. |

| ID | Primary reference and precise use | Boundary |
| --- | --- | --- |
| SF-P01 | [Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §2, §§2.3–2.5 | Bidirectional target abstraction, frames, calling conventions and closures motivate the seam; paper does not prove our HostGraph or Zig economics. |
| SF-P02 | [Zig language reference](https://ziglang.org/documentation/0.15.1/#call), @call/CallModifier, @cImport, Lifetime and Ownership | Required-tail calls reject when impossible; C import parses C; ownership must be managed. No automatic Scheme GC/root/continuation guarantee or complete Gambit C translation. |
| SF-P03 | [Compiling with Continuations and LLVM](https://arxiv.org/html/1805.08842v2), §§3.2–3.5 | Tail ABI, explicit roots, relocation and continuation-address constraints are real backend work. Its custom JWA/LLVM and x86 realization are not stock Zig or Darwin qualification. |
| SF-P04 | [MLIR rationale](https://mlir.llvm.org/docs/Rationale/Rationale/), motivating progressive lowering and modular passes | Infrastructure helps preserve useful abstraction; Scheme dialect, legal transforms and region/effect proofs are project work. |
| SF-P05 | [MLIR C API](https://mlir.llvm.org/docs/CAPI/), Design/Scope/Object Model | Low-level opaque handles, lifetime and unstable API mean a bounded provider adapter and upgrade costs; no high-level Scheme frontend is supplied. |
| SF-P06 | [LLVM GC safepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts), relocation sequence and base/derived-pointer rules | Relocated values need explicit subsequent-use discipline. An alternative provider integration, not a Gambit runtime supplied by Zig. |
| SF-P07 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§1.1–1.3 and §4.4 | Separate semantic compatibility, sequential cost, pause-time/parallel throughput and C-interface constraints; compare GC protocols before choosing collector/language. No OCaml benchmark gain transfers to Gambit. |

All paper uses are bounded paraphrases. There is no imported speedup, source
translation success, matched maintenance estimate or accepted economic result.
