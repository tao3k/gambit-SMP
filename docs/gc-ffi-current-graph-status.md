# GC/FFI, VM Lifecycle And Current Graph Status

## Exact Native Observation

`.data/current-source-gc-ffi-lifecycle-001` binds the fdset-owned-rollback
23-file source lock and exact completed GNU GCC producer, with all three
concurrency flags observed by the completed-producer verifier. It passed in
36.445293/60 seconds, exit 0, no timeout, parent reaped and process group
quiescent. The source/binary identity was checked before and after execution.

The existing official C-interface `retired_root_closure.scm` passed compilation
and execution (0.704582 native process seconds). It checks independently owned
RC/still roots retaining movable children through processor retirement,
relocation, RC release, a still-only collection, still release and collection.
No private cleanup or alternate loader was added.

The unchanged public multi-VM topology workload completed all 4,002 samples
at populations 2/3/4/5 on the observed 12-CPU host. It includes forced GC,
global interrupt overlap, joins, processor drain and official VM cleanup.
Execution took 11.989968 seconds within its original 25-second cap. Each
population retains at least 1,000 raw samples, with the original workload and
nearest-rank percentile calculation. Samples are correlated trajectories, not
independent trials or confidence intervals.

These are successful declared tests, not the entire GC/FFI/fault inventory or
all multi-VM destruction interleavings. `nativeGcPassed`, runtime admission and
performance admission remain false. The raw parent/child receipts, process
logs and full latency JSONL are in `evidence/source-results/gc-ffi-lifecycle/001`.
No executable or complete source tree is claimed to be archived there.

## Source And DSL Correspondence

`evidence/scenarios/gc-transfer/source-correspondence.json` binds candidate
`lib/mem.c` SHA `38b69316dc682ac6771904a976af00547f9c628a78752e6448d3f1171be53dcd`.
Actual source reading identified subtype scanning, RC/still scanning, frame
maps, closure free variables and the queue recheck/count boundary. The precise
completion range is 7186-7238 on these bytes; the preceding range-only version
and prior facts are retained as historical snapshots.

The real DSL derives five source-supported obligations, four source/test
correspondences, six finite shape classes and five scoped recorded runs. It
also retains ten unproven native/refinement boundaries. Source withdrawal and
restoration were tested through Python/C ABI with before/after SHA checks:
the latest check passed in 2.185778/15 seconds. Chez resweep/card machinery is
not asserted to be Gambit's representation or a proven source refinement.

## Full Regression And Failed Graph Attempts

All attempts retain their original 300-second validation cap:

- 024: rejected reordered append-only protocol registry history. Restoration
  preserved all 112 entries, the original 96-entry prefix and every new entry;
  the pre-repair order is saved, not deleted.
- 025-027: retained missing domain-engine selection, concurrent view drift and
  a seal/current-implementation mismatch. No source check was bypassed.
- 028: 1,366 tests, zero skips, two failures, complete inventory and no input
  drift. One historical context was stale; one protocol-only fixture was
  incorrectly classified as a build profile. The original positive historical
  assertion remains checked against exact frozen source bytes, while current
  source rejection is additionally required. Protocol-only fixtures use a
  general schema/type check, not a watchdog-specific exception.
- 029: 1,366 tests, zero failures/errors/skips, no input drift, full PASS;
  validation parent 231.302971/300 seconds. Subsequent history publication
  failed at SQLite commit. Its pending observation/request are preserved.
- 030: lock availability was independently observed with a rolled-back
  exclusive transaction; exact validation reuse/export took 12.848157/15.
  The graph was correctly STALE because a new Darwin test had been added.
- 031: includes that new test, 1,368 tests, zero failures/skips and one source
  binding error. The mutable build workspace's `configure.ac` changed during
  validation; `changedInputs` contains that exact path. Graph export rejects
  the old concurrent-GC view rather than promoting prior coverage to current.

The most recent model source/native candidate transition belongs to the
Working mainline. The observed workspace configure SHA is now
`e35ab387e2db19f3325df2d2dad9f0a3d7d0366c5fb2e14136c488bdc1961522`,
not the old view's `c7a8121eec407a7b03a3d9ca5f2df5fc367c1609d855dc7f47401f3d1981234d`.
Do not rewrite the old view SHA, remove its evidence or describe the fdset
observations as qualification of that successor. Full current graph remains
OPEN until stable, truthful view bindings and the current complete inventory
are independently qualified. Full regression PASS is not current-graph PASS.

## Matched Baseline Remains Blocked

The original queue-endpoint completed producer failed its read-only custody
check in 3.319480/15 seconds: evidence or artifacts drifted. Its live workspace
has been reused. The old standalone executable still matches SHA
`14706eb506411db1c39be43259fd3982ad5a7581d9d48bc37f152ca23955d935` and
links only system `libSystem`; its fixture SHA still matches the current input.
Those observations do not substitute for the kernel's completed-runtime gate.
No direct execution, ad hoc runner or weaker source contract was used.

Recovering a checked baseline needs actual original artifact custody, an
authorized source-bound rebuild, or a separately specified and qualified
generic captured-executable contract. No such recovery is claimed in this
turn. Historical 12.880484-second timing, current 11.989968-second timing and
the two earlier object samples are not a fresh matched performance experiment
and must not be reported as a speedup or performance closure.

All historical failures, original identities and budgets are retained. No
SubAgent, runtime C patch, source waiver, force push or native-gate promotion
was introduced by this qualification work.
