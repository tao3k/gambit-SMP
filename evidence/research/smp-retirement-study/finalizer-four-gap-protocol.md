# Four-gap integration protocol: keyed registry, admission, OWNED and service

2026-10-23. Proposed Grok implementation protocol and finite-model evidence only.
Formal qualification remains8/12. No runtime/observer/recipe/milestone/history
change, native execution, other-thread operation, commit or push.

## Decision: one protocol, four linearization boundaries

Use per-VM native control, a full immutable entry key, a single atomic admission
word accounting for all relevant lifetime units, and two-phase claim publication.
The collective consumes only stable keyed state and bounded nonblocking checks.
Do not patch the four source sites independently and infer their composition.

The source baseline is the4b8ae711 per-file observation bound by
`implemented-pin-review.json`; it is not the current mutable tree or a coherent
built producer. In that snapshot a post-GC epilogue already exists, but borrower
checks still block and the ledger is global/slot-only. No native result is
inherited from a source observation, mem.o/setup.o or a changed archive.

## 1. Full K and per-VM ownership

Proposed native identities (not installed declarations):

```c
struct retirement_key {
  vm_instance_id vm_id; vm_generation vm_gen;
  resize_epoch epoch;
  slot_id donor_slot; slot_generation donor_gen;
  native_handle_lifetime handle_gen;
  lane_id join_lane; lane_generation lane_gen;
};
struct receiver_key { vm_instance_id vm_id; vm_generation vm_gen;
  slot_id slot; slot_generation incarnation; };
```

Native handle lifetime is a creator-issued token bound to the original handle,
not the printed pthread_t/address. A fixed join owner capability is assigned from
first claim and separately checked. Worker pointers, slot numbers and same logical
VM administration cannot replace these keys. Generations never wrap while old
messages, controls or borrowed handles exist; refuse exhaustion before mutation.

`retirement_vm_control(vm_token)` resolves a checked stable native control held
outside memory reset by setup_vmstate. Each VM owns its entries, admission word,
service cursor/cut, receiver records and lanes. A process registry maintains
instance high-water/tombstones and native control-reader grace; it is not a
process-global array indexed only by processor slot. Two VMs both using slot1
must share no retirement entry or cursor. A stale VM token must be rejected
without dereferencing its freed pstate. A native tombstone reader is not permission
to access destroyed Scheme/VM data.

Entry construction initializes full K, pin/phase, root carrier, actual join owner,
handle copy and native result source before release-publication. The Scheme root
carrier remains typed and VM traced; a native key/ledger contains no untraced
movable SCMOBJ. Record reset/reuse requires last-reader grace and a fresh key;
`memset` of an entry still reachable by atomic readers is forbidden.

## 2. Closed admission must also count existing-resource delegations

Proposed `admission_word` packs phase OPEN/DRAINING/DESTROYING/DEAD and a bounded
reference count into one aligned native CAS word. Verify the selected operation
is actually lock-free; no libatomic mutex fallback may be hidden inside a cohort.
Use sequentially consistent RMW/load for the initial implementation to simplify
review; weakening ordering is separate work, not a performance claim.

Counted units include: an in-flight enrollment reservation, a live entry's resource
pin, derived service/native-reader borrows, and every other migrated native VM
lifetime consumer. Diagnostic live_entries/native_tails/reclaim_complete remain
useful, but none bypasses a nonzero admission count or substitutes for sealing.

| Proposed operation | Required atomic protocol | Linearization / responsibility |
|---|---|---|
| `retirement_enroll_begin(vm,K)` | CAS OPEN,n→OPEN,n+1, then claim unused per-VM record | New root enrollment is authorized only by this ticket. Overflow/refused seal leaves no accepted worker retirement. |
| `retirement_enroll_commit(ticket,payload)` | Initialize immutable key/root/entry, publish LIVE; transfer reservation's one unit into resource pin without decrement/reincrement | A ticket obtained before closing may finish after DRAINING. Destroy still sees its unit throughout. No zero-count hole before entry publication. |
| `retirement_enroll_abort(ticket)` | Unwind only initialized private prefix, no accepted retirement; drop reservation after last VM access | Old cohort/public operation returns common precommit failure. No fabricated join or callback replay. |
| `retirement_derive_borrow(parent_cap)` | Exact valid parent K already owns a unit; CAS n→n+1 while OPEN or DRAINING | Closing rejects new root admissions but allows existing debt to finish. Parent cannot release until child unit exists. A zero-count/dead control cannot derive from a stale capability. |
| `retirement_close_for_destroy(vm)` | CAS phase to DRAINING preserving count | Same word orders closure against root enrollment. Do not wait holding VM-list/guard locks. Return retained/deferred when units remain. |
| `retirement_try_destroy(vm)` | CAS exactly DRAINING,0→DESTROYING,0 BEFORE first destructor | No root or derived admission can appear after this transition. Check remaining nonmigrated native contracts too; missing consumers prevent implementation admission. |
| `retirement_release_unit(cap)` | Last VM/entry access first, then atomic decrement in stable native control | The control itself remains protected by process-registry reader grace. After decrement only scalar locals/control-release bookkeeping may be used. |

This single total is necessary: sealing only enrollment while allowing an old
entry to increase a separately counted service_refs after a destructor's scan
recreates the original observation gap. A resource unit is retained from before
worker marker retirement through last reclamation. Native-tail consumption is a
sub-obligation, not pin destruction. No preexisting gate reference may be forgotten
on a failed path. A checked cleanup retry uses the same closed instance; it never
reopens an old incarnation merely to finish debt.

In C, the descriptor/ref implementation must protect stale capability lookup
itself: checked process-registry token first, acquire VM admission unit second,
then dereference VM data. The finite QNT starts with valid control tokens and
does not prove a native weak-pointer/ABA algorithm.

## 3. Initialize receiver before publishing OWNED

Do all fallible receiver/root/identity preflight before claim. Proposed entry
transition:

```text
actual same-key join0 -> release-publish JOINED
CAS_acq_rel(JOINED -> CLAIMING, unique finalizer ticket)
  initialize native receiver key, stable receiver borrow and service ticket
  release-publish OWNED
acquire observer sees OWNED -> validates full K + ticket + receiver generation
  -> exact keyed tail-token CAS once
```

CLAIMING reserves the sole writer; it does not mean receiver is readable. A
competitor returns DEFER while CLAIMING, without writing receiver, consuming tail,
joining or cleaning anything. OWNED observed by the same ticket can return
ALREADY_OWNED as a status, not a second execution capability. Service execution
itself remains single-owner/exact-once through its attempt/phase token.

Writing receiver before the initial CAS permits losers to corrupt the winner's
payload; writing it after publishing OWNED does not publish it to acquire readers.
The intermediate state avoids both. It neither drops nor reacquires the resource
unit. Initialization between CLAIMING and OWNED must allocate nothing, call no
Scheme/host callback and have no supported nonlocal escape. If an unexpected
failure prevents publication, retain CLAIMING/ticket/unit and use the reviewed
fault disposition; no timeout-based takeover of a possibly live owner.

## 4. Cohort service is bounded and nonblocking

Replace `donor_borrowers_clear` as an in-window blocking helper. Before election,
close the donor's relevant request/scan/native-mutation admission through checked
gates; an earlier publisher holds a counted unit until its actual last access.
Pin a certificate `(full K, membership generation, admission-close generation,
borrower state/scan cut)` under a valid owner. Outside the cohort may prepare it;
inside the cohort may only validate stable values or perform bounded try checks.

For a fallback guard/slot/misc check: try-acquire; raw BUSY produces DEFER; inspect
the protected fields; checked unlock; only then inspect another lock. Do not nest
setup guard and slot lock, hold either across a barrier, or fall back to blocking
lock acquisition. Separate snapshots suffice only while matching closed gates
prevent new relevant mutators; two unrelated zero counters are not a certificate.
Actual external RC/still APIs must obey supported host quiescence or be migrated
to checked leases. A VM lifetime pin alone does not make moving GC/data mutation
safe. Refuse unsupported raw-C concurrency rather than claim complete coverage.

One elected transcript for all current members, also used after completed GC:

1. All-member entry after previous GC accounting; retain its result separately.
2. P0 selects full keyed candidate or EMPTY using this VM's rotating cursor.
3. Perform bounded check. BUSY/borrowers>0/stale certificate -> DEFER, no splice.
   Eligible -> existing non-failing splice units/ownership log under exclusion.
4. Publish known result; every member ACKs; every member exits the same transcript.
5. Keep the derived service unit through the LAST epilogue/receiver/metadata access,
   then release it outside the transcript. Resource pin may remain on DEFER or
   local cleanup quarantine. ACK of service cut never erases resource debt.

For known BUSY, A's debt remains and eligible B can complete in a later bounded
pass. This guarantees no wait on A's lock inside the window, not eventual A
completion if its lock is permanently busy. Fairness/callback return/native
borrower progress remain assumptions of successful completion. Original absolute
deadlines/watchdogs are preserved. No spin-to-success loop or enlarged budget.

Provide standalone elected `OP_RETIRE_SERVICE` handling for GC-quiet operation,
sharing the helper/transcript with the post-GC epilogue. In the bound source,
using an opcode inside private barriers is not proof there is a dispatch case
for an external service request. Preserve resize-internal GC debt and common
growth/shrink/abort returns as specified in `resize-service-debt.md`.

Unknown shared lock/transport outcomes follow the separate direct process-fatal
protocol from `finalizer-tail-handoff.md`; no Scheme throw, cleanup, host callback
or broken-barrier report is attempted. A known local cleanup failure can be
quarantined only after shared exit and a proven dependency cut. Expected fatal
injections are not successful recovery or lifecycle qualification.

## Grok function-level work order

| Current anchor in4b8ae711 observation | Implementable replacement / review order |
|---|---|
| `mem.c:5516–5572` global ledger/slot lookup | Native per-VM control+full K+stable descriptor token; allocate/reserve all needed capacity before accepted shrink; migrate selector/cursor, not only entry lookup. |
| `reserve_pin:5918`, `reset_if_reclaimed:5900`, `unreclaimed/destroy_admit:6156+` | Begin/commit/abort reservation-unit protocol; shared gate seal/CAS-to-destruction; reset only after keyed record-reader grace. No plain completion flag bypasses total units. |
| `publish_joined:5978`, `claim_finalizer:6003`, `take_tail_token:6069+` | Actual join0 binding, JOINED->CLAIMING->OWNED, receiver/ticket publication, same-key exact-once tail consumption. CAS winner alone initializes payload. |
| `setup.c` actual shrink join/claim path near2180–2228 | Enroll precommit; worker tail marker retains existing entry. After join0 claim/delegate existing unit, never add a new unpinned entry. Known failures pass common resize result. |
| `donor_borrowers_clear:1072–1133` | Outside-window certificate+closed admission, or sequential checked try-only reads. Every guard/slot unlock outcome classified; no nested locks or blocking fallback. |
| `execute_sync_op:2311–2355` GC epilogue, opcode table/loop | Per-VM keyed candidate/cursor, same transcript on EMPTY/DEFER/success, checked sync outcomes, standalone service dispatch, exact membership/service generations. |
| `vm_native_consumers_clear`, `___cleanup_checked`, `cleanup_vmstate_locked`, owned VM cleanup | Seal and CAS admission BEFORE any destructor. Both VM0 and additional VMs consult their own controls. Derived service/reader/entry/helper consumers must be represented or explicitly drained before granting destruction. |
| `retirement_reclaim:5800–5816` | Finish entry work and ownership/root handoff, then retire resource unit; keep service/record-reader units through remaining native access. No complete-before-pin-clear shortcut; no memset while observers remain. |

Changing the frozen gate/source lock merely to accept a different vendor HEAD is
not an implementation step. Any adapter/producer source migration must be
separately authorized and bind exact source/config/generated-C/executable bytes.

## Combined QNT and distinguishing controls

`models/gambit/finalizer_registry_composition.qnt` combines both VMs sharing slot1,
all key components, registration/closure interleavings, reservation-to-pin unit
conversion, derived service/reader units, CLAIMING payload initialization, common
ACK/DEFER, and one same-VM second epoch with old-message rejection. The packed
word is represented as fields updated in one atomic transition; C must implement
one actual word or an equivalently proved serialized operation.

Candidates: normal, guard BUSY, slot BUSY, misc BUSY, seal/enrollment race, repeated
epoch, reader grace, one BUSY then retry, enrollment abort, and a service unit outliving its resource pin. Completion goals
separate retained A/B completion from whole cleanup. Key mutants independently
change VM, VM generation, epoch, slot, slot generation, handle or lane generation.
Other mutants admit after seal, drop reservation before publication, ignore pin
after advisory completion, publish OWNED before receiver, allow two writers,
block inside window, return a member early, reset a live reader, forget service
unit or derive after destruction. A temporal mutant waits forever on a busy
in-window native lock; decoded loop/stutter evidence is required.

The first25-control run checked root-enrollment sealing plus separately tracked
live pins. It is retained as a narrower predecessor; it did not model service
units in the gate. A subsequent compile attempt hit the original30s cap before TLC and is preserved as a timeout, not a pass. The final strengthened model includes reservation, resource and derived units in the same total, explicitly exercises a service unit outliving its parent resource, and adds two relevant negatives. Do not use the
earlier25 pass to prove the stronger lifetime protocol. Only unreferenced initializer declarations are erased in per-case compiler inputs: every removed name is checked to have no other reference, canonical/projected hashes and erased-name lists are retained, and publication reproduces every projection byte-for-byte. No protocol action, invariant, fairness clause, backend limit or deadline is changed. Exact final counts/results
are in the companion JSON and immutable run receipt; parser/timeout/harness
failures never count as distinguishing negative results.

This model assumes true join0, valid native control handles, atomic transitions,
stable root/scan ownership and fair supported native action completion. It does
not prove C11 lowering, lock-free ABI, arbitrary callback/native-call termination,
real frames or root scanning, raw host-pointer safety, native teardown coverage
or process-fatal behavior. Earlier22 fault-disposition controls are separate,
not a new whole-runtime combined proof. No native run occurs in this task.

Reproduce the strengthened combination within registered audit and unchanged
30s/case,1G heap/8m stack TLC limits:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-finalizer-registry-composition.py
```

## Native acceptance on one final producer (future, not executed)

Freeze source/Scheme/generated C/header/config/compiler/link/archive and relinked
GSI identities. Object/archive-only changes do not certify gsi. Keep topology,
original deadlines and registered production custody; reuse the completed producer
through typed references. Tests require declared native pause points/injection
with exact source identity, never fabricated OS errno or stdout substitution.

1. Two VMs concurrently use the same donor slot with different handle/generation
   tokens; finish A, then operate B. Wrong VM/key messages and stale tombstone
   handles reject without touching B. Repeat same VM epoch2 and replay epoch1
   JOINED/claim/tail/completion: no second join, tail decrement or transfer.
2. Pause after enrollment reservation, race close/destroy, then complete or abort
   enrollment. Destruction must defer while reservation exists. New root enrollment
   after closure must reject. Partial construction failure releases only its own
   initialized prefix and unit; old cohort remains safe.
3. Pause in CLAIMING before receiver initialization and before OWNED publication.
   Competing callers return DEFER/ALREADY status with no payload write or execution
   authority. Cleanup rejects; resumed winner publishes initialized receiver and
   consumes tail once. Wrong receiver generation/key rejects before pointer use.
4. Close admission with an accepted entry, derive service/reader units, and release
   its resource unit while child units still exist. Destruction must still defer.
   After LAST child access, release unit; only then can DRAINING,0 CAS succeed.
   No new derived grant can succeed from stale capability after DESTROYING.
5. Hold setup guard, request-slot mutex and misc lock in separate fixtures. Each
   service window takes a bounded DEFER path, all members exit, old deadline stays,
   A retains debt and eligible B progresses. Release holder and retry same K;
   join0 stays latched. A permanently held shared lock does not promise successful
   transfer for another donor needing that lock; record bounded refusal honestly.
6. Hold a real exported scan chunk/record reader across join0 and common exit.
   Repeated GC must retain/update actual root classes while deferred. Free/reset
   blocks until the real last reader leaves; no cosmetic empty-queue certificate.
7. Repeat growth/shrink/abort and resize-internal GC with service debt pending.
   Verify mandatory service and standalone GC-quiet operation, no overwritten
   debt, no member early return, and no callback inside native splice core.
8. Raw shared lock-error/fatal and local destroy-quarantine controls remain
   separately labelled; successful first-eight and earlier39 contracts must be
   rechecked on the same FINAL producer. Two reviewed lifecycle campaigns are
   still separate from these focused controls. The current formal error->same-
   owner0 gate is unchanged, and none of this model evidence advances8/12.

Record native events with full K/receiver/ticket, gate word before/after CAS,
reservation/resource/service/reader unit ownership, claim/publish/tail sequence,
common member ACKs, actual native outcomes, root payloads and exactly-once counts.
Native bounds and contention costs are unmeasured: per-VM bounded storage and a
few CAS operations are a design cost, not a performance result.
