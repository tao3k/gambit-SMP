# SMP Trajectory Supervision Review

Date: 2026-10-18. This is a reviewed observation summary, not a native verdict
or an independently replayable copy of the complete public tool transcripts.
Raw Agent transcripts remain disposable local cache, not a new Git asset.

The generic ownership review belongs upstream in ASCENT:
`docs/trajectory-supervision-feedback.md`. This file records its SMP application.
Existing protocol and usage remain in [the application document](smp-trajectory-application.md).

## Observations, Not An Efficiency Claim

The cached `grok-smp-debug-projection-public-events.jsonl` trace contains 26
assistant messages and 64 public tool calls, zero terminal calls and zero
edit/write calls. It contains no final result event. The supervisor stopped
that run; the operator interruption is retained, not labeled a native failure
or a user cancellation. Its bytes have SHA-256
`5e2970bfccb1c9e06729bc4cca4f2d24fd8373fbd326c1656db85b23d2d90357`.

These counts show a failure to transition from reading into query execution
and a repair artifact in that window. They do not prove every read redundant,
nor identify the cause as missing DSL expressiveness. Repeat classification
requires comparable source, question, operation and input identities; otherwise
the comparison stays unknown.

The later `grok-smp-debug-projection-tools-restored-public-events.jsonl` trace
attempted one `trajectory clues` query using the project's Scheme constructor
and candidate/mechanism bindings. The tool rejected execution before any Library
result. The wire message said "User cancelled the execution"; no corresponding
human cancellation was observed. This is an execution interruption, not a
negative logical query result. The exact permission/parser cause is unproved.
That trace's SHA-256 is
`261180d98838910c5bdb689e072db2b024badc364c5d615b082957be2eae41d6`.

A separate local invocation of the configured Scheme query returned the
registered debug-label counterevidence with a source digest and expandable
reference. That establishes an available query path, not successful Grok use
of it. Framework tests and formal protocol checks do not close this distinction.

## Architectural Assessment

`repository_clues` already loads registered Views, binds source identities,
calls ASCENT selection/slicing, and persists an opaque read checkpoint. The
project's `make-stack-entry-navigation` declaration already expresses all-factor
matching on one `(id, digest)` witness. These are reusable boundaries to retain,
not reasons to create another Python search engine.

For this investigation, a new source observation, debug-label association,
applicability condition or failed premise belongs in Evidence and Scheme DSL.
Python must not acquire branches for `_repl`, GC headers, label partitioning,
specific candidate names, or the milestone count. A new scenario should use the
same query/checkpoint entry with different registered data and declarations.

The recent generic completed-runtime source-inventory change addresses producer
binding, not logical relevance. It must be assessed by that contract and its
cross-source negative tests. Help changes address interface discoverability;
they are not proof of better evidence use. No further Python branch is justified
merely by the two failed Agent windows recorded here.

## Improvement Record And Acceptance

- Entry-use gap: audit whether the concise API and existing caller-owned DSL are
  sufficient to formulate and execute a query. Expected benefit is fewer
  implementation-discovery reads; no measured reduction is claimed.
- Execution gap: retain the exact rejected command and tool result separately.
  Resolve at the CLI/client boundary if reproduced; do not alter inference or
  introduce an execution bypass to obtain a green query.
- Evidence gap: add or revise declarative facts/rules only when an executed,
  source-bound query demonstrates a missing association or applicability fact.
- Continuation gap: compare passed checkpoint, source/rule identities and shown
  units before calling replay redundant. Scope changes and intentional rereads
  remain valid; do not force a research direction.
- Task outcome: retain the native failures and require a source repair plus
  original native acceptance. Better citations alone do not advance SMP.

The immediate expected architectural benefit is extending this case without
another Python domain edit. Real acceptance requires observable Grok queries,
traceable slices and useful continuation, followed separately by native repair.
No new efficiency or native correctness result is claimed by this document.
