# Procedural interrupt retirement: native observation

## Bound candidate

- Source lock: `source.lock.json`, SHA-256
  `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
- Cumulative patch: `patches/fixtures/processor-interrupt-collective-wait-cumulative.patch`,
  SHA-256 `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
- Native program: `models/gambit/native/procedural_interrupt_retirement.scm`,
  SHA-256 `688de26dde95b2d8f05da13e123e343a1e9308a4d625e3bf40c56615f7cff050`.
- QNT: `models/gambit/procedural_interrupt_retirement.qnt`, SHA-256
  `328c7874cd41b86197d0285626653a2f7791c2a82410cddc6f6a47b0a8bff575`.
- Existing Bazel profile retains SMP, multiple VMs and multiple threaded VMs.
  Actual compiler is GNU GCC 16.2, not Clang.

## Reproduction and checkpoint reuse

Use the existing research runner with `procedural-retirement.recipe.json`, the
existing sealed registry-lifetime engine and the original collective-wait
native checkpoint as `--prior`. No runtime source changed in this experiment.
Source, configure, seed and core steps all recorded `executionLaunched=false`.
No bootstrap, fresh source tree or feature-disabling build was performed.

Raw observations remain under the ignored cache directory
`.cache/processor-interrupt-collective-wait/procedural-retirement-native`.
The outer receipt SHA-256 is
`f0b8180dc4055c0a2533be278254d01ae59ecbf4a795229c10635321aa292306`;
the child receipt SHA-256 is
`f910d143f4fed2f68361734959dcb925164b31600f16d7d256dbf30dc3add0a2`.
No cache path or cache existence is required to reproduce the registered recipe.

## Actual assertions, not inferred schedule coverage

The host capacity observation was 12 available CPUs. External producer count
was derived as capacity minus one: 11, not a source-coded machine constant.

1. A real procedural callback entered through the public service API and waited
   on host synchronization after the runtime removed it from the queue.
2. Under the actual queue mutex, the owner observed zero queued items while
   that callback had not returned and the mutex remained live.
3. Eleven external pthread producers each enqueued a distinct procedural item
   while the callback was still suspended. Every producer joined; queue size
   was exactly 11 and the callback still had not returned.
4. Releasing and joining the consumer completed exactly 12 callback executions
   and left the queue empty. This includes the service loop's post-callback
   relock, not just callback entry/return markers.
5. The owner enqueued 11 more items with no remaining consumer. Public VM
   cleanup released exactly 11 items with `op=false`; each release observed
   the mutex still owned/live. Afterwards the readiness flag was false and
   the child was absent from the global VM list.
6. A separate global broadcast producer remained enabled across child cleanup,
   produced before and after retirement, and joined cleanly. This does not
   prove an individual broadcast overlapped the internal close instruction.

The process exited 0, stdout was exactly
`PROCEDURAL-INTERRUPT-RETIREMENT:PASS`, stderr was empty, and no timeout occurred.
Compilation took 3.232650292 seconds, execution 0.531868417 seconds, the native
stage 4.857896709 seconds, and the supervised invocation 13.339536416 seconds.
These are one bounded diagnostic observation, not release latency percentiles
or a measured speedup against a matched baseline.

## Formal and evidence boundary

TLC exhaustively checked the positive finite abstraction (119 distinct states),
including safety, enabled progress and conditional temporal progress. All three
negative policies produced the expected invariant counterexamples. Five
explicit Quint trajectories also passed with one sample per trajectory.
The published portable result is
`evidence/model-results/processor-interrupt-collective-wait/procedural-retirement-qualified/receipt.json`.

The first verifier launch lacked sandbox loopback permission and failed before
model checking. That failed launch remains in cache; the authorized checker
run is separate. No timeout, parser or invariant was weakened.

This establishes reachable empty-queue/nonquiescent-consumer state and working
joined-owner retirement for this schedule. It does NOT establish a legitimate
concurrent destruction bug, all possible external embeddings, root signal
handler quiescence, weak-memory correctness or failed-join recovery. Destroying
while a direct user is unjoined was not run, because it violates the ownership
premise and may invoke undefined behavior. No speculative C patch was added.

## Milestone scope

Cumulative progress remains 8/12. The lifecycle gate gained a real native
producer/consumer witness; it is not complete. Its remaining subobligations
include additional constructor failures, rollback and join failures, and the
root signal in-flight boundary. Full GC/FFI, current Gerbil build/test and
release performance remain the other three unclosed milestone groups.
