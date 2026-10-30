# Evidence: Depth Debt, yieldto and Environment Pairing

The Tcl source identity remains `cbf86d62348d6b052e1961b4df995960fb21545f`.
All 366 retained source/manual/fixture files are rehashed; no new unique file
is fetched for this study. The [source ledger](tcl-coro-invariants-source-bindings.json)
retains LF line conventions, capture paths, hashes and original verification
classes. [Site inventory](tcl-coro-invariants-site-inventory.json) records a new
bounded search of the 350 committed C/H/M files. Its negative results are not
whole-program or installed-image absence proofs.

IE01. Actual Gambit integration retains its native obligations.

[tcltk.scm](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50) has the public
Tcl evaluation/callback bridge, callback RC roots and marker/result/error
delivery. Its [event-loop code](../../../vendor/gambit/examples/tcltk/tcltk.scm#L348)
polls Tcl_DoOneEvent through a native bridge. [Kernel marker handling](../../../vendor/gambit/lib/_kernel.scm#L1019)
remains the existing authority. Tcl coroutine suspension is not evidence that
Gambit may abandon a C stack frame or release roots before actual return.

IX01. Fresh bounded site and producer map.

The [lexical inventory](tcl-coro-invariants-site-inventory.json) explicitly
records the pattern, files, LF lines, text and occurrence counts. The
[caller/transition inventory](tcl-coro-invariants-caller-inventory.json)
separately classifies executable depth, tail-transfer, environment-switch,
deletion and injection routes. Definitions/comments/stubs are not call counts;
the regex does not prove all aliases, macros, loaded extensions or native hooks
are closed.

IX02. Ordinary credits and the native callback runner.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4256)
4256–4304 stages one ordinary command credit and an exclusive callback root;
4517–4553 follows current TOP_CB, pops-before-call and frees after return;
4556–4591 retires credit before async/cancel/limit checks. 6133–6211 and
8334–8355 route a canonical-list root through that staging.

IX03. Root debt and tailcall reservation are different producers.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8397)
8397–8426 reserves a deferred NRCommand without credit, or explicitly pushes
a credited tailcall point. 9263–9311 initializes aux=0 and root state, stages
the root command and explicitly discounts its credit. 8812–8857 compensates
only after terminal cleanup. Matching all these sites is required before a
depth conservation claim.

IX04. Actual affine updates and failed-yield rollback.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8877)
8877–8958 saves current caller depth in active aux, adds suspended offset,
checks C stack position, rolls back caller splice on failure and performs
successful yield's inverse depth/offset assignment. It contains the actual
assignments; the prose header in tclInt.h is not substituted for them.

IX05. Two real yieldto emitters.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8642)
8642–8723 implements object yield/yieldto. [tclExecute.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2504)
2504–2608 implements bytecode INST_YIELD and INST_YIELD_TO_INVOKE; it increments
the list reference before installing it in caller environment and stages
activation after TEBC_YIELD. The selected source paths have different local
reference handling and both require lifecycle coverage.

IX06. Splice selection, scheduling and list-release endpoints.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8440)
8440–8461 scans for the first unmarked empty NRCommand slot and panics if none;
4556–4591 clears the slot and schedules tail evaluation before async checks;
8544–8599 releases on error/namespace preemption or stages evaluation plus
release. [tclNamesp.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNamesp.c#L365)
365–406 cleans frame variables before transferring its pending tailcall.

IX07. Deletion, rewind, caller and exit callbacks.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8725)
8725–8857 saves/restores result state, sets rewind, directly schedules
TclNRInterpCoroutine, drains to the caller root on suspended deletion, handles
active-deleted state after yield and destroys terminal state before depth
compensation. 9120–9169 stages resume without adding ordinary command credit;
9184–9233 installs DeleteCoroutine as the command deleteProc and retains the
command reference.

IX08. Environment, callback and deferred layouts.

[tclInt.h](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L1417)
1417–1461 separates four-field CorContext, CoroutineData and ExecEnv;
2110–2115 stores deferredCallbacks on Interp; 4470–4509 defines TOP_CB,
callback allocation/free and optional assertions. [tclExecute.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L909)
909–943 creates empty environments; 963–1010 checks stack/callback/coroutine
state on deletion, with final-exit exceptions. These are source checks and
layout facts, not proof all invocations satisfy them.

IX09. Real public deletion, namespace and injection producers.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3154)
3154–3285 marks deletion, invokes deletion traces and deleteProc;
3929–3964 rejects normal evaluation in a rewinding environment after result
reset; 9068–9117 implements unsupported injection into a suspended environment.
[tclNamesp.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNamesp.c#L917)
917–935 explicitly deletes coroutine commands during namespace teardown.
The live official [C object-command manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/CrtObjCmd.htm)
documents public deletion and command token duties; it is a separate live
manual, not pinned installed-version evidence.

IX10. Bytecode rewind and other depth leases.

[tclExecute.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2230)
2230–2246 and 8033–8047 route rewind to abnormal return rather than normal
resume/catch selection. [tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6753)
6753–6778 pairs hidden-invocation extra depth; [tclCompile.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompile.c#L2212)
2212–2220 pairs compile nesting; [tclParse.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2284)
2284–2316 pairs bracket depth and zero-depth reset. These cannot be omitted
from a complete interpreter-depth claim.

IX11. Pinned public coroutine contract.

[coroutine.n](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/coroutine.n#L23)
23–76 describes suspension, resume, arbitrary yieldto target and argument list,
terminal context deletion and variable-deletion traces. Session-persistent
suspended coroutines are part of the semantic domain, not automatically garbage
that a clean-reuse guard may delete.

IX12. Retained source fixtures, never fresh passing tests.

[coroutine.test](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/coroutine.test#L255)
255–273 covers terminal/suspended/active deletion; 629–642 early trace yield;
741–801 different resume depth, event/yieldto chains and C-stack-busy failure;
803–839 unsupported injection and deletion. No fixture is executed here, and
none is promoted into a cancellation oracle.

IX13. Nested trace leaves a real native future writer.

[tclTrace.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1759)
1759–1798 and 1883–1944 implement selected-record busy, synchronous callback
evaluation, whole-word flags restoration and cleanup. [tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4853)
4853–4951 contains the actual ordinary trace helper callers. A child's logical
yield does not erase these native frames, snapshots or result obligations.

IL01. Learn resource and native-boundary reasoning from OCaml.

[Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
sections 2.3, 3.1–3.2, 4.2 and 5.6: native frames constrain capture, callback
semantics and resource cleanup; suspended computation can retain resources
beyond stack memory. Application here is an inference: explicitly own logical
suspension while preserving Gambit's native/root authority. It neither equates
Tcl coroutines with Gambit multi-shot continuations nor imports OCaml timing
or finalizer policies into this design.

IL02. Use histories to locate the reuse cut.

[Herlihy and Wing, Linearizability](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
sections 2–4, supplies invocation/response and pending-history reasoning.
Application here: source clear, local native return, suspended ownership,
producer settlement and next epoch publication must have separate events.
The correctness condition does not prove arbitrary cleanup termination or this
unimplemented guard's correctness.

IL03. Tcl's own coroutine proposals explain intent and limits.

[TIP 328](https://core.tcl-lang.org/tips/doc/trunk/tip/328.md), Rationale and
Limitations, distinguishes NRE-aware capture from non-NRE native boundaries.
[TIP 396](https://core.tcl-lang.org/tips/doc/trunk/tip/396.md), Proposal, explains
caller-context tail dispatch and multiargument resumption. These live historical
design explanations motivate why source and target activation must remain
distinct; exact branch claims above come from pinned current-source captures.

IO01. Prior contracts remain unresolved.

[Private admission study](tcl-private-coro-design.md),
[trace reachability](tcl-trace-reachability-design.md) and
[entry/completion guard](tcl-entry-cancel-design.md) retain interpreter-wide
cancel/raw writer, exact source-reset, roots/markers and native-return duties.
This study refines the ordinary-command floor by explicitly separating direct
rewind; no prior receipt, native admission or registered claim is rewritten.
