# Current-source registry topology qualification

## Actual native result

The existing host-derived `registry_topology_grid.scm` completes and prints
`REGISTRY-TOPOLOGY-GRID:PASS`, exit zero, no timeout. All original fixture
assertions remain unchanged.

- Native executable compilation: **1.481442 seconds**.
- Native execution: **1.262543 seconds**.
- Native stage including checks: **3.522341 seconds**.
- Supervising process: **12.652215 seconds**; whole run **12.885300 seconds**.
- Inputs stable; parent reaped; process group quiescent.
- Source/configure/seed/core all PASS with `executionLaunched=false`.
  The failed original interpreted aggregate remains failed. Only its verified
  successful build prefix is consumed. **No bootstrap is repeated.**

On this observed twelve-CPU host, the existing allocation policy exercises:

| Independent VMs | Processors per VM | Root plus interrupt driver |
| --- | --- | --- |
| 2 | 5 + 5 | 2 |
| 3 | 4 + 3 + 3 | 2 |
| 4 | 3 + 3 + 2 + 2 | 2 |
| 5 | 2 + 2 + 2 + 2 + 2 | 2 |

The program derives these populations from available capacity; twelve is not
a configuration constant. Each population performs at least sixteen resize
cycles per VM with pinned processor work, rooted values checked across forced
GC, worker joins, shrink to P0, independent ownership and cleanup under an
overlapping global interrupt producer. The existing assertions require actual
interrupt overlap and every owner to complete. The marker is emitted only
after all selected populations. It is not per-population timing telemetry or
a measurement of physical CPU affinity/utilization.

## Bound identities

- Source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
- Cumulative patch: `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
- Program: `078e34ef259dbcb66343ce19219a2b16b67f64aa2a55e0e17c25d6e3db36f35d`.
- GNU compiler: `406040ac6e22d01468e601a5aaa548e60af1c151efb056aa45d485d6804f0cd4`.
- Profile: `3aa072e9ced23ba963d623476f9e2380172d71b7c747188386dcd07c252d695b`.
- Engine: `fe7d8cdf9c19a8ba59a48421adf0bd9d279a7ccd1d0c1bdb8821ca01b8cd4889`.
- Outer receipt: `af41ae6abbb6cfcd856cfb62c84d41c2bd20b4fe4afa07e8c10372a207231dc9`.
- Child receipt: `cde123e81b474528723cda7f1f20e3ead5b8469e50269316f45101df9cc03e66`.

## Model/source boundary and retained failures

The existing implementation already contains the reader admission/replay,
resource grace and all-changed-count publication repairs. This run does not
invent or reapply another C delta. See the
[current source mapping](registry-lifetime-source-audit.md).

Before execution, the source-bound writer and count-publication checks pass:
1533 distinct / 3563 generated writer states and 90 / 150 publication states,
with three decoded old-policy counterexamples. Receipt:
`8b8e512e4b971cc4917768fb5f3b132d6889685aa63e08ae18298e5d8de47bad`.
The original 15-second per-check ceiling is unchanged.

The first manifest selected the guarded-policy-only `noopNoWrite` predicate
as an old unguarded-policy counterexample; that expected-negative check
correctly found no violation. The DENY receipt is retained:
`f3aac1571bf6d0d0e061f46e439d2904144230cadb8aedaa74f546c7e8b0f8b6`.
The corrected old no-op control checks `safe`, exposing its overlapping count
access, without weakening the positive invariants or enlarging a timeout.
An initial seal command also incorrectly supplied a Recipe as an output path;
the framework rejected it before any native execution.

The subsequent in-place multi-writer model strengthening explicitly gives replay
its own lease, captures the current epoch on admission, and prevents a second
writer publishing until delivery/release. It preserves the original writer
bypass counterexample and adds a missing-replay-drain counterexample. The latter
captures epochs `[1,0]` at replay admission; a faulty second writer publishes
`[1,1]` while reader 4 still owns that lease. The decoded trace has 13 states,
SHA-256 `c62fa1f11d9da925267bfe55d4e9aa757281843114a570fc0ec4dfc9881c75d2`.
It is an injected old-policy counterexample, not a captured native failure.

The strengthened positive protocol exhausts **1661 distinct / 4003 generated
states**, queue zero, with conditional temporal progress. Both model positives
and all four negative controls pass within the original 15-second ceilings.
Receipt: `9fd635e3fc77c3e28eb36092436306997ec1bbdf6321c8c4675eb6a8c1e0bfe5`.
All five trajectory controls pass in a separate guarded process: 1.370214
seconds, exit zero, no timeout, process group quiescent. That intermediate model
SHA-256 is `5c586fd442b9df1f6aa163c8a0bd33924e6deb9a63abe50a41f1600a3c41fa0a`;
its exact bytes remain in `models/gambit/history/vm_registry_cross_vm_progress_replay_publication.qnt`.

Grok's completed source review correctly distinguished this publication
exclusion from a proof of actual resource survival. The existing model is now
extended with prepared, live, visible and captured incarnation sets and
per-owner reclamation. Epoch/incarnation labels are ghost resource identities,
not C `startup_epoch` or `scheduler_epoch` fields and not a proposed hardware
generation check. The model still abstracts a completed old barrier and
successful external joins; it is not literal C control-flow refinement.

The final positive explores **1944 distinct / 4777 generated states**, queue
zero. Two positives and all six negative controls pass within the unchanged
15-second ceilings. Added controls reject freeing a still-visible incarnation
and retaining an old visible incarnation across replacement. The positive
post-publication trajectory retires the old incarnation while a replay reader
still owns only the new one: safety does not require blocking all new readers.
All **eight trajectory tests pass**, exit zero, no timeout, process group
quiescent, in **0.876358 seconds** under the existing process guard.
Final model: `60bd4b7f61359c801b5379ea64a3c6315230f2e38be68c50c2eb134f5cbff20d`.
Final source-bound receipt:
`b1f51c1b7b22830785a64b1369cef4d1f04dd7c76da4fadb653ee3c0f621ca6f`.

The native result is preserved independently; this later proof does not mean
the frozen execution ran those newer model bytes or that its global input map
became current again. Actual runtime source, program and profile are unchanged,
so no bootstrap or unchanged native rerun is justified solely by a proof edit.
No new C delta is manufactured to restate the already-integrated repair.

Successful OS joins and externally owned direct-user discipline remain
assumptions, with actual happy-path execution here. Lifecycle fault injection,
complete GC/FFI, Gerbil correctness, current-source full inventories and release
latency populations remain separate obligations. This is not whole SMP or
release admission and is not a matched performance comparison.
