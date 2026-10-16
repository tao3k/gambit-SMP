# BTQ Selection Across Ticket Handoff

## Decision Before Implementation

| Question | Assessment |
| --- | --- |
| Relevant? | The production ticket wait uses a volatile load without a post-wait acquire. BTQ callers read the sentinel minimum after primitive locking. |
| Already explored? | The ticket model abstracts a queue head; the operational tree model chooses deletion inputs from current members. Neither alone checks whether the caller selected a stale, already-cleared tree node. |
| Worth checking? | Yes: compose existing models before another expensive bootstrap. Do not repeat the allocator-only native candidate unchanged. |
| Expected benefit? | Reject an insufficient repair policy and identify the missing ordering contract. No native speedup, crash causality or measured investigation-time saving is claimed. |

## Composition

`models/gambit/btq_ticket_selection.qnt` imports the existing ticket actions
and the existing tree insertion, replacement, color and sentinel helpers.
The initial valid tree has black root 2 and red minimum leaf 1. The predecessor
removes leaf 1, clears its links/container, updates the minimum alias and
reconnects the parent's child. No deletion rotation is needed in this domain.

The successor's selected node comes from the ticket model's cached observation,
not nondeterministic selection from the current member set. Ticket head values
0 and 1 correspond to minimum nodes 1 and 2 in this finite composition.
The invariant checks that the actual selected node remains a member.

The ALLOC-only policy supplies no acquire to primitive BTQ locking. The queue
acquire policy refreshes the abstract observation at ownership handoff. This
is conditional on the existing ticket model's weak-memory abstraction; it is
not a C/ARM refinement proof or evidence that a specific hardware reordering
caused the native crash. Multiple mutations, ABA/node reuse, arbitrary trees,
collector relocation, real forwarding, and trylock are not covered here.

Source anchors: pinned `include/gambit.h.in` production
`___TICKETLOCK_LOCK2` and `___PRIMLOCK`; `lib/_thread.scm`'s
`##btq-abandon!` reads `macro-btq-leftmost` after primitive locking.
The allocator successor leaves the shared primitive unchanged.

## Native Constraint

The allocator-only successor completed both bootstrap passes, but the unchanged
compiled `06-thread/tfib_stress.scm` still failed with upstream exit LO=11.
Its native stage took 17.492 seconds; the upstream file summary reported
14.0 seconds. This does not locate the new crash or prove equivalence to the
parent BTQ crash. Exact source/producer/receipt bindings are retained in
`evidence/fixtures/darwin-allocator-acquire/compiled-tfib-observation.json`.
The observation does not itself implement a framework retry-denial rule.

Use the existing sealed research recipe
`evidence/research/current-source-full-bootstrap/btq-ticket-selection.recipe.json`.
Keep tool-path, parse, type-effect and TLA conversion failures in their original
receipts. They are model/tool integration failures, not native SMP failures.
No invariant, budget or release gate was weakened to accommodate them.

## Checked Result

The corrected composition completed in 22.743 seconds through the sealed
framework. ALLOC-only produced an invariant counterexample (15 states reached).
Queue acquire exhausted 13 distinct / 18 generated states with zero queued
and no invariant violation. This is finite safety, not liveness or hardware
proof. Exact bindings are in `ticket-selection-model.json` alongside the
other compiled-stress source results. The milestone remains 5/12.
