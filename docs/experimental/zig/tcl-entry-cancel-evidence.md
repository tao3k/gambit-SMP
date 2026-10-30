# Entry Gate and Completion Guard: Source and Paper Evidence

Research date 2026-10-21; research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Tcl is pinned to `cbf86d62348d6b052e1961b4df995960fb21545f`, with LF byte anchors and
rehashed retained blobs in [source bindings](tcl-entry-cancel-source-bindings.json).
The bounded text [site inventory](tcl-entry-cancel-site-inventory.json) reads the prior 33 retained files plus two newly captured mutex/manual files
(35 source/doc files total), including comments/definitions; it is not a preprocessed,
whole-program or installed/loaded domain. The earlier 350-file corpus was not rerun.
No implementation or native test is supplied.

GE01. Actual Gambit integration: [setup and direct eval](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–123; [Scheme callback/RC/string custody](../../../vendor/gambit/examples/tcltk/tcltk.scm#L125),
125–195; [event service/shutdown](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347),
347–425; [callback invoking Tcl](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28; [C return marker/processor validity](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071. These establish real users, not an existing owner/gate/guard issuer.
No cleanup construct replaces actual native return or Gambit root validity.

| ID | Pinned source / LF scope | Fact used and boundary |
| --- | --- | --- |
| GX01 | [Async state/registration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L21), 21–66, 113–140; mark/invoke 159–243; delete 271–315 | Oldest-ready selection, unlock-before-callback, code fold, head rescan and owner TLS. asyncReady can be zero while active; no nested-drain or bounded-progress guarantee. |
| GX02 | [CancelInfo and CancelEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L90), 90–109, 4145–4210 | C-held conversion/copy/decrement and C -> A mark; early NULL/missing-target ERROR paths precede success-path object decrement. No epoch/lease/guard/prepared-payload protocol exists here. |
| GX03 | [CancelEvalProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467), 3467–3520; [flag macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172 | Installs C/U/message under C, propagates children, returns incoming code. New callback-free immutable-message installation would be a core representation change. |
| GX04 | [Readiness/check/reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3929), 3929–3980, 4000–4015, 4042–4121; early bytecode entry 6214–6240 | Result preparation precedes installed check; Canceled clears C before filtering; reset may be no-op; early ERROR precedes bytecode-return cleanup registration. |
| GX05 | [NRE and inline reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4256), 4256–4340, 4517–4553, 4556–4593, 4608–4641, 4669–4695; bytecode return 6289–6337 | Exception reset and later NRCommand async service are separate; late install can follow reset. A final guard alone does not cover every prior writer. |
| GX06 | [Tcl_ObjType](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tcl.h#L794), 794–810; [refcount/string/free macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L3675), 3675–3689, 3814–3818, 3859–3886 | Custom type conversion/free hooks and slow paths exist. Presence of a callback pointer does not establish that arbitrary recursive Tcl evaluation from it is legal; actual build/debug variants still need qualification. |
| GX07 | [ResetResult](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919), 919–961, 982–1009; string result 483–512; [Tcl_Eval postlude](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6005), 6005–6025 | Result operations have custom free/internal-rep/legacy-variable boundaries. Inner evaluation return precedes outer result mirroring and actual outer return. |
| GX08 | [Script-capable async fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTest.c#L850), 850–905; [notifier](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNotify.c#L600), 600–624, 844–863, 1032–1058 | Some real source handlers evaluate scripts and read interp/code/result; event service can pass NULL. Fixture is not proof it is loaded, lawful in every proposed entry context or native-tested. |
| GX09 | [Builtin cancel](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L682), 682–752; descendant set/reset 2096–2141; ChildEval 2776–2823; [substitution reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2281), 2281–2316 | Actual core producers and reset writers bypass a host-only wrapper; descendants and nested scopes extend coverage. |
| GX10 | [NRE staging/coroutine context](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8334), 8334–8373, 8719–8858, 8880–8965 | Staging return, saved-root callback running, yield and actual exit/wind-down differ. No automatic lexical guard/grace or suspended native-root closure is established. |
| GX11 | [Pinned Async manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Async.3#L85), 85–163; [Cancel manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3#L20), 20–70; [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), Behavior | Handler input/output context and oldest-ready/code/result fold are documented. Warning recommends saving/restoring interp state for script-capable handlers. Cancellation's next-script/reset specification is not a proof that a new gate/guard preserves every source path. |

GX12. Newly captured pinned [Unix thread implementation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/unix/tclUnixThrd.c#L471),
471–538; [Thread manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Thread.3#L138),
138–149; [thread/no-thread macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tcl.h#L106),
106–113, 2578–2593. Lock storage is lazily allocated, initialization uses default
pthread attributes, and the pinned manual gives no portable same-thread relock
guarantee. Non-threaded builds erase the mutex calls. The Unix file also matches
the previously pinned tree blob; the manual is pinned-API blob verified. Neither
is evidence of actual installed Darwin mutex type or Tcl build flags. A separate
POSIX web fetch returned 403; no platform conclusion is based on that unavailable page.

GL01. Herlihy and Wing, [Linearizability: A Correctness Condition for Concurrent Objects](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
1990, §§2–4: define acceptance, decision and settlement ordering points against the
selected sequential semantic policy. The method does not make a new priority class,
context or reset transition equivalent to the old one or prove finite progress.

GL02. [C11 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4 and §7.17.3: race-free history/permit/descriptor publication; actual
Tcl/platform mutex/atomic mappings and mixed-language ABI remain unqualified.

GL03. Sivaramakrishnan et al., [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
PLDI 2021, §§2.3, 3.1–3.2: learn explicit C-frame, root, continuation and cleanup
boundaries. Neither OCaml restrictions nor its benchmark results transfer to Gambit;
actual native return/marker validity and retained GC duties remain GE01.

GO01. Prior [next-evaluation identity](tcl-next-evaluation-design.md),
[its arguments](tcl-next-evaluation-arguments.md),
[mixed history](tcl-mixed-cancel-design.md), [targeted settlement](tcl-targeted-cancel-design.md)
and [service](tcl-reuse-service-design.md) are design dependencies, not independent
native witnesses. This study specifies policy-bound gate/guard alternatives and
source migration duties; previous immutable receipts remain unchanged.

## Writer Evidence Follow-Up

The [new evidence ledger](tcl-cancel-writer-evidence.md) distinguishes the prior 35-file selection from a fresh 350-file text reread, adds trace save/eval/whole-restore and its actual callers, and records the raw failure/manual argument-ownership discrepancy. [Corpus](tcl-cancel-writer-corpus.json) and [whole-flag audit](tcl-cancel-writer-flag-audit.json) are static source evidence, not preprocessed/loaded/alias closure or native behavior. [Trace](tcl-cancel-writer-traceability.json).
