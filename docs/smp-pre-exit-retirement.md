# Join failure before OS exit: source chain, root frontier and bounded repair

2026-10-22. Work item repair-9-12, audit role. Research only. Cumulative status 8/12.

## Source identity and claim boundary

This study reads pinned Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882 plus the retained `handler-quiet-while-pending-cumulative.patch` (SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7). B means baseline file/line; P means patch-file line, not applied C line. It does not inspect, message, modify or control the other worker or certify its current producer. No runtime code, existing model, Recipe, native product or timeout is changed. Model and report are fresh registered audit outputs, not a new workspace.

Three conclusions must remain distinct: the inspected code executes a late callback and changes the cohort before joining (source fact); arbitrary callback GC is not mechanically excluded by this public interface (missing contract/enforcement); no supported native failing-join/live-target/GC trace is executed here. In particular the model's error outcome is not evidence of a legal recoverable Darwin EDEADLK path. Historical crash causes remain unestablished.

## Actual call and event order

| Event | Exact source operation | What has and has not completed |
| --- | --- | --- |
| 1 | P `___current_vm_resize` -> `sfun_vm_try_close(vm,target)` -> `current_vm_resize_admitted` -> `on_all_processors` -> `execute_sync_op_loop` | SFUN closes the relevant counted frame entries. Old processors rendezvous for resize. No arbitrary raw producer or callback prohibition follows. |
| 2 | `___vm_resize_pstate` (P:4714–4749), pending check; heap guard collective; optional `___garbage_collect_pstate` | Pending prevents another resize; no corresponding pending check is added to ordinary `___garbage_collect`. Required pre-resize GC completes through the old cohort. |
| 3 | P0 records retiring `join_pending`, resets local `handler_quiet`, publishes pending count (P:4807–4819) | A pending record is ownership retention, not a GC root registry. Donor has not finished release callbacks or OS exit. |
| 4 | `barrier_sync_op(OP_SET_PROCESSOR_COUNT)` (B:541–714, P:4525–4547) collects old-cohort messages; at P0 it closes registry readers, writes the smaller `processor_count`, reopens/replays, then sends replies down the old tree | Count changes before retiring processors return from this barrier. This barrier proves arrival and message ordering, not completion of code executed after it. Its local `n` is the old tree size for that invocation; later collectives read the smaller count. |
| 5a | Retiring member's `___vm_resize_pstate` branch (P:4757–4782) removes Scheme deque membership under its primitive lock; calls `cleanup_interrupts_pstate`; calls `___cleanup_os_pstate`; stores quiet=1; `___thread_exit` | The callback release and OS cleanup occur after cohort withdrawal. Normal Scheme thunk does not resume on this path. No full GC/FFI root/work handoff has been inserted here. |
| 5b | P0 starts `___thread_join` on each retiring member (P:4833–4870) | Runs concurrently with 5a. Successful join waits for OS exit. Error return establishes neither exit nor joinability and retains pending state. POSIX return-code encoding is already fixed in P:4147–4153. |
| 6 | Only success+quiet invokes `___transfer_mem_pstate`, `___cleanup_mem_pstate`, clears pending/decrements count | Current still/RC transfer occurs after join success; a failed join has not moved those lists. |
| 7 | `execute_sync_op(OP_VM_RESIZE)` runs `barrier_sync_op` with OP_VM_RESIZE_RESULT at P0 and NOOP elsewhere (P:4895–4917); surrounding loop returns/propagates result | Surviving processors rejoin this post-resize result collective using the new count. A retired processor exits from inside `___vm_resize_pstate`, so does not participate in it. This result barrier is not an exit acknowledgement from that retired member. |
| 8 | A surviving allocation later invokes `___garbage_collect` -> `on_all_processors(OP_GARBAGE_COLLECT)` (B:1182–1198) | If P0 is still in successful blocking join, it cannot service this collective yet. If join returned an error and the survivor result loop finishes, ordinary GC has no pending-based admission prohibition in P. It uses the smaller cohort. |

Existing normal collective completion does protect work performed before its return. With a no-GC exit callback and successful join, P0 transfers the still/RC ownership before it returns to the survivor result barrier; survivors cannot run a complete new GC past that P0 until the transfer suffix finishes. This is concrete counterevidence to calling ordinary successful shrink universally unsafe. The missing bridge is specifically a GC-demanding late release or failure-return ownership path after event 4, not a general absence of barriers in Gambit. Adding another new-count result barrier does not count the removed member.

The Scheme entry has another existing protection: P:956–976 renames the C entry current-vm-resize-raw and migrates a Scheme caller on a nonzero processor to P0 before calling it. Thus the calling Scheme continuation is not simply abandoned on a retiring processor in this supported wrapper. Preserve that mechanism; do not propose new universal C-frame migration. Raw C entry callers have separate premises. The raw C/Scheme-object result and result barrier propagate the resize result; source does not make every failed-join return a guaranteed process termination. A supported caller that retains an error result/handles an exception cannot be assumed to prohibit all subsequent allocation/GC.

## Can the retiring release callback create GC work?

`cleanup_interrupts_pstate` (B setup.c:396–417, P readiness additions:4420–4447) acquires `procedural_interrupts_mut`, reads each queued request, calls `release_procedural_interrupt`, clears head/tail and unlocks. `release_procedural_interrupt` (B:158–166) directly invokes `h->execute_fn(intr, ___FAL)`. The callback is invoked while the queue mutex is held and its returned SCM error is ignored by this void cleanup.

The callback type (B gambit.h.in:11585–11589) is an ordinary C function pointer returning SCMOBJ. `___init_procedural_interrupt` only assigns that pointer. Neither type nor dispatch checks no-GC, no-allocation, no-throw, bounded blocking or no-same-queue-reentry. Therefore the source does **not** supply those premises. Conversely, absence of a check is not proof the public embedding contract promises all such reentry is supported.

A mechanically available GC chain, conditional on a callback legitimately holding its current pstate, is:

`execute_fn(self,false)` -> `___alloc_scmobj(ps,...)` (B mem.c:1712–1724) -> `alloc_scmobj_still` (B:1556–1660), whose insufficient-space branch unlocks ALLOC_MEM_LOCK then calls `___garbage_collect(ps,words)` -> `on_all_processors(OP_GARBAGE_COLLECT)` -> tree rendezvous.

Even a callback with no Scheme invocation can enter this path through native still allocation with a non-NULL pstate. C `malloc/free`, atomic counters and OS descriptor close do not themselves constitute this Gambit GC path. Do not claim every release callback allocates or every allocation collects.

The targeted search of vendored Gambit lib/examples and native source fixtures found no built-in registered callback implementation establishing a universal cleanup policy. The concrete `models/gambit/native/procedural_interrupt_retirement.scm:21–36` callback's false branch only validates state and updates atomics. Its retained native success witnesses that callback population, not arbitrary allocating cleanup callbacks. No new native fixture was executed.

If the callback requests GC after event 4, it has already left the collective population. If P0 is also blocked joining it, its exit can await a GC that needs P0: a conditional wait cycle. Even if join immediately fails, using the retired processor as a normal GC participant is not made safe by that failure. Reentering the same interrupt queue also attempts its nonrecursive held mutex; merely moving cleanup earlier without detaching or defining no-reentry is insufficient. Nonlocal escape from cleanup while holding this lock/old collective requires explicit failure containment.

The post-callback tail is much narrower: `___cleanup_os_pstate` -> `___cleanup_io_pstate` (os_setup.c:3146–3152) -> close select-abort pipe/event (os_io.c:11807–11827), then quiet store and OS exit. The inspected tail contains no Gambit allocator/collector call. External interrupt senders still require the existing lifetime exclusion before descriptors are closed; OS close outcome/FD reuse remain separate obligations.

## When roots leave the scan population

| Root/work class | Actual scanning/admission | Consequence after failed join with donor outside processor_count |
| --- | --- | --- |
| `r`, `saved`, `type_cache`, current continuation and Scheme processor roots | Per participating processor: garbage_collect_setup_phase, mark_continuation/registers/saved/type_cache/processor_scmobj; P adds root barrier before recursive scan | Retaining donor struct bytes does not schedule these scanner calls. A value may already be dead or reachable elsewhere; that must be shown per field, not assumed. Captured continuation semantics and live C activation cannot be replaced with raw copying. |
| Still objects with nonzero external refcount | `setup_still_objs_to_scan` (B mem.c:4210–4233) walks that processor's still list; it is called by its GC setup phase | Retained donor still-list ownership is not equivalent to inclusion in the survivor scan. An externally referenced still object's reachable children need correct tracing as well as byte retention. P transfers list/counters only after successful join. |
| Registered RC data | `mark_rc` scans `rc_head` data; P:3579–3582 already fixes baseline P0-only scanning to each participating processor | This repaired per-processor scanning still does not enumerate a withdrawn pending donor. Actual external RC ownership/liveness remains caller-specific. |
| Private/queued scanning work and msections | setup_stack_heap_vmstate (B:3410–3467) obtains np=processor_count and reassigns stack/heap state for i<np; scanner stealing/worker counts also use np | Keeping old pointers does not pin sections or keep old work in the next GC phase. Relevant phase work must have completed/been published before withdrawal. |
| Wills/weak tables | per-processor strong/weak phases and process_wills | Must be dead, already owned/scanned elsewhere or transferred with the original weak semantics. Permanently rooting all of them changes behavior. |

This establishes the **scan frontier**, not that every retired register/list is necessarily live. A discriminating missing-coverage example requires a real live object reachable only via one of these retained donor roots and a survivor GC before safe transfer. That native example has not been run. The existing P text supplies no general retired-root scan loop for these classes, and pending_join_count is not consulted by ordinary GC. Therefore the general failed-join/live-root safety premise is unproved; source retention alone cannot close it.

## What the existing boundaries can guarantee

1. Old-cohort arrival and completed previous GC phases: present, with existing barriers. Do not replace the collector algorithm.
2. No further ordinary Scheme evaluation on the normal removed member's shrink branch: present after it takes the exit branch. It still runs native release callbacks and OS cleanup.
3. Normal exit-side quiet store dominates ___thread_exit: present; together with correct owner/slot identity and successful join, it supplies local completion. It says nothing about failed joins or arbitrary process handlers.
4. Root/work/callback closure before new count publication: absent as a general demonstrated handoff. OP_SET_PROCESSOR_COUNT precedes release callbacks; success-only transfer is later.
5. The new result barrier includes removed members: false. It covers the survivor set only.
6. Safe ordinary GC during a retained failed join: conditional on actual root/work ownership already discharged or separately enumerated. Neither a pending flag nor blocking all GC proves it.

## Minimal bounded repair for a GC-capable release contract

The selected design moves the semantic commit point, not just the join call. This is larger than adding one boolean but confined to existing resize/interrupt/transfer boundaries. Proposed names below are not runtime changes.

| Change site | Minimum semantic change | Why a smaller superficial edit is insufficient |
| --- | --- | --- |
| 1 `cleanup_interrupts_pstate` / release helper | Split queue detachment under mutex from release-callback invocation outside it; preserve pending request ownership and actual errors/nonlocal outcomes. Producers must already be stopped/denied through their supported lifetime contract. Run GC-capable release while donor is still a valid participant. | Invoking user C under queue lock cannot support reentry. Ignoring return errors cannot authenticate callback completion. Moving the existing locked loop one line earlier does not let a blocked cohort service nested GC. |
| 2 `___vm_resize_pstate`, `execute_sync_op_loop` / existing collective dispatcher | Introduce a prepare-retire subphase before OP_SET_PROCESSOR_COUNT. Every old member remains able to service required GC until retiring callbacks and root/work handoff acknowledge completion for that slot/incarnation. Only then commit new count. Finished members must service collectives, not park at a plain barrier while another callback requests GC. | Reuse the startup-pending-loop idea, not its exact code: nested resize priority/reentrancy, errors and old/new cohort membership need their own transition. A P0 busy wait or pthread_join here deadlocks the GC-capable callback. |
| 3 `___transfer_mem_pstate` and caller-side root/work discharge | At the legal old-cohort safe boundary, transfer still/RC ownership to a surviving scanner; prove each other live root/work class dead, already covered or safely registered. Preserve weak/will/continuation semantics and callback arguments through any moving GC. Record acknowledgement only after actual coverage. | Current transfer moves only still/RC lists and word counters and runs after join. A root record in an excluded pstate or a `prepared=true` flag is not collector-visible coverage. Do not move raw live stacks or call end_heap_chunk outside its valid GC phase. |
| 4 shrink/recover join state and final cleanup | Join consumes OS lifetime after prepare+withdraw. Error retains an OS/resource-owning record with exact slot/incarnation/owner, distinct from joined/transfer completion. OS tail after commit is constrained to the audited no-GC/no-Scheme operations. No successful join is retried; errors are not all assumed retryable. | After prepare, survivor GC is safe even if the OS thread has not quite exited and join fails. Before prepare, refusing new resize alone is insufficient. Do not label safe retained failure a successful cleanup. |

The four rows are semantic obligations, not four independent giant subsystems. The preferred first implementation would keep fixed pstate containers, current scheduler/collector/frame ABI and current root mechanisms. Source-level proof can remove unnecessary data movement for dead fields. No generation counter protects an already dangling raw pointer; direct external producers still need real admission/lifetime ownership.

Rollback matters: a prepare callback error before commit keeps the old cohort, original ownership and a reportable incomplete state; participants still need to leave the subprotocol consistently. Partially released requests cannot be replayed as if untouched. Cancellation/fatal/nonlocal exit needs exact same-phase unwinding or terminal containment, not a boolean rollback of side effects. The finite model below checks successful prepare and a later terminal join failure; it does not qualify this complete rollback inventory.

If the intended API instead restricts release(false) to native no-GC/no-Scheme/no-throw/no-reentry cleanup, that is a different contract choice requiring explicit declaration, enforcement at actual entry paths and compatibility audit. It cannot be silently inferred from the sample callback. Even that restricted option still requires scanner-visible retained root ownership when join fails; it does not by itself solve root omission. No API restriction is changed by this report.

## Pre-exit QNT and source correspondence

`retirement_pre_exit.qnt` begins before callbacks, cohort withdrawal, join or OS exit. It explicitly separates phase 0 before callback, phase 1 callback, phase 2 callback return, phase 4 actual OS exit; member=true means old-cohort participant; roots=0 is a live donor-only root and roots=1 is actual surviving scan coverage; joinState=1 is error with no exit assertion, 2 is success. A blocking join and GC request are separate states.

| Model event | C source or proposed change | Proof boundary |
| --- | --- | --- |
| withdraw | OP_SET_PROCESSOR_COUNT inside barrier_sync_op | Current policy permits it before callback/handoff, matching code order. Staged policy requires both acknowledgements. |
| startCallback / callbackReturn | cleanup_interrupts_pstate -> execute_fn(false) -> return | Existing source order. Model assumes one finite callback; arbitrary host behavior is not proved. |
| requestGC | explicit still allocation's insufficient-space path -> ___garbage_collect | Conditional callback capability, not an observed request in the retained native fixture. |
| serviceGC | old-cohort progress by the proposed prepare-retire dispatcher | Must be implemented/refined. Existing join-blocked/new-cohort path does not imply this event is enabled. |
| handoff | root/work transfer at old-cohort safe boundary | A typed semantic obligation, not an existing universal function. Model assumes a live donor-only root and successful actual receiver registration; native liveness/census/weak semantics remain to prove. |
| joinAttempt(error) | ___thread_join nonzero, pending retained | Does not advance exit phase. Error identity/retryability is not fabricated. |
| exitThread / joinSuccess | quiet/OS cleanup/___thread_exit; later successful OS join | Error path may reach actual exit eventually but cannot claim join success without an actual call. No retry is modeled. |
| survivorGC | new-cohort result loop returns, survivor calls ___garbage_collect | Enabled after error return even before actual target exit; root coverage must hold independently of OS byte retention. |

Positive checks: staged successful join, staged error-before-exit with terminal resource retention, and the retained source's no-GC normal success path; all include safety plus conditional completion. Negatives: current early withdrawal with a GC-demanding callback; current join error retaining an untransferred live root; quiet-only acknowledgement without root handoff. Named trajectories require an actual test report and show error+survivor-GC before OS exit, and the retained source's no-GC normal successful join after exit followed by its existing transfer suffix. The model explicitly includes handoffAfterJoin and prevents a successful-path survivor GC before that suffix, so the negatives do not manufacture a missing transfer on the already protected normal path.

The earlier audit attempt 5063c175084b413aaaac2e5407946193 copied the initial model before the normal-success suffix/control was added. Its checks and bytes remain retained, but it does not supply this normal-path source-correspondence control. Use the successor model hash and receipt accompanying this final report for the full comparison; do not treat the initial report's later prose as evidence that its model contained handoffAfterJoin.

`noCallbackWaitCycle` is a local wait-for-cycle/participant check, not a measured hang duration. `rootsCovered` checks the modeled live root only when a survivor GC runs; it is not a claim every native donor slot contains a live root. Completion assumes finite callbacks, a prepare loop that services enabled GC, finite OS exit and bounded modeled work. Retaining an errored OS record is not a recovery success and does not establish arbitrary resource bounds. Moving GC, all root/weak classes, C weak memory, cancellation, multiple donors, nested resize and prepare rollback require additional source/model discharge. Earlier post-exit checks remain scoped and their timeouts remain unchanged.

## Decision

The existing collective arrival is sufficient for prior work, but does not, by itself, establish the late-callback/root frontier required by the full contract. The stable small-refactor candidate is **prepare while still participating -> callback and root/work closure -> commit cohort shrink -> OS-only exit tail -> join/resource result**. This addresses the missing pre-exit premise directly. No current native crash is attributed to it here, and no model-only result closes gate 9 or 10.


## Actual QNT results

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 1.233454041997902 |
| initStagedSuccess | PASS | 13 | 15.756 |
| initStagedErrorBeforeExit | PASS | 12 | 22.139 |
| initCurrentNormal | TIMEOUT | n/a | 30.511 |
| initCurrentCallbackGC | Decoded expected counterexample | 7 | 27.762 |
| initCurrentErrorRetained | Decoded expected counterexample | 13 | 22.214 |
| initQuietOnly | Decoded expected counterexample | 18 | 23.212 |
| failedJoinDoesNotEstablishExit | PASS | n/a | 2.3801982089935336 |
| normalJoinConsumesAfterExit | PASS | n/a | 2.93622983401292 |

The positive checker runs include safety and per-action weak-fair conditional completion, compiled by the existing Quint/TLC backend. Every check keeps the original 30-second cap, host-selected workers and 1 GiB heap. Expected counterexamples require a decoded distinguishing state; nonzero exit alone is not accepted. Trajectories require actual 1-passing reports. This model tests proposed sufficient rules and concrete omissions under its stated input capabilities; it is not a C refinement theorem or native fault witness.
