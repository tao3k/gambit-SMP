# c86 handoff alignment

2026-10-23. Source edit in the mutable c86 producer. Not a campaign receipt
and not 9/12. Qualifier, milestone, recipes, and historical recovery
receipts were not edited. gsi was not relinked and this path was not run.

The producer is
`.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6`.
`mem.o` and `setup.o` were rebuilt into that tree's `libgambit.a`.

What the edit does:

- The retiring worker calls `___retirement_reserve_pin` before marker
  retirement. That pin stays through claim, splice, and empty-donor
  destruction. Reclaim clears it only after the entry is marked reclaimed.
- After a real join 0, P0 publishes `JOINED` and CAS-claims `FINALIZER_OWNED`
  before `___retirement_take_tail_token` may call `setup_native_tail_leave`.
  A duplicate claim does not consume the tail again. A missing pin is not
  created on the joiner side.
- `___retirement_destroy_admit` refuses VM cleanup while any pin or noted
  join is unreclaimed. `vm_native_consumers_clear`, `___cleanup_checked`,
  and `cleanup_vmstate_locked` consult it before freeing.
- The shrink transcript try-locks the VM misc lock. Busy keeps the debt
  and returns. A mutex error other than busy, or a mutex unlock that
  returns false, calls `___retirement_shared_fault_stop`, which is `_Exit`
  with no host callback and no barrier. Ticket try does not take a ticket
  when the CAS fails. Ticket unlock still has no status word.

Also in this edit:

- The post-GC epilogue now runs after `___garbage_collect_pstate` returns.
  Every member crosses a noop barrier, P0 selects one already-claimed donor,
  and the selection and service result cross `barrier_sync_op` before the
  final noop barrier. `OP_RETIRE_SERVICE` is that payload. It does not join
  a worker and it does not create an OS join errno.
- `sync_mut` lock, unlock, condvar wait and signal, the setup guard, and
  `vm_list_mut` lock and unlock call `_Exit` when the boolean result is false.
  `___MUTEX_DESTROY` of `vm_list_mut` is unchanged.

Still open:

- No dependency cut is proved for a donor-private quarantine. `EBUSY` on
  scan-lock destroy keeps the descriptor and the pin. It does not call
  `_Exit`.
- Generic `___cleanup_mem_pstate` remains for callers other than this shrink
  path. The shrink path does not call `free_still_objs` or `___release_foreign`.
- Darwin still has no still-joinable `___thread_join` error followed by a
  later same-owner join 0. The count stays 8/12.

Clue continuation used before the edit:
`clue-read:5b4791a5ed04e5430b018835978f2ceabe044ef521786136badecb6411abe820`.
The processor-interrupt collective view stayed unclosed.
`executionAuthorized` and `runtimeAdmitted` stayed false.
