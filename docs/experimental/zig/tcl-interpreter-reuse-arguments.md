# Reuse Barrier: Conditional Proofs and Counterexamples

Handwritten arguments over [UR01–UR14](tcl-interpreter-reuse-design.md), with
[pinned source](tcl-interpreter-reuse-evidence.md). Static document validation
checks references and dependency graphs; it does not execute these histories or
mechanically prove runtime correctness. [Cases](tcl-interpreter-reuse-cases.json)
retain explicit missing-premise and refutation traces.

UP01. **Compiled Try exceptional exit.** The selected compiler creates the
ranges and result/options continuations in UR03. Assume a body/handler/finally
exit reports TCL_ERROR, persistent unwind is installed when checkForCatch is
reached, and no foreign jump abandons library cleanup. US06 takes abnormalReturn
before selecting any enclosing Try catch target. Consequently the ordinary
handler/finally recovery instructions at that target are not executed on that
exit. This closes the previous generic-VM-to-Try lowering gap for these selected
paths. It does not cover every execution before the check: a previously executed
finally effect remains, and BREAK/CONTINUE has a direct processCatch branch.
Conditioned exception propagation is not an all-instructions cancellation theorem.
[UR02–UR04]

UP02. **Direct reset counterexample.** Take an interpreter whose ordinary result
release hooks do not themselves reenter or reset it. A direct command's NRCommand
installs unwind and reports error; the direct parser used NOERR, so the outer
TEOV reset was not scheduled. Direct cleanup and string-result mirroring do not
clear the flag. A following nonempty direct evaluation reaches readiness and
rejects while unwind persists. Tcl_ResetResult between the two does not fix the
cancel bit. A noncanonical object evaluation that fails readiness similarly does
not schedule its usual bytecode return callback. These are source-level traces
at US01, not claims of native reproduction or every path behaving identically.
[UR05–UR06, US07–US09]

UP03. **Pending-installation closure.** Assume the epoch/ancestor sender seal is
complete, all old API leases have joined, no untracked target writer exists,
owner is outside an active async invocation, and every thread-wide handler that
can run during the drain has a finite qualified behavior. AsyncMark makes each
old mark visible under its internal mutex; nonrecursive owner AsyncInvoke runs
ready handlers and rescans. After the finite closure returns, no old pending
handler installation remains and no old producer can mark another. Its return
code with interp=NULL does not prove target outcome delivery; the proof depends
on the closed producer set and completed service. AsyncReady alone supplies none
of these premises. A handler-generated descendant must be accounted before its
parent settles. [UR08–UR11, US09–US10]

UP04. **Reset then next-epoch isolation.** Under UP03, establish every target's
actual owner idleness and zero nesting. A qualified facade executing the pinned
non-forced reset then has a clear-state postcondition; an OK code without those
preconditions is insufficient. Keep admission sealed until next descriptor
publication. No old writer or pending handler can reinstall cancellation between
reset and publication. Publish under the lifecycle lock; new consumers acquire
the fresh epoch. Induction over accepted requests shows that a cancellation in
the next epoch is either newly authorized or a protocol violation, never a
legitimate late old request. Resetting before UP03 leaves the UX06 counterexample.
[UR07–UR12, UL01]

UP05. **Stale handle rejection and custody.** The lease/epoch check and seal share
one lock. An old request either acquired a counted lease before the seal or fails
validation before native pointer use. Next epoch cannot publish until all such
leases return. A queued request cannot resolve a new “current” epoch on dispatch;
otherwise pointer-address reuse defeats its intent identity. Failure to acquire,
snapshot, queue or reset leaves the previous owner liable. Rooted managed values
and native images survive until an actual receiver accepts or explicit disposal
settles them, independent of the next interpreter result. [UR08–UR10, UR13]

UP06. **Progress is conditional.** A finite bound requires finite accepted scopes,
async invocations/descendants and per-item work, fair owner service, a terminating
cleanup dependency relation and no required cleanup waiting on its own blocked
barrier. Existing noncooperative native handlers invalidate this premise. Let H
bound the number of handler records encountered per rescan and Q bound handler
invocations in a drain. The inspected AsyncInvoke rescan overhead is
O(H*(Q+1)), plus actual callback work; it is not generally O(H+Q).
Repeated closure phases and root/delivery work add their own costs. Without
finite H/Q/work bounds, latency stays unbounded even if retained custody remains
safe. [UR09–UR13, US10, UD01]

UP07. **Semantic preservation domain.** The barrier starts after accepted control
scopes return and preserves their actual result/options and Scheme outcomes.
It does not move Gambit wind hooks, resume an expired native activation or
translate every continuation into Tcl cancellation. Noncompiled variable traces,
partial finally effects, ordinary handler replacement and -during must remain
part of the admitted trace. Root safety and cancellation isolation cannot prove
all Scheme/Tcl control behavior equivalent. A plain C implementation and Zig
must satisfy the same domain; a provider cannot obtain positive value by deleting
that behavior. [UE01, UR02–UR06, UR14, UL02, UD01]

UP08. **Failure-to-retire safety.** If any reuse predicate cannot be certified,
keep publication closed. The old epoch retains request/outcome/child obligations
and necessary allocator, root scanner and native image support. Once actual
users and request leases return, owner retirement may dispose pending library
state without claiming those requests were observed. A separate explicit outcome
records reset/barrier failure, preserving the original evaluation's result.
Unbounded waiting does not authorize a free, and interpreter deletion does not
mean a Scheme recipient received its result. [UR09, UR12–UR14, UD01]

## Inert Counterexamples and Missing-Premise Traces

| ID | Distinguishing history | Consequence |
| --- | --- | --- |
| UX01 | Direct command installs unwind; NOERR route returns; next nonempty direct call enters readiness | Evaluation return alone does not reset the interpreter |
| UX02 | Tcl_ResetResult runs between those evaluations | Result state reset leaves cancellation installed |
| UX03 | Old cancel already installed; noncanonical Tcl_EvalObjEx fails readiness before scheduling its callback | Merely switching object APIs does not establish reset |
| UX04 | A canonical-list object takes Objv/NRE; a string object takes bytecode | API name alone does not determine reset/callback history |
| UX05 | Noncompiled top-level catch returns OK; TEOV_Exception clears before NRCommand | Conditional reset-before-reassert hazard; completion code is not a cancellation-observed receipt |
| UX06 | Reset returns; delayed old CancelEval marks; next evaluation services it | Reset-before-seal/join/drain violates isolation |
| UX07 | Queued old request resolves “current” interpreter after next epoch publishes | Valid pointer can carry stale intent; bind epoch at acceptance |
| UX08 | Child sender set is sealed, but an ancestor cancellation is still pending | Resetting only the child cannot isolate inherited cancellation |
| UX09 | ResetCancellation(force=0) sees numLevels nonzero and returns OK | Success code does not certify clear state; verify owner-idle pre/postconditions |
| UX10 | Pending/installed cancel coexists with BREAK/CONTINUE's direct processCatch branch | Cannot infer every exceptional route uses the cancellation guard |
| UX11 | Finally performs an effect before the first reached cancellation check, or is bypassed after error | Neither always-run nor never-any-effect claims are valid |
| UX12 | Public zero-word Objv happens to reach TEOV reset on pinned source | Useful source candidate, not a documented portable reset contract; do not hide it in the emitter |
| UX13 | Barrier resets result, invoking a native string freeProc or legacy variable action | Snapshot and retain control/image/resource custody before service; “reset” can have effects |
| UX14 | Unmanaged handler re-marks itself or queues a new target cancel indefinitely | Async drain can fail to terminate; do not promote it on queue observations |
| UX15 | New epoch publishes correctly, then a genuinely new authorized cancel arrives | This is valid new cancellation, not stale contamination or barrier failure |
| UX16 | Old captured Scheme continuation later targets its expired C marker | Epoch reuse cannot revive the native activation; preserve existing validity error |
| UX17 | Barrier runs inside active AsyncInvoke while asyncReady is zero | Nested zero-ready check can miss old pending handlers; no owner-idle receipt |
| UX18 | Reset facade cannot link or fails postcondition; coordinator publishes anyway | Private ABI/source capability and barrier failure must block admission |
| UX19 | Catch/Try stores a result variable; native trace effect occurs before reassertion | Effects remain observable even if a later guard cancels evaluation |
| UX20 | Pinned source bytes match, but an installed library has different flags/ABI or extension writers | Coherent static proof is not installed-runtime qualification |

UX05 is source-composed: actual callback ordering and level premises are stated,
but this document does not claim a reproduced installed Tcl bug. UX10 covers a
control-path caveat, not a guarantee that arbitrary BREAK suppresses cancellation.
No table row is an executed test or exhaustive whole-program result.
