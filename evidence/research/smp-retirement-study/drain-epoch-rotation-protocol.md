# Drain-before-GO: closing admission, resetting ACKs and reusing channels

This source-bound evidence-only continuation uses `cohort-ack-rc.lock.json`, lock SHA256 `c5b2e0bd4db5b8b99dee274d3d5cfbdec8df387eb7ca9d4df4b6d971a3b8686d`, main revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, cumulative patch SHA256 `3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7`. Coordinates below refer only to the candidate in audit `a9fe653a2e1b44c6ab2f0a6f5da03d15/outputs/cohort-drain-source-audit`. Vendor HEAD is unrelated source authority. No runtime, qualifier, historical receipts, production build, other thread, commit or push is changed. Recorded qualification remains8/12; native executions0.

## Independent decision

Keep **drain-before-GO**. Do not add overlapping old/new channel traffic to complete this patch. Its remaining prerequisite is a closed interval in which zero counts remain zero, plus generation-qualified ACK/result storage and an explicit re-open after GO/ABORT. A zero-counter scan, an index recheck or an ACK1 bit does not establish this interval.

Closing every barrier entry at once is also wrong: current ack_service_window calls sync_owner_phase twice, and those calls themselves enter barrier_sync_op. Distinguish an accepted operation/transition capability from a transient communication pin. Close new ordinary rounds first; permit the pre-registered old-cohort drain phases; seal those drain entries after every member is done; then wait for communication and ACK-writer pins to reach zero. GO waiters keep a separate completion-record reference and hold **no** communication pin.

Use a separate transition generation even if an ABORT keeps the same cohort epoch. Otherwise an old ACK from the failed attempt can authenticate the next attempt. Reusing the same physical channel index is safe only after sealed communication grace and complete initialization. Reusing ACK/GO storage additionally requires its writer and result-reader grace; those are different consumers.

## Actual source audit

| Candidate site | Confirmed implementation | Missing condition / concrete change |
| --- | --- | --- |
| `setup.c:794..800 barrier_sync_op` | Acquire-load index, acq_rel-increment selected channel pins, acquire-recheck index. Pin is per call. | Change entry to `cohort_enter(ps,operation_cap,role,&handle)`. Admission/epoch/index validation and counted entry must be serialized against close/seal. The current double index load alone does not qualify multi-epoch entry or prevent an increment during GO checks. |
| `968..969 barrier_sync_op` | Release-clears member tail flag and acq_rel-decrements channel pins after forwarding. | Preserve actual last native-access ordering. A communication pin covers wait/unlock/signal/forwarding; transition/result waiter references remain separate and cannot be included in the zero-communication predicate. |
| `998 ___cohort_record_result_ack` | Stores ACK1; only the definition is present. | Accept a live transition capability/full key, publish generation/result identity under a counted ACK-publication reference, and reject stale writers before touching the slot. A null-rejectable API must check ps before deriving VM/id. |
| `1012 ___cohort_publish_go` | Checks ACKs/tails, both channel pin counters, then release-stores GO1. Only the definition is present. | Require SEALED admission and no ACK writer before checks; accept exact current generation/member incarnations, not any nonzero ACK. Publish tagged COMMIT or ABORT in a pinned completion record. It must not free the RC carrier. |
| `1690 sync_owner_phase`, `1757 ack_service_window` | Carries epoch and phase in a fixed barrier; root increments ack_phase_generation/ack_round. Owner batch currently performs no debt unlink. | Thread an already accepted old-cohort capability through these barriers. Add transition generation and actual round/phase validation; the current phase payload does not carry the complete round identity. Do not close these internal entries before they finish. |
| `1786 execute_sync_op_loop`, service_sync_op/on_all_processors | Shared outer loop; resize/result skip service window; local NOOP/error paths may exit. | Add one stable-cohort transition schedule with no early return across closing/seal/result/resume. Preserve startup/resize/nested-GC debt. Two opcode exclusions alone are not proof that every nested role reached a stable common boundary. |
| `6072..6088 setup_vmstate initialization` | index0, GO0, RC-intent1, channel epochs1/0, flags WAITING, ACK0/tails0. No transition reset/rotation writer exists. | Factor native initialization into `cohort_prepare_successor` plus `cohort_reset_ack_slots` under the closed/drained protocol; initialize a fresh incarnation/transition before any READY/OPEN publication. Initialization is not a reusable reset protocol. |
| `header:12145..12163 cohort fields` | Two inline channels, int index/GO/RC flag and per-member ACK/tail arrays. | Add explicit admission state/count, immutable transition/result keys, writer/result-reader references and per-attempt ACK records. Ordinary RC counts remain separate. |

The new helpers are currently unwired, so the interleavings below are conditional implementation-gap counterexamples, not observed native races. Existing ack service is neither result ACK nor GO. cohort_rc_held1 is intent, not a traced carrier/root-install certificate.

## Concrete state machine and capability classes

Proposed VM control state:

```
OPEN(E,Tlast)
  -> CLOSING(E,Tnew): reject new ordinary rounds; registered DRAIN(E,Tnew) allowed
  -> SEALED(E,Tnew): reject all new communication / ACK-writer entry
  -> ZERO_OBSERVED: both channel pins, per-member tails and ACK-writer pins zero
  -> PREPARED: inactive channel initialized; exact member/result ACKs validated
  -> COMMIT(Enew,Tnew) or ABORT(E,Tnew): release-published completion
  -> RESUME_ACKED: all old members acquire-observed same tagged disposition
  -> OPEN(stable epoch,Tnew)
```

The same close authority must protect entry checks and pin increments. Prefer a nonblocking combined atomic admission-state/count CAS on the existing stable VM control word, under an already-valid VM borrow. It grants a short-lived lookup/admission pin first; only then acquire-load the stable current epoch/index/transition and validate the expected full capability. Publisher cannot rotate while that lookup/communication count is nonzero. A stale expected key drops the pin and rejects before mailbox access. New ordinary OPEN entry and registered CLOSING drain entry have separate validation; SEALED admits neither. Channel pin and the total admission count must cover their initialization/decrement interval, so final zero checks include the total count as well as both channel counters.

Actual caller constraint: `_thread.scm:690..700 ##lock-scheduler-object-with-sync-participation!` may invoke ##sync-op-interrupt! while other scheduler ownership is retained; migration at3315..3337 holds the current thread lock and calls that helper to acquire the destination processor. Introducing a blocking cohort-control mutex on this path can create a new lock cycle. Either implement the atomic nonblocking counted fast path, or prove/implement a complete saved scheduler landing that releases/restores ownership before the blocking slow path. Blindly unlocking a migration or silently skipping required sync participation is invalid. Leadership prepare/close/reset may use native control serialization only at a no-T/P-lock boundary. The model abstracts this atomic entry authority; it does not prove those C caller/lock constraints.

A separate closed boolean followed by unprotected fetch_add recreates the race. A phase/count CAS without a protected VM lifetime and post-pin full-key validation is also insufficient: the mode/count bits can repeat after another transition. That repeating word may grant a temporary pin on the **current** descriptor, but it must not authenticate an old transition. Overflow refuses before count wrap. Every zero observation occurs after SEALED, and no initialized index/key is overwritten until counted lookup/communication users have drained.

Counted capabilities:

- **Accepted operation registration:** created before ordinary close, proves which old cohort/round the entry belongs to. It authorizes only its prescribed drain phases, not arbitrary new GC/resize/election work. Merely passing role=DRAIN or setting TLS is not authority.
- **Communication pin:** acquired for one admitted barrier call and released after all mailbox/pstate/backend accesses. The final GO zero test includes every communication class and both channels.
- **ACK writer pin:** acquired against the current transition before writing ACK payload/release flag; dropped after the last slot access. Seeing ACK is not seeing the writer's native tail finished.
- **Completion reader reference:** protects the tagged GO/ABORT record through native wait/acquire/return. It may outlive resume ACK, but never counts as an outstanding communication pin. Reuse of its record waits for its actual last reference.
- **Parent carrier/native job pin:** unaffected by channel reset or GO. Replacement-root ACK and owner-local RC grace remain separate unimplemented gates.

CLOSING blocks a *new* ordinary round. A registered old round can finish READERS_EXITED/OWNER_SERVICE_DONE using its counted internal lane. After a member publishes its final generation-qualified drain/result ACK, that capability must not initiate another old barrier. Once all members have done so, seal the internal lane and wait for all accepted communication/ACK writer tails. Existing consumers can always drop their references; they never wait for OPEN/GO to do so.

## ACK reset, channel reuse and publication order

1. Reserve a new transition record/full key `{VM incarnation,cohort epoch,transition generation,round,member incarnation}`. It must not alias a record still held by a historical ACK writer or completion reader. If a bounded record pool is full, refuse/defer a **new transition** while continuing the current stable cohort; do not overwrite a held record.
2. Initialize that record's ACK slots to EMPTY and expected key before release-publishing CLOSING/transition identity. Reset only the selected transition record. An old writer admitted before the close must finish/drop its writer pin before that storage can be reused; an attempted historical writer after reset is rejected before the write.
3. Complete the fixed old-cohort drain phases; publish each member's ACK with the exact transition and observed result. The ACK payload is written before its release flag; leader acquire-loads the flag before reading payload. A failed attempt may keep E unchanged, but T always advances; comparing E alone is insufficient.
4. Seal communication and ACK-writer admission. Only now may the leader's successive zero reads remain valid. Confirm exact ACKs, communication pins/tails and writer grace. Existing accepted-drop paths remain legal and nonblocking.
5. Reset the target inactive channel: all message flags WAITING, no leftover payload considered valid, full target epoch/descriptor generation, and initialized wait resources. This occurs while ordinary and drain entry are sealed and counters are zero. Keep current channel pointer immutable for every already counted call. Counter zero without sealed admission does not authorize reset.
6. Initialize successor membership/rank/scan-domain descriptor before publishing its index/epoch/result. COMMIT changes active epoch/index; ABORT publishes the old stable membership and does not masquerade as a successful park. Both preserve the parent carrier. No Scheme allocation/callback or unclassified destructor in this common window.
7. Release-publish `{T,stable_epoch,COMMIT|ABORT}`. Every old member acquire-observes that same disposition and publishes a resume ACK through the stable native record, without reacquiring communication pins. Wait/ACK record lifetime is separate from reusable channel lifetime.
8. Re-open ordinary admission only after the defined common resume condition and initialized stable descriptor. An error returns through the agreed ABORT completion after this convergence, never locally before other members know the result. Reopening must occur on both success and safe abort; forgetting it leaves safe roots but dead service.
9. Pending GC is recorded throughout close/seal. It starts its next snapshot only on the stable OPEN cohort and is serviced before another transition can consume the next service opportunity. Do not clear it during ACK reset. New GC requiring an old drain is not invented after SEALED.

Current GO1 and ACK1 integers cannot encode this protocol by resetting them in place while a delayed observer is still reading. A historical GO reader must retain immutable `{T,status}` storage until its last access. Clearing GO to0 for the next attempt can otherwise erase an unobserved successful outcome. The model distinguishes resume observation from the reader's actual final release.

## Failure boundaries and C ordering

Known preparation failure before active-index publication can publish ABORT and resume the old cohort with a new transition generation. Do not restore stale fp/root copies or clear carrier/native pins. Failure after an ambiguous index/result publication is not a safe local reopen; retain and use the reviewed shared reconciliation/terminal policy. Missing members/writers can block a transition indefinitely; bounded retention protects memory, not unconditional progress.

Mutex/condition-variable unknown results cannot be repaired by resetting ACK fields. Treat them under existing shared fault policy. An epoch/count wrap refuses before reuse; no modulo alias is an acceptable historical key. VM shutdown closes public admission while preserving counted internal drain/drop capabilities and keeps VM/pstate/wait resources alive through their own last consumers.

Required happens-before chain is: initialized transition/ACK payload → release publication → matching acquire read; each communication/ACK-writer last access → acq_rel drop → leader acquire zero after SEALED; initialized channel/descriptor/status → release result → acquire member observation → release resume ACK → acquire all-resumed → OPEN release → acquire entry. Initial pointer/key lookup and acquisition must be protected by stable VM/control ownership. This is a conditional C design argument; QNT's atomic steps do not prove actual C11 code.

## Grok implementation order and source-bound native checks

1. Define VM/control/transition record fields and full keys; audit the scheduler-lock-held sync path before choosing the atomic fast path or a fully proved slow landing. Separate communication counts, ACK writer pins, completion readers and parent carrier ownership. Define overflow/capacity refusal and setup/cleanup ordering before publishing READY.
2. Replace raw barrier entry with `cohort_enter(ps,accepted_cap,ORDINARY|DRAIN,&handle)`; close/seal and entry increments share one authority. The atomic lookup pin precedes full-key/index validation and blocks rotation until put; no blocking control-lock acquisition under scheduler locks. Adapt service_sync_op, on_all_processors, startup/native loops and sync_owner_phase callers. Passing DRAIN must require a registered capability. Keep drop paths usable under all closed states.
3. Factor reusable ACK/channel initialization from setup_vmstate. Give ___cohort_record_result_ack a full transition key, initialized result identity and writer pin. Give ___cohort_publish_go a SEALED token and matching result record; it cannot infer closure from sampled counters.
4. Wire CLOSING→registered drain→SEALED→zero→prepared→tagged COMMIT/ABORT→resume ACK→OPEN through execute_sync_op_loop's shared native/ Scheme roles. Preserve pending GC and avoid opening a transition inside an unresolved resize/startup cohort. Publish all error dispositions before returning.
5. Compile the exact configured generated Scheme/C and inspect capability/root handling at each actual C call. Completion-root ACK and owner RC reclaim remain separate from this mailbox patch; no GO path may fake them or clear cohort_rc_held.
6. On one bound producer pause entry immediately before pin increment while P0 closes admission; pause an ACK writer after its release store but before writer put; pause a GO reader after observation but before its final release. Require rejection/drain/backpressure respectively, never reset of live storage.
7. Exercise at least three transition generations: success, abort with unchanged cohort epoch, then retry; alternate both physical channels and attempt delayed ACK/GO replay from the first attempt. Require exact-key rejection, all native tails before channel reset, and old result retention until the final reader leaves.
8. Inject GC during CLOSING and SEALED; prove prescribed old drain can finish and latched work runs on the reopened stable cohort before another transition. Inject both prepublication ABORT and unknown publication faults; check common outcomes and parent-root retention. Keep original watchdogs and preserve negative receipts.

Independent conclusion: the chosen drain design is sufficient in principle for mailbox reuse only if these admission/lifetime/identity conditions are implemented together. The finite model can expose missing closure, stale ACKs/parity-only EMPTY acceptance, live ACK-writer/result-record reuse, early reopen and close/reopen deadlocks. It does not supply missing generated maps, actual common-role integration, native tests, frozen root/weak/finalizer correctness, lifecycle acceptance, arbitrary integer wrap or recovery from lost participants. Formal9/12 remains open.

## Recorded validation and limits

`models/gambit/drain_epoch_rotation.qnt`,Quint0.33.0/TLC:19 expected controls, all matched:3 safety/weak-fairness conditional-progress scenarios,9 decoded safety negatives,2 decoded temporal lassos,5 reachability witnesses. Maximumcase10.519s under unchanged30s per-case cap. Receipt:`.cache/tasks/repair-9-12/processes/audit/runs/fe025d74b66c4622b8a9ba44ea2cb81b/outputs/drain-epoch-rotation/receipt.json`. Projections reproduced byte-for-byte; independent Python predicates checked safety violations, targets and safe non-goal temporal cycles.

Positive modes cover3 successful transition generations, an initial ABORT followed by retries without changing the failed cohort epoch, and a permanently retained old completion reader that permits2 transitions but backpressures reuse of its record for the third. Progress also checks that a recorded GC request is eventually serviced on stable OPEN membership; pending GC precedes admission of another transition. Registered drain admission while CLOSING and GC latched during close then serviced after reopen have separate reachability witnesses.

Negatives cover a new pin after zero observation, stale nonzero ACKs, writer tails ignored during reset, live result-record reuse, resetting a pinned channel, OPEN before initialized publication, dropping RC intent on ABORT, freeing a result at observation rather than last reader, and parity-only acceptance of EMPTY ACK0 at generation2. The model also contains a generation1/3 replay mutation, but the shortest decoded failure is the earlier EMPTY0/2 collision; no separately witnessed1/3 replay claim is made. The existing C helper checks ACK==1, not parity: this is a weakened proposed-matcher control, not an observed current-C failure. Temporal negatives retain memory but deadlock when close prevents old tails/drain from finishing, or when publication never reopens admission.

The model has2 abstract members,2 physical completion records/channels and3 transition generations, with atomic admission/initialization and fixed member set. It does not model C CAS/lookup instructions, scheduler T/P-lock ownership, actual root storage, arbitrary epoch wrap, dynamic resize/startup membership or unknown publication reconciliation. rcHeld is an intent invariant, not GC-root proof. Proposed completion-record pins are distinct from communication pins; permanently stuck pins do not imply eventual reclamation. Native executions0; no qualifier/runtime/history changes.

## Counted entry and registered-drain caller refinement

[Atomic entry/held-thread-lock sync/registered drain](drain-cap-admission-protocol.md) refines the proposed atomic entry into lifetime pin then authority check, grounds service-needed polling in actual migration/trylock callers, and separates communication/ACK-writer count from GO reader ownership.26 controls include mode-word ABA rejection, wrong-step/spent token negatives and3 safe-memory deadlock/starvation lassos. It does not turn abstract heldT/threadRoot into generated C evidence; earlier immutable receipts remain unchanged.
