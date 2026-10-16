# Current SMP Qualification Audit

## Explicit Progress Count

Cumulative milestone completion is **5/12 (41.7%)**: complete bootstrap,
complete GSI inventory, PR/GSI, complete GSC inventory and declared PR/GSC
coverage. Repository source identities, patches and
retained exact-source evidence govern that count; disposable fixture existence
does not. The new source successor needs requalification, but that does not
reset completed work to zero. Seven full gates remain open. The dynamic-profile
successor has complete two-pass bootstrap, 380/380 GSI and 380/380 GSC evidence.
Actual fixture hashes, not renamed observed-step labels, close its declared
PR/GSC scope through ASCENT. Remaining gates do not permit claiming SMP green.
Model checks and exact patch reapplication alone do not add a native gate.
The twelve-row current table is at the top of `smp-threaded-vm-milestone.md`.

## Latest Source Successor

The active `darwin-dynamic-modulo-scope` candidate retains all 23 SMP source
files of the fdset successor and changes only Darwin/GNU dynamic-module flags.
Bootstrap took 204.522 outer seconds; interpreted validation took 57.074 outer
seconds. Full compiled validation passed 380/380 files, 12/12 groups and zero
timeouts in 510.373 native / 587.987 outer seconds. The numerical file retained
its original generated C, original loader/assertion protocol and 90-second
inactivity window per real completed phase. The earlier 379/380 DENY remains.
Current sealed custody and checked ASCENT file coverage are recorded in
`evidence/source-results/compiled-suite-coverage/receipt.json`.
This closes two correctness gates, not release performance or the seven
remaining gates. See `darwin-dynamic-modulo-candidate.md`.

### Preceding Fdset Source

The latest candidate is `fdset-abort-owned-rollback`, a 23-file source lock
retaining the SFUN explicit-context and pipe-descriptor ownership repairs.
Only os_io.c changes from the immediately preceding pipe-descriptor candidate.
Its new ownership model exhausts 119 states with three controls. The human
subsequently approved a separate frozen-candidate 600-second build scope.
Complete two-pass bootstrap now passed, with all four phases executed twice;
complete interpreted/PR validation passed 380/380 on that exact producer.
See `fdset-frozen-source-qualification.md` for the results and retained failures.
The earlier ledger is unchanged. Cumulative completion remains 3/12; these
results requalify existing gates rather than add new gates.

## Earlier Queue-Endpoint Source Requalification

The last bootstrapped successor is `gc-queue-endpoint-access`, with only mem.c changed
from the 22-file wake-budget parent. Its complete two-pass bootstrap passed;
all four phases ran twice and `from-scratch` took 131.042 seconds. The whole
outer qualification took 246.038 seconds within the retained original ledger.
The full GSI/PR inventory passed 380/380 in 65.385 outer seconds. These three
existing gates are requalified on the current successor, not reset or newly
counted. Its original public latency grid also completed all 4,002 samples in
12.880 native execution seconds and 74.369 outer seconds. This first success
does not close full lifetime, fault or GC/FFI acceptance. See
`gc-queue-endpoint-source-successor.md` for precise scope and immutable hashes.

### Earlier Wake-Budget Producer

`evidence/research/current-source-full-bootstrap/completed-producer.json` binds
the actual completed bootstrap, original immutable DENY/STALE receipts and
the sealed stage journal. All original stages passed; all four bootstrap
phases ran twice. Exact retained predecessors and live final bytes revalidate,
with no budget extension or failed-stage upgrade. Bootstrap execution took
135.935 seconds; the original 600-second run spent 218.226 seconds.

The public-cleanup interpreted grid passed 380/380 standard/PR files in a
71.610-second whole run. The official VM-table fixture passed compilation in
3.370 seconds and execution in 0.517 seconds, without private cleanup or fault
interposition. Five VM cohorts and twelve GC rounds were derived from observed
host capacity. This diagnostic does not close the full registry/lifecycle/FFI
grid. The unchanged interpreted stress workloads hit the 300-second hard gate;
the timeout remains failed evidence, not correctness or performance acceptance.

Full GSC dispatch was denied before execution: two historical compiler-cost
reviews required a lower optimization level, but the actual comparison was
O1 to O1. Those checks are not weakened or falsely credited with an improvement.
Compiled stress is a separate native gate, not a replay of interpreted stress.

The prepared deep saved-stack fixture has now run against this current
producer in compiled scope: 131,072 non-tail recursive levels per host-derived
pinned worker, two forced collections, exact retained-frame checks, joins and
shrink passed. Compilation took 2.993 seconds and native execution 0.733 seconds;
the complete outer run took 40.700 seconds with its child receipt preserved.
See `current-source-saved-stack-native.md` for source geometry, exact identities
and still-missing physical-rollover/full-GC requirements. This does
not close a fourth gate.

The same deep saved-stack fixture also passed in GSI mode through the canonical
known-failure inventory and actual ASCENT preflight. Its one-file suite process
took 0.311 seconds, and the complete outer run took 38.811 seconds. Exact sealed
readback returned CURRENT. The companion sealed inference/resource-plan domain
passed 43/43 tests without skips in 15.408 seconds with host-derived workers.
These checks validate their declared scopes, not a complete GC/FFI native gate.

Cache removal, `make clean`, restart or STALE artifact readback alone cannot
revoke a completed gate. A demonstrated regression, invalid original proof or
explicit scope change can revoke it, with the causal evidence retained.
Reproduction/admission status and cumulative completion must be reported
separately. The earlier zero-counter presentation was a reporting error;
there is no newly observed native failure justifying that reset.

## Authoritative Readback After Cache Pruning

The shared framework was actually invoked with:

```sh
uv run --locked gambit-smp research --read \
  .data/fixtures/vector-increment-arity-parity/loopback-admitted-bootstrap-run
```

It returned stored `outcome: PASS`, but current `identityStatus: STALE`,
`runtimeAdmitted: false` and `sourceRefinementAdmitted: false`.
Historical bootstrap/GSI/PR-GSI coverage remains 3/12. It is not a currently
admissible completed producer and must not authorize a new native campaign.
The selected bootstrap runtime is retained, but earlier source/configuration
trees were pruned. `recipes.inspect_run` checks every step's output tree, not
only the final runtime; preserving receipts does not preserve those trees.
Current input drift is a separate possible reason for STALE. No unique cause
or successful revalidation is claimed from the readback alone.

This is a mismatch between bounded disposable storage and the current producer
readback contract, not a Gambit runtime failure. Do not restore hundreds of
source copies, forge their identities, weaken validation or reset expenditures.
Qualified reuse needs a framework-supported, source-bound retained producer
contract that distinguishes pruned predecessors from actual input drift.

## Official Interface Boundary

Ten native fixture sources reference `___cleanup_owned_vmstate`:

- `independent_threaded_vms.scm`
- `registry_topology_observation.scm`
- `registry_topology_grid.scm`
- `registry_topology_latency.scm`
- `registry_resize_grace.scm`
- `pending_join_recovery.scm`
- `pending_join_errno_recovery.scm`
- `vm_owned_pending_join_recovery.scm`
- `vm_scoped_pending_join_recovery.scm`
- `vm_constructor_sync_faults.scm`

These files are under `models/gambit/native`. The symbol is exported by the
research candidate but is not in the pinned upstream public header or GSTATE
function table. Exporting a research symbol is not sufficient to satisfy the
human's official-public-loader/FFI-only qualification restriction. The old
observations remain evidence of their original scope, not current official-API
acceptance. No interposition or private cleanup invocation is launched here.

Replacing the helper with public `___cleanup_pstate` followed by
`___cleanup_vmstate` without proving reader quiescence is not acceptable:
`vm-owned-retirement-contract.md` already records that ordering hazard.
A safe public lifecycle design and its source-bound model are prerequisites;
renaming the helper or adding another public-looking export is not a repair.

## Source Audit And Next Eligible Execution

The continuation origin/export/handoff composition now exhausted 2,160 states
for safety, no-stall and weak-fair progress, with both old-protocol negative
controls retained. The 20.016-second framework result is portable evidence,
not a fourth native gate. See `continuation-origin-handoff-composition.md`.
The next collector decision is the actual saved-stack/rollover publication
source witness and a bounded nonserializing implementation, not another replay
of the three already-known standalone models.

That decision now has a concrete private-chunk source successor. It batches
publication until copied frame links are complete, using existing chunk links
and two local endpoints rather than a scanner lock. The finite conservation,
readiness and progress checks passed; all 22 source files were exported and
reapplied. GNU GCC syntax diagnostics passed with a retained configuration,
not a qualified current-header build. See `continuation-private-chunk-segment.md`.
This changes the source candidate, not the 3/12 native completion count.

Review of that candidate found a parallel-notification gap: a multi-chunk batch
retained only one idle-worker signal. Its source successor now uses a local
saturating wake count bounded by the current VM cohort. A real negative control
and exhaustive positive safety/progress checks passed before the source edit;
all 22 source files were exported/reapplied again. See
`continuation-segment-wake-budget.md`. No native gate or speedup is claimed.

The current official ASCENT C-ABI artifact was packaged from its canonical
std/make output without rebuilding it. Source correspondence tests completed
10/11 in 107.263 seconds; the remaining error is a historical source-unit
receipt omitting locked inputs. This is not complete ASCENT/native acceptance.
No historical source hash or missing runtime output was replaced to make it pass.

The public-entry cohort obligation now has a checked composition model and
an immutable source successor. See `public-vm-retirement-composition.md`.
Both active-cohort and pending-join negative controls are retained; the guarded
protocol exhausted 57 states. The source rejects unsafe public teardown before
any resource release. It still needs actual compilation/bootstrap and does not
advance the native milestone count or qualify a retained old binary.

The current cleanup candidate has closed foreign admission and registry-reader
draining, but its public void cleanup requires the caller to drain processors
and direct users. The checked global cleanup retains resources after join
failure; the private owned cleanup has a separate recovery path. These are
already recorded protocol obligations, not justification for another speculative
guard patch or a replay of known negative controls.

The current source-stage consumption remains 417.0321317510097/600 seconds,
leaving 182.9678682489903. The old 226-second recipe is ineligible. There is no
qualified current-bootstrap receipt for the public-cleanup source successor.

Before another whole native execution, the same qualification chain must have:

1. A currently revalidated, source-bound producer under the bounded storage
   contract, or a genuinely eligible bootstrap with original cumulative charges.
2. An official public lifecycle contract composing VM/pstate ownership,
   foreign frames, registry readers and failed joins; no private fixture bypass.
3. Complete GSI/GSC, PR/GSI/GSC and stress inventories on that exact producer.
4. Registry lifetime, lifecycle faults and GC/FFI native qualification within
   the authorized public mechanism and original budgets.
5. Gerbil correctness and performance acceptance on the same source identity.

No new runtime gate was completed by this audit. No communication with another
task, new source tree, unchanged timeout replay or budget relaxation occurred.
