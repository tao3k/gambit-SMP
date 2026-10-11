# Thread Interrupt Fixture Ordering

## Scope

Keep the useful PR988/1038 runtime repairs. This is a test-protocol correction,
not evidence that the runtime interrupt implementation is correct in general.
The original fixture uses busy work to delay the worker and main thread;
independent SMP scheduling does not establish recipient lifetime or completion.

## Model

`thread_interrupt_test_protocol.qnt` freezes two old-protocol counterexamples:
interrupting a finished recipient and asserting before worker completion.
The completion-gate/join variant exhausts 23 distinct states, 36 generated,
with zero queued and no safety violation. The model assumes correct runtime
interrupt delivery and join semantics; it does not prove memory publication,
GC interaction or unbounded progress.

## Native Check

`native/pr988/thread_interrupt_completion.scm` retains the original assertions.
Main owns a mutex before starting the worker; worker completion waits on that
mutex. Main releases it only after observing interrupt handling, then joins
before asserting the final value. No sleep or larger budget substitutes for
synchronization.

Using actual source candidate 019, interpreter mode passes in 4.165 seconds;
compile-and-execute mode passes in 19.344 seconds, each within its 20-second
mode budget. Both bind the original support file and exact fixture hashes.
Processor selection is host-auto (12 available on this run).

The complete interpreted upstream suite subsequently passes 375/375 files in
177.070 seconds under its original 300-second budget, with this explicit
test-only patch and unchanged assertions. This is not compiled-suite or
bootstrap admission. The original failure receipt remains retained.
