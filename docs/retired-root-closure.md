# Retirement Root Closure

## Source Obligations

The selected source is pinned by
`evidence/fixtures/vector-increment-arity-parity/source.lock.json`, not by an
ephemeral build directory. Its `lib/mem.c` implementation of
`___transfer_mem_pstate` transfers the still-object list, RC list, accounted
still words and deferred still words. Its GC independently initializes still
roots, marks RC roots and sweeps still objects. An RC-only handoff therefore
does not establish complete retirement root closure.

The transfer's caller must establish donor quiescence and borrower drain.
This work does not replace that prerequisite with a pre-`pthread_exit` flag.
The exit-tail refutation remains in `retired-rc-exit-tail.md`.

## Executable Model And Native Binding

`models/gambit/retired_root_closure.qnt` imports and executes the existing
`retired_rc_gc_visibility` transitions. It adds an independently retained still
object and its movable child, plus two conserved accounting quantities.
The complete policy requires all three invariants: the original RC protocol,
still-root closure and accounting conservation. RC-only and dropped-deferred
policies are separate negative controls. The bounded integers denote word
tokens, not machine capacities or thread limits. Pending-join closure in the
model is conditional on its donor-quiescence premise; the runtime has not
implemented that failed-join repair.

`models/gambit/native/retired_root_closure.scm` uses standard Gambit FFI APIs
on the exact completed source toolchain. Each actual nonzero processor creates
a referenced still pair and a movable vector. The still allocator receives
only immediate arguments, respecting `___make_pair`'s nonmovable-input contract.
After allocation, a non-GC RC registration and pair-field publication retain
the vector through both independent root paths.

After successful shrink to P0, forced GC must update both roots consistently.
The test releases every RC handle, forces GC again and verifies relocation
and contents using only the still pair's positive reference count. It then
releases every still reference and forces a final GC. Population is obtained
from the actual VM; framework concurrency is host-adaptive. There is no join
interposition, private cleanup, reduced SMP configuration or fixed CPU count.

This is an actual successful-retirement GC test, not a reproduction of the
failed-join/post-GC defect. The abstract accounting invariant is not measured
by this native test; no full source refinement is claimed.

## Verified Receipt

Recipe: `smp-vector-arity-retired-root-closure`.
Run: `retired-root-closure/explicit-initializers-model-native-run` in the
framework fixture store.

- All fourteen required steps passed; outer wall time 51.702050 seconds.
- Original budgets retained: whole 300, native stage 120, execution 30 seconds.
- Safety and enabled-progress checks: 15 distinct / 18 generated states,
  zero states queued. These are finite checks, not scheduler fairness proofs.
- Both declared negative controls produced counterexamples.
- All nine exact trajectories passed, including five imported RC trajectories.
- Native compilation 2.128501 seconds; execution 0.634107 seconds, exit zero,
  exact `RETIRED-ROOT-CLOSURE:PASS` output, no timeout, reaped/quiescent groups.
- Current host selected eleven runtime processors; this is an observation,
  not a hardcoded capacity.
- Source transfer: 2,092 COW files, zero byte-copy files. Runtime transfer:
  2,243 COW files, zero byte-copy files. No bootstrap was rerun. Logical sizes
  are not physical APFS allocation measurements or speedup evidence.

Outer receipt SHA-256:
`6dc042258bf0b0e3a71f0cdb71ce3b89978248d9b4b21bd37e2e308b224d5a46`.
Child receipt SHA-256:
`5a3b3668331c483cfb8ef5c5fc6abfe32c505cf80e97fb49d10c8a1214b7f7bb`.
Engine: `be2acb890384e5bcf8e36535f02a7c2282bc9d0b5777f1cd0f5210af21109eb8`.
The v2 engine remains a bounded diagnostic seal, not a qualified full
105-review/current consumer graph.

The first `model-native-run` remains DENY. Quint accepted the parameterized
initializer at typecheck but rejected its TLA+ conversion with QNT409.
The exact test inventory also correctly rejected omission of imported tests.
Explicit initializers and all nine tests corrected those two concrete defects;
no invariant, expected failure, workload or budget was weakened. The blocked
native stage in that first run is not counted as execution.

## Remaining Requirements

SMP milestone coverage remains three of twelve complete gates. This receipt
adds partial GC coverage, not another complete gate. Failed join followed by
GC, complete exit-tail admission, permanent-failure ownership, concurrent FFI
mutations and source refinement still require a verified runtime protocol.
The full GSC/PR-GSC/stress suites, registry lifetime, lifecycle faults,
GC/FFI, Gerbil correctness and release performance remain open. New evidence
must be bound through the existing Scheme DSL/ASCENT review rather than
promoting this diagnostic PASS to global SMP green.
