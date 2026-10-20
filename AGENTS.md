# Project Interface

Use the single `gambit-smp` dispatcher and one stable task ID across Codex/Grok: `gambit-smp --task TASK COMMAND`
or the `workspace` supervisor. New worktrees use `.data/worktrees/TASK`; never
create provider/date-specific top-level output directories or root `campaigns/`. For starting,
finishing or reclaiming tasks, read `docs/task-workspace-lifecycle.md`.

Evidence, prior failures, provenance and open references are already registered:
`.venv/bin/gambit-smp trajectory clues --help`. No catalog/file discovery or
downstream compilation is needed.

The request is Scheme data: `((bindings (("NAME" "VALUE"))))`. Bindings jointly
match one observation identity, not keywords. The registered Scheme association
derives scope; a caller-written `selector` may use arbitrary Scheme/Datalog.
Python callers use `from gambit_smp import repository_clues` and
`help(repository_clues)`; this is a function, not a submodule.

Results contain `brief` and `checkpoint`. `(checkpoint "TOKEN")` continues
acknowledged evidence across processes/scopes; omission explicitly requests a
fresh read. `(expand ("CLAIM-OR-REFERENCE"))` opens arbitrary references.
Hypotheses and direction remain caller-owned; reads grant no execution authority.

Grok launch receipts advertise `evidenceRead`: an exact read command and an
owner-local Scheme request file, independent of native-program permissions.

`research --help` describes durable execution checkpoints and source-bound
Recipes; `research --read RUN` inspects retained stages without rerunning them.
`verify --help` describes the existing QNT verifier. Keep historical failures;
cache availability, framework checks and native qualification are separate.
