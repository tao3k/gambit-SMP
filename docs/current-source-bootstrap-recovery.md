# Current Source Bootstrap Recovery

## Native Observation

The current continuation-segment-wake-budget source lock completed configure,
seed, causal review, full bootstrap and verdict. Configure took 27.529 seconds,
seed 32.523 seconds and `from-scratch` 135.935 seconds. Each of phases 1 through
4 ran twice. The complete outer observation took 218.226 seconds within its
independently authorized 600-second budget. GNU GCC and all three concurrency
flags remained enabled; make concurrency was selected from host capacity.

The original outer DENY and child STALE remain unchanged. The final validator
incorrectly compared every intermediate in-place inventory to live final bytes.
Revalidation found no input drift, sealed intermediate states RETAINED, and the
final bootstrap inventory AVAILABLE. Recovery requires the complete original
recipe inventory, all stages PASS, exact sealed journal and current final bytes,
quiescence and the original budget. It never upgrades a failed or missing stage.

## Current Setup Audit

The interpreted regression intent's setup.c successor is
`e25fee5f565f65bf299f1b965bec2be9e8c7d4f87d9c0f60c9802e2505a6ad39`.
The older intent expected `396e82c0050505a24168569cd2c1f978029e73b9c00e7528d86e1f9e7a715a1d`;
that original intent is preserved rather than edited.

Current setup retains acquire/release scheduler status publication, startup
epochs and pending-join ownership. Public VM cleanup now requires one processor
and no pending joins, rejects active foreign frames through the legacy fatal
error contract, closes/drains registry readers under the mutation mutex and
delegates resource destruction to the locked cleanup helper. These changes
justify rechecking full interpreted regressions on this exact candidate; they
do not prove host ownership, native fault recovery or a speed improvement.
The `_system.scm` and `_thread.scm` bytes referenced by the other interpreted
causal changes still match their original exact hashes.

The prior timeout remains a partial 300-second observation, not proof of a GC
deadlock. Complete assertions, file inventory, original per-file budgets and
the 300-second whole-suite cap remain unchanged. No private cleanup or injected
loader hook is admitted. The source and runtime are reused in the same directory.

## Progress

Historical qualified progress remains 3/12. The current bootstrap is now
independently revalidated; current GSI/GSC, PR, stress, lifecycle, registry,
GC/FFI, Gerbil correctness and release performance still require native results.
Framework tests and finite-model checks never count as those native milestones.
