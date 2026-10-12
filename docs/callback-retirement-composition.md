# Callback Return And Processor Retirement Composition

## Source Findings

The pinned `lib/c_intf.c:___make_sfun_stack_marker` stores the Scheme procedure
and original processor ID in a vector. `___kill_sfun_stack_marker` clears the
procedure field and decrements the marker's reference count. The cumulative
callback candidate already protects `proc_or_false` across allocation with
`GC_SAVE1/RESTORE1`; that fixes an allocation-root hazard, not a C-frame lifetime
protocol.

`lib/setup.c:___call` leaves a Scheme return frame containing that marker, enters
the trampoline and expects an unwind back into its **still active C invocation**.
The generated `BEGIN/END_SFUN` macros in `include/gambit.h.in` kill the marker
after the call/result handling. `_kernel.scm` first compares the stored
processor ID with the current one; a mismatched processor migrates back before
returning to C. The current result-preservation patch addresses this value path.

The cumulative shrink path removes the retiring processor from the scheduling
deque, cleans its interrupt/OS state and exits its OS thread; P0 subsequently
joins before memory cleanup. Inspection finds no C-stack-marker admission/drain
or incarnation validation in that path. A joined OS thread and a heap-copied
Scheme continuation do not imply that a nested foreign invocation returned.

This is a missing proof obligation, **not a demonstrated native crash**. Actual
reachability of shrink while a nested callback needs the retiring processor,
the embedding API's supported concurrency contract, and whether the runtime
entry frame may intentionally be abandoned must be established. In particular,
`___run` also creates a marker: treating every live marker as an unreturnable
foreign borrower would incorrectly prevent normal worker retirement.

## Executable Composition

`callback_retirement_composition.qnt` imports the actual transition relations of
`callback_return_owned_result` and a checked alpha-renaming of
`resize_saved_stack_retirement`. Quint 0.33.0's effect checker rejects combining
the two plain imports' identically named `s` variables. The isolated retirement
file changes only the module name and state identifier, with exact template
equality checked in regression tests; no guard, domain or action changes.
Existing model files and receipts stay untouched. Migration's
body return is paired with capture; routing is paired with execution detach.
Subsequent callback collection/resume/restore and saved-frame publish/scan/copy
interleave independently. These interface pairings are abstraction assumptions,
not claims that native macro and queue operations are atomic.

The extra state distinguishes marker validity, outstanding C activation,
conversion completion, original processor generation, slot generation and
collective quiescence. Processor 1 is a removable origin and 0 is a surviving
destination: two semantic roles, not a CPU limit. Three opaque result identities
are explored. The fixed design drains the callback before collective quiescence
and retires only after both the C activation and raw Scheme frame are safe.

Four counterexamples test independent obligations:

1. Heap copying alone permits retirement while the C activation is outstanding.
2. Killing the marker at migration loses a still-required return destination.
3. Reusing a numeric processor ID lets an old callback return to a new slot
   generation even though the local return model's ID equality still holds.
4. Entering collective quiescence before waiting for the callback can disable
   the very scheduling needed to finish it, producing a nonterminal deadlock.

No asynchronous future can be assumed to return once every action that would
complete it is disabled. Join success cannot substitute for callback return;
root copying cannot substitute for a surviving C stack. The fourth control is
a design hazard, not attribution of this exact schedule to current native code.

## Design And Remaining Gates

Do not fix this with a global lock held across foreign calls, copying or GC.
Candidate designs include an explicit per-incarnation foreign-borrow admission
protocol, or a documented/reported refusal of unsupported shrink **before**
entering a blocking collective. Classification of runtime entry versus nested
SFUN calls, nested/exception paths, failed admission rollback, generation
wraparound and C memory ordering require model/source refinement first.

A counter alone is not a solution: acquisition must race safely with closing,
and failed or nonlocal exits must release exactly once without touching retired
storage. This composition does not yet implement any such source redesign.
It assumes ordinary callback completion under fair protocol scheduling; hooks
that never return, OS starvation and arbitrary embedding calls are not covered.

The complete SMP/native/bootstrap/Gerbil correctness and retained native
startup/build/test/stability gates remain open. No budget is widened, feature
disabled, new runtime serialization added or speedup claimed here.
