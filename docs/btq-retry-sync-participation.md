# BTQ Retry Collective Participation Candidate

## Causal Delta

The sampled and source-mapped `##thread-lock-remove-btq-toq!` retry reacquires
the thread lock successfully while repeatedly failing the mutex/condition
variable queue trylock. Thus the existing failed-thread-lock helper is not
necessarily reached. The candidate checks `___INTR_SYNC_OP` after releasing
the thread lock, before retrying. It does not dispatch ordinary interrupts,
change queue ownership, remove assertions or disable concurrency.

The 21-file source lock inherits reporter-preservation exactly except for
`lib/_thread.scm`: candidate SHA-256
`0250e820e99119e15a37f0f77328244374b43baa04cda4ad862e161deb197541`.
Patch SHA-256 is
`2d6921e8b61535d2f270aaa6a63f3426c7e0afcac0d4c10e89179d60bd630540`.
Source authority remains the immutable submodule revision and lock, not the
diagnostic cache. No retained baseline is overwritten.

## Verified Results

The existing scheduler retry model, not a duplicate model, passed source-bound
parse/typecheck, safety and weak-fairness progress in the sealed framework.
Six distinct states were exhausted. Its unchecked-retry negative control
reproduced the safety violation. Whole recipe: 19.807 seconds. This is a finite
conditional abstraction, not source refinement or unique native attribution.

Fresh Bazel-profile full bootstrap passed in 301.573 seconds whole. Phase1-4
each completed twice. Seed core: 37.977 seconds; from-scratch: 139.726 seconds,
zero exit, no timeout, reaped and quiescent. The observed host selected make-j12
through adaptive capacity; all three concurrency switches and original
600-second cap remained. The completed reference is
`evidence/research/vm-registry-reader-lease/btq-retry-completed-producer.json`.

Retained refusals: missing sealed Quint, unavailable prior tool observation,
duplicate file entries in patch inventory, and incomplete bootstrap verdict
dependencies. None was interpreted as an executed native failure or removed
from the evidence tree. Corrected inputs were validated before bootstrap.

## Open Acceptance

The candidate now has bootstrap and complete gsi gates closed (2/12). Its own
379/379 files passed in 78.098 seconds whole, using the latest qualified UF
framework seal `ba611348c9e46fe58bca6e89180e4509abee5c45ac31ba02fab20506ddbbd205`.
Readback is CURRENT/PASS. All nine suite groups exited zero without timeout.
Its initial gsi attempt was correctly denied before native execution because
the inherited ended-interrupt source change still named old bytes. The new
candidate-specific causal evidence preserves that failure, baseline, budget,
model and terminal-unlock repair, while reviewing the four-line retry delta.
Three candidate/source/recipe integrity tests passed; these are not native
acceptance tests.

`smp-btq-retry-complete-topology-latency` passed in 40.596 seconds whole and
12.980 seconds native on the exact new producer. CPU-derived 2-5 VM populations
completed 1000/1002/1000/1000 samples. Original forced-GC/root/resize/join
assertions and original 300-second whole/120-second native caps were unchanged.
Readback is CURRENT/PASS; raw SHA-256 is
`ca24ee2746dec9971e7b1b37a2b311b9acc05ff78c3543e67087c0f23372183e`.

| Concurrent VMs | Samples | P55 ms | P99 ms |
| --- | --- | --- | --- |
| 2 | 1000 | 13.253 | 68.657 |
| 3 | 1002 | 5.645 | 30.393 |
| 4 | 1000 | 3.895 | 8.114 |
| 5 | 1000 | 3.655 | 8.460 |

These are nearest-rank correlated trajectories, not confidence intervals or
a release speedup. The previous producer timed out in its first population;
successful candidate runs are not proof of full stability or a precise speed
ratio. An independent repeat on the same producer and latest UF framework
passed CURRENT in 41.621 seconds whole / 14.388 native, again 4002 complete
samples. Its P55 ms were 13.432/5.739/4.057/3.612; P99 ms were
82.328/30.027/13.438/60.332 for 2/3/4/5 VMs. In particular the 5-VM P99 changed
from 8.460 to 60.332 ms: retain this tail variation, do not claim a stable tail
performance gate. Repeat output is `topology-stability-repeat` under the
semantic candidate fixture. Full fault/GC/FFI coverage remains required.

Full gsc, separately declared PR and stress campaigns, complete lifetime
and fault coverage, GC/FFI, current Gerbil and release performance remain open.
Neither a short topology success nor model/bootstrapping PASS will close those
requirements. The candidate is not a qualified replacement baseline yet.
