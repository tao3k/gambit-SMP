# Prepared signal implementation: one nonblocking native try-commit

2026-10-24. Current baseline is `procedural-suffix.lock.json`, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, patch6aca28e0. This is a concrete implementation refinement for Grok, evidence-only in this chat. It corrects the runnable destination choice and removes held-lock Scheme calls from the preceding plan. No runtime or generated C is edited, no producer/native test/model rerun, no peer operation, commit or push.

## 1. Decision: make the no-GC boundary implementable

Keep Scheme responsible for allocation, rooting, thunk execution, SYNC/GC retry and post-commit notification. Move **all** request-specific lock attempts, mutation and unlock into one new internal native helper, proposed `___thread_intr_try_release(ps, request, mode, unit, normal_action, abandoned_action)`. The generated Scheme wrapper calls it with no scheduler locks held. It returns with no scheduler locks held on every ordinary return.

The helper takes no blocking ticket, waits for no actor and calls no Scheme procedure. Contention returns Retry with no mutation; Scheme participates in SYNC/GC and repeats from fresh input. This avoids needing to prove that several generated Scheme tree procedures have no stack checks, closure creation or GC while M is held. Do not simply wrap calls to those Scheme procedures inside a C function.

Implement three native mutation kernels from the **current selected SMP** `define-rbtree` generator: BTQ remove, TOQ remove and runnable BTQ insert. Use iterative C locals/fixed-size arrays, no recursion, allocation, Scheme conversion or indirect callback. Share statically called pure rotations/fixup/accessors where useful; do not introduce a general callback-driven tree framework. Preserve the source sentinel/color/parent/container/leftmost rules and comparison semantics. A direct call to a proved pure native helper is acceptable; a hidden scheduler/allocator/throw/lock call is not.

This has a larger, finite code diff than renaming the four-store leaf, but avoids the present indefinite “maybe generated helpers are pure” dependency. It is selected for stability and auditable boundaries. The port still requires differential tests and actual configured object inspection; it has not been implemented here.

## 2. Function split and exact ownership

| Current function | Required resulting responsibility |
|---|---|
| `##thread-intr-execute!1543` | Run thunk and construct/root outcome without primitive locks; store/root payload while keeping Active phase2 (remove the early phase store1557), then call the request-specific release wrapper in Normal or Abandon mode. Replace its result-mutex generic `macro-mutex-unlock!1558` with this same path, so normal completion does not retain the old partial-unlock risk. Re-raise a target exception only after consistent abandonment/wake, preserving sender behavior. |
| `##thread-intr-abandon-owned!1511` | Route cleanup through the same wrapper; no T-held wait for M, no waiter from deque-next, no unlocked generic signal. Guard target-unit consumption against repeated dynamic-wind exit. |
| Proposed `##thread-intr-release-owned!` | Root request/unit/outcome/action procedures; call native try-commit; on Retry service legal unlocked SYNC and restart; on committed result perform post-lock notification then exact unit settlement. Already-moved ownership is not automatic completion: check actual terminal stage/consumer before dropping R. Partial/unknown state is retained. |
| `___thread_intr_release_commit295` | Supersede its isolated self-link/owner/phase write sequence with the complete internal try-commit entry and native kernels; migrate both normal/cleanup callers together. Do not leave the old abandonment caller linked to this four-store version. |
| `##mutex-signal-no-reschedule!4221` | Remains for generic callers. Its drop-M/keep-W acquire branch4235..4246 and internal TOQ/P acquisition must never be called by native commit. Factor/port its mutation semantics; do not call it after unlocking. |
| `##thread-btq-remove!2693`, `##thread-toq-remove!2708`, `define-rbtree228..642` | Semantic source for the prepared native kernels, not callable GVM helpers inside commit. Do not accidentally enable the commented priority-downgrade path or non-SMP variants. |

Add a SenderFinal mode for the same private result mutex: expected owner is the actual current sender, request terminal phase/outcome is preserved, and the private no-waiter condition is checked. The sender calls this after normal lock2 consumption and from its supported lock2-error guard if it actually acquired M before the exception. It consumes S only after consistent final unlock/confirmed previous completion, never by blindly unpinning. Unexpected waiters or ownership ambiguity retain S rather than invoking a generic slow path. This keeps the private request cycle inside the same audited entry; it does not replace generic mutex APIs.

Native return statuses are private tagged results such as Retry, Committed, OwnershipMoved, Retained/Invalid. They are not pthread errno or qualification banners. Pre-mutation refusal changes nothing; accepted-but-ambiguous responsibility cannot be rewritten as not-accepted. No recoverable error/GC/throw is allowed after first mutation. A detected internal failure or hardware fault after that point must not resume Scheme/collector over a half-mutated tree; use the declared non-returning terminal disposition with retained diagnostics, never retry/rollback a partially modified tree. This is not arbitrary-corruption recovery.

## 3. Complete lock set and discovery without a stale root

Notation: M=result mutex, T=old target/owner, W=actual M.leftmost (or empty sentinel M), N=W.result if a thread, Q=W.toq-container if present, D=runnable destination. A request's R unit prevents normal member removal while this native attempt runs; public cleanup must also honor that debt as specified in the main plan.

1. Scheme reserves/allocates all needed objects and enters with mapped live request/action/unit/outcome roots. Native uses **try** for M; failure returns Retry immediately, no ticket reservation or spinning.
2. Under M, read T and actual W from slot7. To discover N safely, try W alone if present, read W.result, release W. There is no old-owner T ticket held in this discovery step. C retains the observed SCM value only inside this no-GC attempt; it is never returned as an unrooted pointer to Scheme.
3. Sort/de-duplicate `{T,W,N}` with current header `___OBJECTBEFOREP`, excluding only #f N and empty W; a truthy non-thread N is a pre-mutation retained/invalid state, not anonymous ownership. Acquire by try only. Failure releases the already acquired thread tickets and M and returns Retry. Recheck W still M.leftmost, W.btq-container==M, N still W.result, actual M.owner/reciprocal owner-deque links and requested phase. A changed observation releases all and returns Retry.
4. With W locked, compute `Q = W.toq-container` and **`D = W.migration-target or W.pinned or current-P`**, matching source705..721. The previous “always current P” choice is incorrect for pinned/migrating W. Validate D/Q membership and processor-object identity; sort/de-duplicate `{Q,D}` and try these P tickets. Aliases include Q==D, D==current-P, T==W, N==W or N==T. Acquire/unlock each distinct physical object once. If any P try fails, release everything and return Retry.
5. Recheck all state used for mutation, including Q membership, destination precedence, W's intended owner/termination disposition and root/sentinel validity. No Scheme/GVM call occurs while this set is held. Release order is P set, thread set, M on unchanged retry/finish; do not double-unlock aliases. Discovery's W ticket is not carried into the full-set acquisition.

Only M is common across discovery and full-set acquisition. N can change while W is temporarily released, so full-set revalidation is mandatory. Native C locals remain valid during the attempt only because this is a managed, active GC participant that never reaches a safepoint; a foreign/unmanaged/parked native owner is not admitted to this entry. A failed attempt returns no W/N/Q/D raw locals to be reused after SYNC.

## 4. TOQ and runnable write sequence

Derived SMP slot map, to be checked against actual generated accessors before compiling the port:

- BTQ node/sentinel: color4, parent5, left6, right/leftmost7; owned-mutex deque next2/prev3 and owner8.
- TOQ node/sentinel: color10, parent11, left12, right/leftmost13.
- Thread: floats16; BTQ container17; TOQ container18; end-condvar20; result22; resume-thunk31; pinned35; migration-target36. These come from the current `define-type thread1206..1264`, not a foreign ABI.
- Float vector: timeout0, effective priority6. Higher priority means `F64LT(priority2,priority1)`; equal timeout uses priority. Keep existing equal-key insertion order, native F64 comparison (including its existing NaN semantics), red=#f/black=tree-sentinel and root-parent fixup.

Under the complete prepared lock set:

1. Remove M from T's owned-mutex deque: write `prev.next=next`, `next.prev=prev`, then M.next=M.prev=M. Only these deque links change; do not use them to select W.
2. If W exists, remove W from M's blocked RB tree, including rotations/recoloring, M.leftmost updates, W.parent/left/right clearing and W.btq-container=#f. Port generator427..565 exactly; it also resets sentinel.parent. A parent clear alone is not removal.
3. If Q exists, remove W from Q's TOQ RB tree using slots10..13 and container18; update Q.leftmost/sentinel links and clear membership. Do **not** call `macro-thread-toq-remove-if-in-toq!1431`, which would reacquire Q. No timeout change/rebase is performed.
4. Apply the correct normal/abandoned/new-owner disposition from existing signal/unlock semantics. Live N receives M in its owner deque under N; terminated N follows existing abandoned behavior; anonymous N follows existing not-owned behavior. Set W.result/resume action consistently. No-waiter Normal sets existing not-abandoned state; no-waiter Abandon sets abandoned. Do not copy “owner=abandoned” unconditionally into the waiter branch.
5. Insert W once into D's runnable RB tree using BTQ slots4..7, container17 and existing strict-priority comparator. This writes **W.btq-container=D**, not current P unconditionally. TOQ membership is already gone. Set the request phase/result disposition after these structures are consistent.
6. Before unlocking, install any remote D notification responsibility into a preallocated scanned carrier (below). Release all locks, return Committed. No call to `##wait-abort!`, device abort, logger, allocator, VM lock, callback or participating helper occurs inside commit.

The port is three fixed native tree kernels, not replacement of the scheduler. Red-black fixup iterations must mirror the source's progress on valid trees; no fixed false “four stores” bound. A valid-tree premise is required; this work does not repair pre-existing heap corruption or TFIB.

## 5. Pin/root transfer and generated-C boundary

Keep request `[next,M,target,phase,id,R-unit]` from the preceding plan. Refine R-unit to preallocated `[armed,pending-D]`; its CAS flag stays at0, destination root at1. S/H unit cells may remain one-field. Native writes D there before unlocking when remote notification is owed. Do not return an unrooted processor pointer/id. The unit/request carrier keeps D live while locks are dropped and any Scheme GC occurs during finish.

The explicit unit argument is R for target Normal/Abandon and S for SenderFinal; its role/shape is validated before mutation. Only target R-unit has pending-D slot1; SenderFinal does not index that slot in the one-field S cell.

R remains acquired through actual native attempt, unlock and last D/notification access. Sender S can finish concurrently; it does not release R. H retains its own callback/forwarding guard. On Retry leave unit state/pending-D unchanged (normally empty), reload request/unit after SYNC, and discover all scheduling objects again inside the next native call. On success, finish the checked notification outside locks, clear pending-D only after last access, then consume R once. If publication/notification is uncertain, retain the named obligation; do not unpin because the helper returned or because the queue is empty.

Proposed Scheme bridge shape uses actual existing c-code argument machinery, **not captured generated output**:

```
(##c-code
 "___RESULT = ___thread_intr_try_release(___ps, ___ARG1, ___ARG2, ___ARG3, ___ARG4, ___ARG5);"
 request mode unit ##thread-locked-mutex-action! ##thread-abandoned-mutex-action!)
```

Emit an internal typed declaration in the same build/header arrangement as current direct release helper; do not edit generated C or rely on an unresolved legacy archive symbol. Action arguments are SCM procedure objects to store into resume-thunk, not native callbacks to invoke.

Compiler `_t-c-2.scm4201..4245` emits c-code operands and result; `targ-use-all-res` alone is no map certificate. Actual maps must root request (which reaches M/T/R-unit/id), explicit unit including lexical S, live outcome and action procedures and sender S around the wrapper, plus pending-D during finish. Save/reload actual live GVM registers/RA as required at the legal GC/reentry boundaries. A proved pure native call that neither enters Scheme nor changes GVM fp/hp/RA need not copy the blocking wait bridge's FRAME_STORE_RA/W_ALL sequence merely because it is a C call; verify the generated convention and keep RA unchanged. Adding a callback or GC to that body would invalidate this exception. After each unlocked SYNC, discard old interior pointers; the next helper derives every address again. Native locals W/N/Q/D need no independent moving-GC map **only within this demonstrated no-GC active-owner call**. Plain C local pointers are not roots at any other boundary.

## 6. Source feasibility and concrete remaining fixes

The tree generator contains no explicit Scheme allocator in its mutation algorithm, but emits local procedures/loops; current compiler emits CHECK/POLL machinery based on generated resource needs. Therefore the existing separate Scheme calls cannot presently certify an uninterrupted no-GC region. The native iterative port makes that certificate feasible without modifying global compiler scheduling. Inspect configured preprocessing and transitive object code for the real wrapper/kernel; reject Scheme calls, GC checks, allocations/conversions, blocking atomics, recursion, instrumentation/logging and exception paths in the normal commit. Pure direct native access/fixup helpers are audited transitively. Existing GCC tree-edge diagnostics (`macro-btq-edge-*971..996`) must not be copied as callbacks into commit; validate before mutation and use the existing terminal diagnostic disposition on illegal state.

Lock memory order is part of this proof: header6221..6227 currently makes grant loads acquire only for Darwin/GCC, with volatile fallback; TRYLOCK6237..6239 also starts with a volatile grant read. On the selected producer, replace/verify both debug and release grant observations with native-width acquire loads (or its proved platform equivalent), retaining release/full-barrier unlock. Do not assume a ticket reservation before the previous owner's writes is an acquire after grant, or switch compiler merely to bypass this obligation. Keep the existing non-thread branch distinct; native-width alignment/lock-free implementation must be checked.

Remote notification is another real gap already in integration step4: `os_io.c1538..1564` ignores write/SetEvent failure and11703..11794 permits an infinite native wait. **Subsequent SMP-call-site correction:** `_thread.scm3227..3238` already bounds bare idle to50ms and services unlocked; the device/no-sleeper branch3247..3252 is still unbounded. See `delivery-service-roots.md` for the precise selected-branch fix and no-GC/root certificate. Committed means durable runnable state, not observed wake completion. The earlier broad “no scheduler quantum” conclusion did not account for the Scheme bare-idle caller.

## 7. Same-producer acceptance, exact implementation order

1. Add private derived accessors/native tree kernels and try-commit status contract, then redirect target normal/abandoned release and sender final unlock. Preserve generic mutex users. Validate candidate slot map against regenerated accessor samples; derive reference clones from unchanged Scheme tree operations.
2. Compare native and reference BTQ/TOQ insert/remove across empty/singleton/head/middle, both-child deletion, rotations/recoloring, equal priorities/deadlines and supported F64 boundaries. Normalize node IDs/sentinels rather than heap addresses; inspect root/black height/parent/leftmost/container and unrelated nodes. This is a differential oracle for the port, not a fixture that repeats its algorithm.
3. Real M/T/W/N/Q/D alias/contended controls: no-waiter; Q absent; Q==D; remote pinned D; migration-target overriding pinned; N aliases; head/timeout/destination change during Retry with real GC. Verify no mutation on Retry, no lock leak, true W selected and real receiver resume action.
4. Instrument the real wrapper boundary: no scheduler locks on entry/ordinary return; no GC/poll/callback while native owns locks; moving GC before retry and during finish rewrites pending-D/rooted outcome. Show native attempt and same generated map/object identity. No injected blocking hook inside held locks.
5. Cover Normal, Abandon, SenderFinal, target termination and sender lock2 exception with R/S/H guarded counts; finish D notification and last release; retained notification/error/partial states prevent cleanup/resize. Do not clear debt to pass a test.
6. Freeze one final B with compiler/config/preprocessed/object/archive/generated-C/GSI/UUID and helper/fixture hashes. Run the existing focused controls then the bound flood and original two stress files from `delivery-integration-native-plan.json`, unchanged caps/topology/heap. Failure yields the actual unfinished R and earliest missing edge; no whole-inventory rerun or repeated unchanged producer.

No new model run is needed for this source/codegen refinement: prior15 controls abstract the prepared lock/tree steps and do not prove this native port, destination priority, maps or atomics. The concrete feasibility judgment is **implementable with the chosen native try-commit boundary, not certified in the current lock**. There is no final regenerated producer yet. Qualification remains8/12; TFIB, lifecycle, Gerbil and release do not close from this work.

## Audit receipt

All26 current candidate hashes and20 source conditions were checked. Complete excerpts/derived36-field thread layout are in the matching JSON. This final argument refinement covers target R and sender S explicitly and rejects truthy invalid N before mutation. Existing generated references remain unadmitted; no new QNT, compiler/object build or native test was executed.
