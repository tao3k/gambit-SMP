# Activation roots, nonlocal escape and callback-free cleanup commit

2026-10-24. This is an implementation/acceptance handoff against `procedural-suffix.lock.json`, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` and cumulative patch6aca28e0. It is evidence-only work in this chat; Grok's later implementation must follow its own authorized custody. No runtime, qualifier, recipe or historical receipt is edited. Native acceptance and qualification remain unestablished/8/12.

## 1. Independent judgment: what the current code really provides

An independent activation can be made GC-visible using existing RC scanning, but the present source does **not** provide a ready-to-use concurrent activation API:

- Header defines RC header `prev,next,refcount,data`. `mem.c` allocates with `data=FAL` and registers into this processor's `rc_head_`. `mark_rc` scans **only `&h->data`**, rewriting it after relocation; strong-phase invokes that per processor. Arbitrary SCMOBJ words in native payload, `probe`, `act->result` or a native pin are not scanned automatically.
- `___addref_rc` is plain increment, `___release_rc` plain decrement plus intrusive unlink/free, `___set_data_rc` plain assignment. There is no internal lock or atomic publication. Adding a reference on a remote processor or unlinking from a GC reader is not supported by these helpers themselves. `cleanup_rc` frees all nodes regardless of refcount. A live RC reference cannot independently prevent VM teardown.
- `___GC_SAVE1/2/3` use the same `ps->saved[0..2]`; `mark_saved` scans them, but an inner marker allocation (`c_intf.c`) can overwrite/clear the outer saved slot. These are short helper temporaries, **not a nested activation stack**.
- Current `___run` makes a marker then calls `___call` and kills the marker inside the TRY body. A native throw from `___call` can bypass marker invalidation and be caught by END_TRY. Generated SFUN macros put marker kill and sfun leave after END_TRY, inside the successful marker-creation branch; that is a useful structural precedent, not proof that raw `___run` already has equivalent cleanup. The marker is a returnability object, not an activation ledger.
- Moving `cleanup_interrupts_pstate` callbacks outside its **own** mutex is insufficient. `___cleanup_pstate` and `___cleanup_vmstate` call destruction while holding `vm_list_mut`. Shrinking worker invokes interrupt cleanup **after** the target membership/count transition. A callback that reenters registry/Scheme/GC there can deadlock or use an excluded GC owner. These are concrete caller constraints on the proposal.

## 2. Concrete activation representation and publication order

Proposed fields are new implementation requirements, not existing names: per-owner `procedural_activation_top`, activation `{vm,slot,incarnation,parent,operation,phase,root_rc,callback_snapshot,outcome_disposition}` and closed/draining cleanup state. Each invocation, including nested invocation and false-op release, gets a distinct activation. Native IDs/context are separate from Scheme values.

Reuse one registered RC allocation per activation under its **current active processor owner**; `root_rc` header.data points to one Scheme carrier vector containing all required Scheme payload/parent references/outcome. A native-only callback can use FAL roots only under an explicit payload contract. Existing exported void/native publishers have no root-carrier argument: migrate known callers to a checked descriptor/entry or retain a documented, tested native-only embedding contract; unknown opaque callbacks cannot be certified to enter Scheme safely. Do not guess roots by scanning native bytes or change external header layout without ABI migration.

Publication sequence:

1. With valid VM/slot/incarnation borrow, no T/P/queue/registry locks, and mapped incoming Scheme roots, allocate/preinitialize the activation and carrier. Preallocation failure is a not-accepted return, caller retains payload. An already accepted queue item stays queued on prepare failure.
2. On the owning active processor, install carrier in registered `header.data` before publishing activation or detaching the queue item. There must be no GC/SYNC between capturing an unrooted incoming SCMOBJ and its installation; if preparation participates, reload the mapped incoming root after it. `alloc_rc_no_register` alone is not a root. The registration window must obey the same managed-owner/safepoint exclusion as the existing per-pstate RC list; an unmanaged host thread cannot perform it.
3. Transfer the queue unit into the rooted activation under queue mutex, snapshot the callback while the original header is valid, and detach one head. Unlock with a known successful status. Current callback may free its header; the activation may not be embedded solely in that header.
4. Before every Scheme entry and after every nested callback/GC, fetch the current carrier through `___data_rc`, then rederive interior pointers. Never use a cached pre-GC vector/body address or stale returned error value. Store Scheme-valued outcome in the scanned carrier before any participating settlement.
5. Completion publishes to the already responsible owner/consumer; it does not remotely call `___release_rc` or mutate a donor RC list. The actor that owns the RC list performs final unlink in a no-GC local interval after all native readers/scan readers and consumers have left. Until then the activation and VM/pstate generation remain pinned. No shrinking/removal of that owner is admitted unless its scanner domain has a separately implemented handoff; this handoff is **not** present in this lock. The immediate safe integration is pre-count-change refusal/defer while such activations exist.

Final release is **after** callback return/registered unwind settlement, last native header/context use, outcome consumption or verified target handoff, and relevant scan-reader grace. Unlink owner activation; copy any external release token needed afterward; clear data/unregister/free using owner discipline; then release that external token without touching the freed activation/VM fields. Order the last destruction pin so teardown cannot race with RC unlink. Neither callback return, queue head becoming empty, nor child completion is the last release point by itself.

This uses existing per-owner scanning instead of changing RC globally to atomic. If off-owner mutation is required, it needs a separately audited GC/list protocol; an atomic refcount alone does not protect intrusive links or `data` relocation.

## 3. Escape boundary and actual generated C obligations

At `service_procedural_interrupts_pstate`, a dispatch wrapper must install a resident native catcher **after queue unlock** and before calling the snapshot. Keep activation/catcher completion state outside autos whose modified values become indeterminate across setjmp/longjmp. A stable heap/RC-backed record is suitable; `volatile SCMOBJ` alone is not a scanned root.

Classify outcomes, preserving the existing API:

- Ordinary NO_ERR/non-NO_ERR: finalize current invocation once; non-NO_ERR already returns unlocked in the new patch; preserve shared suffix/OTHER retrip (`___service_interrupts_pstate`). It does not retry current callback or turn a Scheme exception into successful data.
- A throw caught by this registered invocation: first restore catcher/activation nesting, settle only frames actually crossed, preserve the original error in a covered location, then return/rethrow according to existing service/outer contract. Do not swallow a genuine throw as NO_ERR or double-finalize an inner activation.
- A registered escape crossing multiple activations: each crossed invocation's resident catcher settles or retains its own activation in order. A child whose continuation resumes inside the outer invocation does not release the parent. An arbitrary host longjmp bypassing all runtime catchers is unsupported: reject before acceptance when the API requires such support, or use declared terminal retention; do not fabricate completion after it.
- Callback state/partial native resource destruction unknown: retain activation, carrier, generation and current-item disposition. This is a terminal/pending resource state, not resumable release. Never rerun its execute_fn with FAL to “clean it again”.

The new source already returns ordinary callback errors while unlocked and snapshots execute_fn/self before detach; keep those changes. Its automatic C locals are not a persistent activation or scanned carrier.

Grok must repair raw `___run` with a successful-marker flag/handle in stable state, and put marker invalidation after END_TRY for normal and thrown paths. Do not use an automatic flag assigned after setjmp and then read after longjmp unless C rules make it valid. Do not kill an uncreated marker. Preserve `___err`; invalidate each successfully created marker once before the corresponding native frame returns/disappears. Internal trampoline/staged dispatch codes in `___call` are not all final exits: no activation/marker release at every loop iteration, retained early return, or caught internal dispatch by text substitution. Keep the existing staged returnability and sfun counts distinct. A cleanup that itself escapes is retained/terminal, not a successful ACK.

Current generated references `_thread.c`/`_kernel.c` are unadmitted source-package artifacts. The new producer must supply generated wrapper labels, frame bitmap/RA/register save before callback entry, nested SFUN conversion-error paths, post-call result rooting, native catcher scope and post-END_TRY marker cleanup. `W_ALL` preserves selected GVM registers; it neither scans C locals nor makes raw header payload a root. Use current header as the SFUN expansion specification and header for both setjmp and C++ configurations, then verify actual preprocessing/object code. Existing `saved[]` cannot hold the persistent outer carrier across nested entry.

## 4. Lock-outside cleanup and suffix ownership: callers must change too

Implement an internal checked preparation operation (proposed `prepare_interrupt_cleanup`) and a callback-free destruction commit. Preserve public ABI with an explicitly mapped refusal/terminal policy; a void cleanup must not silently report success and free resources on preparation failure.

Preparation runs while the owner is still active and scanned, before shrink membership change, with valid Scheme context if any release callback may enter Scheme. It closes publication under the same checked admission protocol, elects one cleanup consumer and transfers one item at a time into rooted activations. Queue mutex and `vm_list_mut` are both released before callbacks. Closed admission rejects new work with caller ownership; do not clear the queue to signal closed. Service already in flight either finishes under its own activation or leaves a retained activation; cleanup cannot also claim its detached item.

After each callback, reacquire the queue mutex and reload live head/tail. The suffix is the current shared queue, **not the saved pre-callback `next`**. Concurrent append before close remains owned by that queue; append after close must be rejected. A nested authorized consumer may consume it once; record that transfer instead of requiring a stale pointer to remain head. On ordinary error or escape retain the current disposition and untouched suffix; do not clear/destroy the mutex or free memory. No retry of unknown partial release.

The new patch's empty-queue cleanup branch sets `delivery_fault` on unlock failure but still returns NO_ERR. `cleanup_interrupt_resources_pstate` then conditionally destroys the mutex and clears ready without checking destroy success. Fix this to return a checked non-success/retained result; never let fault-marked emptiness authorize destruction. Also, the last detached item may have failed before being freed: a subsequent empty queue cannot certify its release. The independent retained activation must be included in the drained predicate. `delivery_fault` is a plain shared int in the new source: cross-owner fault publication/observation needs a defined atomic/synchronization path; do not treat it as the root/ownership ledger or infer a memory-order guarantee.

Only successful, drained preparation yields a once-consumed token bound to VM/slot/incarnation and queue/activation state. Under final destruction locks, revalidate closed admission, no live/retained activation, no writer/scan/host borrowers and correct epoch. Then commit may reset head/tail, destroy interrupt/sync resources and clean memory without callbacks/GC. Unknown mutex destruction result is retained, not ready=0.

Concrete call-site changes:

| Current call | Required split |
|---|---|
| shrink worker before OS exit/quiet | Do callback preparation while old cohort is active **before** resize commits count; busy/failed preparation uses common refusal. Post-commit worker tail may only consume a validated callback-free cleanup token. It cannot newly enter Scheme/GC. |
| `cleanup_pstate_locked`, public `___cleanup_pstate` | Preparation outside `vm_list_mut`; reacquire and revalidate for destruction-only `cleanup_pstate_locked`. A retained token cannot proceed to `cleanup_os_and_mem_pstate`. |
| `cleanup_failed_pstate` | Distinguish unpublished construction with no accepted items from a partially live slot. Never run arbitrary Scheme cleanup without a valid owner/context. Failure retains partial state or follows an explicit terminal path; no automatic free-after-void-return. |
| `cleanup_vmstate_locked`, public | Check activation debt before first sync resource cleanup; preparation before taking registry lock; revalidation and no-callback commit afterward. Existing sfun/join checks are necessary but not activation coverage. |
| `cleanup_interrupt_resources_pstate` and bootstrap/teardown callers | `cleanup_interrupts_pstate` success must precede mutex destroy and ready=0. Startup P0 may lack Scheme context: allow only proved native-only/no-GC release, otherwise refuse/retain; never invent a bridge from an uninitialized owner. |

A callback can block forever: this protocol retains roots and prevents unsafe destruction but does not prove eventual GC/cleanup completion for arbitrary host callbacks. In particular an active worker stuck in foreign code can still prevent collective GC. Require bounded/cooperative callbacks or separately validated staged-FFI parking and frozen scanner ownership. This lock does not supply a blanket proof of that cooperation; do not advertise general nonblocking cleanup merely because its mutex is released.

## 5. Same-producer native acceptance for Grok

Use one final regenerated GSI and bound callback fixture objects, no relink between controls; keep existing30s focused limits and flood limits. Bind source/header/ABI/codegen/maps/compiler/object/archive/GSI/UUID and each hook actually reached.

1. Two nested callbacks allocate and force moving GC. Check outer and child carrier identities/contents through `data_rc`; child exit leaves outer root and pin intact. Mutation negative: use `ps->saved[0]` for outer lifetime or put SCMOBJ only in native payload; detect lost/stale outer roots.
2. Callback throws through its own registered catcher, then through nested `___run`/generated SFUN conversion-error paths. Count successful marker creations/invalidation and activation settlement exactly once, preserving original error and untouched outer activations. Force marker allocation failure separately: no kill/leave on nonexistent marker. Inspect setjmp state preservation in actual object/configuration.
3. Self-free current header, then return error or enter Scheme/GC. Stable activation is still valid; no read of freed header. After GC, outcome is fetched from current carrier; a cached body/address negative must be detected. No remote addref/release of the RC list.
4. A→B, append C before close, close publication during A, reject D after close. A's partial release errors/escapes: B/C remain queued or have authenticated nested ownership; D remains caller-owned. No clearing suffix, re-executing A, resetting ready or freeing RC memory. Track request IDs/epochs/owner events, not just queue length.
5. Race service with cleanup and nested callback release. Exactly one consumer owns each detached item; cleanup callback sees neither queue mutex nor `vm_list_mut` held. Retained activation prevents shrink/count change, memory teardown and slot reuse. Negative: child releases outer pin, remote RC free, post-error destroy or stale drained-token commit; each must fail.
6. Exercise each concrete cleanup caller class above, including bootstrap failure without a Scheme context and retired worker tail. Verify that the actual production checked helper is linked; a fixture-local clone is not evidence. Ordinary callback error still retains OTHER/retrip and later consumes remaining suffix once under real service.

Receipts include activation/parent IDs, owner VM/slot/incarnation, actual RC scan address and relocation/writeback, frame/map ID, catcher crossing scope, marker lifecycle, callback RUN/RELEASE mode and result, close point and caller ownership on rejection, suffix consumers, native lock states, cleanup token/commit decisions, last header/context/root/pin access, exit/timeout/reaping. Native controls have not been run in this audit.

## Sufficiency boundary

This is a concrete implementation path: registered per-owner carrier, stable nested activation, resident-catcher settlement, successful-marker cleanup and prepare-before-membership-change/lock-free-callback cleanup. It reuses RC scanning but requires new activation debt and admission checks at every destructive caller. Leaving raw `___run`, unsynchronized remote RC mutation, or callbacks under registry/post-shrink cleanup unchanged breaks the argument. Models below validate conditional ownership/retention, not arbitrary host escape, callback termination, C frames or TFIB's cause. These conditions must be implemented and demonstrated on the same producer before claiming this path closed; they do not independently establish9/12.

## Current-lock coordinates and verification

The new patch is byte-verified against all26 locked candidate hashes. Its `setup.o` compile is user-reported; no final GSI or native activation execution is admitted by this audit. Exact coordinates below supersede old scan-lock coordinates.

| Function | Current source |
|---|---|
| `service_procedural_interrupts_pstate` | `lib/setup.c:407` |
| `cleanup_interrupts_pstate` | `lib/setup.c:667` |
| `cleanup_interrupt_resources_pstate` | `lib/setup.c:714` |
| `___call` | `lib/setup.c:4413` |
| `___run` | `lib/setup.c:4622` |
| `cleanup_pstate_locked` | `lib/setup.c:5929` |
| `___cleanup_pstate` | `lib/setup.c:5938` |
| `cleanup_failed_pstate` | `lib/setup.c:5957` |
| `cleanup_vmstate_locked` | `lib/setup.c:6119` |
| `___cleanup_vmstate` | `lib/setup.c:6143` |
| `setup_rc` | `lib/mem.c:707` |
| `cleanup_rc` | `lib/mem.c:718` |
| `___alloc_rc_no_register` | `lib/mem.c:737` |
| `___register_rc` | `lib/mem.c:757` |
| `___alloc_rc` | `lib/mem.c:777` |
| `___release_rc` | `lib/mem.c:794` |
| `___addref_rc` | `lib/mem.c:817` |
| `___data_rc` | `lib/mem.c:840` |
| `___set_data_rc` | `lib/mem.c:850` |
| `mark_rc` | `lib/mem.c:4926` |
| `mark_saved` | `lib/mem.c:7756` |
| `garbage_collect_mark_strong_phase` | `lib/mem.c:8084` |
| `___make_sfun_stack_marker` | `lib/c_intf.c:6514` |
| `___kill_sfun_stack_marker` | `lib/c_intf.c:6560` |

Sixteen new QNT controls matched expectations:4 safety,8 decoded mutant counterexamples and4 positive reachability; unchanged30s case caps. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/d1b77c4b5f324ad9971cf6fc54d7088d/outputs/activation-roots-cleanup/receipt.json`. The run began before the procedural-suffix update using prior scan-lock identity; this document separately audits correspondence to the new lock. No runtime-source refinement follows from that model. The initial compile failure is retained and not counted as a native/semantic negative. The model represents nested parent/child roots, one GC relocation, concurrent pre-close append, locked-callback/opaque-root/early-parent-release/stale-carrier/retained-destroy/remote-release negatives; it does not prove marker code, ABI, arbitrary host longjmp, FIFO, C memory ordering or callback termination.

Additional current source defect: `cleanup_pstate_locked5934` and `cleanup_failed_pstate5972` discard the checked callback cleanup result and may continue OS/memory cleanup. Propagate failure to every destructive caller, not only `cleanup_interrupt_resources_pstate`. Empty cleanup unlock failure693 still returns NO_ERR694; destroy723 is unchecked before ready=0 at724. These source findings require implementation and targeted native tests.
