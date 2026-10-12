# Extracted Notification Protocol Controls

## Evidence Boundary

Campaign 031 uses unchanged extracted 026 publisher/wait code as a negative
control and the actual 029 fragments as the candidate. Both use the same
freshly configured 029 header (their locked header templates are identical).
POSIX mutexes, conditions and threads are real. Queue link/head consumption
uses the generated Gambit macros; payload tracing is deliberately stubbed.
This is component source evidence, not linked Gambit GC or performance evidence.

## Observed Interleavings

| Schedule | Original 026 | Candidate 029 |
| --- | --- | --- |
| Publication after empty probe, before M acquisition | One signal before wait; one pending, unconsumed queue item | One signal before wait; M-held recheck returns to scan; item consumed before wait |
| Publication after idle decrement, before atomic wait registration | One signal before wait; item remains unconsumed while helper sleeps | Publisher waits for M; signal occurs after registration; item consumed |
| Two publishers / two helpers | Not run as an additional unchanged failure route | Two signals, two chunks consumed once, count zero, four threads joined |

All five expected observations matched, with process exit zero and no timeout.
Candidate control durations were 0.571, 0.014 and 0.015 seconds. These are fixture
durations, not speedups or Gerbil build/test times. The first window uses forced
count-zero cleanup after recording the decisive queue/wait observation; this
cleanup does not prove source termination and cannot turn a negative into a
positive. The multiple-thread run is one schedule, not exhaustive or arbitrary
cardinality coverage. The second-window candidate and multiple-thread test
return through the extracted source count/termination path.

`PROTECTED_PUBLISHER` affects only fixture coordination: for the unprotected
negative, the coordinator joins the publisher before allowing wait registration;
for the protected candidate, it permits that publisher to block on M. The
adapter verifies this parameter against the actual extracted publisher. It
does not switch or replace source synchronization operations.

## Reproduction And Archives

```sh
uv run --locked python -m gambit_smp.notification_schedule \
  --gcc "$GNU_CC" --out "$LOCAL_BUILD_DIR/notification-schedules"
```

Configure keeps a 90-second watchdog, each fixture compilation 30 seconds and
each process 5 seconds. The four C roles specify a protocol topology, not a
hardcoded machine build-worker budget. Compiler identity is GNU GCC 16.2.0;
assembly/link driver paths resolve through the controlled Apple-tool PATH.
Their hashes identify selected drivers, not all payloads dispatched by Apple's
tool shims. Neither multiple-SMP flags nor driver hashes alone qualify a runtime.

The archive at `evidence/source-results/gc-notification-source-schedules-031/`
contains 27 receipt, header, source-fragment, fixture and log artifacts. Effective
argv, environment, budgets, raw/portable log hashes and observed parent exit
are retained. No binary or personal absolute path is published. The Datalog
research audit binds every archived file transitively and exposes the limited
observation without creating model/native/runtime/release admission facts.

Campaign 030 failed before execution because the fixture discarded a volatile
queue-head qualifier under `-Werror`. Its separate 11-artifact archive preserves
that failure. The correction preserves the qualifier; warnings were not disabled.
The run used the existing prepared Python environment because concurrent
dependency edits left locked uv setup unverified; it is not a locked-install pass.

Still open: payload/object ownership, repeated wake/error handling, phase and
resize composition, weak-memory visibility, full linked GC, VM teardown,
compiler/bootstrap and complete Gerbil package correctness/performance gates.
