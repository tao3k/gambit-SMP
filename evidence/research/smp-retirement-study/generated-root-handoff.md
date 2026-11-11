# P0 READY generated roots, native tails and lock publication

This supersedes the lock nesting suggestion in `setup-ticket-propagation.md`.
It is evidence and implementation guidance, not applied runtime code. The same
`models/gambit/integrated_growth.qnt` now includes the generated-boundary
obligations. Native admission and formal 9/12 remain false/unchanged.

## Source identity and evidence boundary

All line references below use immutable per-file copies under
`.cache/tasks/repair-9-12/processes/audit/runs/bad1e9aa8d7d47e2a1304a6225f6f2ae/outputs/integrated-growth-source-observation/observed/`.
The accompanying receipt binds each saved file. This does not certify a coherent
compiler generation or link these files to the mutable producer's current GSI.
The proposed READY helper is absent from these generated C bytes. No new Scheme
compilation, native harness or GSI execution was performed for this report.

## Existing C/Scheme boundary and actual root map

| Concrete saved site | What the bytes establish | Implementation consequence |
|---|---|---|
| `_thread.c:22193` startup function declaration | Its `___PD_ALL`, `___PR_ALL`, `___PW_ALL` name heap, fp, r0..r4. These are macro definitions, not executed spill/reload instructions. | Finding PW_ALL in a function is insufficient to prove an inserted C call publishes registers. |
| `_thread.c:22225` VM unlock and `22252` processor unlock | Startup releases the primitive VM/P locks before allocating/initializing primordial state. | Keep READY at the existing unlocked tail; do not move it into native collective service or hold T/P across it. |
| `_thread.c:22275` stores primordial into current processor and global root | Actual generated stores establish roots before the tail, not just Scheme local names. | READY checks existing initialized typed roots; it does not copy them into a raw native context. |
| `_thread.c:22308–22314` L9→fault-control call→L10 | R0 is set to L10 before calling `##fault-control-make!`; current L10 returns VOID, adjusts fp by -4, and returns through stack slot1. | Proposed checked helper must be inserted by Scheme regeneration before that return. There is currently no READY call here. |
| `_thread.c:31116–31127` startup descriptors | One RETI descriptor has cfs4/link0/map0x3f1; the subsequent RETN descriptors have fs1/link0/map0x1, including the return after fault-control. | This is the existing compiler frame shape. It does not describe a newly inserted allocation, raw C local carrier or new continuation. Do not hand-copy map0x1 after changing liveness. |
| `_thread.c:31044–31050` fault-control descriptors | The allocation path has RETI cfs8/map0x3f03 and normal return maps. | Root creation already has compiler-managed allocation points; the new native publication need not allocate to duplicate that work. |
| `_thread.c:21398–21401` fault-control root stores | Pins the control thread to processor0, puts it in record slot0, then stores the record from stack slot-6 into VM structure field2. | This existing VM field is the durable Scheme root; do not replace it with a native ticket pointer. |
| `gambit.h.in:9299–9333` descriptor decoding; `mem.c:4197–4275` mark_frame | RETN/RETI decoding supplies fs/link/map; mark_frame scans marked stack words through mark_array. RETI cfs expansion depends on frame/register conventions. | A bitmap is interpreted with its actual frame kind/size/RA; it is not a generic list of all C locals or all registers. |
| `gambit.h.in:7004–7105`, `6816–6817` | W_FP writes local fp to pstate; W_Rn/R_Rn copy cached GVM registers when enabled; W_ALL/R_ALL expand the selected host/procedure set. | Writeback and reload are real operations only where expanded/executed. They do not manufacture a valid return-address/map or root arbitrary native variables. |
| `gambit.h.in:10339–10340`, `10377–10383` | The existing CFUN context saves R0 in its frame, performs W_ALL, invokes C, and performs R_ALL; OOL calls use the same context veneer. | Prefer a compiler-generated, scalar/no-Scheme-pointer CFUN veneer if a full context is needed. Inspect its actual generated caller, continuation and descriptors after regeneration. |
| `_kernel.c:22903–22935` no-cleanup exit bridge | It declares a wide register set, but directly calls `___propagate_error(ARG1=R1)` without an explicit W_ALL/R_ALL at this site. | This is a nonallocating scalar throw bridge, not proof that an arbitrary added GC/reentrant helper is safe. Do not extend its behavior silently. |
| `setup.c:1318–1332`, `4019–4050` | propagate_error forwards a non-NO_ERR fixnum to throw_error/THROW; original run catches and finalizes its live marker after END_TRY. | Return status from the READY helper only after native locks/entry borrows are released, then propagate the exact negative fixnum through the supported bridge. |

Recommended helper contract: scalar result, no movable SCMOBJ arguments or
returned Scheme object; no allocation, GC, callback, scheduler/collective entry,
Scheme exception raising or nonlocal escape while inside native publication.
It may inspect established VM roots only while its owner/VM/context is pinned
and same-VM GC cannot run without this processor's participation. Keep any
ordinary same-VM GC at compiler-owned Scheme safepoints before/after the call.

For the new source call, generate the normal CFUN call veneer or an explicitly
reviewed W_ALL/R_ALL no-GC inline veneer. The latter does not become a GC point.
If later requirements add GC to this helper, stop and redesign it around a real
compiler return frame and explicit GC_SAVE/RESTORE for every C-local movable
value; W_ALL alone is not that redesign. `gambit.h.in:8073–8099` saves in pstate
`saved[]`, restores updated values and clears those slots. Those slots are not
an unbounded reentrant root stack: nested helpers must not overwrite an outer
save set. This proposal avoids borrowing them for the new scalar helper.

A registry/VM lifetime borrow prevents destruction; it does not freeze movable
Scheme objects. A foreign native entry still cannot keep an untracked SCMOBJ
address across GC merely because it holds that borrow or request lease. Use
existing scanned/RC/still carrier protocols for payloads, and reread updated
Scheme references after GC. This helper's P0-only, non-GC scope avoids adding a
new foreign movable-reference window; lifetime protection and relocation
coverage are separate invariants.

The existing marker allocation already uses GC_SAVE1(proc)/GC_RESTORE1(proc),
then stores proc in a refcounted still vector. Preserve that route. A native
setup record stores native identities and scalar status, never a cached Scheme
procedure or coordinator pointer. The generated stores into VM/global roots
remain the authoritative Scheme references. A stable marker address does not
make every Scheme object referenced from it immovable.

## Checked failure order and last consumers

READY's original-scope authentication remains one-shot. Separate native READY
and OPEN status from resource initialization bits and native borrow counts.
On failure, do not invoke exit jobs/coordinator routing in partial bootstrap,
convert the negative fixnum to a positive program status, or throw while a
native mutex/entry borrow is held. Finish the native helper, unlock/release,
reload compiler registers, then call the existing scalar no-cleanup error bridge.
An optional test allocation between failure result and bridge must be a real
Scheme safepoint with the regenerated frame map, never a C malloc/GC callback
inside the publication helper.

| Consumer | Concrete end point | What zero/completion does **not** authorize |
|---|---|---|
| Scheme marker's external still reference | `retire_marker_entry`, `c_intf.c:6520`: invalidate field0, decrement still refcount, publish marker count decrement, free native entry | Does not end the original run's C tail, outer setup owner, a worker's OS cleanup or its join obligation. |
| Optional setup-context marker reader | Proposed common marker retirement, exactly once for matched owner | Release only after its last context/VM access in that retirement path; keep the independent outer owner/VM record pin. Nested ordinary markers carry no setup authority. |
| Original P0 run C entry | `___run` calls kill after END_TRY and returns its scalar error | Any remaining P0 C-tail VM accesses need the outer setup-owner pin. Marker count0 alone is not an external cleanup grant. |
| Outer setup owner | Its authorized original-return/partial-prefix cleanup epilogue; final disposition published after last VM access | Another caller cannot steal RETURNING or destroy its record because marker-reader0. After dropping owner authority, return using scalar locals only. |
| Worker native tail | `setup.c:1428` retires markers, then `1429` calls cleanup_os_pstate, then `1430` thread_exit | The marker count can already be0 while native code still reads VM/pstate. Preserve slot/VM ownership through real same-owner join0. |
| Marker retire-all diagnostics | `c_intf.c:6532–6544` still reads VM wake_fault_errno and processor identity after the loop | Moving a context/VM free immediately after its last marker decrement would race these accesses. Join/worker owner pin must cover them. |
| Checked request's native entry | From registry validation through the **last** slot/procedural/VM access and return-value copy | Dropping its producer count earlier does not end this native read-side lifetime. |
| Accepted async request | Queue node, selected handler, wake obligation and any VM/root borrow all finish | Function return or producer0 cannot erase an already accepted delivery obligation. |
| Fault/retirement coordinator and pending donor | Actual terminal coordination, reader grace and applicable join/finalize protocol | No completion is inferred from a cleanup call returning NO_ERR on setup_state!=1. Retain failures and roots. |

`___run:4030` uses `volatile live_marker`, assigns it after successful marker
creation and tests that value after END_TRY. Reuse that finalization witness.
Put optional context-borrow ownership in the persistent native marker entry and
record; use an opaque native record reference plus scalar nonce/scope kind and
shared private C release/accessor declarations. Keep the Scheme marker vector's
existing layout. Never store a raw context pointer in one of its scanned Scheme
slots or disguise that address as an ordinary SCMOBJ. Ordinary SFUN entries
initialize the optional native reference to NULL and carry no setup right; do not add a normal stack-local acquired flag modified inside TRY and
then relied on after a nonlocal jump. A failed marker/context association must
leave one durable, exactly-once release responsibility or unwind it immediately
before returning; stale/foreign kills still cannot decrement another owner.

Implementation should make these references explicit and distinguish them.
The QNT `contextReader` models the marker reader; new `tailLive` models the
remaining native tail/owner use. It is not a proposal to drop actual outer-owner
ownership at every marker decrement, nor proof that one new counter replaces
existing join/queue/wake/grace witnesses.

## Release/acquire and destroyable-resource lifetime

The saved configured `include/gambit.h` has a default
`___MAX_LOCAL_GVM_REGS` of25 under an ifndef at7011, and SINGLE/MULTIPLE host
selection is conditional. Compiler command-line defines can override it. A
textual occurrence of a macro in either header does not identify the final
preprocessed branch; obtain the final compile flags/preprocessed veneer during
native acceptance.

The observed request slot mutex is not destroyed by
`cleanup_interrupt_resources_pstate:835`; its `ready` flag is not reset there.
The routine closes admission, reads producer state and destroys the pstate's
**procedural** interrupt mutex. Do not misreport a proven request-slot mutex
use-after-destroy. Keep request-slot mutex storage process-lived where practical,
initialize it under the static guard/once discipline, and publish initialization
with synchronization. The current plain ready/key/producer reads outside their
owner lock are not a new memory-order proof. `request_lease_current` also reads
identity/counter fields without taking the slot mutex; a held lease proves
lifetime only if its implementation actually pins that lifetime, not race-free
access to concurrently modified fields.

For stable registered instance/slot descriptors, use a checked native-entry
borrow to protect the record, VM and destroyable native-resource generation.
This revises the previous suggestion to nest entry guard→slot mutex:

1. Lock the process-lifetime entry guard. Validate registration, requested
   incarnation/nonce, allowed entry kind/phase and initialized resource mask.
   Reject arbitrary VM/pstate pointers **before** dereference/slot arithmetic.
   Increment `native_entry_users`, pin record/VM and copy only stable native
   handles. Unlock guard (release). Do not transfer an old owner's ticket.
2. Lock the already initialized slot mutex (acquire), revalidate exact key and
   phase, and atomically accept/pin the request or reject it. All identity,
   producer and phase authority is read under this mutex. Previously granted
   accepted requests retain their distinct queue/handler/wake obligations.
3. Unlock slot (release). Do remaining native work with the record/VM lifetime
   borrow and applicable per-request ownership. Any procedural lock follows its
   own existing queue order; never call Scheme/GC/cohort work while holding
   either native lock. Copy outputs before releasing the last native-entry pin.
4. After all slot/procedural/VM accesses, lock entry guard, decrement the entry
   borrow, publish any terminal metadata, unlock guard (release), then return
   using native/scalar locals. No guard and slot mutex are held simultaneously.
   Internal release of an accepted lease must remain allowed while fresh
   admission is closed; gate closing cannot prevent consumers from draining.

OPEN publication: owner/native-resource pin remains held; validate and write
slot key/payload/READY+OPEN under the slot mutex, unlock it, then publish matching
registry admission under the entry guard and unlock it. A new observer first
locks guard (acquire) and takes its entry borrow, then locks slot (acquire) and
rechecks key/phase. It cannot accept a registry hint as the payload itself.
The second release/acquire pair protects the slot tuple even if a hint was read
incorrectly elsewhere. The QNT order checks this protocol causality, not a C11
axiomatic weak-memory execution.

Close/cleanup order: under entry guard stop **fresh** entry grants and reserve
one cleanup owner; release it. Mark slot DRAINING under slot lock, release it.
A prior entry can accept only before that slot-close linearization; close cannot
revoke an already accepted obligation. Without holding either mutex, wait via
the existing bounded/progress mechanism for entry users, accepted consumers,
marker/native-tail/outer-owner uses and the relevant worker join/grace. On any
failure retain the record, keys, roots and resources. After genuine quiescence,
reserve FINALIZING under guard; no new users can enter. Release guard, perform
fallible destruction of only successfully initialized, destroyable resources,
then reenter guard to publish CLEAN or RETAINED. No callback runs under guard.
Request-slot mutex may stay process-lived; its closed generation view is still
invalidated and cannot be used as authority for the next VM incarnation.

Only CLEAN plus all independent consumers allows a new nonwrapping incarnation
and invocation nonce under guard. Publish the new key CLOSED before fresh READY
and OPEN. Record/VM pin release/acquire and worker join ordering are mandatory;
`volatile`, a plain ready bit, producer0 or a standalone CPU fence cannot replace
these lifetimes. Failed lock acquisition/destruction is not a successful state
transition. If slot lock acquisition fails after registry borrow, no slot
ownership was acquired: record the error and return the borrow only through a
successful guarded release. If guard reacquisition also fails, retain that
borrow/fault responsibility; never decrement unprotected memory to claim clean.
If slot unlock fails, ownership/release is uncertain: do not publish registry
OPEN or throw into Scheme while pretending no native lock is held. Retain the
fault, resources and owner; an implementation needs a separate safe fault/
fail-stop disposition before claiming resumable completion. Correct POSIX owner
unlock is expected to succeed; arbitrary mutex corruption is outside the
progress proof. The model's release actions assume a successful native release,
while its publication-before-release negative rejects bypassing that condition. Reject exhaustion or broken synchronization; do not reset a live
mutex or invent a completed cleanup.

A bare mutex or release store does not guarantee bounded service under arbitrary
OS scheduling. The guard must never wait for join, a VM collective or callback
completion; mutex fairness and timely scheduling remain native progress
assumptions. If high-rate native admission starves cleanup, a drain/owner turn
must close fresh grants under guard rather than merely hope for a quiet gap.

Cost: a conservative external acquire now needs two short entry-guard critical
sections plus its slot lock, and a borrow counter/reference. This supersedes the
prior one-slot-lock-only cost claim. It can contend under high-rate foreign
publication; measure it on the same final producer before optimizing. Existing
accepted queue nodes need not copy or allocate a new Scheme carrier. A later
stable-handle/RCU optimization would need its own lifetime proof and is not a
prerequisite for this correctness path. Scheme scheduling/GC callbacks remain
outside the locks; no unbounded blocking wait is permitted under guard.

## Correction to the prior 69-case model

The immutable69-case model's bootReturn reset the entire ticket/context group,
including recordLive, rather than only retiring its marker reader. The earlier
invariants did not require remaining boot roots/resources to retain that record,
so the positive OPEN-failure case could pass while forgetting responsibility.
This is a defect in that model, not an observed runtime change or new native
fault. Keep the measured69-case receipt, but withdraw its sufficiency for this
failure-return ownership claim.

The corrected bootReturn changes only pending-return, scope/reader and stage;
record identity, resource mask, roots, native tail and scenario selectors stay.
New invariants require recordLive while bootRoots or bootRes remain. A dedicated
initEraseObligationsOnReturn negative erases record/tail together and must now
produce a distinguishing counterexample. Checking scenario-selector immutability
caught this unintended reset; it is also an explicit code-generation guard
against broad record resets during an error return.

## Unified QNT and native implementation checklist

The canonical model retains flat protocol fields. Several representation-only
attempts hit the backend's unchanged20MB JSON-string cap before state checking;
their failed receipts are retained. Grouping state did not solve that limit and
was not adopted. The final verifier emits a per-case compiler input by removing
only unreferenced alternative initializer declarations and specializing the
four injected-fault action groups on the selected initializer's immutable `bug`.
It asserts each initializer has no references elsewhere, checks that bug is only
declared/initialized, retains the selected initializer and matching injected
fault, and records canonical/compiled hashes plus each disabled false guard.
All invariants and fairness remain unchanged by this compilation step. The
final compiler input also replaces reads of mode/bootMode/ticketMode/mapMode
with their selected constructor constants, after checking that no protocol
action assigns them or reenters a constructor. Their values remain in state;
only those immutable reads are specialized. Every per-case proof records the
constants, guards and byte hashes. This check exposed the old bootReturn reset
before it was corrected. Normal transition effects and native/test limits are
not weakened. A bug0 run
cannot reach an injected bug40 action before or after this transformation.
The ordinary step still references those action groups; an empty group becomes
an explicitly disabled state action. This is source-checked dead-branch removal,
not a smaller replacement protocol or permission to erase reachable failures.
It models a valid
compiler landing, executed spill, two abstract moving-GC updates and reload,
non-GC native helper, slot release followed by registry release/acquire,
normal helper return before scalar throw, and a native tail after marker-reader0.
The publication observer may run before or after the native helper returns;
helper return has no observer precondition. The old bootGc action is also disabled while nativeBridge is true, so both abstract ownership GC and relocation GC obey the same non-GC boundary. The tail-failure positive forces
observation after helper return. External request progress still assumes the
harness supplies its request actor, but the helper does not wait for that actor.
It composes with every earlier bootstrap/ticket/growth/queue/debt scenario.

Four positives exercise mapped READY with two GC updates, checked OPEN failure
with two updates, failure retention while the native tail remains live, and
teardown→new incarnation with renewed publication. Eleven negatives expose:
declared-but-not-executed spill; spill without frame map; GC inside the non-GC
helper; use before reload; registry publication before slot release; observation
without matching acquire/release; destroyable-resource invalidation with a live
entry borrow; dropping VM pin after marker0 but before native-tail end; throwing
while native entry ownership is held; renewal while native tail remains live; and erasing record/tail obligations together on failed return.
The negative for mutex lifetime is a protocol counterfactual, not a claim that
the current request-slot mutex is actually destroyed.

`lockAlive` represents the valid per-incarnation native-resource view, not a
literal proof that request_slots.mut storage is destroyed. `registryAcquire`
models an acquire-guard observer before its subsequent real slot validation;
`slotPayload` abstracts the exact key tuple. On checked OPEN failure,
`registryRelease` publishes an error/CLOSED diagnostic disposition, not OPEN;
existing bootOpen/bootGranted fields still deny admission. Reading that status
is distinct from acquiring a valid request lease. These variables do not simulate
POSIX internals or prove every native entry has been migrated. The prior bootstrap resource1 now has to be read as a per-incarnation admission
resource/view, not an instruction to destroy and reinitialize a process-lived
slot mutex. The implementation must distinguish process-once lock initialization
from generation cleanup; the finite reverse-prefix flags alone do not prove it.
Root versions0,1,2
are relocation tokens, not real object addresses. No result proves generated C
for an absent helper, arbitrary nested save-stack safety, callback termination,
all host-pointer validity or the full cold startup topology.

Grok should implement/review in this order:

1. Persistent static guard/registry and independent outer owner, marker reader
   and native-entry references; preserve current worker join ownership.
2. Migrate raw ready/key/producer checks and legacy unchecked entry paths to
   checked registration/borrow plus locked exact-key validation. Audit every
   native return/exception path for borrow release after its last VM access.
3. P0 scalar/no-GC READY/OPEN helper at the post-fault-control tail. Release all
   locks and temporary native-entry borrows before returning its status. Keep
   original setup/marker authority across the entire call, not just OPEN.
4. Regenerate `_thread.c`/related generated units using the actual producer's
   compiler/configuration. Inspect the executed CFUN or explicit spill/reload
   veneer, current R0/fp and new RETN/RETI descriptors; preserve parent return
   slot and module-init continuation. Do not patch old C map constants by hand.
5. Verify no-GC status throw through existing no-cleanup bridge, original
   `___call` catch/rethrow, original `___run` END_TRY finalizer and private
   partial-prefix unwind. Preserve first status separately from cleanup fault.
6. Inject a real Scheme moving GC before helper and between checked failure
   result and supported error bridge at valid generated safepoints; exercise
   r0/fp/register caching configurations. Demonstrate carrier roots survive and
   post-GC references are reloaded; refuse a helper that allocates/reenters.
7. Barrier-test an admitted native entry held between registry and slot; close
   admission, attempt cleanup, and show retention until that entry and accepted
   queue/wake/handler consumers leave. Test rejection and late release too.
8. Hold the native tail after marker0; P0 owner or worker join still blocks
   cleanup/renewal. Match final consumer release/acquire and same-owner join0
   before moving memory. Negative destruction/renewal must be refused, not
   reported as OS join errno. Retry only authorized retained cleanup.
9. Bind one final producer's exact source, generated C, compile/link configuration
   and executable hash; run focused controls under original limits. Historical
   model/39 checks, old GSI or a link workaround cannot supply this acceptance.

The finite protocol is stronger than the previous ticket graph: a stable marker
alone is no longer treated as proof of a correct generated boundary, and marker0
is no longer the end of every native reader. It remains conditional on the real
C implementation, generated-code audit, aggregate last-consumer completeness
and native tests. Formal lifecycle gate review, interrupt delivery, GC/FFI,
Gerbil and performance remain separate; native count stays8/12 unless actual
accepted evidence independently changes it.


## Executed verification

Final84/84 expected controls completed:32 safety/conditional-progress positives,
49 decoded distinguishing invariant counterexamples,3 temporal loop/stutter
negatives. All69 prior scenarios reran with this model's root/native-tail
prefix. Original30s/case cap unchanged; maximum observed duration
23.334s. Receipt:`.cache/tasks/repair-9-12/processes/audit/runs/1b0f52afa2a545799b249c516b38b664/outputs/integrated-growth-model/receipt.json`.
Exact canonical model SHA256:`e1c7a2b005d650477fead17bf4cc944654eb57d642811ad3d20751048a3d50b5`. Every case records canonical and
compiled input hashes, disabled immutable-bug guards and unused initializer
erasure; the handoff audit reconstructed all84 projections and compared bytes.

Four failed compile batches are retained at audits
7202474268b94c17951d31e5f7c0abf6, dfd99484b2ad4f8e8dc0b96a4dccd283, 08642ed35aa64e859a5d42b89bb24538, 33baef93f535440fb821e42cc63b70a5. They hit20MB JSON-string input limits before TLC checking,
not protocol counterexamples. One superseded partial batch also recorded a real30-second initAbortRetry timeout; it remains a failed bounded attempt, not a protocol counterexample or a final pass. The first compile batch was deliberately interrupted by its own
verifier owner after repeated identical compile failures; it was reconciled
through the existing audit resume API. No peer was signaled or operated. A separate partial model run9b564deaac7d46199698f06e5e066f44 was stopped to remove helper-return dependence on an external observer; final controls reran with both observation orders.

Read-only qualification:`{"admitted": false, "count": "8/12", "closed": null, "runsOk": false}`. New model evidence does not
change native contracts or admission. No runtime changes, native/GSI/full-suite
execution, other-thread operation, commit or push occurred.

Reproduction from the SMP checkout:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-integrated-growth.py
```
