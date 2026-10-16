# Evidence, Cache And Qualification

## Independent State Axes

The Python readback now separates these existing facts instead of using one
`STALE` label to infer lost progress:

| Axis | Meaning | Authority |
| --- | --- | --- |
| Recorded outcome | What the original execution reported | Retained receipt; not an unconditional proof of validity |
| Evidence binding | Whether source, patch, tools and evidence-log hashes match | Recipe inputs, observed inputs and historical bindings |
| Artifact availability | Whether declared output bytes exist and match | Disposable output descriptors and tree/file identities |
| Current producer eligibility | Whether the producer still satisfies every reuse requirement | Existing strict completed-producer validation |
| Milestone completion | Which full requirements have valid durable evidence | Existing Evidence Scheme DSL/ASCENT requirements; not cache existence |

`recipes.inspect_run` returns `recordedOutcome`, `evidenceBindingStatus` and
`artifactAvailability`. `research_kernel.inspect` propagates those facets
through the sealed receipt and exact child-receipt hash. Available, missing,
modified and unknown outputs are distinguished. Missing cache does not become
a failed original execution. Missing output and source/patch drift can coexist;
neither condition hides the other.

The legacy `identityStatus` remains fail-closed for existing producer consumers:
it requires valid evidence binding AND all required output identities. Runtime,
source-refinement and execution admission are not granted by a recorded PASS
or by the new diagnostic facets. No budget, review or native gate is relaxed.

## Strong Evidence And Patch Binding

The source/patch authority is an exact revision and source lock, including
the overlay SHA-256 and per-file hashes. Recipes declare repository inputs;
materialization binds source locks and actual patch bytes as observed inputs.
Inspection rechecks those declared and observed hashes separately from output
availability. Historical bindings must supply matching archived bytes; they
are not inferred from a filename or a missing cache. Native milestone rules
remain in `evidence/research/smp-threaded-vm-native-grid/milestone-rules.ss`.
Python must not invent a package-specific completion counter or grant a native
gate because a Quint model passed.

Repository-persisted gate evidence must retain the gate scope, fixed source
identity, patch identity, execution receipt/log hashes and original budget.
Deleting `.data/fixtures` or running `make clean` must not delete that authority.
Changing patches creates a candidate requiring requalification; it does not
silently invalidate a completed older-source milestone or qualify the new one.
A demonstrated regression or invalid original evidence can withdraw completion
with explicit source-bound causal evidence. Cache absence alone cannot.

## Verified Boundaries And Remaining Work

Tests check exact source and patch drift, log tampering, output modification,
cache deletion, unchanged readback and sealed readback composition. Deleted
cache retains recorded PASS and valid binding where the durable inputs/logs
remain available, but keeps producer reuse denied. Modified source/patch/logs
still invalidate binding even if caches are missing or intact.

Actual retained-bootstrap readback now distinguishes missing source/configure/
seed output trees from its available final runtime. Its evidence binding also
reports STALE: input/tool/log drift must be resolved independently, not blamed
solely on cleanup. No accepted new producer follows from this diagnostic.

This change does not yet publish a durable native gate archive or make an old
fixture-addressed completed-producer reference cache-independent. Those require
an explicit source-bound archive/export contract and restoration policy. Do
not claim that adding diagnostic fields completed that migration. Existing
portable Quint bundles already retain model source and log hashes; native
bootstrap/gate evidence needs equivalent durable ownership before pruning.

The first combined framework run executed 76 tests and reported 15 errors:
the EngineSeal tests could not import `transfer_resource` from the installed
`ascent_engine.build`. This is a dependency/API mismatch, not a cache-eviction
pass or a reason to drop those tests. The failure is retained here. No skipped or mocked import
was used to turn that combined run green. The focused inspection/recipe run
passed 29/29 in 0.154 seconds, including the new sealed-readback cases.
The broader inspection/recipe/completed-producer/historical-input and non-seal
research regression selection passed 94/94 in 0.592 seconds. It deliberately
does not substitute for the 15 failing EngineSeal cases or native SMP gates.

The dependency mismatch was subsequently resolved by moving immutable-generation
transfer into this framework's artifact-custody module, without changing the
installed ASCENT library or weakening seal checks. The same selection including
all EngineSeal cases passed 110/110 in 3.387 seconds. Source identity, ownership,
mutation rejection and cross-device fallback assertions remain in place. This
framework regression result is not native SMP acceptance or completion of the
durable native archive contract above.

The final regression selection additionally included artifact-storage rejection
tests: 119/119 passed in 3.127 seconds. Generation source symlinks, destination
overwrite and permission-error fallback are rejected. This count covers only
the selected framework modules, not all native tests.

Cumulative milestone completion remains 3/12; newest source requalification is
pending. The count is not reset by the diagnostic artifact-availability axis.
