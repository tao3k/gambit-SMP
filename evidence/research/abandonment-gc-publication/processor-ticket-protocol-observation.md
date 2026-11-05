# Processor Ticket: Conditional Protocol Qualification

## Identities And Reproduction

Candidate source lock: `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
Model SHA-256: `da12d6328ef6f1680e50f9083a24e34af0799e145c5728780ba2d0b250ee7f15`.
Manifest SHA-256: `3f97d0d03a3fb24f7cdf3b2c393f47aa0df9f0d1066636a71737e188ce9b93c8`.
Receipt SHA-256: `8bfc935417b80433fc8acec0a4c1e2714e8e81abc44f21c48cc8860435ececd2`.

Use the existing verifier; select this case rather than repeating unrelated
abandonment controls:

```sh
.venv/bin/gambit-smp verify \
  --manifest evidence/research/abandonment-gc-publication/model.manifest.json \
  --case processor_interrupt_ticket --out .cache/processor-ticket-protocol-check
```

The verifier requires its normal loopback service. The initial sandbox refusal
occurred before model execution; the failed launch directory was preserved.
The completed run used host-auto scheduling, not a hardcoded CPU count.

## Results

All five checks completed; input context stayed unchanged. Campaign time was
12.742 seconds. The positive check exhausted 108 distinct states, 132 generated,
with zero queued states, including the declared finite liveness property.

| Check | Result | Counterexample boundary |
| --- | --- | --- |
| Participating rooted protocol | PASS | Served-ticket and failed-trylock strategies; GC, resize and NOOP abstractions |
| Raw reservation progress | Expected violation | Owner enters collective; raw waiter cannot participate |
| Unrooted participation | Expected violation | GC relocates payload; later publication uses its old reference |
| Repeated reservation | Expected violation | A retry leaves the original ticket unserved |
| Notification before release | Expected violation | Queue is published but the notifier still holds its ticket |

The negative controls begin in valid initial states and reach their violations
through transitions. They are not pre-broken initial states or a scripted phase
counter. The rejected earlier draft and failed verifier observation remain
separate historical evidence.

## What This Does Not Establish

Source refinement: `setup_processor_scmobj_pstate` marks the processor object
`___PERM`; its lock address remains stable. Only the payload reference relocates
in this model. The previous over-approximation and its receipt
`b25aa0b7d3cd65ee140d05c9809f3b351ec286e49f7533aa6317c87d5b6b8d40`
remain historical, not current qualification. The source-refined unrooted trace
now reaches stale payload publication rather than a fictitious moving lock.

The model assumes that a holder may enter a collective with its ticket held;
it does not identify the holder or collective operation in the retained sample.
Relocation is atomic and complete root tracing is a positive premise. It is not
a proof of the C collector, generated-code root maps, ARM ordering, membership
changes, unbounded-arrival fairness or source refinement.

Neither participating strategy is an applied source repair. A C-side GC poll
without a root contract, a repeated fetch-add after retry, deletion of the
non-SMP scheduler definition, or an unprotected device queue is not admitted.
Runtime and release admission remain false. Cumulative SMP progress remains
6/12; no original pressure test or bootstrap was repeated for this model run.
