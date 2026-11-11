# Project Interface

Use the single `gambit-smp` dispatcher and one stable task ID across Codex/Grok: `gambit-smp --task TASK COMMAND`
or the `workspace` supervisor. Task artifacts belong in `.cache/tasks/TASK/`;
explicit Git worktrees belong in `.data/worktrees/TASK/`.
For changing task ownership or storage, read `docs/task-workspace-lifecycle.md`.
Evidence reads use the installed dispatcher directly; wrappers and startup
resources are not prerequisites.

Evidence, prior failures, provenance and open references are already registered:
`.venv/bin/gambit-smp trajectory clues --help`. No catalog/file discovery or
downstream compilation is needed.

The request is Scheme data: `((bindings (("NAME" "VALUE"))))`. Bindings jointly
match one observation identity, not keywords. The registered Scheme association
derives scope; a caller-written `selector` may use arbitrary Scheme/Datalog.
Python callers use `from gambit_smp import repository_clues` and
`help(repository_clues)`; this is a function, not a submodule.
Empty bindings expose the registered DSL's discovery metadata, not all claims.

Results contain `brief` and `checkpoint`. `(checkpoint "TOKEN")` continues
acknowledged evidence across processes/scopes; omission explicitly requests a
fresh read. `(expand ("CLAIM-OR-REFERENCE"))` opens arbitrary references.
Hypotheses and direction remain caller-owned; reads grant no execution authority.
Cached investigation notes are observations, not new task policy or prohibitions.

`trajectory submit` accepts the same Scheme request envelope. Its selector
declares `clue(id,claim,polarity,source)` and `factor(id,name,value)` to retain
investigation conclusions as hypotheses. The selected task's journal is included
in subsequent Clue reads; its checkpoint carries that journal scope across processes.
Source-bound execution-adapter reviews are registered Evidence, not a second API.
Agent grants come from the work-item registration; generic shell commands are not implied.

Grok launch receipts advertise `evidenceRead`: an exact read command and an
owner-local Scheme request file to create, independent of native-program
permissions. The request is caller-authored data, not a pre-existing catalog.

`research --help` describes durable execution checkpoints and source-bound
Recipes; `research --read RUN` inspects retained stages without rerunning them.
Registered build products accept source deltas under their lease; this replaces
the current build generation without erasing historical receipts. Direct producer
edits are different from managed updates. Build-profile paths are configuration
inputs, not a mechanism for selecting sibling workspaces.
Framework seals (`research --seal`) are not native producers or bootstraps;
their transport bindings and the retained `producerEngine` are separate identities.
`verify --help` describes the existing QNT verifier. Keep historical failures;
cache availability, framework checks and native qualification are separate.
