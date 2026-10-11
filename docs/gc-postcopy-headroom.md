# Post-Copy Allocation Admission

## Evidence And Path Review

- Basis: keep the useful PR988/PR1038 repairs and the admitted prior source
  inventory; do not replace GC or rewrite synchronization.
- New evidence: repeated observations of one optimized diagnostic compiler
  show completed GC cycles 97 then 169. This disproves persistent deadlock
  over that interval, not every possible synchronization failure.
- Existing route: `heap_allocation_headroom` already reserves the overflow
  reserve and one next section beyond the initial processor/live floor. That
  work is retained. It did not model extra sections assigned during copying.
- Source gap: `resize_heap` floors section count using processor population and
  live-word totals. `compute_free_heap_space_approximately` subtracts actual
  assigned sections. These are different quantities when copying assigns more
  sections than the initial processor floor. `___heap_limit` requires one
  section of approximate free space; the prior floor need not leave it.
- Expected result: eliminate this allocation-admission shortfall, potentially
  reducing repeated GC. No percentage improvement was assumed before native
  validation; larger memory usage and maximum-heap behavior require review.

The observed 25 assigned sections during strong marking are not claimed to be
the final post-copy assignment. The source arithmetic and controlled model
establish the conditional shortfall; the diagnostic GC rate motivates testing
it, not proof that it is the sole timing cause.

## Model And Source Change

`gc_postcopy_headroom.qnt` checks 1/2/4/12 processors, zero to two additional
assigned sections, and capped/uncapped cases. Its old counterexample has four
processors, nine assigned sections and eleven total sections: free space is
57,336 words, below the 131,072-word next-section requirement. The fixed model
explores 25 distinct states (601 generated, zero queued). It does not prove
copying, allocation failure, max-heap recovery, C overflow or performance.

The five-line candidate in `resize_heap` raises the existing lower bound to
actual assigned sections plus the existing reserve/next-section headroom.
Maximum-heap clamping remains after this lower-bound calculation. Source
inventory recovery proves the candidate changes only this delta over candidate
017. Lexical binding checks source order; it is not a C semantic proof.

## Native Acceptance Boundary

Candidate 018 uses GNU GCC, multiple VMs, threaded VMs and SMP, with automatic
host processor selection (12 on this run) and the unchanged 20-second per-stage
budget. First `table_decode` regression passes:

| Stage | Seconds | Result |
| --- | ---: | --- |
| Interpretation, including forced GC | 1.949 | PASS |
| Executable compilation | 13.139 | PASS |
| Compiled regression, including forced GC | 1.850 | PASS |

Receipt: `evidence/model-results/native-postcopy-decode-host-pass.json`.
The queue-only control timed out at 20.007 seconds; it has no completed compile
time, so it cannot support an exact speedup ratio. Interpretation did not get
faster. Repeated stability, full native suites, threaded bootstrap and Gerbil
correctness/performance remain required. This is not a release patch yet.

## Follow-Up Acceptance

Two planned successful-candidate repetitions also pass all three stages, without
changing the candidate or budgets:

| Round | Interpretation | Compilation | Compiled Test |
| --- | ---: | ---: | ---: |
| 1 | 1.949 | 13.139 | 1.850 |
| 2 | 1.906 | 11.892 | 1.912 |
| 3 | 1.184 | 13.572 | 1.614 |

The generic isolated upstream-suite adapter additionally passes all nine pinned
table files in interpretation (1.266 seconds) and compiled mode (72.685 seconds
for the whole nine-file mode). It preserves upstream exit/count assertions,
isolates generated artifacts, derives processor settings from available CPUs,
and binds original/support fixture hashes. Its modes are separate: one mode's
success must not admit an unfinished campaign. A live environment-only processor
probe prints 12, matching this host; the wrapper now has a fail-closed probe for
future campaigns. These timings are not MCP package build/test timings.

The original PR1038 `serialization.scm` is also tested without changes. Its Git
blob is `9522db3af90e5c9a841a1ab80e6896862bce8cc0`, matching cached head
`7e1ae2a5b1b65b3d917e9be9565c9cf969ff4b3f`. It includes identity keys, empty
tables, resizing and self-references omitted by the earlier narrow fixture.
Interpretation passes in 0.190 seconds; compiled mode passes in 8.711 seconds.
The fixture is added only to the isolated suite, never the candidate runtime.
Portable receipt: `evidence/model-results/native-upstream-pr1038-serialization-018.json`.

None of these receipts establishes complete collector correctness, all upstream
tests, generated-source parity, full bootstrap, Linux admission or Gerbil gates.
Those obligations remain open before promotion to the release patch chain.

## Complete Interpreter Campaign Denied

The 375-file normal upstream interpreter campaign used the same 018 identity
and verified the host-selected 12 processors. It hit its declared 300-second
budget at 300.094 seconds; the last log counter is 348 passed and nine failed,
not a completed suite. Three assertion failures concern thread interruption,
shared-object output and table search. Six UDP tests report `Operation not
permitted` in the restricted sandbox and cannot be attributed to GC.

The thread-interruption fixture uses busy-loop work to wait for another thread
before asserting 11; it has no join establishing that completion order. This
is an assumption to audit, not permission to remove its assertion. Shared
output and table-search failures remain unclassified. The last started module
port test has no terminal result; a timeout alone does not identify its cause.
Do not repeat the unchanged full campaign or widen its budget to claim green.
Receipt: `evidence/model-results/native-upstream-all-interpreted-018-deny.json`.

## Source Bootstrap Not Admitted

The isolated GNU GCC two-pass `from-scratch` reached the second core C build,
but hit the declared 600-second whole-bootstrap budget at 600.093 seconds.
The log contains both bootclean commands and the intermediate new-compiler
copy. It shows no recursive make error or crash before termination. This is
unfinished bootstrap, not proof of a compiler deadlock or successful parity.
The original runtime remains source-stable. `include/stamp.h` changed as well
as generated `_module.c` and `_std.c`; stamp generation needs auditing before
any future source admission. No candidate identity was emitted or promoted.
Receipt: `evidence/model-results/bootstrap-018-deny.json`.
