# VM Constructor Owned Rollback Fixture

## Candidate Source

`evidence/fixtures/vm-constructor-owned-rollback/source.lock.json` pins the
submodule plus a thirteen-file cumulative overlay. It extends the preceding
owned-log Fixture with:

- Checked POSIX mutex-backed spin and scan synchronization initialization,
  releasing only the successfully initialized prefix on failure.
- Private root preparation and heap allocation without list publication.
- Heap reservation based on the intended processor count, not published zero.
- An unpublished VM-memory abort path without P0 or list unlink access.
- Root catchup, list link and count enable in one `vm_list_mut` critical section.
- Caller rollback for activity-log, memory, P0 and publication failures,
  including ready P0 synchronization after a failed publication.
- Global-prefix cleanup when the VM constructor already unwound and count is
  zero, without revisiting the failed P0/VM memory constructor.

The canonical identity is semantic. Revisions and content hashes distinguish
inputs; no experimental source sequence number is an active identity.

## Evidence Boundary

The private memory QNT model splits both spin initialization failure points and
leaves successful constructors unpublished. All configuration/failure choices
and six controls are checked; the positive closure has 978 distinct states.
The root-publication model checks four controls and a 32-state positive closure
against this exact Fixture context. The subsequent composition now joins
configured P0/log rollback, private memory, finite global registration and
publication failure rollback. Retirement and asynchronous readers remain open.

The repaired policy completes safety and temporal progress with 564,510 distinct
states in 22.667 seconds. Three old policies each reproduce a safety violation;
their progress-only checks do not qualify repaired safety. Four disjoint policy
closures total 2,214,156 states, matching the aggregate run's state count.
Mechanical specialization tests preserve the full configuration/failure domains,
transitions and fairness. State-count agreement is supporting evidence, not a
general refinement theorem. Each check keeps its original 90-second limit;
the seven-check campaign takes 119.785 seconds, not 90 seconds overall.

The original aggregate temporal timeout, helper-action conversion failure and
nested-instance namespace failure remain archived. Flat policy specialization
avoids the observed Quint conversion limitations without changing protocols or
widening per-check budgets. Portable results and exact model closure are under
`evidence/model-results/fixtures/vm-constructor-owned-rollback/publication-rollback-contract/`.

The Datalog dependency node `pstate_log_publication_rollback` is registered
separately. Its standalone delayed-return control reproduces the ownership
violation, but the positive initializer hits QNT409: the shared
`initializeFor` action is classified as both initialization and step. The failed
attempt is retained under `processor-initializer-conversion-deny`; no standalone
positive receipt is admitted. The complete VM composition uses its own direct
initializer and has a completed proof, not that rejected helper route. Do not
retry the standalone helper unchanged or transfer the composition's receipt to it.

The object Recipes GNU-compile the actual full `mem.c` and `setup.c` with SMP,
multiple VMs and multiple threaded VMs enabled; memory compilation also covers
the POSIX mutex-backed spin initializer branch. The caller Recipe projects the
exact `___setup_vmstate` bytes from the locked tree and injects returning
allocation/P0/publication primitives. It passes ten branches in each threaded
and single-threaded mode. Removing the memory-failure log abort produces a real
exit-1 control, with two detected leaks across root/non-root contexts.

The portable observation summary preserves raw receipt/log hashes and outcomes;
it is explicitly not a complete raw producer archive or runtime admission.
The initial sandbox object attempt failed in m4 before C compilation; the
host-permitted run passed with unchanged source, tools and budgets.

## Reproduction

Select the host GNU GCC executable and native ASCENT API installation, then:

```sh
gambit-smp research --seal .data/fixtures/vm-constructor-owned-rollback/engine \
  --gcc "$GNU_GCC" --ascent-api "$ASCENT_API"
gambit-smp research --run vm-constructor-owned-rollback-objects \
  --engine .data/fixtures/vm-constructor-owned-rollback/engine --allow-native \
  --out .data/fixtures/vm-constructor-owned-rollback/fresh-objects
gambit-smp research --run vm-constructor-owned-rollback-caller \
  --engine .data/fixtures/vm-constructor-owned-rollback/engine --allow-native \
  --out .data/fixtures/vm-constructor-owned-rollback/fresh-caller
```

The Recipe owns preparation, byte ranges, binding, compilation, tests and
terminal native Datalog evaluation. No feature-specific Python producer was
added. Output directories are disposable, never authority for committed inputs.

## Remaining Gates

Memory callee/source publication failure injection has passed with primitive
allocation/synchronization injection: four multi-VM configurations cover 22
checks each, single-VM covers 18, totaling 106. The missing scan-mutex-release
control returns exit 1 with ten detected ownership violations. The byte-locked
projection includes the complete constructor, unpublished abort and publication
functions; actual allocators and OS implementations are not qualified by it.

Real root-publication concurrency, semantic C refinement, C memory order
and asynchronous readers, lifecycle/retirement, full GC regressions, source
bootstrap and Gerbil build/test remain pending. Global initialization failures
before `setup_state = 1` also remain a separate source ownership obligation.
Object/caller/model success must not discharge any of those gates implicitly.

## Next Source Obligation

The locked `lib/mem.c:___setup_mem_pstate` still invokes
`___SPINLOCK_INIT(heap_chunks_to_scan_lock)` without checking the POSIX
mutex-backed initializer result, after processor log setup succeeded.
`___cleanup_mem_pstate` releases still objects and reference-counted memory but
does not destroy that lock. Default ticket initialization cannot return the
same failure, so this is not evidence of a ticket-backend OS leak.

The existing `pstate_spinlock_initialization.qnt` describes ignored initialization,
blind rollback, missing owned destruction and a remote queue user. It is a
design contract, not implementation acceptance. A source repair must clean the
already-owned processor log on mutex initialization failure; successful lock
destruction also needs admission closure and remote-user quiescence, not merely
an unconditional destroy in general cleanup. Bind that protocol to a semantic
Fixture and validate actual returning initializer branches before any whole
runtime retry. The current composed model assumes the P0 memory/log callee
contract and does not discharge this scan-lock obligation.
