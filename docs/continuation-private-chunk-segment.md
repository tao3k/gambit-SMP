# Continuation Private Chunk Segment

## Decision And Source Successor

The origin/handoff composition is followed by one collector source successor,
not another general queue-lock or scanner-serialization experiment.

The current source ends a chunk during section rollover before the next copied
frame completes the previous frame's link. Stealers release the queue lock
before scanning `___sFRAME`; that scan does not acquire the producer's MISC
lock. This proves the source ordering, not that a native saved-stack witness
has executed that interleaving.

Changing only the stale allocation threshold to `alloc` would publish more
unfinished frame links. The successor therefore closes eligible chunks into
a private intrusive segment during `mark_captured_continuation`. Its two local
endpoints use existing chunk-link words: no per-chunk allocation, new PSTATE
field, global scanner lock or hardcoded processor count. After final link
completion and root retagging it splices the segment into the existing FIFO,
preserving the two publication barriers and wake-registration mutex order.
The ordinary `end_heap_chunk` entry retains immediate publication.

The private producer remains an active collector until it returns; it cannot
announce idle with hidden private chunks. Local-scan exclusion remains the
unchanged source predicate. Queue-lock duration covers only segment splicing,
not continuation copying or scanning. Wakeups are batched once per segment.
No numerical performance benefit has been established.

| Artifact | SHA-256 |
| --- | --- |
| `evidence/fixtures/continuation-private-chunk-segment/source.lock.json` | `7eba00fdb1e95be329f3e5a8e40044612be0c934e68c02331acd3e21f6d4751f` |
| `patches/fixtures/continuation-private-chunk-segment.patch` | `bdba2f8c15c898001113ae9a030bc36ffd85a82b8be4d4e05ffcfc911a5b6d44` |

Only `lib/mem.c` differs from the public-retirement parent. The framework
exported and reapplied all 22 locked files from the pinned submodule revision.
It reused the existing thin source workspace; no new retained tree was made.

## Verification And Limits

The finite model checks 1–4 chunks, arbitrary close/complete/consume schedules,
private/public/scanned conservation, link readiness and no hidden idle work.
These are proof-domain bounds, not a runtime limit or machine worker setting.
The old publication control finds an early scanner read at 31 distinct states.
Safety and no-stall, each with weak-fair progress, exhaust 98 distinct states.
The existing host-adaptive framework campaign took 11.279 seconds; individual
checks took 3.808, 3.719 and 3.743 seconds under unchanged 15-second caps.
Portable receipts are registered append-only in the protocol bundle manifest.

GNU GCC 16 `-fsyntax-only` passed on the successor `mem.c`, using the retained
bootstrap configuration header and dependencies. This is explicitly a mixed
configuration **diagnostic**, not current-header compilation, linking,
bootstrap, native execution or runtime admission. It produced no binary and
does not qualify the old executable for the new lock.

Remaining obligations: exact current configured-header build, physical
saved-stack/rollover regression, intrusive link layout and publication-order
refinement, full parallel GC/FFI and suite qualification, then performance.
Allocation failure remains the existing fatal heap-overflow path; no new
recoverable rollback or portable weak-memory proof is claimed.

**Cumulative completion remains 3/12. The new source is not native-qualified.**

## Prepared Public Native Regression

`models/gambit/native/continuation_rollover_public.scm` adds the missing deep
saved-stack workload, rather than changing the shallow VM topology test and
invalidating its historical fixture hash. It uses the framework's available
CPU count, pinned workers, a declared depth, condition-variable parking, two
coordinator-triggered collections and exact per-frame root/result checks.
Every worker must join and the VM must shrink successfully. It has no C hook,
interposition, private cleanup symbol or suppressed assertion.

The campaign must choose and bind depth from the locked section geometry
before running; a deep stack alone is not proof that the target rollover was
actually executed. All three concurrency flags and a current admitted source
producer are prerequisites. It must run in both GSI and compiled GSC scope,
under original campaign accounting, not an old binary or a new budget.

The preserved old reader parsed 29 forms without evaluating them. The related
32 static/portable-evidence tests passed in 0.054 seconds. Neither check is a
native run. The prepared source/model/fixture binding and remaining requirements
are in `native-regression-contract.json` beside the successor source lock.
