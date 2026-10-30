# Callback preparation is split from final destruction

2026-10-23. Follows `async-destruction-callers.md`. Not a closure and not 9/12.
`vendor/gambit` was not edited. `libgambit.a` was not updated and gsi was not relinked.

Producer source: `.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6/source`.

`prepare_procedural_callbacks` detaches the procedural queue under its mutex, then calls `release_procedural_interrupt` with that mutex released. A non-`___NO_ERR` callback is not called again. Its uninvoked suffix is put back on the queue. `cleanup_interrupt_resources_pstate` destroys the mutex only after that preparation returns `___NO_ERR` and the queue is empty, then sets `procedural_mutex_destroyed[slot]`.

`free_still_objs` calls `___release_foreign` while `still_objs` stays published. A non-`___NO_ERR` result sets `still_callback_debt` and returns without `free_mem_aligned_heap`. Storage is freed only after every foreign release has returned `___NO_ERR`, and `still_storage_destroyed` blocks a second free. The free pass does not call `___release_foreign` again.

`make -C lib setup.o mem.o` succeeded with the tree's gcc-16. Configured call coverage, real root maps, and native fault injection are still missing. The milestone stays 8/12.

`callback-preparation-protocol.md` keeps the count at 8/12. A later `free_still_objs` now returns immediately when `still_callback_debt` is set, so a consumed `___release_foreign` is not called again and an unclassified suffix is not dispatched. `prepare_procedural_callbacks` records `procedural_callback_debt` and an invocation nonce; a later entry returns the saved error and does not invoke another callback. `procedural_mutex_destroyed` and `still_storage_destroyed` still block a second teardown. This is not the rooted job ledger, nested frame stack, or regenerated `_thread.c`. `tests.test_current_checkpoint_qualification` is 11 tests OK. No gambit-smp rerun. The milestone stays 8/12.
