# SFUN Gate And Count Publication Order

## Review Before Implementation

1. Relevant: sfun_frame_enter changes the VM temporary gate and per-processor
   frame count separately; sfun_vm_try_close seals that gate before scanning
   removable processors. Their interleaving determines whether active callers
   prevent retirement.
2. Already covered: foreign_origin_retirement_admission and word_bounds model
   publication and gate release as one action. They cover origin, stale lookup,
   errors and saturation but do not expose the real intermediate publication.
3. Worth checking: this is a correctness prerequisite for the existing fast
   per-processor lease design. No global lock or waiting collective is added.
4. Expected benefit: more faithful protocol evidence; no runtime speedup or
   new source bug is claimed before checking.

## Source Sequence

include/gambit.h.in:sfun_frame_enter reserves an even VM gate contribution
with CAS, publishes the processor count with CAS, then subtracts the temporary
gate contribution. Counter saturation rolls back the temporary contribution
before returning an error. lib/setup.c:sfun_vm_try_close requires CAS(0,1)
before scanning frame counts and reopens on busy. Existing word_bounds covers
the finite overflow abstraction; this model isolates the successful ordering.

The model imports and reuses foreign_origin_retirement_admission for call
lookup, reservation, allocation/outcome/release, closing, retirement and reuse.
Only publication is split into count-before-gate updates. Its intermediate
phase retains both a visible count and a temporary gate contribution. Physical
counts include that phase; the old abstract population is obtained by subtracting
the intermediate count until gate release commits abstract publication.

Controls independently release the gate before count publication, omit count
publication, or release the temporary contribution twice. The close operation
must see busy either before publication (gate reservation) or after publication
(processor count), without waiting for active Scheme callbacks inside a
collective.

## Assumptions And Open Obligations

Atomic operations are sequentially consistent returning actions; this does not
prove a particular C/CPU memory model or machine-code mapping. Two tokens and
two origin roles are finite bounds, not host CPU/VM limits. Generation lookup,
VM storage lifetime and reuse retain the imported model's assumptions; actual
raw PSTATE acquisition needs its own registry/lifetime refinement. Allocation
root/catcher behavior remains a separate checked model, not automatically
composed by this import. No arbitrary nested-callback, full GC or fairness proof
is claimed. Passing this model cannot qualify an unbuilt source successor.
