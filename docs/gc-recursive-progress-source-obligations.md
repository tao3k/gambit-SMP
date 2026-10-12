# Recursive GC Progress: Source Obligations

## Identity And Scope

This is a source/paper audit, not a model-check receipt or native acceptance.
The reviewed base is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
`evidence/runtime-source.lock.json` binds the base files, candidate027 overlay
and resulting `mem.c`, `setup.c` and `gambit.h.in` bytes. All three base/candidate
hashes and the overlay hash were checked. Candidate line numbers below refer
to that reconstructed source, not the differently numbered base submodule.
Local reconstruction is not evidence that these inputs are committed or that
any configured binary was rebuilt from them.

The cached GHC sections 3.4-3.5 and HotSpot section 3.3 were re-read, with both
PDF pins and cache extraction hashes checked against `evidence/papers.lock.json`.
No download or unchanged failed native/checker route was repeated.

## Enabledness Is A Separate Obligation

The ranking matrix and independent arithmetic rule constrain transitions that
occur. They do not show that a nonterminal state has a transition. Establish
`candidateInvariant => terminal or enabled(actualStep)` separately, using the
same full candidate domain and unchanged original transitions.

Apalache's rejection of native `ENABLED` is a tooling limitation, preserved in
`evidence/model-results/quint-symbolic-enabledness-unsupported/`. It is neither
a protocol counterexample nor an enabledness proof. An alternative projection
must derive existential action parameters, all guards, and satisfiable next-state
assignments from the original public IR. Handwritten guard-only predicates,
empty-choice suppression, partial parameter enumeration, or a successor filter
that conceals an invalid original update do not establish this equivalence.
Record correspondence checks and controls that remove a real enabled branch or
create conflicting assignments; neither may retain a false positive.

An arbitrary candidate-domain deadlock is not automatically reachable from
original Init. Conversely, restricting the generator to convenient reachable
samples does not prove candidate-domain enabledness. A changed induction premise
needs renewed Init inclusion and unchanged-action closure, not a new success guard.

## Source Correspondence Gaps

| Obligation | Reviewed source and model difference | Required evidence |
| --- | --- | --- |
| Notification and recheck | Candidate `end_heap_chunk:3455-3456` releases Q and signals without M. `mark_reachable_from_marked:6955-6984` takes M, decrements the count and waits without a queue recheck. The model's combined `acquireSignalMutex` and `probeRecheckQueue` are not implemented by this source. | A causally justified runtime candidate, Q-before-M release ordering, predicate recheck and matching publication/wait schedule tests. Do not call combined-policy results current-source refinement. |
| Repeated steal probes | Candidate `mem.c:6910-6918` performs `(np-1)*1000` probes using the source queue-selection formula. The finite model retains the first-occurrence order for four workers, not every retry and failed locked recheck. | An explicit concrete-to-abstract stuttering map, finite control-loop progress, memory-read assumptions and lock-acquisition obligations. An unlocked empty hint is not a simultaneous queue snapshot. |
| Unbounded wakeups | Candidate `mem.c:6973-6984` can return from waiting, restore the count and enter the outer loop again. QNT `spuriousWake` consumes a once-per-worker budget; the rank includes that consumed budget. | Separate the bounded-model theorem from an unbounded source/environment theorem. Do not extrapolate the rank through arbitrary repeated wakeups or remove actual retry behavior. |
| Terminal wake/drain | Model `countOrRetry` wakes every waiting worker in one state update and `terminal` also requires all modes done. Candidate `mem.c:6961-6964` signals repeatedly while holding M, followed by separate returns and mutex acquisitions. | Registration/population closure, eventual return/reacquisition, zero-count observation and participant exit mapping. GC completion alone does not retire unrelated synchronization senders. |

The base source has the corresponding steal/count/wait logic at
`vendor/gambit/lib/mem.c:6694-6767`; the overlay adds other changes and shifts
locations. Preserve the candidate's acquire fence and cursor exclusion. These
findings do not establish a new native crash or attribute an old failure.

## Fairness And Divergence

`weakFair(step, Set(s))` concerns the entire action disjunction. For the bounded
model, strict bounded progress on every nonterminal transition can make that
aggregate condition useful once enabledness is established. It is not a proof
of per-worker scheduling, mutex/ticket fairness or eventual condition return in C.

After removing the wake budget, a potentially starving worker may remain
continuously able to copy while another worker repeatedly wakes, restores its
count, probes empty queues and waits again. Such an abstract schedule can take
the overall disjunction indefinitely. Aggregate weak fairness alone does not
require the copier to run. This was initially a fairness coverage argument.
The [focused wakeup audit](gc-wakeup-fairness.md) now archives actual TLC
cycles from both unchanged initial policies, evaluated against the complete
action-disjunction fairness predicate. Its first-copy controls do not prove
whole-GC progress or establish an observed native schedule.

State exactly which scheduler, waiter and lock assumptions are required and
which are justified by the implementation. Supply a divergence-sensitive map
for hidden probes/retries: infinitely many concrete internal steps cannot be
declared a finite abstract stutter without a termination argument. Stronger
fairness assumptions are assumptions, not runtime fixes. The two papers do not
prove Gambit's condition-variable protocol or the host scheduler's guarantees.

## Paper Correspondence And Engineering Gates

GHC section 3.5 polls pending work while another scanner remains active and
rejoins the active count before scanning. HotSpot section 3.3 similarly revisits
queues while inactive and restores active status before a steal attempt. Their
active-population reasoning does not justify replacing polling with an unproved
sleep/notification abstraction. Neither supplies candidate027's Q/M lock order,
initialization rollback, failed-join ownership or C memory-order refinement.

Next: establish action feasibility without weakening transitions; expose the
finite wake bound; prove or reject the retry/wakeup simulation; then choose a
minimal source repair with source-shaped positive/negative schedule controls.
Expected benefit is a defensible progress contract. Costs include lock traffic,
proof state and instrumentation; no performance improvement is established.

Keep synchronization lifetime and partial-initialization rollback repairs in
the same identity-bound candidate. Native acceptance still requires GNU GCC
with `--enable-smp`, `--enable-multiple-vms` and
`--enable-multiple-threaded-vms` together: GC regressions, multi-VM lifecycle,
full bootstrap, Gerbil build and complete real tests. Preserve original budgets,
teardown and parent-observed exits. A source identity change alone does not
authorize replay of a known failed route. All native gates remain open.

## Minimum Combined Repair Design

This is a two-site design for review, not an admitted patch. Existing
`gc_wait_notification` counterexamples reject signal-only and recheck-only
repairs; `gc_notification_lock_order` rejects taking M while retaining Q.
Reuse their archived controls rather than rerunning unchanged checks.

1. Keep payload/link/tail publication and its existing barriers under Q in
   `end_heap_chunk`. Release Q first, then acquire M, signal the condition and
   release M. Do not move M acquisition inside the queue critical section or
   hold M while copying, allocating or scanning.
2. At the existing `mark_reachable_from_marked` M acquisition, before decrement
   and wait registration, inspect the actual per-processor FIFOs one Q at a
   time. Read head/tail with the queue's acquisition/visibility contract. If a
   queue has work, release Q and M and return to the existing scan/steal path
   while still counted active. Do not decrement and later repair the count
   merely to retry. If no work was observed, retain M through the existing
   decrement and atomic condition-wait registration/release.
3. Retain the existing zero-count exit and nonzero wake restoration. Release
   every acquired lock on each branch. Do not substitute an unconditional
   wake, a fixed worker identity, a larger spin budget or successful-return
   shortcut. Every real publisher must follow the notification contract.

Sequential rechecks are not an atomic snapshot of all queues. A publisher can
add work after an earlier queue was inspected; the proposed protection must
force its subsequent notification to occur after the waiter's registration,
or permit an already registered waiter to receive it. Active producer accounting
is still required to justify the separate zero-count branch. Show this with
multiple publishers and waiters and recursive discoveries, not a one-chunk proof.

The reviewed queue lock sites are candidate `mem.c:3428,4496,4520,6926`; M is
taken at `6955`. Queue locks must be released before scanning can reach a
publisher that takes M. Existing GC condition initialization/destruction at
`4901,5126` are separate ownership/error obligations. Audit their callers,
participant population and strong/weak phase boundaries before admitting C.

## Native Validation Contract

Before any launch, record why the changed two-site protocol addresses the
selected failed schedule, and bind source/patch/configuration, GNU compiler,
build driver, fixture and the newly built binary. Reuse the failed-route
preflight. A fresh output name, document edit, or unrelated source change is
not a causal reason to repeat a rejected native route.

| Gate | Required observation on the same repaired candidate |
| --- | --- |
| Atomic notification schedules | Force publication before M acquisition, between each queue recheck and wait registration, after registration, and during wake/reacquisition. Vary publisher/waiter identities and queues; preserve the source, signal-only, recheck-only and inverted-lock controls. Record actual predicate, count, owners, registration and parent-observed exit. Mock scheduling alone is not a native pass. |
| Assignment and fairness evidence | Bind all 22 original action IR identities; distinguish guard coverage, expression definedness, consistent complete updates, domain closure and native scheduling assumptions. Retain a no-enabled-branch or assignment-error counterexample and every timeout as failed evidence. |
| GC regressions | Recursive graphs, eager head/tail ownership, local unexported work, repeated publication, repeated wakeups, strong/weak phases and population variation. Preserve historical relocated-slot reports independently; notification success is not their root-cause proof. |
| Multi-VM lifecycle | Repeated create/resize/shrink/reuse/shutdown, synchronization ownership, both initialization failure sites and cleanup rollback. Failed joins must not transfer retirement ownership. No resource destruction while admitted senders/waiters remain. |
| Full bootstrap and Gerbil | GNU GCC with all three requested switches enabled together; complete bootstrap, Gerbil build and the complete real test inventory, including teardown. Carry source and artifact identities through every stage. |

Every gate keeps its original watchdog, observed child/parent exits, log hashes,
actual test inventory and outcome. Do not omit timeout, teardown, partial tests
or concurrent drift. Only after all correctness gates pass may matched
performance measurements be accepted. No native gate is completed by this design.
