# GC Chunk Cursor Operations

## Why This Component

The retained origin trace records an 11-word vector-body scan with two visits
within one VM and strong-marking cycle: first own-FIFO on P0, then stolen-FIFO
on P7. Victim queue ownership and allocation generation are not recorded, so
address reuse is not excluded. At the old-space abort the scan context is
inactive and the failure cell lies outside that recorded body. The later
compiled BTQ SIGSEGV is separate; no shared cause is asserted.

Before implementation:

| Question | Answer |
| --- | --- |
| Relevant path? | A local cursor, a queued chunk and a stolen chunk can reach the same physical arena. Their handoff is directly relevant to explaining or excluding repeated scanning. |
| Already modeled? | `gc_scan_claim_transfer.qnt` models an abstract ownership handoff. `continuation_export_origin.qnt` classifies publication eligibility. Neither executes the candidate's in-memory chunk links, saved/local cursor distinction and recursive allocation together. |
| Worth optimizing? | First establish correctness of the producer/consumer protocol. Do not change export timing or add a global lock from an abstract counterexample. |
| Expected benefit? | Narrow the next source audit/native observation to an unexplained operation. No measured runtime or investigation-time improvement is claimed. |

## Source Identity

The authority is the pinned Gambit revision plus
`patches/fixtures/darwin-dynamic-modulo-scope.patch`, checked by
`evidence/fixtures/darwin-dynamic-modulo-scope/source.lock.json`.
The candidate `lib/mem.c` SHA-256 is
`38b69316dc682ac6771904a976af00547f9c628a78752e6448d3f1171be53dcd`.
Candidate line numbers below refer to that reconstructed file, not the
different baseline file in the submodule and not a disposable fixture path.

| Source | Model |
| --- | --- |
| `next_msection_without_locking`, 3217-3278 | P0 rollover and a peer request advance the same VM free-list cursor under the caller's allocation lock. The fallback is P0's own stack section, not its old heap section. |
| `set_heap_msection_possibly_sharing_with_stack`, 3513-3560; `prepare_heap_msection`, 3566-3593 | Reproduce the quarter-gap arithmetic, reserve two end markers, initialize the new section prefix and chunk cursor. |
| `start_heap_chunk`, 3389-3396 | `allocate` updates start/limit after writing a complete-chunk marker. |
| `publish_heap_chunk_segment`, 3413-3444 | Append through the actual tail link, then replace the tail endpoint in one lock-protected transaction. |
| `end_heap_chunk_segment`, 3447-3487 | Test saved `scan_ptr` membership after writing the marker; either retain local ownership, publish, or append to a private frame segment. |
| `mark_array`, 3733-3741, 3802-3810 | Recursive allocation may close a chunk or move its start before the scanning caller advances its own local cursor. |
| `mark_captured_continuation`, 3882-4008 | Keep the copied frame-link field pending, build private links, resolve before publishing the segment. Queue consumers do not acquire `MISC_MEM_LOCK`. |
| `scan_complete_heap_chunk`, 4448-4472 | Stop at the physical marker; scan a task cursor independent of the caller's saved cursor. |
| `scan_movable_objs_to_scan`, 4527-4582 | Save the boundary, claim through the FIFO head, finish queued work, then resume at the current incomplete chunk start. |
| `mark_reachable_from_marked`, 7150-7183 | A thief advances the same protected head before scanning the claimed payload. |

## Executed State

The model stores word addresses, header/marker kinds, physical FIFO links,
allocation/start/limit addresses, saved scan boundary, caller cursor, nested
queued-task cursor and thief cursor. It also stores the frame producer's
private first/last pointers and pending link fields.

Each object has an eager-owned field and one modeled scanner-owned field.
The latter starts as an old-space input, becomes redirected when scanned and
must not be scanned again in that cycle. A pending captured-frame link has a
distinct invalid-input state. Visit counters and field states are observations
checked by the invariant; they **never guard or suppress** scanning actions.
The model does not execute the raw forwarding CAS or prove canonical object
copying from these field-state transitions.

The allocator belongs to P0. P1 steals from this arena; it never allocates into
P0's cursor. P0 may allocate recursively while scanning either its local chunk
or its own queued chunk. Root copying precedes the existing traversal barrier.
Ordinary and captured-frame copying are both initial domains, not a fake
global serialization of all collector work.

Controls mutate six source operations:

- Publish even when the saved cursor still owns the chunk.
- Delay the thief's head update until after scanning.
- Resume local scanning at the old arena start instead of the incomplete chunk.
- Publish captured-frame chunks before pending frame links are resolved.
- Rollover into an already-used heap section instead of a fresh/own-stack section.
- Let the peer reserve a section without advancing the shared VM allocation cursor.

These are sensitivity controls, not claims that the locked candidate contains
these exact errors. The last also characterizes the already-known unsafe
publication ordering; it does not authorize repeating an old native failure.

## Remaining Composition Requirements

- This component has one payload arena, at most six small objects, two objects
  per chunk and two scanning roles. A second allocating role issues at most one
  request against the same VM cursor. These are finite model bounds, not CPU/worker limits.
  TLC workers are selected adaptively by the framework.
- One heap-section rollover executes both fresh-section and own-stack fallback
  domains. It closes even an empty trailing chunk, so adjacent physical markers
  participate in ordinary FIFO scanning. Per-address allocation generations
  and a sticky reuse check are observations, not allocation guards.
- The finite arithmetic instance has 32-word sections, 16-word semispaces,
  fudge 1 and stack bottom 46..48 in the stack section starting at 32. No
  equivalence to all actual section/fudge sizes is claimed. Fatal exhaustion,
  full stack allocation, custom allocation, repeated GC epochs and epoch/address
  reuse remain unexecuted.
- Initial reserved sections precede free cursor 128. A peer can reserve before
  or after P0's rollover; disjointness is checked against its claimed interval.
  The peer's payload graph and cross-arena aliases are not modeled.
- This is sequential consistency above existing queue-lock release/acquire;
  relaxed unlocked hints and C weak memory remain separate obligations.
- Forwarding CAS losers, object headers, all actual payload layouts, eager
  recursion and weak/continuation root closure are not proved by the field-state
  abstraction. The private-segment path does not prove full stack-frame layout.
- Completion means this arena and its claimed tasks drain under weak fairness.
  It is not a proof of `scan_workers_count`, condition-variable wakeup, every
  VM lifecycle or a performance measurement.

The correct interpretation of a positive result is that these reconstructed
cursor/FIFO operations did not generate the duplicate in this finite domain.
It is not evidence that the actual diagnostic failure disappeared. Keep the
native failure open and refine the unmodeled allocation/origin or producer
interactions before selecting another native experiment.

## Initial Verification

The existing sealed framework checked the combined ordinary/frame-copy model:
**1,029 distinct states, 2,609 generated, zero queued**, safety and weak-fair
completion PASS. All four concrete mutation controls produced invariant
violations. In the early-private-publication trace, the thief reads while P0
is still in `callback-local` and physical fields 10 and 13 are pending; the
invalid-input flag changes only at the actual thief field read.

The whole child run took **42.256 seconds**; the positive TLC invocation took
**4.536 seconds**. No bootstrap, runtime patch, stress retry or speedup was
admitted. Exact hashes, timings and remaining requirements are in
`evidence/source-results/compiled-stress-failure/chunk-cursor-model.json`.
The initial ordinary-only run (505 states) is retained separately. The first
combined attempt failed parsing because a local binder shadowed Quint's
`fields` builtin; it did not execute model checking or native tests.

The bound observation is now part of the existing BTQ edge-integrity Evidence
view, without a new inference backend. Its three source/native obligations
remain open. Removing this model's source support withdraws its model context
without erasing the native DENY. BTQ/concurrent-GC/view regression modules
passed **18/18, zero skips, 17.228 seconds** through the receipt-bound ASCENT ABI.
This does not change the **5/12** native milestone count.

## Section And Allocator Composition

The strengthened model includes the rollover, own-stack gap, empty chunk and
shared allocator operations above. It explored **16,239 distinct states**,
46,083 generated, zero queued, with safety and weak-fair completion PASS.
All six mutation controls fail their invariants as expected. The positive
check took **7.247 seconds**, the whole child framework run **57.648 seconds**;
stage limits were unchanged. The intermediate section-only check (8,766
states) remains a narrower historical observation.

This is still not the native duplicate-scan origin. It narrows which extra
information is needed from a future diagnostic: first/second origin and
physical allocation generation must be bound, rather than inferring a missing
allocation lock or replaying the unchanged abort. Full payload copying and
cross-arena aliases are the next uncomposed protocols.
