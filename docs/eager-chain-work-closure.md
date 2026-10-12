# Eager Chain Work Closure

## Review Before Runtime Changes

This is a source-shaped correctness refinement, not a performance candidate.
Expected speedup is unknown. Existing work-closure models represent abstract
graph work, and the eager/tail partition model covers one object. Neither covers
the concrete sequence where eager marking discovers and exports another object
after an earlier tail has already been handed to a scanner.

Do not interpret `gc_scan_claim_transfer` as forbidding all producer activity
after export. Its exclusive claim applies to the transferred field interval;
the eager first field is outside that interval. The registered source-specific
`eager_tail_scan_partition` contract retains this legal overlap. No old model
or hash-bound receipt is rewritten to pretend it originally modeled the split.

## Paper And Source Correspondence

GHC section 3.5 and HotSpot section 3 distinguish pending-work emptiness from
completed tracing: an active producer may still export work. Their termination
principle does not prescribe Gambit's queue layout or prove its C synchronization.

In candidate027 `mem.c:3753-3775`, full object copying precedes chunk export;
`cell` retains the first destination field and `goto again` continues marking it.
That field may point to a fresh movable object, repeating allocation, copying
and export within the same `mark_array` call. `scan:4324-4327` and pair scanning
skip the corresponding first field, so a remote scanner may legally finish the
earlier tail before the eager chain finishes.

`mark_reachable_from_marked:6883-6987` completes local still/movable scanning,
claims queued chunks, and calls `scan_complete_heap_chunk` before reaching the
idle-count decrement at line 6957. `mark_array` performs no such decrement at
export. The model preserves that structural fact. Its fault control is a proposed
bad optimization, not an accusation that the selected source already idles there.

## Finite Composition

The model explores chain lengths 1..3 and 2..4 workers. Each object has one eager
edge and one immediate tail field. Worker zero owns the eager chain and cannot
claim tail work until its marking call returns. Other workers may become idle,
wake and consume published tails while the producer reserves/copies further
objects. Atomic queue claims and abstract count/wake operations are assumed.

The positive requires all heads and tails completed, producer returned, queue
empty and no active scanners before strong termination and weak-phase entry.
Two independent negative controls idle the producer at export or begin weak
processing early. Weak-fair progress does not prove actual condition-variable
signaling, infinite graphs, allocation recovery or native scheduler behavior.

## Remaining Gates

General graphs with aliasing/cycles and references in tail fields, multiple eager
producers, CAS losers, allocation failures and heap reuse remain open. The actual
count/condition-wait protocol needs separate source refinement, as does C queue
publication. Nothing here explains the historical repeated vector-body scans.
Do not rerun those denied routes or serialize all chunk export on this evidence.
Native regressions, full bootstrap and Gerbil full correctness/performance gates
remain required after an admitted source repair.

Campaign001 was denied at parsing because a local `length` shadowed Quint's
builtin. Its snapshot/log/receipt remain in `.data/eager-chain-work-closure-001`;
it contains no accepted protocol evidence. The subsequent model renames only
the local to `chainLength`, preserving the state transitions and constraints.
The portable diagnostic summary is
`evidence/model-results/eager-chain-work-closure-parse-deny.json`; it is not a
counterexample or model admission.

Campaign002 has stable model/source/paper context. Both independent controls
produce invariant violations. Positive safety and weak-fair progress completed
over 2,664 distinct states, 10,084 generated, zero queued in 32.957 seconds.
Portable hash-bound evidence is in `evidence/model-results/eager-chain-work-closure/`.
Host capacity determined the verifier workers; no runtime thread limit was set.
Native execution was not run; runtime and release admission remain false.

After registration, the eager-chain, retirement-generation, result-distribution
and constructor-contract test modules passed 15 framework tests in 22.943 seconds.
These are model/evidence/framework checks, not native GC or bootstrap acceptance.
