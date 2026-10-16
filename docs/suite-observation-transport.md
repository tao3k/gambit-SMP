# Suite Observation Transport

## Interface

`gambit.suite` optionally accepts `observationFiles`, a mapping from an exact
selected fixture to its `observations/<semantic-name>.json` output. The original
upstream runner is unchanged. This supports fixtures whose successful stdout is
discarded by that runner; it is not a replacement test harness.

The framework rejects existing outputs before launch, escaping or symlinked
paths, nonregular files, outputs larger than 64 KiB, malformed/nonfinite JSON
and nonobject payloads. Only successful suite groups can collect outputs.
Collection checks file identity before/after reading and freezes exact bytes
in a separate shard snapshot. The published `suite-observations` artifact
binds each file, owner fixture, byte count and digest. Downstream artifact
consumption rechecks the existing tree identity. Collection is inside the
original deadline; it never resets a file or step budget.

`semanticAdmitted` remains false. A fresh valid JSON object is transport
evidence, not proof that payload assertions, performance or SMP are correct.
The QNT model `suite_observation_transport` abstracts those transport checks;
its Boolean assumptions require the concrete filesystem/process checks. It
does not prove filesystem race exclusion against a malicious concurrent owner,
crash durability or native SMP behavior.

The source-bound model recipe passed all nine steps in 25.222596 seconds:
safety and enabled-progress each explored 67 distinct / 230 generated states,
zero queued; both faulty-policy controls and all four trajectories passed.
Outer receipt: `636d0f7c83b664b6d176e7c999b66b55cdd00fa9761271b17fd64803af0a67f4`.
Child receipt: `b1f546afcc9e043f17adf3244830a8d57025df8f6728b405ddd67d56279f28d2`.

## Actual Interpreted Cost Observation

The structured busy-delay fixture preserves the original `(busy-sleep 6000)`
body and 250 repetitions per owner from the prior diagnostic. On the detected
host, the existing framework chose 11 processors and one shard. All 11 workers
joined, reporting 16,500,000 decrements and 293,603,897 elapsed nanoseconds
(0.293604 seconds). Runner expenditure was 0.310244 seconds; whole campaign
was 29.303861 seconds under unchanged 300 / 30 / 20-second limits.

Recipe: `smp-vector-arity-structured-busy-delay-observation`.
Inspection: PASS/CURRENT, runtime/source-refinement admission false.
Payload SHA-256: `822965aace76809aaae92a80b17008ac6ab49414748458b81eee36bbab9d7008`.
Outer receipt: `b776f1d81bb8f861dc561275842300858dbd3faa1cc827ba6b066b2bffa6dedf`.
Child receipt: `48a8f8bb0fbaf8f147c2bf3438c4d75543890fe6691e3d2ed75017eb1f7b4c12`.
Engine: `29168c77e1ebb475a68a1e08ee28bfcdcce0d4f79661ec3520fa5e65566fcb98`.

The fixture uses `current-time`; integer nanosecond representation does not
claim nanosecond clock resolution or a monotonic-time guarantee. This sample
cannot be linearly extrapolated into a stress completion time or lower bound.
The original tfib stress remains unchanged and unqualified. Thread creation,
recursive scheduler/GC interaction and larger-load behavior are not measured
by this loop diagnostic.

No bootstrap was repeated. The producer reported PASS/CURRENT after restoring
the exact original bytes of its locked documentation input. Earlier attempts
remain DENY: documentation drift at handoff; unchanged-route prelaunch denial;
and a leading-dot Scheme float rejected by the strict JSON reader. The final
fixture writes an integer duration, not a relaxed JSON parser. Its recipe now
explicitly declares the inherited locked document prerequisite.

The legacy prototype document remains byte-for-byte unchanged because it is
a bootstrap input. Updated capacity/replay conclusions live separately in
`registry-capacity-writer-replay.md`; its historical open-requirement wording
must not be mistaken for the selected successor's implementation.
