# Recovery and generation admission audit

The source under review is the retained observed-retirement checkpoint and its
incremental mutex-return successor. `lib/setup.c` is identical in both; the
successor changes only `lib/_thread.scm` and regenerated `lib/_thread.c`.

`recover_retired_processors` at setup.c:1106 calls the real `___thread_join` for
pending slots. Only success transfers memory, cleans the processor, clears its
pending flag and decrements the count. Child VM cleanup can return an error
without reclaiming the retained processor and an exclusive owner can retry.
Root cleanup has a separate sticky failure phase: setup and cleanup return the
same saved error before changing parameters or tearing down retained resources.
These are different recovery contracts.

The existing native normal mode observes a real pending runtime join and its
successful completion. The detached-live-thread controls induce an adversarial
ownership fault and a real Darwin join error. They neither manufacture errno nor
prove a supported, naturally recoverable failure. A detached thread cannot be
reattached; that control cannot establish successful recovery after an error.
No wrapper self-join substitutes for either runtime path.

A signal handler outside `vm_registry_enter` is not an admitted reader. Signal
handler uninstall plus seal/drain therefore does not alone account for an old
handler paused before admission. Reopening the same global admission state on a
later setup permits this abstract old handler to observe the new generation.
A counter increment at the first C instruction still cannot count a handler that
has not reached that instruction. An immutable generation token cannot simply
be assumed at signal delivery.

The executable conditional model is `runtime_generation_recovery.qnt`. Four
trajectories check conditional still-joinable owner recovery, non-recoverable
detachment, the cross-generation counterexample, and a host-quiescent control.
The accepted finite-state receipt is
`evidence/model-results/processor-interrupt-collective-wait/generation-recovery-qualified-04/receipt.json`.
It exhausts 15 distinct states. `noCross` fails with a four-state witness as
required; the characterization and no-false-recovery invariants pass. Progress
is conditional on the finite modeled transitions and fairness, not an OS-wide
join or handler-lifetime theorem. The first syntax failure, initializer-alias
conversion failure, and their original model bytes remain retained.

Two additional premises remain unimplemented and unaccepted natively:

- A real error followed by a successful runtime-owned join while the original
  thread remains joinable and the owner remains exclusive. No eligible natural
  error has been observed. Do not substitute detach, expired ids, self-join,
  join interposition, or writes to private pending fields.
- Quiescence of old OS handlers before reopening a new lifecycle. A host contract
  that accounts for every producer could supply this premise; ordinary admitted
  reader drain does not. A host thread paused before calling the API is only an
  external-producer control, not evidence of an already delivered OS handler.
  A native acceptance fixture needs a justified signal-handler lifetime contract
  or a source design that prevents reopening until that contract is established.

The host-removal action in the model is an explicit extra premise. It is not a
runtime patch and must not be reported as native cross-generation closure.
