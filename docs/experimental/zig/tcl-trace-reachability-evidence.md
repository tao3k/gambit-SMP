# Reentry and UNWIND Reachability Evidence

[Ledger](tcl-trace-reachability-source-bindings.json), [site inventory](tcl-trace-reachability-site-inventory.json),
[operations](tcl-trace-reachability-operations.json), [cases](tcl-trace-reachability-cases.json),
[trace](tcl-trace-reachability-traceability.json). Fixed Tcl commit:
`cbf86d62348d6b052e1961b4df995960fb21545f`; line anchors use LF byte ordinals.

RE01. Gambit evidence and custody remain unchanged.

Rehash local vendor/gambit/examples/tcltk/tcltk.scm lines 50–123, 125–195,
347–425, fig16-10.scm lines 24–28 and lib/_kernel.scm lines 1019–1071.
The Scheme callback/root/marker/result boundary is not replaced by native trace
record counting. No Scheme/C source is modified and no backend is implemented.

RX01. Fresh registration/reset/busy text inventory.

350 exact retained C/H/M blobs are rehashed and searched; 7 matching files,
41 LF lines, 42 lexical occurrences. Private reset and child helper text includes
declarations/stubs, recursive forwarded force, and two source call families.
No concrete force=1 hook producer is identified by these hits. The statement is
bounded lexical evidence, not absence of arbitrary private/alias/loaded clients.

RX02. Independent records created by public registration.

[TraceExecutionObjCmd allocation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L469),
[Tcl_TraceCommand prepend and compile epoch](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1105).
Each registration has independent clientData/busy/ref state; compiled command
trace support is set on the shared command, not a blanket record-busy flag.

RX03. Actual direct trace selection and callback source point.

[direct loop](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1420),
[record-specific busy test](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1759),
[save/eval/restore](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1883).
Interpreter-wide I suppresses the separate interpreter trace loop, not this
direct loop. New local context is copied before the callee's busy return.

RX04. Public call depth, entry check and bounded callback roots.

[Tcl_EvalObjv saved root](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4264),
[increment and ready](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4295),
[root-bounded runner](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4517),
[readiness](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3929),
[Tcl_Canceled](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4042).
U rejection and C consumption are distinct from reset.

RX05. Every identified U-clear family has a concrete predicate.

[private reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4000),
[TEOV scheduling](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4608),
[TEOV direct clear](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4669),
[child reset recursion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096),
[ChildEval non-force call](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2776).
The child argument's descendants are iterated, not the argument parent itself.

RX06. Direct string/bracket path supplies the private depth-zero construction.

[TclEvalEx setup/reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5090),
[parsing](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5237),
[word substitution](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5308),
[NOERR dispatch](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5419),
[bracket readiness/decrement/reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2284).
The reset runs even when bracket readiness returned ERROR; restored depth selects
whether it clears. The bracket body need not run. This is a concrete body path,
not evidence that a supported real caller invokes private traces at depth zero.

RX07. Pre-readiness native hooks and pinned duties.

[Tcl_ResetResult](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919),
[ResetObjResult](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L982),
[pinned freeProc contract](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/SetResult.3#L217),
[pinned object cleanup contract](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/ObjectType.3#L225).
Reachable callbacks do not license unrestricted recursive eval or a private reset;
object freeIntRepProc must not access the bytes member.

RX08. Other completion and context branches bound the invariant.

[bytecode readiness before callback registration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6214),
[bytecode zero-depth clear](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6289),
[actual trace enter/leave callers](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4853),
[coroutine context/depth changes](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8880).
Coroutine branches are excluded from the fixed-depth proof, not assumed impossible
just because one yield route has a C-stack-busy check.

RX09. Trace specification has a separate semantic claim.

[Pinned trace.n](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/trace.n#L172),
[TIP 62](https://core.tcl-lang.org/tips/doc/trunk/tip/62.md), execution-trace
suppression and multiple-trace order. The broad name-level prose is not substituted
for the exact stable-record source path. Source preservation and a new broader
suppression policy must be named separately.

RX10. Independent existing fixture obligations, unexecuted.

[two-trace order/deletion fixtures](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L1910),
[dynamic remove/readd](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2428),
[direct/step nesting](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/trace.test#L2485).
They constrain normal compatibility without being fresh passes or UNWIND tests.

RX11. Private/native API surfaces do not prove real zero-depth or force callers.

[private trace declarations](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L431),
[private reset declaration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L574),
[private reset stub](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L1320),
[pinned native trace manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/CrtTrace.3#L78).
The native manual constrains callbacks/status/objv; it does not specify arbitrary
direct calls into private trace-check helpers outside evaluation. Installed
ABI, threading, target lifetime and actual private clients remain unqualified.

RL01. Herlihy and Wing, Linearizability (1990), sections 2–4.

[Primary paper](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf).
Use explicit invocation/response and sequential operation meanings; a body path
under a supplied private precondition is not an observed supported history.
Equal bits/status alone do not supply the missing provenance or caller.

RL02. Sivaramakrishnan et al., Retrofitting Effect Handlers onto OCaml (2021).

[Primary paper](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), sections
2.3, 3.1–3.2 and 4.2. Learn explicit native callback, context and cleanup custody;
do not import restrictions or performance numbers into Gambit or assume lexical
cleanup covers arbitrary captured native-frame escape.

RO01. Prior state separation, guard and raw-history contracts.

[Trace design](tcl-trace-cancel-design.md), [writer design](tcl-cancel-writer-design.md),
[entry guard](tcl-entry-cancel-design.md), [full support matrix](tcl-trace-cancel-benefit-matrix.md)
and [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md) remain requirements.
This study narrows the fixed multi-record domain and conditional U invariant;
it does not promote full semantic/native/retirement/total-cost/Zig gates or erase
private/hook/context-change uncertainties.

## Private Entry and Coroutine Admission

The [private-entry/coroutine study](tcl-private-coro-design.md) distinguishes unsupported private table access from actual caller admission, derives coroutine depth/cleanup phases, and refines completion custody. See its [arguments](tcl-private-coro-arguments.md), [evidence](tcl-private-coro-evidence.md), [matrix](tcl-private-coro-benefit-matrix.md) and [trace](tcl-private-coro-traceability.json). Private depth-zero dispatch and legal force-reset-hook producer closure remain unresolved; no implementation or native tests.
