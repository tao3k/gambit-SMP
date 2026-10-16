# SFUN Allocation Unwind Contract

## Decision Review

The new explicit-context repair enables compilation; it does not establish
resource cleanup. Existing sfun_catcher_cleanup/error_families models start with
marker allocation and primarily cover later callback/conversion failure. The
foreign_call_admission model abstracts allocation failure without the saved root
or catcher. Neither covers their pre-marker interaction in the current helper.
The scoped addition below closes that model gap, not a new runtime defect.
Expected benefit is correctness evidence; no speedup is predicted.

## Current Source Sequence

In include/gambit.h.in, sfun_frame_marker admits a lease before entering
ON_THROW_AUX. BEGIN_TRY installs the passed processor's temporary catcher.
In lib/c_intf.c, make_sfun_stack_marker saves proc_or_false in saved[0] before
make_vector. Both normal/error returns execute GC_RESTORE1, which clears it.
A nonlocal throw bypasses that restore. END_TRY restores the outer catcher
before the helper's error clause clears saved[0], leaves the lease and rethrows.
The ordinary returned allocation error leaves the lease once without rethrow.
Success transfers the lease to the wrapper, which kills its marker and leaves
once on completion. No failed allocation publishes a marker to that wrapper.

## Model And Limits

sfun_allocation_unwind enumerates two distinct processors and all nine pairs
of success, returned allocation error and nonlocal allocation error. These two
identities are a finite interference bound, not a host CPU setting. Each owns
its catcher/root/count. Controls independently omit root clearing, omit lease
release, decrement another processor, or rethrow before restoring the catcher.
The positive model requires exact per-processor counts, cleared roots before
propagation, restored catchers, honest errors and no terminal leaked lease.

Admission is abstractly successful; the gate's multiword publication and VM
retirement are not proved here. Also excluded: same-processor nested callbacks,
real C setjmp automatic-variable rules, allocation internals, C memory ordering,
GC movement, a scheduling fairness proof and native source refinement. Existing
public-FFI restrictions remain: no private cleanup execution or injected loader
hooks. No runtime source edit follows merely from a model passing.
