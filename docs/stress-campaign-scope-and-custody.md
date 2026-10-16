# Stress Campaign Scope And Custody

## Decision Before Execution

The current dynamic-profile producer has a complete two-pass bootstrap and
380/380 interpreted and compiled correctness results. Its four unchanged
upstream compiled stress files still require qualification. The earlier
interpreted timeout is retained; compiled stress is a distinct execution path,
not a reduced workload or an unchanged interpreted retry. No speedup is expected
or claimed from the scope/custody changes below.

The stress recipe uses host-adaptive shared CPU capacity, all three concurrency
flags and the original 300-second completed-work inactivity window. It does not
reduce repetitions, add heartbeat progress, remove assertions, serialize SMP
or convert CPU activity into completed work.

## Scope Is A Relation, Not A Run Number

The first new compiled campaign stopped before native execution because three
historical ordinary-suite budget failures were attributed to every use of
`tests/run-unit-tests.scm`. Their exact archived receipts contain closed
375/379-file selected inventories and no stress files. The failure IDs have no
semantic role; classification uses their bound content and file membership.

`failure_campaign_scope.qnt` explores all 32 combinations of bound provenance,
closed inventory, budget category, generic-runner scope and overlapping files:
64 distinct states, zero queued states, safety and weak-fair completion pass.
Three decoded negative controls reject excluding unknown scope, semantic
failures or overlapping campaigns. The checked framework run is
`.data/failure-campaign-scope-public-loopback`; earlier loopback prerequisite
and recipe-validation rejections remain separate observations.

Python only projects closed, source-hash-bearing historical file inventories.
The Scheme DSL derives disjoint campaign scope. Every originally matched
failure must occur exactly once in the applicable/disjoint partition.
Unknown inventory, assertions, crashes, non-runner scopes and any file overlap
remain applicable. Disjoint does not mean fixed or PASS.

The actual sealed-engine regression command completed **74/74, zero skips**
in 135.624 seconds, including the 40 cases that require a real sealed engine.
The preceding unsealed transport run skipped those 40 and is not an equivalent
verification result.

## Historical Inputs Do Not Replace Products

Changing review policy correctly made the original bootstrap's live input
comparison stale. The old sealed engine retains the exact original policy:
SHA-256 `7c8de105cdeb10ae3598442d8353e62503625a30588a2d05ee0570cd1580eb90`.
It was copied unchanged to the versioned archive under
`evidence/source-results/compiled-campaign-scope-history` and bound to the
original outer receipt, without rewriting either receipt or workspace state.

The same validated historical-input mapping now reaches retained workspace
state checks and output inspection. It does not authorize missing or changed
runtime bytes. Archive drift, absent binding, mismatched state inventory and
changed products still fail. The real bootstrap revalidated as
`HISTORICAL_BOUND`, with source/configuration/seed epochs retained and final
runtime available. Its new explicit reference is
`evidence/research/current-source-full-bootstrap/scope-reviewed-completed-producer.json`.
Historical-input/artifact/inspection/custody regression coverage passed 40/40.

## Explicit Plan Before Partial Receipt

The next entry rejection exposed a separate architectural issue: global
reference discovery selected the first filename, reaching a stale legacy
reference before the recipe's declared successor. Reuse now prefers the exact
completed-runtime dependency declared for the matching materialization step.
Malformed or ambiguous explicit references reject; they never fall back to an
unrelated successful producer. Without an explicit dependency, the legacy
fail-closed discovery/duplicate-build protection remains unchanged.

The executor supplies its already-validated complete step plan. A partial
execution receipt cannot reveal a future consumer and must not be used as the
plan. Tests cover a lexically earlier stale reference, invalid/ambiguous
explicit references, and selection before the future producer step executes.
The focused producer/history/recipe/custody run passed 82/82.

`completed_source_selection.qnt` models explicit custody, invalid references,
ambiguity, source/product binding and an unrelated global first candidate.
Its positive safety/progress and three negative controls are required before
stress execution by the same recipe. Parse success alone is not verification.

## Acceptance Boundary

The pre-native failed attempts are retained at:

- `.data/fixtures/dynamic-modulo-complete-compiled-stress-run` (scope review).
- `.data/fixtures/checked-campaign-compiled-stress-run` (historical state binding).
- `.data/fixtures/scoped-custody-compiled-stress-run` (implicit reference discovery).
- `.data/fixtures/explicit-producer-compiled-stress-run` (partial receipt is not a plan).

None executed stress workloads. The corrected attempt is
`.data/fixtures/declared-plan-compiled-stress-run`. Its terminal receipt, not
this design description, determines stress acceptance. Cumulative milestone
completion remains 5/12 until that complete native gate actually passes.

## Terminal Native Result

The corrected chain completed its source/producer validation, positive QNT
check (128 distinct states, zero queued), all three negative controls and
actual ASCENT scope review. It then ran all four original stress files.
The whole attempt is **DENY**, 344.402766625 seconds; native stage
306.044755291 seconds. Two files completed successfully; `tfib_stress.scm`
reported signal 11 and `thread_interrupt_stress.scm` reached the unchanged
300-second inactivity watchdog. The latter is censored, not a proven deadlock.

Portable summary and original small stdout logs:
`evidence/source-results/compiled-stress-failure/campaign.json`.
The macOS interpreter incident binds the exact candidate GSI hash and image
UUID. The upstream runner does not record its grandchild PID, so the normalized
report explicitly does not claim PID attribution. Personal paths and unrelated
incident metadata are not included.

The faulting frame is `___H___thread+33864`; the instruction is
`ldur x2, [x2, #0x27]`. With the configured tagged-body layout, nearby accesses
to color/left/right fields resemble generated BTQ red-black removal fixup.
This is a source-audit lead, not an exact generated-label attribution or a
proved collector/queue defect. Existing moving-lock-root models assume complete
successful transitive tracing and ownership preservation; they cannot discharge
this newly observed failure. Tree-edge integrity, writer ownership and exact
fault-site binding must be checked before proposing a runtime repair.

Do not retry this unchanged candidate to seek a pass. No stress or performance
gate closed, and the cumulative count remains **5/12**.

## Exact Fault-Site Refinement

The existing `gambit.object` capability rebuilt only `lib/_thread.c` with `-g`
added to the configured GNU command, using the same leased workspace and a
separate object output. It did not relink or replace any qualified product.
Object compilation took 5.585 seconds; the complete checked attempt took
22.781 seconds. Generated C SHA-256 matches the actual stress producer.

Original and diagnostic objects have identical rendered `__TEXT,__text`
bytes and all 5,840 text relocations. Whole relocation inventories differ
because the diagnostic adds DWARF sections; that difference is not ignored
or described as whole-object identity. The host symbol is at object offset
`0x6e64`; adding the observed 33,864-byte offset gives `0xf2ac`. The original
object and linked interpreter have matching instruction windows at that
relative location. DWARF maps it to generated C **line 11553**, label
`___L9__23__23_btq_2d_remove_21_`: the color read of the sibling's right child
in red-black removal fixup. The unchanged generator range is pinned under
`vendor/gambit/lib/_thread#.scm:428-471`; no cache source is its authority.
Machine-readable correspondence is retained in `symbolization.json` beside
the portable failure summary. No native root cause is inferred from this
location alone. The other two processors were in device-select paths at the
incident snapshot; that does not exclude earlier concurrent or collector writes.

## Coupled Access Obligations

`btq_gc_transitive_edges.qnt` allows collection while the queue write lock is
held and permits independent work on a second queue. The positive conditional
contract passes safety and weak-fair completion over 16 distinct states, zero
queued. Root-only tracing, a same-queue writer with the wrong ownership and
duplicate canonical destination identity produce decoded counterexamples at
14/16/14 distinct states. These are controls, not three proven causes of this
incident or an implementation of the red-black algorithm.

The actual Scheme DSL view
`evidence/scenarios/concurrent-gc/btq-edge-integrity.view.json` is registered
in the existing view registry. It binds the pinned generator, candidate lock,
model source, conditional model observation, fault mapping and native DENY.
It retains three open obligations: exact queue writer exclusion, transitive
child closure and unique copying/scan destination identity. Model PASS and
native DENY coexist without upgrading source/native admission. Four new
tests cover hash-bound sources and actual-ABI inference for opaque numeric-looking
IDs, model withdrawal and refusal to discharge gaps from PASS labels. Combined
view regression coverage passed 14/14.

Existing `gc-old-space-input-contract.md` already records native repeated-body
scanning, with unknown producer origin. `eager-tail-scan-partition.md` proves
only a conditional field partition and explicitly leaves that origin open.
Do not repeat either diagnostic unchanged or add a to-space skip. The next
causal observation must bind first/second scanner origin, VM/cycle, allocation
generation, chunk/field interval and retained producer activity before any
collector repair. The new fault-site mapping narrows the affected consumer;
it does not supply the missing producer trace.
