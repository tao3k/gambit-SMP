# Processor Publication Standalone Review

The global protocol inventory registered a configured processor-publication
dependency but pointed to a missing standalone receipt. Its first fresh check
passed the negative control, then Quint rejected the positive initializer with
QNT409: `initializeFor` was reused for initialization and step contexts.
This is a compiler translation denial, not a reachable ownership failure.
The original log/model archive is preserved at
`evidence/model-results/fixtures/vm-constructor-owned-rollback/processor-publication-init-alias-denial/`.

The canonical model adds only `initStandaloneFixed`, with the exact body of
`initializeFor(true, false, true)`. Original constructor entries, state fields,
transitions, predicates and fairness stay byte-for-byte unchanged. Two regression
controls compare the entire old snapshot after removing the added initializer,
then check exact parameter substitution of domains and assignments. This is a
backend adaptation, not a state-space reduction or a runtime source repair.

The standalone manifest selects this dedicated initializer. All 100 original
threaded configurations are explored: memory failures, borrowed ownership,
logging enabled/disabled and activity-log failures. Positive safety and progress
pass over 1,050 distinct / 1,515 generated states in 4.551 seconds; the delayed
cleanup control produces its expected counterexample. The new receipt is at
`evidence/model-results/fixtures/vm-constructor-owned-rollback/processor-publication-contract/`.

Because the canonical dependency changed, the full VM constructor models were
requalified rather than transferring their old verdict. Four positive checks
and three negative controls pass with unchanged 90-second per-check caps:
positive times 19.732, 19.866, 30.527 and 18.506 seconds. The full composition still
explores threaded and nonthreaded configurations and its existing memory/backend
domains. Fresh receipt:
`evidence/model-results/fixtures/vm-constructor-owned-rollback/publication-rollback-dedicated-init-dependency/receipt.json`.
Only the current registry pointer changes; old receipts remain historical.

The global collector now binds 80 bundles, 935 inputs, 85 models and 84 current
checked models; no composition target is unknown. The remaining unqualified
model is `gc_recursive_queue_wait`. Its existing full-exploration DENY is a
90-second source-policy timeout; partial symbolic safety/ranking receipts do not
prove whole temporal completion. No unchanged timeout rerun was performed.

Fifty-one focused tests pass, including historical identity, tamper, protocol
evidence and initializer-shape controls. These tests and finite model checks do
not qualify physical allocator/OS behavior, full GC, complete native suites,
bootstrap or Gerbil correctness/performance. No runtime or release admission.
