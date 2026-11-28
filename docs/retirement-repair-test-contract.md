# Retirement Repair And Stability Test Contract

## Purpose And Evidence Boundary

Passing the current 9/12 milestone is an acceptance checkpoint, not a proof of
stable repeated operation. This contract specifies the extra test obligations
which turn a bounded repair into reproducible engineering evidence. It does not
change the owner's milestone count, start Grok, change runtime sources or select
an Experimental runtime redesign.

The [campaign model](../models/gambit/retirement_repair_campaign.qnt) imports the
[current exit/handoff machine](../models/gambit/retirement_exit_handoff.qnt).
Each successful cohort must actually traverse that machine's callback, saved
stack, sender, join, root/work handoff and release stages before it is credited.
A second cohort gets a fresh incarnation; an old receipt cannot replace its
execution. Work and roots handed to the surviving recipient remain in a
separate cross-cohort ledger. Starting a donor does not clear that ledger;
a distinct last-consumer completion event moves obligations to completed state.
The model checks coverage and exclusive live/completed ownership and includes
a defective restart which loses the recipient's still-live state. Failed joins retain the original machine. Cancellation retains its
state and is not a completed cleanup or a pass. Source changes invalidate active
credit while historical observations remain available.

Two cohorts are a bounded witness, not a native stress population or a complete
native file inventory. The model's independent observation events are abstract;
they must be implemented by source-bound runner/observer events before native
admission. The [Lean companion](../models/gambit/lean/RetirementRepairCampaign.lean)
proves join-once receipt conservation over arbitrary finite event lists, a separate
arbitrary-trace recipient ownership/conservation theorem, sticky
failure retention, refusal to reset unfinished work, and rejection of wrong
VM/incarnation keys. It includes a concrete two-cohort success with BUSY and a
repeated join request. It is a test protocol, not a refinement proof of all C
memory, callbacks or OS behavior.

The Lean `joins` field counts successful join completions in collected receipts,
not failed OS-call attempts. Actual attempt accounting is distinct and remains
visible in the imported QNT `joinCalls` and the native observer obligation.
The ledger theorem is per-identity coverage and exclusive live/completed
ownership, not a native allocation, multiplicity or heap-space bound.
Recipient-ledger proofs assume that a `lastRead` event denotes the real last
consumer; they do not discover omitted consumers or validate a fabricated event.

## What Is Modeled And What Still Needs A Real Fixture

| Boundary | Present evidence | Remaining implementation/test obligation |
| --- | --- | --- |
| Repeated complete cohorts | The existing finite machine runs twice with distinct generation keys; reachable success is checked. | Real supported lifecycle operations, host-derived populations and long-run retained-resource observations. |
| Source change and replay | Active credit is withdrawn on source change; a new cohort cannot borrow the prior receipt. | Source/header/archive/toolchain closure and observer authenticity in the actual runner. |
| BUSY and joined state | General Lean traces ignore another join request at the joined phase and retain failed states exactly. | A source-reachable joined-but-unhanded BUSY/resume path; no such native path is manufactured here. |
| Cancellation | The campaign stops crediting and preserves the underlying model state. | Real descendant quiescence, cancellation timing and all retained resources through the runner's cleanup. |
| VM/configuration identity | Lean keys distinguish VM, source, configuration, incarnation and case. | Simultaneous native VM/cohort schedules and actual authorization; a key is not an OS capability. |
| Completeness | Two declared cohort slots must both be observed and credited; one is insufficient. | Complete branch/file inventory, all actual roots/private producers, nonlocal paths and platform configurations. |

The policy parameter selects corrected and deliberately defective test collectors;
it never changes during a trace. Positive safety covers corrected normal,
source-change and cancellation policies. Each faulty collector has a separate
invariant and decoded violating trace. Liveness is conditional on weak fairness
and the imported finite, returning-C protocol. No claim is made that arbitrary
native callbacks terminate or that every native schedule is represented.

## Reusable Findings From Experimental

| Reference contract | Current-test use | Architectural boundary |
| --- | --- | --- |
| [Independent synchronization keepalive](experimental/retirement-handoff-model.md#independent-synchronization-keepalive) | Hold a real waiter through notification, OS return, runtime restoration and final tail exit; assert synchronization storage survives each live consumer. | Do not invent an independent post-VM carrier inside the current VM. Test that forbidden destruction is refused until a supported carrier exists. |
| [Waiter participation](experimental/retirement-handoff-model.md#waiting-participation-is-a-different-obligation) | Exercise waits which can participate in GC/collectives and waits which cannot. Bind each to its actual wrapper and cancellation/error semantics. | A universal wait adapter or barrier is not selected. |
| [OS return versus waiter exit](experimental/retirement-handoff-model.md#os-return-is-not-waiter-exit) | Pause at each legal boundary and test the last consumer, including cleanup/release tails. Notification and join alone must not authorize reuse. | An ordinary wrapper path does not establish every nonlocal unwind path. |
| [Per-consumer release](current-repair-research.md#per-consumer-release-not-blanket-retention) | Verify root/work ownership is retained or transferred through the last actual read. Permit recipient-owned work after donor retirement. | No blanket full-heap drain, universal retention-until-join rule or transplanted Chez/OCaml ABI. |

These references contribute hypotheses, falsifiers and test obligations. Their
finite passes are not current-runtime passes. Existing Experimental source/Lean
receipts remain attached to their original inputs.

## Test Matrix And Independent Oracles

| Test family | Stimulus and schedule | Independent observable assertion | Negative or sensitivity control |
| --- | --- | --- | --- |
| Repeated cohorts | Public create, grow, execute, shrink and close across new incarnation keys; retain a baseline before and after each cohort. | Exactly one OS join per actual joined worker; no donor reuse before handoff/cleanup; original Scheme outcomes preserved in each cohort. | Replay the preceding receipt for the next cohort: it must leave coverage missing. |
| Joined but unhanded | Arrange real work/root/borrower contention at a supported source boundary; resume the supported transfer operation after BUSY. | Original joined identity remains retained; resume performs transfer and clear without a second join. | A second join request or clearing before handoff is an actual counterexample, not an injected successful join. |
| Terminal join error | Use a legal source fixture and natural OS result when one exists. Otherwise record the branch as a model/control obligation. | Original error, target identity and retained resources remain; destructive setup cannot erase failure. | A detached/self-join or interposed errno is labeled ownership-breach/injection control, never recovery evidence. |
| Callback and exception tails | Real nested FFI entry, normal result, exception return and cleanup callback; synchronize through supported entry points. | Compare result/error and root values against an independent Scheme expectation; every acquired entry/frame is released once on its origin. | Marker invalidation or release invocation alone must not satisfy tail completion. |
| Root and collector phases | Force actual supported collections while live Scheme values, captured stacks, RC/still ownership and claimed work cross the legal boundary. | After reload, semantic values and descriptor interpretation match the oracle; source/destination ownership covers each declared live root. | Deliberately omit a declared root/work class in the model; a real test without that coverage cannot claim the class. |
| Remote sender and waiter tails | Synchronize real sender unlock/signal and waiter restoration/tail exit around retirement. | Storage remains valid while any actual sender/waiter can access it, independently of receiver join and registry counts. | Notify/OS-return-as-exit controls must be rejected by the corresponding model. |
| VM and generation isolation | Run independent public VM/cohort operations where supported; inject stale *requests/receipts* from prior identities through the observer, not runtime private fields. | An event for another VM/source/configuration/incarnation cannot discharge the current case. | Same pointer address or recycled pthread ID does not establish current authority. |
| Build/source identity | Change one declared source, generated header, compiler/configuration, archive or test inventory between plan, build, run and readback. | The affected dependency closure is rebuilt; changed or partially completed inputs remain inapplicable. Preserve historical valid receipts. | Old build plus new header, old module plus new runtime, or subset inventory cannot produce a whole-current-source pass. |
| Failure and cancellation | Stop a real child at supported stage boundaries; retain failure receipts; use the existing process-group watchdog and cleanup. | Failure is not success; descendants are accounted for; no active resource is silently reset. A resumed run starts only from a valid source-bound stage. | Log traffic, diagnostic markers or a model pass cannot reset the hard deadline or turn timeout into completion. |
| Long-run stability and cost | Repeated source-matched correctness campaigns, then separately declared performance populations, under controlled interference. | Stable semantic results and bounded retained-resource growth; compare cold/warm phases only with matching workloads and identities. | A fast subset, correctness timing, contaminated run or widened timeout is not a release population. |

Provenance archives intentionally grow with completed cases. They are not live
runtime ownership. Resource-growth tests must separately observe active VM,
thread, FD, callback/root and retired-storage obligations, with explicitly
permitted survivors and a pre/post cohort baseline. The present Lean receipt
list does not prove allocator bounds, OS-handle bounds or absence of native leaks.

Each real fixture must declare its supported API, source callsites, root/work
classes, legal synchronization points, oracle, genuine progress events, budget,
cleanup contract and missing branches. Use latches/barriers at legal boundaries;
a sleep or 'thread started' message is not proof of entering `pthread_join`.
Do not mutate private pending fields, manufacture runtime success, rewrite memory
images or replace a natural path with a handwritten mirror.

The existing [completed-work watchdog](../models/gambit/completed_work_watchdog.qnt)
and [stage retry clock](../models/gambit/stage_watchdog_retry.qnt) already model
noise versus genuine work and attempt/phase clock separation. Reuse those
contracts with each runner's declared hard-wall or inactivity semantics; this
campaign does not replace them with another clock. The existing
[failure scope](../models/gambit/failure_campaign_scope.qnt) and
[resource correspondence](../models/gambit/native_resource_plan_correspondence.qnt)
keep a resource-budget diagnosis distinct from semantic failure or acceptance.
These links identify reusable obligations, not a new execution of those models.

The expanded tests must enter a declared complete inventory and a measured CI
resource schedule. Passing each 30 s model check does not prove that the whole
CI job fits its original wall budget. Reuse exact-input receipts or partition
independent checks with complete coverage/provenance; do not silently skip a
family, enlarge a timeout or relabel partial CI as a full pass. Whole-framework
CI and real native/Gerbil execution for this extension remain unqualified.

## Coverage And Repair Workflow

1. Bind the first actual failure and source/configuration/ABI identity. Keep the
   original failing receipt, input and budget.
2. Check the relevant model with an omission control that actually violates the
   claimed property. Retain a reachable repaired success and a retained failure;
   refusal of every case is insufficient.
3. Map every critical model event to a source producer and a separate observer.
   Identify which borrowed storage, roots and interpretation metadata that event
   actually covers. An unimplemented event stays an open source obligation.
4. Run a focused real fixture and its matched control on the changed dependency
   closure. A mirror is useful only as a separate protocol control.
5. Run the full current native inventory and Gerbil build/test, then repeat the
   lifecycle/cancellation/identity families above with distinct cohort keys.
   Only actual completed required cases supply coverage; duplicates add none.
6. Re-read exact inputs and receipts after the run. Source/recipe changes revoke
   applicability only where causally relevant; they do not erase history.

The existing ASCENT composition relations remain the evidence interface. New
source semantics require explicit scoped edges and checked QNT/Lean interfaces;
old local passes cannot cover new properties. This campaign adds no native
`satisfies` fact and is not registered as a C refinement. Python tests invoke
existing formal backends and decode their evidence; they are not a second
semantic oracle for the retirement algorithm.
