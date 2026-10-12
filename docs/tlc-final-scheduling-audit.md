# TLC Final Scheduling Audit

## Hypothesis And Source Evidence

The recursive/eager-field campaign's normal TLC log spent 16 seconds checking
temporal properties on an intermediate graph of 2,093,932 states. It then still
had 444,764 unexplored states. Deferring intermediate liveness checks is a
checker-cost hypothesis, not a Gambit repair or a promised speedup.

Primary implementation references:

- [TLC option parsing](https://github.com/tlaplus/tlaplus/blob/master/tlatools/org.lamport.tlatools/src/tlc2/TLC.java)
  accepts `-lncheck final`.
- [TLCGlobals](https://github.com/tlaplus/tlaplus/blob/master/tlatools/org.lamport.tlatools/src/tlc2/TLCGlobals.java)
  excludes `final` from periodic `doLiveness()` checks.
- [ModelChecker](https://github.com/tlaplus/tlaplus/blob/master/tlatools/org.lamport.tlatools/src/tlc2/tool/ModelChecker.java)
  calls `liveCheck.finalCheck` after error-free state exploration when the model
  has liveness properties. The option is not equivalent to `off`.

Installed bytecode inspection confirmed both the scheduling branch and the
final call in the actual bundled artifact with SHA-256
`880c0b2b72354816f12e9a9755829f2907071e9a181ffea1937954c23d54739d`.
The source links are upstream references, not an assertion that moving `master`
is the exact source revision of this JAR.

Quint 0.33.0's normal TLC adapter accepts workers/heap/stack settings, but does
not pass arbitrary JSON keys through as TLC options. The explicit adapter uses
public `quint compile --target tlaplus` stdout followed by the same TLC artifact.
In this installed CLI, `--out` serializes compiler IR instead of emitting the
TLA+ target; the initial experiment rejected that output before running TLC.
The regression suite now rejects IR and requires the TLA module and requested
`q_init`, `q_step`, `q_inv` and, when selected, `q_temporalProps` wrappers.

## Execution Contract

The opt-in `verify --tlc-liveness final --tlc-jar "$TLC_JAR"` path keeps the
original initializer, step, invariant, temporal formula, finite role bounds,
CPU allocation and JVM limits. Java identity, compilation and TLC share one
total deadline; this is not a separate 90-second budget for each phase.
No state constraint, symmetry declaration, fairness change or off switch is
introduced. Unsupported config keys fail rather than being silently ignored.

Quint's existing `-deadlock` setting is retained; models must keep their explicit
`enabled(step)` deadlock property. Acceptance still requires no timeout, real
exit zero, complete exploration with zero queued states and a completed temporal
check. Intermediate progress counts are not an exhausted proof.

Source/model/config/JAR/launcher identities and compiled TLA/CFG hashes are
bound in receipts. Publication verifies the compiled configuration still contains
the requested properties. Independent checks retain unique log/trace names;
a regression catches artifact-loop variables overwriting the check identifier.
The framework deletes only its freshly created TLC disk-state scratch after
the supervised process has exited or been killed and reaped. Compiled inputs,
logs and decoded counterexamples remain. This is not checkpoint/resume mode.

## Diagnostic And Denied Results

The explicit integration fixture checks three properties under both strategies:

1. Safe terminating execution must pass, with the same exhausted state count.
2. An invariant fault must produce a decoded counterexample.
3. An always-safe, enabled fair cycle must fail only its temporal property.

The first successful diagnostic preserved under
`evidence/model-results/tlc-final-scheduling-parity/` passed all six expectations;
the terminating model had two distinct states in each strategy. Its individual
checks ranged from 3.351 to 3.494 seconds. It remains `accepted=false` for overall
repair admission and `parityPassed=true` only for this checker diagnostic.
The current cleanup-enabled framework repeated all six expectations in 21.402
seconds, with stable inputs and all three final-mode scratch removals recorded.
That separately bound receipt, logs, safety traces and compiled artifacts live
in `evidence/model-results/tlc-final-scheduling-parity-cleanup/`. Individual
checks took 3.390-3.546 seconds; this is still diagnostic, not a speed baseline.
Compiler-IR rejection and an earlier diagnostic message-matching failure are
not Gambit failures and are not evidence for dropping a temporal obligation.

The same recursive/eager-field model then hit its unchanged total budget at
90.141 seconds under `final`. The last logged progress had 2,271,137 distinct
states and 469,341 queued states. No complete temporal proof occurred; the other
positive policy was not started. The DENY, generated specification and config
are preserved in `evidence/model-results/gc-recursive-queue-wait-final-deny/`.
That historical campaign also exposed the subsequently fixed log-name shadowing
bug; its original receipt is retained, not rewritten as a corrected campaign.

This observation does not establish a stable speedup or solve the positive
model. Do not rerun the unchanged recursive positive merely because final is
available. First correct the source-model probe/frontier gaps described in
[recursive composition](gc-recursive-queue-wait.md).
