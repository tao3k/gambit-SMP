# Scan slot memory order: publication, close and interrupted banks

2026-10-24. Evidence-only refinement of [scan-slot-implementation](scan-slot-implementation.md), with the same bounded fields, no in-run reuse, no live payload reader and no new runtime/error/GC protocol. All C below is proposed diagnostic pseudocode, **not implemented or compiled here**. New lock20e7af89 / patchfbf60628, main7c490c3, reconstructed mem.c477f301e; setup.c05196683 and header9044f4a6 are unchanged locked inputs. No runtime/header/generator/qualifier/Recipe/history edits, native execution, peer action, commit or push. Recorded8/12 remains unqualified.

## 1. Separate publication edges and one close linearization

Do not replace the following edges with one 'full barrier somewhere'. The compiler/CPU proof has five separate objects: local handle, slot.state, native_bound, active and bank.footer. Plain metadata is written only by its authorized initializer/owner and is immutable after its corresponding publication. Plain record payload is written by one admitted activation and read only after all native writers stop.

| New-lock implementation surface | Producer operation and memory order | Consumer / proof obligation |
| --- | --- | --- |
| `___setup_mem_vmstate:5261`, `___setup_mem_pstate:5126`; new diagnostic atomics in header pstate mem11430ff | Harness initializes every state/guard/coverage/native_bound/footer before launch. setupP initializes its nullable local view on the existing exclusive setup path. Claim FREE->CLAIMING by a bounded CAS; initialize immutable slot IDs. **CAS** CLAIMING->READY with release success, relaxed failure. | GC accepts state with an acquire operation. Failed final CAS publishes no view. A blind release store READY could reopen a slot which cleanup already closed; forbid it. FREE is reachable again only in a new artifact after old final release. |
| Local pstate view publication and detach | Store immutable non-owning view pointer with release; collector loads it with acquire. Cleanup exchanges pointer to null with acq_rel. All accesses to that pointer use the atomic form, never a mixed plain load/store. | A collector that loaded the old view may retain that copied view safely because its mapping/slot is not reclaimed in-run. This does not make a freed pstate safe: existing native pstate lifetime is still a precondition. Pointer exchange is detach, not drain. |
| Real worker entry `setup.c:1140`, P0 native entry7894 | `native_bound` uses existing proposed registration field: UNBOUND0 -> BINDING1 CAS, then actual native identity payload, release store BOUND2. No retry/spin or competing identity rewrite. | Acquire BOUND2 before reading immutable native-owner payload. READY alone publishes setup IDs, **not** a native identity written later. BINDING or partial failure gives unavailable diagnostics. P0 creating a worker state at1488 is not worker registration. |
| `___garbage_collect_pstate:7776` -> collector/helper argument chain | Copy view; acquire-check cheap eligibility; CAS active0->1 with acquire success/relaxed failure. After winning, perform one **acquire RMW CAS READY->READY on state**. | Final successful state CAS is the diagnostic admission point, ordered with cleanup's state close in that atomic object's modification order. If it fails, release active0 (this activation owns it), pass null diagnostic context and run original GC. Do not enter scanner based solely on the earlier load. |
| `___cleanup_mem_pstate:5673`, VM5691; partial setup failure | Exchange slot.state to RETAINED with acq_rel. Never reset to FREE and never clear footers/records. The exchange closes all future successful READY->READY validation. Detach local view; preserve shared backing. | A writer validated before close may finish using its copied view. A contender that validates after close cannot publish. Closure does **not** prove previous writers or initialization stopped. No unmap, recycle or plain payload read follows solely from close or active0. |
| Normal collector end `mem.c:7918..7923` | After last diagnostic access, only the admitted owner release-stores active0. No reset on nested/failed admission. | Later acquire successful active0->1 observes the prior owner-local sequence/bank-selection writes. Fault/THROW may leave active1; do not add catch or forced clear. Actual process quiescence is the final-reader condition. |

The no-op state RMW is deliberate: it gives successful admission and close one same-object ordering point, without combining fields or adding a wait. A plain acquire load before the separate active CAS cannot express that atomic decision. A successful READY->READY RMW preceding the close is admitted, even if cleanup runs immediately afterward; no record storage is freed by that close. After the RETAINED modification, a successful comparison against READY is impossible without forbidden reopening. Cleanup need not read active to decide whether it may close. It must not infer drainage from active==0, which can also mean a contender has not claimed yet.

Use actual target-proven lock-free atomics. Source-level one attempt must not hide a lock helper or an unbounded retry loop in a lock-held path. A weak CAS may refuse spuriously and mark diagnostic coverage unavailable, but must not change original collector behavior; no spin until success. Inspect the actual target code. A failed CAS never uses release/acq_rel failure order. [GCC atomic builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html) specifies valid success/failure orders; the same-object RMW argument follows the [WG14 atomic modification-order rule](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2389.pdf). These are C/in-process ordering arguments, not an ISO C proof of cross-process crash-memory persistence.

### Minimal admission pseudocode

```
view = atomic_load_acquire(ps->mem.diag_view);
if (!valid_view_without_dereferencing_freed_ps(view)) use_null_context;
if (!native_bound_acquire_and_matches_current_registration(view)) use_null_context;
expected = 0;
if (!CAS_once_acquire(view->active, expected, 1)) {
    atomic_or_relaxed(view->coverage, REENTRY_OR_CONFLICT);
    use_null_context;                 // NEVER clears the outer owner's active
}
expected = READY;
if (!CAS_once_acquire(view->state, expected, READY)) {
    atomic_store_release(view->active, 0);
    use_null_context;                 // this activation owns this active bit
}
// Copy authorized view/identity to a C activation; pass it explicitly downward.
// On normal return only, after last access: atomic_store_release(active,0).
```

The pseudocode labels diagnostic refusal paths, not new return/throw behavior in GC. All original barriers, phase participation and overflow/result paths must still execute. Never return early from `___garbage_collect_pstate` just because diagnostics refused. A nested invocation must receive its own null argument on refusal; a pstate/TLS global pointing to the outer C activation would bypass this protection. Sticky coverage is atomically updated but does not publish associated plain payload; an acquire observation of coverage alone grants no payload read.

## 2. Exact original call/read chain and bank sequence

Change existing publish3901..3947 and wrappers3951/4170 to explicit view+local context. Carry that nullable diagnostic context along GC7776 -> strong7647/weak7710 -> root markers / mark_reachable_from_marked7473 / process_wills5787 -> scan_still_objs_to_scan4757 / scan4521 / pair macro4718 -> mark_array3969/debug3953 and captured/frame/continuation/RC4174/4337/4418/4489. Companion prior table covers all29 direct mark_array calls. These are C-helper arguments; no Scheme root or catch stack is added.

At the existing outer cell selection3994, construct a local attempt. Entry start/extent from3985..3986 and entry role stay distinct from current tail parent/span; tail4123 updates only local current context. Reserve two checked nonzero commit values before any bank modification. After sequence exhaustion, publish no more records and latch coverage; do not reset on GC, cleanup or setup. Fields from an old bank must not supply a new attempt's context.

For each publication, choose the bank which is **not** the last complete bank. Do not use the current plain struct copy3929. The following deliberately conservative sequence refines the existing two-bank proposal; target optimization is allowed only with an equivalent reviewed proof:

```
atomic_store_relaxed(bank.footer, 0);  // invalid record before reuse
atomic_thread_fence_seq_cst();        // invalidation BEFORE any payload overwrite
write_payload_from_this_local_context();
bank.commit_seq = reserved_commit;    // plain, owner-only
atomic_store_release(bank.footer, reserved_commit);
atomic_thread_fence_seq_cst();        // complete publication BEFORE original read
// CELL stage: obj = *cell;            // exact original mem.c4003
// HEADER stage: head = body[-1];      // exact original mem.c4021
```

The first fence must order footer invalidation before the earliest changed payload byte, including compiler movement. The final release footer orders preceding payload for a synchronized observer; the trailing full fence addresses following ordinary-read order. All are required proof obligations; the actual instruction envelope may differ from this schematic sequence. The new lock currently has only a single private global record/prev copy, so neither this first invalidation nor exclusive bank ownership is implemented there. The reported STR/DMB object does not establish these future edges.

CELL_PENDING captures no raw word. Only after the original obj load4003 succeeds may the HEADER_PENDING record contain that obj, computed body/header address and its same attempt token. The second stage takes the other bank, retaining the complete CELL stage while HEADER is incomplete. Once the second footer is published, it can be the latest complete bank. If the prior stage loaded an immediate and no header stage occurs, unused reserved sequence is simply skipped. Commit order does not imply the next original load completed: only faultPC/actual outcome distinguishes it.

Do not publish the 'latest' bank index as an additional reader synchronization mechanism. Owner-local selection state may stay plain under active ownership. At final quiescent reading, validate both bank footers and their own identity/context/commit values; no shared latest-index protocol or live seqlock is needed. A fault can interrupt updating the owner-local index, so that index is not postmortem authority. Zero footer, incomplete context, inconsistent commit sequence or sticky coverage means that observation is unavailable; an older complete bank cannot be promoted to the later fault merely because it survived.

## 3. Partial initialization and close are retention, not reclamation

| Interruption/failure point | What remains trustworthy | Required action / forbidden shortcut |
| --- | --- | --- |
| Before any slot claim or mapping validation fails | Preinitialized harness header/other slots only | Leave local view null; no object guessing, fallback global write or change to original setup result. |
| FREE->CLAIMING succeeded, metadata partly written | Claim ownership and zero footers; not complete identity | Failure closes to RETAINED with no published view. A cleaner seeing CLAIMING must not read unfinished plain identity/native payload. Keep object until initializer/writers stop. |
| Cleaner closes CLAIMING before initializer finishes | RETAINED is final for this run | Initializer CAS CLAIMING->READY fails. It must not use a blind READY store or publish its view; no handle and no record can be exposed. |
| READY published, local-view publication has not happened | Slot initialization is complete for acquire readers | Existing exclusive setup lifetime still applies. If failure/cleanup intervenes, state close prevents later admission even if a delayed non-owning view was copied. New setup requires a fresh slot. Do not race an unregistered setup initializer by freeing the pstate. |
| Slot READY, native binding BINDING but not BOUND | Setup identity only | No collector diagnostics. Never treat a partially written native token as the fault owner. No bind retry from another native thread in the old slot. |
| Writer admitted before state closes | Its copied view, sequence and local context remain owned until normal return or process stop | Retention and no in-run reuse make completion safe for diagnostic bytes. Closure does not cancel the writer; no resetting active, clearing payload or unmapping. |
| Fault leaves active1 / incomplete bank | A valid older/current committed bank may still exist; writer may now be dead | Only final harness quiescence can authorize examination. Do not call it a live owner forever; do not clear active to fabricate normal finish. Exact stage/PC and coverage still decide attribution. |

All atomics/footers start in the harness-created virgin artifact. A new claimant initializes plain metadata under CLAIMING; it must not zero atomics belonging to an already published or closed slot. RETAINED alone does not prove the slot ever reached READY or BOUND: a partial-init slot with zero footers is metadata-only/unavailable. No native owner dereference or payload interpretation is authorized just by RETAINED. Cleanup from setupP's early-return paths5126ff and existing ___setup_pstate5809ff must use the nullable local attachment, never assume success merely because a slot index was reserved. Existing cleanupVM5691 calls P0 cleanup5717; it is not evidence every native writer finished.

This design deliberately preserves the artifact through partial setup failure, not leaked runtime ownership indefinitely. Runtime may proceed/fail/exit according to existing semantics. The existing harness owns the diagnostic storage and releases it after the final boundary below, regardless of whether runtime cleanup callbacks ran.

## 4. Safe final reading with active1

The only payload reader is outside the owned writer group. `framework.execute:184..230` communicates/reaps and records parentReaped and processGroupQuiescent; these are necessary observations, not a promise no writer escaped into another group. Bind the declared writer set/backing object and refuse unknown outside writers. Normal exit, SIGSEGV, watchdog termination and partial setup failure all use the same actual all-writer-quiescent boundary. This research does not signal or inspect any peer.

After that boundary, active/state are evidence of interrupted control flow, not locks the reader must acquire or clear. The reader acquire-loads native_bound before native identity when present, then each nonzero bank footer before interpreting complete matching payload. It validates schema/run/backing identity/size, slot incarnation, actor, sequence/context, actual binary/PC and coverage. There is no concurrent payload overwrite at this point. Cross-process atomic layout/coherence and crash visibility still require the actual Darwin MAP_SHARED controls; C acquire/release vocabulary alone does not prove them. DMB/DSB cannot preserve a mapping held only by a dead process.

Keep the original raw artifact even if no bank is admissible; publish UNKNOWN with its reason. Copy/hash an immutable snapshot and finish every reader before the harness unmaps/closes/unlinks. Child cleanup has no right to clear/truncate that shared backing. The reader does not call a dead writer's destructor, release active, resurrect a slot, infer a fault from timeout-only evidence or follow raw Scheme pointers. Disk/power-loss durability remains outside this RAM-backed surviving-reader requirement.

## 5. Implementation order and minimal native acceptance

1. Update only diagnostic fields/initialization sites in header11430ff, setupP5126/setupVM5261 and real native startup1140/7894. Wire null-first atomic local views, checked claim/final READY CAS and separate native BOUND publication. Prove existing pstate initialization/cleanup exclusivity; these diagnostic atomics do not repair an illegal runtime setup race.
2. At GC7776 wire no-spin active claim plus final same-state RMW validation; explicitly thread its nullable context through the existing helper chain. Close/detach at cleanupP5673/VM5691 without free/reset. Normal release goes after last diagnostic access before actual return7923; nonlocal/fatal paths retain state. No catch or new early GC return.
3. Replace private globals3883..3899 and copy3929 with owner-local context, checked pair reservation and the two banks in the reader-owned mapping. Enforce invalidation-before-overwrite and payload/footer/fence-before-original-load. Review debug validation4014, which may fault before the header record; either cover that existing read or reject that PC as uncovered.
4. Bind exact configured/preprocessed C, compiler flags, atomic widths/alignment/lock-free lowering, generated object/archive and gsi SHA/UUID. Inspect each edge above, including no-op state CAS not weakened to an unsafe load/ignored result. No independently compiled control certifies the actual object. No compiler/production run occurred here.
5. In the existing registered native lane, on that **one** B and unchanged caps, collect the following controls before original TFIB. These are required native cases, not tests already executed:

| Control | Expected native observation |
| --- | --- |
| Initializer paused before final READY; cleaner closes; initializer resumes | Final publication CAS fails; no reopened slot/view or partial metadata interpreted. Retained object survives until final snapshot. |
| Writer paused before/after final state validation; cleaner closes | Validation after close refuses without payload; validation before close may finish safely using retained mapping. No busy-wait, reset or GC early return. |
| Two real workers plus same-slot/reentry refusal | Distinct complete payloads for admitted slots; rejected contender cannot change bank or release owner's guard. Sticky gap remains; no mixed actor or hidden retry lock. |
| Actual maximum sequence boundary | Complete reserved pair then refusal of next pair; no0/wrap/reset, no old slot reuse under repeated GC/setup. |
| Controlled fault after invalidation, midway payload, after footer/before load | Invalid/partial target bank never accepted; other bank intact; post-footer record is still 'pending', not completed read. Exact emitted ordering and faultPC recorded. |
| Original cell fault and successful-cell/header fault | Correct stage/raw-presence/address/owner/context on B; active1 may remain. Survivor reads after all writers stop without runtime cleanup dependency. |
| Partial mapping/slot/native binding setup failure | Null/closed attachment, no uninitialized atomic/plain metadata consumption, original setup status unchanged; consumed slot not reused. |
| Cleanup/new setup at same pstate address and a still-writing descendant | Fresh incarnation uses fresh slot; old record unchanged; reader/release waits for actual writer set to stop, not active0 or direct-child reap alone. |

Retain all negative/UNKNOWN outcomes, raw snapshots and quiescence receipts. If pausing/fault injection cannot be performed by the existing owned lane without introducing a new catch or violating lock/safepoint rules, leave that native case unverified rather than fabricate a command or PASS. Do not enlarge budgets. After these controls, original TFIB15/5000 supplies the scan witness for a causal repair; this diagnostic publication protocol itself is not the TFIB fix or9/12.

Execution handoff: [existing runner and eight control classes](scan-controls-harness.md) binds actual execute/recipe/capability entry points, identifies missing diagnostic hooks, avoids illegal live-VM init/cleanup races, and preserves raw controlled-fault exits outside zero-exit validators. It supplies required per-case evidence fields without adding a capability or recipe.
