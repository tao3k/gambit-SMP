# Interrupt delivery: one current-lock integration and one falsifiable native result

2026-10-24. Implementation order for Grok, against `procedural-suffix.lock.json`, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, patch SHA `6aca28e02e43991b90c17784c758f953541cc7feec06f799bb0681eae2c905cf`. This chat only publishes evidence. No runtime edit, native run, peer operation, new commit or push. This handoff supersedes older *ordering* documents for the interrupt-delivery integration; it does not erase their failures or certify the new producer. No new QNT is added.

## Scope and decision

Deliver one integrated implementation of result-mutex interruption on this lock. The accepted request remains owned until exactly one execution/reply or real terminal abandonment. Processor procedure hints are scheduling hints, never owners of the result-node link. Preserve synchronous/async API, nested callbacks and processor procedures. Fix the actual current source below; do not restart from old source or reimplement mechanisms already present.

Do not make arbitrary FFI/journal/reaper architecture a prerequisite for the first original interruption experiment. Keep existing unsupported/native-terminal boundaries explicit; do not count those as production coverage. No concurrent shrink/reuse while delivery responsibility remains: the existing precommit common refusal is the bounded implementation choice, not an invitation to invent a new scan-domain handoff. TFIB cause, lifecycle contract revision, Gerbil and release remain independent. The outcome of this work is a source-bound native delivery result, not9/12 by declaration.

## Current source defects and remaining checks

The companion JSON binds all26 files, concrete excerpts and function coordinates. These are source findings, not attribution of an observed crash to this producer:

1. `##thread-intr-make-hint!` obtains a delivery pin before allocating its vector/closure. Unpublished hints on terminated/stale/self/non-running-target paths have no balancing release. Its callback releases only after `##thread-intr-wake!` returns; error/escape skips that release. Request construction also takes pins before allocation without an enclosing exact-once unwind owner. This can leak debt and permanently deny shrink, even when a flood happens to complete.
2. `##thread-intr-route-locked!` shadows the locked P after a participating acquire. Track the actual locked P separately; re-read/revalidate target routing after participation and release **that** lock before retry. Whether T protects a particular field is not a substitute for making the lock identity explicit.
3. `___thread_intr_release_commit` currently sets mutex.next/prev to itself, owner and request phase. It does not update old-owner deque neighbors. The caller's linked branch has not removed those neighbors first. This is not equivalent to `macro-btq-deq-remove!` and can leave owner-list links pointing at a self-linked mutex.
4. `##thread-intr-abandon-owned!` derives `waiter` from owner-deque next, rather than the mutex blocked-tree head; it then releases locks before calling `##mutex-signal-no-reschedule!`, whose explicit precondition requires mutex and waiter-thread locks held. It also tries the mutex while already holding T, contrary to the ordinary mutex→thread acquisition order unless all failure/retry paths release/reorder. These are integration blockers before pressure testing.
5. Current `##thread-intr-execute!` protects the body and generic unlock with dynamic-wind but its after action unconditionally unpins. Continuation reentry/escape and partial ownership changes require a once-consumed responsibility unit, not “after ran, therefore decrement”. Preserve actual owner/link-stage checks and do not abandon a mutex already transferred to sender.
6. The new procedural suffix snapshot/error return is useful and stays. It is not persistent activation/root admission. Empty cleanup unlock failure can still return NO_ERR; destroy result is ignored; `cleanup_pstate_locked`/`cleanup_failed_pstate` ignore cleanup failure before memory cleanup. For this integration, propagate checked refusal and retain resources at those existing boundaries. Do not expand into implementing arbitrary host callback recovery.

## Six implementation steps — merge as one producer

| Order / functions | Required change and acceptance artifact |
|---|---|
| 1. `##thread-intr!`, `##delivery-pin!` / `##delivery-unpin!`, hint constructor | Enumerate concrete units: publisher construction, target queued/active execution, synchronous sender consumption, hint publication/activation. Preallocate where possible; every acquired unit has a local unwind owner until it is explicitly transferred. Use guarded once-only release. Unpublished hint is released on every early return; published hint is released by its consumer on every supported exit. No silent counter underflow; a partial/unknown release retains debt and records a fault. Test branch-by-branch balance before proceeding. |
| 2. `##thread-intr-propagate!`, `##thread-lock-remove-btq-toq!`, route/wake helpers | Keep Fresh→Queued and the sole result-node T splice under T; preserve pre-removal predicate on every retry. Fresh request rejection must settle its result-mutex contract rather than enter lock2 waiting for nonexistent delivery. Track `locked-p` versus reloaded route; release/retry on mismatch. Running target receives a fresh procedure hint; non-running target gets exactly one runnable insertion. Consume/discard the unused hint explicitly. Never publish #f as a hint or use delayed raw processor id after unlock. |
| 3. drain/execute/abandon helpers; release commit; existing mutex unlock/signal | Keep current T pop and Queued→Active under T, then execute outside scheduler locks. Correct owner-deque removal, real blocked waiter selection, and mutex/waiter/owner/TOQ lock preconditions as one change. Reuse full existing signal/timeout/runnable semantics; do not call a lock-requiring helper after unlocking. Prepare all participating acquisitions/retries and revalidate owner, links and waiter. If native commit is retained, include both neighbor stores **before** self-link/owner publication; no post-mutation fallback. Audit the small actual commit and its bridge, not an invented example. A partial commit remains retained, never blind re-unlink or unconditional unpin. Preserve successful result versus real abandonment and target-side rethrow. |
| 4. `##wait!`, scheduler idle/device return, heartbeat, `##thread-intr-service-unlocked!`, wait adapter | Keep explicit service only after actual P/T/V unlock. Bare idle, device wait and heartbeat must all reach it; do not rely solely on masked OTHER or an abort byte. Keep the existing scheduler-only return/recheck design and original absolute deadlines; no timeout rebasing or fake device readiness. Nudge failure cannot delete the committed queue obligation. Bind the actual wait backend/abort helper used by this producer. No new waiting architecture is added in this task. |
| 5. delivery common guard and existing cleanup callers | Preserve shared pre-count-change refusal while any unit remains, original requester/winner and common status/return. Fix the bounded cleanup error-propagation gaps above so retained debt cannot be freed or ready-reset. Unsupported callback escape remains retained/terminal; it must not silently open admission. No pending-as-errno, join rewrite, observer or historical-receipt change. |
| 6. actual SMP regeneration, link and diagnostics | Generate `_thread.c`/`_kernel.c` once with the final compiler/config. Verify roots and spill/reload around route SYNC, result storage/unlock, abandonment, sender lock2 and wait return; inspect real leaf preprocessing/macros/object instructions. Freeze GSI/archive/objects/UUID and all loaded fixture/helper identities. Do not run an intermediate mixture or relink between controls and pressure. |

The leaf is a finite audit task: its used FIELD/BODY/index/neighbor stores and configured bridge can be preprocessed and inspected on the same build. “Field macros may hide a call” is a reason to collect that output, not an indefinite architectural blocker. There is presently no final producer certificate. A passed object compile is not the certificate.

## Same-producer run order, original fixtures and unchanged budgets

The machine-readable acceptance plan binds immutable upstream fixture bytes and the retained flood by SHA. All tests below use B, the one final producer. B is currently absent; `executionReady=false` until paths, hashes, generated code and processor preflight are filled with real evidence. No executable from a different generation may fill the missing binding.

1. Startup and a normal/abandoned result request, then the retained focused controls (30s cap each): duplicate pre-removal; request construction/hint early exits; migration plus real GC; stale hint; target termination; nested callback/exception/continuation; no-waiter and waiter release with result GC; park/service/deadline; delivery-busy common resize refusal. A hook not reached is uncovered. In particular owner deque neighbors and real blocked waiter must be checked, not just the final numeric return.
2. Two independent batches of8 rounds of the exact retained100000-request flood at p11, each round under the existing12s cap. Require `PROBE-DONE 100000`, correct returned vectors/count, exit0 and actual child/group quiescence. This is a short control, not the original stress result.
3. Run only the two original interruption stress files using the original GSI unit-test loader, unchanged input/expectations and original mode. `thread_interrupt_stress.scm` executes `go (* time-scale 60000)` with interpreted time-scale100 (6000000). `thread_interrupt2_stress.scm` keeps iterations1000000, ten competing senders, processor-derived independent tests and all six target states. Do not replace them with flood or reduced counts.

Derive original-loader argv exactly from `native_capabilities.run_suite_groups` and `runner_option`: `{B}/gsi/gsi -:{runner_option(option)} -f run-unit-tests.scm -gsi -stress unit-tests/06-thread/thread_interrupt_stress.scm unit-tests/06-thread/thread_interrupt2_stress.scm`, cwd the bound tests view. Preserve the original tests runner/support tree and runtime lib/bin/include aliases. `GAMBOPT=option` carries the topology selected by the existing preflight; runner_option uses p1 for the loader, **not** a reduced test population. Record actual child processor counts and child executable identities. Do not force p11 here if the declared original campaign selected another population.

These selected originals share at most the original3600s stress stage window; do not give each file a fresh3600s allowance. Keep the existing sealed recipe unchanged. This focused replay is not its whole-inventory receipt. If current durable accounting disallows retry, do not reset that budget; resolve genuine source-bound retry admission under existing rules first. Do not run TFIB/Gerbil/release/full inventory as a response to a failed interruption control.

## Six diagnostic groups: identify the actual unfinished R

Use the existing parent-owned retained-record method; no live unsynchronized reader, printf/allocator or blocking diagnostic hook under T/P. Producer B must contain the diagnostic cuts before it is frozen; pressure on a relinked instrumented binary cannot be attributed to B. Use writer-owned bounded records, commit validation and read only after the owned run is quiescent. Overflow/partial commit/missing records means UNKNOWN, never “no lost request”. No new general coordinator/carrier framework is part of this task.

Private request shape is currently `[next,mutex,target,phase]`. If adding the diagnostic serial, use a fifth immediate field4 and validate shape; do **not** reuse slot2 (target), slot3 (phase), or read field4 from ordinary procedure/hint nodes. ID is `(session nonce, VM incarnation, nonwrapping serial)`, allocated before acceptance and preserved across GC/migration. Addresses are observations, not identity or GC roots. Do not retain otherwise dead objects solely for logs.

| Cut group / current functions | Required scalar events and meaning |
|---|---|
| A sender: `##thread-intr!` | ID issued, accepted/refused, publisher/target/sender unit transfer; LOCK2_ENTER and LOCK2_RETURN are distinct events. Capture rejection/throw before lock2 too. |
| B queue commit: propagate/route/wake | T enqueue committed, hint published/discarded, observed route/locked P, route retry; preserve one result-node owner. No “propagate returned” substituted for enqueue commit. |
| C actual consumers: drain/service/resume | T pop→active transfer; P hint pop/forward/discard; execution identity and current target/processor. Snapshot/commit before destructive unlink without logging through a possibly freed node. |
| D execution/release: execute/abandon and real mutex helpers | BODY_ENTER, outcome stored, old-owner neighbor unlink, owner/phase commit, actual runnable wake, physical lock release, execution unit settlement. Record error/escape disposition without fabricating completion. |
| E scheduler return: idle/device/heartbeat | Wait-enter/return reason, original absolute deadline, abort status, P unlock, explicit service entry. Correlate route/hint IDs; a hint may schedule many checks and is not the result request itself. |
| F sender/last consumer and fault | Sender result/abandon consumption, last pin release, terminal retention; parent/child request IDs remain distinct. Unknown escape retains an incomplete record instead of synthesizing a reply. |

At timeout, begin with committed LOCK2_ENTER IDs without LOCK2_RETURN. For each R, join A→B→C→D→F and use E to explain absent service. Report a committed causal prefix, actual owner at its last trustworthy event, and earliest missing/contradictory edge. No B: publication/rejection issue. B without C: queue routing/park/service issue. C without BODY_ENTER: dispatcher/ownership issue. BODY/outcome without owner+wake commit: exception/release issue. Wake commit without LOCK2_RETURN: result mutex/scheduling issue. A producer may contain several faults; totals alone cannot identify which R stalled.

A complete prefix plus producer/config/fixture identity is the next useful failure artifact. An empty P head or equal propagate counters is insufficient to conclude a lost node. Do not sample/debug a peer; harvest only the test process owned by this run using existing harness custody and timeout/reaping.

## Stop rules and deliverable

Any short-control failure stops the original-pressure stage. Any original failure/timeout stops repeated same-version runs: retain stdout/stderr, committed records, exact R/prefix, actual exit/signal and quiescence, then repair that concrete edge. A repeated run is justified by a causal source change or a declared fixed repeat plan, not by hoping for another8/8.

Grok's deliverable is one final producer binding, the per-function semantic diff, focused controls and original two-file result, plus either actual completed requests or one trustworthy unfinished R. Diagnostics unavailable, ungenerated C or no final binary is BLOCKED, not PASS. Models are supporting contracts and are not the acceptance artifact. Successful interruption replay does not explain TFIB or revise the unreachable lifecycle errno gate; qualification remains8/12 until those independent contracts are reviewed and actually met.

## Current-lock function coordinates

These coordinates are from the26 hash-verified procedural-suffix candidate files, not vendor HEAD or historical generated C.

| Function | Source |
|---|---|
| `##delivery-pin!` | `lib/_thread.scm:1595` |
| `##delivery-unpin!` | `lib/_thread.scm:1599` |
| `##thread-intr!` | `lib/_thread.scm:1603` |
| `##thread-intr-make-hint!` | `lib/_thread.scm:1453` |
| `##thread-intr-route-locked!` | `lib/_thread.scm:1460` |
| `##thread-intr-nudge-locked!` | `lib/_thread.scm:1447` |
| `##thread-intr-wake!` | `lib/_thread.scm:1490` |
| `##thread-intr-propagate!` | `lib/_thread.scm:1637` |
| `##thread-intr-drain!` | `lib/_thread.scm:1565` |
| `##thread-intr-execute!` | `lib/_thread.scm:1543` |
| `##thread-intr-abandon-owned!` | `lib/_thread.scm:1511` |
| `##thread-intr-service-unlocked!` | `lib/_thread.scm:1583` |
| `##thread-lock-remove-btq-toq!` | `lib/_thread.scm:769` |
| `##mutex-unlock-no-waiter!` | `lib/_thread.scm:1008` |
| `##mutex-unlock-out-of-line!` | `lib/_thread.scm:4105` |
| `##mutex-signal-no-reschedule!` | `lib/_thread.scm:4221` |
| `##wait!` | `lib/_thread.scm:2774` |
| `##thread-heartbeat!` | `lib/_thread.scm:2906` |
| `##thread-resume-execution!` | `lib/_thread.scm:2971` |
| `##thread-migrate-to!` | `lib/_thread.scm:3401` |
| `___thread_intr_release_commit` | `lib/setup.c:295` |

This audit rechecked12 source conditions and original fixture bytes. It ran no new QNT or native workload. Native plan: [delivery-integration-native-plan.json](delivery-integration-native-plan.json). Required producer binding is deliberately empty until Grok creates the real integrated artifact.

### Selected algorithm for steps1 and3

[owned-release-restructure.md](owned-release-restructure.md) now fixes the choice: request-specific all-locks-prepared mutation, actual owner-neighbor writes, blocked-tree leftmost waiter, no lock-dropping generic signal during commit, and per-role guarded unit transfer. Its private unit layout adds targetUnit at5 while retaining diagnostic ID4. This replaces the earlier diagnostic-only five-field layout; all constructor/consumers must migrate together. Fifteen focused conditional controls distinguish the wrong choices; the same-producer native plan remains not executable until B is bound.

### Prepared signal and no-GC implementation boundary

Use [prepared-signal-native-commit.md](prepared-signal-native-commit.md): one native nonblocking try-commit acquires/revalidates/mutates/unlocks; Scheme runs SYNC/GC only after Retry with zero locks. Runnable destination is migration-target→pinned→current-P. Both normal and abandon paths must migrate, including delaying early phase publication until consistent commit. Existing bound abort ignores errors/infinite wait remains possible, so the earlier wait-return design is not presumed installed.

2026-10-24 refinement: [Failed notification service ownership and generated-C boundary](delivery-service-roots.md) corrects the bare-idle/device distinction and specifies independent scheduler return, durable responsibility, map/reload certificates and15 conditional QNT controls. It does not admit a native producer.

2026-10-24: [Device P reacquire and SYNC](device-relock-sync.md) specifies materialized readiness, unlocked collective participation, pure try-publish, registration/borrow lifetime and14 QNT controls. Current-lock source evidence only; no runtime admission.

2026-10-24 landed-source review: [Retained Active dispatch guard](delivery-service-landed-review.md). The new native helper is implemented, but the new drain must not re-claim Active/terminal requests; phase-aware eligible scanning and exact-object unlink are required before interpreting small controls as nested-delivery coverage. No new native result is claimed here.

2026-10-24: [Active/Queued dispatch and precise unlink](active-request-drain.md), patch621449cf;16 QNT expected controls and same-B minimal yield/nested/migration fixture, unexecuted. No runtime or native admission claim.

2026-10-24: [Active/Queued dispatch and precise unlink](active-request-drain.md), original621449cf/currenta3039312;19 QNT expected controls and same-B minimal yield/nested/migration fixture, unexecuted. No runtime or native admission claim.
