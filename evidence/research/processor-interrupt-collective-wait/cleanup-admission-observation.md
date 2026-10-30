# Lifecycle Admission Rollback And Work Accounting

## Scope And Current Source

This closes a precommit admission-prefix rollback branch, not the complete
lifecycle gate. Cumulative progress remains **8/12**. No new C patch is justified:
the current `close_cleanup_sfun_vms`, `sfun_vm_try_close` and `sfun_vm_reopen`
already implement the reviewed prefix unwind. Validation consumes the existing
source/configure/seed/core checkpoint; all four report `executionLaunched=false`.
No bootstrap, runtime interposition, debugger or fault-injection hook is used.

Source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
Cumulative patch: `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
GNU GCC 16 and the retained Bazel profile retain SMP, multiple VMs and multiple
threaded VMs. Host capacity is supplied by the framework, not a fixed CPU count.

## Real Native Observations

| Workload | Compile | Execute | Whole campaign | Outcome |
| --- | --- | --- | --- | --- |
| Last-child rejection predecessor | 1.412485 s | 0.889433 s | 13.678418 s | PASS, natural exit 0 |
| Every child-list position successor | 1.472151 s | 0.583235 s | 23.935027 s | PASS, natural exit 0 |

The observed host exposes 12 available CPUs. The fixture derives `CPU - 2`
independent single-processor child VMs: ten here. The successor visits all ten
child positions. Each round creates a real public `c-define` frame in the chosen
child, calls checked global cleanup, requires `INVALID_OP_ERR`, and verifies
that every admission gate and global setup state are restored. Every child then
performs another public FFI callback with a rooted vector across forced GC.
This yields ten rejected global attempts and 100 post-rollback callback returns.
All owners subsequently perform checked owned cleanup and real pthread joins.
No timeout occurs; parent reaping and process-group quiescence are recorded.
The post-call gate observation does not prove that the suffix was never touched;
prefix-only undo and suffix nonmutation are separate source/model correspondence.

The two times are **different workloads**, not a matched speedup. Neither one
sample nor the aggregate campaign duration establishes P55/P99, a stable latency
baseline, a release performance gate, or a VM-throughput improvement.

Native source SHA: `61209c5b8151b837f3f94ef2292551891fd40549bd8463ba8092d62435766664`.
Successor outer receipt SHA: `3823631ff6ac8fdeb6e7f0b5cfa791511a75d2175394ba6d4d3a0febf4d6d52d`.
Successor child receipt SHA: `64baee26c0ff596b7830118084946fb6eb8170b69278c60b3d66e240f606303f`.
Predecessor outer receipt SHA: `f2ef3ab0c11e90a4c6a5c490c6cd8246848e16694d1db9cb65dfc342d5b8bed2`.

Raw process records remain disposable cache observations; these reviewed source
identities and scope are durable evidence, not executable-cache admission.
Later proof-only work-accounting additions do not rewrite either native receipt
or grant a CURRENT whole-input verdict to the earlier execution.

## Conditional QNT And Lean Contract

The existing `vm_registry_global_cleanup_preflight.qnt` now additionally models
the sequential admission scan, a busy member reopening its own gate, prefix
undo, and retry after actual frame return. All busy-member subsets of three
abstract list positions are explored. These positions are not a CPU limit.
The earlier population/pending-join checks remain separate; this is not full
composition with arbitrary concurrent FFI entrants or host lifecycle writers.

Eight explicit trajectories include missing undo, early commit and redundant
scan controls. A finite safety/progress check binds the current source, fixture
and Lean source. The progress premise is weak fairness; it proves termination
of this finite scan/undo protocol, not OS starvation freedom or callback return.

Work is counted **per attempt**: each VM is inspected once, each successfully
closed prefix member is reopened once, and gate operations are at most twice
the inspected VM count. The negative redundant-scan policy remains safety-correct
but violates this work contract. No SMP flag is disabled to satisfy the bound.

`CleanupAdmissionWork.lean`, using the existing pinned LeanPoo dependency,
generalizes the arithmetic to arbitrary VM counts and processor populations:

`frameProbes + gateAttempts + rollbackReopens + busyReopens <= processorBudget + 2 * members`.

The premises require at most one gate attempt per visited member, processor
probes bounded by the sum of their populations, and at most one reopen per
attempted gate. Source correspondence is a separate review obligation. The
theorem counts operations in `close_cleanup_sfun_vms`, not the entire checked
cleanup, lock waiting, hardware CAS retries, scheduling, allocation or GC.
The separate child-population preflight adds its own linear list scan.
Sequential retries add their actual costs; resetting per-attempt QNT counters
does not erase prior work. QNT retains separate cumulative counters across a
bounded reject/retry composition; Lean bounds an arbitrary list of attempt
costs by its length times an established per-attempt bound. The exact three-work
units per visited member equality has an explicit single-processor premise;
general populations use the list's processor-population sum instead.
A false extra-reopen arithmetic control is rejected.
Lean elaboration uses the existing process runner with 15-second watchdog,
200000 heartbeats and recursion depth 512; no unguarded Lean process is used.

## Retained Failures And Open Requirements

The first model manifest was rejected for a missing temporal contract. Subsequent
model attempts exposed uninitialized independent state, mismatched action effects
and duplicate updates; those receipts are retained, not counted as passes.
One Lean elaboration rejected a reserved binder name; its bounded failure is
retained. A model run whose Lean context changed remains a rejected aggregate
even though its individual checks passed. No timeout or assertion was weakened.

Grok independently audited the constructor gaps and the initial last-child
fixture. It identified absent middle-position and global-retry coverage; the
successor adds all child positions. Grok did not author a new C fix or execute
these native tests. The supervisor implemented and ran the additional contract.

| Remaining milestone gate | Actual state |
| --- | --- |
| Lifecycle faults / rollback / retry | Admission-prefix rejection and FFI reentry now have current-source native coverage. Constructor allocation/publication failures with same-storage retry, failed OS joins and sticky root failure remain unqualified. The disallowed RTLD_NEXT fixture is not used. |
| Complete GC/FFI | Forced-GC callback roots add coverage; complete GC/FFI and unwind/failure composition remain open. |
| Gerbil correctness | No full build/test receipt for this exact producer is added here. |
| Release performance | Conditional linear work model is added. Matched repeated latency populations and downstream build/test timing remain open. |

Current-source full GSI/GSC and PR requalification are still release obligations;
historical successes and cumulative 8/12 do not replace them.
