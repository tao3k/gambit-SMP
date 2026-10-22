# Runtime Entry Contract Validation

## Evidence Boundary

Local 2026-10-19 verification of the [contract audit](runtime-entry-contracts.md).
No runtime source, TLS, locks, bootstrap or native qualification was changed.
These are bounded model checks, conditional proofs and real Scheme DSL
consumer checks, not C source refinement or an SMP gate increment.

The existing verifier used host-auto capacity: 12 available processors,
two concurrent negative checks with six TLC workers each, and twelve workers
for a positive check. These observed values are not configuration constants.

| Final asset | SHA-256 |
| --- | --- |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `be39d309976619f8ab49174bb4605d711f9f84bd1ccb2450ac84dfe3b2eab46d` |
| `models/gambit/runtime_metadata_allocation.qnt` | `66dad1d9ee95d35478bc206652509df86a9e9a6f8d9a21dd81267c2653412af5` |
| `models/gambit/runtime_host_entry.qnt` | `c887d5add58248386e16575f880f191519e17fb9d2c8c545033cfa961a452acc` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `200120150f996283ad1fd22047bb3f577f52209d335de1763d14f7feb4e8dbbc` |
| Reused `models/gambit/serial_number_transaction.qnt` | `4d56c21fd70cba660c50a32400bec0d08098d17396b793805cc63e271f0c2ff3` |

The manifest binds the reviewed Gambit source lock/patch, reference source and
conditional Lean inputs. It does not bind an arbitrary future native candidate.

## Actual QNT Outcomes

Quint 0.33.0 with TLC completed both new positive safety/liveness checks with
an exhausted state queue and `Finished checking temporal properties`.

| Check | Outcome | Explored evidence | Checker seconds |
| --- | --- | --- | --- |
| Metadata positive | Safety and weak-fair completion pass | 232 distinct states | 3.993 |
| Split reservation control | Expected `reservationSafe` counterexample | 5 decoded trace states | 5.451 |
| Early publication control | Expected `publicationSafe` counterexample | 4 decoded trace states | 5.434 |
| Host entry positive | Safety and weak-fair completion pass | 97 distinct states | 5.449 |
| Lease-only control | Expected `executionExclusive` counterexample | 5 decoded trace states | 5.566 |
| Unregistered entry control | Expected `memberSafe` counterexample | 3 decoded trace states | 5.577 |
| Lost binding control | Expected `bindingRestored` counterexample | 5 decoded trace states | 4.567 |
| Reused serial-number transaction | Original negative and positive pass their expectations | Positive 23 distinct states; no new liveness claim | 5.233 / 5.184 |

The traces isolate different premises: two readers reserve from the same stale
cursor; publication precedes initialization; two TLS-bound lease holders enter
the same processor; an unregistered owner enters; or a return keeps the target
instead of restoring the prior binding. These are abstract counterexamples,
not reproduced Gambit failures. The models do not prove rehash-reader safety,
psection growth, source linearization, nested C unwind or GC progress.

Final new-model receipt SHA-256:
`1c421b1e4e9f1545843d464b8104bd59298ca5413a811d919ee7cd51453e8479`.
Reused-transaction receipt SHA-256:
`1c0e7180b9d646855c7e9064764c546cf89f82edab2fdc7b08c51801cd1a176c`.
Raw logs/decoded traces remain disposable cache artifacts, not source
dependencies. These hashes identify the observed local run; a fresh run will
have its own receipt identity. The versioned summary does not substitute for
a missing raw log when a consumer requires proof admission.

## Lean And Scheme Consumer Outcomes

The existing pinned LeanPoo project built `RuntimeEntryContracts`. All five
named theorem inventories were checked without `sorryAx`; their only reported
axioms were `propext` and `Quot.sound`, or none. The two deliberately false
claims were rejected by `decide` as false, not by import/type errors.
Compilation and elaboration used the existing guarded process adapter, with
120-second build and 15-second elaboration caps plus heartbeat/recursion
bounds; no timeout occurred and all observed process groups were quiescent.

The focused three-test consumer passed in 1.077 seconds. It checks the guarded
Lean result and false claims, moved documentation links/input hashes, and the
actual installed Scheme DSL. The DSL retained two explicit partial research
chains, reused the Session, exposed withdrawn source premises and restored the
same answers. It never derived native `satisfies`. The existing five-chain
consumer also passed independently in 0.262 seconds.

## Retained Failures And Corrections

- The first verifier invocation could not bind its loopback checker port under
  the sandbox. It was an infrastructure failure, not a model counterexample.
- Initial Lean closed examples lacked explicit unfolding for decidability;
  the build failed and printed error-generated `sorryAx`. They were rejected,
  corrected by unfolding the definitions, and checked again. No theorem was
  admitted from that failed build.
- A test initially expected a different Lean diagnostic phrase, despite the
  two desired semantic rejections. The assertion now checks the pinned
  checker's actual `decide`/`is false` diagnostics and excludes synthesis errors.
- A test edit briefly removed a required `Path` import and raised `NameError`;
  the import was restored and the complete focused consumer rerun.

The earlier QNT receipt bound the pre-correction Lean input. A fresh whole
new-model run binds the final manifest above; the old run was not relabeled.
No historical receipt or other lane's native failure was edited.

## Reproduce Without A Native Rebuild

From the repository root, with the pinned tools and installed ASCENT engine:

```sh
.venv/bin/gambit-smp verify \
  --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json \
  --out "$FRESH_CACHE_OUTPUT"
.venv/bin/gambit-smp check --case serial_number_transaction \
  --out "$FRESH_TRANSACTION_OUTPUT"
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Output directories must be fresh configured-cache paths. No original pressure
test or known failed native route is launched by these commands. Actual C
ownership, reader/writer completeness and the two implementation horizons
remain the open source/native obligations in the audit.
