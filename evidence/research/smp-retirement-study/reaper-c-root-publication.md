# Reaper C refinement: root domain and publication ownership

2026-10-23. Source/evidence design only. No runtime patch or native execution.
Formal lifecycle predicate, recipe and milestone stay unchanged at8/12.
This is a function-level plan for Grok, not an applied patch or admission claim.

## Principal finding

**A reaper by itself does not close the GC gap.** Existing thread save can retain
a raw donor-stack frame address; current GC root/RC/still setup and accounting
are per active processor. Thus reducing processor_count while retaining native
donor allocation is not continuous scanning coverage. A carrier boolean and a
release flag cannot repair that loss. The bounded refactor needs both:

1. Scheme-safe preparation, captured-frame materialization and a persistent
   retirement GC domain for frozen donor-owned still/RC lists;
2. an immutable-generation publication/consume protocol and a GC-domain removal
   boundary that forbids reclamation while readers or native publishers remain.

The final experimental GSI remains7263fe03... with ten source identities in
`final-device-owner-verification.json`. It implements neither this root-domain
extension nor the reaper. Previous39 targeted checks cannot certify new paths.

## 1. Actual source correspondence

References below are pinned producer-relative source paths/lines. The companion
JSON binds exact bytes including `_thread#.scm` and `os_setup.c` inspected here.

| Actual code | Established behavior | Consequence for the patch |
|---|---|---|
| `_thread#.scm:1422`, `macro-thread-save!` → `##thread-save!`; `gambit.h.in:6319`, `___THREAD_SAVE` | Stores `frame` into the thread continuation; one branch casts current fp to SCMOBJ | A saved thread is not proof its continuation has already left the donor stack. |
| `mem.c:3822`, `mark_captured_continuation` | Stack-frame representation is detected; collector allocates/copies frames, writes forwarding links and updates root reference | Reuse this mechanism under the old GC cohort. Do not memcpy fp, treat arbitrary words as Scheme roots or resume a raw C frame through a new helper. |
| `mem.c:4053`, `mark_continuation` | Walks actual donor fp/stack_break and GC maps; mutates frame links | Do not call it with a retired donor as the collector after its GC allocation context has been retired/reassigned. |
| `mark_registers:6934`, `mark_saved:6949`, `mark_type_cache:6964`, `mark_processor_scmobj:6979` | Marks mutable locations; forwarding may update those locations | Export live locations/values into an authoritative traced owner before withdrawal, or keep explicitly scanned slots. A one-time untracked C copy becomes stale after GC. |
| `mark_rc:4124`, `___set_data_rc:822` | RC header owns mutable `data`; GC marks `&h->data`; setter writes actual header data | Pending RC headers need per-GC marking/writeback in their real data slots. A carrier snapshot of old RC values is not equivalent. Host mutation must obey GC participation/quiescence. |
| `setup_still_objs_to_scan:4365`, `scan_still_objs_to_scan:4392` | Resets every native still header's mark/link and queues externally referenced objects for scanning | Include each pending donor owner once in every GC setup. Repeat mark initialization and scanning; do not scan a copied list once and forget it. |
| `___garbage_collect_pstate:7466–7489` | Setup→barrier→strong mark→barrier→weak mark→barrier→cleanup | Insert pending-owner setup before the existing setup barrier and RC roots in strong phase. Reuse phase ordering instead of inventing a concurrent collector. |
| `setup_stack_heap_vmstate:3565`, `determine_occupied_words:6684` | Stack/heap assignment and accounting use active population | No raw pending fp may survive section reassignment. Include pending still/RC resource accounting without counting moved owners twice. |
| `___transfer_mem_pstate:5257`, `___cleanup_mem_pstate:5307` | Splices still/RC lists only after caller-supplied join/drain; destroys donor scan lock | Finalize at one agreed GC-quiescent collective boundary. Registry removal, list transfer and cleanup cannot interleave with a new root snapshot. |
| `setup.c:267`, `release_procedural_interrupt`; `cleanup_interrupts_pstate:520` | Calls arbitrary registered `execute_fn(intr, ___FAL)` while releasing queued native callbacks | Current post-count exit tail is not proven callback-free. Detach/drain/fail the release suffix while old cohort still serves GC; do not run arbitrary callbacks on reaper or after root freeze. |
| `setup.c:1117` retirement tail; `os_setup.c:3146` → `os_io.c:12177` | Deque manipulation touches Scheme objects; OS cleanup closes select-abort resources | Move Scheme deque work before final freeze/count commit. Delay any descriptor close until its actual writer/selector/handler grace. Pure-native exit is a new requirement, not current fact. |
| `_thread.scm:3112`, VM unused-field2; `mem.c:6996`, `mark_vm_scmobj` | unused-field2 already roots fault coordinator; VM body is marked using VM_SIZE | Do not overwrite that root. Add an explicit traced retirement field with matching type/constructor/layout/generation updates. |

## 2. Concrete root-domain design

### A. Prepare before entering the count-changing C collective

Add a private Scheme coordinator/landing-pad path in `_thread.scm`, with layout
macros in `_thread#.scm`. Prepare requests must be launched **before** P0 enters
`___current_vm_resize`'s count-changing collective, outside T/P locks. Waiting
for a Scheme request while holding that collective would deadlock the very
scheduler/GC work preparation needs. Registered private preparation remains
serviceable while public donor admission is closed.

Use existing save/migrate mechanisms to retain each live Scheme thread, its
continuation/environment, result-mutex request/outcome, queue suffix and processor
object. Drain procedural release callbacks with a rooted current item/error and
unexecuted suffix; failures return to the preparation coordinator. Do not replay
consumed prefixes. Returnable foreign/sfun C frames that cannot reach the landing
pad cause refusal before count commit; direct external-C entry does not acquire
a valid Scheme context merely by calling this helper.

Then perform a supported old-cohort GC/materialization rendezvous, with all
retirees still serving nested GC. Confirm captured continuation references and
saved live state no longer rely on donor raw stack storage. Root every live
register/saved/cache/processor value that will be used later; clear dead slots
only after establishing their authoritative carrier and no future reads.

A new final native, nonreturning retirement entry must consume only native IDs
and prepared handles. It cannot touch the Scheme deque, allocate Scheme objects,
invoke callbacks or read old saved SCMOBJ values after commit. Its generated C
and marker lifecycle need explicit review. Existing C resize tails cannot simply
be declared safe by setting `prepared=1`.

### B. Use an explicit traced VM field, not raw malloc roots

Proposed append-only VM field `retirement-roots` holds typed per-generation
carrier objects. Update `_thread#.scm` VM type/constructor and `gambit.h.in`
VM_SIZE together; regenerate/verify all affected C layout uses. Existing field
positions can remain unchanged by appending, but this is a rebuilt layout, not
ABI-compatible reuse of an old executable. Preserve fault-coordinator field2.
No native reaper record contains a Scheme pointer that the reaper dereferences.

The carrier contains supported Scheme references; native ledger contains keys,
handle copies and bounded owner descriptors. The carrier exists before root
withdrawal and remains reachable throughout rollback/pending/failure. Global
VM rooting covers the Scheme object graph; it does not automatically traverse a
native RC or still-object linked list.

### C. Factor collector context from native-list ownership in mem.c

Proposed functions, implemented inside mem.c where existing GC macros/helpers
are available:

- `retirement_gc_snapshot_begin(collector, vm, snapshot)`: at GC setup, acquire
  stable native registry lease(s) under one registry mutex, then release mutex.
  All entries already have fully prepared roots and closed donor mutation.
- `setup_still_owner_to_scan(collector, owner, scan_tail)`: factor the existing
  per-owner mark reset and externally referenced still queue setup; operate on
  each active or pending owner once. Collector's allocation/work context stays
  active. Compose queues before the existing setup-phase barrier, after its own
  setup so the pending queue cannot be overwritten by the active setup call.
- `mark_rc_owner(collector, owner)`: factor the RC traversal, calling
  `mark_array(collector, &header->data, 1)` so GC updates actual RC locations.
  In P0 strong phase visit pending owners before the existing strong-phase
  completion barrier. Do not pass donor ps as the collector simply to change
  what a per-processor macro points at.
- `retirement_gc_account(snapshot)`: include retained native allocations and
  pending still bytes in relevant heap/resource accounting exactly once. Do not
  silently exclude them because active count shrank.
- `retirement_gc_snapshot_end`: after all phases no longer use pending list
  headers/queues, drop the registry lease. Do not reset this count in a resize.

Pending owners' zero-ref/unreachable still objects are conservatively retained
until post-join transfer rather than swept from a donor that is still exiting.
Every GC still resets their mark state and traces externally referenced/reached
objects; retention is not omission from tracing. Deferring pending sweep/finalizers
has a resource cost and must be included in accounting. After transfer, normal
receiver sweep owns those objects exactly once.

Direct host RC/still mutations are not made safe by a lifetime borrow alone.
Active Scheme participants stop at the existing GC collective; nonparticipating
external C users require the existing GC-quiescence contract or a reviewed
admission extension. Audit `___set_data_rc`, RC release/link mutation and still
refcount users before supporting them concurrently. If this cannot be established,
refuse retirement admission rather than assert that a copied RC vector is complete.

## 3. Four boundaries and exact admission conditions

| Boundary | Conditions that must be earned | Proposed implementation point |
|---|---|---|
| Prepare→Ready | Drained callback suffix; valid Scheme landing; materialized captured frames; complete typed exports; root field published; pending-list GC registration; host/worker mutation contract | Scheme coordinator + `___retirement_prepare_pstate`; old-cohort materialization; no reduced population yet |
| Ready→Committed | Every donor of same epoch Ready; helper already created; root/list registry visible; no raw Scheme reads in exit tail; old cohort agrees on commit/rollback | `___vm_resize_pstate` before OP_SET_PROCESSOR_COUNT |
| Done→Consumed | Actual join0/error stored; matched immutable generation and owner; consumer acquires same publication; sole consumer claim; no premature payload reads | `___retirement_reaper_entry` / `___vm_retirement_poll` |
| Consumed→Reclaimed | Successful keyed join; destination roots installed; old handlers/queue borrowers gone; no active GC snapshot; atomic GC-domain transfer; no later producer access | New collective `___vm_retirement_finalize` around transfer/cleanup/registry removal |

A native join0 orders target thread termination but does not by itself drain
remote GC snapshots or close arbitrary host admission. Reaper completion and
resource grace are separate boundaries.

## 4. Publication proof and C-shaped reference protocol

This is a design sketch, not an applied/compiled patch. Use one per-record atomic
publication token; allocate/reuse under the native ledger mutex. Token includes
bounded epoch/incarnation plus phase or storage remains nonreusable until every
old reader is gone. Counter exhaustion must refuse, not wrap into an old token.
Only one reaper writes a claimed record, only the P0 coordinator consumes it.
Signal handlers and metadata observers do not directly read payloads.

```c
/* P0, after preparation; record storage is pinned and has no old readers. */
r->input = immutable_native_key_and_handle;  /* no SCMOBJ payload */
__atomic_store_n(&r->token, READY(g), __ATOMIC_RELEASE);

/* Reaper: claim also prevents a second native join. No GC/P/T lock held. */
expected = READY(g);
if (__atomic_compare_exchange_n(&r->token, &expected, JOINING(g), 0,
                               __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
    input = r->input;                         /* only after successful acquire */
    result = ___thread_join(input.thread);    /* exactly once */
    r->output = native_key_and_actual_result(input, result);
    notify_target = stable_vm_native_pin;     /* copied before final publication */
    __atomic_store_n(&r->token, DONE(g), __ATOMIC_RELEASE);
    /* Last access to r. Hint uses only copied data under VM native pin. */
}

/* P0: no payload read on a relaxed poll or failed compare_exchange. */
expected = DONE(g);
if (__atomic_compare_exchange_n(&r->token, &expected, CONSUMING(g), 0,
                               __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
    local = r->output;                        /* complete snapshot, native only */
    validate_full_key_owner_and_actual_result(local);
    /* Keep consume/slot leases until GC-quiescent finalization. */
}
```

The source for the happens-before argument is
[WG14 N1570 §5.1.2.4 and §7.17](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf);
[GCC atomic builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html)
provide the spelling used by the existing compiler. Same-object release observed
by acquire orders preceding payload writes before following reads. Missing either
edge leaves non-atomic payload access without the required synchronization; it
may be a C data race, not merely an occasionally stale but otherwise valid read.
These rules also do not extend object lifetime after free.

A separate per-donor PREPARED handshake precedes P0's input publication: the
worker installs Scheme references in an already VM-rooted carrier, materializes
frames and stops changing the exported state, then release-publishes PREPARED(g).
P0 acquire-observes that same donor token before treating its fields as complete.
This orders preparation but is not a substitute for the existing collective GC
barriers or the root registry. No SCMOBJ is smuggled through a native ready flag.

Required edges, with lifetimes stated separately:

| Producer→consumer | Happens-before chain | Lifetime / exclusive-access rule |
|---|---|---|
| Donor preparation→P0 | rooted/exported state writes → release PREPARED(g) → P0 acquire of the same donor token → readiness decision | Carrier is already traced; frozen donor does not rewrite values later; old cohort still alive until all Ready |
| P0 input→reaper | write input → release READY(g) → successful acquire claim reading that token → read input | Immutable until final producer access; stable VM/record borrow already acquired |
| Reaper output→P0 | write actual output → release DONE(g) → successful acquire consume reading that token → read output | Reaper never touches record after DONE; consumer owns it through validation/finalization |
| GC-domain publication→collector | publish fully prepared registry entry under registry unlock → later registry lock and lease → scan | Slot/domain cannot detach while scan lease exists; collector uses native lists in active GC context |
| Destination→domain removal | install traced receiver roots and native lists → collective finalize boundary → remove pending owner | GC cannot start between transfer and root-domain removal; no list is scanned under both owners |
| Helper stop→VM free | stop admission → final record consumption → helper stop ack → actual host join of helper → drain readers → free | Stop ack alone is not helper exit; late hints/writes require the VM pin until helper join |

A fence on one flag and acquire on another are not this proof. Notifications are
not publication; loss of a pipe byte cannot discard the mailbox. A successful
CAS, after reading the matching token, supplies ownership as well as ordering;
its failure grants neither. CONSUMING prevents slot overwrite while P0 reads.
Do not reset EMPTY/start a new generation while GC, reaper, P0 or registered
native observers can still dereference the record.

For registry admission and scan count, prefer **one short mutex-protected state**
(admission/open flag and readers together). Close admission and inspect readers
under that same mutex; do not repeat the separate-atomic count/closed race from
the wake-fd investigation. Pointer lookup must occur under a valid VM/registry
borrow before its first dereference. Lifetime must not be justified by incrementing
a counter inside memory that may already have been freed.

## 5. Reclamation ordering: one GC-quiescent finalization transaction

`___vm_retirement_finalize` runs as an agreed collective operation on survivors,
not an arbitrary callback between GC phases. It must establish no GC snapshot
lease and no remote old-handler/queue/native borrower. Hold no wait/join across
T/P/VM-list/GC locks. If grace is unavailable, remain JoinedAwaitingGrace and
return Pending; the native join is never repeated.

At that boundary: validate key/consume claim → install receiver roots → splice
still/RC and update accounting under the existing memory lock → remove pending
GC owner → clean donor native resources/scan lock → drop carrier and slot lease.
No GC may observe an interval with neither owner, or two scan owners for the
same native list. Ordinary MISC_MEM_LOCK alone is not proof of whole-collector
quiescence. Existing collective arbitration/nested-GC behavior must be verified
before selecting the exact operation priority/entry.

Failure before commit rolls back admission/root preparation in the intact old
cohort. Failure after commit retains ledger/carrier/list owners and exact error;
no false success or sticky-cleanup reset. Descriptor close remains behind actual
writer/selector/handler grace. Reaper errors never execute Scheme callbacks.

## 6. Ordered patch units for Grok

1. `_thread#.scm` / `gambit.h.in` / `_thread.scm`: append and initialize the typed
   retirement root field, add preparation coordinator/landing pad, preserve
   existing coordinator field2, export mapped state, drain release callbacks
   outside native mutexes, and prove materialization under old cohort.
2. `mem.c` / `mem.h`: factor explicit collector/owner RC and still helpers, add
   pending-owner snapshot leases, repeated setup/mark coverage and accounting;
   no post-commit raw-frame scanner. Verify second GC updates actual RC slots.
3. `setup.c` / `os_thread.c` / relevant header: add bounded pinned native ledger,
   fixed native reaper, immutable keyed tokens and matched publication/consume
   protocol above. Reaper entry must not use the processor/Scheme startup path.
4. `setup.c` / `_thread.scm`: move prepare outside count collective, commit only
   after all root/domain premises, safe-point poll mailbox outside P locks,
   preserve actual requested resize semantics, and keep callback-free exit tail.
5. `setup.c` / `mem.c` / native IO cleanup: implement keyed collective finalize,
   scan/handler/queue grace, exact-once transfer and accounting, helper stop/join
   before VM/record/descriptor destruction. Preserve retained failure behavior.

The existing `___cleanup_io_pstate` is void and ignores some close outcomes;
if retirement finalization needs checked release, introduce a checked variant
with retained ownership on error rather than assuming the existing call reports
success. The current fault/device tests do not automatically cover a changed
per-P cleanup ordering.

These units are one integration: a native reaper-only patch must not be admitted
before unit2 supplies real GC coverage. Generated C/layout and exact source/GSI
identities must be rebound; old completion seals do not certify these changes.

## 7. New QNT refinement and native checks still owed

`models/gambit/reaper_root_publication.qnt` complements the16-control reaper model.
It separates save from materialization,7 actual root families, repeated GC,
donor-to-P0 prepared visibility, input/output visibility, consumer ownership and scan leases. Two generations
retain prior transferred roots. Weak cases permit a stale observation when a
matching edge is absent; this is a conservative publication abstraction, **not a
complete C11 execution/data-race model**. Its proof assumes the C11 rule above,
not the other way around. It does not manufacture an errno or implement tracing.

The candidate checks safety and fair completion. Eighteen negative initializers
separate missing input release/acquire, missing output release/acquire, early
payload read, overwrite during consume, raw-frame commit, missing still scan,
post-freeze callback, free during scan, DONE before payload, stale epoch,
unrooted carrier, producer access after DONE, partial export, omitted second
GC's RC scan and missing donor PREPARED release/acquire. Each requires a decoded counterexample, never a parser failure.

Grok's native controls must force these boundaries on one integrated producer:
materialize thread-save frames before withdrawal; retain actual register/saved/
processor/thread/request payloads; keep externally referenced donor still/RC
objects through two GCs and mutate RC data between GCs under supported admission;
verify relocated references at their authoritative slots; force GC after native
DONE but before finalize; delay a scan snapshot and verify reclaim refusal; lose
only the hint; reject old epoch and duplicate consumer; retain native error;
check callback release failure/escape before freeze; finally verify exact-once
transfer, actual join0, helper join and no remaining consumers. No timeout/heap/
processor weakening. These are future native requirements, not results of this
source/model audit.

Reproduction (registered audit role, unchanged30s per model case):

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-reaper-root-publication.py
```

The contract observer/recipe/probe/milestone are unchanged. QNT and source
refinement plans cannot move the counter or substitute for those native controls.


## Follow-up: executable patch sequence for materialization and owner domains

`retirement-materialization-domain.md` and its patch-plan JSON specify proposed
fields/functions, old-cohort parking/materialization, rollback through current
GC-forwarded continuations, active-versus-pending native-list classification,
per-GC actual RC-slot writeback/still mark reset, accounting and collective domain
removal. Pending RC roots enter before the INTERNAL strong-root barrier/closure.
PREPARING registration never double-enrolls an active native owner. New16-control
QNT passes4 candidate safety/fair terminal cases and12 decoded negatives; actual
C implementation/native evidence remain owed. Current contract stays8/12.
