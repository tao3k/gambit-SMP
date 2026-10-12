# Source Wait Induction Obligations

The source-wait reachability search was incomplete. Its preserved full
transition relation is now connected to the existing symbolic induction
framework, without a feature-specific runner or stronger guards on actions.

`gc_source_wait_induction.qnt` imports the unchanged candidate domain/predicates
and the source-wait extension. The matrix resolves named actions through
explicit unqualified wildcard imports; ambiguous origins, cycles, aliases and
nested action disjunctions are rejected rather than guessed. Its parsed full
relation still contains exactly 22 action branches.

## Actual Checks

The new filtered campaign used machine-derived scheduling and the framework's
existing 90-second per-obligation ceiling. Inputs and snapshots remained stable.

| Obligation | Seconds | Result |
| --- | ---: | --- |
| Source initial state implies candidate invariant | 15.413 | Proved |
| `orderedRecheck` preserves candidate invariant | 18.600 | Proved |
| `unboundedWake` preserves candidate invariant | 19.718 | Proved |

The preservation checks ran concurrently; summing these times is not wall time.
The entire Cartesian state generator was checked by the existing IR contract,
with 25 fields and 22 independent choices. This is the existing trusted
Cartesian-choice conformance rule, not a solver proof of the generator auditor.

Portable receipt, full parse IR, model snapshots and logs are preserved in
[`gc-source-wait-new-action-induction`](../evidence/model-results/gc-source-wait-new-action-induction/archive.json).
Reflection binds every archived artifact by digest.

## Remaining Boundary

This filtered campaign deliberately reports `preservationComplete=false`,
20 uncovered actions, `accepted=false`, and no temporal/native admission.
It has not checked the safety implication in this campaign. Earlier results
for the unchanged actions cannot be silently transferred: reuse needs a
mechanically checked semantic dependency identity or fresh obligations.
No old receipt was rewritten, and the earlier full-step timeout remains
incomplete. Successful primitives, coherent memory, finite roles/graphs and
one GC phase remain model assumptions. C refinement and complete native
GC/multi-VM/bootstrap/Gerbil acceptance are still open.

Reproduce the exact filtered scope from the repository root with:

```sh
python -m gambit_smp.induction_matrix \
  --manifest evidence/gc-source-wait-induction.json \
  --out .data/gc-source-wait-new-action-induction-reproduction \
  --step orderedRecheck --step unboundedWake
```

The output directory must be new. Its use is disposable output storage, not
a source input. No fixed CPU count is required.
