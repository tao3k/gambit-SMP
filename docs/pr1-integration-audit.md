# SMP PR 1 Integration Audit

## Identity And Scope

This integration joins the accumulated research/storage checkpoint at
`3fffdca` with PR 1's published head
`71a8db0a7a610c364ac4520f22f7f5983d0d5549`. Both histories remain ancestors;
the PR branch is updated without a force push. Concurrent uncommitted compiler
research and the dirty upstream submodule are not merge inputs.

## Conflict Decisions

Thirty paths required explicit reconciliation. Decisions were made by contract,
not by accepting either branch wholesale:

- Evidence references retain immutable Git/checkpoint identities and use
  `reference_bytes`; reading a mutable pathname alone must not replace this.
- Clue transport retains the published bounded UTF-8 carrier and native query
  recovery. The local reader binds one snapshot across framing trials and adds
  task-scoped hypothesis replay; the opaque checkpoint retains that scope.
- Grok retains the published literal read/help and carrier declarations together
  with registered task capability grants. This does not grant arbitrary shell
  execution or native producer edits.
- Lifecycle qualification retains the stricter delayed join-error recovery
  controls. An immediate repeated join in the error arm does not establish a
  successful later transfer. Numeric-host observations do not promote 8/12.
- Research documents retain the additional local source findings and failed
  experiments. The observation view retains the expanded native observations,
  with its matching byte identity rather than the older smaller view's digest.
- Source reviews retain the v2 immutable before/after identities. Published
  historical model results, counterexamples and prior review material from PR 1
  remain available; their bytes and outcomes are not relabeled as fresh runs.
- Zig traceability retains the collector-context extensions and their matching
  document bindings. Source-scoped checkpoint references remain explicit.

The `.olean`/`.txt`/`.rb`/`.sh` Evidence exclusion is extended to all raw
`.log`/`.stdout`/`.stderr` transcripts. Both branches' historical raw identities
are retained as typed, content-addressed observations in the existing publication
registry; transcripts move to disposable task cache. Expected failures and
decoded counterexamples remain Evidence, without promoting their outcomes.
Readers and publishers now use that same contract, including model progress,
source components and native archives. Cache deletion does not reset historical
results or checkpoint progress, while source drift and missing observations still
fail qualification. The imported
historical `view-loader.patch` has an existing trailing blank line; its bytes
are retained rather than rewritten merely to silence a whitespace warning.

## Verification Boundary

The integration regression covers storage/publication, immutable source reads,
Evidence views, progressive CLI queries, checkpoint and journal recovery, Grok
permissions and delivery, lifecycle qualification, and CI contracts. The log
belongs to the existing task cache, not Evidence. This integration is not a new
SMP bootstrap, native stress qualification, or milestone promotion.

## Retained Regression Results

- Integrated regression: 405 tests, initially 403 passed with two fixture
  contract failures in `test_native_observation_bindings`. The temporary
  checkout now has a real registered execution owner, and changed output
  identity still fails validation. Both affected modules passed the subsequent
  26-test run. The original failed result is not relabeled as a green run.
- Additional Evidence consumers: 111/111 passed after correcting two historical
  raw-file readers. Their failure and post-fix results remain distinct.
- Validation-profile controls: 23/23 passed. The existing Evidence profile now
  includes output-observation and storage-boundary tests.
- Typed observation controls: 8/8 passed, including cache deletion, source drift,
  incomplete/timeout rejection, and rejection of arbitrary raw-text wrapping.
- Installed `evidence --validate`: `DATALOG-COVERAGE-OK`. Complete review
  collection also passed with 1,831 bound inputs; unresolved obligations are
  retained rather than converted into current native qualification.
- Publication audit: 21 inventories, 1,930 staged objects, zero hash mismatches;
  zero excluded raw/generated suffixes in the Evidence tree or Git index.

The existing publication registry retains 1,120 content-addressed observations
with 1,428 historical origin labels, including the newly rerun compiler-probe
model and its prior immutable receipt. Raw test output stays in the task cache;
these reviewed outcomes, counterexamples, identities and limitations survive
cache collection. Other concurrent uncommitted research remains untouched.
