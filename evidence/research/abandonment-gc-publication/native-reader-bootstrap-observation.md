# Native Reader And Bootstrap Observation

## Retained Failure

The current locked engine is
`1bef0d2f5953c7b0d0f0afaa59ae0a2aecc5e92dab228f83adc239d130f8b1c7`.
Its installed ASCENT dependency is Git
`88b4aa5eb098143594cf039a8e0c74d1f7e639ca`.
The canonical GNU profile and progress-watchdog mode were retained. The draft
Recipe incorrectly enlarged the original stage windows; neither run qualifies
the original-budget acceptance contract. The original headers remain unchanged.

The source in `source.lock.json` completed materialization (4.355 s),
configuration (36.884 s), seed core (72.525 s) and retry review (1.197 s).
Bootstrap failed after 98.459 s: `from-scratch` returned 2, and the first
compiler failure was `_thread.scm: Incomplete form, EOF reached`.
Original compiled stress was not run. Neither this run nor its seed is a
completed bootstrap or a new native milestone.

The outer receipt digest is
`5e429644e7b9250991fca4ad595b62c83759530fe5c16395793b0949f634fef9`.
The child reports `STALE` and `inputsStable=false`. Later byte comparisons of
its input map and per-step observed-input maps found no mismatch. That does
not explain or override finalization: tool custody, artifact availability and
source-input stability must be distinguished before diagnosing this status.
Do not rewrite the receipt to PASS.

## Isolated Native Counterexample

The added `if` and `begin` in `##mutex-unlock-out-of-line!` require two extra
closing parentheses. The previous delta added only one. The repair changes
the final `(##void))))` to `(##void)))))`, with no protocol change.

The existing process-observation framework ran a source-built retained GSI,
with explicit virtual library paths, no init files, explicit exception handling
and reaped child process groups:

| Observation | Exit | Timeout | Result |
|-------------|------|---------|--------|
| Reader host control | 0 | false | `READER-HOST-READY` |
| Previous source | 70 | false | `Incomplete form, EOF reached` |
| Single-parenthesis repair | 0 | false | `NATIVE-READER-PASS forms=1` |

The process-observation receipt digest is
`19347d9b2a72d7f3d8d323a80067c6b0f9bdfa592db9b1f6ffd2fb762d63ed7a`.
This is a reader diagnostic, not candidate runtime qualification. Earlier
reader attempts using the failed build's `gsc-boot` had no output and timed
out; their receipts remain retained, and they establish no syntax verdict.

`source-reader-repaired.lock.json` and its cumulative patch reproduce the
repaired source from the pinned submodule without depending on temporary
diagnostic files. The previous lock and its cumulative patch still reproduce
the malformed source. The repaired `_thread.scm` digest is
`e00b3dd19beebcb7addd5fd9ee51ba1123e0acd23a3f59101adc84fa253f443a`.

## Admission Boundary

The repaired source subsequently completed bootstrap with exit 0 in 351.288 s.
Compiled TFIB and terminate completed together in 52.786 s, and compiled
interrupt completed in 77.194 s. Interrupt2 did not complete. The supervisor
stopped its recorded process group after discovering the enlarged budget;
TERM did not stop its busy child, so KILL was required. This is an interrupted
observation, not a passing stress suite or an invented watchdog timeout.
The final receipt is DENY, `inputsStable=true`, with parent reaped and process
group quiescent. No original-budget or complete-stress qualification is claimed.

A one-second read-only OS sample of that exact child found 809 of 814 samples
in `___raise_high_level_interrupt_pstate`, called from `___H___kernel`.
Two other threads were sampled in `barrier_sync_op` / `_pthread_cond_wait`.
This is coexistence evidence, not proof that the new mutex or tgroup changes
caused the interrupted test. Interrupt publication versus barrier participation
is an explicit source/model audit gap; no unchanged retry is justified here.

The current Recipe restores every original window: source 30 s, configure
60 s, seed 130 s, review 15 s, bootstrap 270 s, compiled stress 300 s,
verdict 10 s. These are progress-watchdog windows, not total elapsed-time
performance claims. The raw earlier Recipe declarations retain their wider
limits and are not rewritten.

This native failure exercises the existing command-completion obligation:
model acceptance and source custody cannot close a failed bootstrap command.
The protocol model does not prove Scheme syntax or refine the new signal and
thread-group paths. A fresh source-bound bootstrap and original stress remain
required, and cumulative SMP progress remains 6/12.
