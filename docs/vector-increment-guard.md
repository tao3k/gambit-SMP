# Public Atomic Increment Guard

## Path Review

- Direction: the original compiled `vector_incbang.scm` fails its type-exception
  assertion for `(vector-inc! vect1 0 #f)`, returning 12 instead. This is actual
  native evidence, not a timeout diagnosis.
- Prior work: the checked-negation repair does not cover this expander; no
  existing model covers an invalid public atomic-increment delta.
- Value: restore the public primitive's checked dispatch contract without
  changing the underlying atomic operation, GC or useful PR988/1038 repairs.
- Expected benefit: correctness, not a measured performance improvement.

The ordinary-vector expander's `value-checker` is absent because vector
elements may be arbitrary Scheme values. Increment's explicit delta is
different: it must be a fixnum. The shared expander currently therefore passes
an invalid delta to unsafe `##vector-inc!`. The interpreter passes the original
file; the compiled full-suite batch exposes this missing compiler guard.
This is a generic local compiler defect, not attribution to PR988 or Darwin.

`vector_increment_guard.qnt` covers omitted delta, valid explicit delta and
invalid explicit delta with a valid vector/index. The old control violates
the invariant; the checked variant exhausts 7 distinct / 10 generated states
with zero queue. Invalid input must report an error without mutation. Numeric
overflow, invalid stored values, atomic linearizability, GC and C memory order
are outside this bounded model. Its first verifier attempt is denied by a
local-service socket permission error, not an invariant counterexample; the
subsequent permitted run records the actual negative and positive checks.

The candidate changes only `gsc/_prims.scm`'s increment delta check: explicit
third arguments use the existing fixnum predicate; omitted arguments retain
the default increment. Existing ref/set/cas checks, fallback, argument
temporaries, vector/index/mutability checks and the unsafe primitive remain.
The source builder computes the exact expected whole-file hash and rejects
other edits. It removes `_prims.c` before regeneration and requires a new
compiler artifact while the interpreter bytes and ordered runtime object
members stay unchanged. Archive headers and Darwin's regenerated symbol index
are container metadata, not object members; the build must still link actual
binaries without errors. Attempts024/025 remain denied: the first used archive
byte identity, the second also treated `__.SYMDEF SORTED` as object code.
Their native build exits are zero; neither denied receipt is rewritten.

Runtime026 real GNU GCC source-core rebuild passes in 28.509 seconds with new
compiler bytes, unchanged interpreter bytes and identical ordered runtime
object-member hashes. The unchanged original increment and CAS files pass in
both modes: 2/2 interpreted in 0.554 seconds, 2/2 compiled in 22.414 seconds,
under the unchanged 300-second mode budget. Source and artifact identities
remain stable. The original failure is retained. The old batch and the new
isolated regression have different topology/workloads; these times do not
establish a matched speedup. Full vector-family checks are a separate gate.
That 31-file family passes interpretation in 10.172 seconds. Compiled mode is
DENY at 300.853 seconds: complete shards pass 11 and 10 files; the third has
seven completed-prefix progress entries and three outstanding files, with no
failed assertion observed. A completed prefix is not a successful whole shard,
and this receipt is not rewritten or admitted as a whole-family timed pass.
The three outstanding files separately pass compiled execution in 9.562 seconds
under the same 300-second mode budget, with host-auto shared capacity. This is
not an unchanged repetition of the denied complete-family configuration and
does not admit the original whole-family timing gate. The timed-out shard's
completed prefix is retained as partial evidence, not a completed-shard PASS.
No complete bootstrap or SMP green claim follows from this local repair.
