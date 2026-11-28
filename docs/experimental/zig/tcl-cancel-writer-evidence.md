# Cancellation Writer Evidence and Research Boundary

The [ledger](tcl-cancel-writer-source-bindings.json) binds exact captures and LF
anchors; the [corpus](tcl-cancel-writer-corpus.json) binds the full declared
350-file text selection. No source/native implementation or performance test.

WE01. Gambit remains the semantic and runtime owner.

Local `vendor/gambit/examples/tcltk/tcltk.scm` lines 50–123, 125–195 and 347–425
bind the foreign object, command registration, callback marker/root conversion
and result boundary; `fig16-10.scm` lines 24–28 and `_kernel.scm` lines 1019–1071
bind real callback usage and relevant runtime control. These source ranges are
rehashed in the trace; no new Scheme source was changed. Prior root/marker and
native-return obligations are retained, not replaced by payload refcounting.

WX01. Full selected committed-source text inventory and broad audit.

All 350 `.c`/`.h`/`.m` blobs from the earlier untruncated pinned Git tree were
reread, byte/hash/blob checked; 324 were recaptured, 26 reused. The cancellation
word pattern has 10 matching files, 104 LF lines, 114 occurrences. The separate
whole-assignment/saved-word/constructor/trace audit has 99 lines and includes
unrelated object types. The method is text search followed by selected source
inspection, not AST/alias analysis, preprocessing, loaded-image or Tk closure.
[Corpus](tcl-cancel-writer-corpus.json), [audit](tcl-cancel-writer-flag-audit.json).

WX02. Pending data, constructor and raw acceptance.

Pinned [CancelInfo](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L90),
[constructor flags](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L631),
[token/message initialization](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L710),
[raw cancellation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4145).
The raw NULL branch assigns away the prior result pointer without a visible free
at that branch; installer retains the pending buffer and deletion frees only the
then-current pointer. This is a source-local ownership-loss history, not a measured
whole-runtime leak frequency or a claimed performance gain. The new service must
define default-message replacement retirement explicitly.

WX03. Install flags, child propagation and target diagnostic.

[CancelEvalProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L3467),
[cancel macros](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L2156),
[recursive helper](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096).
Installer reads the retained pending record; it sets only the target message and
sets descendant flags. Macro parameters do not prove arbitrary flags harmless;
only C and optional U are copied into the installed cancellation bits.

WX04. Destructive checks and private reset.

[TclResetCancellation](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4000),
[Tcl_Canceled](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4042).
C is cleared before UNWIND-only filtering; the display path constructs a string
with -1 length. Private reset OK may be a no-op and never clears the pending slot.

WX05. Inline reset points and completion-sensitive successors.

[NRCommand](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4556),
[exception scheduling](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4608),
[TEOV_Exception](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4669),
[bytecode early readiness](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6214),
[bytecode completion](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L6289).
Clear points precede some checks/cleanup; adding a final-only reset is insufficient.

WX06. Real child/parser reset callers and private ABI.

[ChildEval](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2776),
[substitution branch](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2284),
[private stub entry](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L574),
[reset macro](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L1320),
[child compatibility alias](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclIntDecls.h#L1432).
The stub slots are observable ingress, not proof of actually loaded clients.

WX07. Object callouts and mutex boundary.

[Tcl_ObjType hooks](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tcl.h#L794),
[decrement path](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L3675),
[string/internal-representation path](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L3859),
[result reset](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919),
[pinned Unix mutex](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/unix/tclUnixThrd.c#L471).
The pinned Thread manual warns against same-thread double-lock, and threadless
macros are empty; installed Darwin lock/thread configuration remains unqualified.
Hook reachability does not establish every recursive Tcl call legal.

WX08. Newly exposed whole-flag writer and actual trace routes.

[TraceExecutionProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1759),
[save/eval/restore](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1883),
[direct call](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1469),
[indirect route](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1588),
[step registration](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1918).
These are real function/callback paths, not an observed cancellation failure.
The broad audit identifies constructor and trace as whole `iPtr->flags =`
destinations in the selected exact source; arbitrary alias closure remains open.

WX09. Async claims and destruction.

[async claim/callback/rescan](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L193),
[owner token delete](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclAsync.c#L271),
[DeleteInterpProc](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L1426),
[deletion cancel block](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L1469).
Do not free callback clientData after unlink without joining an already selected
callback; the new lease mechanism is a proposal, not a current Tcl guarantee.

WX10. Actual cancellation producers and argument ownership discrepancy.

[builtin interp cancel](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L739),
[thread fixture](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadTest.c#L954),
[public stub](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclDecls.h#L3794),
[pinned Cancel manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/Cancel.3#L23).
Manual says non-NULL argument decremented before return; actual early failure
branches precede that decrement. Preserve/report the discrepancy rather than
inventing one uniform legacy ownership rule. The fixture unlocks its thread-list
mutex before raw cancellation; it is not a proven lifetime-safe managed caller.

WX11. Result-state restoration does not restore the whole cancellation word.

[Tcl_SaveInterpState](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L65),
[Tcl_RestoreInterpState](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L125).
Its flag mask is ERR_ALREADY_LOGGED; do not confuse it with WX08's whole-word
assignment. TclCreateInterp's known public and child callers pass zero or
SAFE_INTERP; private constructor ingress still needs the profile's input contract.

WX12. Installation actually copies the target's explicit bytes.

[Tcl_SetStringObj](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclStringObj.c#L853)
frees/invalidate previous representations and calls
[TclInitStringRep](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L3838),
which allocates length+1, copies length bytes and appends NUL for nonempty input.
This supports the I*M installation-copy opportunity, while actual result/errorCode
copying, allocation rates and end-to-end performance remain unmeasured.

WL01. Herlihy and Wing, Linearizability (1990), sections 2–4.

[Primary paper](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf).
Use explicit operation histories, sequential meanings and commit cuts to reason
about acceptance versus supersession; the paper does not prove this design.

WL02. C memory model, N1570 sections 5.1.2.4 and 7.17.3.

[Committee draft](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf).
Publication/read/refcount rules require race-free synchronization; immutable bytes
alone do not establish lifetime or a happens-before edge. Actual native mutex/
atomic mappings remain to be qualified in each provider.

WL03. Sivaramakrishnan et al., Retrofitting Effect Handlers onto OCaml (2021).

[Primary paper](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), sections
2.3 and 3.1–3.2. Learn to make native-stack, continuation and cleanup boundaries
explicit; do not copy OCaml restrictions or borrow its benchmark percentages as
evidence for Gambit/Tcl/Zig.

WO01. Prior contracts and TIP behavior remain separate evidence layers.

[Gate/guard](tcl-entry-cancel-design.md), [next evaluation](tcl-next-evaluation-design.md),
[mixed history](tcl-mixed-cancel-design.md), [service](tcl-reuse-service-design.md)
and [TIP 285](https://core.tcl-lang.org/tips/doc/trunk/tip/285.md) provide the
existing requirements. TIP requires core integration and distinguishes catchable
cancellation/unwind and idle-next-evaluation behavior. It does not imply raw
shared bits contain managed provenance or that a late guard fixes trace restores.
Full source/semantic/retirement/total-cost/Zig-increment requirements remain
unresolved; no registered witness or gate is promoted by this study.

## Trace Evidence Follow-Up

The [trace evidence study](tcl-trace-cancel-evidence.md) reads pinned doc/trace.n and tests/trace.test, binds three recursion domains and actual trace caller/result/delete paths, and freshly searches the retained 350-blob selection with a trace-specific pattern. Upstream fixtures are unexecuted preservation obligations; bit-level counterexamples are not promoted to native reachability. [Ledger](tcl-trace-cancel-source-bindings.json), [trace](tcl-trace-cancel-traceability.json).
