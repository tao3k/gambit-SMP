# Thread Queue Payload Root Native Observation

## Result And Source Path

`models/gambit/native/interrupt_thread_queue_payload_roots.scm` compiled
against the new thread-completion candidate in 3.275 seconds and ran in
0.532 seconds. Both processes exited zero without timeout, with quiescent
groups. The fixture requires its single success marker and nonzero failure
exit. Requested processors were selected from host capacity, observed 12,
not a fixed source constant or an independently verified population probe.

A non-inlined helper creates payload and callback, invokes actual
`##thread-intr!` in asynchronous mode and returns void. The target is pinned
to the caller's processor before starting, solely to control this diagnostic
window. The compiled caller disables interrupt polling while it registers the
request and forces two collections. It checks zero deliveries before and after
GC, then joins the target and checks exactly one callback with intact payload
and correct current-thread identity. Other processors and all SMP flags remain
enabled; this is not a parallel-speedup or arbitrary scheduling result.

Source inspection of `lib/_thread.scm:##thread-intr-propagate!` shows that a
non-running target receives the request through its thread queue. The target
cannot execute on a peer while pinned, so this fixture exercises that path
rather than an already-executed callback that would hide the root window.
The caller retains the target, as required to reach its queue, but does not
independently retain the payload or request.

## Retained Failure And Evidence

The initial fixture attempted to include all private thread macros and directly
modify a queue. Compilation rejected a macro-name collision before runtime.
Its source snapshot, log and 0.206-second exit-1 observation are retained. The
accepted fixture uses actual existing interrupt APIs instead, without weakening
assertions, extending the 60-second diagnostic cap or changing runtime source.

Portable logs, exact candidate identity, final fixture snapshot and generated
summary are at
`evidence/source-results/fixtures/interrupt-thread-queue-payload-roots/native-diagnostic`.
The existing runtime identity checker revalidated actual source/runtime bytes
after execution. The independent research read remains a separate source-core
freshness check, not a full test admission.

## Remaining Requirements

Together with the earlier processor/local fixture, all three abstract root
ownership windows now have actual diagnostic observations on this new candidate.
This does not prove physical relocation, absence of every transient root,
concurrent cancellation/retirement, weak/strong phase ordering or full GC.
The root model's transitive-scanning and cohort premises are not discharged
by payload-content assertions alone.

These are direct bounded process observations, not a sealed typed full suite
or ASCENT causal-review admission. No new Python producer or runtime fix was
introduced. Complete native tests, full bootstrap, same-artifact Gerbil and
production performance remain OPEN; runtime/release/performance admission
fields remain false.
