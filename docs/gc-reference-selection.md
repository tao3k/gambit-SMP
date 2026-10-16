# GC Reference Selection And Scoped Reasons

## Admission To The Comparison

A reference is useful only when it discriminates a concrete Gambit design
choice. Popularity, chronology and a model PASS are not selection criteria.
Keep the existing collector as the baseline. Do not transplant a collector.

| Reference | Specific question | Cost or incompatible premise to investigate |
| --- | --- | --- |
| Pinned Chez | Can segment ownership and remote re-sweep conserve work through repeated handoff? | Remote traffic/re-sweep; generated object-shape and memory-order correspondence remain open. |
| GHC ISMM 2008 | How do private scan blocks, exported work and active workers establish global termination? | Shared queue contention and publication; this is a paper implementation, not current GHC source. |
| Generational ZGC | Can barriers and relocation metadata reduce pauses without breaking foreign lifetimes? | Barrier coverage, allocation headroom, bandwidth, epoch reclamation, continuation roots and C accesses. |
| OCaml, screening only | Does preserving a mature C interface favor parallel STW minor evacuation over concurrent minor movement? | Its domain/heap/root conventions are not Gambit's Still objects or independent VMs. No new OCaml model is warranted yet. |

## Primary Material And Reading Depth

- Chez: `models/chez/source.json`, fixed revision and reviewed line ranges;
  unread obligations remain explicit. No whole-source claim.
- GHC: cached ISMM 2008 paper, sections 3.1-3.5 previously read in the
  comparison. Parallel collection is not mutator-concurrent collection.
- ZGC: Oracle JDK 27 GC tuning chapter reviewed for current generational
  status and allocation headroom. It is operational documentation, not a
  proof or a measured Gambit benefit:
  https://docs.oracle.com/en/java/javase/27/gctuning/z-garbage-collector.html
- OCaml: ICFP 2020 *Retrofitting Parallelism onto OCaml*, C-interface constraints
  in sections 1.2-1.4 and targeted read-barrier/evaluation passages inspected;
  OCaml 5.5 manual parallel-GC and C root-registration sections read. These
  targeted passages are not a complete section-by-section paper reading.
  No pinned OCaml source adapter exists.
  https://arxiv.org/abs/2004.11663v3
  https://ocaml.org/manual/5.5/parallelism.html
  https://ocaml.org/manual/5.5/intfc.html

OCaml's current manual describes parallel STW minor evacuation and concurrent
major mark/sweep with short STW phases. Root registration updates C-held values
when moved; field updates have prescribed interfaces. This makes C compatibility
a useful research discriminator, not proof that it supports arbitrary raw C
pointers or should replace Gambit's collector. The paper explicitly contrasts
its concurrent minor design's changed C read assumptions with parallel STW
minor collection preserving that interface, and evaluates both. That historical
result motivates a Gambit experiment; it is not a universal rejection of read
barriers, an ARM result, or a current Gambit performance prediction.

## Executable Boundary

`reasons.ss` derives scoped `why`, `why_not`, `unknown`, `tradeoff` and read-only
actions. Each answer retains the reference path and SHA. Missing support is not
refutation. A finite counterexample refutes only its modeled protocol profile,
not Chez, GHC, ZGC or an actual Gambit incident. Native obligations have distinct
IDs so literature support cannot discharge them. Source withdrawal removes
support, not the obligation. No rule derives acceptance, retry or authorization.

`DesignEvidence.qnt` checks this classification boundary; it does not model the
collectors. Existing epoch/visibility/payload/handoff models remain the mechanism
controls. The candidate lock is a declared source identity, not an executed
three-flag runtime receipt. Missing actual flag evidence remains visible.

## Runtime Qualification Still Required

All three flags must be observed on the same completed candidate. Check startup,
registration, allocation, GC, continuation/root transfer, FFI, retirement and
teardown together. Keep foreign stable payload, borrowed movable pointer and
callback return cases separate. The pending Scheme/C fixture is not a PASS.

Compare identical workload bytes, compiler/options, live heap, allocation volume,
VM/processor topology and hardware. Measure pause tails, throughput, total CPU,
memory reserve/RSS, single-worker overhead and C-call latency. Keep all failed
and timeout samples and instrumentation overhead. No new runtime design or
collector speedup is established by this evidence-classification work.
