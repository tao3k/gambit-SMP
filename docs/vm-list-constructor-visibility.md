# VM List Constructor Visibility

## Route Review

The route is to characterize the source's actual publication guards before
changing list synchronization. Existing constructor rollback models do not cover
the concurrent global-table registrar and ordinary interrupt observer. The
benefit is rejecting invalid repairs and avoiding removal of guards, not a
measured speedup. No unchanged native failure is rerun.

`___setup_mem_vmstate` prepares roots under `vm_list_mut`, sets the new node's
`prev` and `next`, then publishes list links. `___glo_list_add` holds the same lock
while visiting the list, growing VM root tables, and publishing the new global
generation. A failed global registration does not advance the global count.
Simply delaying list publication without handling intervening global generations
would be a different protocol, not an obvious safe replacement.

`___raise_interrupt` traverses reverse links without `vm_list_mut`. Its disabled
lock block explicitly records possible recursive-mutex deadlock. A same-thread
asynchronous handler must not wait for the interrupted writer's nonrecursive
mutex. Ordinary heartbeat/terminate requests are masked while the fresh P0 is
unready; the constructor initially enables only the synchronous-operation bit.
This does not establish the safety of synchronous/procedural interrupt callers.

## Model And Scope

The model has one fresh zeroed non-root VM, one global registration, one ordinary
interrupt, initial global generation 0/1, and a sequential constructor. It explores
registration failure and same/different-thread handler delivery. Sequential
consistency, valid root-table growth and initially zeroed interrupt fields are
assumptions, not proofs of C pointer publication or arbitrary embedding inputs.

Four controls remove root preparation, remove node-link preparation, enable
ordinary interrupts before P0 readiness, or insert a mutex-taking handler. These
are injected regressions/proposed repairs, not attributed source/native bugs.
The positive `init` preserves the source guards and is deliberately classified
`protocol`, not `fixed`. The shared framework now permits negative controls on
characterization models without inventing a repaired initializer; existing
characterization models without controls retain their original checks.

Campaign001 rejected all four controls and checked `guardSound` plus temporal
progress: 432 distinct / 752 generated states, zero queued, 32.536 seconds for the
positive check. Source and model context stayed stable. Portable logs and receipt
are under `evidence/model-results/vm-list-constructor-visibility-model/`.

No unpublication, storage reclamation or constructor-error drain is proved.
POSIX heartbeat cleanup sets the timer off and handler disposition to ignore;
that alone is not a proof that an already running callback has returned. Global
shutdown and live-VM rollback have different admission constraints. Datalog keeps
`vm_list_reader_retirement` and `vm_list_c_memory_order` open. Mutex locking in the
handler is rejected, not proposed as their solution. No runtime patch, bootstrap
or performance claim follows from this source characterization.
