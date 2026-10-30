Current extension: generated-root-handoff.md/json,83 controls, generated-boundary/root/reload/native-tail and nonoverlapping lock-borrow publication. Earlier counts below are historical.

Current extension: setup-ticket-propagation.md/json,69 controls; persistent guard and original-marker setup authority now precede the earlier bootstrap/growth graph. Historical counts below retain their own receipts.

Current model extension (2026-10-23): bootstrap-unified-protocol.md/json now
verifies53 expected controls in this same model. Historical30-control sections
below predate explicit bootstrap identity/failure/reuse/original-return states.

# Integrated growth transaction: reservation, admission and native shells

2026-10-23; repair-9-12. Evidence/design only. Runtime integration belongs to
Grok. No runtime modification, native execution, other-thread operation, commit,
push, observer change or formal-contract change is performed here.

## Decision

Use one transaction record and one full incarnation key for the three mechanisms.
The saved current source already contains experimental reservation/admission
helpers, but the observation below shows that their integration is incomplete.
A private allocator claim, a native worker gate and a checked request lease must
not each invent a different meaning of "ready" or "released". This is a concrete
implementation order, not a request to implement three independent patches.

Two corrections are necessary when composing the previous proposals:

1. Split **count/scan-domain commit → per-child GO → startup collective → Scheme
   READY → OPEN**. Count membership does not authorize a public producer lease.
   A child is a GC/collective participant after GO but accepts external work only
   after exact READY. Keep internal startup/GC notification separate from public
   request admission. Otherwise a public request can enter an unserviceable slot.
2. Split **private-view discard**, **typed root release** and **native-control
   destruction**. Before commit, discard makes old-cohort GC safe without waiting
   for a stuck native join/close. It does not free the native control. After
   successful startup, the transaction root may be released when all actual
   payload consumers have handed off; the gate/handle record remains owned until
   actual retirement join0 and its remaining native borrowers leave.

A rejected processor hint must retain the primary thread request's delivery
obligation. Closing public admission does not revoke already granted leases.
Queue/handler/wake consumers remain after a producer releases its lease. These
are separate ownership transitions, not different names for a producer counter.

## Source-bound implementation order

Function names below identify implementation responsibilities; historical line
anchors are navigation clues. The saved current-source observation at the end
provides updated locations and separates existing experimental helpers from
unimplemented integration. NEW means a proposed protocol responsibility; do not
infer absence of a similarly named helper from that label.

| Order | Actual entry / proposed helper | Required transition and C/Scheme rule | Last consumer / model correspondence |
|---|---|---|---|
| 1 | `setup.c:___vm_resize_pstate`; NEW `___growth_prepare` | Allocate VM-owned descriptor, resource mask, typed carrier and per-created-child join owner before accepting growth. Key is VM instance + transaction epoch + slot incarnation. Checked increments refuse exhaustion before mutation; no key wrap. Record VM service demand, preserve prior watermarks. | VM pin covers native control; mapped/typed VM carrier covers SCMOBJ. `begin`, `retry`. |
| 2 | `___setup_pstate` at5069, native prefix split; `os_thread.c:___thread_create` at493 and `start_pthread_thread` at427 | Initialize native-only gate/control before create. Record actual successfully created prefix; creator and child have distinct borrows. Shell publishes PARKED, waits on persistent WAIT predicate with original absolute deadline. No pstate TLS/Scheme/GC/sync before GO. | Creator return does not prove child stopped. `create`, `park`, `abort`, `exitShell`, `joinShell`. |
| 3 | NEW `___pstate_request_acquire/close`; public high-level and procedural entries at setup364/489 | Previous incarnation must be drained before staging. Same short admission mutex validates VM owner/key/ACTIVE_READY and pins producer atomically. STAGED/STARTING reject before accepting payload. Release mutex before T/P/queue locks. | Lease spans final queue and wake access. `acquire`, `refresh`, `release`. |
| 4 | Heap guard and direct GC at setup1077–1086; existing common sync election | Old cohort remains the only collector while shells wait. Issue service debt before internal GC; agree one common outcome before any member returns. Finish old-cohort GC-safe rendezvous, close/drain short VM registry readers, then take ALLOC lock. Do not wait for VM lifetime pins in this reader fence. | Blocked native cleanup retains VM pin but cannot hold old GC hostage. `earlyGc`, `debtCut`, `serviceAck`. |
| 5 | `mem.c:next_msection_without_locking`3218; NEW `___reserve_private_pstate_sections` | Capture actual cursor/counts/generation; preflight overflow/capacity; inspect distinct unused2*k suffix nodes. Do not call allocating/fallback/custom-hook path or modify shared cursor/counts/links. Custom allocator needs explicit transactional adapter or preacceptance unsupported result. | ALLOC + common GC exclusion protects claim. `reserve`; eager allocator/GC-during-private negatives. |
| 6 | `set_stack_msection`3282, `set_heap_msection`3466; split `___setup_mem_pstate`4787 | Construct only unpublished empty views/first break/VOID regs/empty still/RC/wills. All fallible native setup already finished. Defer global-accounting-dependent limits until commit. No callback, Scheme allocation or external publication. | No inactive pstate enters active/pending scan registry. `buildFirst`, `buildRest`. |
| 7A | NEW `___discard_private_pstate_sections`; native prefix cleanup | Common ABORT decision is irreversible. Invalidate all private views before dropping claim/GC exclusion. Shared allocator stays byte-for-byte logically unchanged. Release ALLOC before registry reopen or OS cleanup. Full old ACK + reader grace authorizes old Scheme/GC resumption. | Actual created handles still need fixed-owner join0; failed join/close retains control/resource mask/key/VM pin. `abort`→`oldAgreement`→`readerGrace`→`oldResume`, with independent joins. |
| 7B | NEW `___commit_private_pstate_sections`; `barrier_sync_op` count publication around800–819 | One common GC-excluded commit publishes exact allocator accounting + membership + scan ownership, with infallible numeric limits finalization. Consume a genuine preclosed registry guard; do not reclose registry while ALLOC is held. After first shared write, no recoverable old-cohort rollback. | `commit` changes membership but leaves public admission CLOSED. Later cancellation is TOO_LATE/active lifecycle. |
| 8 | NEW native gate entry; factored `start_processor_execution`980 | Release-publish same-key GO payload; child acquire-loads predicate before pstate dereference/TLS binding. Startup NOOP collective runs before resolving current rooted thunk. Existing local `thunk=self->data_scmobj` before that loop must move to a fresh typed-carrier read after it. Mapped active frame then owns SCMOBJ across later GC. | Carrier→mapped frame handoff must be continuous. Native gate record survives startup; `publishGo`, `bind`, `startupGc`, `runScheme`. |
| 9 | Scheme startup READY hook and NEW `___pstate_request_open_ready` | Release READY only after successful Scheme initialization; acquire exact key/READY under admission discipline before OPEN. Startup failure after commit is an active membership fault: keep new scan membership/root/control, deny public requests and invoke existing rooted fault disposition; never call private discard. | `publishReady`→`open`; post-GO rollback and early-OPEN negatives. |
| 10 | `_kernel.scm:##raise-high-level-interrupt`; `_thread.scm:##thread-intr-propagate!/notify!/wake!`1370/1404 | Migrate header/import/GSTATE/export users to checked leased API together. Primary result-mutex node stays in target thread queue. Hint denial leaves rooted route debt; recheck target/key under T/P discipline, route a NEW hint or use existing rooted fault coordinator. No dual-linking, fake reply or silent void fallback. | `acquire(1)` denial preserves `hintDebt`; queue claim/disposition is separate from wake completion. |
| 11 | NEW close/drain implementation + existing queue locks/fault coordinator | OPEN→DRAINING under admission mutex, then unlock. Previously granted producer can still publish. Drain accepted node to execute/migrate/explicit failure; independently drain handlers/wake writers. No waiting/callback/GC under admission or T/P locks. | `close`, `publish` after close, `drain`, `wakeDone`, `release`; producer0 is not quiescence. |
| 12 | Stable-cohort service window, actual retirement/reaper path | ACK only captured service cut, never a demand that arrived after that cut. Service inspection of retained resources is not their reclamation. Next resize needs a stable-cohort handoff and covered cut. Native control/slot reuse additionally requires actual join0, queue/wake/marker/scan/native-reader grace and successful prefix cleanup. | `debtCut`/`newDebt`/`serviceAck`, `retry`; root release and control destruction are distinct. |

`___vm_registry_close` at setup176 actively waits for short registry readers.
It must run before ALLOC acquisition. Splitting the wrapper with a caller boolean
is insufficient: the guard must encode ownership of the closed registry, and
its release must not expose half-published membership. Signal delivery/replay
and all relevant readers must obey that guard. The finite QNT treats common
commit and its exclusion as atomic: it does not implement this guard for C.

## Failure table: required concrete behavior

| Trigger | Allowed continuation | Forbidden shortcut |
|---|---|---|
| Gate init/create prefix failure or park deadline | Common precommit ABORT; join actual prefix; release only initialized resource mask. Old cohort remains serviceable. | Inventing join for an uncreated slot; resetting deadline on each wake. |
| Partial private constructor failure | Invalidate views, drop private claim, common ACK/grace, resume old GC; native cleanup independent. | Global cursor rewind after unrelated allocator history; GC while unpublished views remain accessible. |
| Native join/close error | Retained record/key/resource mask/VM pin; old GC may proceed after view discard/ACK/grace. Other independent lanes progress. | Treat EXIT_HINT as join0; reuse slot; retry ambiguous fd close; claim eventual cleanup. |
| Concurrent lease close | Reject later acquisitions, honor earlier grants and finish accepted work. | Check then pin; revoke earlier lease; wait while holding admission/P lock. |
| Hint rejection during startup/migration | Primary node remains rooted; durable route debt retries after exact READY/route recheck or reaches rooted terminal fault. | Returning hint rejection as if primary was never accepted. |
| Failure after count commit/GO | Keep committed accounting/scan ownership; READY stays false; rooted active-fault handling. | ABORT/rewind old count or private views after any child can run. |
| Late old-epoch GO/request | Refuse using full key before touching pstate/queue; caller retains unaccepted node. | Reuse small epoch counter or accept slot-id-only pointer. |
| Debt arrives during service | ACK old cut, retain newer demand, service again before next admitted resize. | ACK current demand without inspecting it or clear ledger on retry. |

## Native acceptance checklist for Grok

These are **required new tests**, not a claim that a growth fault-injection
runner already exists. Implement them in the existing registered native probe
workflow and same source-bound producer; do not invoke historical execute/patch
scripts against an arbitrary base. The current audit runs only Quint.

- [ ] Record exact Scheme/C/generated header/GSI/compiler/config hashes before
  tests. Build through normal same-task exclusive custody and canonical producer
  registration after production lease naturally releases. No other-thread action.
- [ ] Instrument full key, stage phase, real created handle, fixed join owner,
  gate decision, allocator before/private/commit tuples, scan owner and root
  carrier identity. Record lease grant/close/publication/producer/handler/wake
  last release and service demand/cut/ACK. A textual READY/EXIT banner is not proof.
- [ ] Deterministically pause after count commit but before each GO, after GO
  before startup collective, and after collective before READY. Attempt both
  checked request APIs at every pause: no successful public lease until READY.
  Resume and require exactly one execution/disposition per accepted request.
- [ ] Inject gate/native initialization and create failures at prefix0/1/2;
  partial view failures after each stack/heap assignment. Compare actual allocator
  cursor, assigned/stack counts and suffix links before/after ABORT; force old
  GC repeatedly before next epoch. No leaked unregistered heap view/double scan.
- [ ] Hold one actual join or native cleanup failure while another completes.
  Old cohort must collect/service primary requests after common ACK/grace; failed
  slot/control must remain nonreusable. Do not manufacture Darwin errno11.
- [ ] Pause publisher between atomic lease grant and queue insertion, close
  admission, then resume publisher. Require insertion and one terminal disposition;
  hold wake writer/active handler after producer0 and verify no reclamation.
- [ ] Pause primary thread request after queue publication; reject/redirect hint
  across migration and STARTING/CLOSED slots. Trace primary request ID to actual
  thunk/reply or rooted VM fault; empty processor queue alone cannot discharge it.
- [ ] Force moving GC in startup NOOP before thunk resolution and between result
  store/unlock. Check real mapped frame/VM carrier/RC/still write-back in generated
  C, not just Scheme declaration macros. No stale raw `data_scmobj` value survives.
- [ ] Force Scheme startup failure after GO. Confirm committed scan membership is
  retained, no old-cohort allocator rollback, no OPEN, and rooted fault termination.
- [ ] Repeat ABORT→epoch2 success and success→later retirement/reuse. Replay old
  GO/ABORT/request key at each boundary. Check no stale acceptance/double join,
  no lost VM debt and no key wrap; test exhaustion refusal before mutation.
- [ ] Issue GC/service demand after captured cut and race a queued resize. Later
  demand must survive ACK and receive a stable-cohort service window. Measure
  actual deadline from original start, including spurious wakes/EINTR.
- [ ] On **one final completed executable**, run existing targeted request/fault/
  device/marker/deadline runners listed in grok-native-handoff.md section4. Keep
  p11, 8×100000 exact deliveries, child caps (12s floods/30s controls), existing
  600s aggregate supervisor cap and original250ms deadline; inspect every child
  exit/timeout/reaped/group-quiescent receipt. Do not substitute an aggregate exit0.
- [ ] Compare first-eight qualification/source contracts and their negative
  controls. This work does not authorize rerunning full GC/FFI inventory, Gerbil
  or release. Do not call the narrow growth tests a first-eight regression suite.

Model command (registered audit; no production execution):

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-integrated-growth.py
```

Existing focused native command chain and qualification read commands are in
`grok-native-handoff.md` section4. No new growth-native command is invented here.
Formal9/12 remains blocked by the separately documented unreachable OS-error
contract until separately reviewed. Pending→real join0 tests preserve ownership
safety but cannot satisfy the current errno observer. No observer/recipe is edited.

## Independent sufficiency verdict

The integrated protocol removes the rollback and admission design contradictions
for the default allocator, controlled checked clients and well-formed finite
incarnations. It provides a specific implementation route. It does **not** prove
unconditional eventual resource release: an OS join/close, callback, publisher or
worker may never finish. The stable response is retained ownership plus service
for unaffected members; a blocked borrower legitimately prevents its own reuse.

C closure still requires implementing the atomic common publication/registry
fence, release/acquire gate and READY edges, generated frame/root handoff, and
checked API migration. These are explicit code obligations in the table and
native checklist, not reasons to keep redesigning allocator rollback. Do not
claim arbitrary foreign raw-pointer clients/custom allocator compatibility.

The finite model represents two staged slots, two overlapping publishers, one
already accepted primary thread request, an old two-member cohort, repeated
abstract GC and two epochs. Safety mutants break actual ownership/order fields;
temporal negatives preserve safety while exposing unjustified completion claims.
It abstracts page contents, real C frames, atomic instruction semantics, arbitrary
callback behavior and shrinking/reaper scan internals (covered by prior studies,
not magically proved by importing their conclusions). It is not 9/12 admission.

## Performance and compatibility trade-off to implement explicitly

- Growth preparation moves fallible native work outside the final excluded
  interval. Private suffix inspection/construction is O(k) in added workers;
  keep its nodes/descriptors preallocated. No native join, reader-drain wait,
  callback or fallible OS operation belongs under ALLOC or in the count commit.
- Checked admission adds a short native mutex/pin pair per cross-processor
  request, besides the existing queue lock. It is not a new lock on every Scheme
  allocation. Optimize only after measuring contention; deleting validation or
  combining admission/P locks would undo the ownership proof.
- Public OPEN waits for exact Scheme READY. This may increase growth latency;
  old-cohort service and separate private startup GC notifications avoid using
  unready children to hide that latency. The model proves no numerical latency.
- Allocate control/join lanes from a bounded VM-owned resource budget before
  accepting growth. Retained join/close failures consume that budget and keep
  their original incarnation. Refuse further preparation when capacity is gone;
  never recycle failed controls or keep allocating unlimited replacements.
  A post-GO worker that cannot service collective requests can require rooted
  VM terminal disposition; this design does not promise a healthy continuing VM
  in that case. An unresponsive external borrower can prevent safe destruction.
- Migrating the raw void pstate API is a supported-client ABI change. Rebuild
  the exported table/generated headers and declared native clients together;
  reject unsupported custom allocator mode before acceptance. A compatibility
  shim that silently drops requests cannot preserve the new contract.

These costs buy a defined owner at every handoff and a safe disposition under
permanent failure. Actual pause time, request throughput and first-eight behavior
still require the matched native receipts above, with no widened budgets.

## Composition correction: recovery lanes outlive the resize call

Review of the integrated progress target exposed a further insufficiency: old
GC could resume while another successfully joinable shell's cleanup was enabled
only inside ABORT. Leaving ABORT would disable that cleanup forever. Safe roots
alone would hide the liveness regression. This is a design/model finding, not
an observed new C runtime failure.

**Concrete correction:** put each created worker's join/cleanup cursor in a
VM-owned recovery record, with its independent fixed join owner. Its runnable
service state is not the resize stack's PREPARING/ABORT phase. After common old
ACK/grace and private-view discard, the old cohort resumes, while the same
keyed record continues exit/join0/checked native prefix cleanup. A blocked lane
retains its own resource mask and pin; another lane must remain schedulable.
No serial blocking join loop may own all records. Schedule service from the
stable-cohort mandatory window and/or its already reserved native lane; do not
ask a new resize to restart it. ACKing inspection does not retire the record.

In the final QNT `exitShell`, `joinShell`, and `cleanup` remain enabled after
oldResume in stable/retained phases. The blocked-join positive now requires
worker3's actual cleanup, in addition to retained worker2 and old GC/request
service. `initStopJoinLaneAfterResume` restores the bad phase restriction and
must produce a temporal counterexample while preserving safety. This is the
additional native pause test: freeze worker2's join, leave ABORT before worker3
joins, then require worker3's same-key join0+cleanup without another resize.

The model abstracts the independent lane's scheduling. The native test must
show a real lane/owner, not rename a P0 blocking join loop or assume a stable
service callback can finish a permanently blocking pthread_join synchronously.

## Non-negotiable commit-to-GO implementation condition

Count commit cannot be followed by a fallible operation whose failure leaves a
new counted worker permanently in WAIT. In the model `publishGo` is an enabled,
non-failing same-key predicate publication; fairness of this step is an explicit
assumption, not proof that a condvar notification works.

Implement the decision predicate in preallocated native control with release/
acquire atomics and immutable payload. Publish GO by an infallible store after
common count/scan commit; notification is advisory. The shell checks that
predicate outside the condition-variable mutex before/after its bounded native
wait and on every wait error. Reuse the independent bounded-return discipline;
do not require a broken notification to deliver the decision. The absolute
precommit preparation deadline is never restarted. After commit, a deadline or
wait error cannot change GO into ABORT. Keep control pinned throughout.

Inject notification failure specifically between count commit and GO observation:
the worker must observe the predicate independently and join startup, or report
a retained active fault. If a counted member cannot reach any collective-safe
point, a Scheme fault coordinator that performs GC cannot by itself guarantee
termination: it would wait for that member. Require a checked **native terminal
failure disposition without Scheme allocation/GC** in that case, retain every
root/handle/VM pin for the real last consumers, and report failure to the owning
host/process. Do not claim healthy VM recovery or safe destruction of a stuck
OS thread. The existing fault coordinator may do Scheme cleanup only when the
cohort's participation condition actually holds. This condition must be tested
before admitting the implementation, not hidden as a new fairness assumption.

## Concrete traced-carrier insertion point

In the bound producer `mem.c:7221 mark_vm_scmobj` marks exactly `___VM_SIZE`
words of the actual VM Scheme body; `include/gambit.h.in:6539` defines size20.
`_thread#.scm:2161` and its alternate definition at4174 both describe that layout.
Add a named traced growth/retirement carrier field consistently to both VM
representations, constructors, field offsets, VM_SIZE, generated header and
Scheme-generated C. Do not overwrite unused-field2: it is already used by the
fault coordinator in this experiment. Keep native ownership/key/cursor data
outside the traced Scheme payload; a malloc descriptor is not itself a root.

Lease acquisition does not root a raw SCMOBJ. Before any allocating, waiting or
GC-capable request path, the Scheme argument/request/thunk must be in that VM
carrier or a valid mapped caller frame; after transfer, queue/active handler or
mapped startup frame becomes the traced owner. The leased publish helper accepts
an already rooted payload reference, resolves its current value only at a safe
point, then performs nonallocating queue publication under the existing queue
lock. Native procedural payloads containing Scheme values need an explicit
traced/RC owner; a `void*` cast is not sufficient. Preserve that caller owner on
all typed rejection paths. Native test acceptance requires generated frame-map
inspection and a moving-GC test at these boundaries; QNT's carrier boolean is
only the protocol obligation.

## Current source observation overrides helper-presence assumptions

The initial precheck found eight files different from the previous manifest;
the later saved per-file observation contains nine, including generated _thread.c.
At the first precheck GSI still matched7263fe03, but the later saved observation
records replacement SHA c65582f4ee491eaa4bcc7d40562b02a7b9116f40f21f93a4cc1ced7fa5c713ac. Read-only per-file forensic copies
are retained in audit `bad1e9aa8d7d47e2a1304a6225f6f2ae`, output
`integrated-growth-source-observation`. Its receipt explicitly does **not** certify
a coherent source generation or bind those files to the executable. We did not
modify, lock, compile, signal or operate the producer. Historical identities stay
intact. Table names describe required protocol obligations; NEW must not be read
as asserting that similarly named experimental helpers are absent now.

The saved observation permits these narrower, actionable conclusions:

| Observed source | Established fact / classification | Concrete integrator action |
|---|---|---|
| `setup.c:1439–1509 ___vm_resize_pstate` | Integration is incomplete: growth still calls monolithic setup, publishes count, then creates OS threads with fatal failure. No staged shell call path is wired here. | Replace that actual branch with the ordered native-prefix→PARKED→private build→common commit→GO→READY sequence. Helper-only native tests cannot certify it. |
| `setup.c:395 request_open_slot`, `setup_interrupts_pstate:736` | OPEN is still returned from interrupt setup, before staged Scheme READY; slot phase/ps/vms publication is outside `slot->mut`. | Split initialized/CLOSED from READY/OPEN; serialize phase and identity publication with the same mutex used by acquire/close, and publish exact startup key after Scheme READY. Do not turn `slot->ready` (mutex initialized) into Scheme readiness. |
| `mem.c:3418–3423 ___init_empty_pstate_from_sections` | Helper validation gap: the loop succeeds when either stack or heap matches any reserved node, so a reserved stack plus foreign heap passes this test. No consumed-node/view uniqueness mask prevents pair reuse. This is a source-level input-validation defect, not an observed crash. | Independently locate/check both nodes; require distinct unused indices; reject duplicate pstate/view before any writes; mark both indices used only after successful validation. Native rejection must leave views/nviews/used-mask unchanged. New integrated negatives `initForeignHeapNode` and `initReusedSectionPair` make these preconditions explicit. |
| `setup.c:457/494 ___pstate_request_acquire[_current]` | Helpful partial implementation: OPEN/key validation and producer pin are under one mutex. Current-slot acquisition deliberately chooses the current incarnation; it is not authority for an old external incarnation. | Keep exact-key acquisition for external retained work; define CURRENT only for route recheck under a valid live VM capability. OPEN must mean exact Scheme READY first. |
| `setup.c:632 ___raise_high_level_interrupt_pstate` | Raw void compatibility path remains: a failed acquire increments a counter and silently returns. It is not a typed denial or primary-request disposition. | Migrate supported exports/clients or explicitly forbid this API at admission; do not certify an unleased compatibility path as equivalent to checked entry. |
| `_kernel.scm:1522`, `_thread.scm:1399/1430` | Checked adapter returns status and the first hint refusal rechecks routing. The running-target forwarding call in wake still does not consume the forwarded hint's failure status. | Give every failed forwarding attempt a durable rooted route debt or checked terminal disposition, not only the initial propagation attempt. Keep the primary request exactly once. |
| `mem.c:3297/3385 private_pstate_generation` | Conditional multi-VM gap: process-global non-atomic increment is only under each VM's own ALLOC lock, which is not a shared inter-VM lock. It also lacks explicit exhaustion refusal. No current native multi-VM failure is claimed. | Use a VM-owned nonwrapping transaction counter under its own admission discipline (full VM instance key prevents cross-VM ABA), or an actually shared atomic checked counter. Validate exhaustion before accepting work. Test two VMs only where the existing configuration supports them. |

These observations strengthen the verdict: the proposal has an executable finite
protocol, but the saved source is **not yet an integrated runtime implementation**.
Do not call it a completed source-bound producer or infer its behavior from the
historical old GSI. The replacement executable has no native acceptance here. Native test additions must include both invalid constructor
inputs and repeated pair/view reuse, plus early-OPEN races at the real setup path.


## User-reported build failure and acceptance prerequisite

The user subsequently confirms that the private reservation/leased admission
helpers were compiled into this producer, the old7263fe03 executable was
overwritten without a same-hash copy in the tree, and the new executable exits71.
The reported link attempt used gcc-16, first missed libSystem symbols, then added
`-undefined dynamic_lookup`; debugger entry often did not reach setup_base_module.
These are attributed human observations, not tests executed by this audit. The
saved observation independently establishes changed source and GSI bytes, not
the origin of exit71. Runtime and build configuration are not repaired here.

Grok must first restore a correctly bound, normally starting executable under
the existing task build workflow and record actual compiler/linker flags. A new
dynamic-lookup flag is configuration drift and cannot inherit an old seal or the
old39 checks. Before growth fault controls, require a supervised minimal native
startup/exit0 receipt on the new source-bound executable; exit71 blocks that
prerequisite. Then run the paused real growth path and targeted regressions.
No prior test result is transferred merely because the producer directory name
is unchanged. Old executable absence is recorded as user-reported, not inferred
from a broad cache scan. Lifecycle landing/finalize/scan-domain/generated-root
changes remain separate incomplete work; the formal errno gate remains8/12.

An initial evidence publication attempt (audit
bcfc27af46ce478ba4403070d82f00f8) stopped before publishing artifacts because it
incorrectly expected the captured GSI to match the historical SHA. That failed
audit is retained. Normal audit resume reconciles only this chat's metadata;
source observations and the user report correct the identity assumption. No
model rerun is needed for a provenance-only correction.

A second publication guard (audit0ca2379635564b1b87ffd3a3f12edc32) retained a
failed assertion that the drift count remained8. The saved observation actually
contains9 changed files, including regenerated _thread.c. Final publication
derives drift directly from saved rows; it assumes neither a coherent live tree
nor a fixed mutation count. Both failed metadata audits are preserved and
reconciled using normal audit resume, with no production takeover.


## Executed model evidence

Final integrated model: **30/30 expected controls**,9 safety/conditional-progress
scenarios,18 distinguishing invariant counterexamples and3 temporal
loop/stutter counterexamples. Quint0.33.0/TLC; every executed case below the
unchanged30-second cap. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/93375c6a60ea468297705dbebe4a619f/outputs/integrated-growth-model/receipt.json`.

The first26-control integration receipt remains at
`.cache/tasks/repair-9-12/processes/audit/runs/219ebc3392ea41d4922cc49cbac908ff/outputs/integrated-growth-model/receipt.json`.
It passed its controls but was superseded after review separated transaction
carrier release from native-control reclamation and added post-GO startup failure. A second27-control receipt17b2aca61c7141a79de647fca00b0fcf
was superseded when review required worker3 cleanup after oldResume despite
blocked worker2; all30 final cases reran. A third28-case receipt88f9a7ffaf6340f5ab232e7b06d9fae6 was superseded when
current source observation motivated foreign-node and reused-pair negatives.
All30 cases reran on the final model. No prior run is reused as final verification.

Positive initializers: success; create prefix failure; partial private views;
blocked join retention; native close failure retention; held publisher retention;
ABORT/retry epoch2; original gate deadline; post-GO Scheme startup failure.
Repeated GC can occur during shell staging/startup and old recovery. Two
publishers overlap close/publication/wake completion; stale epoch1 request is
denied before refresh in epoch2. Demands arriving after a cut are not ACKed by
that cut.

Negative initializers: early OPEN, pre-GO TLS bind, eager allocator mutation, GC
during private construction, native control free before actual join, dropping
primary debt on hint denial, check-then-pin, revoking old grant, forgetting queue
or wake consumers, retained-slot reuse, stale GO, resetting service debt, stale
thunk, post-GO rollback and ACKing unseen debt, a foreign heap node accepted because only stack matches,
and repeated reserved-pair reuse. The verifier checks decoded
fields for each intended failure, not just the existence of an arbitrary trace.
Temporal negatives preserve safety: no park deadline can stall preparation; a
retained native join error does not imply eventual successful growth; stopping
join/cleanup service after oldResume can starve an otherwise reclaimable worker.

Fairness assumes each enabled supported action is eventually scheduled. It does
not supply an OS/callback completion guarantee or a latency bound. The native
checklist must verify the original deadline and the implementation's concrete
service window; finite action fairness cannot establish production performance.


## Exit71 attribution resolved by supplied native trace

Read bootstrap-admission-regression.md/json. The user-supplied machine trace and
saved C agree: early P0 slot initialization reads null ps->vmstate before later
___setup_pstate binds it, computes an invalid id and returns IMPL_LIMIT_ERR, which
main maps to71. This is distinct from the preceding unresolved-symbol link
failure. Fix explicit bootstrap identity/native prepare CLOSED and READY→OPEN
separately; a null→slot0 fallback is unsafe. Added focused startup/failure-prefix/
identity tests to the handoff; none executed here. Existing30 QNT controls do
not cover this concrete bootstrap precondition and were not rerun unchanged.


## Bootstrap prefix is now executable in the unified model

See bootstrap-unified-protocol.md for function/field/native acceptance order.
The new53-case receipt reruns every old growth scenario after actual modeled
bootstrap CLOSED→Scheme READY→OPEN. It covers live/retained repeat refusal,
initialization cleanup, completed-teardown retry, failed OPEN and original-return
root retention, with optional abstract GC there. Worker READY is not a P0 hook:
the observed target>0 dispatch would skip P0. This remains finite protocol
evidence, without runtime changes or new native acceptance.
