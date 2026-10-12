# Foreign Call Admission Before Processor Retirement

## Source Facts And Decision

`___run` and generated `BEGIN_SFUN_*` both create stack markers, but the former
is a runtime entry and the latter surrounds an external C-to-Scheme invocation.
Counting every marker as a foreign borrower would prevent normal worker exit.
`___make_sfun_stack_marker` alone cannot classify these callers by whether its
procedure argument is false: generated calls and runtime entries can both pass
a procedure. Admission must be tied to caller semantics, not that heuristic.

The current generated callback C, bound by the physical-relocation archive,
calls `SFUN_CALL_SCMOBJ`, handles result conversion, then ends through
`END_SFUN_SCMOBJ`. That macro kills the marker on the sequential tail. Inside
`___call`, `BEGIN_TRY/END_TRY` catches a trampoline throw, restores the prior
catcher, then propagates an unexpected unwind to the caller. `ON_THROW` in the
embedding fixture can catch it outside the generated SFUN invocation. Under
the setjmp implementation a nonlocal throw can bypass sequential tail code;
the C++ configuration has a separate exception mechanism.

This audit does not demonstrate native stale-marker exploitation or a supported
concurrent embedding schedule. It establishes why inserting an increment at
entry and a decrement at the existing END_SFUN tail is not an adequate design:
allocation failure and nonlocal exit require explicitly owned rollback/cleanup.
Existing root-allocation and result-preservation fixes remain unchanged.

## Proposed Protocol Model

`foreign_call_admission.qnt` is an unimplemented reference protocol. Two foreign
call tokens are distinct from the runtime-entry frame. The positive initializer
explores all nine allocation/normal/nonlocal-outcome combinations and all
enabled action interleavings. Admission and close are atomic model operations;
this is an implementation obligation, not a property of today's C code.

The closing operation either seals zero-borrower admission or returns a busy
outcome **before** any collective quiescence. Busy does not block callback
execution. Previously admitted calls retain ownership through marker
allocation, Scheme execution, conversion or exception handling; cleanup clears
the marker and releases the lease exactly once. Calls arriving after closing
are rejected without touching retired storage. Closing after acknowledged drain
permits retirement. Modeled errors remain recorded rather than becoming a
successful invocation outcome.

Negative controls cover split check/increment, counting the runtime entry,
allocation-failure leak, nonlocal-unwind leak and false shrink success despite
outstanding calls. These differ from the previous composition's heap-only,
early-marker-kill, processor-ID-reuse and wait-inside-collective controls.

## Performance Boundary

Ownership bookkeeping is on external SFUN admission/release, not every Scheme
allocation, scan or copy. The model bounds successful ownership updates to two
per admitted token; **it does not bound CAS retries or native instructions**.
Contention, failed attempts, cache-line placement and actual invocation rates
must be measured. A per-processor/incarnation design is preferable to a global
lock across C calls or GC, but placement and memory ordering remain unproved.

Atomic acquire/close may be implemented with a reviewed word/state protocol,
but wraparound, retirement generations, publication order and allocation-root
interactions must be modeled and source-bound before code is accepted. A
plain count check followed by a separate increment is explicitly rejected.

## Open Requirements

Runtime-entry versus SFUN classification must be source-bound for every wrapper
kind and dynamic C closure. Every normal, conversion-failure, allocation-failure
and nonlocal exit needs a current-origin, exact-once cleanup witness under both
supported exception implementations. Cancellation, nested stack discipline,
multi-VM embedding, pstate generation reuse and real collective-result/error
distribution remain open.

The finite two-token progress proof assumes no unbounded stream of new calls
and fair protocol scheduling; it is not a wait-free proof or OS guarantee.
Complete GC/retirement composition, full native suites, two-pass bootstrap,
Gerbil and unchanged performance/stability gates remain required. No source
admission counter has been added and no source/native/release green is claimed.
