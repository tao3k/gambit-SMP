# SFUN Context Model Result

## Retained Failure

`sfun-marker-explicit-context-model`: DENY, 19.622076959 seconds.
The positive safety model completed (4 distinct states, queue empty), and the
missing-context control produced an accepted counterexample. The static-binding
control violated safety in its initial state, but the framework requires a
decoded transition trace with at least two states. That control was rejected;
the run was not upgraded to PASS. The original model and recipe remain intact.

Child receipt SHA-256:
`098ecbc10990fa7b6731f353fd365b0ad1a894288cd357fc1d4a1c18d55cc479`.

## Explicit Binding-To-Use Successor

`sfun-marker-context-use-model`: PASS, 19.369565250 seconds, all 8 steps.
The binding policy is selected at initialization; actual use is an explicit
transition. This is a source-directed abstraction, not a simulated C compiler.

| Check | Result | Distinct States |
| --- | --- | --- |
| Automatic explicit context | Exhaustive safety PASS, queue empty | 4 |
| Missing context | Expected violation, decoded two-state trace | 2 |
| Shared static context | Expected violation, decoded two-state trace | 2 |

All three trajectory tests also pass. TLC obtains its worker count from the
available host CPU count (12 observed, not a model constant).

The failed run plus successor consume 38.991642209 seconds, below the original
90-second model campaign ceiling. The successor ceiling was reduced to 70
seconds; no compiler/bootstrap qualification allowance was added.

Engine ID:
`fc943732ddf04239f2dd9426f57ad71f00af2b384ff04ecd77337fadffa7ff2b`.

Outer receipt SHA-256:
`d93ae44ab68674735029a45480cc7f8fdb498c49f4a6af892077b553ffd065a1`.

Child receipt SHA-256:
`d7c0f6a44523f035dc3c4bc4f06ed758470a990619ccf3321ea2b02f6e8f9e81`.

Model and recipe are repository assets; decoded counterexamples are retained
under `evidence/fixtures/sfun-marker-explicit-context/`, not only in caches.
The source lock binds the pinned submodule revision and complete candidate
patch. The workspace-state reference is inventory custody, not an executable
backup or permission to admit the old producer against the new source.

## Source Checks And Remaining Requirements

Compile-only fixture `models/gambit/native/sfun_marker_header_context.c` now
expands all three BEGIN_SFUN wrappers as well as the helper. GNU GCC 16 and
G++ 16 each pass direct-import and late-binding modes. These are syntax checks,
not execution of a private helper or full native acceptance.

Still required for this successor: source-bound complete bootstrap; native
allocation-failure unwind and lease balance through permitted public paths;
complete compiled inventory and stress; VM lifecycle/registry/GC-FFI gates;
Gerbil correctness and release performance. The cumulative milestone remains
3/12, with the previous queue-endpoint runtime retaining its completed gates.
The unchanged qualification ledger remains 468.695876834 / 600 seconds.
