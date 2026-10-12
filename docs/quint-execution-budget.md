# Quint Execution Budget

## Two Concurrency Levels

The shared verifier uses host-detected CPUs, not a hardcoded worker count.
Independent negative controls may now execute in bounded batches. The total
TLC worker allocation in a batch does not exceed the detected CPU capacity;
each check has a separate directory and server endpoint. A failed batch stops
before any subsequent batch or positive check is launched. Already running
siblings finish within the unchanged per-check watchdog.

Positive exhaustive checks remain serial and retain the full detected TLC
worker capacity. This avoids claiming that CPU oversubscription solves state
explosion. Default independent concurrency is bounded by the CPU square-root
and physical-memory capacity. Quint 0.33.0's observed defaults reserve 8 GiB
for TLC plus 4 GiB for Apalache per check; the plan reserves one quarter of
physical memory. Unknown memory capacity falls back to serial. Physical memory
is not a live available-memory guarantee or a Java RSS limit.

The current 12-CPU, 32-GiB host selected two independent control jobs and six
TLC workers per job, while positive checks use all 12 available CPUs. These
are observations, not configuration constants. `--jobs` accepts a bounded
override; `--jobs 1` retains a serial control run.

## Observed Diagnostic Timing

Four identical-model independent controls originally consumed 19.455 seconds
in summed serial check time. A subsequent two-job control-only campaign took
9.240 seconds overall; its individual checks took 4.505, 4.592, 4.640 and
4.629 seconds. This is a single observational timing comparison, not a stable
performance baseline or proof of end-to-end model/native acceleration.

```sh
uv run --locked gambit-smp verify --manifest evidence/gc-recursive-queue-wait.json \
  --controls-only --out .data/control-timing-campaign
```

`--controls-only` records `controlChecksPassed`, but **always** leaves overall
`accepted=false`, `runtimeAdmitted=false` and `releaseAdmitted=false`. It cannot
stand in for either positive policy's complete safety/temporal exploration.
The portable diagnostic archive lives in
`evidence/model-results/gc-recursive-queue-controls-parallel/`.

Logs show Apalache startup/translation before TLC begins. Parallel controls
overlap this overhead; they do not make a single translation instantaneous.
No unsupported TLC flags, weakened invariants, smaller role bounds or extended
timeouts were introduced to obtain the timing.

An explicit, opt-in final-liveness scheduling adapter now has separate
checker-only parity tests and a preserved denied recursive campaign. It does
not change the default strategy or grant native admission. See
[the scheduling audit](tlc-final-scheduling-audit.md) for exact properties,
artifact identities, total-deadline behavior and results.
