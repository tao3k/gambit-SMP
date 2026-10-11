# Ended Interrupt Target Lock

PR1047 identifies a residual SMP lock leak, independent of the test-completion
ordering fix. The cached report and patch are bound to head
`037b8e9ae0386ac007c66d6db6a52f7abfe50ff3` and base
`dcd677cd3e40860bdd27dfbdbf5e3ce46ab03813`. This is a cached snapshot, not a claim
about the current upstream merge state.
This is a shared SMP Scheme branch, not a Darwin-only condition. The cached
upstream report records targeted Windows checks; our actual rebuilt runtime
checks are macOS/GNU GCC only. Linux acceptance is still unverified.

Current runtime020 source still uses an `if` without a terminal-target branch
inside `##thread-intr-propagate!`. The callback receives the target lock held.
If the target ended after the initial interruptability check, the callback
returns without unlocking. PR1047 adds the missing unlock. The running-target
branches already release this lock before raising or scheduling the interrupt.
The source contract is explicit: `##thread-lock-remove-btq-toq!` acquires the
thread lock before calling its continuation, and `##thread-end-current-thread!`
acquires that same low-level lock before `##thread-end-locked!` changes terminal
state. Thus the model's stable-state-under-lock assumption is tied to actual
source locking, not inferred solely from the PR description.

The model covers validation, normal or exceptional termination, acquisition,
propagation and observation. The old branch has a frozen safety counterexample;
the fixed branch exhausts 13 distinct / 16 generated states, with an empty
queue. Atomic lock/check operations and stable terminal state under the lock
are assumptions. This is not a weak-memory, full-scheduler or GC proof.

The copied native regression has the exact upstream Git blob
`5fde5fac78e9a7f43b1f7f8114697dad1bfcd353`. It uses a nonblocking trylock assertion
to detect the leak rather than waiting for a public API operation to hang.
The snapshot unit test rejects fixture drift. Original runtime020 fails both
trylock assertions in 0.410 seconds. The exact source-bound terminal-branch
patch completes a real GNU GCC core rebuild in 25.692 seconds, with `_thread.c`
deleted before regeneration and all three core artifact hashes changed.
Original and immutable source inventory checks pass. Runtime021 then passes
the same regression in interpreter mode (0.468 s) and compile/execute mode
(9.502 s) under the unchanged 20-second per-mode budget.
Full threaded bootstrap and complete toolchain acceptance remain open.

The first local verifier attempt was denied by sandbox port binding, not a
model counterexample. The subsequent local verifier run preserves the same
model and budget and records the actual old counterexample and fixed exhaustion.
