# Concrete replacement: private msection construction and checked request leases

2026-10-23. Design decisions and source-bound QNT evidence for repair-9-12 only.
No runtime, observer, recipe, native program, other thread, commit or push.
The accompanying JSON binds c86dff86 source and gsi7263fe03; count stays8/12.

## 1. What changes instead of adding another rollback mechanism

The preceding staging proposal left allocator reversal and unpublished-slot
admission as prerequisites. This revision makes two concrete architecture choices:

1. **No global allocator mutation before growth commit.** Borrow an unused suffix
   privately, initialize only unpublished views/pages, then either publish the
   complete batch once or abandon it. A failed constructor does not need to
   reconstruct shared allocator history because it never changed that history.
2. **No public bare-pstate enqueue contract.** Validate full VM/slot incarnation
   and obtain a nonrevocable producer lease in one native admission operation.
   Publish under that lease; closing admission prevents new leases and waits
   for old producer/queue/wake consumers before slot reuse. Denial occurs before
   node ownership moves. Migrate the callers/exports as one source/API change.

These replace the candidate's earlier compensating ___abort_pstate_reservation
plan for the default allocator. They do not rewrite historical evidence. They
are implementation choices, not runtime changes already applied in this tree.

## 2. Exact allocator facts

`mem.c:3218 next_msection_without_locking` selects `the_msections->head` when
assigned count is0, otherwise `alloc_msection->next`. A successful new assignment
writes alloc_msection and increments nb_msections_assigned. At exhaustion it may
share an existing section or call fatal_heap_overflow. A custom_msection_alloc
hook bypasses this default path.

`next_stack_msection:3376` also increments nb_msections_stacks; the heap path at
3530 updates words_prev_msections and sets heap view pointers. Thus 'subtract
2 sections' is not a complete rollback specification. `___cleanup_mem_pstate:5307`
frees still/RC and the scan lock; it does not visibly reverse the shared cursor/
assigned/stack changes. Global cursor rewind after another allocator operation
would overwrite someone else's ownership.

However `set_stack_msection:3284` and `set_heap_msection:3457` establish local
view pointers without advancing the global assignment cursor. Distinct reserved
stack/heap sections avoid the sharing/fatal fallback helpers. This supplies a
concrete route to construction without an inverse global allocator operation.

### Replacement functions in mem.c

All names below are new proposed interfaces, not existing native guarantees.

`___reserve_private_pstate_sections(vms, k, reservation)`:

- Require the old cohort's completed GC-safe rendezvous, no mutator allocation,
  stable allocator generation and GC exclusion. Native descriptor/node arrays
  were allocated before this interval. No Scheme callback or malloc here.
- Under ALLOC_MEM_LOCK capture the actual cursor, assigned count and stack count;
  use actual values, not processor_count*2. Preflight checked integer additions
  and walk exactly2*k distinct available suffix nodes. Verify enough space;
  return a common precommit error before changing any allocator field if not.
- Record head/tail/node identities, allocator generation and the private stage
  key. Do **not** update global cursor, counts or msection list links. The
  reservation is a private claim while exclusive construction is in progress,
  not a new native scan domain or a detached free-list allocation.
- Do not call next_msection_without_locking or its fallback/custom hook from
  this constructor. The default path is the supported implementation here.
  A custom allocator needs an explicit equivalent transaction adapter; otherwise
  return unsupported before accepting that growth. Do not change configuration
  or claim the ordinary callback is reversible.

`___init_empty_pstate_from_sections(ps, stack_node, heap_node, stage)`:

- Native fallible resources were prepared first with an exact resource mask.
  Set only unpublished local views via the direct set_stack/set_heap operations.
- Initialize the first break frame, empty RC/still/will state, VOID register/
  saved/type-cache fields and false processor-object fields. No user allocation,
  external publication, callbacks, shared fallback or Scheme execution occurs.
- Keep limits unpublished until their inputs correspond to the committed view.
  prepare_mem_pstate at4711 reads global approximate free space. Factor its
  nonallocating numeric limits portion, or run that portion after counters are
  committed but before membership/GO becomes observable. Do not compute future
  limits from stale shared allocation accounting and call the result finalized.

`___discard_private_pstate_sections(reservation)`:

- Verify the stage has not committed and no gate GO was published. Slot admission
  stayed closed; no producer lease or native worker can observe these views.
- Clear/invalidate every partially built pstate view and local ready bit, then
  release the private claim. Bytes left in unused pages are not live objects.
- Leave global cursor, assigned/stack counts and chain links **unchanged**.
  Drop allocator/GC exclusion only after all unpublished views are unreachable.
  Do not run generic cleanup callbacks or OS close under this lock.

`___commit_private_pstate_sections(reservation)`:

- After all checks and empty-state construction, commit cursor=tail,
  assigned=base_assigned+2*k, stacks=base_stacks+k, finalize numeric local limits,
  and publish membership/native-domain ownership in the same GC-excluded common
  transaction. No recoverable error is introduced after the first shared write.
- Publish GO only after complete pstate/count visibility. A cancellation arriving
  after this point gets TOO_LATE / active-lifecycle handling; it never invokes
  private discard or restores old counters.

The section chain is not unlinked, and no whole-VM/pstate memory snapshot is
restored. Exact abort is therefore an identity operation on the shared allocator,
plus invalidation of private views. This is the key simplification.

## 3. Lock order and old-GC recovery

Do not extend the existing ALLOC spinlock around a blocking registry close.
The proposed collective publication sequence is:

1. Close staged-slot admission and drain any previous-incarnation leases/work
   before staging; initialize native controls/resources outside T/P locks.
2. Reach the old-cohort safe rendezvous. Close/drain the existing short native
   VM-registry readers **before** taking ALLOC_MEM_LOCK. This is distinct from
   waiting for all VM lifetime pins: blocked join lanes keep lifetime pins and
   must not block a count-publication reader fence.
3. Take ALLOC lock, privately reserve/construct, then commit or discard. Refactor
   barrier_sync_op's count-publication path to consume a valid preclosed registry
   guard; do not lock/close the same registry again while holding ALLOC. The
   original shrink close lives near setup.c:805 and must remain semantically
   effective, not be bypassed by a caller-supplied boolean.
4. Release ALLOC before registry reopen/replay. Complete the common result/ABORT
   schedule before allowing old Scheme work/GC to resume.

On a partial setup failure before shared commit, the private discard removes all
unpublished heap views without allocator reversal. After old-member ABORT ACK,
reader grace and the stable-old certificate, GC can run using unchanged old
allocation ownership. Service demand is not reset; a stable cohort acknowledges
only its inspected cut as specified by resize-service-debt.md.

Failure closing native pipes/mutexes is now separated from memory rollback.
Keep failed native control/resource masks and their VM pins, but do not keep an
unregistered full inactive heap merely because an OS resource is retained.
The old collector may proceed once the private views are gone. Retained native
resources still block slot reuse/VM destruction; GC resumption is not proof of
successful resource reclamation.

Pure private-view invalidation introduces no ordinary failure-return step. A
memory fault, a violated exclusive-ownership invariant, or a forged raw pointer
is not made recoverable by allocating a rollback journal. Treat detected invariant
violation as checked terminal corruption, not 'rollback succeeded'. The protocol
prevents the supported concurrent writers from producing that state.

## 4. Request admission that closes the check-then-use race

Actual setup.c:364 ___raise_high_level_interrupt_pstate locks the processor
Scheme queue, publishes a node, unlocks and wakes it. At489 the procedural path
locks procedural_interrupts_mut, links a native node and wakes the pstate.
Neither function takes a generation-bearing owner capability; both return void.
The low-level flag API at66 even documents ignoring notification before init.
Such a flag is not an accepted request or queue-lifetime guarantee.

Replace the public contract with these proposed functions:

- `___pstate_request_acquire(vm_owner, slot_id, incarnation, lease*) -> status`:
  while holding one short native slot-admission mutex, validate the VM lifetime
  owner, exact incarnation and ACTIVE_READY phase, then increment its producer
  lease. Validation and pinning have one linearization point. Return REJECTED
  without transferring the caller's node/payload on STAGED/STARTING/CLOSED/stale.
- `___publish_high_level_interrupt_leased(lease, rooted_intr)` and
  `___publish_procedural_interrupt_leased(lease, native_intr)`: publish under the
  existing respective queue lock. The valid lease protects target lifetime even
  if admission changed to DRAINING after acquisition. Only node publication
  transfers ownership to the queue. Scheme payload rooting remains authoritative.
- `___pstate_request_release(lease)`: after the producer's final queue/wake access,
  release the producer lease. An asynchronous wake writer needs its own actual
  last-consumer accounting; do not release lifetime coverage before it finishes.
- `___pstate_request_close` under that same admission mutex changes OPEN to
  DRAINING, then releases the mutex. Wait/drain outside admission and T/P locks.
  No new leases; previously granted ones finish and accepted queued work receives
  an execute/migrate/error disposition. Slot reuse additionally requires queue/
  handler/wake/native/scan obligations, not only producer_count==0.

The admission mutex is **not held while taking the processor/procedural queue
lock**, invoking callbacks, waiting for a producer, or collecting. That avoids
an admission->P versus P->admission inversion. A close cannot invalidate an
already granted lease, nor can a precheck without a lease authorize publication
later. The model tests both interleavings.

### Required source/API migration, not a silent compatibility fallback

Migrate include/gambit.h.in imports and GSTATE function entries at13521/13532,
setup.c assignments at6805/6814, and the Scheme adapter
_kernel.scm:1520 ##raise-high-level-interrupt. Regenerate _kernel.c and headers
as part of the future implementation. Existing exported void raw-pstate entry
points cannot express preacceptance refusal or authenticate an arbitrary cached
pointer. Stop supporting unleased external use in the new contract; migrate and
rebuild native clients. Keep any unchecked helper private and callable only
with an already acquired owner capability. Do not add a fallback that silently
drops work or guesses the current incarnation from an old external pointer.

This is an explicit compatibility cost of the stable ownership solution.
In-repo search finds the Scheme adapter plus generated equivalent and exported
function-table/import surfaces; it is not evidence that every external binary
client has already migrated. The implementation boundary must enforce the new
contract, not depend on external callers voluntarily honoring an old void API.

## 5. Already accepted thread request versus a refused wake hint

Current bound _thread.scm:1370 ##thread-intr-propagate! publishes the result-mutex
node into the thread's queue first. ##thread-intr-notify! at1404 creates a **fresh
high-level hint**, and ##thread-intr-wake! can forward a new hint after migration.
These are distinct nodes and ownership events.

A checked hint enqueue returning REJECTED does not undo the already accepted
thread request. The Scheme adapter must return typed notification status.
On stale/closed target, ##thread-intr-notify! rechecks the thread route under
existing T/P ownership, captures the current slot/incarnation, and retries or
uses the existing durable wake-fault/coordinator obligation. Keep the primary
node rooted in its thread queue and preserve the waiting sender. Do not mark
it never accepted, free it, fake a reply, or let a denial of a separate hint
abandon its result mutex. Permanent failure uses the existing checked fault
path. This model covers the request admission/lifetime protocol; it does not
newly prove that whole Scheme hint-routing algorithm.

## 6. Model, meaningful failures and decision boundary

`models/gambit/private_reservation_admission.qnt` couples private page ownership,
shared allocation counters, allocator generation, partial constructors, commit/
discard, concurrent request acquire/close/publication/producer release and queue
ownership. A valid lease survives close; accepted work cannot disappear when the
producer releases its lease. One scenario starts with an existing extra heap
section, so the proof does not assume assigned==2*processor_count. A two-epoch
abort/retry preserves VM debt and changes the slot incarnation.

Positive scenarios cover exact prefix discard then retry, old-GC resumption,
native cleanup failure isolated from GC, postcommit cancellation explicitly
refused while accepted work drains, capacity refusal, held-publisher retention,
and nontrivial prior allocation accounting. Safety negatives include eager
counter mutation, blind postcommit rewind, GC during private construction,
staged/stale lease, check-then-pin, lost accepted node, early free, native carrier
drop, debt reset, live-page borrowing, unleased publication, retained-slot reuse
and releasing a claim before its pstate views. Temporal controls distinguish
unnecessary waiting for native cleanup before old GC from the genuine inability
to reach quiescence if an external producer never releases its lease.

The initial postcommit-cancel property incorrectly demanded eventual retained
fault even when normal draining completed first. Its counterexample showed a
fully drained committed state with unchanged allocation, not memory unsafety.
The corrected protocol explicitly records TOO_LATE and requires normal accepted
work to drain; all new-model controls are rerun against that source. The old
failed receipt is retained, not relabeled.

Independent decision: for the default allocator and enforced checked-entry
contract, these two *design* holes have a concrete closure: no precommit global
mutation to reverse, and no accepted publisher outside the slot-lifetime protocol.
This is not another request to invent a better error-recovery path. Next work
is implementing this exact function split and API migration, then matching the
model with source-bound native fault/concurrency receipts. No model proves
unmigrated raw-pointer clients safe, arbitrary custom allocators transactional,
or the full9/12 gate satisfied. Those are explicit unsupported contracts or
separate runtime verification, not success inferred from a boolean model.

Verification:23/23 expected controls accepted:7 safety/conditional-progress
scenarios,14 decoded invariant counterexamples,2 temporal loop/stutter
counterexamples. Every executed case remained below the original30-second cap.
Final receipt: `.cache/tasks/repair-9-12/processes/audit/runs/14e8c2d84b1443988aec06e48de05c7b/outputs/private-reservation-admission-model/receipt.json`. Prior failed property and raw
trace retained under audit cca8c8b11ed342dbac74ea776f8f00a5. No native execution.
