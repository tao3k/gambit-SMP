# Python task lifecycle and storage contract

## One interface, one owner

Use `gambit-smp --task TASK COMMAND`. Direct adapter modules and imported
`main()` calls delegate to this same dispatcher; they are not alternate execution
policies. Standalone helpers are grouped under `gambit-smp --task TASK tool NAME`;
implementation filenames do not add public command families. Help is read-only. Execution requires an explicit task or the adopted
checkout's default task. The public clue/query functions remain read interfaces,
not authority to launch actions.

Codex's `workspace run` and Grok's `agent` adapter use the same execution scope,
exclusive task lease, durable attempt journal, process observations, reconciliation,
completion and cleanup functions. Provider configuration remains adapter-specific.
Grok stays on `grok-4.7` with `high`; changing this interface does not authorize
restarting a stopped worker.

`trajectory clues` and `trajectory catalog` declare their read policy in their
existing argument parser. They validate sources and persist read hints without
taking execution custody or triggering global retention. Other operations keep
their task policy; a read does not authorize native execution.

The Grok launch receipt's `evidenceRead` advertises one literal CLI command and
an owner-local `query.ss` request file to create; it is not an existing input
catalog. Writing inert Scheme requests to that
file and using the exact advertised command does not require editing `work.py`.
The command uses the existing stdin interface, not another endpoint or a broad
Python permission. `Launch.query_request` configures the basename or disables
this grant with `None`; sealed native-program grants remain independent. It
does not preload evidence or investigation steps into the model prompt.
The same literal interface descriptor is also exposed with the provider's
existing `--rules` mechanism. It contains only the CLI, caller-authored request
path and help command, not evidence, query factors or an investigation order.
It also names the already-granted writable owner directory; an external scratch
path does not gain permission merely because it is temporary.
The descriptor distinguishes stdout delivery from file edits: read-command
permission does not include shell output writes or mixed command chains. Owner
write permission belongs to the edit tools, not an extra shell grant.
`Launch.read_window_bytes` supplies the existing read CLI's complete UTF-8
carrier capacity (the Library's default when unspecified). It is recorded as
`evidenceRead.wireBytes` and inherited through `GAMBIT_SMP_CLUE_WIRE_BYTES`.
The native renderer folds before delivery; query scope is not narrowed. Match
this configuration to the actual recipient and inspect `terminalDeliveries`
for post-render truncation rather than treating end-turn as delivery evidence.
`grok-runs/` remains host-owned read-only history, not writable Agent scratch.
Receipt discovery is therefore not a prerequisite for using the granted read.
The documented public Python help expression is a literal introspection grant;
directory inspection uses the provider's existing read-only `list_dir` tool.
Neither grants arbitrary Python, scripts or native execution.
The provider matches parsed argument words without shell quotes. The fixed
Python help grant uses an escaped whole-command glob, so a longer Python
payload cannot inherit a prefix approval. See the provider's
[rule matching contract](https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-pager/docs/user-guide/22-permissions-and-safety.md#bash-rules).
`Launch.query_root` can bind a data-only replay below the workspace through
the existing CLI `--root`. Execution custody, working directory and owner output
remain unchanged; only root-bound read/help aliases are granted for that replay.
It rejects external paths and symlink aliases. A source-evidence fixture is not
another runtime checkout, installation or native acceptance result.

The executed command retains stdin redirection; the Bash permission names only
the normalized executable and argument words. Grok's `run_terminal_cmd` tool ID
is distinct from the `run_terminal_command` event name. This permits the existing
read endpoint, not generic Python or compound shell discovery commands.

| Location | Role |
| --- | --- |
| `.data/worktrees/TASK` | At most one explicit Git-managed source checkout |
| `.cache/tasks/TASK/programs` | Sealed task programs; no provider/date top-level folders |
| `.cache/tasks/TASK/runs/RUN` | Attempt outputs, including negative/failed attempts |
| `.cache/tasks/TASK/agents/OWNER` | Provider prompts and private streams |
| `.state/` | Durable ownership, pending requests, process/session journals and custody archives |
| `evidence/` | Explicitly published source-bound evidence |

A root `campaigns/` directory is forbidden. The framework validates writes before
OS mutation, including a package-import guard for that reserved root and active
scope guards for unregistered outputs, aliases, parent traversal and another
task's cache. `runtime_output` is the output allocator. `cache_path` is a shared
input/store locator, not an output allocation escape hatch. Arbitrary native
programs still require their existing supervisors and source leases; Python
policy is not OS containment.

## Work items and reusable processes

A task is a maintained work item, not a provider, date, test invocation or audit
role. `docs/work-items.json` admits one task root per unique scope. The existing
combined `repair-9-12` owner remains intact; future independent issue 9 or issue
10 work would have separate registered scopes. `host-root-research` retains its
separate host-root publication research scope. An unconfigured checkout may
bootstrap one work item; additional concurrent items require an explicit plan.
Admission is serialized across task names to prevent bootstrap races.

Audit, validation and evidence reuse registered maintenance roles under that item:

```sh
gambit-smp workspace process-run repair-9-12 audit -- <literal-command> <args>
gambit-smp --task repair-9-12 --process evidence tool <name> <args>
gambit-smp workspace process-resume repair-9-12 audit
gambit-smp workspace process-gc repair-9-12 audit
```

The process owns `.cache/tasks/TASK/processes/ROLE/runs/RUN`, an actual exclusive
FD lease and separate durable attempt/child records. It can run beside the native
owner without borrowing its lock. Its Python writes cannot alter sibling/native
checkpoint output areas. Both providers use the same mechanism. Run IDs identify
attempts beneath a bounded role; they never create top-level task roots.

Parent completion checks every process lease and real child observation. A killed
process supervisor requires explicit reconciliation after actual quiescence;
interruption remains interruption. Startup, normal return and global collection
apply the same two-calendar-day output cutoff. Protected, occupied or uncertain
outputs remain deferred. `absorb-process` relocates a naturally closed role-task
as exact-byte history, with inode-checked resumable custody and the original
closure deadline; it installs no legacy runtime alias.

## Native Product Reuse And Duplicate Retirement

Native source/runtime trees belong to maintained build products, not attempt
folders. New runtime-import and completed-runtime Recipes require `in-place`
storage. The materializer can project an imported generation's authenticated
source from that same runtime; it does not first unpack another source tree.
The archive-bound original workspace location, full recorded runtime inventory,
source/configuration inputs, host tools and exclusive lease must all validate.
An existing but changed producer is a drift observation, not permission to
silently import a duplicate or bootstrap again.

The same `runtime-artifact-input.v1` descriptor can point to a committed
`run/STEP.observation.json` instead of a tar archive. This route requires the
explicit original `producerEngine` seal. It verifies the immutable journal
ancestry, complete support witnesses, current source/tool/configuration bytes,
and the existing Scheme checkpoint's `consumable` relation. Process quiescence
must be observed even if the outer receipt was interrupted. Only a completed
`gambit.source-core` phase is accepted; a seed, missing final binary, changed
producer or unknown process state cannot trigger a copy or rebuild fallback.
The exclusive lease retains the exact producer directory. The descriptor's
checkpoint digest is not reported as an archive digest.

Later test failures and missing aggregate receipts remain visible in the
producer checkpoint. Consuming this phase does not reconstruct a parent PASS,
claim a two-pass bootstrap, authorize a retry or admit native correctness.
Run-specific descriptors and observation logs are local research inputs/results,
not portable evidence to publish as if their cache paths were reproducible.

Pure Quint/Evidence capability graphs bind their declared model and DSL inputs;
they do not require materializing a Gambit source tree. Adding a native or source
build capability restores the locked native producer requirement.

In progress mode, completed review requests enter an owner-close phase with the
already-declared `overheadSeconds` window. Recipe input/output validation does
not spend the former review deadline twice. An unfinished or timed-out request
does not receive this fresh window. A stalled owner is still killed and reaped;
no native stage budget, original failure or performance decision is changed.

When the producer workspace is genuinely unavailable (for example on a different
CI host), install its archived generation once in the task build store. The
retained import key follows runtime contents and compiler configuration, not
archive envelope or log identity. This is byte reuse, not a new native PASS.
`runtime_storage_observation` exposes the step, mode, source content identity
and copied-file count to the existing Scheme review; it grants no milestone.

The existing `gambit.executable-test` capability also supports `mode: "gsi"` for
a declared standalone interpreted fixture (`gsc` remains the default). It uses
the same leased interpreter with a task-owned output cwd and copies only the
bound fixture, not the runtime or test tree. Host-derived topology, exact
completion output, runtime/source identity and watchdog checks remain unchanged.
Its receipt explicitly reports that compilation did not run. Source programs
remain maintained inputs; measurement data remains cache output. A current
consumer engine must contain this adapter; an old immutable engine is never
rewritten or treated as though it included a later framework fix. Sealing that
consumer is not recompiling or bootstrapping the Gambit producer.

Task/process attempt paths cannot hide complete source copies behind `fixtures`
or `runs`. Incremental materialization may use a disposable staging delta which
is consumed by the existing build synchronizer; that is not another runtime.

The existing `fixture-storage` tool accepts an artifact-backed declaration via
`--discard-bindings`. Before retiring explicitly selected old trees, it validates
the retained archive's actual bytes and the duplicate file hashes. Only bytes
reconstructible from that archive are discarded; logs, receipts and unmatched
bytes are archived outside the selected trees. Active files, nested Git and
occupied workspace leases remain protected. Maintenance may retire those checked
fixture paths without acquiring general write authority over the native owner or
its build products. Historical receipt paths are not rewritten into fresh PASSes.

## Lifecycle

```sh
gambit-smp workspace start repair-9-12 --adopt
# New isolated work instead uses: workspace start TASK --ref REF
gambit-smp --task repair-9-12 verify --out .cache/checks
gambit-smp workspace run --provider codex repair-9-12 -- <literal-command> <args>
gambit-smp workspace migrate-script repair-9-12 .cache/owned-source.py --enable
gambit-smp workspace scripts repair-9-12
gambit-smp workspace run-script repair-9-12 <sealed-program-key>
gambit-smp workspace resume repair-9-12
gambit-smp workspace finish repair-9-12
gambit-smp workspace gc repair-9-12
gambit-smp workspace remove-worktree repair-9-12 --merged-into <integration-ref>
```

Source migration removes the old executable file. Programs use the normal output
allocator and validate their sealed bytes and current lease before their body
executes. Original and relocated program bytes are archived for custody; there
is no forwarding stub or runtime legacy-source translator. Prepared migration
can resume only against the original inode/hash and the sealed new bytes.

A new execution records custody protocol 3. Children validate the current task,
run and actual held lock descriptor, not an environment boolean. Provider tools
that close inherited descriptors obtain the same open file description through
a private authenticated Unix socket and `SCM_RIGHTS`. Both provider paths have
real local-process controls for this transfer. Platforms/sandboxes prohibiting
local IPC cannot use that handoff route; it fails closed. Ordinary descriptor-
inheriting commands do not need a socket. In-flight older executions are observed
in place rather than restarted or retrofitted.

Pipe owners and synchronous adapter commands share the custody/process journal;
command transport bytes remain sealed without making the lazy operator registry a
research-kernel import. Direct historical-producer imports still fail closed.
Framework subprocesses propagate actual lease custody even through restricted
host environments and retain process-group observations. A killed supervisor
cannot authorize a new attempt while a child holds the lock or a recorded group
still exists. `resume` observes real quiescence, pending SQL requests, quarantine
and dependency identities; it records interruption/reconciliation without changing
it into success or replaying the action. Unresolved spawn journals remain denied.
Repeated reconciliation does not refresh an attempt's retention deadline.
Provider resume additionally requires a session ID bound to that task, owner and
authorization. CLI end-turn or process exit is not native restoration.

Worktree creation does not install Python/native dependencies. A framework module
from another checkout is rejected until the environment is bound. Source-file
observations, local tests, full graph qualification and native acceptance remain
separate. Validation fixtures run with isolated task environment while their
actual parent lease stays held; test code must not borrow production task state.

## Two-calendar-day retention

Use Asia/Shanghai dates: on October 20 retain October 19–20. Startup, finalization
and explicit `workspace gc` use the same collectors. Completed attempts and
actually reconciled interruptions can expire even while the task remains open.
Attempt outcomes and archived custody bytes survive outside cache.

The former blanket pin of every old cache/data entry was removed. Existing
outputs carry `retained-output` ownership and the same two-day policy. Explicit
recovery inputs and shared/source stores have separate pins with reasons.
Quarantine, pending requests, live descriptors/groups, recent descendants,
unknown databases and nested Git prevent deletion. Every sweep records its
cutoff and per-path decisions in `.state/storage/retention-TASK.json`.

Some historical databases are test scheduler queues. They may expire only after
the known validation producer's receipt/child/log hashes and exact queue schema,
ordinal inventory and test IDs are checked. Cleanup takes real SQLite writer
locks and archives a consistent queue snapshot, including unclaimed test jobs.
Expired test jobs are not completed, replayed or confused with native requests.
Unknown stores remain protected. Unique/dirty/unmerged Git sources require their
separate Git-flow decision, never an age-based forced removal.

Deletion records the original inode, metadata inventory and exact custody records
before mutation. A real process interruption can resume removal of the unchanged
remainder; replaced files, newly introduced entries (even backdated ones), active
writers or changed archives are rejected. Historical JSON custody is indexed by
original path and exact SHA, so cache removal is not a fresh empty journal or a
fabricated restoration. Large private streams expire with the artifacts.

## Audit history

The initial purge removed 1,759 legacy entries. Its receipts and the intermediate
50-script relocation result remain historical records; the rejected root
`campaigns/` layout was subsequently removed. See
`evidence/review/storage-lifecycle-20261020/audit.json`, `followup.json`, and the
corrective audit in Current Work. None admits native pending-join restoration or
native/Gerbil build/test completion.

## Cache-only generation and incremental build work areas

Generated `pro`, profiles, prompts, policy/policies, private and provider-source
subtrees are rejected before Python filesystem mutation beneath `src`, `vendor`,
provider/provide/VR and `.venv` source areas, including case and resolved aliases.
Editing ordinary source files remains allowed. Engine seal API calls now validate
in-repository destinations through the same allocator as the CLI, before provider
inventory or directory creation. Explicit external export/test destinations keep
their existing contract. Python policy does not contain arbitrary native commands.

During supervised execution both providers receive the same Cache-local
`PYTHONPYCACHEPREFIX`, `UV_CACHE_DIR` and `XDG_CACHE_HOME`, under `.cache/tools`.
The current Python interpreter uses the same bytecode prefix; the previous process
settings are restored when the scope exits. This changes no running owner's env.

Build adapters can allocate stable work areas with the existing workspace API:

```python
from gambit_smp.workspace import build_output
build = build_output(root, "gambit-core", compiler=selected_compiler,
                     flags=literal_configure_and_compiler_flags)
```

The call requires actual current task/process FD custody. The location is
`.cache/tasks/TASK/build/NAME/CONFIG`, or the corresponding process-local build
area. `CONFIG` binds the selected compiler path/bytes, explicit flags and relevant
inherited compiler/linker environment. Provider/run IDs do not change it. Exact
configuration bytes are checked rather than rewritten on a warm lookup, preserving
their mtime. Source edits remain in the same work area so the native build tool
can invalidate only affected targets. A flag/compiler namespace change provides
an empty build area. Transitive tools, dependencies and source correctness still
require their existing Recipe/toolchain declarations and native checks; this
allocator supplies storage identity, not artifact/result admission.

Adapters must still invoke their real build tool and bind current source inputs;
cache existence is never success. Existing explicit in-place Recipe workspaces
and live 9–12 checkpoints remain under their current custody and paths. Logs and
receipts use attempt directories. Idle build payloads use the same two-day
cutoff and owner/child/reference checks as attempts, with JSON custody archived
before deletion and inode/inventory checks on interrupted cleanup. Operational
DBs and Git source remain protected by their existing release conditions.

## Build starts must carry their existing execution lineage

The research runner's immutable header transaction also arbitrates expensive
native build starts. Within one task (including all maintenance roles), another
attempt of the same Recipe requires the latest matching `--prior`, even when
the source lock changes. Changing output directories, provider, display/step
names, engine seal or budgets cannot silently create an independent build.
Renamed Recipes with the same source/configuration dependency graph are also
matched. Source input bytes, literal configuration and producer dependencies
define that graph; attempt names and budgets do not.

Arbitration reads existing authenticated execution headers inside the same
SQLite `BEGIN IMMEDIATE` as the new checkpoint insertion. It needs no new state
database or directory catalog. It includes old headers and survives Cache
deletion and supervisor death. Only one competing fresh start commits. A refused
header cannot launch the sealed runner or a compiler. An accepted prior edge
still requires the existing runner's real source/tool, budget, process and
checkpoint checks; the edge itself never reports a successful restoration.

This gate prevents omitted lineage; it does not automatically make an isolated
Recipe incremental. Repeated source revisions must use the existing explicit
in-place workspace/state or a validated seed/completed producer when applicable.
Build adapters must preserve one owned source/build area per build product and
configuration, run the actual dependency-aware build tool, and retain separate
attempt logs. Unavailable or invalid artifacts remain missing/invalid rather
than becoming a cache hit. Existing sealed programs and active owners are not
rewritten in place. Arbitrary shell commands outside the Python supervisor are
not contained by this Python guard.

## Native and Gerbil Recipes use the managed build products

New research execution and the Python Recipe runner (including v1) require `workspacePolicy: in-place` and
`gambit.materialize(buildWorkspace: gambit-core)` before configuration. Explicit
legacy fixture paths do not satisfy this rule. This check is in both execution
paths, independent of Codex/Grok; historical reads remain available. A previously
sealed, running engine is not rewritten. Repair 9–12 declares only `gambit-core`
and `gerbil` as build products in `docs/work-items.json`.

The maintained CI Recipe and the authored successors in
`evidence/research/incremental-builds/` select these products. Their migration
declaration binds the original Recipe bytes and an allowed successor. A real
`--prior` carries expenditure and lineage through the existing checkpoint path;
the migration authorizes no restored stages, process recovery or native result.
It never redirects a legacy launcher. If no verified managed build exists, the
first managed build is cold; this migration does not import an old isolated
runtime merely because its directory exists.

The adapters materialize pinned Git inputs into the leased source root. Cold
unpublished Cache staging can be consumed without copying every source byte a
second time, while preserving the leased root inode. Warm runs archive only the
old/new overlay paths, retain the complete source inventory, and update changed
source bytes with fresh timestamps. The pending delta is durable before mutation;
only its recorded old/new bytes can continue after interruption. Generated build
outputs survive. Unknown source drift is refused. Configure/bootstrap inputs,
compiler/backend/tool bytes, flags and relevant environment define configuration
namespaces; ordinary C or stdlib edits remain in the same namespace.

Configure reuse requires the actual completed process receipt and exact generated
configuration files, followed by the real effective-concurrency macro probe.
Gambit source regeneration retains its actual bootclean receipt/log, bootstrap
compiler bytes and generated-source inventory. Continuation still invokes the
real `make core`; a state flag cannot replace it. Gerbil installs the verified
same-producer Gambit payload and invokes the pinned upstream `src/build.sh`
stages. Completed bootstrap stages require exact outputs, dependencies and real
quiescent process receipts; dependency-aware downstream builders still execute.
The adapter avoids upstream prepare's directory deletion and its unconditional
second Gambit bootstrap/from-scratch build.

Workspace locks are passed as actual duplicated file descriptors through the
framework, process observation and Python helpers. Killing a controller does not
release the source to a new caller while a native consumer still holds its lock,
even in the same long-lived worker/run. Across runs, prior task/process custody
and actual child-group quiescence must also reconcile. Test fixture isolation
clears inherited workspace metadata rather than borrowing production leases.

Attempt receipts stay separate from the stable build directories. Existing
owner/child/reference protection and two-calendar-day retention apply to these
products; this work does not purge active 9–12 or operational Git/database
payloads. Python enforces its supervised entry points, not arbitrary shell
commands outside the framework. Local transport/compiler fixtures, full upstream
native qualification and full Gerbil qualification remain separate evidence.

Completed native artifacts may cross an executor generation only through an
explicit `producerEngine` pin. The importer authenticates the original seal,
archive manifest, all original producer source/tool inputs, raw completed and
quiescent command receipts, and the complete payload byte/mode/link inventory.
It does not execute the old Python generation or restore an interrupted stage.
Recipe prefix reuse additionally requires the same authenticated executor; old
history and expenditure remain when execution stages must rerun.

Archive installation uses a supervised native tar process after complete member
and internal-link validation, including rejection of symlink ancestors regardless
of member order. Git source extraction retains the prior data-filter mode
semantics with a fixed child-only umask; native runtime installation preserves
original modes and timestamps. Initial pending transfer is durable before the
first write. Warm imports reuse the existing product and verify retained payloads
without copying them again. Process-group observation uses the existing bounded
probe; an unknown observation cannot authorize advancement.

Held workspace validation reuses the current full inventory for ordinary source
entries, with root inode/stat checks and full byte verification at release.
Aliases still require containment resolution. Reviews of added test fixtures copy
only tests, retaining the leased native runtime. Their campaign identity combines
all actual native entries with the complete prospective unit-test tree; it must
match the real execution tree. Additional fixtures never replace upstream inputs:
repeat installation requires durable transfer custody and identical declared and
installed bytes. Source synchronization retains regeneration and fixture-transfer
custody without turning either record into command or test success.

Gerbil stage0 recovery is per compiled module. An actual GSC invocation must exit
successfully with a reaped parent and quiescent group, unchanged input bytes, and
an exact output byte/mode inventory. Its completion is committed to the existing
execution checkpoint before updating the mutable module index. Consumption checks
that immutable observation; rewriting the mutable receipt plus its hash causes
real recompilation. Unproved partial objects are overwritten only by a new real
compiler invocation. The complete module set is required before stage0 closes.
The compiler processor count is measured, and bootstrap uses one compiler worker.
Input-copy plans precede writes and preserve unchanged timestamps.

Official Make tests inherit the same processor population as their current
producer's environment observation, and measure it before execution. A typed
target-specific processor declaration is limited to independent non-unit leaf
targets; a generated Make variable binding changes neither source recipes nor
heap flags. It cannot narrow unit suites or dependency closures. A current source
contract and exact upstream file-frame protocol bind real per-file watchdogs.
Those watchdogs never renew the enclosing wall deadline, and missing/unfinished
required intervals cannot pass.

### Source identity custody instead of Evidence source copies

The existing `view-materialize` entry uses `ascent.source-binding-review.v2`.
Each reviewed change names `before` and `after` immutable identities, affected
citation IDs, its reason, and its retained scope. A committed source identity
pins the exact repository, full commit, path, Git blob, and SHA-256. Dirty or
historical bytes use the existing task execution checkpoint journal through
`retain_run_record`; the reader authenticates the complete checkpoint prefix
and payload bytes. No new task owner, database, or recovery protocol is created.
The transient JSON transport remains in the owned task output tree and follows
its existing two-day retention. Expiring that transport does not delete the
committed journal observation. A missing journal or Git object is a hard error;
local checkpoint references alone are not portable Git publication evidence.

Normal review and imported-source generation no longer write baseline sources
or replay patches under `evidence/`. Legacy v1 requests are rejected. The
existing entry exposes `--migrate-source-storage --out .cache/OUTPUT` for the
one-way migration: retain original records and bytes, publish an authenticated
resumable plan, migrate authored references, regenerate maintained views with
the real producer, and only then remove the redundant copies. The migration
retains original receipts in the checkpoint and marks transformed historical
records explicitly; it does not recalculate their old success claims. Interrupted
publication resumes that exact plan and rejects concurrent author edits.

Views may carry an explicit immutable `identity` alongside their source label
and expected SHA-256. The reader verifies that identity directly, including byte
projections and JSON pointers, rather than treating the label as a current file.
This preserves the exact cited revision while another worker edits its working
copy. Changed current source still requires an explicit new review. Producer
bindings also cover the source identity and Evidence reader implementations.

Source capture granularity is one content identity per existing checkpoint
record. Equal bytes share the capture identity; reading a small source never
requires authenticating an unrelated bulk migration payload. Older compound
records remain historical journal inputs. The existing migration maintenance
action can rebind maintained references to small records without changing any
source-byte digest, retaining the prior declaration and rebind observation in
the same journal, then rerunning the real producer.

### Child-owned birth and exec barrier

The remaining Git helpers, patch validation/application and cleanup `lsof`
inventory use `task_processes.run`, so an active task records their real child
births as well. The only raw `Popen` call is the internal transport boundary.
Unscoped bootstrap and read-only subprocess adapters remain nondurable; they
do not acquire task recovery or completion authority.

The existing Python audit hook rejects direct `subprocess.Popen` (including
aliases and synchronous/async wrappers), shell/system, fork, posix-spawn and
direct exec while the managed storage scope is active. The transport releases
its narrow Popen permission only around its launcher creation; target exec
permission is released after the actual child birth and exec request checks.
These transient call permissions do not establish recovery, successful exit,
or native admission. Kernel birth, descriptor custody and actual group exit
remain mandatory. This is a framework entry policy, not a sandbox for arbitrary
provider/native programs that do not import the framework.

Task program migration rewrites subprocess calls in the source itself, including
import aliases and `call`/`check_call` return conventions. `run-script` completes
this migration under its existing work-item execution scope before launching a
registered old program. Bulk migration requires exclusive work-item custody;
an active task is never unlocked or stopped to make it succeed. The prepared
record binds original and rewritten bytes through existing task checkpoints.
Replacement is fsynced and can resume from either exact byte generation after
interruption. Prepared or unmigrated direct script entries cannot execute.
Disabled programs remain disabled, and no compatibility loader is installed.

New research seals declare the child process protocol. Execution also compares
the sealed transport file hashes with the current transport implementation;
adding a protocol label cannot admit old subprocess code. Old seals/checkpoints
remain inspectable. An incompatible interrupted continuation is not silently
replayed under a different seal.

Managed task launches, Codex/Grok provider launches, fixed/progress observations,
and sealed research recorders share `spawn_protocol.launch`. The durable owner
supplies the existing task/run output root; there is no additional task,
database, public launcher entry, or compatibility startup script. Pure in-memory
observation callbacks do not become durable owners or gain recovery authority.

The parent acquires a per-token flock and publishes the planned request before
creating the child. The launcher inherits that custody descriptor. It publishes
its own kernel PID, PGID, UID, start identity and boot ID through the existing
atomic/fsynced writer, then waits for a private permission channel. The parent
verifies that actual birth and commits it before releasing permission. The
launcher replaces itself with the target, preserving PID/birth and the existing
task/workspace descriptor inheritance. A `started` record with
`phase=birth-committed-before-exec` is birth evidence, not a completed target or
native recovery result. Exec intent is also not proof of a successful exec.

The launcher interpreter runs with `-I -S -B` and a minimal control environment.
Target site hooks and loader/Python environment inputs cannot execute before
birth. The original target environment travels only through the private pipe
after birth is committed; its digest, not its secret values, is recorded.
EOF or an incomplete transfer cancels before target execution. A close-on-exec
status pipe preserves actual executable errors. Fixed execution deadlines include
this handshake; it has no independent extension to the original program budget.

Recovery first reacquires real custody. It distinguishes no committed birth,
birth without exec intent, and an exited target whose execution outcome remains
unclaimed. A live consumer, matching kernel birth, or non-quiescent group blocks
recovery. Actual quiescence observations are retained in the existing process
journal; private request/permission files reside in task/run Cache and follow
its two-day lifecycle. Last-consumer custody is checked even after the parent
has recorded a finished/interrupted child. A reused numeric PID alone cannot
identify an old process.

An old unbound spawn lacking this protocol remains blocked by default. The
existing `workspace process-resume` entry accepts a narrow forensic
`--discard-metadata-read TOKEN --argv-file ROOT_RELATIVE_JSON` action only for
an exact Git `--no-optional-locks … rev-parse --verify FULL_COMMIT^{commit}` argv
whose hash matches the original journal and whose same owner/generation is
interrupted. It verifies producer exit/reap, kernel parent identities, original
group absence and two current-UID birth censuses. It retains the original bytes
and full observations. The result explicitly preserves unknown historical
execution, discards outputs, and forbids replay/native admission. Arbitrary
commands and native builds have no force-clear route.

### Live Execution Inspection

Use the existing `research --read RUN` while the original execution is active.
The committed checkpoint supplies process births, stage locations and completed
work samples; the host observes group presence and boot identity without running
another test. The registered checkpoint Scheme fragment derives
`execution_pending`, `execution_frontier`, `execution_unattributed` and
`execution_detached`. Its same rules can be composed into a downstream Clue
projection, without a Python state machine or a new command family.

`executionObservation` links the compact latest scoped progress to its immutable
observation and preserves missing witnesses. Relation timestamps use integral
monotonic nanoseconds; original receipt timestamps are unchanged. Cross-boot or
permission-denied liveness is unknown. Older births without a complete kernel
identity are explicitly `present-unattributed`, not authenticated live owners.
The task-run owner record is a separately hashed observation: `returned` does not
prove an AI session completed, nor that its native descendants stopped.

The pinned suite runner's completed count is good plus failed. New collector
records preserve the reported split; old records with no split remain unknown.
Neither these observations nor a Clue checkpoint establish native PASS, deadlock,
execution permission, or a new milestone. Counter replay cannot renew the
existing no-progress watchdog. `ResearchFunnel` and its Lean companion exercise
this boundary; they are not a refinement proof of the native runtime.

New runtime imports preflight their declared Make consumers through the existing
source-bound scope contract and Scheme scope inference before downstream native
compilation. This checks header/mode/dependency compatibility only, without Make,
fixture copying or test execution. Fixture inventory and retry/native admission
are still checked by their actual consumers. Active frozen executors retain
their original implementation; no running Recipe or receipt is rewritten.

Seal-byte `CURRENT` and current launch compatibility are distinct observations.
The same inspector exposes Scheme-derived `transportCompatibility` gaps.
Requiring a current framework consumer does not invalidate the bound native
producer, require bootstrap, or authorize a failed native route to be retried.

The provider-owner rule is enforced at the Python API as well as the CLI:
maintenance roles cannot start an interactive Codex/Grok session through an
alternate workspace-execute call. They can still run bounded tools with either
provider tag. The real model session belongs to the existing work-item owner.
Request preparation and all descriptor creation are covered by failure cleanup;
request I/O errors retain errno, genuine exec errors retain OSError, and an
expired absolute deadline cannot release exec permission.

### Investigation Continuity

The existing `trajectory submit` also accepts a Scheme request over stdin, using
`selector` and optional `constructor`. The declaration returns
`clue(id,claim,polarity,source)` and `factor(id,name,value)` through the native
ASCENT frontend. Python transports those rows into the existing CAS hypothesis
journal; it does not parse Scheme, infer a cause, or turn an Agent statement
into an observation. Hypothesis submission has its own journal effect, not
native execution custody: its CAS can append while the task's execution lease
is occupied. It cannot mutate the producer, close a gate, or authorize execution.
Arbitrary conditions, counterevidence and open
references are caller-authored factors, not a prescribed investigation sequence.

Task-addressed `trajectory clues` reads include that journal. The read checkpoint
retains its journal address across processes, while source provenance remains
on the immutable submission. A changed repository identity does not erase an
older conclusion or make it current; it remains a hypothesis with its original
input identity. Clearing read hints does not delete the durable journal. A fresh
read and a different investigation scope remain permitted.

`modeling-guidance` exposes declared `signal` facts through the same Clue exchange
when `signal_witness(id,focus,obligation,kind,source)` binds their atomic identity.
Conflicting identities do not become conjunction matches. A current focus and
source are required; these signals neither prescribe actions nor establish a
native cause. Raw reported repetition is not proof of wasted reasoning.

The existing work-item `agent` registration declares project-relative read/edit
patterns and dispatcher command names. The launch adapter derives grants from
that one declaration and records its identity; it does not keep a hand-extended
terminal whitelist per continuation. Framework/native admission and the external
service's permission review remain independent. Registered source-byte reviews
explain execution adapters without duplicating their validators or interpreting
Python source as a second contract language.

An explicit same-session Agent resume authenticates its owner/session binding
before using the existing workspace reconciler. Live leases, processes and
pending requests still prevent reconciliation. Directory identity changes are
recorded as custody observations, not rewritten into the dependency registry:
resuming an investigation does not admit those bytes for reuse. Consumers still
validate their source/artifact contracts; strict dependency access and retention
release still reject replacements. Interrupted provider receipts remain history.

Source delta export uses the existing `materialize-source --export-candidate`
entry. Optional `--overlay` composes a patch against an explicit `--file`
inventory in disposable file slices, then replays the cumulative output against
the pinned upstream revision. It neither copies a source tree nor mutates a
producer; output digests come from actual bytes, not placeholder hashes. This
is source reproduction only, not native repair or generated-C admission.

When an outer receipt is missing, the existing checkpoint rules distinguish
incomplete execution from `failed_attempt_history`: every declared step has a
verified journal record, at least one failed, and process quiescence is observed.
The latter may support a fresh changed-input attempt on a current consumer with
the same recipe/capability graph and unchanged watchdog/phase budget contract.
It does not resume the old engine's steps or create the missing parent receipt.
The original committed prefix is retained as accounting-only provenance; all
current source/artifact admission checks still apply. Live, successful and
partially recorded executions remain under the exact continuation contract.

Build-product registration may declare `recoveryLinks`, mapping generated alias
paths to exact relative targets. During recovery of a leased `building` workspace,
only matching internal dangling aliases that are absent from both old and new
source-input inventories can be retired. Source identity/custody checks precede
the durable removal plan. The normal update checkpoint records that plan before
unlinking and completes it after an interruption. Real files, resolved links,
unregistered links, source inputs and external targets are not cleaned by this
rule. Publication and runtime consumption retain strict artifact-tree checks.
