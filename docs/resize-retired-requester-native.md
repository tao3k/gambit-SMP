# Resize Retired Requester: Native Counterexample

## Source and Runtime Boundary

The source authority is the pinned Gambit submodule plus the cumulative
`sync-message-atomic-publication` overlay and source lock. The execution artifact
was produced by the successful `sync-message-atomic-publication-source-core`
campaign. Its 956 input hashes and all three artifact hashes were checked before
and after each native observation using the existing `check_runtime` primitive.

The runtime has SMP, multiple VMs and multiple threaded VMs enabled. This is not
a full bootstrap, Gerbil acceptance, or performance admission.

## Adaptive Capacity

The launch capacity was obtained from the host CPU count, capped by process
affinity where available, and verified through the actual VM processor count.
This host reported 12 available CPUs. That is an observation, not a configured
worker limit. Only one native process ran at a time.

The lifecycle fixture derives `population` from the actual VM and uses that
population as its round count. The single-processor phase is an intentional
shrink topology, not a host build concurrency setting. The 64 keys are a data
fixture bound, not a thread limit.

## Native Observations

All observations had a 30-second whole-process budget and a quiescent process
group after completion or termination.

| Case | Exit | Seconds | Outcome |
| --- | --- | --- | --- |
| Actual processor population | 0 | 0.672139 | `PROCESSORS:12` |
| Mixed-key forced GC | 0 | 0.071715 | `NATIVE-OK:gc_key_tags` |
| Initial resize/GC lifecycle fixture | -9 | 30.007989 | Timeout, DENY |
| Phase-instrumented lifecycle diagnostic | -9 | 30.009156 | Timeout, DENY |

The diagnostic did not widen the budget or change the lifecycle protocol. It
added entry/return observations to locate the original failure:

```text
(resize-enter 12 1 caller 0)
(resize-return 1)
(resize-enter 1 12 caller 0)
(resize-return 12)
(resize-enter 12 1 caller 1)
```

No return was observed from the last call. The fixture's later replacement of
the fixed round count with the detected population is not yet separately run;
do not attribute these observations to that latest byte identity.

## Source and Model Finding

`___current_vm_resize` submits the operation on the calling processor.
`___vm_resize_pstate` exits a nonzero processor when its ID is at least the
target population. No requester continuation handoff is established by this
path. The trace is consistent with loss of a calling Scheme thread running on a
retired processor; stack-level confirmation and a safe handoff repair remain
required. Pinning the regression caller to processor zero would hide this case.

The prior `resize_commit_startup_round` initializer restricted requesters to
retained members. The new `initRetiredCaller` control includes a requester in the
retired set; `requesterCompletionSafe` requires that a completed acknowledgement
round has returned to the requester.

Quint 0.33.0 Rust simulation with seed 1, one sample and 80 steps found an
invariant violation in 72 ms. This is a bounded counterexample, not exhaustive
verification. A first invocation using the existing `safe` invariant failed
because this simulator does not implement `enabled`; that tool failure is not a
protocol counterexample. Historical exhaustive receipts bind the prior model
bytes and must not be represented as verification of the extended model.

## Repair Requirements

- Transfer the requesting Scheme continuation and reachable roots to a retained
  processor before retiring its OS processor, or explicitly reject the request
  before any membership publication. Rejection would change the API contract
  and is not an accepted repair here.
- Preserve exactly-once operation completion, authoritative result delivery and
  thread queue ownership during transfer.
- Model current-thread, runnable and pinned-thread drain together with GC root
  ownership, startup acknowledgement and join/resource retirement.
- Validate the original unpinned native lifecycle after a source repair, then
  compiled execution and broader upstream tests. Do not rerun the unchanged
  timeout route merely with a longer budget.

## Exhaustive Thread-Drain Design Contract

`resize_scheme_thread_drain.qnt` adds running, queued and parked Scheme-thread
roles, closed admission, explicit cooperative pin release, save-before-publish,
retirement, join and requester completion. Two processors and three roles bound
the state space; neither is a runtime capacity setting.

The positive protocol explored 40 distinct / 81 generated states with safety
and temporal progress accepted. Three negative controls produced invariant
violations: exit without ownership transfer (5 states), publication before
clearing execution ownership (28 states), and ignoring a pin (36 states).
Host-auto scheduling selected two control checks with six TLC workers each and
12 workers for the positive check. The campaign took 20.126 seconds.

Portable authoritative evidence is
`evidence/model-results/fixtures/sync-message-atomic-publication/scheme-thread-drain-bound-contract/receipt.json`.
The Datalog bundle registry binds this receipt and manifest. Direct fact
recovery validated one checked model, three controls, four source references,
six unresolved obligations and 13 bound inputs. Adding the explicit empty
composition list reused unchanged verified model checks; no TLC rerun was used
to disguise an earlier failure. The initial sandbox loopback denial is a tool
restriction, not a protocol failure.

This is a design contract, not a source implementation. In particular:

- Atomic model actions abstract scheduler locks; no concurrent pin-release,
  foreign reentry, C weak-memory or arbitrary-population proof follows.
- `roots` are ownership tokens. The native timeout does not itself prove that
  GC dropped the Scheme object: `mark_processor_scmobj` and `mark_vm_scmobj`
  scan Scheme structures. Reachability and runnable execution ownership must be
  audited separately.
- `___THREAD_SAVE` stores a continuation frame into the thread, but does not
  itself clear the processor's current-thread or establish safe publication.
- `##thread-migrate-to!` publishes to the target queue before clearing the
  source processor's current-thread and uses a fixed busy-wait TODO. That is not
  an acknowledged handoff protocol and must not be treated as the repair.
- Successful OS joins and cooperative unpinning are assumptions. Permanent
  pins, failed joins and GC phase/drain composition remain explicit obligations.

The runtime and release admission flags remain false. The unchanged failing
native route remains denied.
