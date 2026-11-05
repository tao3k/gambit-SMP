# Admission gate landed in the c86 cache source

2026-10-23. This is the first C step of `admission-lifetime-aba.md`. It is not a 9/12 receipt. `vendor/gambit` was not edited. No patch was written. `libgambit.a` was not updated and gsi was not relinked.

Source: `.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6/source/lib/setup.c`.

`make -C lib setup.o` with the tree's gcc-16 completed after the edit.

The stable `request_slots` array is process-lifetime storage. Each slot's `gate` is one sequentially consistent word: phase in the high half, count in the low half. `__GCC_ATOMIC_LLONG_LOCK_FREE` must be 2. Enrollment is `OPEN,n -> OPEN,n+1`. Close is `OPEN,n -> DRAINING,n`. Destroy is `DRAINING,0 -> DESTROYING,0`. Finish publishes `DEAD` and clears the VM pointer under the slot lock.

`___pstate_request_acquire` checks `incarnation` and completes that enrollment CAS before it compares the snapshotted VM pointer. A mismatch releases the count and does not read fields of the caller's pointer. `___pstate_request_release` decrements the same word and does not touch the VM. Underflow calls `___retirement_shared_fault_stop`.

`cleanup_interrupt_resources_pstate` no longer reads `producers` or writes `phase` outside the slot lock. A published slot is destroyed only after `admit_begin_destroy` returns the exclusive ticket. `___cleanup_pstate` returns without a second teardown when the gate is already `DESTROYING` or `DEAD`.

Still open: the other units in the protocol table, entry K, native barrier cases, and both repair-9-12 lifecycle receipts. The milestone stays 8/12.
