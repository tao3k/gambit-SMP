# Retirement Window Research Validation

## Result And Identity

Current source profile: unchanged mutex-return lock
`df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466`, patch
`49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`.
This is not a refresh of the implementing thread's newer candidate or native
qualification. All original root/arena/isolated models and receipts remain
unchanged. The new model imports those source protocols.

| Input | SHA-256 |
| --- | --- |
| New model | `ada6f75c7b9107103de713892d11953c2fe0a1c03a22b77989cb8d6474ce03c0` |
| New Lean companion | `5afc049d860549e74b5c10d4ed08ff7c9dc8f22b13e457c327d45ed1e9596e8a` |
| Recipe | `d94543006d57aad3392c53d05498d4acca550f3b4937ab78a747f424c1cada80` |
| Manifest | `17c6b68c1b9b466eccef2c1ee63fb39c458ae4c67f7a0aacffbfce6f416d11dc` |

## QNT Results

Existing campaign `host-root-research`, run
`2c64cc14e96d4cb9815167bbaaa1da2c`: **6/6 accepted**, context stable,
150.244 seconds total, native `not-run`, runtime not admitted. Raw receipt SHA:
`273773966850c85cf62a7810f0f27ad24356ce4839514a2c54dca7e9b5d587e0`.
It is retained under that run's
`outputs/host-root-publication/retirement-window/receipt.json`.

| Check | Result meaning | Seconds |
| --- | --- | --- |
| `queueCoverage` | A stale empty snapshot admits retirement after a bounded enqueue | 39.656 |
| `admissionCoverage` | Foreign-frame admission is incorrectly accepted without Scheme producer quiescence | 48.192 |
| `fullPhaseCoverage` | Strong done, raw origins resolved and target work empty still do not imply weak/cleanup done | 48.619 |
| `noValidEmptyRetirement` | Positive witness: stable, scoped empty queues permit non-GC return | 46.069 |
| `noTransferredQueueReturn` | Positive witness: abstract valid transfer permits non-GC return; not a claim that C implements it | 31.718 |
| `windowSafe` / `windowCompletion` | Corrected cohort safety, no stuck nonterminal state and weak-fair completion | 20.669 |

TLC enumerated 502 distinct states / 738 generated, depth 23; the positive TLC
phase finished in two reported seconds. Whole-check figures include compilation
and launcher overhead. They are not runtime benchmarks or stable model-speedup
measurements. Scheduling used existing host-adaptive defaults, not a fixed
processor count in the model.

The corrected cohort freezes the declared producers before its scoped empty
snapshot. Per-field read permutations are collapsed only under that premise;
this is an abstraction, not a source bisimulation proof. The bounded arrival
affects the run role; the other declared queue classes are assumed empty.
Previously qualified root-model fault cohorts stutter instead of being explored
again. New window omissions are not suppressed. Every real returning-cohort
move updates the bounded ghost rank; terminal stuttering does not increment it.

`freezeProducers`, `transferQueue`, complete physical roots/aliases, publisher
activity and C barriers still require source binding. No action name establishes
its implementation. Physical section contraction and configured-cap arithmetic
are not state-refined by this QNT projection.

## Lean Results

Seven declarations passed the unchanged 15-second process guard, 200000
heartbeats and recursion bound 512. Focused guard test: exit 0, 3.713 seconds,
no timeout, process group quiescent. Raw `lean-ol86dlik/receipt.json` SHA:
`659282a23bde286475aab31ef9a4b3575de3f2d80e9993e3cd5db6c2734f24bd`.

The stable-empty, foreign/Scheme independence, non-consuming origin,
phase-transitivity and complete-origin lemmas are axiom-free. The two
cap/floor arithmetic lemmas use `propext`. No declaration uses `sorryAx`.
Their arithmetic assumes valid non-overflowing counts; it does not show a
reachable native GC state with an incompatible cap.

## Source Addendum: Join Publication Is Not Processor Idle

This completes the caller-window discussion in the Recipe without promoting
join-before-shrink fixtures to full empty-queue evidence.

Candidate `_thread.scm:1730-1743,1779-1839` clears the thread end condition and
publishes the result while holding the thread lock. It removes thread-group
membership and abandons owned blocked queues before unlocking. Thus a join
reader that takes that same lock cannot treat an early internal flag store as
an independently visible completion before that locked cleanup.

But `##thread-join!:1918-1984` can observe the unlocked terminated state and
return while the target still has its end-condvar notification call and
processor `current-thread` clearing ahead of it. Abandonment/notification may
also make other threads runnable. The target's Scheme join is therefore not
an OS join of its processor, an idle-scheduler witness, or completion of every
awakened thread. This is a concrete last-consumer/producer-scope condition;
no native failing interleaving is claimed here.

The two read-only fixtures bound by the manifest join user workers before
shrinking. That limits their scenario; it does not by itself prove all five
queue/current-activation classes are empty through retirement. The Recipe's
supported-scope handoff must cover these tails or explicitly state exclusions.

## Preserved Failed Attempts And Watchdog Boundary

The initial typecheck attempted to access unexported component state `a`.
It was replaced with a ghost prefix projected from the existing five ordered
transitions. No imported model or framework export was changed.

| Run/receipt | Retained outcome |
| --- | --- |
| `34534eb78fff4d3ea1c85bfd21bd7248` / `48a8353717ee78a0e3f274a6a503959b6e58d805f343839f1f40926a857853ae` | Two compilation timeouts at the initially selected 30-second combined-check limit |
| `729ff0730201428496c3efce7f87eef0` / `23a9d8864aaac4f04d51591dc3f8ac5cbd313f2f675d1c1d9c27a221f35e9c58` | Two decoded negative controls accepted, then two TLC timeouts; incomplete, not a whole-model pass |
| `46ff32a677a2450db5c8281c2599f646` / `0411d9c2963a9e317068c33d3566d55718e934c7027ca7d110a91f64c3fb4db2` | Reduced model reached TLC startup, then timed out at 30 seconds; not a deadlock counterexample |
| task run `af26d8f41d604580946878cacdc9073a` / `133479210f29ab415c838d0803e52bf2c037d23feeb7f42089334542645e428a` | Shared framework import failed before checks (`task_processes.run`); current import was separately confirmed available, then this research task alone was resumed |

A redundant nested `enabled` expansion was removed and equivalent frozen
snapshot permutations were collapsed. These changes did not remove the new
negative traces. The final formal campaign used the verifier's existing
**90-second default research watchdog**, rather than claiming to meet the
initial 30-second wall-clock diagnostic. Earlier statements that the 30-second
limit would remain unchanged are superseded by this explicit correction.
No native stage budget, performance gate or runtime watchdog was changed, and
no old timeout receipt was relabeled as a pass. This is not a 30-second formal
performance qualification.

The first five-lemma Lean prefix passed. Adding cap arithmetic then failed
because `Nat.le_min` is an iff, not a two-argument constructor; the failed
`lean-t8vvpxr0/receipt.json` remains with SHA
`a9e216d7fe2dc00835faf635b33845e7447a64413a0ea9709a87810262744b38`.
The proof now uses the forward constructor of that iff and all seven pass.
Failed elaboration's `sorryAx` output was never admitted as a proof.

## Reproduction

```sh
quint typecheck models/gambit/saved_stack_retirement_window.qnt
.venv/bin/gambit-smp --task host-root-research verify \
  --manifest evidence/research/host-root-publication/retirement-window.manifest.json \
  --out .cache/host-root-publication/retirement-window --timeout 90 \
  --tlc-liveness final --tlc-jar "$TLC_JAR"
.venv/bin/python -m unittest tests.test_saved_stack_retirement_window \
  tests.test_saved_stack_root_closure tests.test_saved_stack_arena_evidence \
  tests.test_host_root_candidate_evidence tests.test_host_root_publication_evidence \
  tests.test_repair_redesign_evidence -v
```

Native execution, complete current graph/CI, empirical performance, busy-queue
shrink semantics and mechanism-level Experimental redesign remain separate.
