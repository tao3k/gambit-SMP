# Next Evaluation Identity and Cancellation Consumption

The next evaluation is the first eligible actual Tcl evaluation attempt for the requested
interpreter after raw idle cancellation, with internal forwarding counted once.
It can be empty or originate in a naturally occurring event/native callback; it is
not necessarily the host's next user job. Observing cancellation, completing that
attempt and removing persistent runtime state are three different facts. This
refines [mixed-history discharge](tcl-mixed-cancel-design.md), including its earlier
shorthand about the next application evaluation. All new records and operations
below are proposed contracts, not implemented Tcl APIs or native qualification.
See [evidence](tcl-next-evaluation-evidence.md),
[arguments](tcl-next-evaluation-arguments.md) and
[value matrix](tcl-next-evaluation-benefit-matrix.md).

## Define the Identity Before Selecting a Cancellation Check

ND01. TIP 285 says the next script is preemptively canceled when raw cancellation
is accepted with no invocations on the interpreter's stack. It does not name a
host job or exempt naturally occurring callback scripts. A host request that has
merely been queued/reserved is not yet that script. Once the actual next attempt
has entered, a later nonempty attempt cannot replace its identity merely because
it reaches a convenient cancellation poll. Pure async installation and a bare
Canceled check outside script evaluation are not script attempts. [NX01, NX02,
NX04, NX09, NO01]

The reference is a matched raw history with the same natural callers and entry
choices. Adding a script solely to consume cancellation changes that history.
An existing event callback that naturally evaluates Tcl can be the actual next
script; hiding it because it is not a user job also changes the history. This
corrects an overly narrow reading of application evaluation in the prior study.

The Eval manual explicitly calls EvalObjv a single preparsed command rather than
a script. Preserve entryKind=script or prepared-command and declare eligible kinds
in referenceContract before classifying history. The operational entry contract
studied here can include external prepared-command evaluation; literal TIP wording
is not proof of every such choice. Under a stricter script-only contract, a
prepared-command check may mutate raw state without satisfying next-script debt;
that history must refuse the stronger receipt. The EvalObjv positive control below
assumes its entry kind is admitted, not universal specification equivalence.
[NX01, NX03]

ND02. Use source roles to distinguish forwarding, command dispatch and new script
entry. The inspected source does not already pass these identity tokens:

| Source path | Proposed identity role | Evidence boundary |
| --- | --- | --- |
| Tcl_Eval -> Tcl_EvalEx -> TclEvalEx | One evaluation attempt; wrappers forward the same identity | Tcl_Eval also mirrors the string result after inner evaluation returns |
| Tcl_EvalObjEx -> TclEvalObjEx -> TclNREvalObjEx | One attempt across public/internal wrappers | Internal callers of the same helper may instead create child attempts; function name alone does not decide |
| Canonical list -> internal TclNREvalObjv; direct object -> Tcl_EvalEx | Forward the current script attempt through an optimized route | Public or callback-initiated EvalObjv remains a separate semantic attempt |
| TclEvalEx parsing several commands -> internal NRE command dispatch | Command-step identities under the script attempt | Do not consume a new next-evaluation identity per command |
| Substitution, script eval command, native/Scheme callback invoking Tcl again | New child script attempt with explicit parent/cause | Wrappers inside that child still forward; a callback scope without evaluation is not a script |
| Tcl_NREvalObj / Tcl_NREvalObjv | New or forwarded attempt according to its source role, with logical completion attached to NRE work | Returning a scheduling code does not certify completion |
| Coroutine resume/yield/exit | Separate activation identity attached to a continuing logical evaluation | Yield/native return is not necessarily logical completion |

Every admitted call site must declare its role. A generated schema can describe
those roles for C or Zig, but a language import does not discover them. Unreviewed
file/global/variable-eval wrappers, indirect extension calls and coroutine routes
remain outside the closed selected graph. [NX03–NX08, NE01]

ND03. Proposed identity model:

```text
EvaluationIdentity = { providerGeneration, targetGeneration, ownerGeneration,
                       semanticEntryOrdinal }
EvaluationRecord = { EvaluationIdentity, jobBindingOrNone, origin,
                     parentEvaluationOrNone, sourceEntryRole, entryKind,
                     nativeScopes, logicalActivation, phase, completionKind }
NativeScope = { scopeIdentity, evaluationOrNone, parentScope, physicalReturn }
EntryReservation = { hostIntent, admissionEpoch, candidateTarget,
                     notYetAnEvaluationIdentity }
NextEvaluationBinding = { rawIdleCoverage, targetIdentity,
                          firstActualEvaluationIdentity, entryCut,
                          referenceContract, identityComplete }
```

The identity is not a source string, object pointer, numLevels value or OS-thread
counter alone. Repeated use of identical bytes or the same cached Tcl_Obj creates
new semantic attempts; forwarding aliases do not. Ordinals are target-specific,
non-reused and source-issued. Nested attempts record parent/cause rather than
borrowing their parent's name. Completion retains the target generation and source
role; copying an identity record does not grant entry/reset authority. [NX02–NX08,
NE01, NO01]

ND04. In the proposed source integration, raw acceptance and actual semantic entry
are ordered by Tcl's cancelLock C. The entry hook runs inside the selected native
entry before callback-capable preparation, publishes the identity/phase and binds
eligible outstanding raw idle coverage to the first entry. It does no evaluation,
allocation or callback under C. Host admission uses L -> C; generic marks use A;
final commit retains L -> C -> A. Raw CancelEval never acquires L while holding C.
Do not acquire C while holding A or call callbacks while holding these locks.

If raw acceptance wins C while the target is provably idle, the next genuine entry
wins that debt. If entry wins C first, a later raw request belongs to an active or
conservatively ambiguous history rather than being retroactively idle-before-entry.
The before-preparation hook and synchronized active/closing states are new source
requirements, not a claim that current numLevels transitions already provide this
ordering. Uncovered closing windows, NRE suspension or reentry classification set
unknown debt instead of fabricating an active witness. [NX02–NX08, NL01–NL02, NO01]

Raw CancelEval itself converts/decrements an object while holding C. If an
admitted custom object callback could reenter evaluation from there, adding an
entry hook that reacquires C would introduce recursive-lock deadlock. The selected
hierarchy is therefore conditional on a qualified callback domain; otherwise
redesign the ordering mechanism or refuse that profile. Source callback
reachability is not proof that such recursive use is supported, and no global
deadlock-freedom claim is made. [NX02, NX07]

ND05. A reservation does not exclude other natural callers or bind the next identity.
If a natural event script enters first for the target, record that actual winner;
the reserved job is later. If a particular host job must be the next script, its
separate admission contract must lawfully exclude other script callers and prove
that exclusion; raw Tcl cancellation itself provides no job selection capability.
Excluding events or callbacks changes the admitted domain and is not free speedup.

Do not bind a raw idle debt to a script in a different interpreter on the same
owner. CancelEvalProc ignores its callback interpreter argument and installs into
the stored requested target; service while another interpreter runs is installation,
not a target evaluation. Parent-to-child flags are inherited effects with their
own target observations; a child's consumption does not automatically discharge
the parent's requested-target next-script obligation. [NX02, NX09, NE01, NO01]

![Actual entry versus reservation and aliases](tcl-next-entry.svg)
[D2 source](tcl-next-entry.d2).

## Source Paths and the Meaning of Consumption

ND06. Entry identity must be fixed before evaluating success/failure, and it must
survive all routes to actual completion:

| Selected path | Native source behavior | Preserve-source decision |
| --- | --- | --- |
| Empty/comment-only direct TclEvalEx | Command dispatch is conditional on parsed words; no universal entry cancellation service or cleanup reset | Record the empty attempt as first; do not count OK as cancellation consumption or relabel the next nonempty attempt first |
| Non-list, non-direct object route with installed C only | TclInterpReady may return ERROR before bytecode-return callback registration | Attributed ERROR and real return can prove observation; future installers and all residual flags still need closure |
| Same early object route with installed U | Early readiness ERROR precedes registration of that route's return-reset callback | Observation can be valid while U remains; clean reuse must stay blocked |
| Canonical list / ordinary EvalObjv route | NRE return handling may reset before NRCommand services pending async work | Revalidate after full callback/native closure; a later reinstall invalidates earlier neutral state |
| Direct script with substitutions | Child evaluations and reset can occur before outer command dispatch and outer native return | Keep distinct child/command/parent identities and actual control causality |
| Pending token not yet installed at object readiness | Readiness checks installed flags, not every pending async token | Entry alone is not preemption; later polling must be recorded with its actual script-effect frontier |

These are conditional source paths, not proof that every special entry conforms
to the unconditional next-script specification. Literal-source preservation and a
stronger normalized entry-cancellation contract must be reported separately.
[NX02–NX06, NX09]

There are useful conditional positive controls. With an already installed
one-shot raw C, no U, no pending/claimed/re-marked installer and callback-free
qualified preparation, the non-list object route can return the attributed
readiness ERROR with C cleared and no script body admitted. With installed U,
an ordinary public EvalObjv call using normal exception handling and a level-one
entry can take the readiness ERROR through TEOV's natural reset and actual return.
If all later callback/control work is closed and no new marks arrive, those
histories can satisfy consumption and raw neutrality without an added private
reset. They are conditional source-composed classes, not installed/native receipts.
[NX03–NX06]

ND07. An empty attempt is still an identity-bearing script attempt. If the source
returns OK without an attributed cancellation route, the first-entry binding is
complete but its consumption requirement is unsatisfied. Preserve its real code
and pending/installed state in source-preserving operation; refuse clean reuse and
the stronger next-script qualification. Do not secretly run the same bytes via
EvalObjv, compile the empty source or skip it as a non-script to obtain a different
result. Such route changes need a declared semantic transformation. [NX01, NX03,
NX04, NX09]

ND08. An early cancellation ERROR with U left set gives an observation receipt, not
a neutral-state receipt. Repeating the same object evaluation may observe U again;
it must not be renamed as the original first attempt. A private reset after the
call can remove U, but that is an added transition in this selected literal source
history. To admit transparent reuse, require an actual qualified natural reset and
closure, or separately qualify a normalized completion policy. Do not use force=1
or level-zero alone to justify clearing state from active or newer histories.
[NX03, NX05, NX07, NO01]

ND09. A UNWIND-only check with C=1 and U=0 first clears C and then returns OK.
That is a destructive filtered check. Record its exact caller and phase, preserve
its raw behavior, and refuse to mint cancellation observation or consumption from
it. An independent managed ERROR or matching error string later cannot supply the
missing raw cause. If such a check occurs outside the first evaluation and destroys
its only raw one-shot contribution, this history cannot satisfy the stronger
next-script contract without a new semantic repair. Re-arming or replaying is a
behavior change, not passive evidence collection. [NX05, NX10, NO01]

ND10. Nested callback semantics require a causal control path. In Gambit's actual
integration, Tcl calls scheme_call_cmd, which calls the Scheme procedure; the real
callback example invokes Tcl again. The inner evaluation is a child identity; its
raw cancellation ERROR may be handled in Scheme or Tcl, while the outer command
returns OK. A child observation therefore does not automatically preempt its parent.
Gambit's current command bridge normally returns TCL_OK and uses Tcl_SetResult;
result text or outer return alone cannot reconstruct a nested cancellation route.
Native return validity, roots, RC payloads and string release remain Gambit-owned.
[NE01, NX03, NX05–NX07, NL03]

For the first attempt E, a direct attributed cancellation check in E can support
preemption. A child check may support it only if a complete causal route carries
that same cancellation to E's rejected entry/error completion before E's user
command execution is admitted. A swallowed child ERROR does not qualify. A naturally
occurring callback that entered before any E existed is different: it can itself
be the actual first attempt. The identity graph must distinguish these cases.

ND11. Preparation is not automatically callback-free. TclInterpReady resets the
result before checking cancellation. ResetResult can call a custom freeProc,
release an internal representation and update legacy error variables. Those are
source-level callback/effect boundaries, not proof that arbitrary recursive use
from every freeProc is legal. Qualify each allowed callback domain or refuse it;
no claim of a valid native reentry/crash is made from the function-pointer call
alone. Result mirroring after Tcl_EvalEx returns is also inside the outer public
Tcl_Eval lifetime. [NX03, NX04, NX07]

A source-issued entry identity must already exist before such preparation. If a
permitted callback then evaluates Tcl, give it a child identity and record all
returns; it must not steal or erase the outer first-entry binding. Keeping metadata
under a native lock must not turn those existing callback sites into calls made
while holding C/L/A. [ND02–ND05, NX07]

ND12. NRE scheduling and coroutine suspension need additional completion state.
Tcl_NREvalObj and Tcl_NREvalObjv return after staging work; some selection/readiness
can happen inline and execution/cleanup may continue in the caller's NRE chain.
Create/forward the attempt at its semantic entry, carry it on scheduled callbacks,
and complete it at an explicit terminal boundary, not on scheduling TCL_OK.
TclNRRunCallbacks stops at a saved callback root; an empty local run does not prove
all work in the interpreter is complete. [NX03, NX08]

Coroutine yield restores a caller context and returns without necessarily running
NRCoroutineExitCallback, which is associated with return/wind-down rather than yield.
Track a stable logical evaluation plus distinct activation/suspension identities,
callback roots and native scopes. Suspended work that can later mutate raw state,
resume old execution authority or deliver results keeps the frontier open. This
study rejects clean reuse for uncovered NRE/coroutine paths; actual bookkeeping and
suspension-safe custody require redesign rather than a numLevels predicate.
[NX08, NE01, NL03]

## Receipts and Their Composition

ND13. The proposed receipts deliberately certify different predicates:

```text
NextEvaluationIdentityReceipt = {
  providerAndTargetIdentity, ownerIdentity, rawIdleCoverage,
  firstEvaluationIdentity, actualEntryCut, forwardingRoleProof,
  referenceContract, issuer, validityGeneration
}
CancellationObservationReceipt = {
  evaluationIdentity, checkSiteAndPhase, rawInstallCoverage,
  beforeCAndU, filterFlags, returnedERROR, diagnosticAction,
  controlRoute, actualNativeAndLogicalOutcomeCustodian
}
NextEvaluationConsumptionReceipt = {
  identityReceipt, attributedObservationIdentities,
  firstAttemptPreemptionFrontier, actualTargetReturn,
  childAndNREClosure, requiredOutcomeContract,
  unresolvedFirstEntryDebt: empty
}
```

The identity receipt can be valid while consumption fails. Observation can be valid
while U remains. Consumption here means that the required effect on the actual
first attempt occurred and the affected attempt/control work returned; it is not
by itself permission to reuse while persistent raw state remains. For a strict
preemptive-entry contract, a later cancellation after script effects does not
retroactively prove that entry was preempted. A weaker cooperative-interruption
contract must use its own named predicate. [ND01–ND12, NX01, NL01]

ND14. RawHistoryDischargeReceipt additionally requires source-conformant raw-state
neutrality, no pending/claimed/re-marked installer, all old authorities closed and
the same binding/owner/tree/ticket generations. Compose the consumed first-entry
coverage with that discharge receipt, then the remaining managed PendingSettlementReceipt,
then final locked reset/postcondition/publication. Do not make consumption depend
circularly on a later ResetReceipt that itself requires discharge. Earlier wording
that included neutralization inside consumption is separated into these facts;
neither requirement is removed. [ND13, NO01]

Final admission uses L -> C -> A and revalidates each history cut. A raw acceptance
before final commit invalidates old proof; one blocked on C until after fresh
publication is preserved as a new raw request. A later check, reset, callback, tree
change or loss of owner/ticket authority invalidates the relevant provisional
receipt. No receipt claims that authorized new cancellations cannot occur.
[NX02, NX05, NO01, NL01–NL02]

## Preserve, Normalize or Refuse

ND15. The design alternatives have different semantic obligations:

| Concern | Source-preserving evidence path | Potential source modification | Admission boundary |
| --- | --- | --- | --- |
| Identity and aliases | Add passive role/entry/return evidence without changing evaluator actions | Explicit internal invocation context and callback completion token | Required for complete selected-domain proof; actual callback/locking effects still need qualification |
| Empty attempt / pending cancellation at entry | Preserve existing result and state; refuse unsupported consumption | Uniform EntryCancelGate before script preparation/dispatch | Changes polling and possible callback/error timing; new contract, not already equivalent |
| Early ERROR with U residue | Record observation; retain block until qualified natural neutralization | Completion guard covering early, normal, error and nested returns | Must not reset live/new raw state; guarded source change with its own proof |
| Destructive filtered check | Preserve Canceled API and record the failed outcome | New non-destructive peek/check API plus migrated callers | Changes call behavior; legacy public API remains; cannot repair already lost history by relabeling |
| Nested callback attribution | Preserve callback effects and record parent/child/control identities | Context propagation and explicit completion/failure return contract | No suppression of legitimate callbacks merely to simplify proof |
| NRE/coroutine completion | Refuse uncovered scheduling/suspended histories | Logical activation ledger and explicit terminal/grace hooks | Native return alone cannot close suspended work |

A uniform EntryCancelGate cannot simply invoke the target callback ahead of other
handlers and claim original raw semantics. Existing AsyncInvoke has list-priority
and callbacks may alter code or reenter; servicing only cancellation changes that
history, while servicing all handlers adds effects and progress obligations.
Pending payload selection, message/flags replacement and raw idle effects must be
specified for the new gate. Exact signal/mark ordering remains unresolved.
[NX02, NX03–NX10, NO01]

ND16. A proposed completion guard must close every admitted early/normal/NRE/error
path and observe true owner/control completion. It may clear persistent state only
under its separately declared normalized policy and only for the completed causal
coverage. A newer raw acceptance between return and guard, a child still active,
a queued re-mark or suspended activation must block stale clearing. numLevels=0
and an early error code are insufficient. In a raw/managed shared bit, subtracting
one origin is not a valid inverse of the original OR; retain contributor history
and validate the whole allowed state. No existing private reset supplies these
completion or provenance guarantees. [NX02, NX05, NX06, NX08, NO01]

ND17. Required migration order is source roles and actual identity first, then
check/control observations, then NRE/native/child completion, then raw neutrality
and receipt composition. Only after those contracts are independently qualified
can normalized gates/guards be compared with source-preserving refusal. Per-adapter
host-job counters, string matching, reset-on-ERROR and schedule-return-as-completion
can retire only after every actual caller/failure exit migrates. Raw APIs, ordinary
event service, Gambit roots/marker/native return validity and image/payload custody
remain. Failure seals clean admission and keeps original custodians; no dummy eval,
forced reset, timeout or unsafe deletion supplies missing evidence. [NE01, NO01]

ND18. Modern generated C can express the identity/context schema, opaque native
facade and common receipt plan. Optional Zig needs the same Tcl-core integration,
raw behavior and Gambit lifetime support. Potential gains come from qualified reuse
or shared policy owners, while entry/forwarding/check/activation/return evidence
adds work and retained state. No necessary support family is established as
eliminated solely by Zig. Fully general raw/managed equivalence, whole installed
entry closure, callback/FFI/source ABI, normalized gate/guard semantics and progress
remain unresolved. [Matrix](tcl-next-evaluation-benefit-matrix.md),
[operations](tcl-next-evaluation-operations.json), [cases](tcl-next-evaluation-cases.json)
and [trace](tcl-next-evaluation-traceability.json) record those limits.

![Observation, consumption and neutrality](tcl-next-consumption.svg)
[D2 source](tcl-next-consumption.d2).

![Preserve or explicitly normalize](tcl-next-admission.svg)
[D2 source](tcl-next-admission.d2).

## Entry Gate and Completion Guard Follow-up

The [gate/guard contract](tcl-entry-cancel-design.md) refines ND15–ND16 with
explicit ordering/context policies, callout-free core publication, active-aware
readiness and a final C-serialized body decision. Guards register before readiness
and settle only at actual native/logical owner-safe closure. Generation-aware
clearing must cover earlier inline reset writers as well as the final guard;
new raw state is retained on any incomplete cut.
[Arguments](tcl-entry-cancel-arguments.md) and
[matrix](tcl-entry-cancel-benefit-matrix.md) supply conditional controls and costs,
not source/native equivalence for an unimplemented normalized provider.
