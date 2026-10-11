# Gambit SMP Verification

Source-grounded Quint models, frozen counterexamples, native regressions and
an executable Datalog evidence index for Gambit's multiple-VM and parallel-GC
repair work. This repository is not an accepted replacement runtime.

## Layout

| Directory | Responsibility |
| --- | --- |
| `models/gambit/` | Bounded QNT protocols and source/case manifest |
| `models/gambit/counterexamples/` | Actual TLC negative traces bound to model digests |
| `models/gambit/native/` | Real Scheme regression fixtures; not scheduler replay |
| `src/gambit_smp/` | Installed Python framework: shared execution, model/source/native adapters, evidence admission |
| `tests/` | Framework unit and integration tests, separate from native Gambit fixtures |
| `evidence/` | Datalog rules, generated relationships and portable upstream inventory |
| `docs/` | Architecture, classified report audit, assumptions and validation boundaries |
| `.data/` | Ignored local checker/runtime outputs, never official repair evidence by itself |

## Local Checks

```sh
uv sync --locked
uv run --locked python -m unittest discover -s tests
uv run --locked gambit-smp evidence --validate
uv run --locked gambit-smp evidence --out .data/evidence-query-001
```

Quint checks additionally require Quint 0.33.0, Java and its TLC backend:

```sh
quint --version
uv run --locked gambit-smp check --case exec_gc_polling --out .data/exec-poll-001
```

Every checker output directory must be new. Native invocation is opt-in and
requires explicit current source/binary identity; see `models/gambit/README.md`.
Do not use a global installed runtime to validate a build-tree candidate.

Primary-source papers can be downloaded once with
`uv run --locked gambit-smp papers`; later runs check hashes offline.
See `docs/paper-cache.md` for local text search and cache boundaries.

Python and dependencies are declared in `pyproject.toml`, `.python-version`, and
`uv.lock`; CI uses the same locked commands. `gambit-smp --help` lists adapters,
and `gambit-smp COMMAND --help` describes each adapter. A wheel installed outside
the checkout uses `gambit-smp --root PATH COMMAND` to locate research data.
See [the framework guide](docs/python-framework.md) for module boundaries and
historical receipt handling. No executable copies remain under `tools/model`.

`evidence --validate` checks the currently available evidence without modifying
the saved index. Missing local source context remains pending on clean checkouts.
`evidence --check` additionally requires the saved index to match exactly; use
`evidence --refresh` only after reviewing changes to its inputs and facts.

The bounty-era evidence inventory covers 127 PRs and 33 selected exact-head
snapshots, not only PR988. See [coverage and open obligations](docs/bounty-evidence-coverage.md)
for classification, the new publication/stack models, and native evidence limits.

## Evidence Is Not Acceptance

Datalog answers coverage and dependency questions. QNT checks bounded behavior.
Neither grants native correctness, artifact parity, full bootstrap, or release
approval. Known failures remain visible until source-backed repairs and exact
toolchain native receipts close them. Historical success reports are not local
reproduction, and missing facts mean unknown rather than safe.

The migrated evidence was captured on 2026-10-10 from the existing Gerbil/Bazel
investigation. The pinned source revision is in `models/gambit/cases.json`.
The current candidate remains unaccepted; no official runtime patch is published.
