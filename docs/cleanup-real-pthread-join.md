# Cleanup With A Real Darwin Join Error

## Path Review

Previous source-unit injection proved the caller's ignored-error decision with
an arbitrary sentinel. This diagnostic replaces that sentinel with a real OS
operation on an explicitly controlled thread. It strengthens the primitive and
caller binding, not the reachability of this condition in valid Gambit usage.
No performance gain is expected or claimed.

## Platform Contract

The [Apple pthread_join manual](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_join.3.html)
documents rejection of a non-joinable thread with EINVAL. The diagnostic is
Darwin-only and keeps that thread alive while joining it; no expired pthread ID
is used. Its detached state is deliberate adversarial setup, not a normal
Gambit processor creation mode.

The [current POSIX specification](https://pubs.opengroup.org/onlinepubs/9799919799.2024edition/functions/pthread_join.html)
does not guarantee portable behavior for a non-joinable target. Therefore this
fixture must not be generalized to arbitrary POSIX hosts, or treated as evidence
that a properly owned joinable Gambit processor can fail this way.

## Source Binding And Observations

The pinned submodule plus the scheduler-retry cumulative source lock is
independently materialized. The fixture includes complete unchanged
`___thread_join` and `___cleanup` definitions, and the locked header's error
encoding macros. POSIX primitives are real; Scheme tagging is abstracted.
Collective resize coordination and destructive cleanup helpers are observatory
stubs, not the real VM implementation.

A condition-variable handshake guarantees the detached worker is still waiting
when the actual wrapper returns. A joinable control is released before cleanup
and joined normally. Neither path destroys the fixture's shared storage while
the worker might still use it; the storage remains static until process exit.

GNU GCC strict compilation passed in 0.151 seconds. Six processes ran in
parallel, bounded by available host capacity and the six-case inventory:

- Joinable control, three runs: error 0, zero unsafe-release calls.
- Detached control, three runs: EINVAL (22), worker still live, two
  unsafe-release calls and one global-release call.
- All six observation assertions passed, no timeout, process groups quiescent.

Passing assertions report the current unsafe caller decision; they do not turn
that decision into a safe protocol outcome. Destruction calls are counted, not
executed against actual Gambit objects. Ambient errno remained EDOM (33), while
the candidate correctly preserved the returned join error identity.

Evidence is under
`evidence/source-results/fixtures/scheduler-retry-sync-participation/cleanup-real-pthread-join-strict-preprocessor/`.
The preceding strict-preprocessor compilation denial is preserved under
`cleanup-real-pthread-join/`, including its original fixture snapshot. A quote in
the skipped non-Darwin #error directive caused that lexical warning; the fixed
fixture changes only that directive. No budget or assertion was relaxed.

## Model And Repair Requirements

The cleanup-error and error/GC-drain QNT models retain their conditional
failed-join branch. This observation supplies a concrete Darwin primitive
example for that branch, not a proof of its production preconditions. Their
positive quarantine policy remains unimplemented.

Before claiming a source repair, establish joinable handle ownership, absence
of concurrent join/detach and the actual retired-processor exit path. Preserve
the failed processor/resource inventory independently of reduced population;
prevent further GC, reuse and teardown if safe quiescence cannot be established.
A checked cleanup return alone does not prove these VM-level requirements.

Still open: valid-processor failure reachability, concrete checked/legacy failure
disposition, native GC/retirement refinement, full suites, two-pass bootstrap and
Gerbil correctness/performance acceptance. No runtime or release admission.
