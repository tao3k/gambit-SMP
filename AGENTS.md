# Project Interface

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

`research --help` describes durable execution checkpoints and source-bound
Recipes; `research --read RUN` inspects retained stages without rerunning them.
`verify --help` describes the existing QNT verifier. Keep historical failures;
cache availability, framework checks and native qualification are separate.
