# Conditional Arguments and Counterexamples

Handwritten source arguments and inert cases only. No checked proof, model,
fixture, native or performance run. Definitions and source groups are in the
[design](tcl-private-coro-design.md) and [evidence](tcl-private-coro-evidence.md).

AP01. Private symbol presence does not entail supported invocation.

Premises: exact declaration header and stub initialization are read; caller
identity/effect contract is unknown. The declaration labels the interfaces
unsupported; initialization copies table hooks rather than checking individual
call-state/lifetime preconditions. Therefore a non-null function pointer cannot
issue PrivateTraceAdmission or ResetAdmission. A project can own a pinned
private adapter, but must supply its missing obligations. Counterexample to an
overstrong rejection: "unsupported" does not imply physically uncallable.
Counterexample to an overstrong acceptance: a public stubs version match says
nothing about valid Command/ExecEnv pointers. [AD01–AD04, AX01, AX02]

AP02. Depth-zero UNWIND resurrection remains a body construction.

Assume an actual valid private entry at n=0, U=1 and a trace prefix beginning
with bracket substitution. Trace saves U; direct string parsing enters bracket
depth 1; readiness observes U and returns ERROR before the bracket body; bracket
decrement returns to zero and non-force reset clears U; old trace restores the
saved flags, reintroducing U. Every branch is source-defined. The assumed
entry is not supplied by the identified ordinary TEOV callers. Consequently
the conditional construction is closed while its real legal producer remains
unresolved. A zero-depth cleanup phase elsewhere does not join these edges
without an actual call. [AD02, AD03, AD14, AX04–AX06, AO01]

AP03. Coroutine creation's explicit decrement balances a staged command.

Premises: ordinary successful coroutine construction, new canonical list,
Tcl_NREvalObj staging and normal callback protocols. Canonical-list dispatch
calls TclNREvalObjv, which schedules NRCommand and increments n. The explicit
decrement after Tcl_NREvalObj cancels that increment, not the enclosing
coroutine-command increment. Initial aux=0; activation adds zero. Later root
NRCommand decrements n; exit eventually adds one. At caller activation depth
d=1 the intermediate n=0 is possible before async checks/terminal cleanup.
This is not idle or a native function return. Directly calling private bodies
outside their command wrapper violates these premises. [AD06, AD07, AX04,
AX08–AX10]

AP04. A positive older trace floor survives a bounded nested coroutine.

Premises: live native trace depth h>=1; ordinary nested command increment gives
d>=h+1; admitted balanced callback pairing and nonnegative a; no private depth
mutation, unknown writer, foreign stack escape or pending old environment
restoration outside the pairing. Resume n=d+a>=d; yield restores d; terminal
root reaches d-1>=h before exit restores d. Composition preserves h across
these phases. Catalogued non-force reset predicates therefore remain false
beneath that older trace. Canceled checks clear only C and installers do not
clear U, so they cannot supply U:1->0 there. This is conditional arithmetic,
not a complete invariant for tailcall/yieldto/alias/deletion/loaded histories.
Aux nonnegativity cannot be inferred merely from its signed C field. [AD08,
AX04, AX06, AX08–AX11, AO01]

AP05. A failed yield is not a successful suspension.

Premises: active coroutine and mismatched C stack position. Source takes the
error branch before successful depth/aux swap; it may remove a queued splice
reference and writes the error result. Therefore the guard retains active
native-call custody until error cleanup really returns; it cannot issue a
suspension receipt or pretend no resources changed. Activation of another
suspended coroutine is a different branch and is not prohibited by this check.
The upstream trace/yield fixture establishes a selected source interaction,
not that a particular trace is permitted to capture C frames. [AD09, AX09,
AX11, AL02]

AP06. Deletion/rewind and zero-depth cleanup do not complete a target.

Premises: suspended live coroutine; delete enters RewindCoroutine and bounded
callback runner. Rewind activates work and retains saved-result restoration;
terminal exit cleans command, environment and line table before compensation;
caller callback then frees coroutine state. Some cleanup or async callouts can
reenter. Until those returns, future effects remain even if command is unlinked,
TOP_CB in one environment is null, flags are clear or depth is zero. A guard
that publishes reuse at any such scalar observation admits a later old effect
into a new epoch. Actual environment/root/native identity is required. [AD10–AD13,
AX08–AX11, AL01, AL02]

AP07. Forced reset needs effect authority independent of cleanup authority.

Premises: a concrete cleanup hook is eventually identified. Storage-release
permission alone does not imply interpreter reentry/reset permission. If the
admitted hook immediately clears U under a saved U=1 trace, old whole-word
restore can revive it; delaying that clear changes the hook-visible history.
If no such hook is admitted, the history remains a counterexample to a proposed
adapter rather than an existing bug. Recursive result cleanup may repeat an
uncleared freeProc; defer or an error union cannot establish one-time ownership
or restore a crossed native stack. [AD04, AD05, AD12, AX05–AX07, AL02]

AP08. Local completion and target reset can be ordered without ancestor wait.

Premises: finite admitted dependency graph, owner-local identities and retained
lifetimes; each callout recorded before entry; terminal/failed/yielded states
distinguished. A child discharges its local obligations and transfers target
custody upward; it never waits on an ancestor blocked on that child's return.
Only the target control owner can settle all producers and publish reuse after
actual trace/native return. This removes that specific wait cycle. It is not
a proof that arbitrary event loops terminate, cancellation always progresses,
raw producers are closed, or the implementation is linearizable. Linearization
requires histories of actual invocation/effect/response, not a reset return code
or suspended callback count. [AD11–AD13, AX08–AX10, AL01, AO01]

AP09. Shared redesign benefit does not prove Zig increment.

Premises: same admitted schema, source semantics, caller set and necessary
supports in both providers. Eliminating old whole-word restores or redundant
audits benefits both implementations only after retirement. Zig-specific net
gain must exceed its residual provider/ABI/upgrade/dual-path cost after all
common work is removed from both sides. No concrete hook or private-caller
retirement here creates such a gain. [AD15, AD16, AV01–AV07]

| Case | Hypothesis / source path | Classification or required rejection | Evidence |
|---|---|---|---|
| AC01 | Private stub is non-null, target depth 0 | Reject automatic public support inference | AX01, AX02 |
| AC02 | Exact public Tcl_InitStubs version accepted | Private layout/effect admission remains unresolved | AX01, AX02 |
| AC03 | Ordinary enter helper after command increment | Identified positive-depth actual caller | AX04 |
| AC04 | Ordinary leave helper on returning command | Preserve leave order/result cleanup; no direct zero entry inferred | AX04, AX05 |
| AC05 | Supply valid private depth-zero trace and bracket prefix | Closed conditional U resurrection body; caller unresolved | AX04, AX05, AX06 |
| AC06 | Coroutine cleanup is at zero | Real phase does not prove a private-helper edge | AX08, AX09, AX10 |
| AC07 | force!=0 with valid target | Private reset body clears at positive depth; producer unresolved | AX06 |
| AC08 | Non-force positive-depth reset returns OK | No clear receipt may be issued merely from OK | AX06 |
| AC09 | TclSetChildCancelFlags forwards force | Parameter propagation is not a force hook producer | AX03, AX06 |
| AC10 | freeProc recursively calls Tcl_ResetResult | Potential repeated cleanup; require ownership/reentry admission | AX07 |
| AC11 | Type freeIntRepProc pointer exists | No permission for arbitrary evaluation/reset inferred | AX07 |
| AC12 | Balanced new root staging at caller d | +1/-1 staging balance, then terminal d-1/+1 | AX04, AX08, AX10 |
| AC13 | Resume suspended offset a at different caller d | Use d+a, not creation depth | AX09, AX11 |
| AC14 | Successful yield | Caller depth restored; coroutine resources still retained | AX09 |
| AC15 | Yield encounters mismatched C stack | ERROR and splice cleanup; no successful depth swap | AX09, AX11 |
| AC16 | Trace callback resumes another suspended coroutine | Do not reject from the active-yield check alone | AX09 |
| AC17 | Older trace h, nested d>=h+1, balanced a>=0 | Conditional floor d-1>=h; no new zero clear | AX04, AX08, AX09, AX10 |
| AC18 | Claim a>=0 for all loaded private callers | Unresolved invariant; signed field supplies no proof | AX08, AX09 |
| AC19 | Suspended coroutine command is deleted | Rewind/activation/callback draining still required | AX08, AX10, AX11 |
| AC20 | One ExecEnv TOP_CB is null at exit | Caller callback/environment obligations remain | AX08, AX10 |
| AC21 | Guard clears target at yield or zero depth | Invalid proposed migration; may enable stale effect | AX05, AX08, AX09, AX10 |
| AC22 | Source force clear deferred until outer guard | Semantic change unless observation equivalence proved | AX06, AX07 |
| AC23 | Child guard waits for ancestor snapshot restore | Reject dependency cycle; return with upward custody | AL01, AL02, AO01 |
| AC24 | Old native trace pointer retained across actual C return | Reject stack lifetime escape; use owned logical record | AE01, AX05, AL02 |
| AC25 | Early execution trace yield fixture | Retained upstream positive control, no cancellation claim or fresh pass | AX11 |
| AC26 | Time/yieldto C-stack-busy fixture | Retained upstream negative control, no fresh pass | AX11 |
