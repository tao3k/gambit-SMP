# Callback Termination After Requester Cancellation

## Decision And Scope

The registered requester-cancellation model and its companion schedules include
target termination after cancellation and collection. Previous native outcomes
covered callback return and exception, not explicit target termination. This is
a missing native correspondence check, not a repeated failed optimization route
or a proposed runtime change. No performance improvement is claimed.

The fixture adds a distinct `terminate-after-cancel` mode. After the requester
is observed waiting on the target-owned result mutex, it is terminated and
joined. A second GC runs while the callback remains alive. The callback then
validates its payload and terminates its own target thread. Target join must
raise `terminated-thread-exception?`; any continuation after termination fails.
Original callback relocation, one-callback and no-late-requester-continuation
assertions remain. Return and exception modes are rerun on the same new binary.

## Actual Observation

The current thread-completion source-core identity was checked before and after
compilation and execution. GNU GCC 16.2.0 compiled the fixture in 1.755 seconds.
The three isolated processes completed concurrently in 0.762 seconds. Each exited
zero, emitted exactly one success marker, had no assertion failures or timeout,
and left a quiescent process group. Host capacity was queried, not hardcoded:
the observed 12 available processors gave three workers and four requested
processors per process. Both compile and whole batch retained 60-second caps.

Portable fixture, assertion helper, exact process observations, identity and
hash-bound receipt are archived at
`evidence/source-results/fixtures/interrupt-requester-cancel/target-termination`.
Previous return/throw archives and registered model receipts are unchanged.

## Remaining Boundary

This checks self-termination while executing the callback, not an external
thread's termination request racing with the receiver's callback. That separate
route must account for nested interrupt delivery rather than infer coverage from
this result. It does not establish arbitrary GC phases, weak-memory refinement,
processor retirement or a complete suite/bootstrap/Gerbil acceptance.

Runtime, full-suite, release and performance admission remain false. This new
fixture changes repository inputs; the earlier 770-test graph PASS remains an
archived qualification of its own inputs, not automatic qualification of this
changed tree. The formal current-producer review handoff is still unimplemented.
