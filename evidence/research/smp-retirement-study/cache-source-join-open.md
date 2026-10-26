# Cache source join is still open

Vendor `gambit` is not the repair tree. The campaign source already materialized under `.cache/tasks/repair-9-12/build/gambit-core/`. There is no `.cache/repair19` directory. The latest handler-quiet materialization is `ce848e4d7a188e379b9f50ebe8e3528ca49ed7b619803461334aad6da19f97cf/source`.

That `lib/setup.c` stores `handler_quiet` and calls `___thread_exit` before processor 0 calls `___thread_join`. `___thread_join` is `pthread_join`. The join-probe for `.cache/tasks/repair-9-12/lifecycle-boundary-current-5` printed:

```
LIFECYCLE-JOIN:NO-STILL-JOINABLE-ERROR
(11 0 1 0 11 0)
```

The first resize returned 0, so `___lifecycle_join_os_errno` stayed 0. A same-owner `EDEADLK` retry on this Darwin host stays 11 until that owner exits. No patch was added from this read. The count stays 8/12.

Framework continuation `clue-read:9d130d9ea353179e0e5cfc112d119f8bff31ec201ee0ec2c817e846ea72e149d` matched `runtime-retirement-model`. A repeat of that same binding kept the same token. `evidence/scenarios/runtime-lifecycle/repair-9-12-native.view.json` leaves `repair-9-12-first-join-zero` and `repair-9-12-edeadlk-retry` unclosed. `runtimeAdmitted` is false. `executionAuthorized` is false.

`evidence/research/smp-retirement-study/darwin-join-feasibility.md` finds no legitimate shrink-graph trigger for a nonzero non-22 `pthread_join` return followed by same-owner join 0. Target cancellation can reach that pair and is excluded. `lifecycle-pending-join.contract-proposal.json` is `evidence-proposal-not-activated`; `oldCounterPredicateStillActive` is true. No cache runtime edit, no new patch, and no `gambit-smp` rerun followed this read. `tests.test_current_checkpoint_qualification` is 11 tests OK. The banner helper returns false for `LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS`. The milestone stays 8/12.
