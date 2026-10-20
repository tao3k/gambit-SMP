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

Grok launch receipts advertise `evidenceRead`: an exact read command and an
owner-local Scheme request file to create, independent of native-program
permissions. The request is caller-authored data, not a pre-existing catalog.

`research --help` describes durable execution checkpoints and source-bound
Recipes; `research --read RUN` inspects retained stages without rerunning them.
`verify --help` describes the existing QNT verifier. Keep historical failures;
cache availability, framework checks and native qualification are separate.
