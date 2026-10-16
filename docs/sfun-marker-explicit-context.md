# SFUN Marker Explicit Context

## Source-Directed Decision

1. Relevant: the current numeric compiler observation failed with GCC exit 70,
   not a timeout. In SINGLE_HOST dynamic code, `___ON_THROW` expanded through
   `___PSTATE` and required an undeclared `___local_gstate` in the inline marker
   helper. This prevents the original assertion-bearing module from compiling.
2. Already explored: the preceding scheduling observation is retained as DENY.
   It is not repeated or relabeled as a scheduling speedup.
3. Worth fixing: all three BEGIN_SFUN wrappers use this helper. Passing their
   existing global and processor context repairs the actual compilation path
   without an exported ABI change, serialization, or disabling SMP.
4. Expected benefit: correctness only is established here. Compilation cost and
   full native acceptance remain unknown until a source-bound rebuild.

## Context Contract

The helper receives an automatic `___global_state ___local_gstate` parameter
and the caller's processor. `___ON_THROW_AUX` retains that processor rather than
declaring a replacement through `___PSTATE`. Late-bound EXT/SETJMP access can
therefore resolve the required global context. Do not use `___GSTATEDECL` in
this helper: `___LOCAL` expands to static, introducing shared state.

All three wrappers pass `___GSTATE`; admission, allocation, saved-root clearing,
lease release and rethrow retain their ordering. No VM/processor layout or
exported RTS function signature changes. The compile-only C fixture is never
called as a runtime test and does not use a private cleanup entry point.

The finite model checks context availability and non-shared binding, including
old missing-context and static-binding counterexamples. It does not prove C
macro expansion, allocation unwind, a memory model, or runtime source refinement.

## Observations And Limits

The original generated numeric C passes three GCC syntax checks against the
new header: configured dynamic imports (9.090 s), SINGLE_HOST late binding
(9.028 s), and dynamic code without SINGLE_HOST (8.462 s).

The small compile-only fixture passes GNU GCC 16 and G++ 16, each with and
without CLIB/SETJMP dynamic-import definitions. An explicit C11 attempt fails
earlier on retained configuration's `thread_local` keyword; that mismatched
dialect is not a failure of the marker repair. The configured GNU default
dialect passes. No TLS change is included.

The generated header uses retained config.status. It is not a freshly linked
producer. The previous queue-endpoint bootstrap cannot qualify this successor.
The user declined a fresh qualification budget: retain 468.695876834 / 600 s
consumption and approximately 131.304123166 s remaining. Continue model and
source checks only; do not reset the ledger or start a full rebuild.

Cumulative milestone remains 3/12. This repair adds no completed native gate.
