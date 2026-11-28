# Targeted Cancellation: Source and Paper Evidence

Research date 2026-10-21; research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Tcl source is pinned to `cbf86d62348d6b052e1961b4df995960fb21545f`.
The [source bindings](tcl-targeted-cancel-source-bindings.json) reuse retained
blob-verified bytes, with LF-based line anchors. No installed source correspondence,
private ABI, loaded producer closure or native behavior is inferred from them.
The prior 350-file [lexical corpus](tcl-reuse-producer-corpus.json) was not rerun;
its 14 matching files and 112 occurrences are not calls or execution counts.

TE01. Real Gambit integration: [setup/direct evaluation/native callback and string custody](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50),
50–195; [DoOneEvent Scheme event loop and shutdown](../../../vendor/gambit/examples/tcltk/tcltk.scm#L347),
347–425; [actual callback](../../../vendor/gambit/examples/tcltk/fig16-10.scm#L24),
24–28; [processor/first-return validity](../../../vendor/gambit/lib/_kernel.scm#L1019),
1019–1071. Global interpreter and a Scheme mutex do not establish OS-owner idleness,
managed cancellation, epochs or native-return coverage. Existing root/marker and
continuation validity remain Gambit-owned; this study adds no second collector.

| ID | Pinned primary source and LF ranges | Finding used by this design |
| --- | --- | --- |
| TX01 | [CancelInfo](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L90), 90–109; [CancelEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4145), 4145–4210 | One shared pending byte payload/flags; clientData ignored; C lock serializes updates; mark called under C. No epoch/request queue or explicit observed acknowledgement. Existing resultObj ownership behavior must be preserved in the raw API. |
| TX02 | [AsyncHandler and TLS](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L21), 21–66; create 113–140; mark 159–171 | Token stores ready/proc/data/owner/list links. Create appends; mark takes owner A and sets level-triggered ready, suppressing global readiness update while active. |
| TX03 | [Invoke](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L193), 193–243; delete 271–315; ready query 336–349 | Clear ready under A, unlock for callback, rescan from head; owner-sensitive delete frees token. There is no target settlement/epoch receipt here. |
| TX04 | [Cancel callback](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467), 3467–3520; Canceled 4045–4121; reset 4000–4015; [flag macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156), 2156–2172 | Callback uses stored target and current pending fields under C, propagates descendants and installs message. CANCELED one-shot, installed UNWIND sticky; non-forced reset may return OK without clearing if nested. |
| TX05 | [Token registration/deletion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L710), 710–724, 1426–1493; [internal child creation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2311), 2311–2375 | Per-interpreter token/table lifetime, deletion C -> AsyncDelete/A. Internal constructors require source integration; wrapping only public CreateInterp is incomplete. |
| TX06 | [Descendant flags](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096), 2096–2141; [builtin interp cancel](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L682), 682–752 | Recursive set/reset and a script-level real producer calling raw CancelEval. No host epoch implicitly attached. |
| TX07 | [Notifier](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclNotify.c#L600), 600–624, 844–863, 1032–1058; [after wait](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTimer.c#L1031), 1031–1089; [parser reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2281), 2281–2316; [fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTest.c#L729), 729–935 | Event service can invoke async without evaluator context, parser can reset while surrounding host activation remains; fixture has delayed marks/script-capable handler. Not proof fixtures are installed or all Tk/plugin paths are covered. |
| TX08 | [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md), Behavior, especially idle-next-script rule, and C API | Raw idle cancellation must survive for the next script; clientData reserved; raw CancelEval callable from any thread. This is specification evidence, not proof of every installed path's conformance. |
| TX09 | [Private reset declaration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.decls#L599), 599–602; [stub bootstrap](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclStubLib.c#L50), 50–131; [result reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919), 919–961 | Current private reset is not targeted settlement. Binding/source/image qualification remains. Result reset can execute freeProc/other actions; it is excluded from the final commit interval. |
| TX10 | [Prior source producer inventory](tcl-reuse-service-callers.json), [pinned source ledger](tcl-reuse-service-source-bindings.json) and [lexical corpus](tcl-reuse-producer-corpus.json) | Selected source families, not installed/indirect/generated/loaded closure. Existing provenance-free instances and untracked raw writers keep clean adoption unresolved. |

TL01. Herlihy and Wing, [Linearizability: A Correctness Condition for Concurrent Objects](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
1990, §§2–4. Use a declared sequential contract and ordering points to reason about
concurrent acceptance/settlement/publication; composition does not prove a wrong
raw contract correct. The paper supplies a method, not a proof or implementation
of this design, and no lock-free progress claim is transferred to these mutexes.

TL02. [C11 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
§5.1.2.4 and §7.17.3: publish initialized descriptors with synchronization; copied
plain or relaxed state is insufficient. Tcl's actual mutex mapping and mixed
language implementation still need platform qualification.

TL03. Sivaramakrishnan et al., [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
PLDI 2021, §§2.3, 3.1–3.2. Learn to make C frames, roots, effect boundaries and cleanup
explicit; do not copy OCaml's continuation restrictions onto Gambit or infer that
Tcl cancellation/async delivery can revive a returned C activation. Gambit's
actual marker/processor checks are TE01. No paper benchmark is a Gambit speedup.

TO01. Prior architecture: [service](tcl-reuse-service-design.md),
[service proofs](tcl-reuse-service-arguments.md),
[interpreter reuse](tcl-interpreter-reuse-design.md),
[control boundary](tcl-control-boundary-design.md) and
[command custody](tcl-command-custody-design.md). These are design dependencies,
not independent source/runtime witnesses. This study refines the targeted option
and explicitly retains the mixed-domain and installed/native evidence gaps.

The [mixed-history follow-up](tcl-mixed-cancel-evidence.md) reviews destructive
checks and distinct evaluation/reset paths from the same pinned source bytes.
[Its trace](tcl-mixed-cancel-traceability.json) records conditional discharge and
refusal rules; it is not an installed/native or fully general mixed-policy witness.
