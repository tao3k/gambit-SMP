# Predicate Participation Qualification

The current candidate is source lock `405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37`.
The mutex/condvar acquire repair is applied and has completed two-pass bootstrap.
It remains a research candidate, not an admitted release patch.

## Executed Results

| Check | Result | Recorded time |
| --- | --- | --- |
| Original predicate composition QNT | Positive invariant and three expected negative controls passed | See `model-observation.json` |
| Explicit retry/root recovery QNT | Positive invariant and two expected negative controls passed | See `retry-rooting-observation.json` |
| Full two-pass bootstrap | PASS; phase1 through phase4 each occurred twice | Whole 274.541 s; bootstrap stage 178.927 s |
| Original compiled stress | PASS, 4/4 unchanged files, exit zero | Whole 65.528 s; stress stage 57.824 s |
| Original interpreted stress | DENY; 2 passed, TFIB timed out, terminate not executed | Whole 310.178 s; TFIB child 300.039 s |
| Complete GSI and retained PR fixtures | DENY; 369 passed, pipe timed out, 10 not executed | Whole 321.182 s; suite stage 305.978 s |

The interpreted interrupt2 and interrupt files completed in 58.560 s and
61.825 s. The interpreted TFIB test ended at its unchanged watchdog, not with
a SIGSEGV or a proven deadlock. The original program includes `(go 15 5000)`;
its absent completion marker alone cannot distinguish slow useful computation
from a synchronization failure. Do not rerun that unchanged failed route as
though the source issue were already understood.

Compiled interrupt2 had timed out on parent source lock `7e59221...`; it completed
in 24.884 s in this campaign. This is a new natural pass, not matched evidence
of speedup or a proof that the parent timeout's cause is eliminated.

## Cumulative Milestone Status

Cumulative progress remains **6/12**, not reset by cache cleanup and not raised
by a model check. Historical completed obligations are bootstrap, complete GSI,
PR regressions GSI, complete GSC, PR regressions GSC, and compiled stress.
Their historical source identities remain attached to their original receipts.
On this new source, bootstrap and compiled stress are requalified; historical
suite passes are not silently transferred to it.

| Still open | Current evidence boundary |
| --- | --- |
| Interpreted stress | Two files passed; TFIB timeout; terminate not executed |
| Registry lifetime | No complete current-source acceptance in this campaign |
| Lifecycle failure/rollback | No complete current-source acceptance; prohibited interposition is not substituted |
| GC/FFI | No complete current-source acceptance in this campaign |
| Gerbil correctness | No complete current-source build/test acceptance in this campaign |
| Release performance | Correctness prerequisite remains open; no performance admission |

## Remaining Design Obligations

The explicit retry model now uses the restored reference at its next modeled
CAS access. Native observations remain counters to whole-runtime admission:
neither lock model covers TFIB's complete allocation, queueing and join protocol.
The registered View links that scope gap to the native failure instead of
marking the failure solved by a finite model.

FIFO order and unbounded-arrival starvation, complete nested-lock/resize/error
composition, the previous pipe timeout, and header-write causality are not
established by the current evidence. Read the source review and the separately
recorded complete GSI result rather than treating this table as a native pass.

The full GSI campaign reproduced `09-io/pipe_concurrent.scm` on the exact new
producer. This is a direct counter to the sufficiency of the two-macro repair
for that failure. The failed group was reaped and its process group was quiescent.
No prior failure was deleted or reclassified as solved.
