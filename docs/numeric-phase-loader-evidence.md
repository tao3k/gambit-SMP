# Numeric Phase Loader Evidence

## Source Contract

The original `03-number/_num.scm` fixture remains unchanged. Generating
`probe.c` gives the module linker name `probe`; the default loader derives
`probe_2e_o1` from `probe.o1`. These names differ. The retained execution denial
therefore establishes a loader contract error, not a numeric assertion failure
or GC deadlock.

Pinned source authority is `vendor/gambit` revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`:

- `lib/_eval.scm`, `##load`: accepts an explicit linker name and executes module
  initialization through `##load-modules`. Metadata loading alone is insufficient.
- `tests/unit-tests/#.scm`: initializes `##failed-test?`, retains assertion
  failures, and uses implicit exit 1 for success and 2 for failure. Procedure
  coverage records require `GAMBIT_COVERAGE`; an empty list is not a failure.

The [loader](../models/gambit/native/numeric_phase_load.scm) installs a sentinel,
loads with the explicit linker name, and requires the original failure flag to
be false after initialization. Explicit exit 0 is an adapter outcome, not a
change to upstream assertions.

## Actual Observations

| Observation | Outcome | Process seconds |
| --- | --- | --- |
| Scheme to C | PASS | 10.000 |
| GNU C to dynamic module | PASS | 18.085 |
| Default module load | DENY, exit 70, missing entry point | 1.039 |
| Incorrect nonempty coverage guard | DENY, exit 2 | 0.544 |
| Explicit linker plus failure sentinel | PASS, exit 0 | 1.0935 |
| Skipped module negative control | Rejected, exit 2 | 0.0098 |
| Forced failure flag negative control | Rejected, exit 2 | 0.6409 |

The successful loader and controls reuse the exact compiled module; they do
not recompile it. Runtime identity and module hashes are retained. CPU capacity
was host-derived; the recorded population is an observation, not a fixed limit.

Portable archives are under
`evidence/source-results/fixtures/sfun-owned-unwind/numeric-phase-loader-denial`,
`numeric-coverage-guard-denial`, and `numeric-sentinel-load`. Their file hashes,
source lock, loader, original denial and controls are checked by
`tests/test_numeric_phase_evidence.py`.

## Reflection And Remaining Requirements

This changes the next action: repair the phase adapter's module naming and
success contract before using it for a new qualification campaign. Do not
repeat the unchanged default-loader failure or classify it as an SMP failure.

The observations were separate invocations. Summed process time is not
continuous wall time; the original 90-second campaign remains DENY, and
`continuousPhaseCampaignPassed` remains false. The O0 diagnostic toolchain is
not a matched production-performance comparison. Full native inventory,
two-pass bootstrap, Gerbil acceptance and performance gates remain open.
