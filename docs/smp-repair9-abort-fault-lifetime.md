# Abort fault ownership, lock-free reporting boundaries and fd retirement

2026-10-23. Design/source/model research only. Native remains **8/12**. No runtime/header/compiler/Recipe change, native run, complete inventory, peer operation, staging, commit or push. This extends [acquire and abort contracts](smp-repair9-acquire-abort-contract.md); it does not replace historical failures or producer identities.

## Decision

The transport can be made structurally safe within an explicit live-channel and bounded-progress envelope: keep an actual consumer through each syscall/retry, record a fault before relinquishing its incarnation, report outside scheduler locks, and prevent close/reset until all old consumers have ended. Keep request ownership and runnable/park delivery separate from the transport byte. This eliminates a class of lifetime/handoff failures rather than repairing an empty head after the fact.

There is also useful existing protection. Shrink already closes/drains global VM-registry readers before publishing the smaller processor count, and the old collective cohort constrains ordinary Scheme callers. These guarantees should be reused. They do not cover every exported raw-pstate C entry or a newly deferred fault consumer. A uniform fd guard everywhere is a conservative implementation option, not proof that the existing normal paths all lack lifetime protection.

We can specify the safety protocol and its minimum call sites now. We cannot yet certify that it fixes the witnessed missing thunk, arbitrary hard-pipe recovery, or native9/12. The exact first writer, source refinement of public-C admission and the terminal fault landing pad remain substantive gates, not performance-tuning details.

## Source cut

Stable read audit `d53671cb657c47fcb636ae9a549504b3/outputs/abort-lifetime-source` contains the actual incremental setup/os_io/os_setup/os_thread, thread/kernel Scheme and header/template files with full SHA256 identities and `readIntervalStable=true`. Line numbers refer to this cut. The earlier select-blocking experiment is absent from this cut's abort chain; neither its source nor its old object is reused to certify the present generation. No current gsi binding or execution is claimed.

## Actual destruction and the protections already present

`___vm_resize_pstate` worker branch setup.c1113–1138 removes the idle-list entry, calls `cleanup_interrupts_pstate`, calls `___cleanup_os_pstate`, then `___thread_exit`. P0's join is later,1183–1196. On successful join it transfers/cleans **memory**. Therefore successful join is not the event authorizing the earlier fd close.

The fd chain is `___cleanup_os_pstate` (os_setup.c3146–3151) → `___cleanup_io_pstate` (os_io.c12013–12032) → `___close_half_duplex_pipe(...,2)` (os_setup.c468–486). That helper closes the read end, writes -1, closes the write end, writes -1. It does not acquire an abort-reader guard or wait for a cached fd. The pipe fields are integer descriptors in `___pstate_os`, not GC roots or ownership counters.

However, setup.c803–819 implements a real shrink grace period: after old processors arrive, P0 locks vm_list_mut, closes/drains registry readers, lowers processor_count, reopens, unlocks and replays pending interrupts. `___raise_interrupt`235ff enters/leaves that reader region around delivery; `___raise_interrupt_vmstate` starts its loop from the old count. Its existing reader remains responsible through the complete nested pstate abort call. A retry loop added **inside** that call must not release the reader on its first EINTR. Ordinary cohort processors cannot simultaneously be executing their synchronous native abort and already have completed the same Scheme-driven collective arrival. That conclusion is scoped to non-reentrant native I/O/flag code, not arbitrary foreign callbacks.

| Last consumer | Existing owner / end event | Unproved or necessary change |
|---|---|---|
| Global interrupt delivery holding an old count | VM-registry reader; end after nested pstate delivery/abort returns | Preserve through all EINTR attempts, error capture and fault publication. Existing OP_SET_PROCESSOR_COUNT grace is reusable. |
| Scheme direct `##device-select-abort!` and target-route notifier | Executing old-cohort processor and its Scheme continuation | Complete synchronous syscall/outcome work before cohort arrival. Never publish a callback that outlives this frame without a new owner. |
| Target select and abort-pipe drain | Current target C activation; return from `___device_select` / `___os_condvar_select` before Scheme resumes | Capture native errors and finish drain before ending its fd consumer. Retirement must first establish select has returned; setting an idle-list link is not that proof. |
| EINTR retry or nested signal writer | Original native writer activation plus its outer reader/instance owner | Keep the same fd/instance consumer across retries. No unlock/reacquire gap that permits close/reuse between attempts. |
| Exported `___raise_procedural_interrupt_pstate`, `___raise_high_level_interrupt_pstate`, direct pstate raise | Header exposes raw pstate entry; procedural path locks procedural_interrupts_mut then eventually aborts | No per-call registry/instance guard is visible at these entries. External callers must have a valid outer VM/pstate owner and an admitted instance borrow, or these entries need guarded admission. Protect before touching procedural mutex/queue, not only just before write. |
| Deferred fault observer | A copied, tagged native scalar record; no fd needed after publication | Processor/VM slot and fault incarnation still cannot be reset/free while a report can affect it. A fault observer is a last consumer of the record, not of the fd. |
| Setup rollback / owner cleanup / global shutdown | setup.c4926–4929,5030–5060,5237,5412, plus resize worker path | Private unpublished setup prefix can use a narrower proof. Published paths need retirement/grace conditions before interrupt and fd destruction. Count1 or joined memory alone is insufficient. |

The generic `___close_no_EINTR` itself retries close on EINTR and its caller ignores error. This study does not turn that legacy wrapper into a portable close-outcome theorem. [Apple close documentation](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/close.2.html) distinguishes interruption and error; the current platform's exact descriptor-release semantics remain separate from proving that logical consumers are gone. Do not infer a close retry rule from the one-byte write rule.

## Proposed fields: smallest explicit state, no root registry

Use native scalar state associated with one admitted pstate incarnation. These are proposed private fields, not edits already present:

- `io_use_gate`: one atomic word, bit0 means open and increments of2 count admitted external/native consumers. Initial zero is closed. Closing clears open atomically while preserving outstanding counts. Releasing subtracts2. No waiting for an open bit in a signal handler. Count overflow refuses admission; it must not wrap.
- `io_instance`: identity for this fd-pair/pstate incarnation, changed only while admission is closed, consumers are zero and the previous record is disposed. Do not reuse `scheduler_status` or assume startup scheduler_epoch already satisfies this contract. Define wrap refusal and VM identity before implementing.
- `wake_fault_code`: one atomic sticky error code, zero→first nonzero via CAS. It belongs to `io_instance`; later successful wakes do not clear it. This avoids a multiword payload-ready publication and avoids a BUSY/seqlock writer that can deadlock when interrupted by its own nested signal writer.
- Existing proposed park/runnable publication fields retain their own sequence/ack. An acknowledgment must match both the I/O incarnation and the relevant park/publication episode. The fault is sticky for the entire incarnation, so a separate per-request fault table is unnecessary.

A selector-return witness may come from the existing old-cohort arrival on the normal shrink path. A generalized cleanup path that lacks that witness needs an explicit matching selector/park acknowledgment. A bare boolean or old epoch acknowledgment is insufficient. Do not add duplicate ack fields merely to restate a guarantee already established by that path.

The outer VM/pstate storage must already be valid **before** trying the embedded gate. An embedded counter cannot rescue an arbitrary freed pstate pointer. For raw external C, borrow acquisition must occur at a valid owner/handle boundary; that API/source contract remains to be established. Likewise, a borrowed request SCMOBJ still needs its existing Scheme/C root contract. These scalar fields do not replace GC roots.

## Function-level lifecycle protocol

Names below describe small private helpers for an eventual patch; they do not introduce a framework or a new public task API.

1. `___setup_io_pstate`: keep admission closed during pipe creation/nonblocking setup. Publish valid descriptors and a fresh instance before release-opening admission. Roll back private prefixes without pretending they were exposed. Initialize the fault code only here or at a fully quiescent reset.
2. Guarded pstate interrupt/procedural/high-level entry and direct `___device_select_abort`: acquire the relevant valid instance before dereferencing its mutable OS/interrupt fields. Avoid redundant nested borrows when the caller already carries one; make that private borrowed-helper contract explicit. Preserve the existing registry reader on the global path. Refusal during retirement is not permission to drop an accepted result-mutex request: its authoritative queue/route owner must retain and reroute it before publication is admitted.
3. `___device_select_abort`: load/copy the fd only after admission; write exactly one byte; snapshot errno immediately. For EINTR retry, retain the same borrow and fd incarnation until final outcome. Success and EAGAIN transfer wake responsibility only to the pipe/receiver contract from the prior model. On another error or unexpected byte count, CAS the sticky fault before releasing the borrow. Preserve signal-context errno; no allocation, Scheme callback, ordinary handler dispatch or blocking scheduler lock.
4. `___device_select` / `___os_condvar_select`: cover fdset construction, select, drain, native outcome capture and return with the selector's existing or explicit borrow. After native return, finish the mapped Scheme wait cleanup before attempting ordinary error handling. Keep the wait processor root and caller frame maps; no native Scheme pointer cache is introduced.
5. Retirement preparation: under the existing scheduler/target contract stop admitting new work to the retiring route. Release T/P/V/M. While the channel is still open, perform the final cancellation wake under a valid control borrow; establish that select/drain has ended for the matching episode. A close-first protocol cannot then rely on a new abort to wake its blocked reader.
6. Admission/grace: close the I/O gate; drain prior admitted writer/control/selector consumers, or reuse a proven existing cohort/registry grace covering exactly those consumers. Do not wait while holding scheduler locks, or close registry admission and then demand a Scheme callback that needs that admission to finish. Preserve whatever SYNC/old-cohort participation is still required before irreversible retirement. Only then call cleanup_interrupts/os/fd destruction.
7. `___cleanup_io_pstate` / `___close_half_duplex_pipe`: one owner performs close, with no remaining old fd consumers. A close operation is not a reference-release substitute. Reuse/free of the pstate/fd slot additionally requires no unresolved fault disposition or deferred old report. Keep an old instance retained on postcommit failure; do not restore an old count after destroying its resources.

For covered Scheme/global paths, the old cohort plus registry grace can establish the same effect without extra per-write counting. A uniform native borrow at exported/raw entry boundaries costs two atomic RMWs per use and simplifies the external-C proof. The implementation choice must follow a complete caller census. Merely adding a leaf fd counter would miss procedural mutex use and deferred reports.

## Fault publication and lock-outside handling

`##wait-abort!` releases V before entering the leaf, but some callers still hold T or M. In particular propagate's noncurrent fallback calls wait-abort-no-remove before unlocking T (_thread.scm1466–1471); slow mutex unlock queues the waiter before `##unlock-3-threads!` and mutex unlock (4044–4054). These are **not** places to throw or run an ordinary Scheme callback.

First publish the sticky scalar fault while the native incarnation is borrowed, then return through the existing unlock sequence. The record outlives the syscall independently of errno and the C activation. An old observer may retain a copied `(VM,instance,code)` record; it must validate instance at consumption and never write back into a later incarnation. Use the same closure/grace identity to pin a live pstate when observing its embedded field. Do not keep a raw pointer to it after releasing that identity.

| Source location | Lock/context fact | Safe use / restriction |
|---|---|---|
| `##thread-intr!`, immediately after propagate returns, before the second result-mutex lock (1352–1356) | Normal propagation has returned through its thread/processor unlocks; sender result mutex and request are in Scheme bindings. | Candidate place to inspect a copied native status. It is **not** automatically legal to raise and abandon an accepted/possibly executing request. Preserve its unique queue/activation owner and result semantics. |
| Scheduler restore closure2972–2978 → entry to `##thread-resume-execution!` | T and P explicitly unlocked; current thread/continuation restored. | Candidate inspection/dispatch boundary with an actual Scheme activation. A new helper's maps and error policy still need verification. Do not inject a transport error into an arbitrary unrelated thread. |
| Idle wait return2653–2657, scheduler3111–3113 | V released, select/drain returned; idle processor may lack a user-thread owner. | Record/coordinate native failure; no proof of an ordinary user exception landing pad here. `##service-interrupts!` being a check does not by itself solve disposition. |
| Raw signal `___raise_interrupt` → registry delivery → pstate abort | Native/signal context and possibly no current Scheme activation | Scalar, signal-safe publication only. No Scheme throw/GC/lock-based fault queue. Keep errno and existing reader lifetime. |
| C resize/cleanup/`___propagate_error` | `___throw_error` is `___THROW`; it can unwind C. | Do not use it while locks, old-cohort duties or rooted restoration are pending. Existing C throw is not a new safe-point proof. |

The proposed private `##check-pending-wake-fault!` should initially mean “validate/copy/report a fault to its actual owner”, not “unconditionally throw”. A proper fault disposition must either preserve the admitted request through recovery, cancel it atomically before claim under the actual API contract, or terminate its target/VM through a rooted legal landing pad. A fabricated result, manual result-mutex unlock or replay is excluded. This terminal/cancellation policy is the largest remaining error-side source-refinement obligation.

## EINTR, epochs and concurrent cleanup

[Apple write documentation](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/write.2.html) motivates count/errno classification. With a valid live one-byte nonblocking pipe, EINTR retries retain the original fd consumer. Do not drop/reacquire a lease between attempts, use a cached fd after admission refusal, or release a registry reader at the first failed write. With k interruptions, cost is k+1 syscalls; progress assumes finite interruption/fair scheduling and has no unconditional time bound. No native timeout is enlarged.

There are two different epochs: fd incarnation (close/reuse) and delivery/park publication (ready service). An epoch1 acknowledgment cannot release epoch2 wake debt. An old instance's saved errno cannot poison a newly opened instance even when the numeric fd or pstate address is reused. Do not reset the sticky fault on a later successful write. Publish complete atomic fault state before relinquishing the old instance; otherwise cleanup can reset the slot before the late fault arrives.

Permanent broken pipe plus sleeping receiver still has no guaranteed recovery using only that pipe. Under the live-channel envelope, preventing concurrent close/reuse removes important EBADF/EPIPE mechanisms; it does not prove every OS failure impossible. Hard fault retention is safety only, not native completion or production recovery. Any independent fallback wake must be proved separately; no new heartbeat, timeout, rescue thread or channel is added here.

## What is established and what still blocks a sufficiency claim

| Claim | Present result | Remaining concrete work |
|---|---|---|
| Ordinary global IRQ during shrink cannot retain an uncounted old-count abort | Existing registry close/drain before count publication, plus source-shaped QNT control | Preserve nested error/retry work inside its reader; full code refinement, not a second registry. |
| Ordinary Scheme direct abort precedes old-cohort arrival | Existing synchronous control shape plus scoped QNT | Exclude/review reentrant foreign callbacks; keep native retry from servicing Scheme mid-borrow. |
| External C cannot race fd/procedural cleanup | Not established at raw-pstate exported entries | Define/guard valid outer owner and per-instance borrow; preserve refusal semantics and public ABI. |
| Native failure can survive returning under locks | Proposed one-word sticky fault, mapped source points; QNT rejects partial/late/reset publication | Place fields, init/reset, CAS backend and source-to-native bindings; no new SCM roots. |
| Fault can be safely *handled* after unlocking | Specific inspection candidates identified | Owner-specific request cancellation/terminal landing pad and all error/unwind branches; no arbitrary-thread exception. |
| Selector and writers are gone before close/reuse | Conditional source/grace/borrow protocol and bounded model | Every cleanup/setup-failure path and incarnation/reset proof; native close outcome semantics remain separate. |
| A small coherent change fixes the reported missing thunk and preserves8 gates | Not established | Compose with authoritative mailbox, rooted claim, pending-aware suspension and same-P park/runnable protocol; identify/check native causal route, then authorized same-producer tests and exact qualification. |

The narrowed production candidate is therefore still bounded: existing queue/lock structure plus the normal ticket-grant acquire, one authoritative request owner, scheduler commit boundaries, typed abort outcome/sticky fault and guarded last consumers. It needs no new collector, global dispatcher or whole-runtime rewrite. This is a credible structural route to a repair; declaring it sufficient today would erase the external-C, terminal-error and native-causality gates above.

## Executable controls

`abort_fd_last_consumer.qnt` combines one native writer, selector, cleanup, one transient EINTR, a scalar fault, lock release, fd reuse and matching selector incarnation. Two normal/transient profiles check safety plus conditional completion; the hard-fault profile checks safety only. Ten negative variants exercise close with writer, retry without borrow, close with selector, late fault after reuse, error handling under lock, resetting an unresolved fault, cached fd before admission, stale selector ack, clearing fault on success and partially publishing fault state.

`abort_quiescence_sources.qnt` distinguishes existing old-cohort/registry coverage from an external caller. Covered ordinary source and counted-external controls pass; untracked external use and early registry-reader release fail with decoded bad states. A pinned external control is the specification for a missing boundary, not code already present.

Together:17 TLC cases (4 conditional-completion positives,1 hard-fault safety-only,12 decoded negatives) and8 deterministic TypeScript trajectories,25 checks. Original30s/check,12 workers,1GiB/8MiB retained. The earlier10-case narrower fd run is preserved; the expanded13-case model supersedes it for this publication. All prior24/44 checks, measured-failure obligation and runtime qualification remain unchanged. Finite state counts establish neither elapsed-time limits nor an unbounded multi-VM/GC/native proof.


## Terminal-error dependency audit

The existing terminal path is now traced rather than treated as an unspecified escape hatch. `___run_and_throw_error_on_processor_0` (setup.c927–976) waits for ___run to return, then calls on_all_processors with OP_PROCESSOR_0_THROW_ERROR; afterwards it keeps serving sync operations. `on_all_processors`1431ff first raises SYNC_OP through the same pstate interrupt/abort path and then enters the collective. Kernel `##exit-with-err-code-no-cleanup`4712ff calls propagate_error/THROW; it is not a second wake channel. Thus merely routing a latched fault to this P0 path does not establish recovery when another processor is asleep and its pipe is permanently broken. The escalation can await the same unavailable service it needs to report. This is a source dependency, not a recovered native failure trace.

New abort_fault_escalation.qnt has four controls: healthy-channel conditional completion; broken-channel collective-wait negative; broken-channel fault retention safety-only; and conditional completion with a hypothetical independent carrier. That final carrier is explicitly absent from this study and is not a proposed installed fix. These four controls supplement the25 source/lifetime checks,29 in total; previous receipts stay unchanged.

The implementation decision is therefore precise. A coherent small repair can target authoritative request ownership, synchronized scheduling, effective ticket acquisition and an owned live fd channel, with existing cohort/registry grace plus explicit external-C admission. An unconditional permanent-transport-failure recovery promise would require an additional proved carrier or a changed terminal contract. It cannot be obtained by a write retry, sticky flag, arbitrary C throw or renamed P0 collective. Native cause, public-C/refusal semantics, rooted owner-specific fault disposition and same-producer first-eight/full qualification remain required before calling the9–12 work safely solved.


## External-C contract refinement (2026-10-23)

[External owner, instance/refusal and actual terminal paths](smp-repair9-external-c-owner-disposition.md) reuses the existing source-bound joined-owner native witness rather than calling unjoined cleanup a valid-program bug. Under that contract, per-call rejection ABI/gate changes are optional concurrent-admission extensions, not automatically minimum fixes. A non-NO_ERR procedural callback does expose an extra-unlock source branch. Primordial exit is distinct from nonprimordial mutex abandonment. The older observation describes mutex ownership at release more strongly than its actual callback assertion (op/readiness/counts); this refinement preserves original materials and records the distinction. New QNT specifications are pending execution during active production custody; no new model/native PASS.
