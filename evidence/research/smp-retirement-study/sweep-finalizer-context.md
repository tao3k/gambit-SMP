# Sweep callback classes, will timing/resurrection, and checked C entry

2026-10-23 source/design review. The audit recorded qualification 8/12; that is an observed result, not a policy that fixes the count. Statements about no runtime/native/qualifier/recipe edits describe the original author's evidence-only execution scope, not a prohibition on another implementation owner.

Implementation sequences below are conditional design dependencies, not an approved executable work order or permission grant. They must first be resolved against one current, coherent source/generator/header/generated-C/producer identity. Per-file historical line numbers are evidence coordinates, never cross-generation patch offsets. This scope clarification does not alter the original observations, model logs, native receipts or qualification predicate.

See [recursive-ffi-journal.md](recursive-ffi-journal.md) for the corrected status: the cumulative one-winner foreign release patch is recorded as landed, while journals/control-reference lifetime, internal wills, checked bridges and new generated C remain unimplemented proposals in these reports. Plain-release-function observations below describe their saved snapshots and must not be read as instructions to redo the landed claim. The lock is the source authority here; the separate vendor engineering checkout is not required to match it and is not a drift test. Patch/lock agreement is not a configured build or current gsi certificate.

## Independent decision

Do NOT transparently defer every legacy foreign release or invent a second weak
collector. Reuse Gambit's existing will weak-selection/post-GC execution path for
explicitly registered deferred callbacks, and preserve inline sweep only for
callbacks actually proved native/no-GC/nonblocking. Unclassified callbacks are
not made safe by a flag, W_ALL, or the fact that a default C++ destructor generated
them. The release-function contract is at most once per foreign wrapper, not
retry-on-error and not once per raw pointer shared by multiple wrappers.

The saved manual excerpt (gambit.txi:19006–19045) defines C void* -> SCMOBJ error
callbacks, default pointer no-op vs struct/type reclamation, at-most-once release,
GC-triggered release, explicit foreign-release!, foreign-released? and address0
after release. It does not establish that arbitrary C callbacks are GC-safe or
reentrant. Source bound in the JSON: mem/setup from4b8ae711; c_intf from9a03;
_kernel source/generated C and OS IO frombad1e9aa. These observations and the
manual excerpt do not certify a coherent native producer.

## Actual GC and will chain

`garbage_collect_mark_weak_phase` (mem.c:8249ff) runs after strong-root scanning,
sets traverse_weak_refs, calls `process_wills`, drains mark closure, and moves
continuations. `determine_will_executability` (:6304) decides from an unmarked
weak testator before the will code retains that testator. `process_wills` (:6339)
marks executable will/testator roots and moves them to the executable list.
`garbage_collect_cleanup_phase` (:8288ff) then processes weak hash tables and
calls `free_unmarked_still_objs` (:4770). Only after GC does the Scheme path
`##handle-gc-interrupt!` -> `##gc-finalize!` -> `##will-execute!` run actions.

Thus an internal will registered BEFORE the wrapper becomes unreachable can
keep its eligible testator intact through sweep and provide an existing mapped
post-GC landing. Adding a strong global job->wrapper edge before the weak test
would defeat this mechanism: the wrapper never becomes eligible. Do not enqueue
raw SCMOBJ pointers at the late sweep cleanup and hope to mark them after closure.

The proposed internal will action closes over only a stable operation token,
not its testator. It receives testator as the existing action argument. Native
callback descriptors must not hide untraced Scheme references. Any typed payload
root that can strongly point back to the wrapper must be part of the explicit
reachability contract; do not promise collection of arbitrary strong cycles.

## Callback classification at creation, not by guessing during sweep

| Class | Actual/proposed binding | Allowed GC/context behavior | Failure disposition |
|---|---|---|---|
| already released / no callback | release state and fn/ptr consumed | no second call; wrapper conversion remains refused/address0 | no automatic restoration |
| INLINE_NATIVE | audited descriptor attached through ___POINTER_to_SCMOBJ / nonnull conversion and actual callback registration | bounded, no Scheme entry/allocation/GC, no arbitrary unwind; valid owning native context | error has an explicit resource owner; never infer retry or free from code alone |
| DEFERRED_NATIVE_WAIT | canonical device cleanup is a candidate, not automatically bounded | internal will/owned post-GC job; actual native progress with inherited deadline and owner affinity, no callback during sweep | known BUSY retains job; hard/uncertain close retains owner or terminal policy; never replay ambiguous close |
| DEFERRED_MAPPED | explicit typed factory/registration requiring a legal Scheme landing | existing will action + mapped preparation frame; nested GC/requests and supported exceptions/continuations under parent capability | completed invocation/error/escape consumed once; unresolved roots/debt retained |
| UNCLASSIFIED | custom release or default C++ destructor without transitive proof | reject registration before native ownership transfers, or refuse preparation with already rooted debt | no silent classification as native-safe; an unsupported legacy callback discovered inside GC without a pre-established safe root/context is a declared fail-stop boundary, not an opportunity to allocate or enter Scheme |

`___POINTER_to_SCMOBJ` (c_intf.c:5157ff) currently allocates the foreign object,
stores tags/release_fn/native pointer, then exposes it. Proposed checked factories
must establish descriptor, operation id, per-wrapper claim and (for deferred
classes) internal will/root registration before exposure. If will/descriptor
allocation fails, preserve GC-updated inputs, keep native ownership with the
caller and publish no partially registered wrapper. Do not call an unregistered
user callback to clean up that failed registration.

Pointer aliases are not wrapper identity: two wrappers may intentionally each
decrement a shared native reference. Do not globally deduplicate by ptr. Bind the
one-shot claim to full VM/instance plus wrapper operation generation and retain
callback-module/descriptor lifetime through the final invocation. Address reuse
or native module unload must not turn an old callback into a new registration.

## At-most-once claim shared by all entry points

`___release_foreign` (:1683) uses ordinary fn/ptr reads and clears before invoking.
`##foreign-release!` disables interrupts locally; this is not a cross-processor
mutex. Absent an independently proved single-mutator contract, this source does
not establish concurrent same-wrapper explicit release / will / cleanup safety.
This is a source-level conditional race concern, not a captured native crash.

Grok must add one per-wrapper release operation state shared by explicit release,
will action, device preparation and terminal cleanup:

LIVE -> CLAIMED(op, owner, invocation_nonce) -> RETURNED / RETAINED_UNKNOWN.

The winner takes a stable fn/ptr snapshot, disarms public conversion fields and
publishes the consumed state before callback invocation. Losers never invoke.
The claim uses the established native descriptor lifetime/full K, acquire/release
publication and bounded checked synchronization; a reused raw pointer is not an
identity. Resolve what concurrent foreign-address/conversion observes: before
claim it may obtain only a separately borrowed live handle; after claim it sees
released/refusal. A Boolean released flag alone does not protect a native pointer
already handed to another FFI operation. Such pointer users need a loan through
last native use, with closing preventing new loans and draining existing ones.
That additional loan protocol remains mandatory C work, not proved by the model. An unmanaged integer from foreign-address or a pointer retained by arbitrary host C cannot be automatically enumerated: either scope it with a checked borrow/native reference contract, or explicitly exclude use after release. No claim is made that this protocol can recover arbitrary dangling pointers outside the supported ABI.

If explicit foreign-release! wins while the internal will is already executable,
the later will clears its own action/testator and consumes the completed release
record without invoking again. The callback may free something and then return
an error: preserve error/resource disposition but never restore fn/ptr and never
repeat it. Unknown outcomes require the prior preparation ledger's containment.

## Timing and resurrection contract

1. Ordinary Scheme wills retain their existing weak-test semantics. Do not alter
   determine_will_executability/mark closure ordering to implement this change.
2. An opted-in deferred foreign wrapper can remain not-yet-released between GC
   selection and its post-GC action. Native resource reclamation is later than
   legacy inline sweep; prompt clients can still use explicit release. This is
   an explicit timing/API compatibility change, not a free optimization.
3. `##will-execute!` copies testator/action, clears both will fields, then calls
   action with interrupts enabled. A user action can put the testator in a strong
   global root. Marked testator survives the current GC, and the new strong root
   keeps it alive at the next GC. This does not re-arm the already consumed will.
4. If the release action has already run, resurrecting the wrapper does not
   resurrect the native resource: released state stays true, address stays0,
   conversion is refused, and release is not invoked a second time. Do not use
   the wrapper's survival as authority to restore the old pointer.
5. Separate user wills and the internal deferred will have no new global FIFO
   order guarantee here. A user action that needs the still-live resource needs
   an explicit dependency/loan contract. Unordered wills cannot be made safe by
   assuming one action runs before another. The model's one internal will does
   not prove interactions among arbitrarily many user wills.
6. If a pending action fails or escapes through the supported landing, its
   invocation is consumed and retained/error data stays rooted. Independent
   never-called suffix jobs may proceed only under declared dependencies.
   Nonreturning callbacks provide safety by retaining ownership, not liveness.

## No-Scheme-context C entry: refuse or opt into a checked bridge

| C entry situation | Required behavior before VM/object dereference/destructive mutation |
|---|---|
| no valid VM token, wrong OS owner, unregistered thread, stale generation | return checked INVALID_OP/NEEDS_CONTEXT and keep caller ownership; never infer a borrow from a raw TLS/pstate/SCMOBJ address |
| valid VM borrow but bootstrap/helper/module registration incomplete | retain/refuse; setup_state or marker0 alone is not a complete Scheme context |
| valid mapped Scheme caller | dispatch preparation at its unlocked safepoint under existing parent; recursive cleanup records intent, not a second teardown |
| valid registered P0 native owner after original ___run returned | only an explicit checked preparation API may create a fresh ___run of a startup-registered rooted thunk; validate VM phase, P0/OS affinity, live parent, helper identity, FFI/marker facilities, no GC/collective/shared locks and real deadline BEFORE entry |
| valid wrong-owner worker/native producer | checked delegation to the legal owner via a capability-owned request if that contract is implemented; otherwise refuse. No implicit thread attachment or TLS replacement |
| terminal unknown shared synchronization or unsupported native unwind | independent fail-stop; not a Scheme callback, host error callback or successful recovery |

Proposed `___cleanup_prepare_checked(vm_token, request)` returns PREPARED,
RETAINED/NEEDS_CONTEXT or terminal failure. `___cleanup_checked` may finish only
with the corresponding preparation/destructor authority. Legacy void cleanup
must preserve an explicit fail-closed embedding policy; it cannot return as if
resources were freed after a refusal. The existing `___run` (:4814) demonstrates
marker creation, ___call, END_TRY and final marker kill; it does not prove the
new private bridge's validation or make an invalid host context valid.

In particular, do not silently add arbitrary Scheme re-entry to a formerly
native-only host cleanup. The host must opt into the checked bridge or supply
already-prepared authority. The actual main/client/pthread entry sites from the
previous tree audit need this policy and regression coverage.

## Generated C correspondence

| Saved bytes | Existing guarantee | New obligation |
|---|---|---|
| _kernel.c:17177–17228, ##gc-finalize! | removes an executable will and hands it to compiled ##will-execute!, with stack/return continuation | queued/root ownership before removal and through new driver handoff; no late raw pointer capture |
| _kernel.c:17230–17290 | testator/action fetched, fields cleared, testator in R1 and action in R3; ___POLL then generated generic call | internal action consumes shared per-wrapper claim; roots survive the actual poll/return frame, not just Scheme local names |
| _kernel.c:30407–30412 | gc-finalize RETN(1,0,0x1), will-execute RETI(4,0,0x3f1) and RETN(1,0,0x1) | regenerate changed helpers and inspect actual maps/configuration; do not copy these maps to a new frame |
| _kernel.c:22108 raw ___release_foreign call | scalar status branch; no executed W_ALL/R_ALL at this saved site | native-only context proof or regenerated proper mapped/context veneer before allowing reentrant callbacks; W_ALL alone is not a new GC frame |
| _thread.c:21039ff/31037ff and callback-preparation report | existing mapped escape/recovery closures and actual root descriptors | new nested cleanup record/driver and owner-preserving bridge remain to generate |
| setup.c:___run -> marker -> ___call -> END_TRY -> kill | supported owner marker cleanup after normal/throw return | retain outer VM/setup parent through final C tail and return; stale/bad C contexts refuse before this chain |

These files are immutable observations across different saved source generations;
there is no linked-producer admission. The new bridge/registration functions and
maps are proposed, not already generated or executed.

## Impact on the eight cumulatively closed categories

The eight categories are named by the existing twelve-gate inventory; their
historical evidence is not erased. A changed producer still needs source-bound
revalidation. No claim below grants a current-source pass.

| Cumulative category | Possible regression from this proposal | Required focused checks before broader same-producer acceptance |
|---|---|---|
| bootstrap | callback descriptor/factory setup before P0/helper ready | p1/p11 normal/error startup, partial setup allocation failures, no will allocation in invalid context |
| complete GSI inventory | foreign-released?/address/conversion and will timing | explicit release success/error/no-op, will eligibility, kept-alive target, resurrected released wrapper, inherited original inventory/limits |
| PR regressions GSI | interrupt/exception/return semantics | exact existing PR fixtures, no swallowed status or changed return value, nested callback/exit behavior |
| complete GSC inventory | regenerated primitive ABI, register roots and frame maps | exact candidate GSC-generated paths, valid moving GC before/after driver, no edited maps or changed compile cap |
| PR regressions GSC | compiled FFI and continuation edges | original declared compiled regressions plus shared explicit/will claim race on same artifact |
| stress GSI | finalizer backlog, reply ownership, hidden blocking | existing narrow interrupt/GC controls first; bounded queue and unchanged deadlines; backlog retention not miscounted as completion |
| stress GSC | codegen-dependent release/callback races | repeated focused compiled stress with actual processor population and same binary/source identity |
| registry lifetime | rooted pending wills/loans pin a VM through close/reuse | two VMs/two epochs, callback module/descriptor lifetime, no generation reuse while pending; checked embedding refusal/bridge and drain |

The remaining GC/FFI, lifecycle, Gerbil correctness and release performance gates
stay separate/open. This turn does not execute any inventory or reclassify history.
Deferred callbacks can increase object/native-resource residency, add will/action
allocation and shift tail latency. A backlog bound/capacity failure policy is
required; do not promise performance based on finite model state counts.

## Grok implementation order and real native control sequence

1. Audit every actual release-function registration, including default generated
   C++ destructors and canonical device callbacks; bind code/module lifetime and
   callback class. Define explicit unsupported-ABI behavior before enabling it.
2. Add one-shot per-wrapper operation state + outstanding native-pointer loans;
   route ___release_foreign, explicit release, device preparation, will and empty
   cleanup through the same claim. Record actual outcomes, never auto-retry error.
3. Add checked typed deferred factory using existing will registration before
   wrapper exposure. Internal action captures only the stable operation token;
   maintain weak eligibility and root-after-selection through existing wills.
   Failure before acceptance leaves native ownership with creator.
4. Keep mem.c weak/sweep phase separation: only audited inline callbacks there;
   validate that deferred wrappers have an existing registered will and marked
   testator. Missing descriptor/registration is not recoverable by allocating in
   sweep. Do not change general user-will ordering to hide missing ownership.
5. Implement checked C preparation/refusal/opt-in bridge; register thunk at setup,
   preserve original owner/marker contract, no callbacks under GC/collective/T/P
   locks. Update main/client/pthread adapters explicitly, not silently via TLS.
6. Generate _kernel/_thread C and actual descriptors, compile/link ONE coherent
   producer, bind source/config/objects/archive/gsi. Never use the previous smoke
   binary or only mem.o/setup.o as evidence of these changes.
7. Focused native order: (a) factory/context refusal before mutation; (b) native
   inline classification and sweep no-Scheme-entry; (c) opt-in will selection,
   root survival through two GCs and post-GC action; (d) queued will vs explicit
   release on separate processors, exactly one callback; (e) resurrected wrapper
   remains released/address0; (f) multiple user wills with explicit dependency
   policy; (g) callback error after side effect, nested GC/escape and unknown
   containment; (h) C host after original run, bad owner and partial startup;
   (i) pending callback/loan vs VM close/reuse and partial cleanup. Use existing
   caps and real absolute deadline, then relevant front-eight source-bound gates.

New native hooks are implementation work; no invented harness command is claimed
available. Model commands: verify-sweep-finalizer.py and
verify-sweep-finalizer-reachability.py under the registered audit role.

## Model and independent closure judgment

`sweep_finalizer_context.qnt` combines factory class/context admission, weak
selection, marked pending wrapper, inline-vs-deferred sweep, post-GC action,
second GC, resurrection, checked fresh bridge/refusal and explicit-release/will
competition. Eight positive scenarios include pre-mutation refusals and terminal
unknown-in-GC containment; these are different outcomes, not eight cleanups.
Twelve negatives cover early strong capture, Scheme-capable call in sweep,
free/drop pending root, invalid C call, replay after resurrection, native pointer
restoration, refusal after access, accepting unknown, late will consumption and
double invocation in the explicit/will race, and erasure of the independent strong root regained before the race. The earlier seventeen-control graph
without that race is retained as a narrower predecessor, not reused for this one.

This finite abstraction assumes classification proof, a valid checked bridge,
will/testator trace correctness and one atomic release claim. It does not prove
actual C memory order, pointer-loan correctness, arbitrary user-will ordering,
callback progress, generated frames, module unload or native performance. The
companion reachability checks add pure observations only; existence of a path
is not fairness or liveness.

My judgment: explicit classes plus existing wills and one-shot shared ownership
is a viable direction; blanket transparent deferral is not justified. Safe
forward recovery exists for never-invoked work, valid bridge refusal/re-entry,
and known unfinished native BUSY units. Consumed/unknown callbacks and failed
roots remain owned/quarantined; unsupported unwind, unsafe GC context without
pre-established retention, or unknown shared-lock state requires the explicit
terminal boundary. Native success remains unproved; formal count stays8/12.


### Model revisions and outcome witnesses

The initial17-control graph is retained. Adding queued-will/explicit-release competition exposed a model error: foreign release consumption was incorrectly coupled to clearing will fields. The actual decoded counterexample has explicitReleased=true, calls=1 and actionCleared=false: that is a legal explicit winner, not a runtime defect. The corrected contract separates the two claims while keeping calls<=1 and rejecting a will that invokes without consuming its action. A later strengthening admits both winner orders, preserves the program's independent strong reference regained from will-testator, and adds a negative that erases that root. Older safety clauses did not prove that root; their receipts are not substituted for the final graph.

The companion pure-observer checks seek seven distinct existential outcomes: deferred completion, released-wrapper resurrection after a second GC, explicit winner with will no-op, will winner with explicit no-op, checked fresh C bridge, no-context refusal before VM access, and unknown-in-GC fail-stop without invoking/freeing. Clean completion, refusal and termination are different result classes; existence of these paths is not a fairness or native execution proof.
