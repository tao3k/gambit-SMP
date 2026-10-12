# Migration, Retirement and Cancellation

## Source Facts

The source authority is the pinned Gambit submodule plus
`evidence/fixtures/thread-migration-resume-gate/source.lock.json` and its
cumulative overlay. No cache directory is a source authority.

In this source, `##thread-end!` sends an interrupt to a started thread; it does
not synchronously detach that thread from all processors. The target's
`##thread-resume-execution!` invokes queued interrupt handlers before calling
the captured resume action. Thus cancellation request and cancellation
completion must be separate model transitions.

`___vm_resize_pstate` makes removed processors exit after a barrier. P0 joins
them and transfers memory only after successful join. This is not evidence
that Scheme queued/running handoffs have been drained: successful OS join
alone cannot prove that their continuation will resume on a live processor.
The current source has no destination-borrow admission protocol established
by this model. Join-failure quarantine remains a separate open requirement.

## Model and Actual Checker Results

`models/gambit/thread_migration_retirement_cancel.qnt` models one saved handoff,
a cooperative cancellation request, destination admission closure, destination
claim, queue rollback to a live donor, completion and destination retirement.
The borrow represents a handoff dependency, not an implemented C refcount.

- Negative policy: retirement without handoff drain violates `lifetimeSafe`;
  31 generated / 18 distinct states. The control is an abstract unsafe policy,
  not a new native observation of a physical use-after-free.
- Design: safety and weak-fair completion pass, 38 generated / 20 distinct
  states. Cancellation completes as cancellation, not successful migration.
- Typecheck passes. No native runtime or release is admitted.

The existing host-adaptive verifier ran with 90 seconds per check. It selected
resources from the available host and memory plan, with no fixed CPU count.
An initially incorrect source anchor was corrected to `___vm_resize_pstate`;
the verifier reused the identical model checks and logs rather than rerunning
the negative route. The corrected, source-context-bound receipt is published:

`evidence/model-results/fixtures/thread-migration-resume-gate/retirement-cancel-contract/receipt.json`

The manifest is registered in `evidence/protocol-bundles.json`. Datalog exports
the checked finite protocol and its six open obligations; registration does
not close those obligations or grant native retry/release permission.

## Requirements Still Open

1. Implement destination ownership tracking and a pre-retirement Scheme drain;
   refinement must cover the actual queue locks, not just an atomic model step.
2. Select a live rollback processor with a generation-bound identity. This
   model assumes the donor remains live; arbitrary simultaneous donor removal
   is outside its checked domain.
3. Compose saved-stack/root copying and physical resource reuse, including
   failed join and rollback ownership, with the handoff protocol.
4. Refine cancellation delivery, handler exceptions, nested migration and
   stale resume-action snapshots. No user pin or thread-specific field may be
   reused as hidden migration state.
5. Add native cancellation/retirement regressions only after a causally reviewed
   source change, then complete full bootstrap and upstream suites before
   Gerbil build/test and performance acceptance.

The native Datalog transport tests currently have a separate sealed-provider
interface failure documented in `thread-migration-interrupt-requeue.md`.
That does not invalidate these TLC results, but prevents claiming the full
native Datalog/Gambit verification chain is green.
