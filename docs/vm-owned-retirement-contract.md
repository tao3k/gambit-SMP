# Owned VM Retirement Contract

This research candidate extends registry reader admission with one combined
processor/VM retirement operation. It does not change the existing embedding
cleanup entry points or claim that all embedding clients are safe.

## Ownership And Order

`___cleanup_owned_vmstate` requires a non-root, successfully initialized VM,
exclusive lifecycle ownership, joined external/direct PSTATE users, and completed
cohort shrink to P0. Processor count is a rejection check, not proof that users
have joined. Concurrent global setup/teardown is outside this contract.

The caller finishes its execution and joins workers before entering cleanup.
The helper rejects the root VM and processor counts other than one. It then
locks registry mutation, closes admission and drains registry readers. A sealed
generation returns an error without releasing resources. Successful retirement
cleans P0, unlinks/cleans the VM, opens admission, unlocks mutation and replays
pending interrupts. Replay never runs under the mutation mutex.

The native fixture now calls this combined helper instead of freeing P0 before
the public VM cleanup operation. Failure retains the VM and TLS resources; the
containing fixture exits rather than freeing a live allocation. Ordinary VM
execution and parallel GC are not serialized. Only the existing registry
mutation/retirement critical section is extended over resource cleanup.

## Model And Source Correspondence

`vm_registry_processor_retirement.qnt` checks a published VM, one reader and
cohort completion. The old early-resource-cleanup order has a real finite-model
counterexample. The proposed order exhausts 26 distinct / 38 generated states
with an empty queue for both safety and finite deadlock checks. Three concrete
positive/negative trajectories also pass. All verifier runs respect 15 seconds.

`___raise_interrupt_pstate` can call `___device_select_abort`; POSIX cleanup closes
the select-abort pipe and subsequently resets its descriptors. That reset alone
does not establish a happens-before edge for an already admitted reader. The
model's resource-use property is conservative: it identifies a protocol gap,
not an observed native crash or proof that every late interrupt reaches write.

The synchronization core from procedural-interrupt initialization through the
declaration of VM OS/memory cleanup remains unchanged from the previously
completed bootstrap candidate. The new helper is outside that core. Its exact
bytes are sealed in `owned-retirement-source.lock.json`; older source locks and
bootstrap receipts remain unchanged. The previous bootstrap's PASS does not
qualify this new helper or the changed native fixture.

## Conditional Investigation Only

GNU native atomics, all three concurrency flags, adaptive shared CPU allocation,
the original bootstrap scopes and 600-second containing deadline remain required.
Historical failures and causal references remain bound to their original bytes.
The new source is a material lifecycle change on construction/interrupt/cleanup
paths, not proof of historical timeout causality or a performance improvement.

Physical C memory ordering, signals during cleanup, direct PSTATE users,
constructor/global-shutdown overlap, failure injection, API export portability,
arbitrary signal storms, GC/FFI and release performance remain native/source
obligations. The candidate remains GNU-backend research code, not an admitted
release patch. Both complete bootstrap passes, exact source closure and child
teardown must independently pass before exporting another producer.
