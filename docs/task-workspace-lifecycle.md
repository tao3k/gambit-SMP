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
