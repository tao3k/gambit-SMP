# Initial source review of the implemented pin/finalizer slice

2026-10-23. Evidence-only review, not a runtime patch or native result. Count8/12.
The user reports mem.o/setup.o rebuilt into c86 libgambit.a, gsi not relinked,
three banner controls passing, and GC/FFI stopped at engine transport before a
suite child launched. Those are attributed reports, not independently certified
object/archive/binary bindings in this review. No prior DENY is relabelled.

## Observation identity and source movement

Per-file stable snapshots: .cache/tasks/repair-9-12/processes/audit/runs/4b8ae711116341ceb0592c720d586417/outputs/finalizer-implementation-review/source-observation.json.
These are not a coherent producer or compilation manifest. In this later setup.c
snapshot a post-GC epilogue exists at2311-2355, although the user's reported build
had not integrated it. Do not merge those observations into one compiled result.
Only immutable snapshot bytes support the findings below; no peer was operated.

## Established changes versus remaining proof obligations

| Source anchor | Established from the observed bytes | Remaining condition / Grok action |
|---|---|---|
| mem.c:5918 reserve_pin, 5978 publish_joined, 6003 claim_finalizer, take_tail_token after6069; setup.c:2180-2228 | Resource pin is retained through JOINED/OWNED; keyed-by-slot tail_accounted CAS prevents repeated aggregate decrement in this path; shared-fault helper directly calls _Exit | This establishes the intended local sequence, not full key or native execution. Preserve the continuous pin and exact-once consumption. |
| mem.c:5516-5546 entry and global retirement_ledger[MAX_PROCESSORS] | Entry is selected only by numeric slot and pointer; no VM instance, slot incarnation, resize epoch or join-lane generation fields are present in the entry | Replace with per-VM keyed registry and immutable full K. Global slot aliasing across VMs/epochs must reject. Same pointer/id after reuse is not same incarnation. Supported topology restrictions must be explicit until implemented. |
| mem.c:6003-6032 claim_finalizer | CAS publishes OWNED before receiver is stored; duplicate OWNED path reads receiver | If concurrent claim/readers are supported, JOINED->CLAIMING CAS must first reserve a unique owner, initialize receiver/ticket/key, then release-publish OWNED; observers acquire OWNED. Do not have competitors write receiver before claiming. Current single-P0 serialization would need an explicit supported premise; no actual race was executed. |
| mem.c:5800-5816 reclaim, 6156-6172 unreclaimed/destroy_admit | Plain reclaim_complete is set before release-store resource_pin0; admission ignores even a live pin when complete is true. destroy_admit is an unsealed scan | It is not yet the reviewed sealed close-versus-enrol protocol. Close new enrollment through the same registry protocol, check debt before destructors, and treat pin1 as blocking regardless of advisory completion. Keep a record-reader grace before reset/reuse. Do not clear pin until after last entry access. Concurrent plain status reads need synchronization; serialized host contracts alone do not prove the proposed concurrent admission extension. |
| mem.c:5900 reset_if_reclaimed | Reclaimed entries can be memset, including atomic-accessed fields | Reset only after closed admission and actual metadata-reader grace; require a fresh nonwrapping generation. Do not race reset with reserve, selector or acquire-load. |
| setup.c:1072-1133 donor_borrowers_clear; 2339-2345 post-GC caller | Helper blocks on setup_guard_lock and request_slots[id].mut; it is called while other cohort members await common service result | Misc try alone does not bound the service window. Precompute/pin a borrower certificate outside the window, or use checked nonblocking checks that yield a common deferred result; no fallback blocking guard/slot acquisition inside the collective. This is a source-level blocking dependency, not a reproduced deadlock. |
| setup.c:2311-2355 post-GC epilogue | Completed-GC barrier, donor selection, common result and NOOP exit are present in this snapshot; GC result stays separate | Need final source/generated-C/archive/GSI binding, raw sync outcome checks, resize-internal-GC/common-return coverage and actual focused fault tests. The static process-global service cursor and global ledger also require per-VM identity review. |
| mem.c:5585-5643 misc try/unlock, checked empty destroy | Known BUSY preserves debt; mutex unknown outcome terminates; EBUSY destroy retains descriptor/pin | Audit actual preprocessed mutex/ticket backend and acquire edge. Other setup/sync/slot results remain part of the unresolved shared-lock safety contract. A return-code path does not prove a native syscall cannot hang before returning. |

These are implementation-to-model mismatches and conditional concurrency risks,
not a claim that the unlinked code has reproduced a use-after-free. The existing
22-control QNT assumed immutable full keys, pre-registered pins, before-destruction
admission and complete healthy transcripts. Its passes cannot be inherited as
proof of source paths that do not yet meet those premises. No unchanged model was
rerun and no new native result was created in this review.

## Required next order

1. Finish registry identity, close/enrol and final-reader release before treating
   the current pin as a concurrent cleanup certificate. Preserve the useful local
   pin->JOINED->claim->tail sequence; fix receiver publication under competing
   claims if that concurrency is admitted.
2. Remove blocking borrower checks from the all-member service window; preserve
   the same result/ACK transcript on deferred checks. Complete checked sync error
   handling and raw fail-stop paths without relying on broken transport.
3. Freeze final runtime/Scheme/generated-C/header/compiler/link inputs, build
   objects/archive and relink the same registered gsi. A source observation and
   changed archive do not certify executable behavior.
4. Run narrowly scoped native pauses at claim/tail/reclaim, stale/full-key and
   teardown/enrollment contention, held guard/slot borrowers, repeated GC and
   same-producer fault controls. Expected fatal controls are not resize success.
5. Resolve engine transport source/protocol mismatch as a separate bound adapter
   issue before launching an authorized GC/FFI consumer. The reported transport
   failure is not a new suite DENY from executed stress tests. Do not rerun the
   unchanged full inventory merely to check this source slice.
6. Review any pending-contract migration separately. The old two errno transcripts
   and qualification gate remain unchanged and8/12; the original Darwin error-to-
   same-owner0 event still has no demonstrated supported trigger.

No runtime, observer, historical receipt, recipe or milestone edit; no other
thread operation, staging, commit or push. No production compile/relink/test ran.


## Combined implementation protocol

`finalizer-four-gap-protocol.md` now specifies the four fixes as one protocol: per-VM full K, a single phase/count admission word accounting for reservation/resource/service/reader units, CLAIMING receiver initialization before OWNED publication, and try-only/common-result borrower service. The final28-control composition and native acceptance steps are evidence proposals, not source/native admission.
