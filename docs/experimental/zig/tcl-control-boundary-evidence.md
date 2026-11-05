# Tcl Control Boundaries: Source, Reports and Papers

Reviewed 2026-10-21. Research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact local working bytes and
intervals are bound in the [trace](tcl-control-boundary-traceability.json).
[External reading records](tcl-control-external-readings.json) identify reviewed
web pages/source locators separately from raw-file hashes and installed
library identity. No implementation, expansion, native test, performance,
whole-program analysis or proof engine ran.

## Gambit Source and Real Callers

| ID | Exact source anchors | Observation and boundary |
| --- | --- | --- |
| CE01 | [SMP exception procedures](../../../vendor/gambit/lib/_thread.scm#L4529), 4529–4620; [call/cc](../../../vendor/gambit/lib/_thread.scm#L4623), 4623–4708; feature boundaries 9–16, 5350–5364 | with-exception-handler dynamically installs a handler; with-exception-catcher captures and grafts; native and explicit R7RS procedures differ. Selected code is SMP; later duplicate non-SMP definitions are not extra runtime clients. |
| CE02 | [Raise/abort macros](../../../vendor/gambit/lib/_thread%23.scm#L888), 888–902; [manual](../../../vendor/gambit/doc/gambit.txi#L11449), 11449–11552 | macro-raise calls the current handler, with interrupts enabled; abort re-signals a noncontinuable exception if it returns. Manual states native raise continuation resumes on handler return. A result wrapper must not conflate these. |
| CE03 | [Wind implementation](../../../vendor/gambit/lib/_thread.scm#L4794), 4794–4819, 4908–5080; [dynwind/denv representation](../../../vendor/gambit/lib/_thread%23.scm#L752), 752–792, 810–826 | Captured-context dynamic-wind construction; source/destination comparison; unwind and wind use saved contexts and call Scheme hooks. Actual internal no-winding operations are part of transfer coverage, not independent safe public replacements. |
| CE04 | [Gambit hook semantics](../../../vendor/gambit/doc/gambit.txi#L11135), 11135–11153; [dynamic binding](../../../vendor/gambit/lib/_kernel.scm#L1354), 1354–1378 | Saved dynamic environment and hook continuation semantics are explicit; kernel binding restores denv/caches around thunk. Gambit's stronger specified hook behavior cannot be erased using a weaker report's unspecified case. |
| CE05 | [C return handler](../../../vendor/gambit/lib/_kernel.scm#L1019), 1019–1071; [call/run](../../../vendor/gambit/lib/setup.c#L3275), 3275–3422; [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562; [manual C-return case](../../../vendor/gambit/doc/gambit.txi#L12208), 12208–12267 | Native origin/validity checks, matching marker or rethrow, pre-allocation target-root obligation and marker invalidation. General managed continuation lifetime and native activation lifetime remain separate. |
| CE06 | [Tcl bridge](../../../vendor/gambit/examples/tcltk/tcltk.scm#L106), 106–122, 124–195, 217–228, 260–276, 347–425, 575–618; [real event callback](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24), 24–28 | Tcl eval → Scheme error callback, static exported proc/apply/string result, command removal, active Scheme DoOneEvent loop and widget procedure export. Figure callback invokes tcl again. Combined map/wind/capture/nested histories are composed, not discovered executed samples. |
| CE07 | [FFI cleanup selection](../../../vendor/gambit/gsc/_ptree2.scm#L2902), 2902–2931, 3235–3245, 3310–3336; [SFUN/CFUN macros](../../../vendor/gambit/include/gambit.h.in#L10040), 10040–10066, 10325–10405; [RC lifecycle](../../../vendor/gambit/lib/mem.c#L674), 674–829, 3969–3996 | Cleanup-type-driven C catcher and conversion-error reentry differ from a semantic foreign-effect boundary. RC locations and scanner updates require actual lifetime/order; they do not protect abandoned Tcl stack resources. |

## Tcl Semantics and Implementation Readings

| ID | Primary evidence | Bounded finding |
| --- | --- | --- |
| CX01 | [catch manual](https://www.tcl-lang.org/man/tcl8.6/TclCmd/catch.htm); [tclCmdAH.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdAH.c), browser source ordinals 277–357 | Ordinary completion codes become visible results/options; normal catch callback can return TCL_OK. Its rewind/limit special branch is distinct from normal error handling. Do not claim every form of cancellation is catchable. |
| CX02 | [try manual](https://www.tcl-lang.org/man/tcl8.6/TclCmd/try.htm); [tclCmdMZ.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdMZ.c), 4856–4899, 5073–5124, 5138–5178 | Normal handler/finally results can replace prior status; -during preserves previous exception information. Rewind/limits have separate early exits, so native cleanup and execution of user finally code are different questions. |
| CX03 | [Cancel API manual](https://www.tcl-lang.org/man/tcl8.6.17/TclLib/Cancel.htm), description/flags; [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), semantics/notes | Explicit cancel-unwind aims past Tcl catch, unlike plain error. API is thread-safe for CancelEval but Canceled is interpreter-thread-sensitive; checks/extensions matter. TIP is design rationale, not a full proof of current interpreter paths. |
| CX04 | [tclBasic.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclBasic.c), 3770–3797, 3825–3898, 3922–3981 | Cancellation request is queued/marked, one-shot and persistent flags differ, reset depends on nesting/force. Request acceptance does not prove all active frames returned or a later request cannot observe cancellation. |
| CX05 | [tclBasic.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclBasic.c), 3732–3749, 8290–8299; [tclCmdAH.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdAH.c), 328–337; [tclCmdMZ.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclCmdMZ.c), 4873–4884 | Coroutine execution-environment rewind, limit and cancellation checks must not be conflated into one flag. Complete cancellation correspondence for bytecode/non-bytecode/try paths remains unresolved. |
| CX06 | [tclEvent.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclEvent.c), 1322–1393, 1413–1458 | vwait/update loop through DoOneEvent and check cancellation/limits; vwait removes its variable trace on return, update clears result. Raw jump can bypass that cleanup; a normal event return does not carry an arbitrary host outcome. |
| CX07 | [DoOneEvent](https://www.tcl-lang.org/man/tcl8.6/TclLib/DoOneEvent.htm), [update](https://www.tcl-lang.org/man/tcl8.6/TclCmd/update.htm), [vwait](https://www.tcl-lang.org/man/tcl8.6/TclCmd/vwait.htm) manuals | Events can recurse. DONT_WAIT avoids sleeping for unavailable work, not time in handlers. vwait's variable write does not complete an outer call while its inner handler remains active. |
| CX08 | [tclEvent.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclEvent.c), 14–44, 139–167, 186–224, 548–564 | Background exception stores result/options, schedules idle handling and resets result; handler expects callers to preserve needed interpreter state; interpreter deletion cancels/disposes pending records. This is not host Scheme delivery. Actual Tk callers remain separate qualification. |
| CX09 | [Prior Tcl source ledger](tcl-command-custody-evidence.md), TX04/TX06–TX09 | Existing string argv post-call release, interpreter/result/image and owner-thread evidence is credited without rereading it as a new binary claim. |

Live general manuals identify Tcl/Tk 8.6.18; the successful cancellation page
identifies 8.6.17. Source readings identify `core-8-6-branch`, not an immutable
commit. Their browser source ordinals are navigation locators, not claimed
downloaded byte hashes. The CancelEval and BgExc manual paths failed; the
successful versioned Cancel page, TIP and source supply the claims. Earlier
retrieval failures remain historical. No installed Tcl/Tk correspondence or
full extension/native-control qualification is inferred.

## Reports, Papers and Language Mechanisms

| ID | Primary evidence | Use and limit |
| --- | --- | --- |
| CL01 | [R7RS report](https://small.r7rs.org/attachment/r7rs.pdf), §§6.10–6.11 | Dynamic extent, hook order and continuable/noncontinuable exceptions provide semantic questions. Its unspecified transfer within hook extent is weaker than Gambit's documented behavior. Do not assume native Gambit raise is the R7RS noncontinuable binding. |
| CL02 | [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), §§2.3, 3.1–3.2 | Mixed stack, deliberate C-frame boundary and resource-cleanup tradeoffs. Learn explicit contracts; do not import one-shot semantics or paper performance numbers. |
| CL03 | [OCaml callback header](https://raw.githubusercontent.com/ocaml/ocaml/5.3/runtime/caml/callback.h), 26–52 | Propagating versus typed-result callbacks are deliberately different interfaces. This supports making a boundary explicit, not equating it with arbitrary Gambit continuation behavior. |
| CL04 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §§5.1.2.4, 7.13.2.1; [prior custody contract](native-callback-custody-contract.md) | Race-free native publication, live same-thread saved environments and stable cleanup state remain requirements. Custody success does not restore skipped Scheme/library semantics. |
| CL05 | [Existing paired language evidence](zig-vs-modern-c-evidence.md), P01–P04; [Zig reference](https://ziglang.org/documentation/0.15.1/) | Prior reviewed tagged state/error/defer/atomic facilities. No new compiler support or foreign-longjmp guarantee is claimed. Generated modern C is the mainline comparator. |

CD01. [Native callback contract](native-callback-custody-contract.md),
[arguments](native-callback-arguments.md), [matrix](native-callback-benefit-matrix.md):
root/cut/writeback and marker laws remain shared support; no duplicate scan
savings or new root system is introduced.

CD02. [Tcl custody design](tcl-command-custody-design.md),
[arguments](tcl-command-custody-arguments.md),
[shared runtime custody](shared-runtime-root-custody-design.md): pre-dispatch
scope grace, producer-owned issuance, derived-work accounting, native result
and module last-return dependencies remain prerequisites.
