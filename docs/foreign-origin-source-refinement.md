# Foreign-Origin Source Refinement

This audit consumes the source lock and submodule revision identified in
[the admission design](foreign-origin-retirement-admission.md), not an arbitrary
cache directory. Read the pinned submodule together with
`patches/fixtures/vector-increment-arity-parity.patch`; current upstream alone
does not describe that candidate. No source repair is admitted by this audit.

## Concrete Source Boundaries

| Candidate path / symbol | Current behavior | Required refinement |
| --- | --- | --- |
| `include/gambit.h.in`: `___BEGIN_SFUN`, `___BEGIN_SFUN_VOID`, `___BEGIN_SFUN_SCMOBJ` | Capture `___PSTATE`, allocate marker, then establish the catch frame | Publish an origin lease before allocating conversion/marker work; failure must release it without relying on marker existence |
| Same three `___END_SFUN*` macros | Catch unwind, invalidate marker, propagate error | Release exactly once after marker/conversion cleanup, before error propagation can unwind the caller |
| `lib/c_intf.c`: `___make_sfun_stack_marker` | GC-protect procedure, allocate still vector, record processor index | Marker allocation is not itself admission; processor index is not a VM/processor incarnation identifier |
| `lib/c_intf.c`: `___kill_sfun_stack_marker` | Invalidate procedure, decrement still refcount | Keep native-frame lifetime distinct from marker object lifetime; do not decrement a lease inferred solely from marker shape |
| `lib/setup.c`: `___run` | Also creates a marker and calls Scheme | Do not count ordinary runtime-entry markers as SFUN leases; doing so would reject normal resize/bootstrap behavior |
| `lib/setup.c`: `___current_vm_resize` | Submit resize to all processors | Close admission before entering the collective, or prove an equivalent collective protocol; never wait on leases inside that collective |
| `lib/setup.c`: `___vm_resize_pstate` | Common pending-join guard, change target, perform collective heap guard, lower population, join/transfer/cleanup | Every member needs the same admission decision before shared mutation; all abort paths must reopen publication |
| `lib/_thread.scm`: `##c-return-on-other-processor` hook | Migrate continuation to recorded origin processor | A Scheme continuation cannot replace its still-live native C frame; either preserve that origin or reject its retirement |

The setjmp catch restores the previous catcher in `___END_TRY`. C++ uses a
different catch form. An implementation must handle both, including any throw
before the wrapper catch exists. A fixnum allocation error is not proof that no
other call along the allocation/collective path can unwind.

## Finite Machine-Word Refinement

`models/gambit/foreign_origin_word_bounds.qnt` uses a deliberately tiny encoded
word to expose wrap. It is not a native processor count or permitted nesting
limit. Checked admission rejects before gate or per-origin lease saturation;
release after a successful admission preserves exact accounting. Negative
controls actually wrap each counter and break the accounting invariant.

Recipe: `foreign-origin-word-bounds-model`, under
`evidence/research/vm-registry-reader-lease/foreign-origin-word-bounds.recipe.json`.

- Final run: `.data/fixtures/foreign-origin-word-bounds/explicit-initializers-model-run`.
- PASS in 41.909375916 seconds; original whole budget 300 seconds, no new bootstrap.
- Safety and no-stall each: 36 distinct / 74 generated states, zero queued.
- Two trajectory tests passed; gate-wrap and lease-wrap counterexamples accepted.
- Engine: `30b196894b2dea5928b8165bf5e40e6012253b20677457790daa93aa4e62f03d`.
- Outer receipt: `2a59971e6168f111b9fcf6c78f7408809f570e5f6777c20fd926ad0b9fe63f65`.
- Child receipt: `e0a0061d8b44eb2eaf992e4de5d2233f50c175e951b2f90aefcbdb9fa9c516c1`.
- Prior DENY retained at `saturation-model-run`, outer receipt
  `f37f96b01788d642f56df5cb7c41033d92e3a1ed36eecb1fb4216ca00fc90a1c`:
  QNT409 shared initializer prevented TLA conversion. Explicit initializers fixed
  that representation error; no invariant, workload or budget was weakened.

Both recipes keep runtime, source-refinement and release admission false.
This small-word result does not prove arbitrary machine widths, incarnation
wrap, weak-memory ordering, VM reclamation, or native performance. Those remain
implementation/proof obligations; no full SMP gate closes here.

## Implementation Decision

Do not put the lease into the shared marker allocator. Bind it specifically to
generated SFUN wrapper entry/exit, with an independent failure cleanup path.
Do not use a VM-wide callback ban: only origins removed by this resize determine
whether it is busy. Keep the publication gate short and free of Scheme/GC work.
Before producing a new source lock, settle pre-catch unwind handling and the
common collective abort decision, then test official-FFI retry after C return.
Keep the unchanged original roundtrip as a historical DENY, not a passing test
rewritten to expect rejection.
