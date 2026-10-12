# Recursive Protocol Validation: 2026-10-11

## Identity And Scope

The repository base HEAD was `f752d5279159d46fdb4a2abe1fc6d5545edb887e` with
uncommitted research/framework changes. The recursive QNT snapshot was
`9b54c960822c7e115be910abda133aa22ca04f542c784bede4cba98f5f48a889`.
These are local receipts, not a committed-head CI or accepted runtime release.

The source input is the pinned Gambit submodule and audited source-slice lock.
The current model tracks per-object eager-head ownership, helper-discovered
children, disjoint tail scanning, four processor queues and explicit waits.
Ordered copy-stack and allocation-frontier refinement remain open.

## Results

| Check | Result | Time |
| --- | --- | --- |
| QNT typecheck | Passed | No timing claim |
| Seven independent fault controls | Seven intended counterexamples | 4.618-5.491 seconds each |
| Recursive source policy, normal scheduling | DENY: timeout; other positive not started | 90.012 seconds |
| Same model, final scheduling | DENY: timeout; other positive not started | 90.141 seconds |
| Current checker parity fixture | Six expected safety/temporal verdicts; inputs stable | 21.402 seconds overall |
| Full Python framework profile | 339 tests; zero failures, errors or skips | 11.560 seconds inside runner |
| Supervised full-profile process | Real exit 0, no timeout | 12.556 seconds, original 300-second budget |
| Current ASCENT evidence handoff | CURRENT; 11 reusable component receipts | Runtime execution unauthorized |

The final recursive log reported 2,271,137 distinct states with 469,341 still
queued. This is progress, not a complete positive proof. The seven controls and
the checker fixture do not authorize native execution. The current evidence
handoff leaves the recursive finite-model premise and 22 source/native premises
open; it does not convert framework validation into Gambit acceptance.

The supervised full-profile receipt SHA-256 is
`8d5663a8cd17d302222a826e37f81e0ae2587c645e70e3e45e3d7925074bdf53`.
The successful current checker diagnostic receipt SHA-256 is
`b33dbc238ff532c8e6f871289fa102f07d3dc770a0bca510fe8a10901b752a1a`.
Portable denied-model and diagnostic archives, including compiled checker
inputs and original raw hashes, are under `evidence/model-results/`.

## Reproduction And Next Admission

With the locked Python environment and a provisioned local ASCENT CFFI artifact:

```sh
PYTHONPATH="$LOCAL_ASCENT_API" uv run --locked gambit-smp agent-context \
  --model gc_recursive_queue_wait --profile full --out .data/new-agent-context
GAMBIT_SMP_TLC_JAR="$TLC_JAR" GAMBIT_SMP_PARITY_OUT=.data/new-checker-parity \
  uv run --locked python -m unittest discover -s tests -p integration_quint_backend.py
```

Outputs must be fresh. Recheck an existing identity-bound context before reusing
its validation. The local native ASCENT library is an embedded CFFI API, not a
remote inference service. Provisioning it is a separate clean-checkout input.

The next source-model edit must replace the atomic all-queue empty assumption
with processor-local drain and sequential steal/probe history, retaining eager
producer activity and wait restoration. Do not rerun the unchanged recursive
timeout, compiled `_num` timeout or bootstrap failure just because a framework
test or scheduling diagnostic passed. Source refinement, same-candidate native
GC/lifecycle tests, full bootstrap and Gerbil build/test remain required.

The stopped final campaign's 774-MiB TLC state cache was removed after portable
evidence archival; that campaign directory is now about 600 KiB. New final-mode
checks automatically remove only their own state scratch after process teardown.
