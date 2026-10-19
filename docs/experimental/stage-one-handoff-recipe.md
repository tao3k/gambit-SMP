# Stage-One Research Recipe: Waiting, Publication And Reader Composition

## Responsibility And Authority

This thread supplies research, source correspondence, model obligations and an
implementation handoff, not runtime changes or native acceptance. The selected
[package](stage-one-integration.md) and its
[coordinated milestone](stage-one-implementation-milestone.md) remain the design.
No second API, Python inference layer, runtime lock or TLS change is introduced
by this Recipe. The implementation owner selects and qualifies the actual source.

Source-bound supplements refine the same package: the
[reader-resumption contract](reader-resumption-contract.md) covers retained
membership, roots and explicit replay; the
[canonical-registration contract](canonical-registration-contract.md) covers
same-key contenders and pre/postcommit error outcomes. Their
[resumption](reader-resumption-validation.md) and
[registration](canonical-registration-validation.md) checks retain exact input
identities and limitations. The [VM-cell ownership contract](vm-cell-ownership-contract.md)
and [validation](vm-cell-ownership-validation.md) add the execution/GC cell-selector
join without changing global value access or disabling constructor failure.
The [root interpretation contract](root-map-lifetime-contract.md) and
[validation](root-map-lifetime-validation.md) add producer/map availability
through native, retained Scheme and admitted scanner consumers. No module
hot-unload or new root registry is selected. None supplies native admission.

Use the pinned Gambit, Chez and OCaml revisions and overlay identified in the
integration design. Source locations below distinguish unchanged vendor files
from the locked Gambit overlay. Never substitute an unversioned cache tree.
Preserve the C backend, proper tail calls, supported continuation/nested-FFI
behavior, VM-local values and allocation/resolved-global fast paths. Replace
defective synchronization under one repaired revision/effective configuration
and a complete rebuild; do not preserve defective-old-SMP or mixed binaries.

## Reference Mechanisms And Transfer Conditions

The earlier audits already identified pre-lock indexing and wait/root effects.
This follow-up connects those findings; it is not another discovery of the same
local race or a claim of a new Chez/OCaml bug.

| Evidence | What the pinned source establishes | Condition for the Gambit transfer |
| --- | --- | --- |
| Chez `c/intern.c:155-228` | Bucket indexing precedes `tc_mutex_acquire`; lookup/create/insertion share the owned interval. | Copy the whole-operation boundary, not the pre-lock derived index. Gambit mutator-side rehash can change bucket selection while a contender waits even without moving GC. |
| Chez `c/thread.c:401-418`, `c/types.h:363-410` | The raw recursive mutex wrapper does not deactivate the caller. Active-thread deactivation/reactivation is a distinct protocol. | An OS mutex wait alone does not publish Gambit roots or acknowledge a collective. Do not infer that it releases runtime execution ownership. |
| Chez `s/7.ss:1253-1297`, `c/intern.c:66-100`, `c/gc.c:1794` | The collector rendezvous distinguishes the last active participant; oblist resize is on the collector path. | Chez's index stability relies on its surrounding collection/participation history. These snippets are not a complete proof of every embedding's lifecycle or a Gambit resize policy. |
| OCaml `runtime/caml/platform.h:80-113,698-704` | Blocking waits inside a mutator require short, cycle-free ownership. Mixing raw blocking and runtime-releasing acquisitions of the same mutex on one domain can deadlock. The preferred helper first tries the mutex. | Classify every acquisition of each proposed Gambit resource consistently, including startup, GC, teardown and external callbacks. A single GC-aware waiter does not repair all mixed paths. |
| OCaml `runtime/unix.c:649-657`, `runtime/signals.c:147-215` | The contended path releases and reacquires execution through blocking hooks; the no-pending entry avoids dispatching pending exceptions there. Return marks pending signals for later examination. | A Gambit wait adapter must establish its own owner/root/return-state and effect contract; collective service is not an interchangeable OCaml domain-lock operation. |
| OCaml `otherlibs/systhreads/st_stubs.c:295-323,636-637` | Installed hooks save runtime state, release the thread lock and restore the selected thread's state after reacquisition. | The default hook implementation alone is not the complete reference configuration. Gambit needs its actual generated root/map/reload/RA correspondence, not a raw C-local backup. |
| OCaml `runtime/callback.c:387-431` | Named-value registration roots its arguments and discards the cached string pointer after waiting; root registration and named-table publication are associated operations. | Stable storage, rooted values, correct derived lookup state and publication are different predicates. A bounds check cannot certify a cached bucket or canonical miss. |
| Gambit vendor `lib/os_base.c:188-265,445-473`; overlay `lib/mem.c:1195-1306` | The reviewed permanent allocation reaches raw malloc/code allocation, not the custom msection allocator. Debug/log and low-level-code branches have additional effects. | The proposed leaf envelope needs an actual enabled-branch census. No Scheme callback/collective dependency may be introduced under P/M. Raw OS completion and scheduling remain assumptions, not finite wall-clock guarantees. |

## Composed Counterexamples And Model Boundary

The existing `predicate_lock_retry_rooting.qnt` gains a separate wait projection,
not a new lock implementation or duplicate collector. Its original root/service
projections remain separate. It combines a finite owner operation, a waiting
participant, one collection and a table-length change:

- A raw waiter cannot participate in the collection that its owner requires
  before releasing the resource. This is a wait-for cycle even without a reversed
  P/M/V acquisition edge. The fixed leaf branch releases independently of GC;
  the alternative parked branch assumes explicit participation and revalidates
  after resumption. It does not implement either branch in C.
- With hash 3, a bucket cached for length 2 is 1. After rehash to length 4,
  bucket 1 remains in bounds but the correct bucket is 3. Root/address stability
  and capacity safety therefore do not imply canonical lookup correctness.
  Rehash may be mutator-driven; no moving GC is needed for this counterexample.

The positive projection requires fair, terminating owner work and explicitly
valid GC participation for parking. Its two work units, two abstract roles and
one resize are finite witnesses, not CPU counts, latency bounds or a model of
the OS scheduler. It excludes C weak memory, arbitrary growth, actual root
relocation and full FFI unwinding. Earlier root, resource-order, constructor and
binding/publication models retain those separate obligations.

Lean's `checkedBucketAfterWait` proves the current index is correct and in bounds
if topology stayed identical with a valid cached index **or** the index was
recomputed from current state. `inBoundsBucketMayMiss` rejects the weaker claim.
These extend the existing proof module; they do not prove source establishes
either premise. Existing binding/root coverage, nested-exit and strict-order
theorems remain dependencies, not additional native credit.

## Implementation Handoff Contract

The native owner should receive the following linked evidence, not an isolated
mutex patch. These are proof/acceptance dependencies, not an agent workflow.

| Join | Existing source boundary | Required evidence and decision |
| --- | --- | --- |
| Entry -> wait | C/startup callers and SFUN/CFUN paths in the entry audit; P/M/V proposals in the package. | Classify owner, allocation class, live roots, held resources and actual wait effects per entry. Choose one coherent contract per resource; do not mix raw and execution-releasing waits without a reviewed cycle argument. |
| Wait -> canonical operation | Overlay `mem.c:2133-2404` exact lookup, intern/create and rehash. | Select the current table and derive bucket/miss after ownership or proven revalidation. Preserve one identity under same-name races and recheck after any unlocked preparation. |
| Metadata -> VM roots | Overlay `mem.c:1435-1644,5232-5251,5400-5429,7307-7346`. | Preserve the already-correct constructor catchup/link/enable transaction. Establish record initialization, count/slot readiness and acquire-visible binding-to-index-to-current-VM-root correspondence separately. |
| Capture -> callback -> exit | Kernel fold, TTY and Geiser boundaries in the closure audit. | TTY's reviewed leaf traversal is not a generic callback contract. A Scheme-owned typed membership capture must remain rooted across callback allocation, error and continuation exits, with no P/M ownership retained during delivery. Raw external visitors and escaped tables require an explicit supported-capability decision. |
| Partial init -> rollback -> retirement | Existing global/VM constructor and generation/lifecycle evidence. | Unwind only the actually owned initialized prefix, preserve the original error and drain users before reclamation. Prepublication retry is not restart after published teardown. Do not overwrite the native owner's newer retirement fixes. |
| Source -> artifacts -> admission | Existing source lock, effective Bazel profile, Recipe and checkpoint contracts. | Freeze the implementation owner's unified revision/configuration, regenerate C and rebuild runtime, libraries and extensions completely. Preserve supported public behavior, not internal binary compatibility with defective code. |

The first-stage cost envelope is intentionally narrow: centralized cold metadata
operations and reservation, differentiated readers and owned setup/cleanup.
Ordinary movable allocation, resolved-global value access and Scheme execution
are not globally serialized. Reduced duplicate preparation or contention is a
hypothesis, not a measured gain. Measure lock hold time, GC delay and sequential
and multicore workloads; the research cannot supply a throughput prediction.

## Closure And Remaining Gaps

- Source provenance and selected package boundaries can be reviewed here;
  actual C memory-order/reader coverage must be established for the owner's
  frozen candidate, including required debug, low-level and platform branches.
- The finite wait/index interaction supplements existing local models. It does
  not compose actual OS waits, all resource owners, generated roots, all VM
  lifetimes and arbitrary continuation re-entry into a complete collector proof.
- Supported callback effects, generic visitor OOM behavior and arbitrary raw
  views cannot be assumed from a signature or silently prohibited. Required
  existing behavior must be reconciled before Stage-One admission; genuinely
  new capabilities belong to separate Experimental milestones.
- Original bootstrap/stress/GSI/GSC/Gerbil/FFI correctness, typed fault coverage
  and preserved performance gates remain with the native owner. No successful
  model run clears a native failure. Watchdogs observe genuine target progress;
  neither total elapsed time alone nor model/heartbeat output proves a stall
  or extends native progress.

The same three native obligations remain unfulfilled in the registered DSL;
`satisfies` stays empty. Research does not reset or advance cumulative native
progress. The dependency graph exposes conditions and alternatives, not a
deterministic next action or a restriction on an agent's hypotheses.

## Unadopted Implementation Excursion

Before this research-only boundary was clarified, an isolated cache candidate
attempted P/M lifetime/reservation, whole-operation interning, global publication
and reader capture. It also produced an uncommitted cumulative patch and source
lock under `shared-metadata-transaction`. No configure, bootstrap, stress or
native acceptance was run for it. It is **not adopted, not qualified and not a
source input to this Recipe**. Its existence is not an algorithmic counterexample
or authorization to implement the research here. No runtime source is changed
by the present follow-up; failures and native-owner work are retained.
