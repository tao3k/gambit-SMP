# Split: lifecycle count contract and runtime stability

2026-10-24. This is the next Grok handoff. It does not change runtime, the qualifier, recipes, or historical receipts. It does not count as 9/12. Recorded qualification remains 8/12. A blank causal cell below is **尚无方案**. Another model pass does not fill it.

## Two problems

| Problem | Current judgment | Required handling |
| --- | --- | --- |
| Lifecycle count contract | On the constrained legal Darwin shrink path, no errno-then-same-owner-join-0 sequence is proved reachable. | Review the contract on its own. Do not require an execution path that does not exist. |
| Runtime stability | Interrupt hang and TFIB SIGSEGV still have no complete source cause. | Decide the repair from a real failure on one producer. A retirement protocol or a diagnostic model is not that cause. |

## Lifecycle target, not a 9/12 implementation

The implementable lifecycle target is: one reaper, fixed from its first join; pending keeps the handle, incarnation, and roots; transfer is allowed only after a real join 0; an error keeps ownership; the completion result is consumed once.

That target still forbids early transfer, a second join, and early reclamation. The reaper is not the original P0 OS owner, so its join 0 is not `LIFECYCLE-JOIN:OS-JOIN-ERROR` followed by `LIFECYCLE-JOIN:SAME-OWNER-JOIN 0`. It needs an independent contract review. Until that review, do not edit `qualify_nine_of_twelve`, the two historical recovery receipts, or the milestone count.

| Required cell | Status |
| --- | --- |
| Real failure transition blocked by a code change | **尚无方案.** The legal shrink joins a thread that has already called `___thread_exit` and gets 0. `EDEADLK` 11 stays 11 for that same owner. No source edit is named that creates a still-joinable nonzero non-`EINVAL` return and then a same-owner 0. |
| Who takes over after failure | Proposed reaper, after contract review. Not implemented. Not the current P0. |
| Same binary confirms or refutes | **尚无方案.** No one binary has produced the required transcript. Do not rerun the legal shrink to mint it. |

## Stability: interrupt delivery

The closest existing evidence is interrupt request delivery, not processor retirement. The required loop is one queue owner for the request, an enqueue commit, a migration recheck, and one execute-or-terminate reply.

Changing only the thread-queue enqueue plus a concurrent wakeup has already failed native batches. Do not recommend that same scheme again. Thread-only results and tail/self-loop guards are prior failures, not a new design. See [causal alignment](repair9-failure-causal-alignment.md) and [carrier remedy](fault-carrier-root-remedy.md).

| Required cell | Status |
| --- | --- |
| Real failure transition blocked by a code change | **尚无方案.** The reported sender waited on the second result-mutex lock. Counts and empty heads do not identify that request. The duplicate-live-node append is a hypothetical counterexample, not a captured transition on the corrected source. |
| Who takes over after failure | **尚无方案** for the retained request. The closed loop names the owner only after a request-specific record: queue loss, masked park, runnable thread without START, dispatcher without START, callback without reply, or result/unlock without sender wake. |
| Same binary confirms or refutes | Not run. The next observation has to be on one frozen producer, with the same gsi for every row. A different binary cannot confirm the cut. |

## Stability: TFIB

The original SIGSEGV binding remains `.cache/tasks/repair-9-12/fixtures/bazel-profile-gc-ffi-inventory-vector-inc-1`. It does not contain the first illegal scan record. A null-pointer injection checks the diagnostic carrier. It does not explain that crash. Do not add another F64 skip or a catch around `mark_array`.

| Required cell | Status |
| --- | --- |
| Real failure transition blocked by a code change | **尚无方案.** No first committed cell or header record from the original faulting `mark_array` is bound to a writer. |
| Who takes over after failure | **尚无方案.** Frame root, stale RC/register root, and bad heap content are different repairs. The fault address alone does not choose one. |
| Same binary confirms or refutes | Not run. The same producer must keep the first pre-read record across the original `(go 15 5000)` SIGSEGV. A later carrier-only probe is not that record. |

## What Grok does next

Do not write the missing errno path. Do not implement the reaper as 9/12. Do not ship another thread-queue-plus-wakeup patch. Do not treat a QNT pass or a null probe as the TFIB or interrupt cause.

The next source edit needs one filled row: the real transition, the code that blocks it, the owner after failure, and the same-binary check. Until a row is filled from a retained failure of that binary, the cell stays **尚无方案**.
