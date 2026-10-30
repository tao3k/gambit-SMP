# Scheduler wait and GC participation contract

## Scope and implementation boundary

This is the small-refactor contract for the current repair, not a GC rewrite.
Retain the C backend, continuations, FFI and uncontended lock fast paths. Use
one repaired version/configuration and regenerate affected modules together.
Do not introduce a second synchronization protocol or a legacy SMP fallback.

The existing `scheduler_retry_gc_participation` and
`scheduler_lock_moving_root` transitions are reused from their resolved
`scheduler_gc_root_cohort_composition` projection. The composition in
`models/gambit/scheduler_wait_gc_contract.qnt` connects them at one collective,
rather than declaring independent GC operations successful. The existing
`exit_drain_mutex_lock_order.qnt` remains the separate two-lock/slow-path proof.
The composition does NOT establish the entire owned-deque drain or lifetime.

## Source obligations

| Boundary | Existing source | Required correspondence |
| --- | --- | --- |
| Contended acquire | `lib/_thread#.scm`, `macro-lock-thread!` and `macro-lock-processor!`; `lib/_thread.scm`, `##lock-scheduler-object-with-sync-participation!` | Identify the lock and the caller's complete held-lock set. Service eligible synchronization without dispatching arbitrary callbacks under scheduler locks. |
| Collective entry | `lib/_kernel.scm`, `##sync-op-interrupt!`; `lib/setup.c`, `service_sync_op` and `barrier_sync_op` | Bind request publication, operation/phase, processor population and acknowledgement to the same collective generation. |
| Root movement and return | `___FRAME_STORE_RA`, `___W_ALL`, `___R_ALL`; generated caller root frames | Demonstrate physical frame/root coverage, preserved lock metadata and reload of moved arguments, not only a declared root slot. |
| Reacquire and revalidate | `##mutex-lock-threads-revalidate!` and `##thread-join!` | Read the current owner/end state after acquisition; do not reuse a pre-collective state classification. A zero-timeout join still acquires the thread lock first. |
| Exit and cleanup | `##btq-abandon!`, thread termination and end-condvar publication | Publish the relevant final state before unlock. Separately close remaining owned-deque drain, last-access and lifetime obligations before reclamation. |
| Failed participation | Actual error/unwind and continuation exits from the affected call sites | Retain still-owned resources/frames or perform a demonstrated unwind. Never convert an incomplete collective into successful return. |

The common acquire helper is already present in the current candidate. Its
presence alone is not a new repair. A proposed change must identify which
source obligation is absent on the path actually reached by the original TFIB.

## Distinguishing evidence

`wait-contract.ss` correlates producer, observation boundary, lock, waiter,
holder and GC generation. The host records observations; Scheme derives missing
bindings and pending participation. No Python workflow or causal classifier is
required. An observation-boundary witness is an input obligation, not something
the DSL fabricates from matching labels.

Require witnessed held-lock inventories for both waiter and holder. A witnessed
zero-lock inventory is valid; missing inventories, inconsistent counts, a missing
held target lock, conflicting holders or mixed observation identities remain
explicit gaps. Do not infer that all GC participation requires dropping every
lock: the existing thread/processor composition deliberately retains a thread
lock across participation. Its safety depends on collector/root correspondence.

Ticket-lock `next/current` fields in `include/gambit.h` are counters, not holder
identities. A Scheme mutex's logical owner is also not the low-level ticket-lock
holder. A stack sample can identify a reached wait routine without establishing
either identity. Where the retained producer exposes no sound holder witness,
record that observation limit explicitly; a ticket value is not a substitute.
Any necessary targeted observer must account for perturbation, rooting,
publication and teardown before its result is used to justify a repair.

An unobserved acknowledgement is pending evidence, not proof of deadlock.
Distinguish collective request/acknowledgement, mark work, termination waiting,
post-GC notification and ordinary scheduler waiting. CPU activity and output
silence are neither root-completion witnesses nor proofs of lock ownership.

## Qualification and handoff

The registered `wait-contract.recipe.json` checks the returning/error contracts,
nine deterministic positive/negative wait trajectories, exhaustive safety and
temporal completion, plus decoded stale-acknowledgement/revalidation controls.
`tests.test_scheduler_wait_evidence` runs the actual Scheme evaluator against
missing observations, cross-producer/owner mixing, stale epochs, callback phases
and absent coherence witnesses. These are reproducible checks, not native passes.

Atomic publication, complete tracing, lock-metadata preservation and fairness
remain model assumptions until bound to the current source and native execution.
The finite model does not prove OS fairness, bounded execution time, arbitrary
processor populations, native exception unwinding or complete GC correctness.

Reuse the retained producer and committed source-core checkpoint. Once a causal
source fix exists, rebuild only its required dependency closure through the
registered in-place build adapter; unchanged bootstrap stages remain reusable.
Run the original TFIB without changing `(go 15 5000)`, then the remaining
interpreted/compiled stress and PR obligations. Preserve the original 3600-second
completed-work inactivity semantics, host-derived processor topology, failures
and distinct producer identities. Do not turn a modified probe into acceptance.

Raw runs, process records and local producer descriptors stay in cache. This
document and the executable contracts contain no claim of native admission.

## TFIB to processor-retirement correspondence

`tfib_retirement_correspondence.qnt` composes the existing
`retirement_pre_exit` machine with an explicit applicability projection. It
does not duplicate its retirement transitions or turn Scheme `thread-join!`
into OS-thread join. Source facts and proposed staged repair remain separate:

The current source is replayable from this directory's
`condvar-participation.lock.json`, rather than from a cache directory name.
Its `lib/setup.c` has the following correspondence (function/branch anchors
remain usable after line-number changes):

| Model boundary | Current source anchor | Limitation |
| --- | --- | --- |
| `activate` | `___vm_resize_pstate`, shrinking `target_processor_count < initial` | Must actually be reached in the original failing interval; Scheme join does not supply it. |
| `R.withdraw` | P0 `OP_SET_PROCESSOR_COUNT` collective; retiring nonzero member leaves `BARRIER()` | Publication order is a source fact, not evidence that TFIB executed a shrink. |
| `R.startCallback` / `R.requestGC` | `cleanup_interrupts_pstate` -> `release_procedural_interrupt` -> `execute_fn(..., ___FAL)` | The first call chain exists; a supported callback that actually requests GC here remains a premise, not a traced event. |
| `R.joinAttempt` / `R.joinSuccess` | P0 shrinking loop, `___thread_join(&ps->os_thread)` result | Do not infer OS error class or joinability from a Scheme exception. |
| `R.handoffAfterJoin` / `R.release` | Only the successful-join branch calls `___transfer_mem_pstate` then `___cleanup_mem_pstate` | Model `roots=1` abstracts real scanner-visible ownership; it is not a complete per-field root refinement. |

The separate retirement research patch has pending/quiet handling not present
at all these current-producer anchors. Those fields are not silently imported
as current guarantees. The bridge reuses only the explicitly modeled source
order and conditional root/participation obligations.

| Case | Required premises | Model result / implementation consequence |
| --- | --- | --- |
| No observed retirement | The retained signal 10, join exit 70, or inactivity alone | Activation remains unknown; these symptoms do not select a retirement fix. |
| Excluded in one interval | Complete source-bound entry census for that producer, execution and interval, with zero entries | Excludes this protocol only in that interval, not all GC or all later cleanup. A sampled processor count is not this census. |
| Entry observed, callback not bound | Same producer/execution/interval and coherent entry witness | Retirement applies, but callback-GC wait-cycle attribution remains unsupported. |
| Current withdraw-before-callback | An actual resize; late release callback requests GC after withdrawal, possibly while P0 joins | Existing pre-exit machine admits a conditional wait-cycle counterexample. Native legality and occurrence of that callback must still be demonstrated. |
| Current failed join before exit | Actual failed OS join, live donor-only roots, survivor GC after withdrawal | Retaining bytes does not establish scanner coverage. This does not assert a recoverable Darwin errno or equate Scheme join failure with OS join failure. |
| Normal successful current shrink | No GC-demanding exit callback; OS join succeeds and transfer precedes survivor GC | Existing result-collective protection is preserved; no universal missing-barrier claim. |
| Proposed staged repair | Callback completes while donor participates; real typed root/work handoff before withdrawal; failed join retains ownership | The reused finite protocol passes safety controls. Concrete callback reentry, complete root inventory, C publication and exceptional unwind remain source obligations. |

The bridge checks foreign producer, foreign execution, stale interval,
missing coherence, incomplete census and contradictory entry/zero-census
observations. Its twelve deterministic trajectories and seven exhaustive
checks are part of the same Recipe. Negative checks must actually find the
callback cycle, unscanned retained roots and unsupported-attribution mutation.
No new temporal completion claim is made for this bridge; the existing wait
composition's temporal check is unchanged.

`wait-contract.ss` exposes these same conditions as
`retirement_applicability` and `conditional_retirement_hazard`. The latter means
that the conditional protocol hazard is witnessed in the selected interval,
not that it caused a signal or exception. Python only submits observations.
Conflicting witnesses remain visible and cannot authorize that conclusion.

For native handoff, first determine whether the original stress interval has
an actual `___current_vm_resize` / `___vm_resize_pstate` withdrawal at all.
`tfib_stress.scm` itself creates Scheme threads and joins their end-condvars;
that is not such an entry witness. Bind any resize outside its body, startup
or cleanup to the failing interval rather than inferring one. If entry is
unestablished, keep the retirement repair conditional and continue the
scheduler/root investigation; the model does not mandate either direction.
If the conditional callback or failed-join case is actually reached, the
staged preparation/handoff protocol above is a candidate small refactor,
not an instruction to add another barrier or prohibit all GC.
