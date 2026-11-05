# Recurrent GC progress and independent donor join ownership

2026-10-23. Proposed C protocol and executable QNT evidence only. No runtime,
observer, recipe, milestone, native program or other thread is changed. The
c86dff86 experimental producer and gsi7263fe03 identities are bound in the JSON.
The count remains8/12. The inactive pending-contract proposal still needs review.

## Independent judgment

The prior 'give GC higher priority than finalize' rule is insufficient. The
prior 'one blocking reaper per VM' rule is also insufficient if one donor can
remain alive forever. Neither problem is repaired by stronger global fairness:
a request that is never enabled cannot benefit from weak fairness, and a join
that never returns cannot serve the next job in a serial queue.

Use a **mandatory post-GC native service window** and **one pre-reserved join
lane per accepted donor slot**. These mechanisms can establish conditional
per-donor progress without requiring all donors to finish. They do not establish
successful whole-VM teardown when one accepted worker never exits. This is an
unavoidable distinction, not a condition to hide in a passing receipt.

## 1. Recurrent GC: service inside the completed collective

Actual anchors: `setup.c:1231 execute_sync_op`, GC case1280,
`execute_sync_op_loop:1301`, `barrier_sync_op:703`, `service_sync_op:1417`,
`on_all_processors:1432`; `mem.c:7400 ___garbage_collect_pstate` ends with
`prepare_mem_pstate` and returns overflow near7546. The GC has several internal
barriers; its final local return is not by itself a new all-member fence.

Proposed helper: `___retirement_service_pstate(ps, origin)` in setup.c. Every
participant calls it at the following **fixed structural positions**:

1. In the selected OP_GARBAGE_COLLECT case, save that operation's GC result in
   its existing result slot, let ___garbage_collect_pstate return completely,
   then call the helper before returning to the outer operation loop. Add its
   own first barrier so every member has completed collector accounting and
   prepare_mem_pstate. Never insert it between mark/weak/cleanup barriers.
2. In a selected standalone OP_VM_RETIRE_SERVICE case for GC-quiet operation.
   Use the same helper, not a separate transfer path. It must also be explicitly
   requested/polled when a native completion becomes persistent; an abort-byte
   hint is insufficient. At lock-free safepoints/common sync boundaries, test
   the native pending-service indication. Preserve the original outer request
   if another operation wins the election.
3. Do not invoke the helper recursively from a callback, join, Scheme allocator
   or on_all_processors. Do not return to mutators between a completed GC and
   its service window. New GC requests remain latched for the next outer round.

The standalone priority can be **OP_MAKE(7,0)=28** in this bound table: priorities
0-6 and10 are occupied, and7 is unused. A proposed all-member validation guard
can use **OP_MAKE(8,COMBINING_AND)=33**, also unused. These are explicit proposed
allocations for review, not installed opcodes or proof that all future tables
are compatible. The post-GC service does not compete at priority7: it is a
mandatory epilogue of the already selected GC. This is what removes starvation.
Do not increase finalize priority above necessary GC to manufacture progress.

### Fixed service transcript

All members execute the same transcript, including when there is no candidate:

- P0 acquires native mailboxes and selects at most one eligible donor by a
  rotating cursor, skipping blocked joins, native errors and active borrowers.
  P0 publishes `(service sequence, lifecycle epoch, full donor key or EMPTY)`
  through barrier_sync_op; other participants submit NOOP. A short native
  registry lock may protect selection. No lock held by a join lane spans the
  OS join. A same-VM membership transaction in progress disables transfer for
  **all members through this common command**, not a local early return.
- All members validate command/key, stable membership, GC quiescence, completed
  join and borrower/scan grace. They execute the common AND guard. Empty and
  failed validation still take every required barrier. Any validation needing
  allocation, list repair, user code or an OS wait belongs before this window.
- P0 claims the exact entry, then performs only the prevalidated native splice,
  destination/accounting publication and pending-domain removal. Other members
  do not execute the destructive splice. They remain in the collective.
- P0 broadcasts `(service sequence, key, EMPTY/TRANSFERRED/RETAINED_ERROR)`;
  every participant checks the expected operation **and phase**, consumes the
  result and reaches the common end barrier. A result descriptor stays native,
  pinned and generation-bound until its final consumer. Do not interpret a
  different opcode's arg[0] as a successful result.
- Advance cursor on a rejected candidate too; retain its entry/error rather
  than blocking scanning of later entries. Preserve the original GC overflow
  result separately from retirement status. No Scheme throw occurs here.

The proposed guard/result operation numbers require a full switch/result
implementation and generated/native validation. Internal helper barriers use
fresh common descriptors; outstanding outer GC/finalize requests stay outside
this transcript. No independent new participant or unsupported external C
caller may enter this same-VM collective halfway through it. Existing startup
and post-___run/native contexts must be classified by the earlier landing plan.

### Why it progresses, and what it costs

For a donor that stays eligible, each completed GC supplies a service opportunity;
GC requests cannot consume that opportunity. With at mostN retained entries and
cursor advance/skip, at mostN completed service windows inspect that donor after
its persistent completion is visible. This is a bound on **windows**, not seconds.
If GC stops, an independently serviceable standalone request/safepoint must
supply windows. OS scheduler fairness and eventual completion of each entered
collective remain explicit assumptions. An infinite higher-priority fatal fault
or stopped participant does not satisfy them.

One donor per window bounds batch size, but the actual still-list splice in
`mem.c:5257 ___transfer_mem_pstate` walks to the tail. Its latency is O(still
objects), not constant. For a short window, prepare a checked `frozen_still_tail`
and counters before admission/commit, and keep pending-list topology frozen
through repeated GC (trace/reset marks without sweeping that frozen list).
Validate that invariant in collector code before using the tail. Otherwise keep
the existing traversal and measure the full pause; do not claim a hard latency
bound. Repeated GC also pays the collector cost of retained still/RC domains.

## 2. Independent native join lanes

Actual functions: `os_thread.c:493 ___thread_create`,548 ___thread_join and583
___thread_exit; the POSIX join wrapper calls blocking pthread_join and returns
an encoded actual result. There is no supported nonblocking join in this path.
Moving that call to a single FIFO helper merely relocates head-of-line blocking.

Proposed interfaces and fields:

| Location | Proposed interface/state | Required behavior |
|---|---|---|
| VM native control | `retirement_lanes`, `lane_capacity`, `vm_helper_pins` | Bounded native lane capacity; persistent helpers each retain a VM lifetime borrow |
| Donor entry | immutable `lane_id/lane_generation`, full donor key, join phase, native result, storage/root token | Lane assigned once before accepted retirement; original donor slot remains leased |
| Lane control | native command mailbox, helper OS identity, command generation, STOP state | Contains no untraced Scheme payload; lifetime separate from reclaimable donor storage |
| New `___retirement_reserve_lanes` | precommit capacity/create checks | Every accepted concurrent donor has an independent lane; insufficient capacity refuses before membership commit |
| New `___retirement_join_lane_main` | lane-local native loop | Claim -> one ___thread_join -> release-publish keyed actual result -> no further donor-storage access -> wait on persistent lane control |
| New `___retirement_consume_completions` | P0 acquire/CAS native results | Read every lane independently; no wait for lower-index donor or VM-global all-donors-done condition |

Reserve/register lanes before publication. Persistent one-per-slot helpers avoid
having to synchronously join an ephemeral helper on the P0 finalize path. A
lane whose target never exits remains blocked and retains its VM pin; it cannot
be cancelled, reassigned or used to justify clearing the donor lease. Other
lanes and per-donor finalize remain independent. A lane with actual join error
retains/poisons that donor; never convert it into pending or invent a join0.

For successful reuse, join0 remains latched, the helper's publication is its last
access to donor storage, and P0 must finish per-donor grace/transfer before the
same slot/lane accepts another generation. Waiting on lane control may continue
because that control is VM-owned, not the freed donor record. Mailbox reuse and
STOP need a separate command-generation handshake. Native lane publication uses
the previous release/acquire ownership protocol; it does not root Scheme values.

A finite pool smaller than the number of admitted simultaneous donors cannot
guarantee isolation against arbitrary permanently blocked donors. Assigning
multiple helpers from such a pool after commit is not a sufficient fallback.
This design pays up to O(admitted donor slots) native threads/stacks and pins.
A capacity limit therefore restricts admission; it is not a changed CPU/test
configuration. No helper has been created in this evidence task.

## 3. Per-donor failure and last consumers

| Situation | Ownership/result | What may still progress |
|---|---|---|
| A permanently blocked in join | A native handle/storage/carrier/scan domain and VM pin retained; slot not reusable | B's lane, completion and finalization; no all-donor gate |
| A joined but scan/queue borrower remains | A JoinedAwaitingGrace, no second join; root/native domains retained | B when B's own borrowers drain |
| A actual native join error | exact native result retained and separately labelled; no transfer | B, unless the actual error is classified as a VM-fatal fault |
| A preflight finalize validation fails | A retained before first destructive write; cursor advances | B; no rollback of a half-splice is assumed |
| Capacity/create failure before commit | no accepted retirement for the failed preparation; original cohort retained | Existing accepted generations; checked cleanup of any created helper prefix |
| VM cleanup while A/lane still live | refuse/retain VM, helpers and descriptors | Ongoing VM work if its public contract permits it; not successful teardown |

A VM helper lifetime pin is not a per-donor scan/borrower lease. Waiting for all
persistent helper pins before transferring B would recreate global blocking.
Conversely, B's join0 is not permission to free a VM still borrowed by A or a
persistent lane. Stop every idle helper and join it through its real owner only
at checked VM teardown; a blocked helper prevents successful teardown. The
current model does not prove this helper STOP/join protocol.

## 4. Safety and progress assumptions

Safety does not require workerA to exit, callback termination, eventual join0
or eventual GC silence. It does require correct same-generation claims, traced
roots, single scan ownership, valid C frame/entry context, GC-excluded transfer,
correct release/acquire, no memory corruption and actual participant compliance.
If a participant or callback stops, retain resources and deny success.

Per-donorB completion additionally requires B's own worker to exit, its native
join to return0, its lane and survivor to be scheduled, B's own borrowers to
finish, a serviceable collective and no endless VM-fatal interruption. It does
**not** require A to exit, A's lease to clear or GC to stop. Whole-epoch/VM
successful retirement requires those progress conditions for every involved
resource. Independent lanes cannot remove that requirement.

## 5. Model and remaining sufficiency gap

`models/gambit/retirement_progress.qnt` uses a toggling GC/request phase to allow
arbitrarily many repeated collections in finite-state cycles, rather than a
counter capped at one or two. Action-specific weak fairness is explicit; a
single weakFair(step) would not prove that a particular helper is scheduled.
Permanent blocked A, permanently retained A grace, join error and finalize
preflight failure are distinct scenarios. Positive properties ask for B's
completion or explicit retained error, not fictitious all-donor success.

Temporal negative controls cover strict-GC priority starvation, a serial reaper,
a VM-global grace gate and removal of scheduler assumptions. These require TLC
lasso/stutter evidence, not an invariant violation mislabeled as liveness proof.
Safety mutants cover shared owner, early root drop, freeing pinned VM, ignoring
scan lease and partial-transfer loss. The runner records classifications and
preserves the generic backend result when separately checking a temporal failure.

Independent verdict: this is a stronger candidate protocol for the two progress
holes, not sufficient evidence for an acceptable runtime patch or9/12. Still
needed: post-GC fixed-phase C/result implementation across every participating
entry; model-to-C root/domain/memory-order refinement; frozen-tail validity or
measured traversal latency; bounded lane startup and STOP/command-generation
recovery; native repeated-GC/block-one-donor fault tests on one completed producer;
and the separate formal contract review. No claim of native stability follows
from this model. Prior19 controls and39 targeted native rows remain independent.

### Measured evidence boundary and regression exposure

15/15 expected controls accepted:6 safety/conditional-progress scenarios,
4 temporal counterexamples with explicit loop/stutter and decoded states, and
5 safety counterexamples. Every executed case remained below the original30s
cap. Two initial model parse failures and the initial temporal-classification
failure remain preserved; the final receipt reclassifies the unchanged TLC logs,
with source log hashes, rather than rerunning or modifying them. No backend
implementation or qualification predicate was changed.

This design touches every selected GC's return path. A fixed transcript adds
collective barriers even when no donor is ready; scanning native mailboxes is
O(lane capacity), plus one donor's splice cost. An empty fast path is valid only
with a common synchronized epoch decision, not inconsistent local flag reads.
The native helper stack/thread cost is additional to mutator processors. Nothing
here proves the previous eight gates unaffected: startup/growth collectives,
GC overflow results, FFI/native return contexts, request/fault ownership and
checked teardown all require source-bound regressions. No native performance
measurement or complete release admission is claimed.

Reproduce model controls with:
`.venv/bin/python evidence/research/smp-retirement-study/verify-retirement-progress.py`
inside the registered audit workflow. The runner's `--reclassify RECEIPT` mode
only verifies/reclassifies retained raw model logs and does not execute TLC.

Final classified receipt: `.cache/tasks/repair-9-12/processes/audit/runs/3912e46fe71742d4959a9776efeb4afe/outputs/retirement-progress-reclassified/receipt.json`.
Original TLC receipt: `.cache/tasks/repair-9-12/processes/audit/runs/05601751de874ecebcee90b651bc8bd2/outputs/retirement-progress-model/receipt.json`.

### Direct resize-GC exception found during final source cross-check

`setup.c:1086 ___vm_resize_pstate` invokes ___garbage_collect_pstate directly
inside the resize heap guard. This bypasses the OP_GARBAGE_COLLECT handler and
runs with target heap/count assignment in progress. The candidate must not be
implemented as a global unconditional transfer hook at the collector return.

At direct resize-GC, keep a native service-debt token latched; do not transfer
pending native domains during the active membership transaction. Once the resize
has a stable surviving cohort and has completed startup/abort/result agreement,
request the normal service collective. Do not invoke a new barrier on the
assumption that every old/new member returns through the same outer-loop exit.
The lifecycle admission protocol must carry this debt across count/generation
changes and must not admit indefinitely many new resizes ahead of it. A proposed
`retirement_service_debt` / stable-cohort handoff prevents dropping this obligation,
but its actual C transition is not implemented or model-verified here.

The recurrent-GC model covers completed selected GCs with a stable participating
cohort. It does not model nested resize/count transactions. Its progress theorem
therefore additionally assumes lifecycle exclusion eventually releases to the
stable-cohort service path. Unbounded obstruction by startup/resize, stopped
participants or VM-fatal errors remains outside that theorem. The two-call-site
check covered setup.c, mem.c and c_intf.c of the bound producer; it is not a claim
that all possible foreign/generated entries have now been audited.
