# Destruction callers, asynchronous handoffs, and generated-root tails

2026-10-23. Evidence-only follow-up to `admission-lifetime-aba.md`.
No runtime/qualifier/history change, native execution, peer operation, commit or
push. Formal count remains 8/12.

## Independent finding: the destructor must not create new VM work

The unified gate is necessary, but calling today's generic destructors after
DRAINING,0 is not sufficient. `free_still_objs` clears the published list before
calling arbitrary `___release_foreign`, then frees the block without handling its
returned status. `___release_foreign` clears the function/pointer before invoking
the callback. A callback can require VM context, produce work, fail or escape;
it cannot safely reacquire OPEN admission after DESTROYING. Retrying the wrapper
is not retrying the original callback because its pointer is already consumed.

**Required change:** prepare/detach callback work under a live parent capability
and an actual traced carrier before hiding the original root. Execute callbacks
at a supported unlocked Scheme/native context, with explicit error/escape
landing. Retain per-item invocation/result state. Only after callbacks and queued
work have drained may a ticket authorize empty native destruction. An unresolved
callback retains its resources; arbitrary callback termination is not proved.
This extends the previous proposal rather than asserting that fences or a zero
counter alone solve it.

## Source set and what “all callers” means

`async-destruction-callers.json` binds 19 immutable files (18 selected runtime files plus the older matching generated-boundary header) and a lexical
occurrence inventory, including direct calls, definitions/declarations and
function-table assignments. Latest saved setup/mem/header bytes are from
4b8ae711; saved c_intf, generated _thread and Scheme _thread are from 9a03f325;
remaining OS/kernel wrappers are from bad1e9aa. Each file has its own SHA. These
are intentionally NOT represented as one coherent build generation. The
inventory includes inactive branches/comments; it is not an AST call graph or
proof about every configured runtime file or external embedding program.

No inspected exported/raw route is exempt merely because its normal caller is
checked. Final source admission needs the same inventory regenerated against the
coherent producer, plus configured/preprocessed call sites, function-table
exports and host entry declarations. Out-of-set callers remain an explicit gate,
not a silently closed coverage claim.

## Caller-by-caller funnel and required authority

Line references use the selected immutable file named in the inventory.

| Call site / caller | Destroyed or borrowed thing | Required implementation and result propagation |
|---|---|---|
| setup.c shrink worker :2115–2120 | interrupt nodes, markers, OS pstate | resource pin before marker retirement already present; prepare callbacks before this branch; pin covers OS cleanup and nonreturning thread tail; actual join0 is still required |
| resize growth failure :2138/:2151 | successfully initialized growth prefix | constructor authority only if no worker/queue/root publication escaped; carry initialized mask and retain debt on failed cleanup; target count rollback is not proof of private ownership |
| setup_os_and_mem_pstate :6181; VM :6208; global :6229 | partial native setup prefix | checked private-prefix destroy; once publication occurs, private abort forbidden |
| cleanup_failed_pstate :6292 | interrupts/memory/actlog prefix | same private-vs-published distinction; explicit completion mask/status through setup error return |
| setup_vmstate_body :6692/:6693/:6696 | mem abort, OS VM, P0 interrupt resources | constructor ticket before first free; preserve staged worker/borrow debt; no use of processor_count0 as publication proof |
| cleanup_owned_vmstate :6564/:6565 | P0 then VM | one exact VM generation destructor ticket for both; if P0 refuses/partially fails, do not call next destructor or return NO_ERR |
| cleanup_vmstate :6513 -> cleanup_vmstate_locked :6490–6498 | per-slot sync/interrupt then VM mem/OS/actlog | exported checked entry acquires ticket; private inner helper requires it; VM registry lock alone does not drain callbacks/readers |
| cleanup_checked :6763/:6770/:6774/:6778 | interrupt admission, global IO, P0 prefix, globals | seal/drain preparation first; global shared IO requires aggregate ownership; zero-count setup path still needs constructor/global tickets |
| cleanup_checked :6844/:6848/:6852/:6867/:6876/:6877 | IO, P0, each VM and globals | transaction completion masks prevent nested P0 teardown repetition; an inner void refusal cannot be consumed as success |
| ___cleanup :6886; cleanup_and_exit_process :6901; main :8483 | public terminal/checked cleanup | preserve exact failure and retained state; unknown shared lock uses independent terminal policy, not an arbitrary host fatal callback |
| ___GSTATE function table :7965–7989 | exported cleanup, cleanup_and_exit, cleanup_vmstate, cleanup_pstate | every external entry needs checked authority; ABI-compatible void wrapper must fail closed according to explicit embedding policy, not silently skip and let caller free storage |
| cleanup_interrupts_pstate :1473; release_procedural_interrupt :267 | queued native procedure nodes | `execute_fn(intr,FAL)` is real callback code; extract rooted/capability-owned work under lock, execute outside lock, save next in stable owned state; do not assume no allocation/escape |
| cleanup_interrupt_resources_pstate :1500 | request slot / procedure mutex | close+producer check+CLOSED under same protocol; no lock-external count test; preserve readiness and descriptor on destroy failure |
| mem.c cleanup_mem_pstate :6225 -> free_still_objs :4844 / cleanup_rc :691 | still/foreign and RC payload | published path requires completed callback preparation and drained scan/RC ownership; use empty checked native destroy, not hidden callback invocation |
| cleanup_mem_vmstate :6243 -> P0 mem :6269 / sections / VM list / tables | VM allocator and P0 | completed-subresource mask: P0 already cleaned by caller must not be assumed safe to repeat; no free of backing that retained child still accesses |
| abort_mem_vmstate :5346 | sections/table/synchronization prefix | private constructor only; never export as a shortcut around published VM close/drain |
| OS adapters: os_setup.c :3146/:3164/:3226–3233 | pstate IO pipe, VM OS, global modules | thread tickets/masks through OS layer; old `___cleanup_io_module` discards checked status; global destructor must consume checked result |
| os_io.c cleanup_io_pstate :12177 | abort pipe / Win32 event | writer/selector grace plus checked OS close; Win32 ignored CloseHandle failure is not covered by Darwin evidence |
| os_io.c cleanup_io_module_checked :12312; void :12336 | device group and module state | checked failure keeps module/resources; void alias must not erase failure before enclosing OS/global teardown |
| retirement_destroy_empty / retirement_reclaim, mem.c :5820/:5800 | joined empty donor and resource pin | finalizer service/metadata-reader unit survives resource pin release; reclaim_complete alone cannot authorize entry reset or VM destruction |

These are exact reviewed families; no instruction here authorizes editing runtime.
The JSON retains the individual occurrence locations so Grok can re-audit the
actual call sites instead of relying on this family summary alone.

## Asynchronous handoff and last-access audit

| Actual path | Existing observed last accesses | Required capability chain |
|---|---|---|
| ___raise_high_level_interrupt_pstate :1247 / ___raise_procedural_interrupt_pstate :1469 | leased publish, release, then immediate void return; no subsequent ps dereference at these wrapper tails | producer unit -> queue-owned unit/root before publication; keep sender unit until publish result and last ps use. Current void wrappers discard publish/release statuses; failure must preserve caller/queue ownership |
| publish_procedural_node :1400ff | unlock then raise OTHER through ps | queue unit is established before visible enqueue; producer unit covers post-unlock raise and abort syscall; hint is not the request's owner |
| ___pstate_request_release :1190 | producer decrement, clear caller lease, unlock stable request slot, return | stable slot mutex/control must outlive VM; do not move that mutex into freed VM storage. Never clear a mismatched key as successful release or decrement a newer generation |
| setup_entry_release :1054 | decrement under global guard then guard unlock; no later VM dereference in helper | global control lock survives VM; caller's full tail still needs outer owner when it executes VM code after helper return |
| ___setup_p0_ready_current :4883ff | helper borrow decremented, guard unlocked, scalar status returned | helper borrows are temporary; outer run/setup capability remains across generated reload, status branch and return/unwind |
| c_intf retire_marker_entry :6528ff | releases optional setup context reader; writes marker, drops still ref; decrements ps marker count then frees native entry | context-reader release is not final VM release. Outer caller/donor resource pin covers remaining marker/ps accesses. No raw movable root in entry; still marker external ref remains through its last use |
| ___retire_sfun_stack_markers :6544ff | after all markers retire, reads VM fault errno and processor id for stderr | confirmed post-marker-zero VM access, covered only by independently held donor resource pin/native tail; logging before final unit release, or copy scalar diagnostics first |
| ___run :4649ff / kill_sfun_stack_marker :6703ff | END_TRY then kill live marker, then return scalar err | exact original owner marker finalizer; run/setup caller retains lifetime until final native tail. Returning to generated/Scheme code is still live execution, not VM grace |
| device_select_with_cap, os_io.c :1602ff | device select returns, wake_selectors decremented, then scalar result returned | no direct post-decrement VM use here. Caller/device/out-pointer lifetimes can extend beyond this wrapper; acquire from live parent before reading PSTATE, retain outer owner through caller processing |
| device_select_abort :1643ff | read/write fd, publish saved fault scalar, then wake_writers decrement; POSIX tail does not then dereference VM | separate counter begins AFTER ps->vmstate dereference: requires preexisting VM capability. Fault publication creates persistent coordinator work which must inherit a unit; writer count0 is not fault-work completion |
| retirement_service :6088ff -> destroy_empty/reclaim | resource pin drops only at reclaim, returns scalar; surrounding sync code continues to access vms/ps and publish common result | selected service/collective parent unit before entry selection through last result/ACK/native access; not a new borrow after pin reaches0 |

No proven post-release UAF is inferred just from these calls. The observed
post-marker accesses are real; whether they are safe depends on the independent
pin/owner that current model assumptions require. This distinction is material.

## Generated C root coverage: evidence is stronger, but scoped

9a03 generated `_thread.c:22313–22329` executes W_ALL -> scalar READY call ->
R_ALL -> R1 status -> success return or no-cleanup error call. Its startup label
descriptors at :31131–31144 contain RETI(4,0,0x3f1) followed by RETN(1,0,0x1).
The matching saved header defines W_ALL/R_ALL at :6816–6817 and W_FP at :7005;
GC_SAVE/RESTORE at :8073ff update selected saved slots. This supersedes the older
bad1 snapshot's “READY absent” observation for these newer generated bytes only.
It is not evidence that an archive or gsi contains these bytes.

Existing guarantees: actual spill/reload statements, compiler continuation
labels, scalar result and rooted primordial/fault-control VM fields. Required
restriction: READY stays nonallocating/no-GC/no-callback/no-Scheme-throw under
native locks. W_ALL does not root arbitrary C locals, provide a GC-capable new
frame, or retain VM lifetime after its owner drops. A new callback-preparation
landing must be generated with its own actual maps; do not reuse READY's map.
Nested helpers cannot overwrite another helper's fixed GC_SAVE slots. Heap
pointers must be read back from actual traced carriers after each moving GC;
raw cached SCMOBJ/body addresses cannot survive merely because a native unit is
held. Register/root coverage, VM lifetime and native descriptor lifetime are
three different proofs.

## Concrete Grok edit order and admission checks

1. Stable VM control/token helpers and one packed gate, with checked overflow,
   nonwrapping full keys and actual target lock-free primitive. Every existing
   embedding entry must either take a token or prove a live parent; no unchecked
   alias. First compile only targeted objects and bind exact source identity.
2. Change request acquisition/publish/release and queue disposal together:
   producer -> queue -> executing/escape-result -> final consumer, no zero gap;
   checked status through void compatibility boundaries. Move procedural
   disposal callbacks out of native mutex, with exactly-one invocation state.
3. Add rooted cleanup preparation landing for still/foreign/device work BEFORE
   terminal close/drain. Migrate free_still_objs callers; checked error return
   retains root/pin and pending suffix. Closing may stop new external roots, but
   authorized child work must still derive from its live parent while draining.
   Recursive callbacks produce new recorded debt, never reopen root admission.
4. Pass constructor or exclusive destructor tickets and monotone masks through
   setup.c -> mem.c -> os_setup.c -> os_io.c. Only empty native destructors after
   DESTROYING. Distinguish private failure, published failure and uncertain lock.
   Use resource masks to avoid repeated P0/free/callback after partial success.
5. Keep outer run/setup and collective service units through final reload,
   Scheme status branch, common result and last logging access. Changes in
   _thread.scm must regenerate _thread.c/actual descriptors, not patch maps.
6. Before native admission, produce full configured/preprocessed call/export
   inventory and resolve every unclassified raw/host caller. A lexical match
   count is discovery evidence, not permission to treat a caller as safe.

Focused native validation sequence on ONE final producer (existing caps):

A. p1/p11 startup and READY failure/normal return: pause after helper decrement,
   before R_ALL, before no-cleanup branch; cleanup remains denied while outer
   owner is live. Record exact macros, maps and scalar status; force moving GC
   only at valid generated safepoints, not inside the no-GC helper.
B. queue publish paused before sender release; sender returns before thunk runs;
   callback escape and nested request; require one queue owner, one reply/result
   consumer and no early VM/entry reclamation. Pause after dequeue to check that
   handler ownership replaces queue ownership without a zero interval.
C. two real moving GCs while request/rooted cleanup job pending: updated actual
   marker/still/RC/carrier references, no raw cached body reuse; nested saves do
   not overwrite outer roots; retain error/suffix on escape.
D. callbacks on procedure disposal and foreign release with non-NO_ERR, supported
   escape, nested work and nonreturning control: no shared lock held, no double
   invocation, no hidden live root; nonreturning callback yields retained debt,
   not invented completion. Complete callback debt before final destructor.
E. pause after marker0/resource-pin release but before worker logging/collective
   ACK. Independent tail/service/outer unit must deny cleanup. Then real join0,
   one transfer and last reader grace; actual final release has no later VM use.
F. inject private prefix failure, pstate destructor busy/failure, nested P0
   cleanup and IO checked failure: caller does not continue/free or return
   success; masks record exact once; raw function-table aliases cannot bypass.
   Unknown shared-lock outcomes exercise independent terminal containment.
G. replay old VM/entry/full K at same address and after two epochs. Assert no
   new-generation decrement and no pointer read before validation. Repeat native
   focused cases before separately reviewed lifecycle campaigns. No unchanged
   full inventory rerun, timeout extension or fabricated errno.

Harness commands for new native pauses/faults do not yet exist in this research
patch; Grok must add them to the existing focused harness and retain source-bound
receipts. The executable model command is `PYTHONPATH=src python3
 evidence/research/smp-retirement-study/verify-async-destruction.py` in audit.

## Combined model, negative controls and sufficiency

`async_destruction_composition.qnt` permits arbitrary interleaving of publication,
sender return, close, dequeue, callback result/escape, result consumption, caller
tail return and two moving-GC abstract relocations. Exact unit sum and root
version are derived invariants, not a preinitialized PASS flag. Destruction is
split into P0 and VM masks; duplicate P0 teardown is a negative transition.
Three candidate modes cover normal, escape and intentionally retained callback;
nine decoded negatives remove queue ownership, handler lifetime, caller tail,
GC writeback, unlocked callback, last-use discipline, destructor idempotence,
escape ownership or callback-free terminal destruction.

This is a new concurrent boundary composition, not the serial 15-state normal
path in the preceding token model. It still assumes valid token/full K from that
refinement and single-VM abstract moving roots; it does not merge every earlier
QNT, execute C memory operations, validate real frame maps or prove callbacks
terminate. Safety can hold indefinitely by retaining a blocked callback's unit.
Final completion additionally needs returning callbacks, fair service scheduling,
actual join0, bounded OS operations and no unresolved shared fault. Lock-free is
not wait-free: CAS retry starvation and compiler LL/SC loops need explicit
progress assumptions; cohort acquisition uses bounded attempts/common DEFER,
never an unbounded blocking fallback. Final release cannot be silently dropped
on a failed try; retain a release obligation under a stable parent until discharged.

My judgment: implementation is now specified beyond the gate itself, but source
and native closure is NOT established. The newly explicit callback-preparation
stage, full caller/export audit, enclosing tail ownership and source-bound moving
root tests are mandatory, not optional optimizations. No current evidence permits
calling this 9/12 or complete native acceptance.


## Tree-wide symbol audit supplement

A separate read-only c86 source-tree query includes hidden/ignored C, header/template and Scheme files: 1571 files, 9 matching files for the nine top-level VM/pstate/memory cleanup symbols. The JSON points to the registered audit source-observation containing every scanned file hash and immutable copies of all matches. File set and every file hash were rechecked after scanning. No source was modified, no peer process inspected/controlled; these bytes are not promoted to a coherent producer or native result.

Additional actual call sites: lib/main.c:1363, tests/client.c:85 and examples/pthread/pthread.c:129 call ___cleanup directly. The main path, C-client sample and pthread embedding sample all need the checked public cleanup/terminal policy. An embedding wrapper must not let its host free VM/native backing after a void cleanup refusal. Tests must cover this exported route, not only internal cleanup_checked. This supersedes the selected-file limitation for the named-symbol search only; configured aliases, arbitrary function-pointer dispatch and tree-external embedding code still require review. No runtime change is authorized/applied here.


## Preparation follow-through

See callback-preparation-protocol.md/.json: the existing device-specific helper is present and reusable under its narrower contract. Generic callbacks require typed nested jobs and an explicit callback/context ABI; pointer clearing before invocation forbids generic replay after error. Sweep callbacks and raw generated foreign-release bridges require separate treatment. The new model includes nested escape/unknown retention and a partial-destructor forward retry, without claiming native closure.
