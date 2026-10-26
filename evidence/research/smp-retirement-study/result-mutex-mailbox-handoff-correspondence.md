# Mailbox handoff bound to the current scheduler

2026-10-23. This binds `models/gambit/result_mutex_mailbox_handoff.qnt` to the repair-9-12 build tree. It is not a native repair. Count stays 8/12. Lifecycle join, TYPEID, and release are not in this claim.

Source lines are the SMP half of

`.cache/tasks/repair-9-12/build/gambit-core/4463d6b544c156ad648f6ff26f8786afbe3e9b73032d924e664dfc98200ba624/source/lib/_thread.scm`

unless another file is named. The non-SMP copy after line 5505 is not the running scheduler.

## Lock order the source already states

`_thread.scm` lines 33–39: different object types lock as mutex, then condition variable, then thread, then thread group, then processor, then VM. Same-type locks use address order. A set that is not known up front uses trylock and retry.

What the running paths actually do:

- `macro-mutex-lock!` takes the mutex lock, then the new-owner thread lock, then either links or calls `##mutex-lock-out-of-line!`.
- `##thread-lock-remove-btq-toq!` (769) takes the thread lock. A processor run queue is locked after that. A mutex or condvar is only trylocked; failure drops the thread lock and retries.
- `##thread-schedule-with-acquired-processor!` already holds the processor lock, then trylocks the next thread. Failure unlocks the processor and retries, so it does not keep processor-then-thread.
- `##mutex-unlock-out-of-line!` holds the mutex lock, then `##lock-3-threads!`, then queues the waiter.
- `##wait!` (2641) takes the VM lock, inserts the processor on the idle list, drops the VM lock, then enters select. The idle caller at 3108 has already dropped the processor lock.
- `___raise_high_level_interrupt_pstate` takes only the processor ticket lock (`___PRIMLOCK` on fields 1 and 9), publishes head/tail, drops that lock, then calls `___raise_interrupt_pstate`.

The mailbox park step cannot hold the processor lock across `___device_select`. Raise needs that same ticket lock. Holding it through select would block the publisher. The model's prepare/commit split matches this: observe under the processor lock, drop it, select, then recheck. The current idle path does not do that recheck under the processor lock.

## Memory order the source already has

On this host the word atomics are `__sync_fetch_and_add`, `__sync_val_compare_and_swap`, and `__sync_synchronize` (`gambit.h.in` 11040–11050). The ticket lock publishes `next` with a fetch-add and waits until `current` matches. Unlock fetch-adds `current`. That is the exclusion for the processor queue and for thread/mutex slots 1 and 9. It is not a generation for runnable publication.

After the high-level link, `setup.c` issues `___SHARED_MEMORY_BARRIER()` before the ticket unlock. `___raise_interrupt_pstate` stores `intr_flag[code]`, then stack-trips and calls `___device_select_abort` only when `___INTERRUPT_REQ` is true: the flag bit must survive `intr_enabled & ~intr_mask`. `___disable_interrupts_pstate` sets `intr_enabled` to only `___INTR_SYNC_OP`. A processor inside `##wait!` therefore stores `___INTR_OTHER` and does not abort select.

`___device_select_abort` (`os_io.c` 1537) is one `write` of a single byte. The error is ignored. There is no publication generation beside that byte. A write before the processor is inside select, or a failed write when the pipe is full, leaves no second obligation. After select drains the byte, the idle path calls `##service-interrupts!` and schedules again. That is a new observation of the run queue, not a check that a ready publication which lost the race is still owed a wake.

## GC roots

`macro-mutex-lock!` calls `##check-heap-limit` before taking the mutex lock so a collection does not run while that lock is held. That is not a root map for the interrupt vector.

Claim today is the pop in `macro-thread-interrupts-remove-from-head!` (`_thread#.scm` 4310). It runs under the current thread lock, copies the head into the Scheme variable `interrupt`, clears slot 0, and updates head/tail. `##other-interrupt!` (1475) and `##thread-resume-execution!` (2836) then drop the thread lock and call the thunk.

Generated `lib/_thread.c` for `##other-interrupt!` binds that return. Before `___JUMPGENNOTSAFE` to the thunk it does `___SET_STK(2,___R2)` where `___R2` is the result mutex, then `___ADJFP(8)`. The return label reloads `___STK(-6)` and only then stores `mutex-specific` and locks the mutex to unlock it (`_thread.c` 15902–15910). The interrupt vector is not kept in that frame; the queue has already dropped it, and the unlock uses the mutex. The procedure frame lists `___R0` through `___R4` (`___PD_ALL` at 15818). This is the normal-return root for this one procedure. It is not a map for a new claim helper, and it is not the resume procedure's frame.

## Thunk exception and unlock

The same return label is the only unlock. `___JUMPGENNOTSAFE` does not come back to that label if the thunk raises. The three Scheme handlers are the same shape: `(macro-mutex-specific-set! x (thunk))` then `macro-mutex-unlock!`, with no catch (`_thread.scm` 1498–1500 and 1527–1528, and the resume copy at 2864). An exception that ends the thread reaches `##thread-end-locked!`, which abandons owned mutexes under the thread lock (1755–1763). An exception that is caught above the handler and continues the thread never executes that unlock. Wrapping all three handlers would be one local change. It would not create the mailbox block-commit or park-recheck, and the witnessed flood does not raise from `##vector-inc!`.

`##c-code` forms pass the next Scheme value as `___ARG1` for the duration of that primitive. That roots the argument of the primitive, not the later thunk call.

No new raw-root ABI is justified. Processor park generations, if added, are scalars on processor state, not Scheme references. `scheduler_status` stays the startup pending/ready/failed word. It is not a park bit.

## Exception paths

The three mutex handlers do `(macro-mutex-specific-set! x (thunk))` then `macro-mutex-unlock!`. There is no catch around the thunk. An exception that never reaches thread end skips the unlock. The sender stays in the second `macro-mutex-lock!`.

If the exception does end the thread, `##thread-end-locked!` (1700) holds the thread lock and `##btq-abandon!` (1755–1763) abandons every owned mutex, then the end condvar is signaled. That is the abandoned-mutex contract, not a normal reply.

`##mutex-lock-out-of-line!` treats the mutex as abandoned when either the previous owner state or the state just installed is the abandoned marker. Termination of the new owner is checked before `macro-btq-link!`. Those two checks are already in this tree. They do not deliver a thunk that never ran.

`##thread-intr-propagate!` on a terminated target unlocks the thread and does not queue the node. The counter report for the flood had zero terminated drops. That path is not the witnessed hang.

## Where each protocol step is, and where it is not

PUBLISH. `##thread-intr!` (1336) builds a two-slot vector and a target-owned result mutex, then `##thread-intr-propagate!` (1360). The running branch unlocks the thread and calls `##raise-high-level-interrupt` (1395), which links slot 0 onto the processor queue. The non-running branch links slot 0 onto the thread queue. One slot is both links. The mailbox rule "this request never enters the processor queue" is not what this function does. Shipping only that deletion is the measured 5/8 thread-queue-plus-OTHER result, which was removed.

NOTIFY. `___raise_interrupt_pstate` does not carry the node. `___device_select_abort` does not carry the node. Both can also fail to wake, as above. A notification is not a substitute for a runnable entry.

CLAIM. Pop under the thread lock, then unlock, then thunk. Root coverage of the popped node across the thunk is unbound. Doing the thunk while still holding the thread lock would invert the rule that callbacks stay outside scheduler locks.

BLOCK COMMIT. Sites in this SMP half that clear `processor-current-thread` include thread end (1697), yield when another thread is runnable (2010), yield when the thread interrupt head is non-empty (2038), sleep (2096), `##thread-reschedule!` (2822), migrate (3287), mutex wait (3905), and the condvar waits (4184, 4273). Only the empty-run-queue yield path reads the thread interrupt head before committing. Sleep, mutex wait, and condvar wait do not. A patch at yield alone leaves those commits able to suspend a target that still owns mailbox work. Resume drains the thread queue only when the thread is actually resumed.

PARK COMMIT. The device-less wait is unlock processor (3108), `##wait!` `#f` `#t` (3111), `##service-interrupts!`, schedule again. Head and the decision to select are not one locked observation. There is no publication generation. Refusing to enter `##wait!` while the high-level head was non-empty scored 4/8 and was removed. That is not this transaction.

SERVICE. `noLost` in the mailbox model is "waiting implies queued or active". `serviceable` also requires a running target, or a ready processor that is not committed to sleep without a remaining wake. Current code can leave a thread interrupt queued on a target that is noncurrent and not on a run queue, while the processor that would run it is inside select and the abort write already happened or never became visible. Reachable node, no service path. That is the model result that blocks a runtime edit.

## Decision

The normal-return mutex root and the exception skip of that return are now bound, above. They are not one source change that implements mailbox handoff. The missing pieces that remain are one shared block-commit for every current-to-noncurrent site above, and a park prepare/recheck that does not hold the processor lock across select. Adding those together is not one bounded change. Mailbox handoff is not being implemented. Publish-only, slot-2 links, pop-rehome, and skip-select were already measured and were not kept. No other open gate has a native close that is a real still-joinable `___thread_join` error followed by same-owner success. The pre-join `___LW_REFUSED` store is not that receipt.

No `gambit-smp` run was started from this correspondence. `os_join_error_then_success` still returns false for `LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS`. Line 502 is `if match is None: return False`. `qualify_nine_of_twelve` stays 8/12 while recovery-1 stores `___LW_REFUSED` before `___thread_join`.


## Refinement and corrections (2026-10-23)

See [frozen source, static instructions, root maps, errors and park protocol](../../../docs/smp-repair9-mailbox-boundary-refinement.md). Prefix fetch-add is not grant-completion acquire; raw C queue locks lack the latter, whereas Scheme thread/processor helpers use a successful CAS. An abort write before select persists; EAGAIN/full pipe can coalesce. Those cases alone do not prove lost wake. Ignored EINTR/other write errors are the unresolved outcome. Resume/wait return maps are now inspected. No newly invented helper or arbitrary escape has a native root/cleanup proof. The old20-check receipt is historical; the maintained model is bound by the new44-check receipt.
