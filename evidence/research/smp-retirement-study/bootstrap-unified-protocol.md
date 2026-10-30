Current84-case root/native-tail/publication correction: generated-root-handoff.md/json. Earlier counts and lock suggestions below are historical.

Current followup: setup-ticket-propagation.md/json extends this same model to69 expected controls, including persistent ticket authority and original marker lifetime. The53-case narrative below is historical and retains its own immutable receipt.

# Bootstrap identity and admission in the unified growth model

2026-10-23. repair-9-12, evidence only. No runtime/native/other-thread/commit/push.

## Concrete change in the proof boundary

The previous 30-control model assumed an already valid VM identity. The same
`models/gambit/integrated_growth.qnt` now begins with unbound bootstrap state.
Every old scenario must establish explicit VM/P0 identity, prepare native
resources CLOSED, establish mapped Scheme roots/READY, then OPEN before entering
the existing staged-growth/reservation/request/GC/debt transitions. This is not
a detached bootstrap model with an assumed-success join to the old one.

State sequence:

`Fresh → IdentityBound → SlotMutex → NativeMutexes → CLOSED → SchemeREADY → OPEN`

Failure and reuse sequence:

`checked init failure → reverse exact prefix cleanup → Clean → fresh epoch2`

or

`cleanup failure → Retained(resources, identity, VM pin, original error)`

A repeat call over CLOSED, OPEN, DRAINING with a live consumer, or Retained is a
nonmutating refusal. It cannot reset the incarnation, producer count, mutex or
resource mask. A completed failed initialization and a completed normal teardown
can each authorize fresh setup in epoch2; neither is inferred from a failure
banner or producer_count==0.

## Exact source-to-model mapping and modification order

Source anchors use immutable source observations from audit
bad1e9aa8d7d47e2a1304a6225f6f2ae. They describe the observed regression, not a
claim that the mutable producer still contains exactly those bytes.

| Step | Actual function / field | Required modification | Unified QNT |
|---|---|---|---|
| 1 | `___setup` early VM0/P0 interrupt initialization at7291; `request_slot_id`383 | Bootstrap already owns live `&gstate->vmstate0` and slot0. Validate explicit owner/slot/pstate equality with checked bounds before deriving any pointer. In threaded layout bind `ps->vmstate` before existing readers; do not use a null-base PROCESSOR_ID subtraction. | `bootBind`, `bootRejectIdentity`, `identityBound`, `bootVm`, `bootSlot`. |
| 2 | `setup_interrupts_pstate`705; current `request_open_slot`395 | Split native resource preparation from OPEN. Proposed `request_prepare_closed(vms,slot,ps,key,mask)` initializes only native slot/procedural mutexes, flags and empty queue state. Public acquire rejects. Prepare is serialized by an already valid instance/registry owner, not a mutex that has not yet been initialized. | `bootSlotInit`, `bootProcInit`, `bootQueues`, `bootRes`, `bootEver`. |
| 3 | `___setup_pstate`5360–5392 | Keep explicit identity invariant for all pstates. VM0/P0 reuses the exact prepared bootstrap record through its existing skip-initialization arm. Do not reopen/reset or destroy it during repeated setup. Distinguish initialized mutex (`ready` in current native record) from Scheme readiness. | `bootRepeat` while CLOSED, `bootEpoch`, `bootRepeated`. |
| 4 | `___setup_vmstate`, thread_init_from_self/TLS bind, `___run` kernel startup at7350–7410 | Keep public admission CLOSED while VM/native/memory/module state and mapped Scheme roots are incomplete. Bootstrap/SYNC/GC flags use their private existing path. Do not make startup depend on a public queue that cannot yet be safely serviced. | `bootProbeClosed`; `bootScheme` represents completing the checked readiness prerequisites. |
| 5 | SMP `_thread.scm:##startup-threading!`3401–3472 | Concrete P0 READY candidate: tail after primordial thread/current-thread, processor queues, interrupt handlers and `##fault-control-make!` rooted record exist, outside T/P/V locks. Add a checked nonallocating private P0 ready/open helper using current known owner/key. Propagate its actual failure through the startup error path. | `bootReady`, `bootRoots`, `bootProbeReady`, `bootOpenReady`. |
| 6 | worker `_thread.scm:##startup-processor!`3318 and `___processor_startup_complete`1746 | Preserve worker collective READY and exact scheduler epoch. Only after its agreed successful return, before reacquiring P lock, open checked admission for that exact initialized worker. A staged shell/count change is insufficient. | Existing `publishGo → bind → startupGc/runScheme → publishReady → open`. |
| 7 | `___pstate_request_acquire[_current]`, close/release, slot metadata | OPEN/identity/key publication and validate+pin use the same initialized admission mutex with release/acquire synchronization. Refused acquisition takes no node ownership. Previously granted leases survive close; queue/handler/wake consumers remain distinct. | `bootGrant`, `bootBorrow`, `bootClose`, `bootReleaseBorrow`, plus separate existing growth `leases/queue/wake`. |
| 8 | `cleanup_interrupt_resources_pstate`, `cleanup_failed_pstate`, early ___setup error returns | Cleanup uses explicit prepared identity and exact successful-init mask. Destroy in reverse actual dependency order, once per resource; never inspect later-uninitialized fields to discover the owner. Preserve the original setup error separately from cleanup error. Partial CLOSED cleanup must not require OPEN. Retain failed cleanup and roots/native pins. | `bootCleanup(3/2/1)`, `bootDestroyed`, `bootCleanupFault`, `bootClean`. |
| 9 | instance teardown and subsequent setup admission | Close, drain every real last consumer, finish checked cleanup/grace, then admit a fresh incarnation. Reject repeated calls over live/retained records. Refuse epoch exhaustion before mutation; no ABA wrap. | `bootRepeat`, `bootRetry`; modeled epochs1 and2, not an unbounded arithmetic proof. |

### P0 cannot blindly reuse the worker READY function

The observed `___processor_startup_complete` invokes an all-processor operation.
Its `OP_PROCESSOR_STARTUP_READY` arm at1540 explicitly requires `target > 0`.
Calling it for P0 would not publish P0 READY; it is also not a justification for
introducing a new bootstrap collective. Keep a distinct scalar bootstrap
certificate consuming explicit VM/P0 identity and completed Scheme-root setup.
Use the existing worker certificate only for workers. Do not weaken its target
or epoch guards merely to reuse a function name.

### Observed reuse is missing a fresh-incarnation transition

The saved setup.c initializes `slot->incarnation = 1` at415. Its recorded
cleanup at841 only sets CLOSED; the observed implementation has no increment
transition for a fresh setup. Thus merely reusing that record after cleanup
would not implement QNT `bootRetry` (new epoch2). Add a checked nonwrapping
incarnation renewal before publishing the fresh record, preserving prior
retained records; old externally remembered keys must fail the shared checked
acquire. Exact-key acquire already validates incarnation under the slot mutex,
but that comparison cannot reject an old key if the value never changes.

`bootGrant` models acquisition with the exact current bootstrap key; stale-key
rejection and explicit delayed publications are separately exercised by the
shared growth admission transitions in this same model. Native acceptance must
also replay a P0 old key after fresh setup. The model does not claim an old key
becomes harmless merely because all its previous live borrowers exited.

### Last consumers and ownership

- Until prepare succeeds, caller owns the known VM capability and partial
  resource mask. No public request is accepted and no Scheme handler runs.
- During CLOSED/READY, the instance/native record retains its key and pin; only
  successfully initialized mutex/queue state may be cleaned.
- During OPEN/DRAINING, producer release is not final resource release. Queue,
  active handler, wake writer, mapped Scheme frame, native marker and VM reader
  must all hand off/leave before slot/native-control cleanup.
- `bootBorrow` abstracts a nonzero union of those live consumer obligations for
  bootstrap reuse. `bootReleaseBorrow` means **the final consumer** leaves,
  not merely producer_count becomes0. Existing growth transitions separately
  model producer/queue/wake completion. C must implement this predicate rather
  than replace it with a producer-only check. Native tests must hold each class.
- On failed cleanup, original error + native resource mask/key/pin remain owned.
  Do not reset an initialized flag while a corresponding destroy failed, and
  do not claim release on a nonzero checked cleanup status.

## Controls in the one model

Old scenarios are rerun on the expanded graph. New positives cover:

1. Repeat setup over OPEN with a live consumer: refuse, preserve key/counter,
   then allow that consumer's real final release and continue growth.
2. Wrong explicit VM and wrong explicit slot: reject without derived lookup or
   resource initialization. Error classes are abstract; exact C fixnums remain
   a native acceptance requirement.
3. Failure at slot mutex, procedural mutex, and later pre-READY checkpoint:
   clean only initialized prefix, preserve setup error and keep OPEN false.
4. Hard cleanup failure: retain resource suffix/key/VM pin; repeated setup must
   refuse without clearing that evidence.
5. Clean failed init→epoch2 startup; repeat over CLOSED; normal OPEN→DRAINING→
   completed teardown→epoch2 setup followed by the existing real growth model.

Eleven new negative controls distinguish lookup before binding, null/wrong identity
aliased to P0, OPEN before READY, destroying uninitialized storage, double
destroy, resetting live incarnation, freeing retained resources, erasing original
error, reinitializing an existing mutex, growth before bootstrap OPEN, and dropping roots before an OPEN-failure C return.

An additional positive fails checked OPEN after Scheme READY. It keeps mapped
roots and the VM pin in state12 (`bootReturnPending`) until `bootReturn` models
the supported original C/Scheme return, then permits native prefix cleanup.
`bootGc` allows repeated abstract GC while Scheme roots exist at READY or this
pending return. The corresponding negative drops roots before that return and
must violate safety. This does not model arbitrary longjmp/cancellation or
prove a native stack map; C must use the supported ___run/marker return paths.

The model does not compute a portable integer from null C pointer subtraction:
`invalidLookup` records that forbidden operation. The supplied id3360434 and
fixnum/exit71 remain native observations; they are not synthesized as a normal
slot exhaustion path. No pending→errno substitution is introduced.

## Focused native startup acceptance for Grok

These are tests to implement/run through the existing same-task supervisor and
registered source-bound producer, after normal exclusive custody is available.
No native test is executed by this evidence update.

- [ ] Bind changed source, generated C/headers, compiler/SDK/link flags and actual
  GSI bytes. Preserve the unusable c65582f4…/exit71 evidence and historical7263fe03
  receipts. A producer directory name is not executable identity.
- [ ] **Cold P0 startup:** trace explicit VM0/slot0 before interrupt init. No
  request_slot_id call can read unbound vmstate. Reach ___setup_base_module,
  thread startup and supervised minimal Scheme startup/exit0 with the existing
  configured processor topology. Do not lower processors or add dynamic_lookup
  as an unrecorded workaround. Link failure and running-process exit are separate.
- [ ] Pause at native CLOSED and at Scheme READY-before-OPEN. Both high-level
  and procedural checked acquisitions must return a caller-visible rejection;
  caller retains payload. Resume OPEN and require actual single delivery/reply
  with mapped roots on the same executable.
- [ ] Inject each init prefix failure. Require native UNKNOWN_ERR for actual
  mutex init failure, distinguish it from identity/limit rejection, and retain
  the exact original error if cleanup also fails. No uninitialized/double mutex
  destroy and no lookup through an unbound pstate on the cleanup arm.
- [ ] Repeat setup over CLOSED, OPEN, DRAINING and Retained. Compare exact key,
  initialized bits, producer count and queue/wake/handler ownership before/after
  refusal. Release producer but hold a queued handler, wake writer or native
  reader; setup must remain refused. Then complete actual teardown/grace and
  require a fresh epoch rather than reopening old storage; replay the previous
  P0 incarnation and require typed rejection before publication.
- [ ] Pass null/wrong live VM capability and negative/out-of-range slot to
  checked preparation; reject before pointer subtraction or invalid dereference.
  An unbound secondary pstate must never alias P0. A raw arbitrary pointer is
  outside the checked-instance contract, not made safe by this range check.
- [ ] Force moving GC between native setup and Scheme READY and at readiness
  helper return. Inspect generated C frame/root coverage, fault coordinator VM
  root and current-thread root. Native lease state does not itself root SCMOBJ.
- [ ] Check P0 and worker READY separately. Worker open occurs after exact
  collective startup success and outside P lock; P0 helper does not silently
  hit the worker `target > 0` no-op arm. Failed READY/open cannot publish success.
- [ ] Run the prior paused staged-grow/reservation/lease/fault controls on one
  final completed executable, under existing child caps/deadlines and configured
  p11/topology where required. Startup success alone cannot inherit old39 rows
  or complete first-eight qualification, retirement/finalize or formal9/12.

Use existing native startup/control child limits (30s where that control already
uses30s), actual absolute deadline and process reaping/group-quiescence checks.
No formal-stage budget or timeout policy is increased. A new fixture must be
registered in the existing workflow, not advertised here as already implemented.

## Independent judgment

This removes a missing bootstrap precondition from the finite protocol and makes
its failure/reuse semantics executable. It does not repair or certify the C
producer. Native mutex/atomic memory-order refinement, concrete SCMOBJ roots,
all actual initialization side effects, arbitrary host-pointer validity and
unbounded multi-VM concurrency remain implementation/native obligations.

The finite model uses one valid VM identity, rejects a second/wrong identity,
and bounds incarnations to two. It does not prove a process-global slot table
can support simultaneous VM0/P0 and VM1/P0; supported multi-VM implementations
need VM-owned slots or a properly keyed owner registry. C generation exhaustion
must refuse safely; finite2-epoch tests alone cannot prove no-wrap arithmetic.
The late failure control represents a checked initialization failure before
public admission, not arbitrary nonlocal Scheme escape. Those distinctions
prevent these model passes from being relabeled as full runtime closure.

## Expected cost and finite abstraction

Bootstrap adds one-time identity/phase/resource-mask bookkeeping and serialized
OPEN publication; it does not need a new lock on Scheme allocation or a polling
result-mutex path. Native failure cleanup is bounded by the successfully prepared
prefix unless an OS cleanup operation itself fails, in which case resources
remain owned. Existing checked admission's per-request cost is unchanged by
making native preparation CLOSED. No startup-latency or throughput improvement
is claimed without native measurements.

`bootErr` is an abstract first-error class, not an errno or encoded Gambit fixnum;
retained cleanup failure is represented by phase8 and its untouched resource
suffix. C must retain both exact first setup status and separate cleanup status.
The three bootstrap resources abstract admission mutex, procedural mutex and
native queue/flag state; all other actual VM/module/memory initialization side
effects remain under the existing full-prefix cleanup contract and native tests.

The pre-existing growth instance still abstracts an established two-member old
cohort and a valid allocator prefix when growth begins. Bootstrap actions do
not read that growth state before P0 OPEN. This proves the new P0 admission
prefix composes with that growth instance; it does not construct a real cold
VM's entire1→N memory/cohort initialization history. The native cold-start test
must exercise the actual configured worker count and the real staged-grow call
path, rather than treating this finite instance as a cold-boot C simulation.

### The prepare guard must exist before the slot mutex

A Scheme V/P lock is not an early-bootstrap lock, and the slot mutex being
created cannot protect its own creation. Use the process/library's real native
setup-once/instance-admission ownership before publishing callable slot entries.
If that owner is not already available at this point, add an explicitly initialized
native once/registry guard before any checked slot API can inspect init flags.
The process-owned guard is not destroyed by partial P0 cleanup.

A concrete prepare sequence is: under that owner, reserve the full VM/slot key
as PREPARING; build the private successful resource prefix once; publish CLOSED
with its complete initialized mask; only then expose the record for checked
lookup. Acquisitions seeing PREPARING reject without locking an uninitialized
slot mutex or dereferencing pstate. READY/OPEN and duplicate-setup arbitration
then use the established native lifetime/phase discipline. Do not leave plain
`slot->ready` reads racing first initialization, or publish a pointer whose
mutex can be destroyed while a checker is waiting to lock it. Native test two
concurrent setup attempts: one owns preparation, the other refuses without any
second mutex initialization. The QNT actions model those serialized phase
transitions; this paragraph is a C implementation obligation, not a proof that
a suitable once/registry guard already exists in the observed producer.

### Internal continuation is not another setup invocation

`bootSlotInit→bootProcInit→bootQueues` represents one authorized prepare owner;
`bootRepeat` is a new invocation lacking that private continuation authority.
Implement this distinction with an explicit setup ticket/context carrying the
full VM/slot/incarnation and native prepare ownership. Route the internal
___setup→___setup_vmstate→private prepared-pstate continuation through that
context. The existing VM0/P0 skip arm must validate/reuse its matching prepared
record, not reset it and not reject its own authorized continuation.

A public/recursive second ___setup_pstate call must not retrieve another active
call's ticket from shared VM storage and impersonate continuation. Same OS thread
is not sufficient authority: same-thread recursive setup is still a second
invocation. Either pass a private prepared-context parameter along the internal
call chain or provide a private helper whose context comes only from its actual
prepare owner. Keep the legacy/public fresh-setup wrapper's admission/refusal
separate. The QNT abstracts this owner distinction by separate guarded actions;
C/context authenticity and unwinding lifetime remain native obligations. Test
both authorized continuation (no second init) and same-thread recursive setup
(refusal with resource mask/key unchanged).


## Executed verification

Final53/53 expected controls:21 safety/conditional-progress scenarios,29 decoded
distinguishing invariant counterexamples,3 temporal loop/stutter controls. Every
case remained under its original30-second cap. Quint0.33.0/TLC, receipt:
`.cache/tasks/repair-9-12/processes/audit/runs/d2420daa2c3e434194e10e13539c6ad3/outputs/integrated-growth-model/receipt.json`. Maximum observed case wall time:
22.075s. All prior growth controls reran on
the expanded graph; no old receipt substitutes for this model's bytes.

The first51-control bootstrap extension also passed but was superseded after
review added checked OPEN failure, pending original C return/root retention and
optional abstract GC there. Its immutable receipt stays at audit
9cf6639a39234b5ca26a782db18f26c4/outputs/integrated-growth-model/receipt.json.
All53 final cases reran. Selected state counts: {"initSuccess": {"generated": 65929, "distinct": 12046}, "initBootstrapTeardownSetup": {"generated": 66005, "distinct": 12082}, "initBootstrapOpenFail": {"generated": 49, "distinct": 22}}. No native execution or source/producer reseal occurred.
Final qualification read: {"admitted": false, "count": "8/12", "closed": null, "runsOk": false}.
