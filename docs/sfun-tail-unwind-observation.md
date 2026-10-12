# SFUN Sequential Tail And Nonlocal Unwind

The source-unit fixture compiles the identified source core's actual generated
Gambit header with GNU GCC. It overrides marker allocation/invalidation and the
Scheme-call body, but executes the actual `BEGIN_SFUN_SCMOBJ`, result/error/END
macros and the configured setjmp `ON_THROW/THROW` mechanism. One synthetic
processor state is used. This is **not a full-runtime callback or SMP test**.

| Injected call | Marker created | Marker killed | Stub marker still live | Outer catcher |
| --- | --- | --- | --- | --- |
| Normal result | 1 | 1 | 0 | Not reached |
| Marker allocation failure | 0 | 0 | 0 | Reached |
| Nonlocal throw from call | 1 | 0 | **1** | Reached |

All three expected assertions passed, exit0, no timeout or leftover process
group. Compile took 0.171 s and observation 0.632 s, within unchanged 60 s/5 s
budgets. The process's successful exit means the **source boundary was
reproduced**, not that the unimplemented borrower design or original runtime
has passed complete correctness. No native stale-marker exploit is claimed.

The exact fixture, source-core identity/lock binding, compiler version, output,
budgets and portable archive hashes are in
`evidence/source-results/fixtures/callback-return-owned-result/sfun-tail-unwind`.
The generated header is reproduced by the bound source-core recipe rather
than taken as an authority from a cache directory.

This observation rejects the proposed shortcut of releasing a new borrower
counter only at the existing END_SFUN tail: the injected nonlocal path bypasses
that tail. Acquisition before allocation also needs failure rollback. It does
not implement those repairs or establish native migration/error reachability.

An additional SMP obligation follows from inspected `THROW`: its catcher is
the **current processor's** catcher. A callback may have migrated away from its
original C owner; a local wrapper cleanup alone does not prove that an error
returns to the right C stack or releases the original incarnation. Current
owner routing, exception data roots and exact-once release must be proved before
retirement can be admitted. The C++ exception configuration is not covered by
this GCC/C source-unit observation.
