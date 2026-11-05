# TclReuseService: Stub and Producer Evidence

Research date 2026-10-21. Research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
All Tcl links below bind commit `cbf86d62348d6b052e1961b4df995960fb21545f`. Exact preserved bytes, reproduced Git
blob hashes and LF-based line counts are in the [source ledger](tcl-reuse-service-source-bindings.json).
Form-feed page separators do not increment an LF source line. Earlier source
ledgers used Unicode splitlines for some total counts; their byte identities
remain valid, and immutable old receipts are preserved.

SE01. Actual Gambit callers: [setup, direct eval and callback/string release](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–195; [event loop and join](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347),
347–425; [real callback reentry](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28; [native return validity](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071. These callers do not establish OS affinity, host epochs or a current
TclReuseService implementation. Existing root/marker custody is credited.

| ID | Pinned source / scope | Source finding and boundary |
| --- | --- | --- |
| SX01 | [Recursive tree at pinned commit](https://api.github.com/repos/tcltk/tcl/git/trees/cbf86d62348d6b052e1961b4df995960fb21545f?recursive=1); [corpus ledger](tcl-reuse-producer-corpus.json) | 350 committed .c/.h/.m files from an untruncated tree; all fetched text reproduced its tree blob; 14 files and 112 lexical hits for the declared symbol set. Includes comments, declarations, tables, tests and both platform branches. Not 112 calls, a preprocessed build or full runtime closure. |
| SX02 | [tclStubLib.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclStubLib.c#L16), 16–24, 50–131; [interpreter table](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L762), 758–764, 1018–1024; [public hooks](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclDecls.h#L1879), 1879–1892 | Per-linked-stub-object globals; bootstrap reads interpreter table, checks public mechanism/version, obtains package data and hook tables. Failure paths do not uniformly clear prior private globals. |
| SX03 | [Tcl_InitStubs macro](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tcl.h#L2384), 2384–2403; [non-stub check](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclPkg.c#L2018), 2018–2060; package boundary 224–285; [Unix build](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/unix/Makefile.in#L347), 280–285, 347–352, 639–644, 1701–1709; [InitStubs documentation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/InitStubs.3) | USE_TCL_STUBS changes the call path. Without it the macro checks package/version, not private pointer initialization. The stub object is built for a shared-library consumer in a static archive. Build rules are not Darwin link/load evidence. |
| SX04 | [Internal table](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L893), 890–925, 1320–1321; [table definition](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclStubInit.c#L497), 497–505, 732–740, 970–980; [declaration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.decls#L599), 599–602 | Reset is internal slot 237 with C signature int(Tcl_Interp*, int). Public hooks lead to that internal table in this source. Internal-table availability and stable private ABI are different claims. |
| SX05 | [Interpreter registration/deletion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L710), 90–109, 710–724, 1426–1493; [child creation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2311), 2311–2375 | Each interpreter gets CancelInfo plus an async token; deletion removes them. ChildCreate calls internal TclCreateInterp, so wrapping public Tcl_CreateInterp alone misses a real creator. |
| SX06 | [interp cancel](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L682), 682–752; [CancelEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4145), 4145–4210; callback 3467–3520; [child propagation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096), 2096–2141 | Builtin script cancellation calls the public API; requests mark a shared per-interpreter token; callback uses the stored target and propagates to descendants. No host epoch is attached automatically. |
| SX07 | [testasync](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTest.c#L729), 729–935, registration 485; [thread cancellation fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadTest.c#L955), 955–992, caller 240–277; [test build objects](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/unix/Makefile.in#L296), 296–300, 707–713 | Real source producers include create/mark/marklater and thread cancellation fixtures. AsyncHandlerProc reads Tcl_GetObjResult before its NULL branch and can evaluate a script. These are fixture sources, not proof they are loaded in the Gambit embedding. |
| SX08 | [Notifier consumers](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNotify.c#L600), 600–624, 844–863, 1032–1058; [timer/after wait](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTimer.c#L1031), 1031–1089; [command return](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4556), 4556–4590; [VM poll](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2349), 2349–2381 | Async work runs outside the explicit evaluator poll: service-event, DoOneEvent, ServiceAll and after wait. DoOneEvent can service async and return 1 before ordinary event processing. These are consumers, not new cancellation producers. |
| SX09 | [Async state and locking](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L21), 21–66, 113–140, 159–171, 193–243, 271–315, 336–349 | Ready/active state is thread-owned; create appends to handler order; mark takes asyncMutex; Invoke releases it before callback; Delete is owner-thread-sensitive. Existing API does not establish a target-only unmark-and-reset service. |
| SX10 | [Token substitution reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2281), 2281–2316; [non-forced reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4000), 4000–4015; top-level resets 4669–4695, 6289–6337 | Command substitution manually increments/decrements nesting and calls reset. Reset state/zero nesting can occur before the surrounding host call returns. This refines the earlier direct-path argument; it does not refute its no-other-reset conditional trace. |
| SX11 | [Cancellation fields](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172; [message installation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3505), 3505–3517; [GetObjResult](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L577), 577–606; result reset 919–961 | Flag reset is narrower than resetting result/options, diagnostics or application state. GetObjResult dereferences its interpreter; the fixture's pre-NULL-check access is a source-level hazard for a blind NULL drain, not an observed crash. |
| SX12 | [Public async declarations](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclDecls.h#L243), 243–253; [Cancel API declaration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclDecls.h#L1673), 1673–1678; [internal reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L573), 573–575 | The inspected interfaces support mark/invoke/delete and private reset. [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md) also describes next-script cancellation when no invocation is active; explicit epoch settlement is a distinct contract. The proposed targeted settlement operation is new design requiring Tcl cooperation, not an already available private stub. |

SL01. [C11 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4, §7.17.3: receipt validity/publication requires synchronization and a
happens-before relation. Source-specific Tcl lock order does not replace host
lifecycle ordering.

SL02. [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
§§2.3, 3.1–3.2: study root, foreign-control and cleanup boundaries together.
Gambit's continuation and GC contracts remain its own; a Tcl flag or Zig defer
does not prove that a foreign activation returned.

SO01. Prior designs credited: [reuse contract](tcl-interpreter-reuse-design.md),
[conditional arguments](tcl-interpreter-reuse-arguments.md),
[cancel/return/result distinction](tcl-cancel-propagation-design.md),
[command custody](tcl-command-custody-design.md),
[previous C/Zig matrix](tcl-interpreter-reuse-benefit-matrix.md).
No old source path is retired by this documentation. The source corpus excludes
Tk, installed/generated inputs not committed in Tcl, dynamic modules, external
applications, scripts as a complete corpus, preprocessing and indirect calls.
It supplies a repeatable lexical search boundary, not semantic or runtime closure.

The [targeted follow-up evidence](tcl-targeted-cancel-evidence.md) reuses the same
pinned bytes and narrows the proposed core-operation contract;
[its trace](tcl-targeted-cancel-traceability.json) records independent conditional
arguments and counterexamples, with no new native or installed-library witness.
