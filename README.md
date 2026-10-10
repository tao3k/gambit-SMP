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
| `tools/model/` | Model admission, source guards, native runner and isolated diagnostics |
| `evidence/` | Datalog rules, generated relationships and portable upstream inventory |
| `docs/` | Architecture, classified report audit, assumptions and validation boundaries |
| `.data/` | Ignored local checker/runtime outputs, never official repair evidence by itself |

## Local Checks

```sh
python3 -m venv .data/venv
.data/venv/bin/python -m pip install -r requirements.txt
.data/venv/bin/python -m unittest discover -s tools/model -p 'test_*.py'
.data/venv/bin/python tools/model/evidence_index.py --check
.data/venv/bin/python tools/model/evidence_index.py --out .data/evidence-query-001
```

Quint checks additionally require Quint 0.33.0, Java and its TLC backend:

```sh
quint --version
python3 tools/model/check_gambit.py --case exec_gc_polling --out .data/exec-poll-001
```

Every checker output directory must be new. Native invocation is opt-in and
requires explicit current source/binary identity; see `models/gambit/README.md`.
Do not use a global installed runtime to validate a build-tree candidate.

## Evidence Is Not Acceptance

Datalog answers coverage and dependency questions. QNT checks bounded behavior.
Neither grants native correctness, artifact parity, full bootstrap, or release
approval. Known failures remain visible until source-backed repairs and exact
toolchain native receipts close them. Historical success reports are not local
reproduction, and missing facts mean unknown rather than safe.

The migrated evidence was captured on 2026-10-10 from the existing Gerbil/Bazel
investigation. The pinned source revision is in `models/gambit/cases.json`.
The current candidate remains unaccepted; no official runtime patch is published.
