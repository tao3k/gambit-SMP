# Native-shell staged growth: start gate, roots and failure reclamation

2026-10-23. Proposed implementation protocol plus QNT evidence only. No runtime,
qualification inputs, native execution, other-thread operation, commit or push.
The accompanying index binds the unchanged c86dff86 source and gsi7263fe03.
Count remains8/12; no pending-contract or observer migration is activated.

## 1. Independent decision: do not stage a complete pstate across ordinary GC

`___setup_pstate` is not just native thread creation. `setup.c:5069-5180` calls
interrupt setup, OS/memory setup, processor-Scheme-object initialization, register
initialization and sync-resource setup. `mem.c:4787-4920 ___setup_mem_pstate`
allocates stack and heap msections, initializes RC/wills and prepares memory.
`mem.c:3565 setup_stack_heap_vmstate` then redistributes sections using **active
processor_count**, and resets assigned/stack counts to np*2/np during GC.

Therefore 'call full setup early, park the new thread, let old GC continue' has
an unproved inactive-section ownership problem. A typed root carrier alone does
not reserve those raw sections against the active collector. I reject that as
the default staging plan.

Prefer two layers:

1. **Native shell and native resources**, created before the count change. A
   shell waits on separate VM-owned native control, has no pstate TLS, executes
   no Scheme, does not join collectives, and retains a VM lifetime pin. The old
   cohort can collect while waiting. Startup thunk/errors remain in a typed
   VM-rooted carrier, not shell-thread data_scmobj.
2. **GC-owned pstate construction**, only in the old cohort's final GC-excluded
   reservation/commit interval after all required shells are parked. Construct
   empty initial memory/state, validate, publish count/domain ownership, then
   release GO. No GC may redistribute inactive full-state sections in between.

This reduces staged scanning obligations; it does not make them disappear. All
precommit Scheme payloads still need authoritative traced roots, and rollback
of memory reservations needs an actual allocator protocol.

## 2. Actual entry chain and proposed functions

| Actual function | Source fact | Proposed change |
|---|---|---|
| `os_thread.c:427 start_pthread_thread` | Immediately calls thread->start_fn(thread), then returns | Set start_fn to a new native `___staged_worker_main`, not start_processor_execution. Initialize every control field before pthread_create |
| `os_thread.c:493 ___thread_create` | POSIX pthread_create can start child before parent stores thread_id; thread_init_common currently returns NO_ERR | Publish a parent-owned native_created/handle result after return; child must not read unpublished handle fields. Preserve actual native errors, and distinguish no-child failure from later wrapper/resource failures |
| `setup.c:980 start_processor_execution` | Reads pstate and Scheme thunk from native thread fields before startup NOOP collective, binds TLS, then executes Scheme | Factor body into a supported activated entry. After GO: validate key, bind initialized pstate, participate in startup sync, resolve current rooted thunk **after** that GC-capable loop, then call ___run without an intervening allocating/untraced path |
| `setup.c:5069 ___setup_pstate` | Monolithic OS/memory/Scheme/sync setup with nested cleanup | Split native-resource preparation from GC-owned section/state initialization; return exact resource-phase bits for partial failure |
| `setup.c:4919 cleanup_os_and_mem_pstate`,5035 ___cleanup_pstate | Generic cleanup includes procedural callbacks and void OS/memory cleanup | Add checked unpublished-state cleanup. Require no accepted queue work; never run arbitrary callbacks inside GC-excluded rollback |
| `mem.c:4787 ___setup_mem_pstate` | Initializes sections, locks, actlog, RC and first break frame | Factor fallible native setup out; use a checked reservation bundle for new sections in the final exclusive interval |
| `mem.c:5307 ___cleanup_mem_pstate` | Frees still/RC lists and scan lock; no explicit reversal of msection reservation counters/cursor in this body | Do not equate cleanup with allocator rollback. Add `___abort_pstate_reservation` for the exact uncommitted bundles |
| `setup.c:1196+` growth path | Publishes count then calls thread_create; failure is fatal | Replace with consumption of already created shells; no new pthread_create after count commit |
| `_thread.scm:3316 ##startup-processor!` / READY operation | Scheme initializes queues, unlocks P and publishes READY | Keep this distinct from native PARKED and GO. Stable-new service handoff still waits exact READY/common result agreement |

Proposed names: `___growth_stage_begin`, `___growth_prepare_native_resources`,
`___growth_spawn_shell`, `___staged_worker_main`, `___growth_reserve_pstates`,
`___growth_commit_and_open`, `___growth_abort_shells`,
`___abort_unpublished_pstate`, `___abort_pstate_reservation`,
`___growth_complete_abort`, and an activated worker entry factored from the
existing start_processor_execution. None exists by virtue of this document.

## 3. Control, ownership and root layout

A native stage entry contains full VM/transaction/slot incarnation, gate epoch,
WAIT/GO/ABORT decision, native resource mask, original native handle, parked
acknowledgement, actual join result, native borrowers, independent join-lane
assignment and VM lifetime pin. Store native IDs/root tokens, not movable SCMOBJ
payload copies. Gates are one-shot for that record; generation changes require
old record reclamation first. Counters must not wrap with old users outstanding.

The typed VM carrier holds the actual startup procedure, deferred request and
error references. A stage root token resolves the **current** post-GC value.
A native copied data_scmobj is not a replacement for that reference. The original
entry reads its thunk before a GC-capable startup loop; the proposed factored
entry must explicitly change that timing/rooting, not merely call the old entry
with a different data_ptr type. Generated C and ___run marker lifetime remain
implementation proof obligations.

| Phase | Native/OS owner | Scheme / native GC coverage | Reclaim permission |
|---|---|---|---|
| Shell native preparation / WAIT | Stage ledger owns control/handle; fixed lane reserved; VM pin | Typed carrier scanned by old cohort. Shell has no live Scheme frame, RC/still ownership or GC msections | Never from PARKED or deadline alone |
| Empty pstate construction before count | Stage owns unpublished pstate/reservation; shell still WAIT/unbound | GC excluded. r/saved/type cache VOID, processor fields initialized false, empty initial RC/wills/frame; handlers from GSTATE must remain valid through commit | Only exact reservation abort, no child has touched pstate |
| Count commit and GO | Membership/native-domain transaction gives active slot ownership; one join capability remains assigned | Fully initialized active pstate enters ordinary GC participation. Carrier remains until native thunk/argument consumers and real Scheme roots are proved safe | GO is irreversible; ordinary retirement needed thereafter |
| ABORT before count | Stage retains original control/handle; same fixed native join owner | Shell executes native exit only; typed carrier remains. Any unpublished sections stay excluded until undone | Actual keyed join0 plus control/creator/reader grace; memory reservation undone separately |
| Aborted and cleaned | Stage result/error plus service debt still VM-owned | Stable old cohort scans surviving carrier until ABORT ACK/grace and final error consumer | Release only resources whose cleanup actually succeeded |
| Rollback fails | Preserve original key, resources, carrier, VM pin and epoch | Native-only retained shell can coexist with old GC. Unreleased inactive sections cannot silently be exposed to old GC | No slot/epoch reuse; no claimed successful recovery |

PARKED means only native gate readiness. EXIT_HINT is not OS termination. Only
real ___thread_join return0 authorizes handle-dependent reclamation. For successful
activation, keep stage control pinned through the worker's actual retirement
join and remaining control borrowers, unless a separately proved early control
handoff is implemented. Copying a native handle identity into the active owner
must not duplicate join/close capability or memcpy mutex/condvar objects.

## 4. Precreate and gate sequence

1. At the existing supported lock-free preparation landing, claim unused slot
   incarnations whose prior storage/borrowers/sfun markers are all clear. Root
   startup arguments/error state, register VM pins, reserve independent join
   lanes and native control capacity before accepting growth.
2. Initialize gate predicate, key and resource flags before creating each native
   child. Move fallible OS resources (interrupt mutex, pipe/selector state, sync
   mutex/condvar and actlog/native locks as applicable) to checked preparation
   outside the final GC-excluded interval. The precise split must be audited;
   do not assume malloc/syscalls are bounded because they are not Scheme code.
3. Spawn each shell through ___thread_create. Its start_fn is the native gate
   entry. It does not call ___thread_set_pstate, ___run, service_sync_op, Scheme
   callbacks or GC. It publishes PARKED and waits for a matching decision using
   its separate native control.
4. Gate waits use a persistent predicate and a checked notification mechanism.
   A timed native recheck can recover a lost notification; preserve the original
   overall stage deadline across spurious wakeups/interruption. A timeout requests
   precommit ABORT, never certifies exit. A permanently broken mutex/wait path
   retains the entry; do not widen the budget or manufacture an acknowledgement.
5. Parent acquires every required PARKED acknowledgement. The old cohort stays
   serviceable while waiting, so request/result thunks need not execute on shells.
   Creator return, child park and join completion are separate ownership events.
6. Run the existing old-cohort heap guard/direct-GC/common-outcome protocol,
   preserving VM service demand. In its final GC-excluded interval reserve all
   new section bundles and build empty full pstates. If any step fails, no GO or
   count publication occurs. All members take the same abort/result schedule.
7. Commit count plus native scan ownership through the existing collective
   publication point. Only after the common commit release each gate GO for the
   same full key. Publishing GO is a release of initialized payload; the child
   acquire precedes TLS binding or any pstate access. No child may read target
   pstate before that acquire.
8. GO children enter the factored startup NOOP path, then resolve the rooted
   thunk and run Scheme. Exact READY remains necessary for stable-new handoff.
   After GO, a failure is an active membership failure; precommit ABORT cannot
   undo it. The earlier HANDOFF protocol transfers pending VM service debt.

WAIT->GO and WAIT->ABORT compete under one native decision discipline. Duplicate
same-key decisions are idempotent. GO->ABORT, stale-epoch GO/ABORT and control reuse
while any creator/worker/joiner can access it are forbidden. Notification alone
is not the gate predicate or the commit linearization.

## 5. Abort, exact resource prefix and allocator rollback

A partial create failure must record which native children actually exist. Send
ABORT to the successful prefix; late-starting children may observe ABORT without
ever announcing PARKED, then return natively. Fixed independent lanes join each
actual handle; uncreated entries need resource-prefix cleanup but no invented
join0. A nonzero native join result retains that record; never relabel it pending
or assume another join will repair it. QNT join-error control is an abstract
fault/injection disposition, not evidence of reachable Darwin error11 recovery.

Do not call monolithic ___cleanup_pstate blindly after a failed partial setup:
its nested helpers may already have cleaned a prefix. Record exact successful
resource transitions and cleanup results. Existing sync resources may be slot/
VM-owned until cleanup_vmstate_locked; they are not automatically per-attempt
objects. No close/destroy result may be silently promoted to success.

The msection rollback API must own a list of **only newly reserved bundles**,
plus its allocator generation and phase. Under GC/allocation exclusion, verify
no GO, TLS binding, Scheme allocation, native queue borrower or other publication
used them; unlink/release those bundles and adjust only their actual accounting.
No whole-pstate/VM memory snapshot restoration, fromspace rewind or stale register
copy is permitted. The existing next_msection path modifies shared allocator
cursor/counts, and ordinary cleanup does not visibly undo those modifications.
A custom_msection_alloc callback requires its own checked reserve/release contract;
this proposal has not proved it GC-free or reversible. Do not change configuration
to hide that limitation.

After successful memory undo, native cleanup failures may retain separate OS
resources/control without retaining untracked Scheme sections, if that separation
has been proved. If reservation rollback itself fails, either keep GC exclusion
and enter checked terminal retention, or implement a real inactive scan/allocation
registry. The latter is not supplied here. Therefore the model's retained
reservation-failure outcome does **not** prove the old VM can resume GC.

Only after real created-child joins, resource-prefix disposition, old-cohort
ABORT ACK and reader grace can the old stable certificate and service cut be
acknowledged. A native-only join-error retention may still allow the old cohort
to service its debt while retaining the blocked resource pin. It does not permit
slot reuse or successful VM teardown. A retry uses new nonwrapping stage keys
and preserves the VM demand/ACK watermark; no reset to0 at epoch2.

## 6. External work and async entry boundary

`setup.c:489 ___raise_procedural_interrupt_pstate` accepts a raw pstate, enqueues
and returns void. Its existence means 'slot not in processor_count' alone does
not prove no native publisher can touch it. Admission/owner validation must
exclude staged slot incarnations **before** a request is accepted. Add a checked
owner/phase path and migrate relevant callers; a void API must not silently drop
an already accepted request. If that proof cannot be supplied, staging refuses
that slot/context. Generic cleanup_interrupts_pstate invokes execute_fn and is
not a safe substitute inside the nonallocating commit/undo interval.

The inspected heartbeat chain is os_time.c:987 -> os_setup.c:3037 heartbeat_intr
-> global ___raise_interrupt; it does not by itself show a direct TLS pstate
lookup in the shell. This does not complete all signal/foreign callback routing
or native gate error analysis. Existing heartbeat-mask helpers address that
signal, not proof of every async entry. The shell's no-VM-entry requirement still
needs platform/generated/native verification.

## 7. Model result and sufficiency assessment

`models/gambit/staged_growth_workers.qnt` separates native-created/parked from
full pstate, count commit, gate decision, TLS-bound, Scheme run, READY, native exit,
join0, reservation ownership, roots, reader grace and service debt. Old GC may
repeat while only shells exist. Full inactive sections require GC exclusion.
Three controls retry epoch1 failure at epoch2 only after actual cleanup/grace,
with new keys and preserved service watermarks.

Eight positive scenarios: success; partial creation failure then retry; gate
timeout abort; retained native join error; setup-prefix failure then retry;
retained reservation rollback failure; retained post-GO startup failure; native
gate/resource initialization failure then retry. Positive retained outcomes are
not successful activation, rollback or VM availability.

Eleven safety negatives cover premature count, shell binding before GO, stale
GO, ABORT after commit, free before join0, stale native thunk, GC over inactive
heap, carrier drop after ABORT, retained epoch reuse, cleanup without reservation
undo and clearing service debt on ABORT. Two temporal negatives show missing gate
deadline can stall preparation, and retained native error does not imply eventual
successful recovery. Action-specific fairness is explicit, not worker progress
proved from a counter flag.

Independent verdict: native-shell staging removes the immediate post-count OS
thread creation failure and avoids needing to scan dormant Scheme frames during
shell wait. It does not yet prove a production-safe runtime patch. Required C
refactors include setup/resource phase splitting, checked allocator reservation
undo, owner admission for unpublished slots, typed thunk resolution, fixed
count/GO/common-outcome ordering, error-safe gate waits and source-bound native
fault tests. Post-GO Scheme startup can still fail; staged native creation does
not prove arbitrary startup/callback termination or recovery from every failure.
An inactive full-state rollback failure still needs a terminal policy or additional
collector support. Those are material remaining conditions, not completed gates.

Verification:21/21 expected controls accepted:8 positive safety/conditional-progress
scenarios,11 decoded invariant negatives,2 temporal loop/stutter negatives. All
checks stayed below the original30-second cap. One initial parser failure is
retained; no timeout/budget change or old-model rerun was used.
Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/3d3908cc6eb9468dbafd2fb4025d54ac/outputs/staged-growth-workers-model/receipt.json`. No native execution or9/12 admission.
