# Evidence Queries

The installed Python framework entrypoint is `.venv/bin/gambit-smp`. Scheme declarations need no downstream compilation.

1. CLI and DSL contract: `.venv/bin/gambit-smp trajectory clues --help`.
2. `trajectory clues --select 'SCHEME_DECLARATION'` evaluates caller-written Scheme/Datalog over already registered Evidence. Variables discover claims and factors without prior identifiers or file searches. `(include clue-selection-schema)` supplies input schemas; derive `question(claim)` and optional trace relations. Sources are read-only.

The CLI transports the Library's inert Scheme `brief` and `checkpoint` directly. Each invocation starts fresh unless the prior token is passed with `--checkpoint`; changing the selector does not carry read progress implicitly. The same token works across processes and changed scopes. Omitting it intentionally replays evidence. `--expand` accepts arbitrary claims; folded families retain expansion references. No caller-written checkpoint files are needed.

Keep historical failures and their applicability conditions. Evidence informs reasoning; hypotheses, scope and exploration remain caller-owned. A query result grants no execution authority or native-test pass.
