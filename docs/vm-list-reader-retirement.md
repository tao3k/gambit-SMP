# VM List Reader Retirement

## Source-Bound Review

`___raise_interrupt` traverses VM links without the writer's list mutex; the
disabled lock includes a recursive-deadlock warning. Global cleanup first calls
`___cleanup_all_interrupt_handling`, then destroys processor/VM-owned resources.
The POSIX heartbeat cleanup stops its timer and selects `SIG_IGN`. This alone is
not a source proof that callbacks already running on other threads have returned.
Actual platform and caller synchronization may establish stronger guarantees;
those paths must be audited before attributing an observed failure.

This is the reader-retirement gap already named by the constructor model, not a
repeat of a known failed native experiment. The benefit sought is a sufficient
ownership contract for reclamation. There is no measured or predicted speedup.
Atomic publication is a prerequisite, not a replacement for lifetime safety.

## Finite Verification

`vm_list_reader_retirement` assumes one initialized node, one independent
callback participant and one cleanup participant under sequential consistency.
Stopping admission and recording entry are atomic abstract transitions. This is
not evidence for a specific signal-safe implementation or arbitrary concurrency.

Campaign `.data/vm-list-retirement-model-001` retained stable input hashes.
Portable evidence: `evidence/model-results/vm-list-reader-retirement-model/`.
Four controls find stale-pointer reads after reclamation: stopping new callbacks
only, holding a writer-only mutex, using an atomic pointer only, and waiting for
late-registered pointer holders only. The last control retains the window between
loading a pointer and registering its ownership. Each search visits 26 distinct
states; that count is not a shortest-trace length.

The candidate closes admission, drains every admitted callback, then unlinks and
reclaims. It passes safety and weak-fair progress with 16 distinct states,
21 generated, 0 queued, 24.870 seconds. This is a sufficient conservative
contract, not a claim that draining all callbacks is the only possible solution.

## Open Refinements

Bind entry/close/drain to the actual signal backend and every interrupt producer,
including non-heartbeat APIs. Handle cleanup reentry from the callback itself:
waiting for one's own completion cannot be admitted by an independent-thread
model. Audit VM-owned resources as well as the externally owned VM struct and
the entire traversal, not only one retained node.

The manifest composes the publication memory-order model as an assumed premise;
it does not mechanically compose that model's transitions or close its remaining
source/atomic obligations. Those obligations are exposed transitively by
`contract_dependencies_with_open_obligations`. Native acceptance remains not run.
