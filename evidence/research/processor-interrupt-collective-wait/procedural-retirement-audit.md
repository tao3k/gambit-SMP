# Procedural interrupt retirement: source and reachability boundary

## Identity and question

The selected runtime is vendor revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the cumulative patch in
`source.lock.json` in this directory. This is not the unpatched vendor tree.
The question is whether an admitted operation can outlive queue draining and
touch a destroyed mutex, processor memory or select-abort resource.

## Producer and consumer inventory

The inventory covers `lib`, `include`, `examples` and `tests` in the selected
source, including generated C in the final symbol scan. It cannot enumerate
unregistered embedding clients outside that source revision.

| Path | Target and protection | Boundary |
| --- | --- | --- |
| `os_setup.c:heartbeat_intr`, `terminate_intr`; `_kernel.scm` heartbeat and `examples/misc/signals.scm` | `___raise_interrupt`, registry admission/reference count through complete VM broadcast | Reader drain protects child unlink and wake. Pending bits contain no PSTATE pointer. Does not enqueue procedural payloads. |
| `os_setup.c:user_intr`, called by TTY signal/console handler | Direct root VM P0, not registry admission | Global cleanup removes handlers before root resources. Handler removal alone is not a proof of cross-thread in-flight handler quiescence; this is a separate root teardown obligation, not evidence of a child procedural-mutex race. |
| `mem.c` completed GC notification | Current processor, under runtime ownership | Must finish before its owning OS thread is joined. Not a procedural queue producer. |
| `setup.c` synchronous-operation broadcast; `_thread.scm` recipient notification; high-level interrupt queue | Live VM/processor participants | Their lifetime depends on processor retirement/join and foreign-call admission. High-level Scheme queue is not the procedural C queue. |
| Exported `___raise_interrupt_pstate`, `___raise_interrupt_vmstate` | Raw pointer supplied by embedding caller | No independent registry lease in these entrypoints; caller must maintain target lifetime through post-unlock wake. |
| Exported `___raise_procedural_interrupt_pstate` | Raw PSTATE; locks queue, enqueues, unlocks, wakes processor | No local close/reference handshake. No internal call site found beyond definition/function-table registration. The owner must stop and join external producers. |
| `service_procedural_interrupts_pstate` | Removes head under mutex, unlocks, calls `execute_fn`, then relocks | An empty queue does not prove the consumer is quiescent. Joining only producers is insufficient if the consumer remains active. |
| `cleanup_interrupts_pstate` / `cleanup_interrupt_resources_pstate` | Drain under mutex; later destroy | Safe only after all target users, including detached callbacks and wake tails, have stopped. `procedural_interrupts_ready` is ownership bookkeeping, not admission. |

## Model and conditions

`models/gambit/procedural_interrupt_retirement.qnt` makes registry admission,
direct admission, in-flight wake, detached callback, queue drain and final
destruction separate states. It reuses the already identified failure classes
of `sync_resource_users.qnt` and `vm_registry_interrupt_admission.qnt` without
claiming a proof import/composition that has not been implemented.

Three deliberately incomplete retirement policies must produce counterexamples:
registry-only closure, forgetting the post-unlock wake, and treating detached
callbacks as quiescent. The positive contract assumes atomic owner admission,
successful joining, returning callbacks and the same storage generation.
It does not assert the raw C entrypoint implements that contract.

Private constructor rollback is unpublished and has no legitimate external
target users. Published VM cleanup explicitly requires joined direct users,
closes foreign-call admission and drains registry readers. Thus the local
window is not yet a reachable violation of the joined-owner contract.

## Native falsifier

Use only public function-table entrypoints and ordinary pthread coordination.
Hold a real procedural callback after it was detached, observe an empty queue
under the actual mutex, and enqueue from capacity-derived external producers
while that callback remains active. Then release and join the consumer,
enqueue another batch, join all producers, and retire the child while a global
broadcast producer remains active. Check exact execution/release counts and
final resource ownership. Never destroy while the callback or direct producer
is active: that would violate the public ownership premise and invoke UB,
not establish a valid-program runtime defect.

The proposed falsifier passed on the selected runtime; the exact observations
and receipt identities are in `procedural-retirement-observation.md`.
This PASS only witnesses the listed schedules; it cannot prove coverage of
all embeddings, native signal delivery or failed joins. No bootstrap is needed
when source/configuration/core checkpoint identities remain unchanged.

## Current conclusion

The queue-empty/quiescent equivalence is unsound. A source repair is warranted
only if a producer can cross retirement under supported ownership conditions,
or if the intended public contract permits concurrent cleanup. A ready-bit
check is not a fix: it cannot prevent destruction between check and lock.
Do not assign this gap as the cause of TFIB/pipe failures without causal evidence.
