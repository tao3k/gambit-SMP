# Tcl Cancel-Unwind: Evidence and Qualification Boundaries

Read 2026-10-21. Research HEAD `1a2d8612f2065387c62858e10baf63ce369cc48c`;
Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Local working bytes are separately hashed in the [trace](tcl-cancel-propagation-traceability.json).
Remote branch readings are not downloaded byte hashes, a coherent immutable Tcl
checkout, or correspondence to an installed Tcl/Tk. Browser source ordinals below
are navigation aids. The [reading ledger](tcl-cancel-external-readings.json)
preserves successful readings and the unavailable compiler source.

## Local Source

| ID | Source | Bounded observation |
| --- | --- | --- |
| PE01 | [Tcl bridge](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50), 50–122, 124–195, 217–228, 245–345, 347–425; [event callback](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24), 24–28 | Actual interpreter setup/delete, Tcl_Eval/error entry, callback result/string release, exported commands/removal and active DoOneEvent loop. No cancellation adapter is established in these selected callers. |
| PE02 | [Wind/continuation](../../../vendor/gambit/lib/_thread.scm#L4794), 4794–4819, 4908–5080; [handlers](../../../vendor/gambit/lib/_thread.scm#L4529), 4529–4620; [manual](../../../vendor/gambit/doc/gambit.txi#L11135), 11135–11153 | Scheme control and dynamic context remain Gambit responsibilities; Tcl unwind is not Scheme continuation invocation. |
| PE03 | [C return](../../../vendor/gambit/lib/_kernel.scm#L1019), 1019–1071; [call/run](../../../vendor/gambit/lib/setup.c#L3275), 3275–3422; [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562 | Native activation/processor validity, matching catch/rethrow and marker/root obligations remain separate from Tcl cancellation. |

## Primary External Readings

| ID | Primary source and locator | Source observation |
| --- | --- | --- |
| PX01 | [Cancel API](https://www.tcl-lang.org/man/tcl8.6.17/TclLib/Cancel.htm), DESCRIPTION/FLAG BITS | CancelEval is cross-thread; Canceled is interpreter-thread only. Unwind is stronger than ordinary error. A non-NULL message object is consumed according to the API contract; clientData is reserved. |
| PX02 | [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), rationale/semantics/notes | Cooperative interpreter cancellation, catch bypass intent, extension checks, idle/next-script and reset behavior. Design intent does not prove every current entry route. |
| PX03 | [tclBasic.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclBasic.c), CancelInfo 80–87; creation 670–683; CancelEvalProc 3255–3324; Canceled/CancelEval 3825–3981 | One request record stores flags/message; async callback sets self/child flags and returns its input code. Canceled consumes the one-shot bit; unwind persists. |
| PX04 | Same tclBasic.c: TclInterpReady 3716–3749; reset 3784–3797; Objv/NRE 4026–4100, 4298–4342; TEOV handlers 4360–4441; direct eval 5124–5237, Tcl_Eval 5682–5697; object evaluation 5880–5990 | Entry checks, NRCommand recheck, reset-before-decrement, object-return reset and direct cleanup are distinct routes. Direct eval uses NOERR; no identical reset is visible in its cleanup tail. |
| PX05 | Same tclBasic.c: DeleteInterpProc 1347–1412; coroutine rewind 8290–8299 | Deletion removes CancelInfo/async state on the owner path. Coroutine rewind is distinct from cancel flags. |
| PX06 | [tclInt.h](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclInt.h), 2004–2019 | TclCanceled tests one-shot or unwind; setting flags preserves an already installed unwind bit; unsetting clears both. |
| PX07 | [tclExecute.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclExecute.c), 38–40, 2234–2262, 6785–6831, 7586–7743 | Polling reaches gotError; checkForCatch bypasses catch ranges while cancellation remains; abnormalReturn releases operand/auxiliary state, restores frame and frees stack. Default poll mask is 63. |
| PX08 | [tclCompCmds.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCompCmds.c), TclCompileCatchCmd, browser ordinals 32–43; tclBasic.c builtInCmds 227/269 | Catch can compile an exception range or fall back. Try has both compiler and NRE registrations. Exact Try compiler lowering was not retrieved. |
| PX09 | [tclCmdAH.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdAH.c), 277–357 | NRE catch callback checks rewind/limit, then can assign result/options and return OK; no direct persistent-cancel test there. |
| PX10 | [tclCmdMZ.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdMZ.c), 4856–5042, 5056–5178 | Try callbacks check rewind/limits; normal processing binds handler variables and schedules handler/finally evaluation. TryPostFinal arbitrates results/options, including -during. |
| PX11 | [tclEvent.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclEvent.c), 1322–1393, 1413–1458; 139–167, 186–224, 548–564 | vwait/update poll after events; vwait untraces on ordinary exit. Background result/options queue, idle dispatch and deletion disposal are separate. |
| PX12 | [tclAsync.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclAsync.c), 107–130, 152–164, 184–232, 259–301; [Async manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/Async.htm) | Mark sets ready and may alert origin thread; Invoke runs owner handlers and can repeat; Delete removes even a ready handler. Readiness concerns the thread, not a specific host request. |
| PX13 | [tclInterp.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclInterp.c), 2006–2048, 2661–2701 | Child flag propagation is recursive; ChildEval resets descendants where permitted and transfers result. Parent success does not certify every child's idle state. |
| PX14 | [try manual](https://www.tcl-lang.org/man/tcl8.6/TclCmd/try.htm) | Ordinary finally/handler rules and -during. These ordinary rules alone are not a cancellation cleanup guarantee. |
| PL01 | [Retrofitting Effect Handlers onto OCaml, PLDI 2021](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), §§2.3, 3.1–3.2 | Distinguishes managed stack/root machinery, foreign-frame boundaries and resource cleanup. Learn the explicit boundary method; do not import OCaml's restrictions or performance numbers into Gambit. |
| PL02 | [R7RS report](https://small.r7rs.org/attachment/r7rs.pdf), §§6.10–6.11 | Dynamic-wind and exception semantics inform the preservation obligation. Gambit's stronger hook behavior still needs its own source/manual contract. |

PD01. Prior designs credited: [control boundary](tcl-control-boundary-design.md),
[conditional semantics](tcl-control-boundary-arguments.md),
[command custody](tcl-command-custody-design.md),
[root/marker custody](native-callback-custody-contract.md),
[paired C/Zig comparison](tcl-control-boundary-benefit-matrix.md).
No old mechanism or claimed saving is counted again.

The unavailable `tclCompCmdsSZ.c` branch/tag/raw/blob retrievals are gaps, not
proof that Try lacks a compiler. Generic manuals identify 8.6.18, Cancel identifies
8.6.17. The successful branch pages may have different crawl times. Pinning a
coherent revision, completing compiler/control routes, and installed binary
qualification remain unresolved. This study executes only document/hash/link/D2
checks, no native, compiler, Scheme, model, solver, prover or analyzer workload.

## Subsequent Source Identity Refinement

The [reuse source ledger](tcl-interpreter-reuse-evidence.md) now records successful
GitHub connector retrieval of the previously unavailable Try compiler and related
files at one immutable commit, with reproduced blob hashes. The unavailable
retrievals and unpinned browser ordinals above describe this earlier study's
evidence boundary; they are not the latest source-availability conclusion.
Installed Tcl/Tk and private-stub qualification remain unresolved.
