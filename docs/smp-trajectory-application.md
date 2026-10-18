# SMP Application of ASCENT Trajectory Evidence

This is the downstream Gambit SMP application of the generic design in
`gerbil-ascent/docs/features/trajectory-exploration.org`. The generic API and
finite protocol model live upstream; this document does not define them.
Neither document is a native correctness, performance, or agent-efficiency result.

The [supervision review](trajectory-supervision-feedback.md) records observed
Agent integration failures and the DSL-first extension boundary; raw tool
transcripts remain local cache rather than a second evidence authority.

## Direct Logical Evidence Reads

The installed Python framework entrypoint is:

```sh
.venv/bin/gambit-smp trajectory clues --help
```

CLI help and Python `help(repository_clues)` share one contract, including source
schemas, term syntax, result shapes and read semantics. This document does not
maintain another copy of that signature or grammar. `gambit_smp.engine_api` and
`gambit_smp.repository_clues` remain public for Python consumers.

Caller-authored Scheme/Datalog queries run over registered Evidence in ASCENT's
native Session. Neither catalog discovery nor a Context lookup is required.
Bindings are declared relation facts, not Python keyword matching. Claims and
factor cells can be discovered as variables; no default topic, Navigator or
fixed investigation path is supplied.

The CLI transports the Library's inert Scheme packet directly, including the
traceable `brief` and a short opaque `checkpoint` token. The same token works
across processes through `--checkpoint`; no caller-managed JSON file is involved.
It acknowledges complete displayed families and complete derived relation
results, not hidden details. The existing history cache stores these read hints
separately from evidence observations and admission. Missing hints cause explicit
safe replay; altered bytes are rejected.

Changing scope or selector re-evaluates relevance while retaining same-source
read progress. Source/rule replacement resets hints, not SMP milestones. Folded
families and derived results preserve source/content-bound references; too-small
capacity for honest references is an error, never an absence claim. Presentation
capacity is not an inference or exploration restriction.

## Existing Configuration Boundaries

- ASCENT owns shared query, delta, display-unit acknowledgement and source-binding
  semantics, together with the QNT/Lean reference laws and native controls.
- Existing `evidence/views.json`, View declarations and component manifests bind
  SMP sources and references. Their `.ss` projections and caller queries express
  factor association, conditions and scope; new factors do not require Rust or
  Python branches.
- Python loads those declarations, verifies bindings and transports native data
  and cached opaque tokens. It does not infer relevance or choose work. No new
  database, configuration interpreter or agent navigator is introduced.
- CLI and API use the same reader and cache. Correctness checks, polarity
  preservation and refusal to acknowledge hidden units are not feature switches.

The read window does not restrict new hypotheses. Failure records retain their
source locks and unresolved premises, not a global prohibition against changed
conditions. Selector output is a query/explanation, not a new attested
observation; derived reachability is not proof of common causality. No `Next`,
action ranking, runtime admission or execution authorization is derived.

## Publication And Reasoning Quality

Protocol properties and Agent behavior have different acceptance boundaries.
Source binding, polarity, unknowns and checkpoint integrity are deterministic
Library obligations. A probabilistic Agent gets a concise, truthful interface
window, not a forced sequence of tools, hypotheses or checkpoints. A fresh read
is valid when intentional; an unexplained repeat is an investigation-quality
observation, not permission to silently rewrite the caller's query.

The published upstream feature is in ASCENT PR #1. The dependency authority is
the existing `pyproject.toml`/`uv.lock`, not a second Library lock or a manually
installed wheel. This publication preserves the PR's existing historical View
registry and does not promote retired sources back to current evidence.

### Observable Quality, Not Hidden Reasoning

Audit public claims, tool requests/results, citations and source-bound
hypotheses. Do not request or inspect hidden model reasoning. Inspect:

- Whether a claim cites the applicable source lock and observation, rather than
  inheriting acceptance or causality from a different candidate.
- Whether a proposed mechanism adds a discriminant beyond already recorded
  requirements. Restating an existing open premise is not a new diagnosis.
- Whether counterevidence and changed conditions survive the conclusion.
- Whether continuation reuses useful evidence, and whether repeated reading has
  a stated purpose. Neither fewer calls nor zero exact repeats proves quality.
- Whether the result changes a source/model obligation or closes a real native
  gate. A well-cited hypothesis alone does neither.

The earlier `c0524b44-7771-4859-a5c8-d98fbf67ff76` report correctly kept
cross-lock causality unproved, but its to-space/stack-start proposal overlaps
the already recorded selection-origin requirement. It did not identify a new
writer, establish operand provenance or repair the runtime. That is partial
investigative value, not demonstrated reasoning-quality improvement.

### Locked-Version Observations And Retained Failures

Session `80a07994-53ea-430e-ae8d-4c2c3e34b711` read help at call one and hit
the existing evidence at call two. Call three omitted the checkpoint and
requested all clues and factor/link relations again. The supervisor stopped
the owned continuation with SIGTERM (exit 143). Keep this failed continuation
alongside the earlier successful one; neither establishes deterministic Agent
behavior. No model query or factor was supplied in its task.

The shared usage window now explicitly says that separate invocations do not
implicitly inherit a checkpoint, including selector changes. This clarifies the
existing API, not a new automatic cursor or enforced navigation policy.

Session `4e39e7e0-d707-411b-941e-6b6cd7074507` had an initial cancelled
read-only command permission, then read help at call two and queried at call
three. Call four independently reused its returned checkpoint, displayed the
two previously folded observation families and replayed zero of the eight
already displayed bodies. The seen support count grew from seven to nine;
the counter-observation remained retained. One deferred derived relation also
became acknowledged. These are observed behaviors under that task, not a
probability guarantee or a cost/efficiency benchmark. A later RTK listing
permission cancellation was retained and only the missing read-only allowance
was added for the same session.

### Supervisor Instructions Are Not Framework Evidence

An instruction to avoid a failed route cannot validate Trajectory. Audit the
actual query, returned slice and subsequent action. The existing Scheme review
distinguishes exact-current attempts, changed premises, intentional replication
and unknown comparisons; a candidate name or repeated file read alone does not
establish redundant work. No supervisor-authored route blacklist is inferred.

Session `a5795010-5c97-4529-adc8-a982f0edc6a0` independently queried the registered
Evidence and attempted checkpoint continuation. The supervisor changed a bound
audit document during that continuation; the query correctly rejected its changed
digest. The supervisor restored the original bytes. Preserve this environmental
failure separately from Agent behavior and native failures. A subsequent fresh
query succeeded. No new runtime patch, formal check or native test resulted.

The public report also illustrates why claim-level factor projection is not a
same-source conjunction. One claim groups current stress and historical bootstrap
observations. Querying factors without retaining observation ID and digest can
lose their association; grouping by claim does not license combining those
conditions. The native family retains per-observation witnesses. The regression
`test_same_claim_does_not_join_conditions_from_different_observations` exercises
caller-authored Scheme joins on those witnesses with current, historical and
unsupported mixed conditions. This tests the existing query contract, not a
mandatory query shape or a guarantee about probabilistic Agent conclusions.

### Evidence Coverage Gap

The registered stack Clues previously omitted the existing
`worker-completion-progress-observation.json`: 503 checked roots completed,
4,497 remained and the original inactivity window expired. The associated
model feedback explicitly distinguishes this from invalid selected-section
alignment and leaves internal work versus root progress, dependency liveness
and complete unchanged stress open.

The new `root-progress-clues.view.json` reuses the same downstream projection
and existing registry. It binds exact recorded sources and exposes those open
links, plus counterevidence against interpreting the timeout as an established
GC-deadlock cause. This does not rule out possible deadlock. No Python inference,
new DSL interpreter, native runtime repair or accepted milestone is introduced.

### Public Counterexample Feedback

After a neutral notice that registered Evidence changed, the same Grok session
queried it and separated the 503-root inactivity result from selected-section
corruption. This was supervisor-announced evidence availability, not autonomous
change detection. The caller chose a fresh read; source replacement makes old
read hints inapplicable in any event.

Its public H-residue report nevertheless confused words with bytes. A general
independent-review request withdrew several overstrong source/image claims but
did not catch that unit error. The reviewed
[source-semantics counterexample](trajectory-public-quality-audit.md) is now
projected by another ordinary View, with the same DSL and exact source hashes.
It counters the byte-offset inference under explicit conditions; the actual
native producer remains unknown. No new Python rule engine or mandatory audit
sequence was added.

The terminal tool truncated some caller-requested 64-KiB presentations. A
Library `presentationComplete` flag must not be reported as proof that every
byte reached the Agent through an outer tool. Honest native folding and actual
transport exposure are separate evidence boundaries. No maximum presentation
capacity or forced query scope was introduced to conceal this observation.

### Final Locked Receipt

The final dependency is ASCENT
`7341569f1b1b388e436ec70018281568a8af5977`, installed by
`uv sync --locked` from Git and verified through distribution VCS metadata.

| Check | Result |
| --- | --- |
| Native Library integration | 85/85, 6.57 seconds |
| Python facade ASP source gate | 1/1, 0.24 seconds; explicit imports replace the rejected glob |
| Strict core Clippy | Pass, warnings denied |
| Installed progressive/Trajectory/View/action/history/index/DSL tests | 97/97, 130.732 seconds |
| History and research-funnel formal tests | 3/3, 173.973 seconds |
| Review-validation framework tests | 11/11, 23.198 seconds |
| Anchored and progressive QNT protocols | Both healthy exhaustive checks passed; all 19 negative controls detected |
| Guarded Lean checks | AnchoredEvidenceSlice and Trajectory passed; children reaped |

The clean-checkout protocol tests first lacked the cached TLC jar and then
encountered sandbox denial of its loopback endpoint. These failures remain
recorded. Supplying the existing jar and permitted local endpoint corrected
the environment; models, assertions and budgets were unchanged.

The earlier upstream `070cc8e` CI rejected the Python facade's new glob import.
The final revision fixes it and passes that actual gate locally. The separate
fixed-baseline ABBA job rejected this functional revision as a changed workload;
no comparable performance result or all-green remote CI is claimed.

After source-semantics counterevidence was registered, the real Grok continuation
authored a new relation query, expanded the returned unit-audit claim, read its
reviewed source and checked the cited vendor lines. Its final public report
corrected the word/byte calculation to `0x80000` bytes and explicitly refused
to infer that integer address 4 was an actual native pointer. It retained the
503-root classification, source/image qualifications, unknown producer and
native non-admission.

That final report's newline-terminated public text has SHA-256
`47bded49992fc761d5b66171ecce5976520d5b6eae072ea26bbebe6ddb4a81ed`.
Its observed source identity was
`e73931657c12d6f99d7809b599e99b9e4705c818ce38755afa001d334a955abc`.
The supervisor explicitly ended collection and requested the public conclusion;
the response ended normally, not as an unassisted termination experiment.

This demonstrates one successful evidence-driven correction after public
self-review alone missed the error. It does not establish a population-level
quality gain, stable reasoning speed, complete transport delivery, a novel
runtime mechanism or native SMP progress. Raw exports remain cache; reviewed
counterevidence and reproducible declarations are versioned. SMP remains 5/12.

The historical qualifications below remain separate from publication and from
complete native SMP acceptance.

## Frozen Progressive-Read Qualification

The local candidate installed in the SMP environment has wheel SHA-256
`a25e488552e1ce2d263b43129625fba07be22845ef804abdee29fa981ad2888f`.
It is not a published dependency revision or a remote-CI result. No lockfile
was updated or public push performed in this qualification.

| Local Check | Result |
| --- | --- |
| Complete native Library integration | 85/85; 12.49 seconds |
| Progressive, Trajectory, View, action and history tests | 81/81; 56.418 seconds |
| Strict core Clippy | Pass, warnings denied |
| AnchoredEvidenceSlice and ProgressiveEvidenceRead | Both healthy exhaustive runs passed; all 19 mutation controls detected |
| AnchoredEvidenceSlice Lean | 17 laws; LeanPoo Guard exit 0, child reaped, 2.426 seconds |
| Formal runner contract tests | 5/5 |

The downstream suite includes cross-process tokens, cache loss and corruption,
partial-page progress, scope shrinking/widening, novel unknown claims and the
same token path through CLI and API. The native suite also covers wide derived
relations: fold with a checkable content reference, expose with presentation
capacity, then retain the exact result without replay. Derived results do not
change observation authority or support/counter counts.

### Real SMP Case

Grok session `c0524b44-7771-4859-a5c8-d98fbf67ff76` used `grok-4.7`, medium
effort, no subagents, the trusted project's concise `AGENTS.md`, and the original
read-only SMP task. Its task contained no query declaration, factor values,
checkpoint or investigation sequence. The separately authorized operating-rule
preload resolved the existing global reference; the only added command allowance
was read-only `rtk rewrite` preflight. Intermediate continuations said only to
continue/complete the current task.

| Actual Tool Call | Observed Result |
| --- | --- |
| 1 | Read the installed framework CLI contract |
| 2 | Authored a Scheme query over attested claims and factor names; received ten evidence families, nine support observations and one counter-observation, with full provenance and a short token |
| 3 | Reused that exact token in another process, authored a different query joining failed candidates and unresolved premises, and expanded seven claim references; mode was `rescope`, delta was 7 added / 0 removed / 46 retained |

Call three returned seven explicit unknown families and zero old observation
bodies. The native checkpoint retained all ten previously displayed observation
identities while adding seven unknown items and two new derived relation results.
Both reads had source identity
`3d7bf6811c9fb7feb512ac59c633018a8243e2171debef5ecc7151699495b259`.
The first public result was 13,186 bytes; the continuation was 6,661 bytes.
They are different scopes, not a matched speed or token-cost benchmark.

The collection episode had 32 public tool calls, zero byte-identical repeated
requests, and no tool errors. After the two relation queries it read distinct
receipts, review contracts and vendor source regions. No build, debugger or
source edit was invoked. Zero exact repeats does not prove zero semantic
redundancy or optimal exploration.

The supervisor ended collection and explicitly requested a no-tool public
conclusion. Grok then ended normally. This final audit is not evidence of
unassisted task termination. Its report recognized the five recorded failed
candidates, kept cross-lock common causes unproved and proposed a falsifiable
to-space/stack-start parity hypothesis bound to the heap-frame identity image.
It did not claim execution authority, a source repair or a native-test pass.

That hypothesis remains unadmitted. The vendor `mem.c` and `gambit.h.in` match
the source lock's base hashes, not its full candidate hashes. The locked patch
leaves the referenced `start_of_tospace`/`set_stack_msection` calculation
unchanged; this is fragment correspondence, not whole-file or whole-binary
qualification. Actual selection-origin values and same-run binding are still
missing. Relevant references are
`evidence/fixtures/darwin-heap-frame-identity/source.lock.json`,
`patches/fixtures/darwin-heap-frame-identity.patch` and
`evidence/fixtures/darwin-stack-selection-origin-baseline/review-contract.json`.
No SMP native milestone was advanced by this read-only case.

### Retained Failures And Reflection

- The first multi-unit draft failed Rust's owned-string conversion check and
  strict function-length lint. Both were fixed without lint exemptions. The
  first QNT draft used unsupported `isEmpty` syntax; it was corrected before
  exhaustive qualification. These are development failures, not native SMP bugs.
- A cross-process test initially referred to a temporary cache fixture absent
  from its test class. That earlier run also left one deliberately corrupted
  scratch read-hint row in the workspace cache. After confirming its exact ID
  and injected `{}` body, the task removed only that row; observation, event,
  head, attempt and clue-journal row counts were unchanged. Both test classes
  now share the existing isolated-cache setup; subsequent fault injection is
  temporary rather than workspace-scoped. The original failed run is retained.
- Session `2ec07810-c75f-4bc4-947d-1c326f03c590` treated `families` as a map and
  failed after Library evaluation. The single CLI/API contract now states its
  actual list shape; no SMP-specific exception handler was added.
- Sessions `10198df5-8ff6-4e67-9233-72bc5d04ca5b` and
  `3a9782e7-4275-4a4d-8c63-b0aa6269fbb4` exposed the common inline-trace capacity
  failure. This was repaired upstream by applying one display-unit protocol to
  families and derived relations, not by widening a performance gate.
- Earlier manual Python output discarded detail or lost the native checkpoint.
  The framework now carries a short cached token, and the normal CLI transports
  the Library's Scheme result without an Agent-written formatter or JSON file.
- Session `88821c83-44d5-4196-ab48-79b967494988` attempted a nonexistent Python
  submodule import. Its extra Python entry hint conflicted with the intended CLI
  discovery surface and was removed. The CLI remains the installed Python
  framework entrypoint; the public API was not removed or restricted.
- The first compound CLI/RTK help call in the following session was cancelled
  by its missing preflight command allowance. That cancellation is retained as
  a harness failure, not attributed to the query engine or hidden as a pass.

This qualifies the specified local progressive-read workflow. It does not prove
arbitrary natural-language association, universally lower Agent cost, automatic
source repair, all-package performance or complete SMP correctness.

## Protocol And Retained History

The upstream finite composition model is
`gerbil-ascent/packages/proofs/quint/TrajectoryEvidenceChain.qnt`. Its
`Append -> Admit -> Check -> ObserveContext/Explore -> Invalidate -> Resume` chain checks that
SMP's retained attempt stays historical after source replacement, that only
independently reviewed current evidence is exposed as a current result, and
that the context neither grants execution nor closes alternative hypotheses. The
SMP adapter must bind each abstract generation to the exact source/fixture/
toolchain identities in the actual receipt. Model checking does not replace
the Scheme evidence review, sealed action authorization, bootstrap, or native
stress tests.

## Existing SMP Inputs

- `reasoning_history.py` retains every observation event, including repeated
  facts. `evidence/dsl/history.ss` derives added, removed, retained, and changed
  input facts without rewriting old observations.
- `evidence/dsl/actions.ss` provides `OpenPrediction` and `Discriminator` for
  competing hypotheses. Observation presence alone does not prove a cause.
- `evidence/dsl/modeling-guidance.ss` emits optional, source-bound investigation
  windows and explicitly grants no execution permission or mandatory order.
- Native receipts, QNT outcomes, source correspondence, bootstrap, and stress
  have different evidential scopes. A model result must not become a native
  pass through the exploration packet.

The SMP adapter should map stable focus, obligation, hypothesis, operation,
source, result, and verdict references to upstream opaque identities. It should
not copy Trajectory storage, infer hidden model reasoning, or implement relation
evaluation in Python. Missing bindings yield an unknown comparison, never an
assumed repeat.

`trajectory-review.ss` emits evidence relations, not a `next` or `actions`
recommendation. An action ID in the adapter identifies an already discovered or
observed request; it does not narrow the model's future hypotheses or choose
its next experiment.

The `context` operation does not take an action ID. It replays retained attempts
into upstream Trajectory and returns their source-bound identities, historical
status, open predictions and discriminators without exposing result references.
A model may form an entirely new hypothesis from this context. `inspect` remains
a separate comparison against an already identified action; neither operation
ranks ideas or authorizes execution.

## Retained Historical Interfaces And Qualification

### Historical Qualification Before Relation Slices

The upstream base is `3bb7b4d871395c94996aff47b87609ff2c487400`; the SMP base
is `dc6ab5f319426ce147a91ef1496840dcc25181fc`. Both working trees include
uncommitted integration work. These are not exact-HEAD CI results. The final
locally installed wheel SHA-256 is
`898c8101e9ccbd52e0fdea2efd4e4b9730f614ee3451b9ebf0648eba2907b192`.

Local acceptance consists of 78 native Rust integration tests, three installed
public-API tests, and 58 related SMP tests (15 progressive Clue, nine Trajectory,
eight View and 26 action tests). Strict core and Python-binding Clippy pass
without suppressions. Both healthy QNT models and their 15 expected negative
controls pass; guarded Lean checks pass for Trajectory and ClueSubmission.
This is not a complete native SMP bootstrap/stress acceptance.

The real Grok CLI case used `grok-4.7`, medium effort, no subagents, no debugger
or builds. The initial task provided the task and normal CLI capability only,
not a prescribed query order. The completed investigation made 90 public tool
calls and first obtained selected Evidence at call 10, versus call 17 in the
earlier interrupted pilot. That narrower discovery observation is not proof of
lower total cost: the old pilot was incomplete. Exact duplicate requests were
zero in the completed initial phase; that does not establish zero semantic
redundancy.

The first follow-up took 21 calls, obtaining selected Evidence on call two.
It exposed a real API defect: catalog and source digests shared a field name.
After the namespace fix, the unchanged follow-up task completed in 12 calls,
obtaining Evidence on call one. This is a same-session continuation, not an
independent matched performance comparison. It no longer reported catalog
digest changes as source drift. It also withdrew its earlier inference from
the shared signal class to a shared crashing handler, distinguished the
bootstrap compiler recipe from the historical linked interpreter, and retained
the missing-image and missing-first-writer premises. No automatic next action
or mandatory hypothesis was supplied.

Public outputs and failures remain in the existing local
`.cache/progressive-clues-grok/` results. Model/native build logs remain in the
upstream `.cache/ascent/`; generated traces and binaries are not Git assets.
The CLI and identity defects were corrected, not counted as successful runs.
Milestones remain 5/12; no Gambit runtime patch or native gate advanced here.

### Interface

The active implementation is the upstream native
`ascent.trajectory.ClueExchange`, documented in
`gerbil-ascent/docs/features/clue-exchange.org`. It uses the existing
SourceSession and the single shared Scheme Clue declaration. SMP supplies
declarative projection and selector sources, checked reference facts and
source attestations. It does not compile a Scheme application or implement
Clue validation, selection, grouping or rule evaluation in Python.

`trajectory catalog` lists context declarations.
`trajectory catalog --context CONTEXT` lists callable view/query names and
the partial factor vocabulary. Metadata discovery does not run sealed native
execution admission. A context without a Clue projection still has readable
View metadata; it does not acquire a fabricated Clue capability.

The current query interface is `trajectory clues --select DECLARATION`, or
`--question CLAIM` for an exact claim. It reads the registered Evidence source
relations directly; selecting a Context is not part of this interface.
`--binding NAME VALUE` supplies source facts to the caller-authored declaration.
Unknown names, values and claims remain allowed. The CLI renders inert Scheme
data through the upstream Library, with no fake row observations or JSON-valued
row factors. The former Context/View query CLI was removed from `clues`.

Identity scopes are explicit: `catalogIdentity` binds catalog metadata,
`contextIdentity` binds the host's recorded context, the native exchange's
`sourceIdentity` binds its source projection, and `selectorIdentity` binds
the chosen declaration and request bindings. Unequal digests from different
scopes are not evidence of source drift. No one of these is native admission.

Repository reads require no investigation scope. `context --context CONTEXT`
requires `--scope NAME` because it reads retained investigation history,
not all repository Evidence. New scopes do not erase existing repository
observations. `record` and `inspect` continue to use the native Trajectory
attempt comparison. Their durable observations and failures remain retained;
the Clue API no longer invents status-encoded claim strings from those rows.

With an optional scope, the existing host journal restores source-current
Agent hypotheses. The native exchange validates the complete submission
before persistence; the journal retains its existing compare-and-swap and
source-generation contract. Hypotheses cannot provide authority fields.
An old-source hypothesis remains history, not current support. No second
database, source lock, rule engine or package manager is introduced.

The native results separate support, counterevidence, conditional hypotheses,
factors, neighboring claims, conflicts and unknowns. A historical failure
refutes only its bound premise. A materially changed premise remains open.
No read selects an action, prevents a novel question or grants native admission.

The retired Python wrapper's earlier unit counts and guided trials are not
acceptance of this native interface. The locked published provider remains a
separate version from the locally built candidate wheel until the upstream
change is published and the normal dependency revision is updated. A local
wheel test is not evidence that a fresh locked installation already has this
new API.

## A Concrete Continuation

### Stack-Entry Case

The retained earlier stack-header context exposed three scoped, read-only Views through
the same installed ASCENT Clue query route. Its older push-statement recipes and
drifted sealed engine remain in `historical-action-context.json`, not in the
current discovery request. The current causal View binds the new
`darwin-stack-call-preflight` source lock, patch and diagnostic observation,
with six open obligations, six typed observations and eleven source anchors. It labels the
write-boundary and poll-kind observations as *different source locks*; neither
is a same-candidate native result. The call-preflight observation is a
same-candidate bootstrap PASS followed by `gsi -v` exit 139 before stress. A
one-object GNU GCC diagnostic relink removes that wrong-handler route but
exposes FRAME-RA exit 134; it is not a source-locked native pass.
The failure-premise View binds five failed routes to their own locks and
observations. It currently derives five unchanged-retry denials and eight
unresolved premises, but no native admission.
The Scheme `causal-links` View derives a shared tag-zero frame symptom under
different base source locks, while displaying the diagnostic zero slot at
`stack_break-40` and the historical slot at `stack_break-32`. These are not
the same measured endpoint. The View carries two historical refutations and four unresolved
requirements without equating their first writer or admitting a repair. A
changed return tag or identical source lock withdraws the relation in the test.
The diagnostic label-base mismatch is separately derived as an established
diagnostic mechanism, not a qualified source repair. Withdrawing that evidence
puts it back among unresolved requirements. An investigator repeated this
already recorded label-base derivation until manually redirected to the first
invalid return-address producer, demonstrating the value of exposing the
established/open distinction directly in the Scheme query.
Its numeric probe facts are transcribed from hash-checked prose receipts, not
extracted from typed numeric receipt fields. This keeps the claim auditable but
does not yet make observation-to-fact binding automatic; future native receipts
should carry explicit slot offsets before this relation can be promoted beyond
an investigator clue.
The diagnostic receipt records image hashes but no retained path; a Grok
investigator found no matching image among 150 local `gsi` files and correctly
declined to substitute the formal bootstrap binary. The View therefore keeps
an explicit traceable-image-or-new-source-locked-candidate requirement open.
The hypothetical-premise withdrawal test shows that a genuinely changed,
checked and source-refined candidate can become reviewable without changing
the historical failures or authorizing execution.

The SMP investigator consulted the first two Views before evaluating the
call-preflight candidate. It identified the old poll-kind/write-boundary lock
split, did not inherit native acceptance, and avoided repeating those unchanged
routes. A separate lightweight Agent initially invoked a stale local CLI and
received a missing-library-lock error; the locked installed CLI completed the
same discovery. A free-form question still returned `unknown`, whereas a typed
`view-query` returned the scoped obligations. This is a real remaining
retrieval gap: the Agent must select a declared View/query from discovery before
it can provide that scope. The case supports better evidence selection in this
one decision, not a measured token saving, general Agent-quality improvement,
or milestone 6/12. Only the complete source-locked native gates can advance it.

Suppose rounds 1-7 run the same native stress on the same source and observe
the same failure. Before round 8, the packet can show that exact result, its
source and failure reference, and the still-open first-corrupting-write
question. The investigator may inspect that write, propose a different header
ownership hypothesis, or re-run stress intentionally to assess nondeterminism.
The packet records prior evidence and the open question; it does not enumerate,
choose or prohibit possible directions.

If the source, compiler, fixture, topology, or hypothesis changes, the old
receipt remains history but is not silently a current answer. A new native
failure may supply a valuable counterexample even when no SMP milestone closes.
An untested, unconventional hypothesis remains welcome even when it has no
immediate predicted observation.

## Downstream Measurements

Measure separately:

- Exact-current repeated attempts and their observed tool/model cost.
- Distinct `repeatCandidates` (later attempts with an earlier matching current
  observation), separately from all `repeatedObservation` evidence pairs.
  Five identical attempts create ten pairs but only four later candidates;
  neither count proves avoidable reasoning or wasted work.
- Similar attempts with changed premises or intentional replication purpose.
- New source-bound observations, competing hypotheses and distinguishing
  experiments proposed in a continuation window.
- Independently closed SMP obligations, native correctness, and total cost.

The claimed pattern of seven redundant rounds in ten is a measurement target,
not an established SMP statistic. Unknown token usage, interruptions, and
failed continuations remain visible. Reduced repeat count with reduced
hypothesis diversity or weaker native completion is a regression.

## Qualification Boundary

First replay a retained SMP prefix using only evidence available at that
point. `inspect` accepts an exact retained attempt ID as `through`; it replays
only that inclusive prefix and rejects an unknown endpoint, so later attempt
events cannot enter the packet. Each new attempt retains the digest of its
recorded-only snapshot. Retrospective replay requires that exact snapshot
digest at the endpoint, even if a later snapshot has the same source identity.
Older attempts without a snapshot digest remain readable as history, but are
not qualified for retrospective shadow review. The digest binds caller input;
it does not independently certify the historical snapshot or the reviewer's
judgment. Audit every upstream `ComparableEarlier` and `RetainedResult` reference
against the exact source and verdict identities. Compare matched later
continuations with and without the packet, preserving all failures. Do not
declare an SMP improvement from a generic upstream unit test, or an upstream
feature from this downstream mapping. Existing sealed native execution review
and budgets remain unchanged; exploratory context cannot override them or
impose its own budget.

## Rule Feedback Boundary

If an exact-repeat notice is contradicted by a source-bound SMP observation,
retain both the notice and the contradiction. It becomes a counterexample to
the comparison rule, not an instruction to rerun or abandon a hypothesis.
The upstream `TrajectoryRuleEvolution` model requires a revised rule to pass
prefix-only shadow evaluation and an independent current-source review before
publication. Review must bind the full identity and content of retained
counterexamples; equal record counts do not make changed evidence equivalent.
This is a formal design contract, not a deployed automatic rule
updater; SMP native receipts remain the authority for native outcomes.

## Grok Supervision Events

From this repository, `just grok` starts the full model at medium effort;
`just grok-sessions` lists exact session IDs, and `just grok-resume <UUID>`
reopens one without relying on the most recent session. `just grok-wait <UUID>`
blocks on the session event file via Darwin kqueue. It returns for an unresolved
permission request, a failed tool, a terminal command result, or a completed
turn. A quiet report is advisory; it neither stops Grok nor proves a reasoning
failure. Automatically resolved permissions are coalesced before reporting.

Supervisor questions belong only at an idle `turn_ended` prompt. Input sent
while the TUI is busy can be consumed by a permission dialog instead of the
model; this happened during the 2026-10-17 frame investigation and enabled
`always-approve` unintentionally. The session was stopped and subsequent tool
calls audited. Event signals invite inspection, not automatic acceptance of a
source repair or native milestone; those still require the locked source,
Trajectory evidence, and native receipts above.

## Current Stack-Entry Clue Application

The current context adds `stack-entry-progressive-clues`. Its Scheme projection
binds the `darwin-stack-call-preflight-label-base` source lock and portable
native observation, alongside the separately identified older diagnostic.
The formal recipe spent 193.826598667 seconds and returned DENY: source,
configure, seed and review passed; `make from-scratch` returned 2 after compiler
subprocess SIGSEGVs. The older FRAME-RA zero-slot diagnostic has another source
lock and image. Their common cause and the first invalid return-address producer
remain open. No native gate advances from this projection.

Clue protocol proofs belong to ASCENT. Its QNT model is
`packages/proofs/quint/ClueSubmission.qnt`, and its Lean laws are in
`packages/proofs/lean/ClueSubmission.lean`. SMP retains its runtime Facts and
consumer integration tests. The context explicitly selects a caller-owned
Navigator Evidence view. Its all-factor intersection is this SMP application's
policy; another context can supply different relations and matching semantics.
Only a `question` projection of exact claim strings is required by the transport.
The existing host journal stores immutable Agent
submissions with source identity and a compare-and-swap prefix. Agent fields
cannot supply an attestation, and a changed source keeps prior submissions
inspectable as history.

Read a scoped slice through the context's declared Navigator:

```sh
.venv/bin/gambit-smp trajectory clues \
  --context evidence/scenarios/stack-header/action-context.json \
  --scope stack-entry-investigation --question stack-entry \
  --binding entity stack-entry --binding candidate current-formal
```

`--question` reads an exact claim. With bindings it labels the investigation,
while the caller's Scheme rules interpret the supplied factors. Neighbor
targets are exact claims for another read. A previously unseen factor can enter
as data; an empty match stays unknown. The help and native `sourceIdentity` and `selectorIdentity` bind the query to
its projection and selector sources; vocabularies remain partial.

`trajectory submit` accepts either `--clues-file` or `--clues-json`, together
with the same context/scope and `--expected-prefix` from `clueJournal.prefix`.
Each record has `id`, `claim`, `polarity`, `source`, and optional `factors` pairs.
It remains a hypothesis after persistence and recovery. A stale prefix rejects
the submission without overwriting the retained prefix.

The three-round integration case reads the current formal failure, then the
historical counterevidence to an unexplored label-base claim, then submits and
rereads a novel producer hypothesis. Those checks exercise actual Scheme rules
and SQLite transport. They do not measure Agent reasoning improvement. Grok's
initial interrupted trials remain in the local cache: shell preparation
permissions prevented early queries; a later read exposed an additional
discovery gap when the Agent searched the implementation to learn query
semantics. The help and source references address that observed interface gap.

The earlier operation-guided Grok trials are historical integration
tests. They do not establish natural tool discovery or independent reasoning
improvement. Runtime-driven qualification must instead start with the task and
normal tool declarations, receive structured clue requests or observable tool
events, query the caller's DSL and return scoped evidence through tool results.
The current event-file watcher is a supervisor notification mechanism; it does
not provide this synchronous tool-result bridge. The existing upstream
`EvidenceConversation`/`EvidenceInteraction` flow is the integration surface to
reuse. Internal model reasoning is not a host-observable trigger.
### Earlier Local Qualification And Open Gate

An earlier local candidate used installed wheel SHA-256
`abbc5e56c1257cf4cb17abd9cc8e014d4bb5173069efaede55164c190b33d001`.
Native integration passed 83/83; the related SMP checks passed 67/67
(24 progressive Clue, nine Trajectory, eight View and 26 action tests).
Strict core Clippy passed. The anchored QNT model passed with all 13 mutation
controls detected; guarded Lean checked 11 laws and five formal-runner tests
passed. These do not qualify Grok discovery or native SMP repair.

The public query manages the checked engine when none is supplied. Shared
`(include clue-selection-schema)` declarations remove schema boilerplate but
provide no association, navigation or question rules. A question identifies
an evidence claim, not free-text search. Source writes remain rejected.

The concise project `AGENTS.md` documents API introspection and caller-owned
queries. Grok initially skipped it because this workspace was untrusted.
Following explicit approval, only this SMP workspace was trusted; inspection
confirmed project instruction loading. In session
`9e9936df-1bd2-43ec-a60d-b8ae75f287fa`, the original task plus the separately
authorized operating-document preload contained no injected API or query
template. The first tool call read `repository_clues` help; the second listed
the directory. This qualifies early interface discovery, not an evidence hit.
The one-turn harness stopped there; its turn-limit exit is not a native failure.
A single continuation containing only "continue the current task" produced
three more calls: two file searches and a scenario-directory listing. No
relation query ran. The trial stopped after five cumulative calls: early API
discovery passed, but transition from the API contract to associated evidence
remains open. Do not repeat this unchanged route as a successful first-hit case.

The qualification records below describe earlier candidates and failed trials;
their hashes and counts are historical, not the latest installed artifact.

#### Variable Binding And Actual Entry Trial

The public usability audit of the trusted-session failure identified a concrete
contract omission: `TERM` did not explain variable binding, joins or the
source-column-to-question projection. File search was the Agent's choice, not
an API prerequisite. The contract now distinguishes direct exact-claim reads
from selectors whose variables bind existing Evidence rows; it documents term,
binding, expansion and negation semantics and a domain-neutral executable
declaration. No investigation factor, fixed navigation or Python inference was
added. A regression test queries real registered evidence without any prior
claim or factor identifier, preserving both polarities and expandable references.

Real Grok session `2404d851-0bcb-4ba0-8547-77a395d3ba40` received the same original
SMP task and authorized operating-document preload, with no query in the task.
Project instructions exposed only the normal API. Actual tool call one read
API help. Call two authored and executed a Scheme declaration joining `clue`,
`factor`, `link` and `attested`; it returned exit zero, nine support observations
and one counter-observation, with receipt/source digests, failed premises and
source-bound expansion references. Thus its first related query hit, at actual
tool call two, without file searching or a known claim identifier supplied in
the task. Harness continuations contained only "continue the current task".

This is not full progressive-use acceptance: the Agent requested 200,000 bytes,
printed a truncated family list, then at tool call three requested 2,000,000
bytes and dumped the whole family set again without a checkpoint. That run was
stopped after the third call. It proves early related-query execution, not
compactness, avoided repetition, better hypotheses or native SMP progress.
The public contract now distinguishes source-bound folding from string slicing
and explains that a missing checkpoint makes a repeated request an initial read.
No artificial capacity cap or automatic cross-Agent acknowledgement was added.

The focused suite passed 25/25 (29.570 seconds). A subsequent 68-test run was
invalidated by this task editing `__init__.py` after snapshot creation; it ended
with five source-drift errors and one downstream expected-error mismatch.
This is retained as an invalid run, not counted as a semantic pass or hidden by
the focused result. All source changes must remain frozen for its rerun.

After freezing the source, the complete related suite passed 68/68 in 48.236
seconds, without assertion or source-currentness relaxation.

A second fresh session, `6120e684-15a8-4086-9ede-86ea1e8552ee`, independently
read help at tool call one and executed its first related Scheme query at tool
call two. The task again supplied no query, factors or investigation sequence.
It joined attested claims and projected factor names, returning nine support
observations and one counter-observation. With a caller-selected 12,000-byte
capacity, two families remained honestly folded with expansion references and
`presentationComplete=false`. The public result was 15,340 bytes after the
Agent's pretty printing; this is not the Library's compact serialization size.

The follow-up at call three still re-queried the whole source set at 65,536
bytes, rather than narrowing the scope. It also wrote a checkpoint to a generic
temporary filename, contrary to the trial's no-file-modification instruction.
No build, debugger or source modification ran. The session was not continued.
Accordingly the two independent first-query hits qualify entry usability only;
progressive scope use, checkpoint discipline and full read-only compliance
remain unqualified. These failures are not converted into a pass by the 68
local tests. No native SMP milestone was advanced.

The package now exposes the same `engine_api` and `repository_clues` objects
through normal Python root-module introspection. Lazy exports preserve CLI
`--root` selection; they do not implement another query engine. Root CLI help
describes the capability, and the current API contract precedes historical
interfaces in this document. The public alias exercises real inference in the
20-test progressive Clue suite (6.289 seconds); the nine Trajectory tests also
pass (1.130 seconds). These are local API controls, not Agent-discovery results.

The direct relation-query candidate uses the locally installed wheel with SHA-256
`8b2acd6d70b7f7d82039b35bfcbc5416ff811af9107d4180c0ebec8331af39c3`.
It is not a published revision or exact-HEAD CI result. Native integration passed
82/82; the installed API passed 3/3. Related SMP checks passed 19 progressive
Clue, nine Trajectory, eight View and 26 action tests. One earlier View run
returned DENY in its action test; its exact reason was not captured before the
test's temporary receipt cleanup. A focused rerun passed in 9.451 seconds and
the subsequent eight-test View run passed in 14.634 seconds. No budget or
assertion was relaxed; the earlier DENY is not erased by those later results.

A real direct CLI relation query returned 7,842 bytes with counterevidence and
source references, without a Context binding. Healthy anchored-slice QNT
exploration covered 7,680 states and detected all twelve mutation controls;
guarded Lean checked ten laws. The other Clue models and their fifteen controls
also passed. These are not native SMP bootstrap/stress results.

Real Grok observations remain separate from those local controls:

| Case | Public Tool Calls | Observation | Qualification |
| --- | ---: | --- | --- |
| Initial capability-mentioned task | 104 | First old View query at call 18; no authored relation query | Discovery gap, not new-slice acceptance |
| Task without the original framework requirement | 79 | No framework invocation; normal end | Not the requested workflow |
| Original task including the existing Python framework | 134 | Read the public API entry; last attempted import/location command was cancelled | Incomplete, not a first-query pass |
| Same session resumed with explicitly authorized Python execution | 14 additional | Call four evaluated four existing Evidence views successfully; normal end after seven turns | Relational evidence retrieved, not new-slice acceptance or cold discovery |
| Public Python exports and improved CLI help, original unhinted task | 122 | First terminal request used whole-view evaluation; permission event was `cancelled` for the compound `test -x ... && python ...` command | No query executed; discovery and harness permission gaps |
| Current contract moved before historical material | At least 11 | First calls read a missing `RTK.md`, listed the repository, then searched files | Supervisor interrupted the exact owned process; exit 130, not acceptance |
| Session-only capability rule, two model turns | 6 | First two calls read missing `RTK.md` and listed the repository | Turn bound reached; two turns are not a two-call bound |
| Visible task-message interface signature, one model turn | 2 | Same missing-file read and directory list | Early discovery gate failed; no continuation |
| Visible task-message signature plus relation schema, one model turn | 2 | Same missing-file read and directory list | Early discovery gate failed; no continuation |

The user subsequently authorized a concise neutral interface description and
required entry within the first two tool calls. That description supplies API
names, signatures, relation schema and return shape, not factor values, query
templates, answers or an investigation sequence. The two short visible-message
trials establish that description alone is insufficient in the current runner.
Their public startup messages contain an existing unresolved `@RTK.md` user
rule; both first calls attempt that nonexistent relative file. This establishes
a concrete startup reference gap, not proof that it is the only cause of later
tool selection. The global rule was not removed, overridden or rewritten, and
no operational/private configuration was exported to work around it. No raw
model reasoning was inspected. No further unchanged long trial is qualified.

The third case ended with Grok's `cancelled` status. It was not a native runtime
failure, and it does not prove that the Agent would never select the interface.
The command was a Python package-location probe, not a relation query. Its
inspection permission exposed a test-harness gap: the original allowlist covered
the CLI, not Python. A broad Python allowance was rejected by automatic review;
a narrower exact-command allowance failed Grok's rule parser on the command's
commas. Neither attempt started a resumed investigation. Following explicit
per-session Python authorization, the same session resumed with the unchanged
task. No blocked operation was routed through another executor.

The authorized resume used `engine_api`, `load` and `evaluate`, not the new
`repository_clues` / `slice_selected` path. Its first executed relation query
was resumed call four (cumulative call 138). It returned five source-locked
failed paths, eight unresolved premises, zero reviewable retries and the
declared cross-lock links. Grok retained the distinction between diagnostic
label-base evidence and current native acceptance. It then proposed an
eight-word return-to-C frame hypothesis, with measurements that could refute
it; this is an Agent hypothesis, not a validated source repair.

The query also exposed an unresolved usage gap: Grok evaluated several whole
views and implemented output filtering/truncation in its ad hoc Python command.
That is not the declared anchor/scope/incremental-slice contract, even though
the underlying relation evaluation succeeded. No authored selector, incremental
checkpoint or slice expansion was exercised in this resume. Neither conditional
first-hit slice acceptance nor reduced redundant investigation is established
by this result. The session ended normally without requesting a build, debugger
or file modification.

Task prompts contain no query statements, factor values, evidence answers or
prescribed operation sequence. No default Context/entry mechanism, forced tool
selection, natural-language workflow prompt or MCP layer was added. Actual
self-discovery and use of the scoped incremental interface remain an open gate.
Low-level relation-query use was observed in the authorized warm resume, not
first-call cold discovery. SMP remains 5/12;
no Gambit source patch or native milestone advanced in this qualification.
