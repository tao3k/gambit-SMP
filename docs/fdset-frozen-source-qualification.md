# Frozen Source Qualification

## Identity And Execution

The candidate is the 23-file `fdset-abort-owned-rollback` overlay, pinned to
Gambit revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Source-lock SHA-256:
`c81d31ec44b016e2d5a3ab92ea27b99d4595571f266d39b7c114d2f224c59754`.
The existing source workspace was reused; no second source checkout was made.
The Bazel profile and GNU GCC were retained, with SMP, multiple VMs and
multiple threaded VMs enabled. Bootstrap selected 12 make jobs from the
observed host capacity, not a fixed CPU constant.

The initial bootstrap recipe reached successful configure and seed stages,
then rejected an outdated header hash in its causal-review intent. Its
78.466963042-second DENY remains unchanged. Successful seed custody was
validated through the existing checkpoint interface; configuration and seed
compilation were not repeated.

The corrected checkpoint bootstrap passed in 155.726185875 outer seconds;
the bootstrap stage took 137.015630875 seconds. All four phases executed twice.
The two attempts total 234.193148917 seconds, below the explicitly approved
600-second build scope. The checked producer is
`evidence/research/current-source-full-bootstrap/fdset-completed-producer.json`.
Its outer receipt hash is
`bcee582978eda0773c06b1d36546101a1c6c8dd7559601ee39c6260ad02e93a5`.

## Complete Interpreted Validation

The exact producer passed all 380 standard/PR/diagnostic files in
62.537291917 outer seconds; the native suite stage took 10.470147084 seconds.
The shared host plan selected three workers and three processors per worker.
The preceding sandbox loopback refusal (0.366055500 seconds) remains retained;
the retry used the original budget and actual localhost permissions.
This requalifies the existing bootstrap/GSI/PR-GSI gates: cumulative 3/12.
Complete GSC, stress, lifetime, faults, GC/FFI, Gerbil and release gates are
not admitted by these results.

## Checkpoint Transport Repair

Bootstrap legitimately changes its imported seed workspace. Requiring the old
seed bytes to remain executable at producer export made successful bootstrap
unexportable. Historical ancestry now validates the immutable journal, retained
tree-state evidence, input/tool hashes and captured import identities instead.
Actual checkpoint import still requires available, matching live artifacts;
completed producer export separately checks the final runtime generation.
The in-place materialized epoch is compared to the imported seed epoch, not
the original pre-configuration epoch. Missing unarchived artifacts and altered
retained-state evidence still reject. Focused transport tests passed 52/52;
the four actual ASCENT milestone-query tests also passed.

## Watchdog Policy Correction

The human clarified that ordinary time limits prevent stalled phases; they
are not lifetime research quotas. A new attempt starts a fresh phase timer.
Prior attempts remain immutable cost/failure observations, not deductions
from later watchdog allowances. A cumulative execution quota requires a
separate explicit human constraint. Correctness timeouts, observed deadlocks
and performance-gate failures must remain distinct classifications.
The existing framework now implements an explicit `progress` timeout policy.
Only completed compiler phases or completed test files renew its inactivity
window. Log volume, repeated counters, timestamps and heartbeats do not renew
it. A progressing attempt is not killed for exceeding total elapsed wall time.
Historical sealed recipes retain their original semantics and receipts; they
are not silently reinterpreted. Release performance thresholds remain separate.

The complete GSC campaign demonstrates the policy error. Its first attempt
spent 54.654236125 seconds before native execution and rejected a stale causal
claim's change identifier. A corrected intent passed ASCENT review, but the
old cumulative policy left a 240-second outer allowance. That run was killed
at 240.832762500 seconds. Its retained progress contains 66 successfully
completed files and no failed completed batch. This is incomplete GSC
qualification caused by the outer deadline; it does not establish a Gambit
deadlock, a complete suite failure, or full correctness. The raw DENY/timeout
receipts remain unchanged. Neither this partial coverage nor the watchdog
policy correction adds a native gate; cumulative completion remains 3/12.

The subsequent per-stage wall-clock campaign completed 161/379 files before
its 300-second stage limit expired. Its numerical file also exceeded its
90-second wall limit. These observations remain incomplete qualification,
not evidence of a runtime deadlock. The newer progress policy does not turn
either historical failure into a pass.

## Completed-Work Watchdog Validation

The focused framework regression suite passed 134/134 tests. Actual subprocess
tests establish both that advancing completion can exceed the nominal wall
window and that repeated identical counters still time out and are reaped.
The QNT completed-work watchdog model explored 2,444 states with no remaining
queue, checked temporal completion, and retained two negative controls for
false wall-quota termination and noise-based renewal. Its four checks were
published through the existing ASCENT-backed protocol evidence interface at
`evidence/model-results/fixtures/stage-watchdog-retry/completed-work`.
This is model/framework evidence, not an additional native milestone.

The current frozen producer also passed the original numerical test assertions
through the existing compiler-observation capability:

| Phase | Seconds |
| --- | ---: |
| Scheme to C | 4.925 |
| GNU GCC to dynamic module | 76.623 |
| Compiled module execution | 0.804 |
| Whole diagnostic attempt, including preparation/review | 110.897 |

Recipe: `evidence/research/current-source-full-bootstrap/fdset-numeric-progress-diagnostic.recipe.json`.
The outer receipt SHA-256 is
`b09cbfd2275dd12496f870451e213543f5f5fd7e0ff7d51b341933afdb1dafcd`;
the child receipt SHA-256 is
`b36a9cdbf34ee14085cb1fea7f34ab80c9e83a2d091eda97c25466bf1c409aec`.
Each real compiler phase received an independent inactivity allowance. The
diagnostic explicitly disabled modulo scheduling, loop rescheduling and
second instruction scheduling for this dynamic-module invocation. SMP and
multiple threaded VMs remained enabled; the default release profile was not
changed. This isolated result is neither a matched speedup claim nor complete
GSC qualification, and cannot be merged with partial default-profile coverage
to claim a complete suite pass. Cumulative completion remains 3/12.

## Complete Inventory Under Inactivity Watchdogs

The first complete-inventory attempt using the approved inactivity semantics
finished in 567.811949916 seconds. All twelve groups were observed and the
process group was reaped and quiescent. The outer supervisor did not time out.
Eleven groups accepted 378/379 files; the remaining numerical file
`03-number/_num.scm` was terminated after 90.123399750 seconds without a
completed-file event (exit -9, timeout true). No other group failed. The
125-file group passed in 392.172493583 seconds, demonstrating that real progress
can legitimately exceed the old 300-second wall limit. The raw overall result
is DENY and the suite step is TIMEOUT, not full GSC PASS or a proven deadlock.

Recipe: `evidence/research/current-source-full-bootstrap/fdset-progress-compiled.recipe.json`
(SHA-256 `610b07f70a4cdc5a4e78ed72b5f9b32614873e9f3e59b743e212b88fb4fb7c15`).
The recipe preserves the previous stage graph, inventory, source, default GNU
flags and file/group windows; only the timeout policy migrated. Its prior
failure is bound rather than rewritten or charged against this attempt.

| Retained artifact | SHA-256 |
| --- | --- |
| Outer receipt | `bb94238d3bd02c81e90d7b0bb43124df92fe10326fd5c044ae2d2c0a270e52c3` |
| Child receipt | `d7e87355a7eaaebeb547d03db24b433cd31bdda6f34a5a12e16844bb83ef852e` |
| Suite group results | `965c9530d6df332ef74647e734d78c951d87137d46a803d345b73e9eb751cf0d` |
| Suite step receipt | `bcd917c328a49ec7feefa394bbdff50927a75b36530f4174c4b05a23eefd5595` |

These raw artifacts belong to the semantic run directory
`.data/fixtures/fdset-owned-rollback-completed-work-complete-compiled-run`;
this versioned summary is not a portable replacement for the raw receipts.
The single-file no-scheduling diagnostic above must not be substituted into
this default-profile campaign to declare 379/379. The next compiler-path
investigation must retain this default-profile timeout and isolate the
remaining scheduling options before any source/profile adoption. No release
performance threshold changed, and cumulative native completion remains 3/12.
