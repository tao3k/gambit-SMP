Current correction/followup: generated-root-handoff.md/json supplies actual generated root maps and native-tail/publication obligations,83 controls, and supersedes the nested guard->slot/one-slot-cost suggestion below. This historical69-case narrative retains its measured receipt, but its failure-return record-retention claim is superseded: old bootReturn reset the context record.

# Setup ticket, persistent prepare guard, and independent P0 READY

This is an implementation handoff, not an applied runtime patch. It extends the
same `models/gambit/integrated_growth.qnt`. Runtime admission remains false.
The prior 53-case bootstrap result remains immutable; the new result must bind
the expanded model's bytes. No observer, recipe, milestone or native count is
changed. This protocol repairs bootstrap authority/initialization; it does not
by itself close interrupt delivery, retirement, GC/FFI or formal 9/12.

## Source basis and concrete defects

Line numbers below refer exclusively to the saved per-file observation under
`.cache/tasks/repair-9-12/processes/audit/runs/bad1e9aa8d7d47e2a1304a6225f6f2ae/outputs/integrated-growth-source-observation/observed/`.
It is forensic source evidence, not a certified coherent build generation or a
source-to-GSI binding. The mutable c86dff86 producer directory is a location
hint. The historical 7263fe03 GSI is not available as the current executable.

| Observed operation | Actual guarantee / defect | Required implementation |
|---|---|---|
| `setup.c:7204` `___setup` knows `&GSTATE->vmstate0` and its P0; `7220` reads `cleanup_admission_error`; `7229` resets cleanup phase | Explicit VM identity is available. Unsynchronized cleanup phase does not serialize setup, recursive setup or initialization. | Reserve an invocation ticket before any shared writes or early interrupt prepare. Concurrent and recursive fresh entries refuse without mutation. |
| `setup.c:7251` initializes `vm_list_mut` inside setup | This mutex cannot protect the earlier first invocation. | Process-lifetime statically initialized POSIX entry guard; never reinitialize or destroy it during VM cleanup. |
| `gambit.h.in:10924` defines POSIX mutex and `10926` `PTHREAD_MUTEX_INITIALIZER` | Concrete Darwin/POSIX initialization mechanism exists. The Win32 NULL macro is not an initialized critical section. | Use the POSIX static initializer here; provide an actual platform once/entry implementation before claiming Windows support. |
| `setup.c:7291` early `setup_interrupts_pstate`; `383` derives VM/slot through pstate; `395` opens slot | Null `ps->vmstate` lookup caused the supplied exit71 trace; native initialization also opens too early. | Validate explicit known VM/P0 capability, bind identity, prepare CLOSED, then initialize exact native prefix. No pointer subtraction on an unbound/untrusted pstate. |
| `setup.c:5568` `___setup_vmstate` clears all marker lists/counts before `5648` calls public `___setup_pstate`; `5380` binds pstate VM | An already-live instance cannot safely enter this reset path. Internal continuation and fresh public entry are currently indistinguishable. | Separate private prepared helpers from public admission wrappers. Only the ticket holder invokes the reset path, once, after old consumer grace. |
| `setup.c:7407` enters `___run`, which spans execution until program return; `4019` creates/calls/finalizes a marker | Outer setup is not a short function that ends at READY. A stack setup context is invalid after retained-failure return. | Persistent registry record plus native context borrow attached to the original C/Scheme marker scope, retained through the entire run and its finalizer. |
| `c_intf.c:6515` marker owner entry, `6520` retirement, `6547` marker creation, `6604` kill | Still marker has an external reference; native list contains no movable heap pointer. Only its OS owner mutates it. Generic SFUN entry also creates a marker. | Add optional native setup-record reference/scope kind/nonce to entries; ordinary markers receive no setup authority. Release the borrow in common retirement, including nonreturning worker exit. |
| `_thread.scm:3401` startup unlocks VM and P, installs primordial roots and handlers, then calls `##fault-control-make!` | A concrete no-T/P-lock P0 tail exists after the coordinator is rooted. Current tail merely returns void. | A checked, nonallocating P0 readiness helper at this exact tail, with initialized root obligations and exact original setup scope. |
| `setup.c:1540` worker READY dispatch requires target>0; `_thread.scm:3318` worker unlocks P before startup-complete | Worker collective READY does not certify P0. | Keep worker cohort certificate; P0 has its own scalar CLOSED→READY transition. OPEN is a separate checked publication. |
| `request_open_slot` initializes incarnation=1; cleanup only sets CLOSED | Neither a fresh generation nor safe counter reuse follows from CLOSED or producers=0. | Persist nonwrapping generation high-water outside VM reset; renew only after complete cleanup and all queue/wake/handler/marker/VM readers leave. |

## Concrete records and lock protocol

Proposed private names are new symbols, not claims that these helpers exist.
Preserve public ABI signatures; route their internals through checked wrappers.

The process-lifetime `setup_entry_guard` protects a persistent registry and its
monotonic high-water counters. For POSIX use a static `___MUTEX` initialized with
`___MUTEX_INIT_STATIC`. Do not initialize it using a slot, VM allocator or Scheme
object; do not zero it with `GSTATE`, VM or pstate memory. The registry entry
exists before the first bind. A reusable fixed VM0 record can avoid bootstrap
allocation; additional VM records require validated registration and lifetime
pins, not indexing arbitrary host pointers. Reject unsupported foreign VM
identity before touching it. Reject exhaustion before publishing a new ticket.

A record needs `instance_id`, `vm`, `ps`, `slot`, `incarnation`,
`invocation_nonce`, `entry_kind`, `prepare_phase`, `native_init_mask`,
`first_error`, `cleanup_error`, `context_readers`, `vm_pin`,
`original_scope_id`, `ready_consumed`, an outer setup-owner reference, and last-consumer state. Keep raw movable
Scheme values out of it. A stack ticket holds a reference/key/nonce and the
permitted next private stage, never the lifetime of the record itself. Persist
high-water values even when the record becomes CLEAN. Address equality or
`pthread_self()` equality is not instance or invocation identity.

The guard is held only to validate/reserve or publish record transitions. It is
released before native initialization, allocation, callbacks, `___run`, joins,
Scheme execution, and fallible cleanup. Logical PREPARING ownership stays in
the record while the mutex is released. A reentrant or concurrent fresh entry
sees PREPARING/RUNNING/DRAINING/RETAINED and returns a real refusal status before
writing globals, zeroing markers or calling INIT. It does not wait for the
outer Scheme call to return. RUNNING also rejects a second global `___setup`.

Lock order: no T/P/allocator lock on public setup or P0 READY entry; entry guard
before an initialized slot mutex when a transition requires both. Release both
before fallible work. Request acquire/release uses only the slot mutex; it never
acquires the entry guard while holding that mutex. Cleanup takes an ownership
snapshot under guard, releases it, performs work, then revalidates the exact
nonce before publishing its result. A rejected or stale caller cannot clean up
the owner's resources. Never call Scheme or foreign callbacks under either
native lock. This is a proposed order; the present source does not establish it.
A growth call currently inside the resize collective cannot be converted into
a fresh public setup call with this order: staged shell preparation needs its
own explicit growth transaction ticket established outside that collective.

Successful mutex unlock/lock supplies release/acquire for registry state and
for the slot key+phase+pin tuple. If a lock-free observer needs a readiness hint,
release-publish the hint after the protected tuple; an acquire hint remains
advisory and never replaces locked key validation/pinning. No plain read of
`cleanup_phase`, init bits or OPEN outside their owning synchronization may
become admission authority. Native atomics and mutex implementation remain
separate obligations from QNT's atomic transitions. Guard lock failure gives no
permission to initialize or tear down anything. A broken unlock/guard cannot
be made safe by resetting the mutex; retain the fault and reject reuse.

## Actual-to-proposed call order

The normal saved bootstrap route is concrete:
`___setup:7407 -> ___run:4019 -> ___call:3901 -> kernel module thunk ->
##load-vm:5347 -> ##load-modules:5336 -> ##init-modules:5306 ->
(macro-module-descr-thunk module-descr) -> _thread module top-level:5576 ->
##startup-threading!:3401 -> ##fault-control-make! -> proposed P0 helper`.
`##init-modules` calls the Scheme module thunk directly; this path does not
require borrowing a nested ordinary C-run's authority. Any loader extension
that actually adds a nested C/Scheme entry must receive its own explicit private
startup delegation or be refused, never silently inherit the ambient ticket.
`___call` builds the existing return-to-C frame containing `stack_marker` at
saved `setup.c:3962` and catches/rethrows errors to its outer caller. Keep that
frame convention and the outer run finalizer; do not substitute a raw native
pointer for its Scheme marker.

1. `___setup(params)` validates immutable arguments, then
   `setup_entry_acquire(GLOBAL_VM0, known_vm, known_p0, &ticket)` reserves a
   persistent PREPARING record under the already initialized entry guard.
   Only that owner copies global setup parameters or changes setup/cleanup
   state. Validate exact registered VM/P0 before binding `ps->vmstate`; derive
   no slot from an unbound pointer. Early interrupt preparation records each
   successfully initialized native resource but leaves admission CLOSED.
2. Replace the internal `___setup -> ___setup_vmstate` call with
   `setup_vmstate_prepared(vms, &ticket)`. Validate instance/incarnation/nonce,
   expected private stage and VM0/P0 key before the existing reset loop.
   Replace its internal public P0 call with
   `setup_pstate_prepared(ps, vms, &ticket)`. Reuse the exact early CLOSED native
   prefix; do not initialize its mutexes again. Each continuation advances a
   one-shot stage. Public `___setup_vmstate` / `___setup_pstate` wrappers reserve
   their own permitted entry kind and refuse an occupied record. They cannot
   fetch a foreign ticket from TLS, a shared VM field or OS thread identity.
   Registration of another valid VM needs its own record and global-state
   synchronization; this finite model deliberately rejects its second VM.
3. After TLS/self-thread initialization and kernel resolution, call a private
   `run_setup_entry(ps, thunk, &ticket)`. Keep ordinary `___run(ps, thunk)` as a
   no-setup-authority entry. Share its TRY/call/finalizer implementation rather
   than fork an unmaintained second unwind routine. Validate/bind the native
   context before entering Scheme. If marker allocation fails, no reader was
   installed; retain the owner's record, return the exact error and clean only
   the successful resource prefix. If attaching the record after successful
   marker allocation fails, retire that marker and unwind the acquired borrow
   exactly once before returning. No registry pointer may point to a stack
   ticket, native automatic variable, or movable Scheme object.
4. Extend `sfun_marker_owner_entry` with optional persistent record reference,
   invocation nonce, entry kind and scope ID. The original setup entry owns one
   context reader. Ordinary `___make_sfun_stack_marker`, including generated
   SFUN callbacks, creates a NULL-authority entry. Any temporary association
   must be removed on failure before `___call`. At the P0 helper, require the
   current OS owner/TLS P0 and the exact current native marker entry to be the
   original setup scope. A nested `___run` or SFUN scope shadows that authority,
   and exiting it restores the parent scope; it does not copy the ticket.
   Direct public recursive setup receives refusal even on the same OS thread.
   Private C helpers are an internal call-discipline boundary, not a defense
   against arbitrary native memory corruption or forged internal calls.
5. At the SMP tail of `##startup-threading!`, after
   `##fault-control-make!`, call a checked private `setup_p0_ready_current`.
   Validate exact owner/key/scope, initialized native mask and actual current
   primordial/run-queue/interrupt-vector/coordinator root obligations. Consume
   the one-shot READY right, set READY under synchronization, then invoke a
   separate checked OPEN publication. Worker target>0 dispatch is not called
   as a substitute. Marking P0 READY must not reset `startup_epoch`, scheduler
   state, marker lists or coordinator roots. OPEN publishes the same current
   incarnation, never increments it. Do not hold T/P or guard across Scheme.
   Preserve SMP/non-SMP conditional definitions and generated ABI conventions.
   In the saved source, `##fault-control-make!` creates/pins/roots a control
   thread and installs hooks; it does not call `thread-start!` or publish a
   high-level request. `##make-root-thread` ends in `macro-make-thread` at1150.
   Thus this observed READY prerequisite is creation/root establishment, not a
   requirement that a CLOSED public request queue execute the coordinator.
   Any added startup work that does require public admission needs an explicit
   private startup capability or a later scheduling point, never early OPEN.
6. On a checked READY/OPEN error, do not return void or continue into user code.
   There is a concrete existing error bridge: `_kernel.scm:4718`
   `##exit-with-err-code-no-cleanup` calls `___propagate_error`; saved
   `setup.c:1318` forwards a non-NO_ERR value to `___throw_error:1304` and
   `___THROW`. The original `___run` TRY catches it and executes its marker
   finalizer after END_TRY. Return the helper's exact negative native fixnum to
   Scheme, then use that no-cleanup bridge on failure. Do not encode it as a
   positive program exit status, run exit jobs/coordinator routing during
   partially completed startup, or allocate an exception merely to return a
   native initialization status. The setup owner performs checked cleanup after
   the original run returns; `setup.c:7419` is the existing outer cleanup site.
   This bridge still needs regenerated root/register validation at the new call.
   It does not authorize a foreign longjmp bypassing the supported catcher. Keep Scheme carriers,
   marker and VM pin live until that original return reaches marker finalization.
   GC may happen between result production and finalization. The helper's
   completion does not release the context reader: successful setup's `___run`
   may remain active for the whole program. No exception/callback may trigger
   reset merely because OPEN did not happen.
7. The outer setup-owner reference and the marker reader are different
   consumers. Marker-reader zero does not authorize a foreign cleanup call to
   steal the still-running outer setup epilogue. Only its matching ticket may
   advance RETURNING→CLEAN/RETAINED. Publish that final disposition after its
   last VM access; any final return after dropping ownership uses local scalar
   status only. QNT `recordLive` persists through this owner cleanup even after
   `contextReader` becomes false.

   In `retire_marker_entry`, release any setup-context borrow exactly once,
   then publish final-reader completion with release semantics; the cleanup
   owner observes it with acquire before destroying context/VM storage. The
   native record pins the VM, not vice versa through destructible storage.
   Apply the same release to `___kill_sfun_stack_marker` and the existing
   `___retire_sfun_stack_markers` nonreturning owner path. Unmatched foreign kill
   remains nonmutating. Registry owns the record after `___setup` returns if
   cleanup fails; do not replace it with a dangling address on the original stack.
8. After supported original return and real last consumers, reverse only the
   recorded successful resource prefix. Add a private
   `setup_unwind_prepared(record, &ticket)` for partial bootstrap: saved
   `___cleanup_checked:5686` returns NO_ERR when `setup_state != 1`, so merely
   calling the current global cleanup cannot prove an early initialized prefix
   was actually released. This private unwind is authorized by the matching
   owner and successful-prefix mask, not the global fully-started bit. Preserve
   the existing cleanup refusal when fault preparation still owns rooted work;
   marker-reader zero must not bypass coordinator/device or wake obligations. Preserve the exact first setup status
   separately from cleanup failure. Failed destruction remains RETAINED with
   key, resource bits, native record and necessary roots/pins. A legitimate
   authorized cleanup continuation can retry; a fresh setup cannot take it over.
   Once resources, original scope, external borrowers, queue/handler/wake and
   VM readers are all gone, publish CLEAN under guard. Only then reserve a fresh
   checked nonwrapping incarnation/nonce for a new setup. Publish its identity
   CLOSED first; fresh READY/OPEN follows its own initialization. Old generation
   checks refuse even if the same VM/pstate addresses are reused.

The existing marker's stability is supported by actual allocation, not only its
owner-list comment: saved `mem.c:1941` `___make_vector` calls
`___alloc_scmobj:1864`; a non-NULL pstate selects `alloc_scmobj_still`, with
initial external refcount1 (documented at1639 and1930). The marker is therefore
a stable still object, while movable values in its Scheme fields still depend
on normal GC scanning/writeback. `___make_sfun_stack_marker` saves/restores its
procedure across allocation before putting it in the marker. Reuse that rooted
route; never copy the procedure into the native setup record. The SFUN macros
at `gambit.h.in:10057` create/kill their own markers around TRY and propagate the
error afterward, which supplies the concrete nested-scope shadowing boundary.

The P0 helper is nonallocating and must use the existing generated register/root
save conventions. Adding its C call requires regeneration and inspection of
`_thread.c`, `___W_ALL`/`___R_ALL`, temporary live values, TRY unwind and marker
retirement. Those generated bytes do not exist for this proposal yet. The model
checks ownership while abstract GC interleaves, not a C frame map. An arbitrary
host longjmp, asynchronous cancellation, unsafe library unload or callback that
never returns has no automatic recovery proof: preserve the record/resources
and refuse reuse rather than invent a completed finalizer.

## Unified QNT correspondence and discrimination

All previous scenarios now pass through the ticket prefix. Existing resource,
queue/wake lease, staged-worker and service-debt scenarios remain in the same
transition graph. Ticket stage0→1 reserves a persistent record; stages2/3 are
explicit VM/P0 delegation; stage4 is the original mapped C/Scheme scope;
stage5 consumes READY; stage6 is original return; stage7 retires the record.
`ticketEpoch` and `ticketNonce` are separately checked. Two modeled epochs use
small nonce values; native generation wrap/exhaustion is not inferred from that.

| QNT fields/actions | C implementation obligation |
|---|---|
| `guardReady`, `ticketReserve`, `recordLive` | Static guard exists before first setup; atomic owner reservation; no registry pointer to an automatic context. |
| `ticketContender`, `ticketRecursive`, `entryDenied`, `recursiveDenied` | Fresh concurrent/same-thread recursive setup cannot reuse the private continuation. Refusals do not mutate the current owner. |
| `ticketVm`, `ticketP0`, `ticketEpoch`, `ticketNonce` | Exact invocation and stage passed explicitly across early-prefix reuse, VM reset and pstate setup. |
| `ticketEnter`, `scopeId`, `ticketNested*`, `contextReader` | Original run owns a persistent-record borrow; nested SFUN/run has no READY right; returning nested scope restores only the parent authority. |
| `bootScheme`, `bootProbeReady`, `bootOpenReady` | Roots precede P0 READY; acquisitions still refuse before OPEN; READY and OPEN are separate, checked, one-shot transitions. |
| `bootGc`, `bootReturn`, `ticketScopeReturn` | GC/checked OPEN failure retains roots and context until supported original return; ordinary teardown waits for original scope exit. |
| `bootCleanup*`, `bootClean`, `bootRetry` | Exact initialized-prefix unwind; retained record survives failure; fresh incarnation only after final native/VM consumer and full cleanup. |

Added positives cover contender refusal, same-thread recursion, nested scope
shadowing/restoration, stale nonce refusal, nested return then retained cleanup
failure, checked OPEN failure/original return, and teardown→new incarnation with
stale nonce rejection again. Added negatives separately expose uninitialized
entry guard use, guard across Scheme, concurrent nonce reset, recursive double
initialization, nested scope claiming authority, stale delegation, record release
before original return, stack-local retained context and incarnation renewal
while the original context reader is live. Each safety negative must produce a
decoded distinguishing witness; a checker syntax error is never a counterexample.

This is one invocation owner with a second refusal actor and nested scope, one
accepted VM identity, two incarnations, aggregate consumers, atomic locks and
supported return. It does not prove arbitrary N-way registry fairness, raw
pointer validity, mutex machine-code memory ordering, real moving-GC frame maps,
callback termination or foreign nonlocal control flow. Conditional progress
uses explicit per-action fairness; RETAINED is a safe endpoint, not successful
cleanup. No model result establishes new native admission.

## Grok implementation and focused native acceptance order

Implement the guard/record and wrapper split before changing OPEN. Then wire
explicit identity/prefix delegation, shared run/marker context ownership,
independent P0 READY, checked error return and final-consumer cleanup/renewal.
Changing only the null-vm calculation would remove the observed exit71 trigger
while leaving concurrent reset, early OPEN and retained-context reuse unsolved.

Use a single final producer and bind its exact source manifest, generated C,
link command and GSI digest. Do not inherit the overwritten old39-check GSI's
results. Keep the normal executable link configuration; a dynamic-lookup link
workaround is not native startup acceptance. Do not run the full inventory here.
The targeted native harness should record real return values and barriers for:

- Cold normal startup: VM0/P0 bound before lookup; CLOSED refuses; mapped
  primordial/coordinator roots READY; READY refuses; OPEN accepts exact key.
- Two host setup entrants held at a barrier before early initialization: exactly
  one owner, one nonmutating refusal, one INIT per native resource. Also invoke
  recursive public setup from an authorized callback; it must return without
  deadlock, marker reset or borrowed ticket.
- Inject each native prefix failure; inject marker allocation/association failure
  and checked READY/OPEN failure. Preserve original status, reverse successful
  prefix only, exercise GC before original return and exactly-once finalization.
- A nested ordinary `___run` and a generated SFUN callback cannot consume outer
  P0 READY; after nested return the original entry can. Repeated helper call
  refuses without second publication or init.
- Hold the original marker reader after OPEN or failed OPEN; cleanup/reuse must
  refuse until original supported return. Fail cleanup, return from public
  setup, then inspect retained record/pin without a dangling stack context.
- Drain producer plus queue/handler/wake/VM consumers; verify normal clean and
  failed-then-clean setup use fresh incarnation/nonce. Old leases/delegation fail
  before mutation. Test exhaustion explicitly; no wrap-to-old key.
- Validate P0's independent READY and unchanged target>0 worker collective READY
  with real topology, generated root maps and original bounded watchdogs. This
  model's old growth prefix assumes a valid two-member cohort, not every cold
  1→N bootstrap side effect. Exercise non-SMP builds separately.

These controls make the proposed patch reviewable and falsifiable. They are
requirements for implementation, not commands claimed to have run this turn.
Formal pending→join0 lifecycle contract review remains independent and unchanged.


Reproduce only the bounded model controls from the SMP checkout:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-integrated-growth.py
```

The verifier opens the existing registered `repair-9-12` audit scope and writes
its immutable per-case logs, decoded witnesses and byte-bound receipt to that
run's existing task output area. This command does not compile or execute GSI.


## Executed model evidence

All69/69 expected controls completed on the final expanded model:28 safety and
conditional-progress positives,38 decoded distinguishing safety counterexamples,
3 temporal loop/stutter negatives. Each used the unchanged30-second cap; maximum
observed case duration 23.584s. Quint0.33.0/TLC receipt:
`.cache/tasks/repair-9-12/processes/audit/runs/a6550d55c63749bfb2ad2a6241cf7989/outputs/integrated-growth-model/receipt.json`. All earlier53 controls reran against these bytes, rather
than borrowing their old pass. Exact model SHA256: `ce188e695c38cd36445edabbbc4a45d49e3577dbaef6dcd779c7b4408926a985`.

Read-only qualification result: `{"admitted": false, "count": "8/12", "closed": null, "runsOk": false}`. No runtime source was
modified, no native/GSI test or full inventory ran, no other thread was operated,
and no commit or push was made. The source observation remains unqualified as a
producer binding. The new proof is a finite protocol result under the stated
atomic-lock, valid-owner, aggregate-consumer and supported-return assumptions.
