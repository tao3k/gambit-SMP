# Tcl Command Custody: Source and Primary Evidence

Reviewed 2026-10-21. Research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact local working bytes and
line intervals are bound in the [trace](tcl-command-custody-traceability.json).
Remote reading identities are recorded separately in
[external readings](tcl-command-external-readings.json): they are not installed
library identities, downloaded raw-source hashes or native qualification.
No implementation, expansion, native test, model or performance run.

## Local Gambit Callers

| ID | Source anchors | Observation / boundary |
| --- | --- | --- |
| TE01 | [Tcl registration and callbacks](../../../vendor/gambit/examples/tcltk/tcltk.scm#L124), 124–195, 217–228, 245–345 | RC client data and still vector; native entry reads cd once before Scheme call; result transfers to custom free callback; delete releases vector then RC; final create Boolean branch has no explicit NULL disposal. No post-Scheme-return cd read in this function. |
| TE02 | [Widget procedure export](../../../vendor/gambit/examples/tcltk/tcltk.scm#L575), 575–618, 650–674; [real bind callback](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24), 24–28 | Procedure-valued widget arguments become exported commands; public define/export/remove wrappers exist; double-click handler reenters tcl. This is a real native callback producer/reentry client, not a map/capture combined test. |
| TE03 | [Interpreter setup/cleanup](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50), 50–122, 201–215; [event loop/exit](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347), 347–425 | Global interpreter, Tcl/Tk init, delete and eval; active Scheme thread polls DoOneEvent(DONT_WAIT), sleeps and joins. Tk_MainLoop binding is commented, alternate definition is quoted. Source does not establish creating-OS-thread affinity or arbitrary reentrant shutdown progress. |
| TE04 | [Conversion cleanup selection](../../../vendor/gambit/gsc/_ptree2.scm#L2902), 2902–2931, 3235–3245, 3310–3336; [CFUN/SFUN](../../../vendor/gambit/include/gambit.h.in#L10040), 10040–10066, 10325–10405; [TRY](../../../vendor/gambit/include/gambit.h.in#L9978), 9978–10012 | CFUN body catcher depends on argument cleanup types; zero arguments choose no parameter cleanup. Catching outside a Tcl body does not execute Tcl cleanup inside it. SFUN END and conversion-error reentry are distinct paths; no whole native effect inference is established. |
| TE05 | [Marker allocation](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562; [call/run](../../../vendor/gambit/lib/setup.c#L3275), 3275–3422; [return handler](../../../vendor/gambit/lib/_kernel.scm#L1019), 1019–1071; [documented capture example](../../../vendor/gambit/doc/gambit.txi#L12208), 12208–12267 | Root-before-marker TODO, logical RA/marker frame, matched/unmatched unwind and marker/processor errors. Retaining a continuation cannot revive an expired native return. No current executable was run. |
| TE06 | [RC lifecycle](../../../vendor/gambit/lib/mem.c#L674), 674–829; [still reference counts](../../../vendor/gambit/lib/mem.c#L1443), 1443–1473, 1730–1741; [scan](../../../vendor/gambit/lib/mem.c#L3969), 3969–3996; [existing patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), 3160–3234, 3433–3452 | Plain RC/still operations, forced cleanup and updateable data scan. Existing per-processor marking/donor transfer credited. Candidate owner/scan/retirement protocol must serialize actual users rather than assume atomic refcounts. |
| TE07 | [String release](../../../vendor/gambit/lib/c_intf.c#L1756), 1756–1776; [native copy](../../../vendor/gambit/lib/c_intf.c#L3199), 3199–3310; [build recipe](../../../vendor/gambit/examples/tcltk/makefile.in#L69), 69–98 | Result free calls release_rc; encoded strings already use native copy/allocation. Tcl_FreeProc cast and allocator pairing need ABI qualification or an exact-signature adapter. Example build inputs do not identify the currently loaded Tcl/Tk source or binary. |

## Tcl API and Source Readings

| ID | Primary evidence and selected location | Bounded observation |
| --- | --- | --- |
| TX01 | [CreateCommand manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/CrtCommand.htm), description | Creation/replacement/deletion callback contract; NULL for deleting interpreter; borrowed argv ownership. A token/Boolean is not a general transactional ownership receipt. |
| TX02 | [CreateObjCommand/DeleteCommand manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/CrtObjCmd.htm), deletion and command info | Delete hooks and token-based removal; renamed commands require identity-aware removal. Mixed string/object replacement has special rules, so object conversion is not a mechanical semantic substitution. |
| TX03 | [Preserve/Release/EventuallyFree manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/Preserve.htm), description | Storage can be held across reentrant deletion and freed at last release. Deductions: preserve/retire must use the same storage identity and matched protocol; preserving interpreter alone does not preserve extension data or Scheme roots. |
| TX04 | [tclBasic.c branch reading](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclBasic.c), browser source-line ordinals 1974–2132, 2387–2409, 2978–3139, 3348–3355, 4225–4306, 5124–5222 | Create has pre-install NULL returns; replacement may directly discard a recreated command; deleteProc precedes final command-structure cleanup; string argv is freed after callback return; normal/NRE evaluation performs post-call cleanup. These establish gaps an external longjmp can bypass. Branch/line reading only, not byte-pinned installed source. |
| TX05 | [Tcl threads manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/Thread.htm), introduction | One interpreter may only be used by its creating thread. A mutex does not grant permission to migrate its operations to another OS thread. |
| TX06 | [SetResult manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/SetResult.htm), freeProc section | Tcl owns/retains results under the specified policy; custom callback handles non-Tcl allocation; VOLATILE copies. Results may be replaced independently of command deletion. Preserve exact callback ABI and allocator. |
| TX07 | [tclResult.c branch reading](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclResult.c), rendered lines 3–8, 47–50 | Saved interpreter state has restore/discard obligations; FreeResult invokes its custom free callback. Result preservation does not provide general library-stack restoration. Rendered lines here are folded web text, not physical raw-file line anchors. |
| TX08 | [CreateInterp/DeleteInterp manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/CrtInterp.htm), memory management; [tclBasic.c](https://raw.githubusercontent.com/tcltk/tcl/core-8-6-branch/generic/tclBasic.c), 1279–1328 | Logical deletion and eventual storage destruction differ; active use needs an owned preserve/release discipline. Preserve does not keep further eval logically enabled after deletion. |
| TX09 | [DoOneEvent manual](https://www.tcl-lang.org/man/tcl8.6/TclLib/DoOneEvent.htm), description | Event processing may recurse; DONT_WAIT avoids sleeping for absent events, not arbitrary time inside a handler. Its event-work result differs from a Tcl command completion code. |
| TX10 | [catch manual](https://www.tcl-lang.org/man/tcl8.6/TclCmd/catch.htm), description | Tcl can catch exceptional command return codes and continue. Hence a return-code sentinel is not proof of an immediate, uncatchable Scheme transfer. |
| TX11 | [DoOneEvent](https://www.tcl-lang.org/man/tcl8.6/TclLib/DoOneEvent.htm) and [SetResult](https://www.tcl-lang.org/man/tcl8.6/TclLib/SetResult.htm) | Event and command-result boundaries need separate adapters; a scope must record which interface actually delivered the callback. No new independent claim of their internals is made. |

The live manuals identify themselves as Tcl/Tk 8.6.18; branch readings use
`core-8-6-branch`. Neither establishes which Tcl/Tk the Gambit example would
load here. No local Tcl source checkout was found in vendor. A tagged raw
tclBasic read failed, the GitHub commit endpoint was unavailable, and shell
retrieval failed DNS resolution. Thus no immutable remote commit or full-source
hash is asserted. Separate DeleteCommand/DeleteInterp/SaveResult/SaveInterpState
and cancellation-page fetches failed; claims use the successful pages/source
above. Failed retrievals are retained as gaps, not converted into evidence.

## Papers and Language/Runtime Mechanisms

| ID | Evidence | Learning and limit |
| --- | --- | --- |
| TL01 | [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), §§2.3, 3.1–3.2 | Explicit C-frame capture boundary and resource-cleanup tradeoffs. Gambit's existing Scheme continuation and native-marker laws remain distinct; OCaml's one-shot choice is not imported. |
| TL02 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §§5.1.2.4, 7.13.2.1 | Race-free accesses, live same-thread saved environment and changed setjmp-local restrictions constrain custody ledgers. An outer saved environment cannot recreate library cleanup skipped by jumping to it. |
| TL03 | [OCaml C interface](https://ocaml.org/manual/5.3/intfc.html), §§5, 7, 12; [callback header](https://raw.githubusercontent.com/ocaml/ocaml/5.3/runtime/caml/callback.h), 26–52 | Roots, execution permission and pending actions have separate contracts. Propagating and typed result callbacks are explicit API alternatives, not interchangeable control semantics. |
| TL04 | [Existing paired language evidence](zig-vs-modern-c-evidence.md), P01–P04; [Zig reference](https://ziglang.org/documentation/0.15.1/) | Tagged representations/ordinary cleanup may improve expression; foreign root lifetime, Tcl affinity and unsupported longjmp remain common obligations. Generated modern C is the comparator. |

ND01. [Native callback contract](native-callback-custody-contract.md),
[arguments](native-callback-arguments.md) and
[matrix](native-callback-benefit-matrix.md): root/writeback, independent native
return capability, callback nesting and scan savings are credited once.

ND02. [Shared runtime root custody](shared-runtime-root-custody-design.md),
[release synchronization](device-release-sync-proof.md) and
[generated native contract](generated-c-native-contract.md): accepted derived
work, lifetime receipts and Scheme-generated shared policy remain the mainline.
