# SFUN Owned Unwind Candidate

## Decision And Source Delta

Real nested C -> Scheme -> C -> Scheme diagnostics found that errors reach the
C caller but generated SFUN tails skip both marker invalidations. Normal calls
observe made2/killed2; injected errors observe made2/killed0, before and after
successful `cleanup_checked`. This motivates explicit exception-safe ownership,
not a different processor scheduler or an admission counter at the old tail.

The candidate changes only six macro lines in `include/gambit.h.in` relative to
the callback-result candidate. VOID, SCMOBJ and generic converted SFUN wrappers
enter `BEGIN_TRY` only after marker creation succeeds. They leave `END_TRY`,
restore the prior catcher, invalidate the owned marker and then propagate the
original error. Marker allocation failure does not enter the try or invalidate
an uncreated marker. Existing conversion/error-handler code stays inside the
guard. No ABI, global lock, disabled SMP or changed budget is introduced.

This correctness candidate is not asserted to be Darwin-specific: the audited
setjmp tail bypass is also possible without migration. Current native evidence
is Darwin/GNU GCC only. Linux and C++ exception configurations remain required
before broad admission.

## Model Boundary

`sfun_catcher_cleanup.qnt` represents the three wrapper kinds, successful
execution, failed marker allocation, nonlocal body error and integer-result
conversion-handler error. It rejects tail-only cleanup, an unrestored catcher,
double invalidation, killing an uncreated marker and error erasure. The model
assumes the selected processor state and C catcher identify the owned frame;
native migrated tests must check that assumption. It is not formal composition
with GC or an operational C/setjmp semantics proof.

Catchers, marker and processor-state locals must remain valid across longjmp.
The marker is assigned before the new setjmp and is not modified inside it;
the prior catcher is captured before setjmp. Result locals modified inside the
try are used only on successful return; the nonzero error is rethrown before
the generated return. Compiler optimization and both exception configurations
still need verification rather than relying solely on this source argument.

Additional guards impose a setjmp cost per external SFUN invocation, not per
Scheme allocation or copied object. No speedup claim is made. Measure repeated
callback cost and complete Gerbil build/test under the existing gates before
admission. Conversion-handler retries, parameter conversion resources,
cancellation, continuation reentry, runtime-entry marker lifetime, complete GC
and processor retirement remain open.
