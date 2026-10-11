# HotSpot Parallel GC (JVM 2001)

Source: [Flood, Detlefs, Shavit and Zhang](https://www.usenix.org/legacy/event/jvm01/full_papers/flood/flood.pdf).
Reviewed PDF identity: `evidence/papers.lock.json`, `hotspot-parallel-gc-2001`.
These are repository-owned analysis notes, not the paper's full text.

## Protocol Obligations

Sections 3.1-3.3 separate root distribution, parallel traversal and termination.
Private and shared work both matter to the work-producing population. A worker
that can discover further reachable objects is not globally idle. Section 4's
speculative forwarding claim does not itself mean copied payload is readable.

## Gambit Correspondence

Use the traversal/accounting questions to audit `mark_array`, `end_heap_chunk`
and `mark_reachable_from_marked`. Gambit's chunk queues, local allocation
frontiers and mutex/condition protocol are not the paper's deque. Distinguish a
missed helper notification from global deadlock; a counted producer can drain
local work. Do not add queue-to-termination lock nesting against an inverse path.

## QNT And Open Gates

Retain counted producers, unique scan claims, payload readiness and independent
fault controls. Real OS wait errors, resource lifetime, C ordering and phase
transitions remain source obligations. This comparison supplies neither a
Darwin-only bug diagnosis nor a measured speedup.

Detailed chapter audit: [reading ledger](../paper-source-reading-ledger.md).
