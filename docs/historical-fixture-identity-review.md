# Historical Fixture Identity Review

Four fixture tests compared immutable observation input hashes with today's
mutable paths. The failures were not all inventory changes: three involved
protocol manifests and one also involved a changed QNT model. Replacing old
hashes with current hashes would lose the tested identity and is not permitted.

## Exact Recovery

`evidence/source-results/fixture-history/inputs.json` binds four original
observation SHA values and five explicitly recovered historical inputs:

- The old failure inventory comes from Git
  `75ab0636641bdd1a7a5a5d4e2305516a7fea1321`; its original SHA matches exactly.
- Three manifests recover original bytes by removing the later empty `composes`
  field without reformatting. Each whole-file SHA matches the original observation
  and model receipt, not an inferred semantic equivalence.
- The old resize model uses the existing frozen
  `resize-commit-reachable-setup-failure/source/resize_commit_startup_round.qnt`,
  whose SHA matches the original observation. No model source is invented.

Original observations, receipts, errors and SHA values remain unchanged. The
test helper remaps only these fixed inputs; every other historical input still
requires its original hash. Archives are durable repository paths, not cache
dependencies. The helper refuses runtime admission and path escapes, checks the
original observation itself, and does not admit the current model or runtime.

Seventeen original fixture tests and six synthetic tamper controls pass (23
tests, 0.033 seconds). Negative controls cover original receipt changes, archive
changes, unlisted live-input drift, path escape and false runtime admission.
Synthetic controls do not enter the research evidence inventory.

## Separate Current Qualification

The current resize model genuinely differs from its historical frozen model.
It was freshly verified at the current manifest/model identity rather than
being admitted through the historical helper. Three negative controls find the
expected result, participation and startup counterexamples. Positive safety
and weak-fair progress pass 394 distinct / 684 generated states in 5.252 seconds.
The fresh receipt is
`evidence/model-results/fixtures/pthread-returned-error-identity/resize-commit-current-model/receipt.json`.
Only the corresponding registry receipt pointer changes; old bundles remain.

Global collection now returns 83 checked protocol models. Two remain without
current accepted model receipts: `pstate_log_publication_rollback` and
`gc_recursive_queue_wait`. This correction does not make either Green, rerun
native tests, establish physical GC correctness or complete bootstrap/Gerbil
acceptance. Historical truth and current admission remain separate checks.
