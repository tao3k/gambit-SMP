# Shared Metadata Package Validation

## Boundary

This records local checks of the [design package](shared-metadata-package.md),
not a runtime implementation, native qualification or performance result.
Historical publication/root-map receipts remain unchanged. The new resource
profile composes proposed leaf acquisition and reservation only; it does not
compose real GC, OS waits or C weak memory.

No native build, bootstrap, debugger or stress test was run. The other lane's
candidate, source lock, Recipes, checkpoint and native failures were untouched.

## Inputs And Source Check

| Input | SHA-256 |
| --- | --- |
| `docs/experimental/shared-metadata-package.md` | `16b35bb6755d9b4fc6d6d57ca833f05544216ded183f8bfd4ccae5dbbc40327c` |
| `models/gambit/runtime_metadata_allocation.qnt` | `f5b4c663900f86bf90b143cb344c71172d2799e0fd3023bfa3bae4b2c733e100` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `2b530d4829f4c2f22d9cd2ddac26eb5625ef13c17df58b07f8d480eb202b8f8f` |
| `models/gambit/lean/controls/RuntimeEntryFalseClaims.lean` | `caa6c3f8017725e5433d17967ed77c5bb12d9360d4f9084539ea8f0b50feceb8` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `b8f8990564ddddfd51d764fec32ea7ed17e6d406f1fff70bbd26fd95bd2a6b42` |

The read-only materialized `setup.c`, `mem.c`, `os_io.c` and header digests
matched the existing overlay lock. No cache pathname was promoted to a source
dependency. The new callback-order observation follows the actual V-owned
cleanup -> procedural-release function pointer, distinct from registry signal
readers. Its possible metadata reentry is a contract gap, not a native deadlock
reproduction or an established TFIB/pipe cause.

## QNT Results And Controls

The existing verifier accepted all eight expected controls and the positive
safety/weak-fair completion check: **884 distinct states, 2,608 generated**.
The five prior controls remain present at the new model digest. The three new
traces were inspected:

- Reverse registry order: three states reach M owned by interner 0 and V owned
  by operation 1, with each attempting the other's resource. This is a
  prospective acquisition-cycle witness, not an execution of Gambit locks.
- Arena bypass: six states give the protected interner and unprotected
  standalone allocator the same unit reservation base 0, after a stale cursor
  observation. Protecting only interner callers is insufficient.
- Guarded callback: two states reach ownership of M followed by an attempt to
  acquire M again. This exposes the nonrecursive effect-contract violation;
  it does not assert Windows and POSIX native mutex behavior is identical.

Positive executions compose M -> P, V -> M -> P and P-only allocation. The
finite scripts terminate without GC/service/callback or OS stalls. Publication
and rehash profiles remain separate; fairness here is not a hard latency bound
or full table/collector/weak-memory refinement proof.

Receipt: `.cache/runtime-entry-models/shared-metadata-resource-composition/receipt.json`,
SHA-256 `30a906f87833b9c5c1e83d28648079a396a8e6f5401d5283c06ece9c67ba581e`.
Context/source remained stable, every check had `timeout=false`, native was
`not-run`, and runtime/release admission remained false. The framework selected
host-auto scheduling (two independent control jobs; six TLC workers per control,
twelve for the positive on this host), not a hardcoded runtime worker count.
No per-check budget was widened. Its 34.264-second campaign is a formal-check
duration, not a runtime speed result.

During editing, the first typecheck rejected a branch-local `resource` name
with `QNT404: Name 'resource' not found`. Moving pure command-derived bindings
to the enclosing action scope resolved it; the corrected model typechecked and
was the sole digest used for TLC. This authoring failure is retained here,
not counted as a protocol counterexample or hidden by a changed expectation.

## Lean And Scheme Closure

Guarded Lean build and explicit heartbeat/recursion-limited checking passed.
Sixteen theorem inventories were printed with no `sorryAx` and only standard
axioms; all nine false claims were rejected as expected. New conditional lemmas
exclude opposing registry/metadata strict ranks and separate a forward aligned
successor interval. They do not establish C lock edges, alignment/overflow code,
failure unwind or native compatibility.

Guarded observations under `.cache/runtime-entry-formal/run-sur40oh7/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `28b10f0c0b071bf92aff6d0a51a6a544cfa53aa04b9c1d92517ff2ef8cbce18a` |
| `axioms.json` | `4488ee154d4aaadec795eea7048420171301ca3f7120973e40ae160abc4c4a64` |
| `false-claims.json` | `8d54a46cfdabf7ceaa73853c48cdf33c21d68e5bc542aa148a81e3cc4bb7be4c` |

Each observation exited without timeout and left a quiescent process group.
Existing runtime-entry focused tests passed (three checks, 4.614 seconds), as
did the unchanged parallel-GC scenario check (0.677 seconds). These are local
test durations, not native runtime acceptance.

The existing Scheme component consumes the added package-order/reservation/
reader/publication/lifecycle premises. Repeated evaluation reuses Session
results, withdrawal of the new package source exposes missing provenance, and
restoring it recovers the original answer. All three transfer conditions still
have partial model coverage and missing native obligations; `satisfies=[]`.
Python changed only in the existing focused test's theorem/control/source
inventory, not production inference, parsing, workflow or registration.

## Reproduction

```sh
quint typecheck models/gambit/runtime_metadata_allocation.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case runtime_metadata_allocation --out .cache/runtime-entry-models/shared-metadata-resource-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Use a fresh output directory for a new formal check. Cache receipts are
disposable observations, not source inputs or native milestone counters.
