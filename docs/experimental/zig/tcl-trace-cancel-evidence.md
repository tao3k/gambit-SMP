# Trace Separation Evidence

[Source ledger](tcl-trace-cancel-source-bindings.json),
[fresh trace-symbol inventory](tcl-trace-cancel-site-inventory.json),
[operations](tcl-trace-cancel-operations.json), [cases](tcl-trace-cancel-cases.json),
[trace](tcl-trace-cancel-traceability.json). Exact Tcl commit:
`cbf86d62348d6b052e1961b4df995960fb21545f`; LF byte line ordinals are used.

TE01. Gambit callback obligations are retained.

Local vendor/gambit/examples/tcltk/tcltk.scm lines 50–123, 125–195, 347–425,
fig16-10.scm lines 24–28 and lib/_kernel.scm lines 1019–1071 are rehashed and
bound as the existing Scheme/foreign marker/root/result-control evidence.
Trace lease bookkeeping does not replace Gambit roots, GC or native return rules.

TX01. Fresh search over retained exact source selection.

All 350 earlier committed C/H/M blobs are rehashed and searched with the declared
trace pattern: 5 files, 52 LF lines, 53 occurrences. No fresh fetch of those
350 blobs was needed; their exact negative content remains retained. This is
neither preprocessing nor alias/loaded-writer closure. Prior writer and broad
whole-flags inventories remain distinct bound evidence.

TX02. Direct command trace loop and context.

[TclCheckExecutionTraces](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1420),
especially lines 1439–1499: active cursor chain, different leave scan direction,
shared context writes before TraceExecutionProc, refcounts, and result-state
restore/discard after the callback. No INTERP_TRACE_IN_PROGRESS check guards
this direct route.

TX03. Interpreter trace loop and suppression.

[TclCheckInterpTraces](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1526),
lines 1545–1648: global interpreter flag check, depth and per-record checks,
Tcl_Preserve/Release, reverse enterstep scan and result-state restoration.
Private declaration/stub entries remain ingress surfaces, not proof of loaded
callers or installed image compatibility.

TX04. Callback preparation, flags and whole-word restoration.

[TraceExecutionProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1759),
lines 1768–1944: local context and same-record busy test; deleted/limit check;
call==0 distinction; step removal; argument/result string building before the
flags are set; lines 1883–1903 save/eval/whole restore; post-restore step work
and final reference release. This order is real source evidence, not an observed
cancellation bug or a native reachability proof for every abstract bit history.

TX05. Trace and flag data domains.

[TraceCommandInfo](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L41),
[busy bit](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L86),
[active command cursor](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L536),
[Trace and active interpreter cursor](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L977),
[interpreter flag values](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2239).
Three fields/scopes must not be conflated merely because each uses an integer bit.

TX06. Actual enter/leave callers and error/result folding.

[EvalObjvCore trace boundary](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4416),
[TEOV_RunEnterTraces](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4853),
[TEOV_RunLeaveTraces](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4904).
Ordering and non-OK propagation are concrete effects; cancellation bit changes
can affect later paths without changing the already returned traceCode itself.

TX07. Cancellation states, readiness, check and catch predicate.

[cancel macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156),
[installer](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467),
[readiness](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3929),
[destructive check](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4042),
[catch decision](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L8073).
The catch predicate actually calls Tcl_Canceled(interp,0); a comment alone cannot
justify classifying every concrete ERROR as exclusively an UNWIND check.

TX08. Guard-sensitive result/native/async boundaries.

[result save](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L73),
[result restore](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L125),
[NRCommand](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4556),
[source inline clear](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4669),
[bytecode completion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6289),
[async callback protocol](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L193).
Tcl_RestoreInterpState restores only ERR_ALREADY_LOGGED from flags but decrements
result/error objects; it is not whole cancellation restoration or a pure no-op.

TX09. Active deletion, cursor repair and reference release.

[remove busy execution trace](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L530),
[command destruction while active](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1341),
[CommandObjTraceDeleted](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1723),
[interpreter trace cursor repair](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L2340).
These real mechanisms remain required even when cancellation is separate.

TX10. Exact pinned trace specification and its boundary.

[doc/trace.n](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/trace.n#L158)
lines 158–185 cover nested trace effects, execution context, temporary disabling,
error propagation, directional order and undefined imported-name behavior.
The [live manual](https://www.tcl-lang.org/man/tcl8.6/TclCmd/trace.htm) is secondary;
the pinned source and fixtures determine this study's selected domain. Exact
same-name multiple-prefix suppression is not silently inferred from broad prose.

TX11. Unexecuted pinned upstream fixtures.

[recursive trace-22/23](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L1722),
[removal trace-24](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L1827),
[remove/readd and scan deletion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2428),
[nested direct/step trace-34.6](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2485),
[dynamic trace-36–38](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2542),
[error trace-40.1](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2667).
Expected results are source-authored obligations, not fresh passes, independent
native evidence, cancellation coverage, or a complete compatibility suite.

TL01. Herlihy and Wing, Linearizability (1990), sections 2–4.

[Primary paper](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf).
Use declared histories and state domains to distinguish actual cancellation
operations from a snapshot write and receipt scope. A valid observation is not
implied by equal bits, and the paper does not prove this proposed protocol.

TL02. Sivaramakrishnan et al., Retrofitting Effect Handlers onto OCaml (2021).

[Primary paper](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), sections
2.3, 3.1–3.2 and 4.2. Learn explicit native-stack and cleanup boundaries for
nested callbacks. This does not import OCaml's restrictions into Scheme or use
its performance numbers to justify Gambit/Tcl/Zig.

TO01. Prior writer/guard policy and cancellation specification.

[Writer contract](tcl-cancel-writer-design.md), [arguments](tcl-cancel-writer-arguments.md),
[matrix](tcl-cancel-writer-benefit-matrix.md), [entry guard](tcl-entry-cancel-design.md)
and [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md) retain the
source/normalized distinction, raw pending/history/idle obligations and actual
completion requirements. C memory-model obligations remain as cited in prior
WL02; this turn's attempted PDF refresh timed out, and no new platform or atomic
mapping claim is based on it. Full semantic/retirement/total-cost/Zig-increment
requirements and AG05–AG07 remain unresolved/non-promoted.

## Focused Reachability Evidence

The [new source study](tcl-trace-reachability-evidence.md) binds public independent allocation/list selection, callback-root bounds, exact post-bracket reset predicates and hook/private API duties. Three new pinned manuals are Git-blob reproduced. Source-constructed, private-body, hook-candidate and unexecuted fixture evidence remain distinct. [Ledger](tcl-trace-reachability-source-bindings.json), [trace](tcl-trace-reachability-traceability.json).
