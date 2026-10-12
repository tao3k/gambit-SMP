# Bounty Evidence Coverage

Current discussion/source audit: [2026-10-11 review](upstream-audit-20261011.md).
The refreshed window still has 127 PRs (49 open within the window), and the
selected catalog has 33, not four. Snapshot coverage is not semantic coverage.
The review corrects #1003's superseded failure report, records issue #912's
single-process Linux compiler failure and adds the #1035 completion protocol.
Counts below describe historical campaigns, not current model/native totals.

Latest extension: FFI/GC, shutdown handoff and special-reader header lifetime
bring the model count to 29. Framework tests pass 62/62. The linked issue 792
snapshot and 21 reported failure/history entries are digest-bound; current
remaining gaps are 19 reports without model links, 23 models without native
adapters and 13 adjacent-source reviews. See `docs/ffi-gc-frame-protocol.md`,
`docs/shutdown-error-handoff.md` and `docs/native-pr793-and-gc-incident.md`.
Counts in the original extension sections below are historical, not superseding
this latest snapshot. Full native/bootstrap acceptance remains open.

## Admission Levels

- Inventoried: 127 creation-window PRs have complete file footprints.
- Evidence-bound: 33 selected PRs have exact-head snapshots and paginated
  discussion records; 21 specific failure/history records retain provenance.
- Modeled: 29 bounded protocol models exist. Context-only references do not
  count as a PR repair proof; the index still reports 19 missing model links.
- Native accepted: only the explicitly scoped receipts qualify. Candidate 009
  passes once but its repeated compiler exits SIGBUS, so overall admission is
  DENY. Extracted-source controls and model passes do not override that failure.

The incidents feed four independent header/lifetime/extent/layout controls into
QNT. Candidate 009's incident lacks child PID attribution; diagnostic 010's
incident binds both image UUID and actual failed compiler child receipt. Neither
incident establishes a forwarding-header root cause or complete collector
repair. Missing mappings and adjacent-source reviews
remain executable coverage obligations rather than silently excluded reports.

## Scope And Identity

The 2026-10-10 snapshot enumerates all 127 PRs created since bounty issue
#760 opened on 2022-08-04. Both PR-index pages and complete paginated file
inventories are cached locally. This is a complete creation-window inventory,
not a claim that every implicit issue, pre-bounty design, or discussion has
been semantically audited.

`evidence/upstream/smp-20261010/` contains the discovery manifest, all-window
file footprints, 33 exact-head report snapshots, authored classification and
generated triage. Selected snapshots record head/base, file blob identities,
merge state, and all paginated issue comments, reviews and inline comments
as public links and body digests. Raw API bodies/patches remain in the ignored
local cache. API patch availability is not a full-diff semantic audit.

`failures.json` initially added 20 specific historical/residual report entries to the
executable index, including #1038 forced GC/compiler failures and #1039's
ordinary-procedure allocation control. They retain their report provenance
and native-open status instead of collapsing every signal 11 into one cause.
The original sampled report audit remains available in
`docs/smp-upstream-report-audit.md`; it is not the expanded inventory.

Triage partitions the 127 entries into 33 catalog reports, 13 adjacent-source
review obligations, and 81 entries without a discovery signal or critical
source overlap. The latter category is not proof of absence of SMP bugs.
The 13 open entries are #809, #824, #848, #868, #871, #891, #905, #926,
#947, #948, #1027, #1028 and #1030. Large compiler proposals, representation
changes, module initialization and I/O fixes cannot be silently excluded just
because their titles omit SMP.

## Architecture Obligations

| Protocol | Report references | Current obligation |
| --- | --- | --- |
| Processor lifecycle, startup, cleanup | #783, #788, #793, #1003, #1004, #1014, #1016, #1036 | Initialization/publication, interrupt propagation, rollback and heap admission |
| Parallel GC, roots and shared tables | #988, #989, #1010, #1019, #1038 | Roots, forwarding, chunk publication, relocation and shared-state ownership |
| Process wait and pipe predicates | #1007, #1037 | Waiting processors retain GC participation; no callback under incompatible locks |
| Scheduling and priority | #1022, #1032, #1034, #1041, #1050 | Queue ownership, preemption, quantum, boost and inheritance interactions |
| Thread groups and termination | #1024, #1026, #1029, #1031, #1035, #1040, #1047 | Membership publication, lock order, abandonment and termination |
| Mailboxes and promises | #1023, #1039 | Unique published state and serialized compound updates without locking user callbacks |
| Continuation stack ownership | #783, #1019, #1052 | Overflow undo must not reclaim a published/shared stack |
| Supporting test reports | #797, #1033, #1042 | Coverage infrastructure or reported tests, not an accepted runtime repair |

#788 is merged; #793 is open and unmerged. #988 remains a withdrawn source
reference, not an accepted all-green runtime. Catalog heads for #1031/#1032
match the original catalog; no head drift was established in this snapshot.
Model context references are deliberately distinct from repair coverage.

## New Bounded Models

| Model / PR | Frozen negative controls | Positive TLC exploration |
| --- | --- | --- |
| `mailbox_publication` / #1023 | Competing lazy installation; stale receive overwrite | 25 distinct / 38 generated / 0 queue |
| `promise_publication` / #1039 | Split check/store; injected callback-under-lock control | 528 distinct / 803 generated / 0 queue |
| `stack_undo_ownership` / #1052 | Shared stack reuse; injected wrong-frame invalidation; metadata wiping | 85 distinct / 109 generated / 0 queue |

Seven actual TLC traces are frozen and bound to model digests. Positive results
apply only to the declared finite bounds. Fault controls are not all alleged
upstream bugs. Mailbox topology/timeouts/GC, general promise recursion and
delay-force chains, C weak memory, arbitrary collector movement and full
runtime progress remain separate obligations. Receipts are under
`evidence/model-results/` and scope is in each QNT/case manifest.

Current-source native `make -C tests test12` passed using GNU GCC 16.2.0 with
inherited SDK/library overrides removed. Output:
`PASS: overflow undo invalidated at all five continuation operations`.
This exercises 20 macro-fixture combinations (five operations, first/nested
frame, metadata absent/present). Wall time was not recorded. The fixture
mocks VM registers/transfers; it is not moving-GC, compiler, bootstrap or
Gerbil acceptance. Existing local source changes were used, not reapplied.

## Reproducible Coverage Checks

```sh
uv run --locked gambit-smp upstream-snapshot \
  --cache .data/upstream-smp-20261010 \
  --export-triage evidence/upstream/smp-20261010
uv run --locked gambit-smp evidence --refresh
uv run --locked gambit-smp evidence --check
uv run --locked python -m unittest discover -s tests -p 'test_*.py'
```

Triage export is offline. Discovery/classification/footprints/triage and report
snapshots are digest-bound inputs to the Datalog export. A file-cache hit alone
does not bind a PR head. Supporting test PRs do not satisfy runtime obligations;
model context does not silently become repair coverage.

The initial coverage-extension framework suite passed 43 tests. It exposed 20 reports
without model links, 20 models without native adapters, and the 13 adjacent
source reviews. All 33 catalog reports have snapshots. An adapter means fixture
availability, not a pass. Compiler SIGBUS, full threaded bootstrap, remaining
source audits and native suites remain open. Do not repeat a known failed native
route without a new source-backed hypothesis, and do not promote a patch from
bounded-model green alone.
