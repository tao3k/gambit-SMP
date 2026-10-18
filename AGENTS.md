# Evidence Queries

The installed Python framework entrypoint is `.venv/bin/gambit-smp`. Scheme declarations need no downstream compilation.

1. CLI and DSL contract: `.venv/bin/gambit-smp trajectory clues --help`.
2. `trajectory clues '((bindings (("NAME" "VALUE"))))'` queries registered Evidence through the project's Scheme association; no catalog, file or constructor discovery is required. Standard input accepts the same Scheme request.

Bindings are relational anchors, not keywords; all must match one observation ID/digest. The default is declared in `evidence/views.json`, not Python. A request's `selector` may replace it with arbitrary Scheme/Datalog; `(include clue-selection-schema)` supplies source schemas. Python `help(gambit_smp.repository_clues)` describes the full DSL.

The result contains `brief` and `checkpoint`. Put `(checkpoint "TOKEN")` in a continuation request to reuse displayed evidence across processes and changed scopes. Omission requests fresh replay, not automatic continuation. `(expand ("CLAIM-OR-REFERENCE"))` can widen the window arbitrarily; hidden families keep expansion references. No caller-written checkpoint files are needed.

Keep historical failures and their applicability conditions. Evidence informs reasoning; hypotheses, scope and exploration remain caller-owned. A query result grants no execution authority or native-test pass.
