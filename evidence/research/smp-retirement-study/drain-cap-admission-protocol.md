# Drain admission: atomic counted entry and scheduler-lock-held sync service

Evidence-only research against the new drain-before-GO lock: main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, lock SHA256 `c5b2e0bd4db5b8b99dee274d3d5cfbdec8df387eb7ca9d4df4b6d971a3b8686d`, patch SHA256 `3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7`. Source receipt/candidate are bound in the companion JSON and audit a9fe653a2e1b44c6ab2f0a6f5da03d15. Vendor HEAD is a separate project. New names below are proposed interfaces, not implemented runtime symbols. No runtime/qualifier/history changes, native build/campaign, other-thread action, commit or push. Recorded qualification remains8/12.

## Independent refinement

The atomic entry must first establish **lifetime and exclusion**, then establish **authority**. A successful CAS on a repeated OPEN/count word does not authenticate a historical operation. Acquire a short-lived counted lookup grant under an already-valid VM borrow, read the now-stable current key/index/manifest, validate the full capability and allowed unconsumed phase, then enter the channel. A stale or forged capability drops the grant before any mailbox mutation.

Keep the short-lived lookup/communication/ACK-writer count separate from persistent operation registration and completion-reader references. SEALED waits for the former to reach zero; a member waiting for GO retains the latter without keeping the gate count nonzero. Drop is always legal in closed modes. Never reset the count to zero while changing mode.

The actual scheduler helper can service sync with a thread lock held. A blocking new control mutex on this route is not an acceptable default. The proposed atomic fast path performs no Scheme allocation, callback, blocking control-lock acquisition or user-thread yield. That does not mean the collective itself never waits: it retains the existing native participation semantics needed for peers to release scheduler locks.

## Concrete C/Scheme call chains and edits

| Candidate source | Actual path | Grok implementation responsibility |
| --- | --- | --- |
| `_thread.scm:3315..3337 ##thread-migrate-to!` | Locks current thread, saves it, resolves destination, then calls lock-processor-with-sync-participation! before clearing donor current-thread root or moving the queue. | Preserve this order and root. Do not unlock the migrating thread casually or clear current-thread before service. Carry accepted native member/transition authority outside Scheme heap pointers. A no-T/P-lock assumption cannot be applied to this caller. |
| `_thread.scm:690..704 ##lock-scheduler-object-with-sync-participation!` and wrapper lock-processor-with-sync-participation! | Trylock retry; when INTR_SYNC_OP is set, enters ##sync-op-interrupt!; no ordinary callback dispatch. | Change the predicate to a new nonblocking `cohort_service_needed(ps)` checking a persistent atomic service obligation as well as the interrupt hint. The predicate is a hint only; authority is checked in C entry. A cleared/coalesced hint must not hide an already-issued drain obligation. Never read resettable manifest pointers without protection just to poll. |
| `_kernel.scm:1468 ##sync-op-interrupt!`; archived `_kernel.c:12362..12396` | Stores RA, executes W_ALL, calls service_sync_op, then R_ALL/fetch RA and normal Scheme return. | Keep actual saves/maps around the native call. service_sync_op obtains an admitted context; it must not allocate a new Scheme capability or throw into a scheduler-lock-held caller. Return/retain/defer through a reviewed native disposition; diagnose invalid accepted internal authority at a safe shared fault boundary. New generated C for the changed poll/context is not present in this evidence. |
| `setup.c:1931 on_all_processors` | Raises VM sync interrupt, then enters execute_sync_op_loop with a caller-owned sop. | Register/count the ordinary operation and its rooted arguments/status before publishing the wake. If CLOSING prevents a new ordinary election, preserve its pending request and join the already-issued drain; re-propose it on stable OPEN. Do not return success with an unexecuted operation or lose a stack-owned result/GC debt. |
| `setup.c:1916 service_sync_op` | Creates OP_NOOP and enters outer loop. | Resolve the registered per-member service obligation. In CLOSING, route to the prescribed drain phase under a full capability; do not send an ordinary NOOP election into peers' drain barrier. In SEALED, a previously admitted member waits via its stable completion reference, not a new communication pin. |
| `setup.c:1786 execute_sync_op_loop`,1690 sync_owner_phase,1757 ack_service_window | Shared engine has fixed owner phases, phase/epoch payload and native/ Scheme callers. | Add explicit operation/transition contexts and allowed phase routing; registration precedes CLOSING. Fully converge old operation/native tails before ACK. No callback or new allocation after the sealed prepare boundary. Nested resize/startup/GC needs a classified context/debt path, not a blanket DRAIN exemption. |
| `setup.c:794..804 barrier_sync_op` | Reads index, increments channel pins, rechecks index, marks member tail. | Replace with `cohort_try_enter(ps,op_cap,phase,&grant)`: count-CAS first, acquire-read current metadata, validate VM/owner/transition/round/phase/use state, then increment/use the fixed channel under that grant. On mismatch release the grant without channel mutation. The existing double index load is not this authority check. |
| `998 ___cohort_record_result_ack`;1012 ___cohort_publish_go | Definition-only ACK1 and scan/store GO helpers. | ACK publication needs a validated writer grant and one-shot EMPTY→WRITING→READY slot; payload before release READY. Seal closes new writer/communication admission while preserving outstanding count; acquire-zero must include ACK writer native tails. GO publication requires the sealed token/full result, and reopening requires initialized stable metadata plus common resume. |

Exact line coordinates remain tied to this candidate; the JSON also lists source symbols for replay. No other producer or generated module is silently treated as equivalent.

## Proposed entry protocol and state word

New native context fields: `{VM incarnation,native owner/member incarnation,cohort epoch,operation nonce,transition generation,round,allowed phase,phase-use claim}`. An accepted operation/member registration holds a stable record reference under the VM lifetime ledger. Scheme cannot mint it by passing role=DRAIN, setting TLS, holding a lock, or observing INTR_SYNC_OP.

The gate word contains mode plus a bounded short-lived user count. Gate modes are OPEN, CLOSING, SEALED and PUBLISHING; field layout/overflow refusal must be specified for each target ABI. Current inline VM storage is protected by a valid VM borrow before its atomic word is touched. Temporary grant acquisition is:

```
cohort_try_enter(vm_borrow, expected_cap, requested_phase):
  snapshot atomic mode/count
  CAS(acq_rel): if mode permits this class, increment short count preserving mode
  acquire-read immutable current epoch/index/manifest while count protects rotation
  validate full expected key + member + allowed phase + unconsumed one-shot claim
  mismatch -> release short count, reject without mailbox access
  match -> bind grant to this channel/phase; keep count through actual native tail
```

An entry linearized while OPEN can finish its already accepted old operation after CLOSING. New ordinary admission after CLOSING is deferred; an accepted, unconsumed transition phase can still enter there. SEALED rejects both. CLOSING/SEALED transitions use CAS preserving count, never a store that erases concurrent references. After count reaches zero in SEALED, stable key/index/ACK storage can change and a later OPEN release publishes them.

A thread can read OPEN/count0, be descheduled across a complete transition, then successfully CAS a new OPEN/count0. The new lookup pin protects current storage, but its historical key must still fail post-pin validation. Reading/caching the index/key before the pin and reusing it defeats the protocol. Mode-bit equality and full capability identity are different checks.

Use bounded native CAS retries with a native RETRY outcome if necessary; no blocking control mutex under retained scheduler locks. RETRY does not mean drop accepted collective debt or return an unexecuted operation. Any blocking leader-side allocation/control setup occurs before close at a no-T/P-lock boundary, or through a separately proved scheduler landing. The model treats CAS as atomic/fair; it establishes no hardware contention-time bound.

## Issuing registered drain authority

1. The initiating on_all_processors operation has a counted record/full key before its wake. The stable old-cohort transition manifest pre-issues a native member capability for each required participant, with exact permitted drain phases and member incarnation.
2. Release-publish the initialized manifest and persistent per-member service-needed flag before announcing CLOSING/raising the interrupt. A poll may read that atomic flag without resolving resettable pointers. It cannot authorize entry itself.
3. service_sync_op takes its pre-issued capability under the counted lookup protocol. It validates exact epoch/round/transition and claims a permitted phase once. Ordinary work arriving late stays pending while the member serves that drain; a status bit or plain role enum is not a capability.
4. sync_owner_phase uses the same admitted old-cohort grant for its actual phase; two owner phases have distinct use claims. After final drain/result ACK, that registration cannot start another old communication round. Fresh nested work becomes persistent debt for a stable reopened cohort.
5. If resource preparation requires GC, do it before SEALED while the old cohort is still serviceable. Preallocate immutable records/slots or fail preparation safely. Do not allocate under SEALED and then request a GC that requires the sealed entry you just disabled.
6. A stale/unaccepted external request may reject before mutation. A supposedly current internal participant with an invalid capability is a protocol/fault case: preserve its roots/debt and enter the common reviewed failure disposition. Silently skipping participation or fabricating ACK would hang or corrupt its peers.

## Count and lifetime table

| Unit | Included in zero-gate count? | Last use / release |
| --- | --- | --- |
| Valid VM borrow / old member registration | No; separate stable ledger ownership | Keeps VM/control/pstate alive across close/wait; release only through its accepted ownership protocol. |
| Lookup grant | Yes | Covers current-key/index/manifest validation before any channel dereference; mismatch drops it without writes. |
| Communication grant | Yes; transfer lookup count rather than double-count accidentally | Covers all payload/wait/unlock/signal/forwarding access. State/count drop happens after actual native tail. |
| ACK publication grant | Yes | Covers slot claim, payload, release READY and post-store native access. Leader seeing READY does not mean grant is gone. |
| Completion-record reader | No | Wait/acquire GO or ABORT, publish resume, finish remaining native access, then release its own pin. Never consume it just because zero communication was observed. |
| Parent root carrier/native job | No | Unchanged by this mailbox protocol; actual ROOT_INSTALLED_ACK and owner reclaim remain separate. |

After READY, seal may succeed with writer count nonzero. It prevents new writers, but the existing writer must always be able to put. Zero scan waits until all such grants end. A record is never reset while an old writer or completion reader can still access it.

## Closing, ACK and reopening happens-before chain

- Successful entry CAS acq_rel grants counted protection before stable metadata reads. Current metadata was initialized before the OPEN release that this acquisition observes. Full-key validation follows acquisition; a raw lookup is not protected retroactively.
- OPEN→CLOSING and CLOSING→SEALED acq_rel updates preserve every user count. The sealed zero predicate acquire-observes prior release/acq_rel drops; an entrant cannot insert a new counted grant after seal.
- ACK claimant owns EMPTY→WRITING; initialize full key/result payload, then release READY. Leader acquire READY before reading fields. Duplicate/stale writer fails before rewriting READY. A deliberately weakened READY-before-payload negative is an ordering violation, not an actual weak-memory C trace.
- The writer's post-store tail finishes before its counted put. Only after sealed zero may reset/reuse write that storage. Publishing ACK and releasing its writer grant are separate operations.
- Initialize stable successor epoch/index/domains/result and resume state while SEALED/PUBLISHING. Release-publish tagged GO/ABORT; old members acquire-observe the exact disposition via their completion references and publish resume acknowledgments. Reopen ordinary admission by release only after the agreed common resume predicate.
- New OPEN entry acquires initialized new metadata, validates a new full key and rejects historical capabilities. Closed-mode DROP paths never wait for OPEN; GO wait references never prevent zero communication.

Actual C field widths, CAS code, registry lifetime, compiler root maps and complete caller lock-order proof are still required. This ordering argument does not replace a C11 implementation/refinement or native test.

## Grok implementation and native validation order

1. Define native registration/grant structures, atomic mode/count width and overflow refusal. Separate persistent VM/member/job/completion ownership from short lookup/communication/writer counts. Keep current drain-before-GO policy.
2. Implement cohort_try_enter/cohort_put without blocking under T/P locks. Acquire count first, validate current full key/phase/member/use claim second. Close/seal CAS preserves count; current metadata rotates only at sealed zero. Add explicit status for unaccepted defer/reject versus accepted internal fault.
3. Publish persistent service obligations before wake in on_all_processors; teach service_sync_op/execute_sync_op_loop to route pre-issued old drains directly instead of creating an unqualified ordinary NOOP round. Update the Scheme trylock poll to consider service-needed independently of the interrupt hint; preserve donor current-thread root and scheduler ownership.
4. Thread counted contexts through sync_owner_phase/barrier_sync_op, and one-shot writer grants through ___cohort_record_result_ack. Change ___cohort_publish_go to require a sealed capability/full result; initialize new metadata and common resume before reopen. Preserve ordinary request/GC debt through close and ABORT.
5. Regenerate the changed Scheme/C under the exact configured compiler/header. Inspect executed W_ALL/R_ALL/RA handling, actual saved current-thread roots and generated return maps. Do not use archived C controls as proof of new helper liveness.
6. On one bound producer pause an OPEN lookup across close and across OPEN/count ABA; require old accepted operation completion or full-key rejection without channel writes. Pause an ACK after READY but before put; zero/reset must wait. Inject duplicate phase, stale owner/member and used/forged drain tokens; require correct fault/reject class.
7. Hold the migration thread lock while the destination lock owner needs collective service. Clear/coalesce the interrupt hint while keeping the registered obligation; require native participation, root coverage and eventual scheduler lock progress without new control-lock inversion, Scheme callback dispatch or unexecuted ordinary return.
8. Keep GO completion reference alive after communication zero and reopening. Verify it neither blocks GO nor frees prematurely. Inject READY-before-payload, count-reset, sealed-entry and reopen-before-init faults as negative controls. Existing watchdogs remain unchanged; unknown shared-state faults retain/terminate through reviewed policy, never a fake ACK.

Independent conclusion: this slice closes a conceptual ambiguity between an atomic pin and an authenticated drain, and grounds the no-new-lock condition in a real scheduler path. It still depends on actual C acquisition/drop code, nonforgeable registration/phase consumption, caller ownership/root maps, dynamic membership/nested service, common fault handling and same-producer native evidence. The finite model proves neither real T/P-lock ordering nor GC root scanning; heldT/threadRoot are explicit abstraction preconditions. The formal lifecycle9/12 gate remains independent.

Research replay command from the SMP root: `PYTHONPATH=src python3 evidence/research/smp-retirement-study/verify-drain-cap-admission.py`. It uses the existing registered audit role and30s per-case cap. It does not compile or qualify a runtime producer. The code/input snapshots and raw TLC logs, including warnings, remain under the bound audit receipt.

### Lock-free code-generation prerequisite

An `__atomic_compare_exchange_n` spelling does not by itself prove the entry is nonblocking: an unsupported width/alignment may call a locking runtime helper. Use a naturally aligned target-native word and require its lock-free property for the configured compiler/ABI (for example the compiler's always-lock-free check plus emitted instruction/object inspection). Do not pack a full generation and count into an unverified wide CAS merely to avoid post-pin validation. Keep the full key separate and immutable while short users are counted. If the required word is not lock-free, the scheduler-lock-held path needs a separately proven ownership/root landing; a hidden libatomic/control-mutex fallback is not an admitted solution.

The count capacity must cover all reserved participant lookup/communication/ACK-writer units and permitted nesting, with overflow refused before arithmetic carries into mode bits. An already accepted drain needs reserved capacity or a bounded native retry/service disposition; a failed increment cannot be treated as successful arrival. The QNT counter ranges come from its single-participant schedule and do not prove the production capacity bound or CAS timing.

## Recorded controls and proof boundary

Final `models/gambit/drain_cap_admission.qnt`,Quint0.33.0/TLC:26 expected controls, all matched.8 safety/weak-fairness conditional-progress cases,11 decoded safety negatives,3 decoded temporal lassos,4 distinct targets. Maximumcase8.507s, original30s per-case cap. Receipt:`.cache/tasks/repair-9-12/processes/audit/runs/43de368c0a8849388c829e4826670c9b/outputs/drain-cap-admission/receipt.json`. All projections reproduced byte-for-byte; independent Python checks decoded violations/targets and safe non-goal cycles.

Positive cases distinguish ordinary entry accepted before close, registered CLOSING drain, and rejection of stale/forged/late-ordinary/OPEN-word-ABA/wrong-step/already-used capabilities. A valid lookup pin is not authorization: the cached-key negative grants a generation1 capability against current generation2; phase and prior-use negatives independently bypass their checks. Others cover unpinned metadata read, READY before payload, lost live count, sealed entry after zero observation, reopen before initialized key and wrong ACK generation. Targets retain thread ownership/root while servicing, retain writer after READY, retain completion reference through OPEN with gatecount0, and reject historical identity after the mode word repeats.

Temporal controls remain memory-safe but fail progress when a newly introduced blocking coordinator mutex waits for the participant it prevents from entering, when a GO completion reference is included in zero-gate count, and when only the cleared interrupt hint is polled despite persistent registered work. These are conditional proposed-protocol counterexamples, not measured current-native deadlocks.

The single-participant/coordinator model abstracts CAS, counts, metadata, a valid VM lifetime and one phase attempt; heldT/threadRoot are explicit preconditions held invariant, not proof of C scheduler locking or GC maps. Wrong-step/spent inputs represent prior unauthorized use; arbitrary recursive/concurrent phase-claim histories are not exhausted. Positive progress of rejection is not whole-cohort progress. Production lock-free codegen, counter capacity, dynamic membership, real registration/storage lifetime, root scanning and native recovery remain open.

Initial audit a3b21e9a07f2426ea8e2c07765b782f1 is retained as a checker-projection failure: initializer filtering removed a normal action named initNew. Renaming it prepareNewKey corrected the projection; that failed run is excluded from final controls. Own normal audit reconciliation followed real quiescence, without manipulating the task/native lease. Native executions0; qualifier not run or changed.

Follow-up: [implementation closure contract](drain-sync-closure-contract.md) completes the direct Scheme entry inventory and adds target CAS compiler controls, nested roots/error handling and integrated native acceptance. Prior26 controls remain historical conditional evidence.
