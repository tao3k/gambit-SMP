# Current Repair Trajectory And Artifact Audit

## Scope

This audit reads retained artifacts; it does not start Grok, rebuild a runtime,
run native tests, change the implementation task's checkpoint or admit item 9.
Items 9 through 12 remain the research scope. The implementation task was
observed running; shared Python/runtime edits and registration changes were not
installed underneath it.

Only public worker reports, receipts and tool-call metadata were inspected.
Private thought payloads are not reproduced or used as a quality metric. Exact
repeated calls are observable behavior, not proof of redundant reasoning.
Cache locations below are observation locators, not reproducible source inputs.
The compact findings and hashes are retained here independently of cache.

## Findings

### P1: Query Capability Is Not The Worker Script Capability

The retained pending worker attempt 0007 grants terminal execution only of its
owned `work.py`. The alias attempt 0006 has the analogous grant. They do not
independently grant the repository's read-only evidence query. The current
`grok_session.py` likewise adds terminal access through individually sealed
task-program keys. This is an authorization distinction, not a request to
weaken permissions or to add MCP.

Observed tool-call totals:

| Retained worker/attempt | Calls | Direct repository-query terminal calls |
| --- | --- | --- |
| pending-repair/0007 | 134: 51 reads, 30 searches, 50 replacements, 2 writes, 1 listing | 0 |
| alias-repair/0006 | 189 | 0 |
| gerbil-freeze/0007 | 40 | 0 |

The last pending attempt was externally stopped, not a completed investigation.
Its receipt reports exit 143, no supervisor timeout and no completed session.
These counts are a bounded tool-metadata audit, not a full multi-session query
count. Earlier scripts/reports include a checkpointed query, so zero here does
not mean the worker never accessed evidence.

A broader metadata pass inspected all 20 retained attempt streams in these
three owners' archives. Seventeen contain tool calls, totaling 1,924 calls and
32 terminal calls. Only two terminal command strings mention the query surface;
both are initial help/interface-discovery composites and have failed tool
updates. They are not counted as successful evidence queries. Internal calls
inside `work.py` are not identified by this command-string count. This is a
visibility/capability audit, not a claim that 1,922 calls were wasted.

**Gap:** calling a query from an editable native-work script entangles reading
with candidate execution and encourages more Python script maintenance. The
Agent cannot be expected to use a separately ungranted terminal command merely
because help documents the API. A tool appearing in the available-tools event
does not imply permission to run arbitrary commands through it.

**Existing-layer remedy:** declare an independently authorized, read-only query
capability through the existing command/registration and provider adapter. Keep
native execution grants separate and unchanged. Do not add a second search
API, a universal Python grant, injected investigation steps or automatic work
selection. Validate the actual granted route, not just the Python callable.

### P1: A Successful Query Can Have No Relevant Evidence

The pending report retains a query with checkpoint input
`clue-read:00fca69a8d0e10c93a8c8d173a0b5e67770df87235471cf9119d0d646155d260`
and successor
`clue-read:d90c25201ab1a9294bf5a7e2249abcd9fd16774ab8714ae6049247f023296b24`.
The API returned successfully but all three supplied associations were unknown:
`SUBJECT=runtime-generation-recovery`,
`ARTIFACT=recover_retired_processors`,
`SCOPE=child-exclusive-owner-handoff`; support/counter/hypothesis counts were 0.
The report correctly does not claim that this confirms the candidate.

A separate auditor read of exact claim `runtime-successful-error-recovery`
returns one unclosed counter-observation with lifecycle and generation-recovery
factors. Thus evidence exists, but the submitted association did not reach it.
This is not a native failure, and query completion/checkpoint issuance is not
evidence relevance.

This audit also exercised the current public Python read API, without the CLI's
execution/cleanup scope. Its first related request used the registered relational
binding `mechanism=runtime-generation-recovery`. Scheme selected four actual
claims, with two support and two counter-observations, no unknown binding and
no conjunction gap. It did not discover a native recovery success.

At display capacity 2048, inference completed but presentation did not; the
family bodies were not shown. A fresh process continued the returned checkpoint
with capacity 8192 and presented all four claims:

- `generation-recovery-conditional-model`
- `generation-recovery-native-handler-quiescence`
- `preadmission-generation-crossing-negative`
- `runtime-successful-error-recovery`

Its `presentationComplete` and `evaluationComplete` are true. The second read's
`added=40, retained=0` is not evidence of replay: the first folded presentation
had not shown those family bodies. Derived association rows already shown were
returned as retained relation references. This distinguishes inference coverage,
display acknowledgement and native qualification. It is a current API read,
not a new Grok execution or proof that all four repair bundles are registered.

A third fresh process repeated the same binding with the second checkpoint at
8192. It returned `added=0`, `removed=0`, `retained=40`, no family bodies and no
deferred claims; both completion flags remain true. The checkpoint itself stayed
unchanged. Thus this actual unchanged-source read does not replay acknowledged
evidence. It proves neither reduced inference time nor worker use of that route.

The complete-read source identity is
`fc0d78586553578134758717d58354632b633dcb79e33e559fcd97a45bbf1f3a`.
Read tokens are, in order:
`clue-read:ad20b3efa29fe3ab43be14ced6ea4331c2971677b735fa663445ac0f2711e098`,
then `clue-read:b3dc3d94cb9b6445958e3d4469f80934f7e37730a5363c5842a878c2d55d5fc0`.
The existing public API was called with the relational binding and prior token;
no new wrapper or workflow was introduced. Loss of these disposable read hints
would require honest replay, not erase the underlying evidence or native history.

**Existing-layer remedy:** use the downstream Scheme association to expose
available factor vocabulary and scoped discovery witnesses when bindings do
not match. Register the current repair clauses and their actual source scopes.
Keep exact conjunction matching on observation identity/digest. Do not silently
turn uppercase aliases into keyword matching or combine factors from different
witnesses. Return unresolved associations and expandable alternatives; do not
tell the Agent which hypothesis to choose.

### P1: VM-Wide Join Flags Do Not Establish Per-Worker Recovery

The inspected cumulative patch has VM-wide `lifecycle_os_join_errno` and
`lifecycle_same_owner_joined`. A failed join can set the errno; a later
successful join can set the success flag whenever that VM errno is positive.
The getter checks the two flags. These fields do not bind both events to a
particular worker incarnation or the same exclusive host owner.

This leaves a source-correspondence hole: an error on worker A followed by
success on worker B is not the required error-then-success on A. The field
representation alone cannot distinguish them. This audit does not demonstrate
that this event sequence occurred in a native run, or that the runtime reclaimed
an invalid resource. It rejects the flags as sufficient evidence of that stronger
claim.

The old cached fixture calls `___lifecycle_join_recovery_witness`; the current
fixture instead calls `___lifecycle_join_os_errno`. Their hashes differ. Old PASS
cannot support the changed contract. The current patch/getter observations are
separate from the old binary's behavior.

**Existing-layer remedy:** reuse the incarnation/source/replay contracts in
`retirement_repair_campaign.qnt` and existing join/exit models. Make the missing
event-to-worker/owner correspondence visible in Scheme. The implementation
session must bind actual errno, successful join, quiet publication and handoff
to the same relevant identity. A matching printed phrase or a model success
bit cannot supply the missing relation. This research does not edit that patch.

### P2: Stage Reuse Exists But Was Not Selected In A Matched Pair

Two retained `handler-quiet-join-recovery` runs have identical 46-entry input
maps, tool inputs, engine, execution configuration, host environment and every
stage's `observedInputs`. Both have stable inputs and Recipe outcome PASS, with
`runtimeAdmitted=false` and `releaseAdmitted=false`.

| Execution | Whole Recipe seconds | Configure | Seed | Core |
| --- | --- | --- | --- | --- |
| lifecycle-join-recovery-1 | 361.189324 | 58.024604 | 98.739417 | 180.607193 |
| lifecycle-join-recovery-2 | 374.941907 | 59.498593 | 99.518723 | 191.518011 |

The second wrapper receipt has `prior=null`. Its configure/seed/core commands
execute again, costing **350.535327 seconds** together. This is an observed
reuse opportunity, not proof all those seconds were avoidable: artifact
availability/custody at the original launch and deliberate replication intent
have not been established. Identical inputs alone never authorize reuse.

**Existing-layer remedy:** expose matching retained stage candidates through
existing checkpoint/Session relations before a fresh execution is chosen. Show
current applicability, material availability and custody independently. Retain
the option of deliberate fresh replication with its purpose; do not ban it or
replay an obsolete receipt. Python can enumerate/observe candidates; Scheme
owns support and invalidation. No new cache index or Python semantic planner
is needed merely to connect the existing `prior` route.

### P2: Read-Only CLI Startup Performs Global Mutating Maintenance

The earlier real `trajectory clues` call was interrupted in
`execution_scope -> collect -> task_retention.collect -> write`, before Scheme
evaluation. The source corroborates that `cli.py` enters `execution_scope` and
that the scope runs `collect(root)` first. That collector visits every task.
Retention stores recursive file metadata inventories and writes the dependency
record containing the accumulated expired entries. The interrupted stack was
serializing such an inventory.

**Gap:** unrelated artifact maintenance lies on the query critical path. This
does not identify Scheme inference as slow or justify skipping identity checks.
No measured percentage is attributed to inventory rewriting from one stack.

**Existing-layer remedy:** distinguish declared read-only query operations from
executing operations in the existing dispatcher. Retain source validation,
history CAS, access control and read-checkpoint persistence, but move destructive
global retention off the read path. Keep interruption-safe cleanup in existing
lifecycle/explicit-GC routes. Audit repeated full expired-inventory serialization
separately; do not discard original cleanup CAS or introduce another state store.

### P2: Durable Storage Is Not An Integrated Repair Trajectory

The inspected history database has seven `trajectory_attempts` across three
older concurrent-GC scopes and two `trajectory_clues` under scope `case`.
No repair-9-12 scope was present in those tables. That is only a query of this
store: Recipe journals, read hints, registered views, provider streams and
archived reports are distinct sources and must not be declared absent from
this count. A worker's checkpoint token demonstrates read continuation, not
automatic ingestion of its new findings into the domain evidence graph.

The pending report acknowledges missing roots/unpublished work and no legal
natural-error recovery; the alias report acknowledges its musttail sites remain
inside one large C function and the diagnostic still times out; the freeze
report keeps producer UNKNOWN and no header/type scene. These are useful
negative results, but the recent research bundles are not all registered in
`evidence/views.json`. More files do not automatically become queryable facts.

**Existing-layer remedy:** publish selected, reviewed findings as downstream
Scheme declarations through the existing registry. Associate source/candidate,
scope, counterevidence and changed premise with each clause. The durable history
and checkpoint should reference these identities rather than ingest private
thoughts or every file in a cache directory. No recursive cache scraping as a
new reasoning system.

## Positive Controls And Remaining Gates

- Existing checkpoint code checks declared support inventories and delegates
  applicability to Scheme. This audit did not find a reason to duplicate that
  inference in Python.
- The retained pending report correctly rejects its platform/mirror fixture as
  a runtime recovery witness. The alias report keeps a tiny-control improvement
  separate from real numerical compilation. The freeze report keeps observer
  capability separate from an actual Gerbil scene.
- `numeric-restored-2` is DENY at 90.878 seconds: Scheme-to-C completed in
  14.082 seconds; C-to-module was killed after 76 seconds, exit -9, timeout
  true, no artifact. That run does not establish a deadlock or a compiler fix.
- Recipe PASS and empty `missing_step` concern that Recipe's declared steps,
  not the four native gates. The archived report's incomplete census remains
  an open source obligation even when an earlier Recipe passed.

No item 9-12 closure, full framework qualification, current graph qualification
or native speedup is awarded by this audit.

## Coordinated Repair And Acceptance Checklist

The following are audit handoffs, not deterministic Agent instructions:

| Layer | Acceptance before calling the gap fixed |
| --- | --- |
| Provider/CLI | An explicitly authorized read-only query runs through the same interface without native-script execution or global destructive cleanup. Execution permissions stay separate. |
| Scheme registration/association | Real retained recovery, compiler and observation findings are discoverable from declared relational anchors; a miss returns honest vocabulary/scope witnesses, not fabricated matches. |
| Checkpoint reuse | A matched-pair replay with immutable receipts offers applicable stages and explains material/custody gaps; explicit fresh replication remains possible. A changed fixture is not credited from the old pass. |
| Identity/model correspondence | Cross-worker and cross-incarnation error/success pairs cannot establish same-worker recovery; an authentic matching pair can be represented. Missing producer/root/borrower coverage remains visible. |
| End-to-end research use | Fresh-process continuation shows new reviewed counterevidence without whole-batch replay; the Agent can choose a different hypothesis. Observed repeated calls are reviewed with source changes and purpose, not automatically penalized. |

Do not modify the active native owner's source or run state to implement these
handoffs. Integrate shared framework/registry changes in a coordinated stable
window, then qualify through the existing tests and real declared query route.
This audit deliberately does not claim that window or those tests occurred.

## Retained Evidence Identities

Paths are repository-relative observation locators; hashes bind inspected bytes,
not an instruction to keep caches forever or regenerate a native result.

| Observation | SHA-256 |
| --- | --- |
| `.cache/tasks/repair-9-12/lifecycle-join-recovery-1/run/receipt.json` | `266ac688e904c0de81cc19607c73c97752f446c2184249e5146621aac17efe2d` |
| `.cache/tasks/repair-9-12/lifecycle-join-recovery-2/run/receipt.json` | `a74fd2f9bd6157cb88b20fbe5900a5502bfd57cd11d652966601fff1c4a5cee4` |
| `.cache/tasks/repair-9-12/lifecycle-join-recovery-2/receipt.json` | `d9a90c3da3ff126ca96522c6281997d460bb1c61c9f5fa6a670b8b85dd162d18` |
| `.cache/tasks/repair-9-12/lifecycle-join-recovery-2/run/join-probe/fixture.scm` | `7fe040f3fab655300dffdb6716eb491642965da3305e9117585a62a5938badef` |
| Current `models/gambit/native/lifecycle_join_recovery_probe.scm` | `0e16af0360768a7b4204977db612f5ad13d9e950ee84cb2e2aebd9ce7e2a10d4` |
| `.cache/tasks/repair-9-12/numeric-restored-2/receipt.json` | `b52c7ce78e510a9667bef6e3c4e16a4428809a0a3191f18164f5414df64d2240` |
| Pending archived `report.md` | `ce40e53188a1a45ec8b41df0c19156a54ac3f514de8f8d7018f9abdedb61e54c` |
| Alias archived `report.md` | `53c788ec4ae75dd7eeb23c7d097d3e07b1c0918e52b177ab3d0eb1330bb35bb3` |
| Freeze archived `report.md` | `fcc33b2d17efe7cc88fd3ad714ee05780fdd23ab38e400a596f3fa3635617cc4` |
| Auditor `recovery-clues-current.json` | `69572b02a569bbd14481885915ce59f885d3f8b3b9611f30cc5da536fb07f0ab` |
| Pending attempt 0007 `receipt.json` | `22c4745e409822f9251acebbe900b23484578a104493f8fe174c1c4ad78d3657` |
| Alias attempt 0006 `receipt.json` | `06c588b2171d83a8889fe9dfdb045aca59189dcbf0a8e58fe9422e5105c5bafc` |

Report/attempt locators are under
`.cache/tasks/repair-9-12/agents/{pending-repair,alias-repair,gerbil-freeze}/archive-20261020/`;
the auditor projection is under `agents/codex/audit-20261020/` in the same task.
No raw private stream or debugger memory scene is published here.

## Inspection Method And Limits

Existing `jq` projected receipt fields and selected `tool_call` metadata; SQLite
was opened with `-readonly`. No new Python extraction script, database or schema
was added. Paths in receipt input maps are absolute: comparisons first verified
the declared keys were present, then compared their actual SHA values. A first
relative-key projection returned nulls and was rejected before the matched-input
finding; null equality was not accepted as evidence. An initial SQLite query
used identifier quotes for JSON paths and failed; the corrected read used string
quotes. These were audit-command errors, not native failures.

Static framework observations at this audit bind `grok_session.py`
`ae26f9529aa047a3b3ecdab82d1ae5dc99ae058cd3de5f537bae613dc22a09d0`,
`trajectory_exploration.py`
`6d1a9fdfa5f328ed1b64ab93328f247bf2867b742f95df42a910363d0ca47148`,
`task_retention.py`
`104e69f6713cad4b36ac6bf0c180a53fe34e7bf142ebcf70fb23140c78cac8af`,
`workspace.py`
`8495e29e2b252ec3a6dc83695405e0e7ffb23d5426e8d552f66d087f0bf5c656`,
and `evidence/views.json`
`62d72d1185c0d01f0b7d5e7bd0aea8f0b4162ef12a9af1931123e5f2efecb3d9`.
All five hashes were rechecked unchanged after the three public API reads.
Concurrent future changes require rechecking the affected finding; these are
not a frozen whole-framework identity or a test pass.
