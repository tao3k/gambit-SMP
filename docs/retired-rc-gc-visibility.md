# Retired RC Roots After Join Failure

## Pre-Implementation Review

1. Supported path: the selected source retains retired memory after join
   failure, but active GC membership is already reduced. Root retention must
   include discovery and relocation, not just an allocated list.
2. Previous work: `vm_registry_failed_join_retention` checks storage retention;
   `vm_retirement_join_composition` checks receiver and sender drain. Neither
   models a registered RC root remaining on an excluded processor during GC.
3. Worth investigating: an RC handle may be the only root for a movable Scheme
   object. A subsequent collection must update that handle even after the
   allocating processor retires.
4. Expected benefit: correctness only; no estimated speedup. The proposed
   contract does not serialize normal VM execution or disable SMP/GC.

## Source Facts

Authority: the pinned Gambit submodule and
`evidence/fixtures/vector-increment-arity-parity/source.lock.json`, SHA-256
`69d4ed5a544b029d5719bd363dd170f516b9bb56334d362c7290c1e7c48e7590`.

| Source function | Observed contract |
| --- | --- |
| `___vm_resize_pstate` | Publishes the reduced count; transfers donor memory only when `___thread_join` succeeds. Failure leaves the slot pending. |
| `execute_sync_op`, `OP_VM_RESIZE` | Publishes the resize error to surviving processors, then returns it. |
| `___current_vm_resize` | Returns the synchronized result to its caller. |
| `___garbage_collect` | Issues `OP_GARBAGE_COLLECT`; it has no pending-join admission check. |
| `garbage_collect_mark_strong_phase` | Calls `mark_rc` on each participating processor. |
| `mark_rc` | Scans that processor's `rc_head` list and updates its data roots. |
| `___transfer_mem_pstate` | Moves donor RC/still lists to the receiver; cleanup follows successful joining. |

The existing `pending_join_errno_recovery.scm` forces GC before the injected
join failure, not afterward. Its native PASS therefore does not qualify this
window. This is a source-guided protocol counterexample, not a reproduced
native use-after-free. Application ownership of an RC handle surviving its
allocating processor must be explicitly specified in the native regression.

## Model And Proposed Refinement

`retired_rc_gc_visibility.qnt` separates pending OS join, donor memory
quiescence, root-list ownership, storage allocation and GC relocation epoch.
The current-retention policy can keep storage allocated while the next GC
misses its RC root. Blind transfer before donor quiescence has a separate
counterexample; moving the call out of the successful-join branch is not an
admitted repair.

The positive design requires an actual donor memory-quiescence acknowledgement
before root handoff and before surviving Scheme execution resumes. OS-thread
and synchronization storage remains pending until successful join. The active
owner then scans the transferred RC root during GC. This is a sufficient
abstract design, not an implemented acknowledgement or C refinement.

The model bounds one retired processor, one root, one collection and one
transient join failure. Enabled-progress is not fairness or a guarantee of
recoverable POSIX join. Permanent failure and repeated epochs remain open.

## Actual Framework Checks

The source-bound model recipe passed all nine steps in 26.007330 seconds under
300 seconds. Safety and enabled-progress each explored 15 distinct / 18
generated states with zero states queued. Both rejected strategies produced
their required counterexamples, and all five exact trajectories passed.

The model plus standard-RC native positive campaign passed all fourteen steps
in 48.572570 seconds. Executable compilation took 2.300390 seconds and actual
execution 0.501567 seconds, under unchanged 300-second whole, 120-second native
step and 30-second execution ceilings. All actual process observations exited
zero, without timeout, and report reaped/quiescent groups.

The framework selected 11 compile/execution processors from host capacity.
The fixture independently enumerates its actual VM population, dispatches each
donor task to its specified processor and checks real P0 execution. It retains
movable vectors only through registered C RC handles, successfully shrinks to
one processor, forces GC, requires each handle to relocate, verifies vector
payloads and releases the exact number of handles. No `RTLD_NEXT`, pthread join
interposer or private cleanup API is used. This establishes the successful-join
control, not the failed-join window or the proposed acknowledgement repair.

Outer receipt: `4f963295654414046957a3a77d422966fc979ce2893f36421350205cf94b4099`.
Child receipt: `d4cdd105b5bfc6365774863b219840b5a34ab636a5c69a85cdd7a1f1ddb16d11`.
Engine: `67c1883a0b7c3eabd7173b2e0817ddef7fdc8a7957266f6d8f1ef8d658d0c69e`.
Inspection returns PASS/CURRENT with runtime/source-refinement admission false.
The original completed producer was reused; no bootstrap was repeated.

## Required Native Closure

- A registered RC handle owned outside the retiring Scheme thread, with no
  alternative Scheme root masking its visibility obligation.
- The actual reduced-count and failed-join path, then forced GC before retry.
- Checks of the relocated handle and payload, not merely a noncrashing exit.
- Physical donor quiescence before any transfer, pending-slot nonreuse,
  successful retry, exactly-once transfer and cleanup.
- CPU-derived multiple-VM populations and the original budgets; preserve all
  failures. Do not replace the original lifecycle or GC/FFI campaigns.

Test-process interposition authorization is still unresolved. No denied hook
is rerun here. Models may identify repair obligations but do not close the
lifecycle, GC/FFI, registry lifetime or full SMP gate.
