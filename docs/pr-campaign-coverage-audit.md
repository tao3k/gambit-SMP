# PR Campaign Coverage Audit

## Confirmed Admission Boundary

The current producer has complete bootstrap and 379-file interpreted inventory
PASS. That is not a complete PR, stress, GC/FFI or release acceptance claim.
The declared seven-file positive PR projection is not admissible under the
existing historical whole-suite reviews. This is a scope defect in the
recipe design, not a newly observed native runtime failure.

Four diagnostic launches remain retained under the vector-increment arity
fixture store: `pr-interpreted-campaign-run`,
`pr-interpreted-bound-source-run`, `pr-interpreted-exact-review-run` and
`pr-interpreted-complete-review-run`. None reached the native suite.

- The first tried to redeclare an already locked upstream completion fixture.
  The immutable-fixture replacement check rejected it.
- The second carried full-suite failure reviews into a smaller selected set.
  The exact review projection check rejected unselected failures.
- The third correctly projected five historical reviews, but the three
  whole-suite failures lacked original inventory coverage.
- The fourth restored the complete QNT/environment/handoff chain but was still
  denied for the same inventory coverage condition. Missing QNT steps were
  not the root cause; that earlier inference is explicitly withdrawn.

## Source And Model Correspondence

`native_review.project_review` records every original selected file.
`suite-review-rules.ss` derives `original_file_missing`, then
`original_inventory_gap`; `whole_covers_original` requires no such gap.
Unscoped whole-suite reviews cannot be treated as independent case budgets.
Scoped single-file or group reviews must bind the actual original inventory,
not manufacture it by changing the current selection.

The existing `native_group_budget_correspondence.qnt` and budget policy are
retained. Adding their positive results does not override missing coverage.
Do not retry either projected recipe unchanged and do not weaken these rules
to produce a PR green label.

## Next Causal Work

Preserve the full historical campaign when binding its original budget, or
use independently recorded original single-case/group controls with exact
identities. Keep all negative reports and original budgets.

The current immutable source already includes the typed GC table snapshot in
`lib/_system.scm` (candidate digest
`a21decdf2130b031dcc1ab0539a9914c1924cf6ffc3aec597872a1494e70577d`).
Its `##gc-hash-table-for-each` and search traverse the rooted snapshot, not the
vendor baseline's mutable physical indices. The full interpreted campaign
passed `write_shared.scm` and `table-search.scm`; this does not independently
close the diagnostic `018-gc-table-iteration` obligation. Bind that original
counterexample to the existing source/model repair before running it, rather
than implementing another snapshot patch or rerunning the failed baseline.

Current milestone acceptance remains 2/12. Complete gsc, dedicated PR gsi/gsc,
stress gsi/gsc, registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness
and release performance remain open.
