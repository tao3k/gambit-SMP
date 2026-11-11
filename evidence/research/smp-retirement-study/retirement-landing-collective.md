# Landing entry, ABORT restoration and collective finalize

2026-10-23. Evidence-only refinement for repair-9-12. The named helpers and
fields below are proposed integration interfaces, not changes to the runtime.
The source identity is the c86dff86 producer recorded in the adjacent JSON;
gsi SHA256 is 7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808.
The previous materialization/domain and reaper publication requirements remain
necessary. Formal qualification remains 8/12; no contract migration is enabled.

## Actual entry and what it does not guarantee

| Actual function/field | Verified behavior | Required extension |
|---|---|---|
| `_kernel.scm:2356` `##current-vm-resize-raw`; wrapper at2368 | The SMP Scheme wrapper migrates its calling thread to P0 before entering the raw c-lambda. The raw function remains a separate entry. | Put Scheme preparation before the raw call, after migration. This wrapper is an entry for the initiator, not a landing pad for donors. Reject unsupported direct C/foreign contexts before changing membership; do not silently jump across their unwind frames. |
| `_kernel.scm:1430` `##sync-op-interrupt!` | Stores RA, executes `___W_ALL`, calls `service_sync_op`, then `___R_ALL` and restores RA. | Return a preparation notification to a supported Scheme dispatch point after the common C loop completes. Do not invoke Scheme or restore a thread from inside `execute_sync_op`. |
| `_thread.scm:2875` scheduler retry; `##thread-migrate-to!:3342` | Scheduler releases P before servicing sync on retry. Migration saves under T and calls `##lock-processor-with-sync-participation!` (702), whose helper at690 services sync while retrying; sync service is therefore not itself proof that every caller has released T. | A pending preparation bit must survive unsafe return sites. Enter the helper only with no T/P lock, outside nested C collective/foreign frames, and with a valid current Scheme thread/control context. Instrument/explicitly track this precondition at each call site; a test of processor ID alone is insufficient. |
| `gambit.h.in:6319` `___THREAD_SAVE`; `_thread.scm:2778` reschedule | Saves a frame reference in the thread continuation; reschedule installs a resume thunk and clears current-thread before scheduling. | Root the actual saved thread and epoch carrier before dropping its prior root. Export existing runnable/request/callback ownership, not copies of its movable values. |
| `gambit.h.in:6382` `___THREAD_RESTORE`; scheduler restore at `_thread.scm:2912` | Installs the thread continuation into BREAK_FRAME_NEXT, sets the saved frame field to END_OF_CONT_MARKER, restores denv interrupt mask, last processor and CURRENTTHREAD. Scheduler's supplied thunk releases T/P before resuming execution. | Restoration is consumptive. Use one generation-checked restore claim and a private abort-ack trampoline; do not repeat restore on a cleared continuation or use ordinary user resume as the acknowledgement. |

Line anchors are for the bound producer source, not top-level runtime files.
There is another concrete entry class: `setup.c:946-975` returns from `___run`,
reports OP_PROCESSOR_0_THROW_ERROR, then services sync forever in a native loop.
That participant does not return through `##sync-op-interrupt!` to Scheme.
Classify it explicitly as native-quiescent only after proving no live resumable
Scheme context/work remains, or supply a supported bridge before preparation.
A Scheme-only notification patch cannot claim this class is covered. Never
create an ACK or PREPARED simply because a native loop has no Scheme callback.

Generated C is unchanged. A new landing helper still requires regenerated-C
inspection to show the intended tail transfer, marker lifetime and rooting.

## Function-level implementation sequence for Grok

1. Extend the existing `##current-vm-resize` wrapper with a private
   `##retirement-prepare!` call on P0 before raw resize. Preallocate/root the epoch
   carrier and checked native records while the old cohort is intact. The C
   `___current_vm_resize` direct entry and shutdown caller (`setup.c:5454`) need
   an explicit prepared-context token or a supported bridge; otherwise refuse
   before commit. Do not treat the raw wrapper as evidence that shutdown has a
   returnable Scheme context.
2. In `setup.c` add a collective **notification**, not Scheme execution, to set
   per-member `prepare_requested_epoch`. `service_sync_op` / the common loop
   must finish its normal common exit before a Scheme landing can run. Add
   `##retirement-dispatch-if-safe!` at the supported Scheme return/scheduler
   paths, outside held T/P locks. An unsafe sync return keeps the request
   pending and reaches a later lock-free safe point. Do not rely on the already
   lossy result-mutex high-level delivery path to deliver this obligation.
3. `##retirement-landing!` claims `(VM incarnation, slot incarnation, epoch)`
   once, saves the current thread via the existing primitive and publishes its
   actual rooted reference. The private control path exports queues/callbacks
   under the previous ownership protocol, then parks. Its wait must continue
   servicing `___INTR_SYNC_OP`; a condition-variable wait or disabled-all-
   interrupts loop is insufficient. P0 must also wait outside the C collective
   while it expects donor Scheme helpers to run.
4. Complete the old-cohort materialization GC only after all required roots
   are published. All old members participate in every barrier inside
   `___garbage_collect_pstate`, including failures after relocation. Preparation
   callbacks may themselves cause earlier/repeated GC. Observe the completion
   stamp after the final barrier and returned outcome; never regard a partial
   collection or just a requested-GC bit as PREPARED. A GC space-failure boolean
   is not an OS errno or the Scheme error object used by resize.
5. Publish GO or ABORT for exactly this epoch. GO keeps donors frozen through
   atomic membership/native-domain commit. ABORT keeps the old cohort intact.
   A member with a saved continuation claims its restore exactly once, supplies
   the current traced thread to the existing restore primitive, and enters
   `##retirement-abort-ack!` as the restore thunk. Release scheduler locks there
   as existing scheduling does, then publish restore/ACK from a GC-safe state.
   A member that never saved acknowledges its unchanged state without restore.
6. An individual ACK does not release arbitrary user execution. Restored
   members remain in a private, GC-capable agreement trampoline until all old
   ACKs and native reader grace complete. Only then publish ABORT_COMPLETE,
   release user execution and drop carriers. Otherwise one restored member can
   capture fresh user frames or change exported work while peers still restore.
   Repeated ABORT(g) is an idempotent state read, not a second restore. Late
   ABORT(g-1), ACK(g-1) and GO(g-1) cannot advance g.
7. On restore/ack protocol failure retain the carrier, native owners, epoch and
   error. Keep old membership and serviceability wherever possible; prohibit
   epoch reuse, domain transfer and cleanup. Report a retained rollback fault,
   not completed rollback. If a participant cannot be made serviceable, there is
   no proved recoverable continuation: bounded validation must fail/timeout.
   No cancel, force-exit, stale frame rewind or invented successful ACK closes it.

Proposed native fields beyond the earlier plan: `prepare_requested_epoch`,
`landing_state` (REQUESTED/ENTERED/SAVED/PARKED), `restore_claim_epoch`,
`abort_ack_epoch`, `abort_complete_epoch`, `collective_depth`, and checked
entry-context/lock-ownership state where not already available. Keep the typed
carrier's saved thread, callback cursor/current/suffix, error and restore thunk
reachable throughout. Native integer flags are not Scheme roots. `___W_ALL` /
`___R_ALL` around a C call expose register state to GC; they do not root an
arbitrary local SCMOBJ in a malloc record or make a foreign frame resumable.

## Collective election, result propagation and last consumers

`barrier_sync_op` (`setup.c:703`) captures active n, combines a tree, selects the
smaller opcode and combines arguments only for the declared combining kind.
GC uses ADD; `OP_VM_RESIZE` is noncombining and outranks GC in the current table
(619-637). Copying resize's priority for finalize is not a justified choice.
Assign finalize an explicitly reviewed noncombining priority after GC, preserving
existing higher-priority error/count operations. A pending GC wins first; the
outer loop must retain the losing finalize descriptor and retry it. The model
checks that policy, not a particular newly allocated opcode number.

`execute_sync_op_loop:1301` returns an operation result only when opcode and
winner identity match (or it is combining), then changes that caller's request
to NOOP. It loops to a common NOOP boundary and has startup-specific cohort
handling. A new operation must preserve this losing-request behavior and common
exit. It must not return from a local error branch while another participant
is still in a barrier. Thread-boundary errors are recorded and handled only
after agreement; no Scheme exception can escape from inside a selected handler.

`execute_sync_op:1259` resize has a separate P0-result barrier. Implement an
analogous **explicit** finalize result/ack protocol: all selected participants
execute the same number of barriers even when local validation fails; P0
publishes a typed native status and all members consume the same epoch/result.
Do not interpret a different elected opcode's arg[0] as a finalize result. Any
additional election must check its opcode and service it through a common
protocol. The model represents this as result publication and per-member ACKs;
it does not prove the C barrier implementation.

`execute_sync_op_loop:1409` only backfills delayed `___err` into a resize
caller's arg[0]. Generalize that decision deliberately for the new request/result
interface. Preserve the first common error and return it to the actual initiator;
P0's final `___throw_error` must not bypass required result/abort agreement. A
caught/nonlocal Scheme error in preparation must become rooted ABORT state,
not unwind an active C collective.

Finalize (`___retirement_finalize_pstate`, proposed) runs only after selection,
join0, borrower/scan grace and validated same-generation ownership. Before its
first destructive splice perform every fallible validation and reserve needed
bookkeeping storage. Selected finalize allocates no Scheme object, runs no
callback, performs no OS join/wait, and never calls `on_all_processors` recursively.
Its actual transfer/registration/accounting sequence must be infallible under
those preconditions. If partial transfer can fail, it needs a separately proved
ownership journal/recovery protocol; the present proposal does not provide one.

Last-consumer table:

| Resource | Last allowed consumer | Reclaim condition |
|---|---|---|
| Saved continuation/root carrier | GC plus restore claim/trampoline; on GO receiver rooted references | ABORT_COMPLETE plus native-reader grace, or receiver installed and transfer completed |
| Old collective membership | Every old member through preparation GC and ABORT agreement | Only all PREPARED GO transaction changes count; ABORT never shrinks it |
| Epoch/result descriptor | Losing request retry, selected handler, result consumers | Matching result ACKs and common exit; no reuse while rollback fault retained |
| Pending still/RC storage | Collector scan snapshot and transfer destination | Join0 plus all borrower grace; atomic GC-excluded transfer/domain removal |
| Preparation callback suffix/error | Protected callback dispatcher and abort reporting | Exactly-once disposition of each item and safe error delivery; no prefix replay |

## Model and limits

`models/gambit/retirement_landing_collective.qnt` refines entry, two preparation
GCs, three old members, two surviving finalize members, GC/finalize election,
per-member result consumption and consumptive ABORT restore. Five positive
scenarios include preparation error, relocated-root GC overflow, retained
rollback failure and retained pre-transfer finalize failure. Fourteen mutants
change protocol state to violate the named invariants; decoded witness labels
are checked in addition to TLC invariant failures.

The model distinguishes successful abort from retained rollback fault. Fair
completion means reaching either success or explicit retained failure under the
model's progress assumptions; it does not prove failed members return, callbacks
terminate or every real C caller has a safe landing. Release/acquire edges and C
frame maps remain the earlier manual/source obligations, not consequences of
Quint's atomic transitions. Bounded scenarios are not an unbounded C11 proof.

Still required before implementation can claim sufficiency: enumerate every
sync-return lock/context path; prove private trampolines cannot resume arbitrary
user code before agreement; generated-C marker/root checks; checked disposition
of nonlocal callback/restore errors; full opcode/result protocol review; native
fault injection of each return/restore/barrier boundary on one source-bound
producer. Formal 9/12 contract review and its two real receipts remain separate.

Verification: 19/19 expected controls accepted (5 positive safety/fair terminal,
14 invariant violations with decoded witnesses), 30 seconds per case unchanged.
Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/dd6b59430ebc48c7a6672dd7be9ea4e1/outputs/retirement-landing-collective-model/receipt.json`. Retained-fault terminal states are not
successful rollback or native acceptance.
