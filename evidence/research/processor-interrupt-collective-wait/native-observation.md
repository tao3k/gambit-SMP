# Processor interrupt collective wait: native observation

## Identity and admission boundary

The candidate is `source.lock.json` (SHA-256
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`).
Its cumulative patch is
`patches/fixtures/processor-interrupt-collective-wait-cumulative.patch`
(`8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`).
The retained observer overlay was removed before production. No new source
clone or debugger was used. The source review limits the repair to propagation
under fixed processor membership; it does not prove resize or every raw C
ticket-lock acquisition safe.

The source-bound Quint campaign accepted six checks, including five expected
negative controls, in 17.258 seconds with stable context. This is a finite
protocol result, not a C memory-model refinement or native qualification.
Model receipt SHA-256:
`176839905d0921d2edcbf4d6d5aeeb33455e547557da4bf16201a32b1ba3c008`.

## Original native campaign

GNU GCC 16 and the registered Bazel profile enabled SMP, multiple VMs and
multiple threaded VMs. Build concurrency was host-derived. The original stress
groups used three drivers with three processors per child. The existing
completed-target and completed-file inactivity watchdogs were not widened.

| Stage | Result | Seconds |
| --- | --- | ---: |
| Configure | PASS | 30.174 |
| Bootstrap seed | PASS | 61.354 |
| Scheme regeneration and core link | PASS | 95.305 |
| Original compiled stress | 4/4 PASS | 62.829 |
| Original interpreted stress | INCOMPLETE | 301.375 |

This was source-core regeneration, **not** a new full two-pass bootstrap.
Compiled interrupt2 completed in 29.189 seconds, interrupt in 60.274 seconds,
and the TFIB/terminate sequential group in 36.712 seconds. Interpreted
interrupt2 and interrupt passed in 68.548 and 71.969 seconds. The interpreted
TFIB/terminate group was killed after 300.061 seconds without a completed
file: TFIB did not complete and terminate was not reached. This is not an
assertion identifying a GC deadlock, a lock holder, or an elected barrier type.

The aggregate verdict remains DENY. The parent was reaped and its process
group quiescent. Native receipt SHA-256:
`a9bd1c65f2ed8df8da605670554146a6d2fde876f0c9a06765ee8e483ec567a5`.
Produced GSI SHA-256:
`f4e12910d834d9e46346241e90fee3c65053d57acda84f9478910e7dd36a848f`;
GSC: `d3093d9329f2c32d8ddc58325740f95b02ff4d8e3ab772ca63f322cf55b8bdc4`.

## Checkpoint continuation and falsifier

The existing execution checkpoint reused source, configure, seed and core with
`executionLaunched=false` for each. No bootstrap or core rebuild occurred.
An isolated original interpreted terminate file passed in 23.915 seconds,
using two drivers/five child processors rather than the original group setup.
It is separate evidence, not completion of the original four-file suite.
Its receipt SHA-256 is
`87a4687ee69d45df89760b3b36287f6e5d67d6718d9a898b209841936809b407`.

The unmodified TFIB input calls `(go 15 5000)`. Its recurrence produces
9,865,000 calls to `short-delay`, each decrementing 6,000 times: 59,190,000,000
artificial loop iterations, before considering thread/scheduler overhead.
The original comment calibrates this delay for compiled execution. A separate
diagnostic loaded the original definitions but did not run the full workload.
1,000 interpreted delay calls took 2,110,121 microseconds. This is a cost
observation only, not a prediction with a guaranteed bound, proof of liveness,
or original stress PASS. Its child exposed eleven host-derived processors;
the measured delay loop itself is sequential.

The first observation was denied because Scheme's `.740...` floating literal
is invalid JSON. That failure remains recorded under receipt SHA-256
`4dca5b6339a1a7b4a2227e0d6fe028534be5e4182ad40572cc07492c3606cfc3`.
The integer-microsecond observation passed, SHA-256
`b42aa2570989cd50f583ea890441f9f066c21ce42981c7864b0a6e2a6c7dede5`.
Neither observation grants native or release admission.

The claim that device selection blocks while retaining this ticket is also
rejected: the audited path releases it before blocking and reacquires it
afterward. A TFIB timeout alone cannot establish that path as the cause.

## Remaining obligations

Historical milestone remains 6/12. The six outstanding acceptance areas are
complete interpreted stress, shared registry lifetime, lifecycle failure and
rollback, GC/FFI interaction, Gerbil correctness, and release performance after
correctness. This candidate's compiled component pass must survive independently
of the aggregate failure; it must not silently become a whole-SMP pass.

Raw receipts and binaries remain cache artifacts. Their digests above retain
identity without requiring personal absolute paths in versioned evidence.
