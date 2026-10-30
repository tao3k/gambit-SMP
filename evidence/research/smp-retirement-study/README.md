# SMP processor shrink and lifecycle recovery research

The historical directory name `smp-retirement-study` refers to **retiring an
individual worker generation during processor shrink**, not retiring SMP as a
feature. SMP remains the implementation being repaired and validated.

Read `../../../docs/smp-processor-lifecycle-contract-review.md` for the current
review checklist (relative link: [contract review](../../../docs/smp-processor-lifecycle-contract-review.md)).
Historical filenames and paths are retained because receipts and source-bound
evidence cite them. Renaming them would not improve the lifecycle protocol.
Proposals, finite QNT results and native acceptance are separate. The proposed
Pending contract is inactive; the formal qualification remains8/12.

The [post-join transfer refinement](post-join-transfer-protocol.md) separates list ownership, GC scan-domain removal and physical native-resource destruction, including retained partial-failure recovery.

The [finalizer lifetime and shared-lock fault follow-up](finalizer-tail-handoff.md) specifies continuous resource pinning, before-destruction admission and the boundary between local retention and process-fatal shared uncertainty.


## Admission lifetime and ABA refinement

See [admission-lifetime-aba.md](admission-lifetime-aba.md) and its JSON index for the C ordering table, reference-unit last consumers, same-address generation reuse, destruction-entry audit and Grok focused native steps. The 12-control boundary model complements the earlier 28-control composition; neither is native admission.


## Asynchronous caller and destruction closure

[async-destruction-callers.md](async-destruction-callers.md) and its JSON retain the per-file caller inventory, generated READY spill/reload correspondence, post-marker tail accesses, rooted callback preparation requirement and focused native sequence. The concurrent 12-control model is safety evidence, not a merged C/native proof or 9/12 admission.


## Callback preparation and forward recovery

[callback-preparation-protocol.md](callback-preparation-protocol.md) and JSON bind actual device/fault entry machinery, nested typed roots, consumed-callback outcomes, generated maps and partial native teardown. Four candidate/ten negative safety controls plus two decoded completion witnesses remain conditional model evidence. Arbitrary callback side effects are not automatically retryable.


## Sweep classes, deferred wills and checked C entry

[sweep-finalizer-context.md](sweep-finalizer-context.md) and JSON bind the existing weak/will/foreign contract, typed callback choices, released-wrapper resurrection, checked host bridge/refusal, first-eight impact and native sequence. The final20 safety controls and7 outcome witnesses do not confer C/native admission; rejected/narrower models are retained.


## Shared foreign claim and native pointer loan composition

[release-loan-protocol.md](release-loan-protocol.md) and JSON bind source/generator snapshots, explicit/will/FFI/VM-close ownership, conversion-prefix/unwind/result tails, exported alias/address boundary, six candidate safety controls, twelve decoded negatives and four existential targets. This is conditional research, not a native repair or 9/12 admission.


## Recursive FFI journal and scope clarification

[recursive-ffi-journal.md](recursive-ffi-journal.md) and JSON distinguish the landed claim patch from pending journal/ABI work, historical audit scope from implementation authority, and per-file evidence from current-producer patch coordinates. New depth-five stack composition covers crossed-frame cleanup, prefix/result failures, trampoline preservation, metadata/tail pins and SFUN result-loan transfer. Eight candidate checks,17 decoded negatives,8 existential targets are conditional model evidence, not native closure.


## Lock-main native-owner/source alignment

[lock-main-native-owner-ffi.md](lock-main-native-owner-ffi.md) and JSON bind33 baseline/overlay files, all26 locked candidate hashes, actual source/archived-generation mismatch, main frame-count/___run/RC behavior, fixed native owners and sender-owned root ACK disposal. The final32 model controls (7 safety,16 decoded negatives,7 scenario targets plus2 continuations from recorded distinct errors) do not certify regenerated C or native behavior. New inventory candidate/transport DENY records are preserved independently.

- [Lock-main run finalization, B-owner ACK disposal and generated roots](run-ack-source-protocol.md): 22 expected Quint controls, native sync-tail coverage and concrete root-map acceptance steps; no runtime admission.

- [ACK collective service phases and blocked-owner isolation](ack-collective-service.md): post-operation reader/DONE phases, cyclic-GC progress controls, bounded per-owner debt, and checked park-before-blocking dependencies.

- [Checked park: Scheme entry, materialization, frozen scans and native rejoin](checked-park-source-protocol.md): split blocking ABI, retained ___call marker, non-P0 scope, failure boundaries and 33 expected model controls.

- [Staged FFI generator and stack-preserving callback repark](staged-ffi-generator-protocol.md): exact lock-main generator/macro/C correspondence, resident catcher, native tail and cleanup ownership; 32 expected model controls, no native admission.

- [Synchronous callback repark: common collective and actual root cells](synchronous-repark-protocol.md): fixed reader-free commit window, old-cohort departure ACK, active failure service and GC-debt handoff;23 expected QNT controls.

- [Old-cohort ACK, successor activation and final RC-carrier release](cohort-ack-rc-protocol.md): result/tail/root lifetimes, independent channels, reached restore landing ACK;22 expected safety/witness controls.

- [Epoch mailboxes, checked pins, ABA and busy-carrier skipping](epoch-mailbox-reclaim-protocol.md):21 combined proposal controls plus6 separately source-matched drain controls; current patch/source identity and open native gates.

- [Drain-before-GO: admission, multi-attempt ACK reset and channel reuse](drain-epoch-rotation-protocol.md): current-lock function plan, nonblocking admission constraint, ABORT/reopen and19 expected controls.

- [Drain atomic admission and scheduler-lock-held capability service](drain-cap-admission-protocol.md): concrete C/Scheme call-chain, post-pin key/phase validation, persistent service predicate and26 expected controls.

- [Drain sync implementation closure contract](drain-sync-closure-contract.md): complete direct entry inventory, local CAS assembly controls, generated-C/root and deferred-error obligations, combined12-control model and ordered native acceptance.

- [TFIB/interrupt causal alignment](repair9-failure-causal-alignment.md): separates actual failure generations and source cuts from drain assumptions;22 discriminating controls and one-producer native order.

- [Current-lock minimum diagnostics](current-lock-minimal-diagnostics.md):29 current scan-entry roles, six rebased request surfaces, actual probe coverage, non-SMP source-package C gap, and one-producer diagnostic acceptance.

- [Diagnostic commit/load ordering and request value/root coverage](diagnostic-order-id-generated-c.md): four standalone compiler outputs,20 assembly shape controls, three checker rejection controls and exact generated-C/native acceptance boundaries. No Gambit execution.

- [Failure-chain repair decision and carrier/escape boundary](fault-carrier-root-remedy.md): one-owner thread inbox plus reliable service handoff as the delivery recommendation; explicit causal limit for retained R/TFIB, supervisor-owned carrier lifetime and bounded escape attribution. No new catch or runtime edit.

- [New scan-lock writer review](current-lock-scan-diag-writer-review.md): verifies fbf60628 patch identity, flags process-global multiwriter diagnostic races, and fixes the order of writer isolation/shared-carrier/object/native controls.

- [Exclusive scan slots and shared-carrier implementation order](scan-slot-implementation.md): exact reconstructed477f301e locations, native-owner binding, no-spin reentry, checked two-value sequences, no in-run reuse, bank invalidation and eight native acceptance cases (not run).

- [READY/active/bank memory-order handoff](scan-slot-memory-order.md): final same-state RMW vs close, cancellable initialization publication, two-bank invalidation/commit edges, partial setup retention and active1 post-fault reader rules; eight native controls specified, not executed.

- [Eight scan controls on the existing native runner](scan-controls-harness.md): exact runner/capability limits, actual-helper versus live-VM scope, hook positions, raw signal/image/carrier receipt requirements, and eight classes with explicit sub-schedules; none executed.

- [Carrier-lock two-worker/source review](carrier-two-worker-review.md): reconstructs26 new locked files, credits shared-carrier survival, distinguishes inserted null probes from original4191/4213 reads, identifies lazy bind spin and incomplete mode publication, and leaves20-second stall location unproved pending raw run.

- [Carrier initialization, cleanup and repeated setup](carrier-init-cleanup-handoff.md): locked C ordering, bounded diagnostic lifetime, request credential index and unchanged20-second acceptance; evidence only.

- [Diagnostic session isolation and attributable cuts](scan-session-cut-handoff.md): proposed one-use setup/slot eligibility, committed publication receipts, partial-record invalidation and Grok negative controls; source-bound handoff only.

- [Full locked setup/slot/cut call paths and QNT controls](scan-session-call-paths.md): explicit return hooks, same-epoch constructor retry and source-bound41-control verification; no native admission.

- [Actual scan-session-cut implementation correspondence](scan-session-cut-implementation.md): retry-entry zeroing/token logic confirmed; immediate failure revocation/global error closes still missing; cancellation and QNT boundaries corrected.

- [Split failure window and refused global error cleanup](scan-failure-window.md): precise revoke/close ordering,28 new conditional QNT controls, and same-producer native hooks; prior41 controls unchanged.

- [Lifecycle contract versus runtime stability](split-contract-stability-handoff.md): no reachable same-owner errno transcript on the legal Darwin shrink; reaper target is not 9/12; interrupt and TFIB cells without a same-binary cause stay 尚无方案.

- [Evidence-backed delivery integration contract](stability-integration-contract.md): current lock versus reconstructed native-tested implementation, function-level integration and same-producer falsification; separate TFIB repair decision.

- [Delivery function integration](delivery-function-alignment.md): reuse/merge/rewrite matrix, delayed-id and post-thunk release gaps, explicit unlocked service, shrink boundary,12 same-producer native controls (not executed).

- [Shrink admission and linked release](delivery-shrink-owner-protocol.md): collective zero-count refusal before `___vm_resize_pstate`; partial unlink is retained. Landed source is `delivery-shrink-release-cumulative.patch`. Generated C and the twelve controls are not run. Not 9/12.

- [Release leaf and common refusal return](delivery-commit-entry-return.md): no-GC commit leaf, procedural double-unlock repair, stale ACK retains the fault. Source patch `delivery-commit-entry-cumulative.patch`. Generated C and native controls are absent. Not 9/12.

- [Shrink, hint roots and actual release ownership](delivery-shrink-owner-protocol.md): common early zero-debt refusal, optional tagged receiver-root handoff, partial-unlink correction, and30 conditional QNT controls; native steps specified, not run.

- [Release commit, entrance ledger and common return](delivery-commit-entry-return.md): prepared native leaf requirements, nine entrance groups, confirmed procedural callback double-unlock source edge, common refusal/throw cleanup,40 conditional QNT controls; no native admission.

- [Native leaf expansion and procedural callback suffix](native-leaf-procedural-suffix.md): branch-sensitive macro/store/save graph, actual callback error return/retrip, self-free and cleanup ownership,10 conditional controls and same-producer certificate checklist.

- [Activation roots, escape and cleanup commit](activation-root-escape-cleanup.md): current procedural-suffix lock, per-owner scanned RC carrier and nested catcher lifetime, ignored cleanup errors/empty-unlock success gap, outer registry/post-shrink constraints,16 conditional QNT controls and native acceptance.

- [Current interrupt-delivery integration order](delivery-integration-handoff.md): primary Grok handoff for one producer, current concrete pin/deque/waiter/lock issues, original two-file pressure binding and unfinished-request evidence. Supersedes older integration ordering; no new model/native pass.

- [Selected owner/waiter/pin restructure](owned-release-restructure.md): concrete all-locks-prepared algorithm, fields/store order, request-specific signal factoring, role-by-role failure releases, pinned research and15 focused QNT controls; no native admission.

- [Prepared signal native try-commit](prepared-signal-native-commit.md): complete lock discovery, corrected pinned/migration destination, exact BTQ/TOQ/runnable port, retry/root/pin ownership and concrete codegen/atomic/wait gaps; no native certificate.

2026-10-24 refinement: [Failed notification service ownership and generated-C boundary](delivery-service-roots.md) corrects the bare-idle/device distinction and specifies independent scheduler return, durable responsibility, map/reload certificates and15 conditional QNT controls. It does not admit a native producer.

2026-10-24: [Device P reacquire and SYNC](device-relock-sync.md) specifies materialized readiness, unlocked collective participation, pure try-publish, registration/borrow lifetime and14 QNT controls. Current-lock source evidence only; no runtime admission.

2026-10-24: [Active/Queued dispatch and precise unlink](active-request-drain.md), patch621449cf;16 QNT expected controls and same-B minimal yield/nested/migration fixture, unexecuted. No runtime or native admission claim.

2026-10-24: [Active/Queued dispatch and precise unlink](active-request-drain.md), original621449cf/currenta3039312;19 QNT expected controls and same-B minimal yield/nested/migration fixture, unexecuted. No runtime or native admission claim.
