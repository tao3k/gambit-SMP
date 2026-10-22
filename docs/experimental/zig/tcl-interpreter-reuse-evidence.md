# Tcl Interpreter Reuse: Coherent Source Evidence

Read 2026-10-21. Research HEAD `1a2d8612f2065387c62858e10baf63ce369cc48c`;
Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.

US01. This study resolved Tcl branch `core-8-6-branch` through the public
[GitHub branch endpoint](https://api.github.com/repos/tcltk/tcl/branches/core-8-6-branch)
to commit `cbf86d62348d6b052e1961b4df995960fb21545f`, then fetched 20 files at that immutable commit through the
GitHub connector. Every captured UTF-8 file reproduced its returned Git blob
SHA-1; SHA-256 and exact line counts are retained in the
[source bindings](tcl-reuse-source-bindings.json). Raw study inputs are under
`.cache/tasks/tcl-interpreter-reuse/source/`; none was compiled or executed.
The initial raw URL/web cache miss and sandbox curl DNS failure are retained
as retrieval history, not a current compiler-source gap. Installed Tcl/Tk,
private-stub linkage, build flags and all extension users remain unqualified.
The earlier unpinned readings/receipts remain unchanged historical evidence.

## Gambit Caller and Control Evidence

UE01. [Actual Tcl bridge](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–122, 124–195, 347–425; [event reentry](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28: setup/delete, direct Tcl_Eval, Scheme error entry, callback/string release
and DoOneEvent service are actual selected callers. No current CancelEval/reset
adapter is established here. [Scheme wind](../../../vendor/gambit/lib/_thread.scm#L4794),
4794–4819, 4908–5080 and [native return](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071 preserve the separate managed-control/native-activation obligations.
Local working-file hashes and exact spans are in the [trace](tcl-interpreter-reuse-traceability.json).

## Pinned Tcl Paths

All links below bind the same commit; locators are actual captured file lines,
not browser reflow ordinals.

| ID | Pinned source and exact ranges | Bounded finding |
| --- | --- | --- |
| US02 | [Try selection](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompCmdsSZ.c#L2752), 2752–2967; [BODY macro](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompile.h#L1533), 1533–1543; [word compilation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompile.c#L2574), 2574–2599 | Four selections; static handler/finally restrictions and cleanup on fallback; BODY emits inline script or token evaluation plus EVAL_STK. |
| US03 | [Handlers without finally](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompCmdsSZ.c#L2987), 2987–3193 | Body catch range, optional on-ok handling, code/prefix matching, local bindings, chained handlers, error options/-during, RETURN_STK. |
| US04 | [Finally without handlers](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompCmdsSZ.c#L3489), 3489–3559 | Body and finally catch ranges, saved result/options on operand stack, ordinary final-result arbitration and reissue. |
| US05 | [Handlers and finally](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCompCmdsSZ.c#L3197), 3197–3486 | Body/handler-binding/finally catch ranges, anonymous result/options locals, on-ok/chain paths and -during replacement. |
| US06 | [VM cancellation and exceptions](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclExecute.c#L2349), 2349–2381, 2474–2505, 7931–8005, 8044–8203 | Reached polling converts cancellation into error; checkForCatch bypasses ranges. BREAK/CONTINUE can branch directly to processCatch. Library abnormal cleanup differs from user finally. |
| US07 | [Direct evaluation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L5075), 5075–5087, 5419–5441, 5525–5542, 6003–6022; [ResetResult](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919), 919–961 | Direct dispatch passes NOERR; its cleanup does not clear cancel flags. ResetResult clears error/result state, invokes release/legacy variable behavior, and leaves cancel bits intact. |
| US08 | [Objv/NRE and reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4253), 4253–4345, 4556–4590, 4612–4695; [object-route choice](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6119), 6119–6245, 6289–6337; readiness/reset/active 3930–4015, 4228–4233 | TEOV reset before decrement, canonical-list route distinct from bytecode object route, readiness failure before callback scheduling; ResetCancellation OK does not certify it cleared a nonzero-level interpreter. |
| US09 | [Pending cancellation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467), 3467–3520, 4045–4121, 4145–4223; [flag macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172 | Async callback uses stored interpreter, sets self/child flags and returns prior code; pending request has no host epoch; persistent and one-shot bits differ. |
| US10 | [Async mark/invoke](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L159), 159–171, 193–243; [child flags](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096), 2096–2141, 2776–2820 | Invoke rescans ready handlers on the owner; asyncReady can be zero during active invocation. Parent and descendant state must share the seal/reset frontier. |
| US11 | [Private reset declaration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.decls#L599), 599–602; [internal stub](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L573), 573–575, 1320–1321; [public declarations](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclDecls.h) | ResetCancellation is internal stub slot 237. Full public header text has no matching declaration. Presence of a private slot is not supported linkage or a stable public reset API. |
| US12 | [Catch callback](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCmdAH.c#L299), 299–375; [Try callbacks](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclCmdMZ.c#L5097), 5097–5145, 5276–5293, 5310–5380, 5396–5438; [API docs](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Async.3), 83–160; [Eval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Eval.3), 95–144; [Cancel](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3), 20–65 | Callback bookkeeping and newly evaluated user scripts differ; public async service is thread-wide. Public docs do not promise an empty-evaluation reset barrier. |

UL01. [C11 committee draft N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4 and §7.17.3: use actual happens-before synchronization for publication;
volatile fields alone do not supply it. The proposed lifecycle lock protocol is
a design choice, not an assertion about uninspected Tcl/Zig ABI combinations.

UL02. [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
§§2.3, 3.1–3.2: study foreign control, managed roots and cleanup together. The
lesson for Gambit is an explicit supported control corridor; no OCaml behavior,
benchmark percentage or foreign-frame restriction is copied into Gambit's API.

UD01. Prior arguments are credited: [cancellation propagation](tcl-cancel-propagation-design.md),
[conditional cases](tcl-cancel-propagation-arguments.md),
[control boundary](tcl-control-boundary-design.md),
[custody](tcl-command-custody-design.md), and
[prior paired-language matrix](tcl-cancel-propagation-benefit-matrix.md).
This study closes the compiler-source retrieval gap and strengthens selected
source-level derivations; it does not promote native, full semantic or Zig-value gates.

## Expanded Producer and Stub Evidence

The [service evidence ledger](tcl-reuse-service-evidence.md) adds stub/archive
bootstrap, internal child creation, notifier/timer consumers and tclParse's token
substitution reset. Its lexical corpus covers 350 committed C/H/Objective-C files;
it does not prove loaded extension/Tk closure. New line counts use LF byte lines
so form-feed separators do not inflate source-line totals; prior source hashes
and immutable evidence receipts remain unchanged.
