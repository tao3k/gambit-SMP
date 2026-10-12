# Pthread Returned Error Identity Fixture

## Review Before Repair

The pinned POSIX wrappers translate ambient `errno`, although pthread create and
join return their own error number. Existing source audit already identified this
route; this fixture implements that repair rather than claiming a new discovery.
Expected performance benefit is zero. This is portable POSIX correctness, not a
Darwin-only optimization or a repair for ignored join results in VM resize.

The source authority is the pinned `vendor/gambit` submodule plus
`evidence/fixtures/pthread-returned-error-identity/source.lock.json` and its
cumulative overlay. The thirteen parent files remain unchanged; only
`lib/os_thread.c` is added to the locked inventory. Win32 and unsupported-platform
branches are unchanged. No ambient errno assignment is introduced.

## Model and Native Binding

`pthread_returned_error_identity.qnt` checks error identity, handle publication,
and progress under returning, errno-preserving injected primitive contracts.
The model abstracts error identities; it does not implement Scheme tagging.

The native recipe projects complete create/join wrappers, the actual errno
conversion function, and header error-code macros. Only POSIX primitives and the
common initializer are injected; fixnum tagging is explicitly abstracted.
Both candidate and unchanged locked parent execute the same assertions.
The 18 cases cover two operations, three return codes, and three independent
ambient errno values. Failed create deliberately writes an output handle: the
wrapper must not publish it. The matrix checks initializer count, primitive call
count, handle ownership, errno preservation, and the actual macro encoding.

The configured-object recipe compiles complete `os_thread.c`, `mem.c`, and
`setup.c`, including the mutex-backed spinlock memory variant, using GNU GCC and
all three required flags. This validates compilation, not a linked runtime.

## Reproduce

Run the generic research framework with recipe IDs
`pthread-returned-error-identity-wrappers` and
`pthread-returned-error-identity-objects`, using an identified sealed engine.
Inputs, native observations and the autoconf sandbox denial are bound in
`evidence/source-results/fixtures/pthread-returned-error-identity/observation.json`.
The sandbox denial is retained; host-authorized compilation is a distinct run.

## Remaining Obligations

Returned-error fidelity does not establish successful join or safe retirement.
VM resize still needs result distribution to non-P0 requesters, permanent-failure
ownership, admission closure and user drain. Complete GC phase composition,
source-regenerated linked runtime, bootstrap, Gerbil tests and performance gates
remain unqualified. No full runtime or release admission follows from this
fixture.
