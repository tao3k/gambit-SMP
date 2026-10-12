# Requester Cancellation And GC Native Result

The checked current thread-completion source-core candidate passed changed
diagnostic fixtures with SMP, multiple VMs and multiple threaded VMs configured.
Processor population was requested from available host capacity (observed 12),
and the fixture requires an actual population of at least two. This is not a
scaling measurement or a guarantee of twelve simultaneously active processors.

| Scenario | GNU compilation | Execution | Result |
| --- | ---: | ---: | --- |
| Callback GC before requester termination | 1.883 s | 0.722 s | PASS |
| Additional GC after requester join, before callback return | 1.597 s | 0.865 s | PASS |
| Return and exception after requester cancellation, parallel isolated processes | 1.771 s | 0.530 s batch | Both PASS |

Both steps in each scenario retained the original 60-second caps. All exits
were zero, with no timeout and quiescent process groups. The exact source/runtime
identity was checked before and after execution. Each run had one success marker,
no assertion failures and explicit nonzero assertion-failure exit handling.

The callback creates its own payload and checks actual relocation after the
first forced GC. The orchestrator confirms that the requester waits on a result
mutex owned by the target, then terminates and joins the requester. The extended
fixture forces another GC while the receiver callback remains alive, then
allows return and validates payload contents. Caller continuation stays absent,
the callback executes once, and the target joins normally. No sleeps, synthetic
heartbeats, timeout widening or runtime source change were used.

Portable exact logs, fixture snapshots and identity are retained separately at
`evidence/source-results/fixtures/interrupt-requester-cancel/native-diagnostic`
and `evidence/source-results/fixtures/interrupt-requester-cancel/post-cancel-gc`.
The first fixture is not overwritten by the added collection. The previously
published compile-only archive remains an accurate earlier-stage observation.

The additional outcome fixture retains all cancellation and payload assertions.
Its explicit command-line mode selects callback return or a deliberate exception
after cancellation. Normal target join must return the expected value; the
exception mode must produce an uncaught target exception. Both prohibit late
caller continuation and require one callback. The existing shared process
transport ran two independent processes concurrently, assigning six requested
processors per child from observed host capacity twelve. The whole batch kept
the same 60-second limit, including queue time; this is not a throughput claim.
Portable evidence is at
`evidence/source-results/fixtures/interrupt-requester-cancel/cancel-outcomes`.
This newer observation is not yet added to the frozen audit registration.

The companion `models/gambit/interrupt_requester_cancel_schedules.qnt` imports
the checked composition unchanged. Its four explicit trajectories cover GC
before cancellation followed by throw, cancellation followed by GC and throw,
cancellation followed by GC and return, and cancellation/GC followed by target
termination. The local Quint command passed these four trajectories and the six
imported controls in 1.778 seconds. Its repeated sampling is not a count of new
states or exhaustive schedules. Target termination in this companion remains a
model trajectory, not an additional native observation. The registered 192-state
model and its immutable receipt were not changed.

## Limits

These are direct bounded compiled observations, not sealed full-suite admission
or a proof of every physical root map, trylock/retry interleaving, memory order,
collector phase, arbitrary request graph or processor retirement. The checked
192-state model permits collection within callback lifetime, but bounded source
correspondence is not full runtime refinement. Complete native suites, stress,
same-artifact bootstrap, Gerbil and production reliability/performance remain
open. Runtime, release and performance admission stay false.
