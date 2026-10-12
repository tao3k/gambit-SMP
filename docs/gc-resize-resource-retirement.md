# GC And Resize Resource Retirement

## Pre-Implementation Review

1. **Supported path:** GHC section 3.5 and HotSpot termination accounting
   distinguish empty queues from completed work. Gambit releases a stolen
   chunk's queue lock before scanning and has separate GC phase barriers.
   Its resize tree can publish to a fast receiver before unlock and signal
   complete. GC completion therefore is not a synchronization-resource drain.
2. **Previously explored:** work closure and resize-message retirement were
   separate verified slices. This composition checks a pending queue unlock
   across phase admission and separates three resource lifetimes. It does not
   rerun a failed native route.
3. **Worth repairing:** using one cleanup site for queue locks, sync resources
   and processor storage can introduce use-after-destroy. Source correspondence
   must establish which users have finished at each site.
4. **Expected benefit:** a correctly scoped repair and fewer incorrect trials.
   No speedup is estimated. Model search time is not runtime performance.

## Source Correspondence

Pinned candidate027 source is bound by the manifest. Key paths:

| Source | Implemented Ordering / Remaining Obligation |
| --- | --- |
| `mem.c:6926-6942` | Remote queue lock, pop, unlock, then scan; empty FIFO alone cannot stand for an operation's completion. |
| `mem.c:6955-6985` | Active-worker termination count is distinct from queue emptiness. Complete discovery and closure are delegated to `gc_work_closure`. |
| `mem.c:7223-7259` | GC phases have barriers; map their exit to the following outer sync round before treating queue users as quiescent. |
| `setup.c:1192` | Public GC uses `on_all_processors`; do not assume an independent per-processor public GC entry. |
| `setup.c:911` | Resize may call GC for heap capacity; this nested path is not covered by a simple GC-then-resize trace. |
| `setup.c:650-717` | Population update and downward messages use old-tree child identities. Published receive is earlier than sender unlock/signal completion. |
| `setup.c:940,984` | Retired worker cleanup precedes exit; processor 0 joins later. A retained non-root parent may still be sending to a retired child. |
| `setup.c:988` | Join return errors are ignored in this source. A successful-join premise is not a proof of this error path. |

## Executable Composition

`gc_resize_resource_retirement` contains GC queue claim/pop/unlock/scan,
per-participant GC arrival, resize-tree publish/unlock/signal/receive, child exit,
join, retained next-round admission and reclamation in one transition system.
Queue lock, sync mutex/condition and processor storage have independent liveness
sets. This is not merely adding dependency edges between separately run models.

The positive model keeps queue cleanup at child exit after GC work completion,
but defers sync/storage reclamation until retired joins and retained next-round
admission. These are abstract sufficient contracts, not implemented repairs.
It does not prove arbitrary cardinality or simultaneous multiple scan operations;
whole GC discovery and checked initialization remain delegated premises.

## Verified Campaigns

Campaign001 fixed the scanner at root and the owner at the last processor. It
passed 4,158 distinct states in 26.321 seconds, but cannot be used as role-complete
evidence. Its frozen snapshot and receipt remain historical.

Campaign002 parameterizes population 2..5, every legal retained prefix, and
every scanner/queue-owner pair, including self/local, remote, retained non-root
and retired scanners. The reviewed initializer has 170 configurations. The
current portable bundle is
`evidence/model-results/gc-resize-resource-retirement-roles-model/`.

Three independent controls reject destroying sync resources at fast child exit,
using queue emptiness as GC completion, and treating joins alone as storage
reclamation permission. The candidate passes safety and weak-fair progress:
94,386 distinct states, 297,221 generated, 0 queued, 51.443 seconds. Source,
paper, model and verifier inputs remained stable. This is model-only evidence.

## Open Runtime Gates

Refine actual outer-round alignment, nested GC during resize, join-error
ownership and C memory ordering. Combine these with VM callback retirement
and the outstanding full GC source obligations. Do not insert an unmatched
`BARRIER()` into one processor's branch, or infer message completion from GC
work termination. Runtime edits, native suites, full bootstrap and Gerbil
correctness/performance admission remain pending.

The existing compiler-cost receipt for the original `_num` fixture separately
records Scheme-to-C success in 30.818 seconds and C-module compilation killed
after 59.250 seconds within its 90-second whole budget. The frozen generated C
hash matches that receipt (152,462 lines, 5,487,425 bytes). The later runtime026
atomic suite denies `_num` at 298.950 seconds; it does not isolate the same phase
or prove a GC crash. Neither result is a native counterexample to this model.
No unchanged native retry or timeout expansion was performed.

## Next-Round Refinement

`sync_retirement_round_closure` refines the retained-next-round premise into the
actual next outer barrier's upward tree convergence, with its own source-bound
receipt. It depends on this GC/resize slice; no reciprocal dependency is added
here. The exporter and query reject cross-layer contract cycles, so two models
cannot close each other's assumptions by circular registration. Pending-round
identity, successful joins, repeated shrink/grow and nested GC remain required
engineering obligations. See `sync-retirement-round-closure.md`.
