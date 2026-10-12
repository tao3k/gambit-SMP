# Nested Foreign Unwind And Origin Ownership

## Source Decision

The pinned setjmp implementation stores a catcher on a processor state.
`BEGIN_TRY` replaces that state's catcher and `END_TRY` restores it; `THROW`
jumps to the catcher selected by the processor-state argument. A catcher is
not a VM-wide continuation and cannot be moved to another OS stack by changing
a processor ID.

`___call` catches a trampoline unwind, restores its prior catcher and propagates
an unexpected code. Generated SFUN marker cleanup follows the call, so the
sequential tail can be bypassed. The actual-header source-unit already observes
that bypass with mocked call/marker operations. It is not an observed native
cross-processor exploit.

Normal Scheme return uses the marker's processor ID to route to its original
C frame. Worker termination follows a different path: `___run` catches the
termination code and `___run_and_throw_error_on_processor_0` sends it through
`OP_PROCESSOR_0_THROW_ERROR`, then remains available for synchronous operations.
That VM-fatal path must not be conflated with an ordinary nested callback error.
The source does not establish the hypothetical recoverable origin-error routing
used below. Adding a local catcher alone does not prove that routing.

## Model And Repair Obligations

`nested_foreign_unwind.qnt` models an outer C frame on processor 0 and an inner
C frame on processor 1. These are semantic ownership identities, not machine
thread limits. Normal outcome and two opaque nonzero errors are explored.
The inner frame must clean its own marker before routing to the suspended outer
owner. The outer owner cleans its frame before propagating the unchanged code.
Only after both frames have drained may retirement complete.

Five negative controls reject a bypassed inner cleanup, cleanup on the wrong
owner, duplicate cleanup, nonzero error erased into success and premature
retirement. The fixed transitions assume successful origin routing and exact
catcher restoration; the model does not implement these assumptions in C.
There is no global lock, disabled SMP or enlarged native budget.

Before a runtime patch is admitted, classify supported nested entry paths,
bind actual catcher/marker lifetimes and distinguish recoverable propagation
from fatal VM shutdown. Allocation/conversion failure, cancellation, error
handler reentry, C++ exceptions, processor incarnation reuse and all GC roots
remain open. A real migrated nested-error fixture and fatal-shutdown fixture
must demonstrate source reachability without retrying unrelated known hangs.

Two cleanups per two frames bound successful cleanup operations only. They do
not bound routing latency, retry count, memory contention or wall-clock time.
Full native suites, bootstrap, Gerbil correctness and unchanged performance and
stability gates remain mandatory.
