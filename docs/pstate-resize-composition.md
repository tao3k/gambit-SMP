# Processor Setup And Resize Composition

`pstate_resize_composition.qnt` joins the previously separate failed-slot setup
and successful-slot caller rollback obligations. It is a source-guided bounded
contract, not a source refinement proof or attribution of a reported GC crash.

In selected candidate026 `setup.c`, `___vm_resize_pstate` calls `___setup_pstate`
for consecutive new slots. On error, `while (--i >= initial)` cleans only prior
successful slots, resets `target_processor_count_`, performs the barrier and
returns. The failed slot is excluded from the caller cleanup loop. A setup repair
therefore must unwind that slot before returning the error; fixing just the
outer cleanup pointer cannot satisfy this contract.

## Bound And Assumptions

Grow 1 to 3: one existing slot, two new slots, five atomic owned setup stages per
new slot. Initial existing resources remain live. Eleven initial choices cover
success or a failure at each stage of either new slot. A stage has an abstract
resource token; this does not model partially allocated OS or heap internals.

The successful-slot cleanup transition assumes the callee really releases owned
resources safely. Current C does not yet satisfy all synchronization resource
lifetime requirements. This composition does not make that assumption true.
VM0 borrowed initialization stays in `pstate_setup_transaction`; this resize
model does not invent a borrowed resize slot. Old processors remain parked and
the synchronous population commit is abstracted as one action.

GHC's phase/participant reasoning motivates explicit population readiness, but
the failure ownership boundary comes from Gambit's own caller, not from the
paper. The manifest binds cached paper context without claiming the paper
specifies processor construction.

## Independent Controls

| Control | Property |
| --- | --- |
| Failed slot returns without self-unwinding | `localRollbackSafe` |
| Caller cleans the failed slot instead of the successful predecessor | `callerRollbackSafe` |
| Caller returns with stale requested target | `targetSafe` |
| Population published before all slots are ready | `publicationSafe` |
| Caller cleanup destroys the existing slot | `existingSafe` |

Each control is injected separately, not asserted to exist in selected C. Positive
checks require all five safety properties plus completion under weak fairness.
The shared verifier and publisher are reused; no candidate-specific Python runner
or fixed host worker count is added.

The first complete campaign rejected all five controls as expected. The positive
safety and temporal check exhausted 109 distinct states (120 generated, no queued
states) in 21.778 seconds. Portable logs, counterexamples and a source-bound
receipt are in `evidence/model-results/pstate-resize-composition/`. This is model
evidence only; runtime and release admission remain false.
The older `vm-resize-rollback.json` matches the current base model hash but lacks
the stable-source admission required by the current index. It is preserved as
historical evidence, not retroactively upgraded. That parent receipt dependency
therefore remains open even though this newer composition has completed checks.

## Remaining Source Obligations

Thread creation occurs after population commit in actual C. Its fatal-error TODO
is explicitly outside this model, not turned into a successful rollback path.
`setup_os_and_mem_pstate` also delegates rollback: when memory setup fails after
OS setup succeeds, it already calls `___cleanup_os_pstate` before returning.
The caller composition abstracts that boundary. The strengthened setup model
now represents its delegated OS resource release and checks sequential cleanup
against live resources; an extracted-function GNU GCC fixture observes the actual
helper with mocked primitives. A C repair must not call unconditional OS/memory cleanup on
that error path and double-clean resources already unwound by the helper.
On a later synchronization setup failure, however, both OS and memory setup have
succeeded, and `cleanup_os_and_mem_pstate` cleans memory before OS. Explicit
stage ownership and cleanup order are required for the source refinement.
Shrink/reuse, global VM teardown, external interrupt senders, admitted late
signalers, weak memory and real OS-call progress also remain open. In particular,
destruction in child cleanup is not justified by this model. Native acceptance
still needs the same GNU GCC artifacts with all three flags enabled, GC and
multi-VM tests, complete bootstrap and Gerbil build/test.
