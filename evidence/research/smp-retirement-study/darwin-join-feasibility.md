# Darwin join feasibility: OS error versus deferred retirement

2026-10-23 source/design review. The audit recorded qualification 8/12; that is an observed result, not a policy that fixes the count. Statements about no runtime/native/qualifier/recipe edits describe the original author's evidence-only execution scope, not a prohibition on another implementation owner.

Implementation sequences below are conditional design dependencies, not an approved executable work order or permission grant. They must first be resolved against one current, coherent source/generator/header/generated-C/producer identity. Per-file historical line numbers are evidence coordinates, never cross-generation patch offsets. This scope clarification does not alter the original observations, model logs, native receipts or qualification predicate.

See [recursive-ffi-journal.md](recursive-ffi-journal.md) for the corrected status: the cumulative one-winner foreign release patch is recorded as landed, while journals/control-reference lifetime, internal wills, checked bridges and new generated C remain unimplemented proposals in these reports. Plain-release-function observations below describe their saved snapshots and must not be read as instructions to redo the landed claim. The lock is the source authority here; the separate vendor engineering checkout is not required to match it and is not a drift test. Patch/lock agreement is not a configured build or current gsi certificate.

## Conclusion and domain

Under the reviewed Darwin branches, a valid joinable distinct worker, an
exclusive live OS owner, no competing join/detach/cancellation and the current
Gambit shrink graph do **not** supply the required nonzero/non22 join return
followed by same-owner same-target join0. A normal join may block until worker
exit, then return0. More retries do not establish the missing first error.

This is a conditional source/contract conclusion, not a theorem about all macOS
versions or all pthread programs. A broader program can cancel the target in a
join cycle and later join it successfully from the original surviving owner;
the historical report describes that boundary. Cancellation is excluded from
the supported Gambit retirement contract and does not certify Scheme root or
callback cleanup. Same-owner recovery is therefore not universally impossible;
it is unsupported by the current legitimate shrink graph and acceptance trigger.

## Pinned primary sources and identity boundary

Apple source is pinned at revision
`42d026df5b07825070f60134b980a1ec2552dfee`,
[pthread_cancelable.c](https://github.com/apple-oss-distributions/libpthread/blob/42d026df5b07825070f60134b980a1ec2552dfee/src/pthread_cancelable.c#L339).
The full licensed snapshot and SHA256 are retained through
`darwin-join-feasibility-sources.json`. It was fetched independently from the
public repository. It is **not matched to this host's deployed libpthread**.
Host inventory is macOS26.6.1 build25G76 / Darwin25.6.0. The local SDK join manual
and header were read; only ordinary pthread_join is declared among the searched
join/tryjoin/timedjoin names. That is an SDK observation, not a global export proof.

In the pinned implementation, `_pthread_join:353–383` validates the target,
rejects nonjoinable/occupied join context, detects self/two-thread-cycle cases,
and otherwise waits or consumes an exited target. `_pthread_joiner_wait:279–336`
loops on interrupted underlying waits; successful owner cancellation exits the
waiter instead of returning a retryable errno. The
[POSIX Issue8 contract](https://pubs.opengroup.org/onlinepubs/9799919799.2024edition/functions/pthread_join.html)
also excludes EINTR as a join return. Invalid-ID/self/concurrent cases must not
be promoted to portable legal recovery merely because Darwin diagnoses some.

The following table is the source-derived interpretation, with exclusions made
explicit rather than hidden in a model's joinFail action.

| Case | Why an error can occur / what changes | Same-owner later0 in supported shrink? |
|---|---|---|
| Live valid worker, exclusive owner | Wait for target exit; then0 | First failure absent. |
| Signal interrupts native wait | Library loops; it is not a returned EINTR | No error/recovery sequence. |
| Self join | Identity remains self while owner survives | No; diagnostic, not retirement. |
| Two-thread cycle A→W and W→A | A receives EDEADLK while W waits for A | Ordinary W cannot finish its join of live A. Retry retains cycle; A exiting destroys same OS owner. |
| Cycle plus target cancellation | W can leave its join via cancellation; surviving A can later join W | Wider-API reachable, excluded runtime repair; must not be counted as safe worker retirement. |
| Joiner cancellation | A exits without returning an errno; W remains joinable | Different live joiner required, not same-owner return/recovery. |
| Invalid/stale target | ESRCH-style diagnosis; reused numeric handle is another generation | No same-target proof; ownership bug/retained failure. |
| Detached/nonjoinable or occupied target | EINVAL; a competing join violates exclusive ownership | Excluded22 and/or unsupported concurrency. |

## Runtime defects remain real

The final experiment GSI7263fe03... still lacks a retirement ledger and deferred
same-owner recovery; its error branch only returns an error. Its checked shutdown
is intentionally sticky-retained, not a resumable operation. These deficiencies
must be fixed according to the desired runtime contract even though the current
native acceptance predicate is not realizable by this shrink graph. Neither
acceptance infeasibility nor QNT success proves runtime correctness.

Source ordering is precise: P0 calls join **after the reduced-count collective
boundary**, not necessarily after the OS worker has already exited. Worker local
cleanup leads to thread_exit; join0 establishes completed exit. Reordering join
earlier does not turn waiting into a nonzero return. Per-P still/RC allocation
retention is not scanning coverage after cohort reduction; live roots/work need
preparation and an actual traced handoff before exclusion from GC participation.
The detailed source table remains in `lifecycle-join-recovery-gap.md`.

## Executable plan for Grok

**Recommended contract proposal: deferred retirement is a runtime status, not a
fabricated OS errno.** Keep native fatal/error retention separate from retry-later.
Do not change the formal observer, recipe or count without explicit reviewed
contract authorization. Keep the current gate open meanwhile.

1. Review two distinct outcomes: (a) retirement not yet ready, with handle,
   generation, queues and traced roots still owned; (b) actual OS join failure,
   with exact native error retained/poisoned. Only the first has an ordinary
   retry-later path. Never encode it as EDEADLK or call it an OS join failure.
2. In `___vm_resize_pstate` introduce prepared/retiring/join-pending/joined/
   drained/transferred states with immutable VM/donor/epoch and owner IDs.
   Prepare under the old cohort, service nested GC, preserve callback and work
   suffixes. Commit membership only when every required preparation succeeds;
   failure before commit restores the same cohort consistently.
3. For a production design that cannot let blocking join stall the surviving GC
   cohort, use a dedicated native retirement reaper as the **fixed OS join owner
   from its first attempt**. It owns no Scheme frames and never executes Scheme
   callbacks. It receives a generation-bound native handle after the traced
   handoff, performs the real blocking join once, and release-publishes its actual
   result to P0. P0 acquire-consumes completion, checks remaining borrowers,
   transfers/cleans exactly once and only then allows slot reuse. Logical P0
   administration and OS join ownership must be separately named; a new reaper
   cannot be called the same old P0 OS owner to satisfy the historical predicate.
4. Root/callback preparation and grace are prerequisites for that worker, not
   consequences of a native queue. A bounded/preallocated ledger, retained root
   carrier and nonblocking completion notification need their own failure paths.
   Reaper startup failure must refuse the resize before commit; lost completion
   must leave an inspectable retained ledger, never free the worker slot. A final
   worker acknowledgement before pthread_exit is not by itself a native join.
5. Exercise the native supported protocol twice on the same completed producer:
   intentionally delay readiness at a controlled supported pre-join boundary;
   observe real runtime pending without claiming errno; force GC and verify
   roots/work; let normal worker retirement complete; consume actual join0;
   verify one transfer/cleanup and successful requested resize. Test repeated
   epoch, multiple donors, wrong owner, pending cleanup, completion notification
   fault and preparation rollback separately. Keep exact original budgets and
   host topology; do not substitute bigger heaps, timeout changes or fake errors.
6. Run actual OS error controls as retention/diagnosis evidence, distinguished
   from normal pending recovery and from full native qualification. Deliberately
   injected failures cannot certify an unmodified OS error path. Only after an
   explicit contract review can the two pending→join0 campaigns become the new
   lifecycle requirement. Migrate recipe/probe/observer/QNT and historical run
   bindings together, retaining all old DENY/banner receipts and8/12 history.

If the existing OS-error11→same-owner0 predicate is retained, the executable next
step is **contract feasibility review**, not another runtime rebuild or two reruns.
A claimed implementation must first demonstrate its legitimate trigger and
root-safe causal escape from that trigger. This audit found no such trigger for
the current shrink graph. The reaper plan is proposed architecture, not a tested
implementation, a small patch guarantee or automatic approval to change the gate.

## QNT correspondence and bounded verification

Model: `models/gambit/darwin_join_feasibility.qnt`.
Runner: `evidence/research/smp-retirement-study/verify-darwin-join-feasibility.py`.
Both are repository files; snapshots/logs/decoded traces are in registered audit
run `7a0968cc922c4c05878d8b6cc457f23d`, output `darwin-join-feasibility-model`.
All10 controls accepted with unchanged30s per-case cap, Quint0.33.0/TLC:

| Control | Check / actual result | Mapping and limit |
|---|---|---|
| initPlatform | Safety across8 platform scenarios | Wait/loop/error/owner-cancel branches; no legal native error→0 in the restricted graph. |
| initDeferred | Safety and fair completion | Runtime pending before join, rooted ownership, worker exit, one native join0, one transfer. |
| initCancelTarget | Safety in wider API | External cancellation is explicit, not hidden in fairness. |
| cancelTargetReachability | Decoded counterexample to `notRecovered` | Explicit canceled-target state with first11, second0, original owner alive; reachability witness, not a mutant success or native result. |
| initInventError | Expected invariant counterexample | Making a first native error appear on normal shrink. |
| initBreakCycle | Expected invariant counterexample | Letting a cycle target exit with no legal cycle-breaking event. |
| initReturnEintr | Expected invariant counterexample | Treating interrupted native wait as returned EINTR. |
| initBusyAsErrno | Expected invariant counterexample | Relabeling runtime pending as OS errno. |
| initFreePendingRoots | Expected invariant counterexample | Losing retained roots before join/handoff. |
| initJoinTwice | Expected invariant counterexample | A second join after completed join. |

`initDeferred` has3 distinct one-way steps plus target-exit progress under the
model's fairness premise. It assumes worker retirement eventually progresses;
it does not claim termination for user callbacks that never return. Root coverage
is an explicit abstraction, not proof that a C frame or new reaper queue is traced.
The model has one target and an implicit fixed owner/epoch; it does not establish
multi-donor provenance, real host ABI or the proposed reaper implementation.
It is a feasibility/discrimination companion to existing joint root/work models,
not a replacement for their obligations. Old `joinable_error_same_owner.qnt`
permits independent joinFail/joinOk; that abstraction cannot prove native trigger
reachability. Its historical receipts remain untouched.

Reproduce only the evidence model, with its registered audit role:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-darwin-join-feasibility.py
```

No new pthread/native/SMP campaign ran in this task. The initial eight-control
model receipt is retained; the final revision adds the wider-API cancellation
boundary and all10 controls were rerun against its new model identity.

## Separate qualification gates and user-provided historical facts

The39 fault/device/request checks remain bound to the same GSI7263fe03... and do
not move lifecycle admission. GC/FFI, Gerbil and release remain independent.
The latest user report distinguishes interrupt2's two-argument vector-inc
arity exception/result-mutex path from interrupt flood stopping in select at
small heaps. Larger heaps' intermittent completion is not a stability repair.
The reported older collective-wait stress completion and unsuccessful transplant
are historical user-provided facts, not new native reproductions in this audit.
Gerbil TYPEID unique source cause remains unestablished; release qualification
requires the correctly accepted producer. None can substitute for lifecycle9/12.
