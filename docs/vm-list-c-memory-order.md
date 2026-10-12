# VM List Publication Memory Order

## Review Before Runtime Changes

This path is supported by the actual list fields being `___VOLATILE`, not C
atomics. The existing constructor visibility model uses sequential consistency;
its successful result does not settle the memory-order refinement. This is a
new refinement of that open obligation, not a repeated native crash attempt.
The benefit sought is a correct publication contract. No speedup is estimated,
and this litmus is not attributed as the cause of the reported compiler crash.

GNU GCC documents that volatile does not order ordinary memory accesses:
[Volatiles](https://gcc.gnu.org/onlinedocs/gcc/Volatiles.html).
Its [atomic builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html)
describe release/acquire synchronization and possible external-call fallback.
The abstraction assumes two existing threads and no alternative happens-before
edge. It is not a complete C memory model or a same-thread signal-handler proof.

## Verified Evidence

Campaign `.data/vm-list-memory-model-001` failed QNT typechecking and is retained.
The corrected campaign `.data/vm-list-memory-model-002` has stable input hashes.
Its portable receipt is `evidence/model-results/vm-list-c-memory-order-model/`.

| Control | Counterexample States |
| --- | --- |
| Volatile-only accesses | 4 |
| Relaxed atomics | 7 |
| Release without matching acquire | 7 |
| Release before payload initialization | 20 |
| Atomic writer with non-atomic reader | 4 |

The unimplemented release/acquire contract passes safety and weak-fair progress:
5 distinct states, 6 generated, 0 queued, 24.429 seconds. Counts for controls
are explored distinct states, not necessarily the length of the shortest trace.
The reader must read the initialization-bearing release store; merely using an
acquire elsewhere is not sufficient. All accesses to the shared pointer must
use a consistent atomic protocol, and initialization must precede publication.

## Still Open

Audit every actual reader/writer and alternative synchronization path before
selecting a source change. Establish lock-free target code generation and signal
handler suitability; generic atomics may call a locking fallback. Publication
does not settle list traversal, unpublication, payload mutation, or safe storage
reclamation. The constructor model's reader-retirement obligation remains open.
No runtime repair, native test, bootstrap, or performance claim is admitted.
