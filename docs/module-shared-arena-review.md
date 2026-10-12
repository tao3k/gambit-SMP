# Shared Arena Ownership Review

This extends the source-derived module initialization ownership audit, not a
separate performance campaign. The locked permanent allocator's fast path reads
and updates a global cursor. Two module descriptors may have different owners
while still targeting this same arena. Caller concurrency remains unproven.

`module_shared_arena_ownership.qnt` represents two distinct module roles sharing
that cursor, with explicit claim/read/allocate/publish steps and retained failure.
The per-module-only exclusion control produces an overlapping-address
counterexample (34 distinct states). A hypothetical failed-preparation cursor
rollback breaks retained allocation ownership (13 states). Neither is claimed
as a native-observed race or an implemented upstream rollback policy.

Abstract global exclusion, monotone allocation and retained failure pass safety
and weak-fair completion: 68 distinct / 76 generated states, 3.689 seconds.
Allocations are one unit, with no collection, reclamation or section growth;
the proof does not cover C weak memory or arbitrary population. The two roles
are protocol participants, not a hardcoded machine CPU count. No performance
benefit is estimated and no runtime locking patch is selected.

The initial attempt used an unsupported Quint `isEmpty` spelling and was denied
at parse time. Its exact model/log archive remains under `shared-arena-syntax-denial`;
it is not admitted. The corrected typed model and counterexamples are under
`evidence/model-results/fixtures/checked-cleanup-retained-error/shared-arena/`.

The model is registered in the global Datalog bundle inventory. Previous actual
consumer qualification remains historical at its exact 79-bundle input; adding
this model requires fresh consumption at the new registry hash, not promotion
of the prior result to CURRENT. Recheck source-bound facts and composition
closure without rerunning unchanged native failures or all Library builds.

Before implementation, compose the chosen ownership policy with VM-list
construction/retirement, intern/global publication and safe collective waiting.
Account for allocation failures and partially rewritten module tables. A
blocking mutex is not a substitute for that refinement. Full SMP, bootstrap
and Gerbil correctness/performance acceptance remain open.
