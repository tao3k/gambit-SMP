# Combined Interrupt Result Native Result

The prepared combined fixture now passes on the exact final two-pass bootstrap
artifact of `abandoned-result-state`. The existing native suite adapter and
actual scope058 ASCENT preflight reviewed the selected one-file compiled route;
no legacy provider or hand-written eligibility decision was substituted.

The compiled whole-mode observation passed in 1.832 seconds under the unchanged
60-second budget. One shard executed one file with 11 child processors, selected
by the shared available-capacity planner. These are observed values, not fixed
processor constants. The child was reaped, its process group quiescent, and
source/artifact identities remained stable.

The six cases are the Cartesian product of normal/exceptional target ending
and these schedules:

- Target ends before processor extraction.
- Target ends after extraction but before propagation.
- Target delivers the request result before ending.

Each case uses the actual processor high-level interrupt enqueue/dequeue and
Scheme propagation/dispatch paths. Atomic compiled helpers extract two distinct
request identities, preserving their different receivers. Assertions check
detached successor links, exact receiver, exactly one B callback, zero A calls
on ended routes or exactly one on delivery, abandoned result exception and
post-exception owner state, target lock release and payload integrity across
forced collections at the transfer boundaries. No assertion or timeout was
removed or relaxed. Interpreter declarations cannot make the queue extraction
atomic, so only compiled execution was requested; this is not a gsi pass.

The raw log reports `PASSED ALL 1 UNIT TESTS`. That upstream count is files,
not the internal six-case count. Portable receipt, logs and exact identity are
under `evidence/source-results/fixtures/abandoned-result-state/interrupt-delivery-native`.
The fixture and source-bound scope review are durable semantic paths.

This is actual combined-path correctness evidence, not a physical GC-root
refinement proof, arbitrary queue-length stress, cancellation/retirement
acceptance or complete native suite coverage. The archive deliberately keeps
`nativeGcPassed`, runtime and release admission false. The frozen current
Reflection predates this new native observation and must be versioned after
the coordinated complete graph window; it is not silently changed underneath
that qualification. No new runtime patch was added.
