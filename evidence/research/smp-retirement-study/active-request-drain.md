# Active request dispatch, suffix claim and exact completion unlink

2026-10-24. Original observation was patch `621449cf1888592864293c2f79c1f4ce4cf1aa91f9ce7e8a69ee49fa7c101112`. During this evidence-only task the same path naturally advanced to `a303931266e5773a9b089d7dec9ad094c112ac9fb776945288e41b4adaa1e625`; that newer patch and landed record are frozen as read-only audit inputs. Both use lock main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. This task changes research/model/fixture evidence only; the patch and peer producer are untouched. Original reported B is gsi `bef5468fd3079337748dd93e88fab1676fa1d9061dbf00548135d3f61a133841`; the new landed record names gsi `f016292e644b3833a0379cb872d72bc50268333b998ec093ac2e0db919cc0245`. Neither binary/object is independently read/admitted here. New landed observations are not relabeled as tests run by this chat.

## 1. Preserve the useful implementation; fix eligibility before invoking

The original request layout is `[next,mutex,target,phase,mutex-states,R-unit]`; a303 appends the preallocated capability at slot6. Thus current layout is `[next,mutex,target,phase,mutex-states,R-unit,capability]`. Slot4 is **not a diagnostic request ID**; do not overwrite it with a sequence. Phase0 Fresh,1 Queued,2 Active,3 Succeeded,4 Abandoned,5 Retained/partial. Procedure hints have a different representation identified by procedural slot1.

The original621 drain keeps Active requests in the thread queue so termination can find them. That is useful. Its missing dispatch guard is patch2125..2128: every result head is unconditionally set to2 and executed. Resume2479 and unlocked service2153 can invoke drain during the thunk. Execute's before thunk2088 accepts2 and therefore does not prevent replay. After return, the existing identity scan2130..2147 is a useful implementation to preserve; do not regress to removing head or using pre-yield `prev`.

**Important additional boundary:** native phase3/4 publication and R settlement are separate. `##thread-intr-release-finish!` may return false with pending-D/unit still armed, and execute/drain currently do not require a settled result before unlink. A terminal phase alone is not permission to remove the last termination/GC anchor. This handoff distinguishes TerminalPendingFinish from TerminalSettled without resetting terminal outcome.

### Newer a303 input: implemented versus still required

The newer source already factors `##thread-intr-claim-queued!` and `##thread-intr-unlink-request!`. Claim scans beyond Active/terminal, changes only phase1 to2 and arms capability; middle procedure hints use exact unlink. Execute CASes capability1→2. These are source fixes to the original replay issue and should be reused, not reported as still absent. Its landed record reports yieldBehindActive(entries1,result41,behind1,exit0), terminateWhileYielding(abandoned,entries1,exit0), continuationReentry(refused,entries1,result7,exit0), plus200 interrupts exit0. They remain reported small controls, not complete codegen/native admission.

The newer drain still unlinks on phase3/4 alone; native notification/R finish can remain unresolved. Termination still advances after a false release disposition. The mutex-specific payload store still precedes native release/owner validation. These are the remaining windows this final model distinguishes. The new claim/unlink remain Scheme procedures called under T; their generated no-GC/call-graph certificate is not supplied, so the pure-native leaf option below remains an implementation route, not a claim that current code already meets it.

## 2. Selected algorithm and function changes

### `##thread-intr-drain!`: claim only eligible work

Under current-thread T lock, scan from the live head in queue order:

- Procedure hint: exactly detach that selected node under T, including middle/tail links; keep it rooted locally and retain its H cleanup unit before unlocking/invoking. Once scanning beyond Active, the old `macro-thread-interrupts-remove-from-head!` cannot remove a selected middle hint.
- Result phase1: verify immutable target is this current thread and R-unit is valid, make the single1→2 claim and return that rooted request to execute. Leave it linked for termination.
- Active2, terminal3/4: skip for dispatch. Do not reset phase, detach on behalf of another active invocation, wait on it under T or stop at the first Active.
- Retained5/unknown: preserve ownership and fault evidence; skip ordinary dispatch. A specific registered cleanup owner handles retry; queue emptiness is not the success criterion.
- End of scan with no eligible work: unlock and return to the saved resume continuation. Do not spin or block on the Active head. A later new enqueue uses the existing route/wake path.

Queue-only pseudocode (not code to run while holding a Scheme-generated lock scope):

```
for node in current_live_chain:
  if procedure_hint(node): detach_exact(node); return rooted_hint(node)
  if phase(node)==Queued: claim_once(node); return rooted_result(node)
return NoEligibleWork
```

Implement the lock/scan/claim as a small native try-only/no-GC leaf, proposed `___thread_intr_try_claim(ps)`; a busy T returns Retry so unlocked Scheme can participate in SYNC. Return the selected SCM node directly in RESULT or an immediate status; allocate no result tuple under T. No cached predecessor escapes this call. A legal selected node must be in a real generated root location before any post-return allocation/SYNC/exception. The scan is iterative, not a generated recursive closure while T is held. Existing pure macro accessors may be factored, but not a hidden callback/allocator/logging path.

### `##thread-intr-execute!`: one outer invocation, resumption is different

Pass the claimed request and its unique preallocated execution grant. Queue claim1→2 is one-shot; entry consumes Claimed→Running once. `thread-yield!` and `##thread-migrate-to!` resume the existing invocation, not a new execute call. Its continuation keeps request/outcome/grant rooted. `##thread-resume-execution!` still consumes migration before drain; nested drain may claim B after A, but never calls A's thunk again.

Reuse a303 slot6 for the already preallocated grant; keep existing slot0 pin flag, slot1 pending-D and request slot4 mutex-states intact. Allocate it during Fresh construction in `##thread-intr!`, before publication or primitive locks. A unique SCM grant object is preferable to a wrapping native counter. Its entry/exit state must be guarded by the same owner/phase contract; phase2 alone does not prove which invocation is entering.

**Do not overstate continuation semantics:** preventing a second runtime invocation of the thunk is distinct from preventing user code from replaying its own captured mid-body continuation. A dynamic-wind before check may not run when a continuation jumps within the same dynamic extent. This change preserves normal yield/migration and runtime exactly-once dispatch; arbitrary user continuation side effects are not made once-only. Cross-extent entry into an already entered/terminal internal execution grant must be explicitly rejected or given a separate supported contract. Rejecting it must retain/settle the actual owner, not unpin blindly. The QNT capability check abstracts that boundary; it is not proof that a Scheme before thunk catches every call/cc.

### `##thread-intr-release-finish!`: return a disposition the caller must use

Keep native Normal/Abandon/SenderFinal complete commit. Propagate explicit Finished / TerminalPendingFinish / Retained / OwnershipTransferred from finish, rather than letting execute treat every returned false as cleanup completed. The actual M owner, request phase and exact R-unit CAS decide idempotence. Terminal phase is never rolled back to Active. SenderFinal only settles S; it cannot authorize target R unlink.

On target exception, preserve the exception outcome and perform the same owner-aware finish before rethrow. A supported nonlocal escape executes cleanup once, with an unresolved disposition remaining owned. A late activation callback after termination must observe Abandoned/Retained or changed owner and do no normal result store, re-execution or second R decrement.

### Move payload storage behind the same owner/grant validation

The current `macro-mutex-specific-set!` in execute is before native finish and is not protected by its M/T/grant checks. Remove that unconditional store. Pass the already allocated/rooted `outcome` and execution grant through the release wrapper into native try-release. Validate actual M owner, expected execution grant and Active/terminal state under the complete lock set *before* publishing payload or changing queues. In a valid first Normal/exception commit, store outcome's value as part of that no-GC commit. SenderFinal and late cleanup never rewrite it.

Use an explicit NoPayload outcome for cleanup-only calls (for example #f, while actual outcomes are validated two-slot vectors), so a legitimate Scheme #f result is not confused with no outcome. Extend the current C declaration/wrapper/call sites consistently, keep request slot4 mutex-states intact, and regenerate/map the added outcome/grant operands across Retry. If termination/another terminal outcome won, return its real disposition without any payload write, phase reset or second pin decrement. If success committed first, later termination preserves that success and only completes pending R/notification. The model's CommittedThenTerminated positive and LatePayload mutant test these opposite orderings without relying on duplicate pin-count detection.

This is a result-publication boundary change, not a new exception convention. User-code exceptions remain target exceptions and sender abandonment follows existing declared semantics.

### Completion unlink: reuse live identity scan, add eligibility and owner checks

Proposed `___thread_intr_try_unlink_finished(ps,request)` tries T, re-reads live head and finds **this request by identity**, computes current predecessor/successor and updates head/tail under T. Entry/ordinary return own no scheduler locks; body is no-GC/no-callback. Re-read phase and R-unit armed/pending-D state. Detach only Finished/settled3 or4, or after a **completed rooted handoff** to an explicit retained owner.

Never use `prev/next` saved before executing user code. If B behind A finishes during A's yield, B unlink must update A.next from B to C. A later unlinks using that C, not the old B. Middle procedure-hint removal obeys the same rule. Tail is recomputed from the current predecessor; absent-node cleanup changes no head/tail/node.next. If termination already detached the node, do not clear slot0: that slot may now belong to the cleanup chain.

For a valid finite acyclic chain, the structural argument is local: claim changes no edges; exact unlink changes only current predecessor.next (or head), tail if and only if the selected node was last, and the removed node's next. Every other reachable node preserves its order. No-match changes nothing. This explains why the head/middle/tail controls are discriminating; the bounded model is not an induction proof for arbitrary queue lengths or corrupt cycles. A detected invalid chain is retained/terminal per policy, never an unbounded locked scan. Scan cost is O(skipped Active/terminal prefix); no extra allocation or OS wake per skipped node is needed.

A not-found request is not automatically Finished. Confirm which cleanup owner/root now holds it; Unknown/Retained prevents pin/anchor release. The status returns to an unlocked caller which can service SYNC, reload and retry; it is not a blocking T acquisition.

## 3. Termination: one cleanup owner and a durable retained suffix

Patch2327..2349 detaches the queue under T, drops T and traverses a private chain. That is the correct direction because native try-release takes T itself. But it clears the current node.next before release and proceeds regardless of false/Retained disposition. That can leave an unresolved R without the detached-list root, especially async requests or after active frames are destroyed. A positive pin counter does not keep a moving Scheme object reachable.

Grok must make each of these steps explicit:

1. Under T, close request admission/mark target terminating, transfer the complete current queue (including Active) to a rooted cleanup activation. Publish the new cleanup owner before clearing T's head/tail. No new grant is issued after that boundary. Preserve actual source terminated-marker ordering and check it, not only a Boolean in QNT.
2. Save/root `next` across each unlocked release; never hold T while calling native try-release or SYNC. Cleanup grants queued/Active requests an abandonment outcome through the existing actual-M-owner checks. Terminal committed requests retain their existing result; no overwriting3 with4 just because shutdown arrived later.
3. Process unrelated B/C even if A is Retained. Do not discard A and do not hold the whole detached chain in an unregistered C stack. Before returning or destroying the cleanup frame, hand A to a persistent scanned owner.
4. Concrete bounded fallback if this producer has no such registered owner: add one private **Scheme VM root field** for delivery-retained requests, with a preallocated separate retained-next field in R-unit. Link under a separate try-only VM-root transaction after dropping T/M/P; preserve the old mapped cleanup owner until publication succeeds. `mark_vm_scmobj` must scan it and VM cleanup/resize admission must see its live debt. A native `delivery_fault` bit/list pointer alone is not a root. Do not reuse request.next for both live queue and retained registry. Reuse an existing root only after binding its actual scan/last-consumer path in B.
5. Mark Finished only after R settles or retained handoff is acknowledged. If no persistent owner is installed, cleanup cannot report target/VM teardown complete; retain the mapped activation and service legal SYNC, or use the existing declared terminal failure policy. Never turn Retained into a synthetic abandonment success.
6. Late dynamic-wind cleanup rechecks grant/actual M owner/unit; unit CAS consumes R once. Missing from live queue means Detached/Retained ownership check, not permission to reset links or release again. The last retained-root unlink is after outcome/notification/native borrowers and R are settled, with no access after last release.

This is a small queue/execution cleanup change, not lifecycle errno reform or a new scheduling framework. Rooting a failed async cleanup is necessary for this exact path; deferring it as “later lifetime work” would make the Active fix incomplete.

## 4. Interleavings and why the change blocks them

| Interleaving | Old failure / tempting bad fix | Selected behavior |
|---|---|---|
| A Active; yield→resume→drain | Same A set2 and invoked again | Skip A, claim only phase1; resume original A frame once no eligible work remains |
| A Active, B Queued; A waits for B | Return on Active head starves B | Scan suffix, grant B once while A remains a termination anchor |
| B completes behind A, then A returns | Pop head loses A; stale A.next can resurrect B/drop C | Exact identity scan under T, recompute current neighbors and tail |
| A phase3 but notification/R finish incomplete | Phase-only unlink drops last anchor | Skip dispatch, retain anchor until R settlement or persistent retained handoff |
| Termination during A/B Active | Dequeued Active is unreachable; unconditional cleanup can overwrite result/double-release | Close admission, rooted detached owner, actual-owner/idempotent finish, once-only R CAS |
| Retained A, finished B/C | Stop entire cleanup or silently drop A | Keep A on scanned retained root, continue other dispositions; teardown remains incomplete |
| GC/migration between nested calls | Saved raw predecessor/address becomes stale | Root request/grant, discard old neighbors; selected leaf reloads every pointer after SYNC |

The native helper's no-GC proof and generated maps remain required. The queue model cannot certify RB-tree mutation, lock memory order, arbitrary continuation behavior or the unimplemented device-wait/P-reacquire protocol. These are not counted as closed here.

## 5. Same-B minimal native controls, not a large pressure rerun

`active-request-minimal.scm` is an **unexecuted evidence fixture** for `yield`, `nested` and `migrate`; it has an atomic flag handshake and increments the thunk-entry counters before yielding. It uses the actual runtime thread-interrupt path. Every case is a separate process of the same frozen B under the existing30s focused cap. Keep original p11 topology and heap; migration IDs0/1 must both be admitted. Do not relabel the old200-run or execute a different gsi for one case.

Existing-supervisor command template (do not run as an unregistered shell timeout):

```
argv = [B/gsi/gsi, '-:p11', '-f', ABS_EVIDENCE/active-request-minimal.scm]
env += {'SMP_ACTIVE_CASE': 'yield' | 'nested' | 'migrate'}
cap = 30 seconds
```

Use the registered validation process under the same repair-9-12 exclusive custody, binding actual argv/env/cwd plus source/patch, compiler/config, generated C/maps, native helper/object/archive/GSI SHA/UUID and fixture hash. The original bef5468f B is the replay reproduction control; a303/f016292e is the reported guarded control. Any further repaired B is another identity and must be named honestly. Do not overwrite a completed producer's identity or call before/after the same binary. For each frozen B, all selected controls use that B.

Expected on original621 patch: yield/migration can reveal multiple A-ENTER or an abandoned/error/deadlock prefix; **not yet observed here**. Expected after fix: A count1/result41, nested B count1/result42, CONTROL-PASS and exit0. COUNTERS-OK alone is insufficient: cleanup/thread-join errors remain CONTROL-FAIL/exit70; outer watchdog preserves missing-edge evidence.

Additional hook-dependent cases require a new bound producer hook, not a fake fixture:

- Pause between terminal native commit and exact unlink. Reenter legal service; A never resets2; C behind it can run; R pending finish keeps anchor.
- B or a middle procedure hint completes while A yielded; append C concurrently; verify actual queue reachability/head/tail, no old prev/next reuse after real moving GC.
- Terminate target with A/B Active and C Queued. Sender sees declared abandoned semantics; no old activation normal-store after termination; once-only R/S/H counts. Inject release Retained for A and finish B/C: persistent A root/epoch survives GC, no teardown success, no cohort-wide lock wait.
- Exercise supported continuation boundary separately. The fixture does not prove arbitrary multi-shot call/cc side effects are once-only. Bind actual generated before/after/error labels and verify the grant owner, rather than merely checking phase2.

Do not add blocking/GC hooks under T/M/P. Generated C must map request, unit/grant, exception/outcome, selected hint/H and cleanup next/retained nodes across every unlocked SYNC/allocation/escape. Source-package maps or source-level W_ALL are not that certificate. No original6-million stress or full inventory is run here; after the focused controls and codegen certificate Grok follows the existing pressure plan.

## Source/verification binding

This audit reconstructed selected candidate sources by exact-context application of the supplied diff to immutable `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` Git blobs; no runtime checkout was edited and no compiler ran. Snapshot paths, hashes and candidate line numbers are in `active-request-drain.json`. These are patch-derived source identities, not an independently verified identity for the reported gsi.

Quint/TLC19 controls matched expectations:4 positive safety/conditional-progress checks,10 decoded safety mutants,1 temporal head-only stall and4 completion/retention reachability witnesses. The extra positive preserves a committed success through later termination; LatePayload catches an overwritten outcome without needing a second pin decrement. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/3f7ebac3414a4aaea2428f32e51b8c9b/outputs/active-request-drain/receipt.json` (SHA256 `7338e3583f01430bddd2d09f14e06e03e3f5e6291b77ac73c1050bc1cb1d5d29`). The final model includes TerminalPendingFinish and outcome/termination ordering; prior15/16-control receipts remain retained, not relabeled as final. Every case retains30s. The Good path has two abstract GCs and migration; termination/retention paths include the prior yield/migration then detached cleanup. Retained “done” means the observation/control completed with A still rooted/pinned and B/C settled, **not completed target/VM teardown**.

The model uses a concrete three-node singly-linked chain with head/tail, logical request identities and one detached-owner root. Atomic actions abstract valid short native transactions; per-action weak fairness and finite modeled thunks are progress premises. It does not prove actual generated maps, arbitrary queue lengths, native tree/lock code, multi-shot user continuation semantics or a persistent retained VM root already exists. No new native run; actualGeneratedBridgeCertificate remains null; count8/12.

2026-10-24 exact353 producer follow-up: [Actual generated maps and Retained consumer gap](producer-353-retained-audit.md) resolves066f07d2 and distinguishes publisher roots from missing notification retry/final unlink. Earlier QNT controls are not recast as native closure.
