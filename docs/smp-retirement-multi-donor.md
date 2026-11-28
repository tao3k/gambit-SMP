# Two donors, repeated GC and preparation abort

2026-10-22. Work item repair-9-12. Extends [the source-refinement audit](smp-retirement-prepare-refinement.md). Runtime acceptance remains **8/12**. No runtime code, Recipe, budget or implementation-worker operation changes.

## Checked scenario and outcome

The model has P0 and donors A/B, two moving collections, a preparation transaction with epoch 2, and stale acknowledgements labelled epoch/round 1. A becomes Ready while B is still active; B's first nested GC finishes, then B returns an error. P0 still has modeled fallible preparation work, which requests a second GC while that error is pending. All three remain collective participants, including Ready A and Failed B. Both donor roots and the error root receive the second GC's updated value. Only after P0's remaining work is closed does the old cohort decide abort, acknowledge the current epoch, discard A's temporary receiver root, and return from preparation. Cohort size stays three. The error root survives until its final modeled caller consumes the result.

Abort here means a common exit from preparation, **not termination of the old OS threads**. Participants may return one by one after the common completion point because no further preparation rendezvous depends on them. Callback effects remain recorded; no callback is replayed. Success is a separate initializer with receiver publication/source withdrawal at the modeled commit cut before cohort size changes to one. That atomic abstract cut is an implementation obligation, not an assertion that current C performs it.

This is a finite targeted extension: two donor callbacks each execute once, two GC rounds, one transaction; A Ready precedes B outcome. Arrival ordering and A-readiness relative to the first collection are explored. It is not an unbounded test of every callback count or an implementation trace generator. The second-GC request represents remaining GC-capable preparation work at P0; it does not claim current P0 cleanup necessarily allocates there. If implementation proves all such work nonallocating, this path is an extra conservative service obligation. Arbitrary callback reentry into Scheme or a nested resize remains outside the contract.

## Source-to-model refinement table

B = vendor Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882; P = retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P numbers are patch-file lines. The study does not inspect or qualify the implementation worker's moving candidate.

| QNT state/action | Actual source event / last consumer | Existing guarantee versus proposed change |
| --- | --- | --- |
| `startA/B`, `readyA`, `finishB`, callback counters | release(false) calls arbitrary execute_fn, B setup.c:158–166; cleanup walks under mutex, B:396–417 | Callback return exists; cleanup currently ignores it. Proposed persistent per-member Running/Ready/Failed and at-most-once cursor are required. Original queue removal is not callback return. Model failure is a returned/caught outcome; actual throw containment remains the local catcher obligation. |
| `requestFirstGC`, `requestSecondGC` | callback native allocation can reach garbage_collect; on_all_processors B setup.c:1131–1149 | Existing GC operation and interrupt rendezvous can be reused. Model requires prepare service on every old member; current shrink-withdrawal/callback order does not already supply that protocol. P0 may not park in join. |
| `arriveP0/A/B`, round-specific tags, `finishGC` | barrier_sync_op B setup.c:541–714 snapshots processor_count for the tree; existing collective return/root phases | The model tags are a specification of distinct rounds, not new C counters automatically required. Existing sync-message ordering can discharge the obligation if a source refinement proves each preparation round uses it without early exits/reused messages. No equality on stale phase bits may substitute. |
| `aSource/bSource`, versions and receiver locations | B mem.c:3969–3991 mark_rc scans header.data; P:3579–3593 per-processor RC scan and root barrier | Existing scanners update registered locations. Retaining bytes in an excluded slot is insufficient; sources in this model count as covered only while cohort=3. Proposed temporary receiver locations must be really registered on surviving owners. Model roots are representative strong roots, not a classification of all continuations/wills/weak references. |
| `finishP0Preparation`, `decide` | execute_sync_op_loop B:1067–1108 and P:4932–5013 service/NOOP exit; OP_SET_PROCESSOR_COUNT B:650–658 | Requires global no-future-preparation-work frontier. A/B outcome alone is insufficient while P0 still may allocate. Ordinary NOOP must not exit outer prepare; nested GC returns to its own invocation. Parent replay is conditional offer reachability as corrected in the prior audit. |
| `ackP0/A/B`, `finishAbort`, `leaveP0/A/B` | Proposed abort operation/phase on existing old-cohort collective; outer current_vm_resize catcher P:5090–5105 reopens admission | No existing shrink abort handshake is established in P. All current-epoch acknowledgements must precede common completion. Acknowledging does not permit early return; P0's outer error propagation must wait for completion. Prior-epoch tags in this model are injected stale inputs, not a proof of two actual transaction lifecycles. |
| `consumeResult`, `releaseResultRoot` | ___data_rc B mem.c:803–813 reloads current value; ___release_rc B:758–779 immediately unlinks/frees at last ref | Preserve traced error until the true result consumer; source-specific caller ownership must identify that consumer. The model assumes preallocated registered error storage before error publication, not untraced C payload rooting. Repeated GC updates that slot before consumption. |
| success `decide` | ___transfer_mem_pstate P:3301–3353 and current join-success calls P:4680,4864 | Existing transfer only splices still/RC lists and counters after joined-donor premise. It cannot simply be moved to a live-donor preparation phase unchanged. Model's successful handoff is a required linearization contract; exact nonallocating live-cohort ownership transfer and complete resource classification remain unproved. |

## Negative controls and discriminating witnesses

Each mutation is accepted only when TLC reports an invariant counterexample **and** the decoded trace contains the stated witness. Exit nonzero by itself is insufficient.

| Mutation | Required decoded witness / reason |
| --- | --- |
| Failed member returns early | B has left while preparation/abort still requires the three-member cohort. |
| Ready A withdraws source early | Abort removes temporary receiver; neither A source nor receiver remains registered. Local success cannot authorize irreversible source withdrawal. |
| Reuse first-GC arrivals for second GC | GC completes with at least one current round arrival absent; `staleGCUsed=true`. |
| Accept previous transaction's abort acks | Common abort completes without all epoch-2 acknowledgements; `staleAbortUsed=true`. |
| Release error root before result consumption | Movable error remains live but unregistered while consumed=false. |
| Replay failed callback | B callback count exceeds one, preserving the irreversible-effect boundary. |
| Decide before P0 preparation closure | Phase leaves Preparing while P0 still has modeled GC-capable work; no-future-producer frontier was not established. |

## Value for a small gate-9/10 repair

The extension rules out a tempting but insufficient implementation: per-donor Ready/Failed flags followed immediately by local return or root withdrawal. The minimum semantic repair needs three distinct boundaries: callback completion, **global preparation closure**, and common abort/commit completion. Existing collective messages and traced RC locations are candidates for implementing them; the model does not mandate a second barrier framework, new collector or global stop lock.

This strengthens the design evidence used to work toward gate 9 and gate 10. It does not close either native gate. The unresolved API decisions are: disposition/liveness of uncalled detached request suffixes; callbacks that invalidate another request or a resource needed to resume the old worker; actual supported GC/reentry contract; stuck/foreign-longjmp callbacks; root classes outside the representative strong slots; source-specific live-donor handoff; real memory ordering and repeated transaction reuse. A terminal-retained classification cannot be presented as successful recovery. Full native and first-eight regression qualification remain required on the same causal implementation.

## Verification and reproducibility

The existing Quint-to-TLA/TLC verifier is used with the same combined **30-second per-check cap**, final temporal schedule for positives, 12 workers, 1 GiB heap and 8 MiB stack. Each positive checks `safe` and weak-fair conditional `completion`; every modeled actor must eventually take its enabled finite step. Stuck callbacks are not abstracted into automatic success. The named trajectory explicitly checks A Ready -> B error -> second GC -> current-epoch abort -> all members leave -> result consumption -> root release.

An initial parser failure (`fail` is a Quint built-in identifier) is retained in audit 17aab174dcf54db9a05198247a967b72. The corrected model also makes successful receiver publication explicit: donor source roots do not count as scanned after shrinking the cohort. Old models and receipts were not overwritten. The actual result table and source/model hashes follow below; this documentation is not a native execution receipt.


## Actual results

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 0.587 |
| initAbort | PASS | 62 | 4.385 |
| initSuccess | PASS | 53 | 4.264 |
| initEarlyReturn | Decoded expected counterexample | 55 | 4.254 |
| initEarlySourceDrop | Decoded expected counterexample | 74 | 4.235 |
| initStaleGC | Decoded expected counterexample | 69 | 4.230 |
| initStaleAbort | Decoded expected counterexample | 69 | 4.251 |
| initEarlyErrorRelease | Decoded expected counterexample | 55 | 4.300 |
| initReplay | Decoded expected counterexample | 55 | 4.213 |
| initEarlyDecision | Decoded expected counterexample | 64 | 4.201 |
| readyThenFailureAndSecondGC | PASS | n/a | 0.639 |

Model SHA256: `de96a00d35734fbb0fd97d7eece623fa39e72da878384e7fba0ef4f5800d5fc6`. Raw audit: `.cache/tasks/repair-9-12/processes/audit/runs/763957cae1d740eb9b91e4053f5bb6a1/outputs/multi-donor-retirement`. All eleven checks accepted; source input hashes stable; no native execution.


## Next refinement

The [queue/epoch/typed-root contract](smp-retirement-implementation-contract.md) adds real two-epoch execution and ten decoded controls, recommends retaining the untouched suffix in the existing queue through one-node pop, and maps four required edit surfaces. It remains a separate bounded component model, not exhaustive product/native qualification.
