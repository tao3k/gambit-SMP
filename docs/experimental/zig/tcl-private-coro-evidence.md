# Evidence: Private Entry and Coroutine Admission

Pinned Tcl commit: `cbf86d62348d6b052e1961b4df995960fb21545f`.
[Source bindings](tcl-private-coro-source-bindings.json) retain byte hashes,
reproduced Git blobs, LF line ordinals and capture paths. All 364 previous files
are rehashed. Three pinned files were obtained this turn: two are new unique
files (coroutine.n and coroutine.test), while InitStubs.3 is an identical-blob
recapture of an already tree-verified file. The current ledger has 366 unique
files and retains the earlier tree-verified InitStubs binding. The two new API
Git blobs are reproduced without an independent pinned-tree comparison. No installed Tcl,
Tk or private ABI correspondence is established.

AE01. Gambit integration and root authority.

The actual example [tcltk.scm](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50)
uses Tcl_Eval in the selected eval wrapper and Tcl_CreateCommand for callback
registration. Its callback bridge, RC ownership, exception handling and marker
return are obligations retained from the previous studies. The [kernel marker
path](../../../vendor/gambit/lib/_kernel.scm#L1019) remains Scheme-owned. A bounded
text search of vendor/gambit/examples/tcltk and vendor/gambit/lib found the two
public eval/create hits for the selected names and no selected private trace,
reset or cancel producer; this is not a full Gambit or loaded-extension closure.

AX01. Unsupported declaration contract.

[tclInt.decls](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.decls#L1)
lines 1–25 explicitly classify private exported functions as unsupported and
changeable. Slots at 440–449 and 599–605 declare the trace helpers and reset.
Presence in that file is strong evidence of private status, not public admission.

AX02. Stub initialization does not qualify private call state.

[tclStubLib.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclStubLib.c#L51)
51–130 checks the stubs mechanism/package version and copies hook pointers;
118–127 can initialize private tables or leave them null. The pinned
[InitStubs manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/InitStubs.3#L77)
77–94 describes version/table acceptance. The official [stubs guidance](https://www.tcl-lang.org/doc/howto/stubs.tml)
footnote limits its compatibility guarantee to public C interfaces/structures.
This live explanatory page is separate from the pinned source corpus.

AX03. Fresh bounded caller inventory.

The [site inventory](tcl-private-coro-site-inventory.json) is a fresh exact-word
search over the retained 350 committed C/H/M blobs. Declarations, definitions,
comments and stub expressions are counted as lexical occurrences, not calls.
The [caller admission inventory](tcl-private-coro-caller-inventory.json) classifies
the executable TEOV sites, parser and descendant reset, cleanup hooks,
coroutine callouts and hypothetical adapters. No whole-program/alias/installed
claim is made. Optional indexed discovery over Tcl's Tk/thread repositories
found no named private caller; its default-branch index is not a pinned negative
corpus and contributes no absence proof.

AX04. Actual ordinary evaluation and trace producers.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4295)
4295–4335 schedules/increments ordinary command evaluation; 4853–4951 supplies
the four actual trace-check call expressions in two TEOV helpers. 4517–4553
bounds synchronous callbacks by root. 6133–6211 dispatches canonical lists;
8334–8355 stages public NRE evaluation. These establish the creation balance
and distinguish an ordinary entry from a supplied private dispatcher call.

AX05. Trace body and future snapshot writer.

[tclTrace.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclTrace.c#L1420)
1420–1500 and 1526–1648 implement the two trace scanners. 1759–1798 checks the
selected record; 1883–1944 saves/restores whole flags around Tcl_EvalEx and does
record/string cleanup. Native return, not logical child completion, discharges
that old snapshot writer. Its C-stack locals cannot be retained past return.

AX06. Reset predicates and old inline clear obligations.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L4000)
4000–4014 is the force/depth predicate; 4042–4076 clears C during observation;
4669–4695 and 6289–6331 contain inline clears. [tclParse.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclParse.c#L2284)
2284–2316 decrements bracket depth and calls non-force reset even after readiness
ERROR. [tclInterp.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInterp.c#L2096)
2096–2141 forwards reset/force to descendants; 2776–2795 supplies the selected
non-force child-eval caller. The prior direct-string/bracket construction is
retained without claiming its missing depth-zero caller exists.

AX07. Hook implementations must own their effects.

[tclResult.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclResult.c#L919)
919–1003 contains object/internal-rep, legacy freeProc and legacy error-variable
callout edges; 73–170 saves/restores result state rather than all cancel bits.
[SetResult manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/SetResult.3#L217)
217–255 and [ObjectType manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/ObjectType.3#L225)
225–250 specify storage-release/type duties. No concrete hook force-reset
producer or complete reentry/exception/lifetime admission is supplied.

AX08. Context payload and deletion producer.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L110)
110–126 defines four-field frame context save/restore. [tclInt.h](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h#L1417)
1417–1461 separates CorContext, CoroutineData and ExecEnv. tclBasic.c 8726–8808
saves result state, marks rewind, activates on deletion and pairs the caller
callback. These are actual lifecycle producers; absence of flags from context
does not mean flags cannot change through other effects.

AX09. Actual activation, yield and failure arithmetic.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L8877)
8877–8958 adds the suspended offset on resume, returns to caller depth on yield,
and handles C-stack-busy errors before successful depth swap. 8650–8669 stages
yield after checking coroutine presence. An NRE staging return is not final
evaluation completion.

AX10. Discounted root, callouts and terminal compensation.

[tclBasic.c](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclBasic.c#L9184)
9184–9311 creates the command, frames/environment, exit callback and canonical
root; explicit decrement follows staged NRE evaluation. 4556–4591 decrements
before async/cancellation/limit processing. 8812–8857 deletes command and
environment before adding one back and returning the caller environment.
These orderings are relevant even on a source path with zero transient depth.

AX11. Public coroutine semantics and retained fixtures.

[coroutine manual](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/doc/coroutine.n#L23)
23–76 describes suspension, resumption, conventional completion and variable
deletion traces. [coroutine.test](https://github.com/tcltk/tcl/blob/cbf86d62348d6b052e1961b4df995960fb21545f/tests/coroutine.test#L629)
629–642 exercises an early execution trace invoking catch yield; 741–756
describes creation at one level and resumption at another; 757–801 covers
yieldto/event/C-stack-busy interactions. These exact retained source fixtures
are unexecuted here and are not cancellation tests.

AL01. Linearizability supplies an event discipline, not automatic progress.

[Herlihy and Wing, Linearizability](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf),
sections 2–4, distinguishes invocation/response and histories with pending
operations. Application here: reset response, actual clearing, native completion
and new-epoch publication are separate events. A proposed guard needs real-time
and ownership-consistent histories. The paper does not establish this Tcl
adapter's liveness or correctness.

AL02. Learn the native-boundary lesson rather than copying OCaml.

[Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
sections 2.3, 3.1–3.2 and 4.2, distinguishes managed and C frames, resource
cleanup and callback semantics; effects are not permitted to capture C frames.
Application to Gambit/Tcl: represent logical suspension explicitly while
respecting actual native frames and existing roots/markers. This is a design
inference, not equivalence between Gambit continuations, Tcl coroutines and
OCaml effects, and imports no performance figures into this study.

AO01. Prior design obligations remain in force.

[Previous trace reachability](tcl-trace-reachability-design.md),
[writer/reset closure](tcl-cancel-writer-design.md) and
[entry/completion guard](tcl-entry-cancel-design.md) retain raw cancellation,
source reset events, native-return/root custody and unresolved full gates.
This study extends source classification; no previous receipt, native status
or registered claim/witness/relation is rewritten.

## Coroutine Debt, Environment Pairing and Reuse

The [coroutine-invariant study](tcl-coro-invariants-design.md) separates credited/deferred depth, root debt, affine aux updates, two yieldto emitters and direct rewind without ordinary command credit. Its [arguments](tcl-coro-invariants-arguments.md), [source evidence](tcl-coro-invariants-evidence.md), [matrix](tcl-coro-invariants-benefit-matrix.md) and [trace](tcl-coro-invariants-traceability.json) define conditional reuse receipts while retaining all-history producer, pairing and liveness gaps. Design/source research only; no implementation or native tests.
