# GC Queue Probe Access Result

The source-bound sealed recipe `gc-queue-probe-access-discipline` passed all
nine stages in 32.262 child seconds and 34.235 outer seconds under its original
90-second whole budget. Source materialization reused the existing workspace;
no runtime source changed or new source tree was created.

The positive access-discipline model exhausted 13 distinct states with no
queued states and no invariant violation. The three negative controls reached
the expected invariant violations: plain unlocked access, an atomic load with
a conflicting plain writer, and retirement from a stale advisory hint.
The four explicit trajectories also passed. Checks used 12 detected CPUs;
the number is an observation, not a runtime constant or model bound.

The initial recipe declaration was rejected before execution because it did
not start with a locked source producer. Adding the existing source stage
corrected the contract; no source, check domain or budget was changed to obtain
the pass. The earlier Quint nondeterministic-binding parse failure is recorded
in the companion source review. Neither prelaunch failure was a native GC run.

Engine:
`1c5286f4c486502d1cb6462665efd604ae66e4a35c71db1345625102c3af511b`.
Child receipt SHA-256:
`06bf8641324374da4e582fc0927e2512ac7e2855719d1d2178e8ac330bb413c9`.
The outer process group was quiescent, timeout was false, and the real ASCENT
terminal verdict passed. Current model/source/recipe bytes and original
checked outputs remain bound by the sealed run journal.

This establishes only finite access-discipline checks. It does not prove C11
semantics, causal responsibility for the registry timeout, real payload
publication, general GC progress, runtime correctness or performance. A source
successor still needs complete endpoint-access auditing, compiler compatibility
and lock-freedom checks, fresh bootstrap and unchanged native qualification.
The cumulative full milestone remains 3/12.
