# Next Evaluation: Source and Paper Evidence

Research date 2026-10-21; research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Tcl source binds `cbf86d62348d6b052e1961b4df995960fb21545f` and LF byte ordinals in the
[source ledger](tcl-next-evaluation-source-bindings.json). Rehashed retained bytes
and selected source reads are not an installed/native/private-ABI receipt. The
new bounded entry/return-site text inventory over 33 retained files includes docs,
comments, definitions and declarations; it is not a complete caller graph, AST or
preprocessed/loaded build. The old 350-file corpus was not rerun.

NE01. Real Gambit paths: [setup and Tcl_Eval](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–123; [Tcl -> Scheme callback and string/root release](../../../vendor/gambit/examples/tcltk/tcltk.scm#L125),
125–195; [event loop/shutdown](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347),
347–425; [actual callback re-evaluating Tcl](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28; [processor/first C return validity](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071. The callback bridge normally returns TCL_OK; Scheme exceptions/control
still require the prior foreign-boundary contract. No native affinity/epoch/new
receipt system is established by this example.

| ID | Pinned source and LF ranges | Source fact and limitation |
| --- | --- | --- |
| NX01 | [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), Behavior; [Eval manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Eval.3#L75), 75–150 | Raw idle cancellation refers to the next script, not a host-job category. Public APIs execute scripts in several representations. The specification does not by itself provide a source-level semantic-entry identity. |
| NX02 | [Accept/install](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4145), 4145–4210, 3467–3520; [async claim](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L159), 159–243; [descendant flags](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096), 2096–2141 | Pending payload read happens after ready claim; stored target ignores callback's interp argument; child propagation does not make another interpreter's script the requested target's next evaluation. |
| NX03 | [Public EvalObjv/NRE](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4256), 4256–4340; [EvalEx forwarding](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5075), 5075–5090; wrappers 6005–6118; object routes 6120–6284 | Multiple API/helper calls can represent one semantic script. Canonical/direct route forwarding and public reentry require source roles, not a function-name or TLS-depth rule. Tcl_Eval mirrors string result after inner return. |
| NX04 | [Direct setup and command dispatch](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5090), 5090–5195, 5220–5270, 5390–5448; cleanup 5448–5552; [readiness](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3929), 3929–3980 | Empty/comment-only direct scripts can bypass command checks. Readiness resets result before installed-cancellation check and does not service all pending async tokens. Entry identity cannot be inferred from finding a later check. |
| NX05 | [Canceled/reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4000), 4000–4015, 4042–4121; [bytecode entry/return](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6214), 6214–6240, 6289–6337; [flags](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172 | Filter clears C before possible OK; U persists; early readiness ERROR can precede bytecode cleanup registration. Observation, consumption and neutrality are distinct. |
| NX06 | [NRE return/reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4556), 4556–4593, 4608–4641, 4669–4695; [nested substitution](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2281), 2281–2316; [VM checks/catch](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2349), 2349–2381, 8035–8110 | Reset may precede later async installation; nested reset is not outer physical return. Exact cancellation route must follow actual predicates rather than outer code/message alone. |
| NX07 | [Result reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919), 919–961, 982–1009; [string result](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L483), 483–512 | Custom freeProc, internal-representation release and legacy variable writes are preparation/effect boundaries. Source reachability is not proof arbitrary recursive use from every callback is legal. |
| NX08 | [Callback runner](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4517), 4517–4553; [public NRE staging](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8334), 8334–8373; [coroutine cleanup/context](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8719), 8719–8858; activation 8880–8965 | NRE scheduling may return before logical work; runner stops at saved root. Yield and real coroutine exit differ; activation changes execEnv/numLevels, and C-stack-busy is a real constraint. Full coroutine closure not established. |
| NX09 | [Notifier consumers](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNotify.c#L600), 600–624, 844–863, 1032–1058; [script-capable async fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTest.c#L850), 850–905; [ChildEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2776), 2776–2823 | Event/async service can cause native callbacks and some handlers evaluate scripts; fixture is not proof it is loaded. Child calls have a different target; installed flags are not a requested-target next-entry witness. |
| NX10 | [UNWIND-only fixture check](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadTest.c#L445), 445–473; [Cancel manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3#L20), 20–70 | Actual selected caller uses the filter and warns ordinary extensions against that pattern. Owner-thread check requirement and supported flags do not make the query non-destructive. |

NL01. Herlihy and Wing, [Linearizability: A Correctness Condition for Concurrent Objects](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
1990, §§2–4: define the sequential invocation abstraction and its ordering before
reasoning about concurrent histories. The paper does not choose what this runtime
counts as a semantic invocation or prove the proposed hooks correct.

NL02. [C11 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4 and §7.17.3: race-free history publication, lock synchronization or a
qualified release/acquire protocol. Actual Tcl/platform mapping remains unqualified.

NL03. Sivaramakrishnan et al., [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
PLDI 2021, §§2.3, 3.1–3.2: learn explicit native frame, root, continuation and cleanup
boundaries; do not transfer OCaml restrictions or benchmark percentages to Gambit.
Actual returned-C validity and Scheme GC obligations remain NE01.

NO01. Prior [mixed history](tcl-mixed-cancel-design.md),
[arguments](tcl-mixed-cancel-arguments.md), [targeted settlement](tcl-targeted-cancel-design.md)
and [service](tcl-reuse-service-design.md) are design dependencies. This follow-up
clarifies natural callback scripts versus host jobs, first-attempt identity and
observation/consumption/neutrality separation. No old immutable receipt is rewritten.

The [gate/guard evidence follow-up](tcl-entry-cancel-evidence.md) adds exact
handler-fold/context and object-callout/ownership boundaries from the same pinned
bytes. [Its trace](tcl-entry-cancel-traceability.json) specifies explicit semantic
policies and reset migration; it is not a full installed-domain/native witness.
