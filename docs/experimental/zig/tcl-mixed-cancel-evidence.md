# Mixed Cancellation: Source, Specification and Paper Evidence

Research date 2026-10-21; research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
All Tcl source binds `cbf86d62348d6b052e1961b4df995960fb21545f` and LF byte lines in the
[source ledger](tcl-mixed-cancel-source-bindings.json). Retained bytes were rehashed;
no source implementation or native test was run. The prior 350-file lexical corpus
was not rerun, and its symbol scope did not establish all Canceled/check callers.
A new bounded text inventory over 33 retained source/doc files finds selected
check/reset sites; it is not AST, loaded-extension or whole-build closure.

ME01. Gambit source: [setup, direct eval, callback/string custody](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–195; [event service and shutdown](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347),
347–425; [real callback](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28; [native C-return marker/processor validity](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071. These are actual integration paths, not an implemented mixed-history
service, OS-owner proof or permission to revive returned C frames.

| ID | Pinned primary source and LF ranges | Selected finding |
| --- | --- | --- |
| MX01 | [CancelInfo](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L90), 90–109; [CancelEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4145), 4145–4210 | Pending bytes/flags overwritten under C; NULL chooses empty lane; result argument ownership and reserved clientData must be preserved. No request/evaluation/epoch provenance. |
| MX02 | [Async state/mark/invoke](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L21), 21–66, 159–243 | A-locked ready claim precedes callback read; re-mark and current-payload replay possible; global ready=0 can coexist with active callback. |
| MX03 | [CancelEvalProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467), 3467–3520; [flag macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172 | Current raw payload selected under C; sets C, adds U, replaces asyncCancelMsg and propagates descendants. Does not drain/clear retained raw payload. |
| MX04 | [Canceled](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4042), 4042–4121; reset 4000–4015; [manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3#L20), 20–70 | Clears C before UNWIND-only filter; OK can be destructive; U persists. Result text built with message,-1; count/message equality cannot prove byte identity or cancellation origin. Manual gives supported flags and thread domain; source gives exact mutation order. |
| MX05 | [NRE command entry/readiness](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4272), 4272–4340; TclInterpReady 3929–3980; return callbacks 4556–4593, 4608–4641, 4669–4695 | Entry increments levels, exception handling scheduled before readiness; readiness checks installed flags, not async ready. TEOV reset can precede NRCommand's later async service. |
| MX06 | [Object evaluation selection](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6100), 6100–6240; direct route 6240–6284; bytecode return 6289–6337 | Canonical list, bytecode and direct routes differ. Non-list bytecode readiness can return before registering TEOEx_ByteCodeCallback, so installed U may survive early ERROR without that reset. |
| MX07 | [Direct parser/evaluator](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5090), 5090–5195, 5220–5270, 5448–5552; [nested substitution](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2281), 2281–2316 | Direct dispatch is command-dependent; empty/comment-only source can skip command checks. No universal direct cleanup reset; nested substitutions can reset inside a live host activation. |
| MX08 | [VM poll](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2349), 2349–2381; catch path 8035–8110; [child propagation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096), 2096–2141; ChildEval 2776–2823 | Cancellation ERROR may be routed through catch/unwind checks; inspect actual predicates, not comments alone. Descendant flags and independent child tokens extend the frontier; ChildEval resets descendants and transfers child result. |
| MX09 | [vwait](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclEvent.c#L1385), 1385–1420; update 1493–1522; [after wait](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTimer.c#L1031), 1031–1089; [thread fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadTest.c#L445), 445–473 | Real selected checks include a fixture using LEAVE_ERR_MSG plus UNWIND-only. Its own comment warns this is not the recommended ordinary-extension check. Fixture presence is not proof it is loaded. |
| MX10 | [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), Behavior and C API; [pinned cancel manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3#L20), 20–70 | Idle cancellation is specified to affect the next script; raw API callable from any thread, checks owner-thread-only. That specification is not proof that every selected empty/early/extension path conforms. The live Cancel manual fetch timed out; pinned manual bytes provide the API evidence. |

ML01. Herlihy and Wing, [Linearizability: A Correctness Condition for Concurrent Objects](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
1990, §§2–4: define the sequential raw/mixed contract and actual ordering points
before proving concurrent histories. This method does not make different request
policies equivalent or prove this design's implementation/progress.

ML02. [C11 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4 and §7.17.3: synchronized publication and race-free ownership of histories
and descriptors. Concrete Tcl/platform mutex/atomic mappings remain unqualified.

ML03. Sivaramakrishnan et al., [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
PLDI 2021, §§2.3, 3.1–3.2: learn explicit C-frame, root and cleanup boundaries;
do not copy OCaml continuation restrictions or its benchmark numbers onto Gambit.
Actual Gambit C-return validity and existing root custody remain ME01.

MO01. Design dependencies: [targeted settlement](tcl-targeted-cancel-design.md),
[its arguments](tcl-targeted-cancel-arguments.md),
[service](tcl-reuse-service-design.md), [interpreter reuse](tcl-interpreter-reuse-design.md)
and [control boundary](tcl-control-boundary-design.md). Prior permanent-taint admission
was deliberately conservative. This study supplies conditional history-discharge
requirements, not new registered/native witnesses or a general mixed-policy proof.

The [identity follow-up evidence](tcl-next-evaluation-evidence.md) reviews alias
wrappers, preparation/result boundaries, NRE staging and coroutine contexts from
the same pinned bytes. [Its trace](tcl-next-evaluation-traceability.json) records
conditional positive controls and refusal cases; it is not whole installed-entry
closure, a normalized-contract proof or native qualification.
