# Synchronous callback repark: collective entry, native stack and traced roots

This evidence-only handoff is bound to lock-main revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the cumulative foreign-release-claim patch, using the immutable source receipt in [staged FFI identity](staged-ffi-generator-protocol.json). Vendor HEAD is a separate project and is not required to match. New symbols below are proposed; no runtime/generator/C regeneration, qualification, historical-receipt or other-thread changes were made. Recorded qualification is 8/12; no native admission is claimed.

## Independent conclusion and correction

A synchronous function call alone preserves the OS stack but does not establish GC roots, a valid cohort departure, or safe failure handling. The helper cannot simply call current `on_all_processors`, decrement processor_count and return. The existing operation loop has neither a repark result protocol nor an active-rank departure boundary. Three properties must be implemented together: a registered typed native-root journal, a common noncompeting post-operation window, and an old-cohort completion handshake before B can return to potentially blocking host C.

After a preparation GC, a later GC can relocate the same roots before the callback epilogue finishes. Do not require repeatedly restarting the Scheme landing whenever a GC wins. Instead, preserve the completed materialization/no-new-Scheme-frames certificate, trace the actual root cells on every intervening GC, and revalidate current storage in the mandatory reader-free window immediately before membership commit. If new Scheme frames, aliases, private work or unclassified callbacks appear, the certificate is invalid: remain active and reprepare through a controlled landing. A GC generation bit returning to an old value is not freshness evidence. The model's dirty latch is abstract invalidation, not a proposed two-valued production epoch.

## Actual entry and functions that must change

| Same-generation source | Observed behavior | Required synchronous repark contract |
| --- | --- | --- |
| `lib/_kernel.scm:1468..1485 ##sync-op-interrupt!`; archived `lib/_kernel.c:12362..12396` | Stores RA, executes W_ALL, calls service_sync_op, then R_ALL/fetch RA and ordinary Scheme return. | Reuse as an active service/root-publication control only. A successful repark must not fall through its R_ALL/RETURN on a detached ps. Generate a distinct callback preparation landing that returns while active; commit later from the native wrapper. |
| `setup.c:1731 on_all_processors` | Raises INTR_SYNC_OP then synchronously calls execute_sync_op_loop. Its own C callers remain on-stack. | New `___park_repark_callback_in_place(job,cb,certificate)` enters the same common engine from the original native owner with no T/P lock, active membership, rooted live state and a live local catcher. Wake hints do not constitute the request: persist a keyed repark obligation before notifying peers. |
| `setup.c:1600 execute_sync_op_loop` | Elects via barrier_sync_op; clears sync flag; executes operation; marks matching winner NOOP; breaks after the common NOOP; defers some errors until the end. Startup/resize callers differ. | Add one common epoch/round schedule for native and Scheme callers. GC/resize wins may not erase the repark obligation. Stable post-operation READERS_EXITED → bounded repark validation/commit batch → old-cohort RESULT_ACK precedes another election. Do not implement repark as a perpetually lower-priority opcode competing with GC. |
| `setup.c:751 barrier_sync_op`; message macros705..732 | Tree is logical id/processor_count; messages acquire-load and release-store payload flags. Broadcast delivers the choice, not proof that all descendants have finished operation tails. | Gather old-cohort reader/tail completion; decide and publish one initialized new descriptor (membership/ranks/scan ownership). Every old member, including departing B, ACKs the result in a final old-descriptor round. No member enters the next new-descriptor barrier early. Only then B leaves; survivors proceed on the new descriptor. Keep old descriptor pinned through its final reader/ACK grace. |
| `setup.c:1530 execute_sync_op`, GC branch | Calls garbage_collect_pstate; resize has a separate result barrier. No repark operation/result exists. | Dispatch proposed prepared repark records only in the fixed service phase. Validate full VM/job/native-owner/callback/epoch key and no-private-work/alias certificate; use collective status, not local success. Unknown publication is a shared fault, not a retryable local refusal. |
| `setup.c:1716 service_sync_op`; worker post-run loop1006..1036 | Native-only worker can run the collective loop without returning to Scheme. | Repark failure uses a native **retained-active service loop**, entered synchronously inside the still-live callback wrapper. Reuse the common engine, not a separate private barrier or an unserviced condition wait. The loop preserves the original host activation and all job/tail/root pins. |
| `setup.c:3951 ___call`; header10051..10075 TRY and10113..10129 SFUN | ___call supplies live Scheme-to-C return frames/catchers; ordinary SFUN epilogue kills marker/leaves count then propagates error outward. | Checked callback keeps error/result in the registered journal. End the child TRY/marker exactly once, retain a native tail, install an actually live local service catcher, then repark. Catcher context must remain valid throughout synchronous service. Never longjmp to the outer host dispatcher, to an expired child catcher, or across host C++ destructors as a recovery mechanism. |

There is no approved numeric opcode assignment in this handoff. A repark pending record and fixed collective phase are protocol changes, not an excuse to reuse OP_VM_RESIZE or an unreviewed priority number. GC, resize/startup and error convergence must share the same phase schedule before this can be compiled safely.

## Concrete generated C and root correspondence

Existing generated sync code executes the following, rather than merely declaring PW_ALL:

```c
___FRAME_STORE_RA(___R0)
___W_ALL
service_sync_op (___PSPNC);
___R_ALL
___SET_R0(___FRAME_FETCH_RA)
```

This roots selected GVM state; it does not enumerate arbitrary native C automatic variables. Header6833..6834 selects MR/PR and MW/PW macros;7116..7117 copies R1 between the C register local and ps->r. `mem.c:7220 mark_registers` scans actual ps->r;7235 mark_saved scans saved[]. `mem.c:4405 mark_rc` scans **&h->data**, updating the cell, not a copy in a native local. `gsc/_t-c-2.scm:847 targ-gen-label-return*`, its frame-live?/saved-register map construction at890..926, and299..305 return-label emitters determine Scheme frame descriptors. Header9371..9388 decodes the maps consumed by frame scanning/materialization. None creates a map for a newly handwritten C wrapper.

Grok must emit and inspect, on the exact configured compiler/header, these concrete liveness regions:

| Region | Must remain traced and physically updated | Native-only storage / forbidden access |
| --- | --- | --- |
| Callback Scheme execution and preparation landing | Parent carrier, callback Scheme result/error, callback marker while live, current saved continuation; corresponding actual frame slots/register map bits or registered RC cells | Stable native job ticket, copied buffer handles and native loan metadata. Do not call a raw pointer a Scheme root. |
| Child epilogue → collective entry → any intervening GC | Transfer all still-needed Scheme result/error/carrier values into registered journal cells **before** their child frame/marker coverage ends. Preserve cell ownership/native tail after SFUN count drops. | No raw SCMOBJ copy cached across service GC; reload updated cell while active. Do not use an old fp/heap pointer as rollback. |
| Reader-free validation and commit | Complete frozen domain with typed still/RC/continuation roots, one assigned active scan owner; initialized descriptor before release-publication | Only stable native status/result fields after departure. No Scheme allocation, callbacks, R_ALL, ps->temp writes or ordinary Scheme RETURN after detach. |
| Retained-active failure | Same actual roots continue in active scan domain; no duplicate frozen registration; journal/error/tail remain pinned | Loop services cohort on original owner, may retry only a classified prepublication failure. No return to potentially blocking host body while active. |
| Successful departure → callback C return | Parent job/frozen roots outlive callback tail. A truly native callback result is copied before final tail release | Last reference drop is the final descriptor access. Scheme-valued callback result or raw movable alias cannot be returned detached without a separately admitted rooted-handle ABI. |

Proposed emitter shape (not generated/compiled C):

```c
/* child result/error already transferred into registered actual cells */
close_child_try_and_marker_once(cb);  /* returns while still ACTIVE */
/* cb native tail and parent job root/ticket are still held */
status = repark_service_with_live_catcher(job, cb); /* synchronous, no outer throw */
if (status == RETAINED_ACTIVE)
  retained_active_service_loop(job, cb); /* may retry/fault; never ordinary host return */
/* PARKED_ACKED only; no ps / GVM local reload from this point */
native_value = copy_declared_native_callback_value(cb);
release_native_tail_last(cb);  /* no cb/job/ps read through that last borrow afterward */
return native_value;           /* original host C activation continues */
```

This requires a checked SFUN emitter and emitted root ownership table, not insertion of W_ALL/R_ALL around an existing raw SFUN epilogue. The archived C excerpt is a structural control; no new landing/frame map has been generated or certified here.

## GC insertion, callback error and failure dispositions

1. **GC before preparation:** finish it as an active member, then create the current saved/materialized certificate. No T/P lock across the preparation landing.
2. **GC after preparation, before service:** keep the repark obligation; scan/write actual journal cells, saved frames and native roots. In the mandatory post-GC window, after all active readers and native operation tails exit, validate the updated roots and no-new-frame condition, then commit without an intervening allocation/callback/GC. A Boolean epoch equality is insufficient; use full incarnation/round/nonce and lifetime-bound descriptor.
3. **GC requested during the window:** retain its demand and service it on the stable new cohort after departure ACKs, or on unchanged old cohort after a common refusal. Do not start its root snapshot inside validation/commit. This is bounded GC postponement, not dropping a GC request.
4. **Callback error:** persist traced Scheme error before marker teardown; use only the ABI-declared native error mapping. Defer outward errors until common result completion; the service loop must not throw through host frames. A mapped callback error still reparks before returning to a potentially blocking native caller. Unmapped callback ABI is refused before acceptance or terminally contained, not silently converted to success.
5. **Known prepublication refusal:** unchanged old membership and active root owner; retain journal/tail and continue common service. Retry can succeed if the stated transient cause clears. Permanent refusal can remain safe and GC-serviceable indefinitely; it does **not** imply eventual callback/host completion.
6. **Materialization/rollback failure requiring Scheme repair:** keep active scanning and native tail, go through an admitted repair landing only with valid rooted state, then re-enter common service. If no safe repair landing exists, retain in service/fault disposition; do not manufacture readiness or run arbitrary callbacks inside the reader-free batch.
7. **Unknown membership publication, shared-lock unlock outcome, broken service transport or nonresponding active member:** roots retained alone do not close this path. Reconcile via a separately proved shared fault protocol, or use reviewed terminal containment. The current model assumes reliable common phases and cannot justify excluding a missing active member. It is unsafe to label this RETAINED_ACTIVE and then stop servicing.

## Grok implementation and targeted native order

1. Add persistent callback-return/repark ticket and typed root journal in the staged emitter; enumerate every Scheme-bearing field and every final reader. Emit the active preparation landing and inspect its exact return labels, executed register saves and frame maps under the locked configuration. Keep host BODY ABI free of movable Scheme aliases.
2. Implement common fixed service window/old-result ACK in execute_sync_op_loop and native service_sync_op callers. Add native repark entry with lock checks, owner/ticket validation and a local live catcher. Do not let Scheme-only hooks or local NOOP decisions create/diverge phases.
3. Implement one atomic descriptor publication plus old-cohort departure ACK. Keep GC debt until a stable new-cohort service accepts it. Verify active-rank tree/scanner count and complete frozen root inventory together, not as two publications.
4. Add retained-active service and explicit callback-error mapping. Retry only known prepublication refusal; prove no-throw containment and native stack identity across every service round. Pin old descriptor, journal, marker/carrier and native tail until their independent last consumers leave.
5. On a single source/generated/object/link-bound producer, inject GC before preparation, between child marker close and service, and immediately before commit; enqueue another GC during commit. Assert actual RC data/result/error relocation, same host activation/OS owner, zero detached GVM access, one callback epilogue and no post-last-release access.
6. Inject transient/permanent repark refusal and callback error concurrently with repeated GC and another member's work. Assert B remains an active service participant on refusal, every operation gets the same cohort/round/result, GC continues, no premature host return, and later retry departs once. Test unknown shared faults separately as retention/reconciliation/terminal outcomes; never relabel them recoverable success. Keep existing native budgets and receipts; do not run a full inventory merely for this handoff.

Sufficiency is conditional, not established: these changes address a concrete missing service/departure/root protocol. They do not yet prove actual generated maps, C11 memory ordering for new fields, arbitrary nested callback stacks, P0 delegation, frozen weak/finalizer semantics, fault recovery from unknown commit, or native behavior. Production readiness requires those source-bound implementations and same-producer targeted evidence; the model cannot turn 8/12 into 9/12.

## Proposed fields, publication and cost

These fields are not present as a completed protocol in the locked candidate:

| Stable record | Owner and ordering | Last consumer |
| --- | --- | --- |
| job/{vm_incarnation,owner_incarnation,activation,callback_depth,nonce} and root cells | Initialize before release-publishing pending; acquire-validate full identity before use. No cached slot address authorizes a new incarnation. Typed cells are written by the selected active collector; mutate them only under the admitted GC/root protocol. | Native host completion/export and associated scanner/queue readers, independently of child marker lifetime. |
| repark/{prepared_frontier,alias_class,materialization_complete,dirty,pending,status} | B prepares while active. Dirty/fresh state is part of the common round, not two-valued GC freshness. Validation at reader grace refreshes the current root storage/certificate; all result writers converge before release-publication. | B's acquired common result and final old-cohort ACK; retain if status/publication is unknown. |
| cohort/{epoch,ranks,scan_domains,phase,old_result_ack} | Initialize successor descriptor before release-publishing COMMITTED; members acquire-observe it. Keep final old-tree gather/broadcast on immutable predecessor ranks, then enter successor. This is a required implementation happens-before chain, not already proven C memory ordering. | Every predecessor tree/result reader and departing native service tail; no free merely on leader publication. |
| callback/{native_value,error_root,native_tail,service_catcher} | Move Scheme values to actual traced cells before child close. Native tail survives marker/SFUN leave. Local catcher is live only inside the synchronous helper; state used after setjmp is stable journal storage, not modified nonvolatile locals. | Copy native value/status first; close service catcher; final native-tail release; then no descriptor access through that borrow. |

The frozen certificate's frontier excludes the completed child activation after its roots have been transferred. Invoking a new Scheme repair landing creates a new frontier and invalidates any earlier no-new-frame certificate; it must finish while active and re-establish coverage before another commit. Keeping the host C activation is not permission to retain a movable Scheme value in its raw C locals.

Cost is a global rendezvous plus bounded validation/commit work per callback-return park and corresponding rejoin; native stack depth is retained for the callback duration. The fixed service window bounds consecutive GC elections before servicing an eligible repark, but does not bound a slow/nonresponding participant. Root-map/journal scanning adds work proportional to live registered fields and frozen domains on each GC. Existing materialized frames can be traced again without copying the whole continuation on every GC; new frames/aliases require reprepare. No latency/throughput claim is admitted without matched native evidence. This is a semantic cost of safely detaching a participant, not a constant-cost wakeup patch.

## RC carrier implementation constraint found in this source

`mem.c:732 ___alloc_rc_no_register` allocates a native payload and initializes h->data to FAL;752 ___register_rc only links it into the owner chain;772 ___alloc_rc combines them. `mark_rc` traces exactly one Scheme cell, h->data. It does **not** scan arbitrary payload bytes after h+1. Therefore a C struct containing several SCMOBJ fields behind an RC pointer is not a traced journal merely because ___alloc_rc allocated it.

Use either one h->data-rooted Scheme carrier containing the required typed fields, or separate registered h->data cells per logical root (and a classified collector scanner if introducing a different representation). Create/root the carrier while active before any GC-capable conversion, install it with ___set_data_rc, and reload through ___data_rc after every GC; never cache the carrier's movable body address. The payload contains native identity/ownership metadata only unless its fields have an explicit scanner. Model MissingJobMap/MissingCallbackMap are precisely the missing-actual-cell-scan failure, including this payload misconception.

`___addref_rc`, `___release_rc` and ___register_rc in this candidate are plain owner-local increments/decrements/intrusive-link writes; release immediately unlinks/frees at zero. They are not a cross-thread atomic pin or scanner-grace protocol. Allocate/register/update/release on the admitted owner while active or in its authorized reader-free owner window; remote job/scanner readers need the separately ordered descriptor/pin ledger. Do not add a remote ___release_rc or assume incrementing this plain count makes a race with GC safe. The final native-tail token and RC carrier reference have different final consumers. Root and native release must obey their respective grace boundaries.

### Admission and closure caveats

The no-T/P-lock condition is a required staged adapter precondition, not a fact established by merely calling a native function. Arbitrary host locks, recursive owner entry and callback affinity must be classified; the current plain SFUN frame count cannot prove them absent. Implementation must carry/validate the admitted activation and lock/alias state, refusing unsupported adapters before invoking their body. A bare TLS PSTATE is not that authority.

External VM closure must not revoke the accepted job's internal service/rejoin capability. If close has begun after acceptance, preserve its drain ticket and root/native tail until the common close/commit protocol resolves it. A new public admission may be refused while that internal lane remains legal. No code may manufacture a fresh VM incarnation to complete an old job. Closing or destroying the common service backend while such a participant is active is an independent last-consumer violation.

## Recorded QNT validation and exact scope

`models/gambit/repark_cohort.qnt`: Quint0.33.0/TLC,23 expected controls:4 safety/conditional-progress scenarios,15 decoded safety negatives,4 distinct reachability witnesses. Maximum case 5.350s; unchanged30s per-case cap. Receipt:`.cache/tasks/repair-9-12/processes/audit/runs/76e4305ed7b8452d9cb27bc26ef47564/outputs/repark-cohort/receipt.json`. All checker inputs were reconstructed byte-for-byte and witnesses independently checked in Python. Source snapshot33files and protected inputs20 reverified unchanged.

The permanent-refusal positive requires recurrent service-window completion under weak fairness (both service-bit values recur), not callback completion. A transient refusal later commits; the error path returns only after departure ACK. Reachability includes GC→commit, retained-active service after GC, mapped-error return and a GC demand still owned after departure. Negatives cover host unwinding, local exclusion, lost repark/GC debt, stopped active service, GC inside the validated window, stale commit, both missing root maps, stale C local, early native return/tail release, T lock, old ranks and error throw through host frames.

The original21-control predecessor at audit28ae3a093c224f97802aa7f23c07b954 and safety-first23-control slice at audit84c860fc84304152afea4a3c504d434b are preserved. Final23-control evidence additionally requires every recorded GC demand eventually be accepted under fairness; the next stable election may not choose NOOP while that demand is pending. It includes a concurrent GC demand during the window, its handoff and a loss negative; final model identity is bound in the JSON index. Recurrent GC is modeled by relocation parity plus a separate dirty latch. There is one callback and one explicit concurrent GC-demand obligation; arbitrary native recursion, epoch wrap/ABA and multiple queued requests are not exhausted. Atomic reader grace/descriptor commit/ACK stand for required implementations; this is not a multi-processor C refinement or a fault-tolerant consensus proof. No generated-C regeneration or native execution occurred.

## Subsequent ACK and final-root lifetime refinement

[Old-cohort ACK/successor activation/RC carrier](cohort-ack-rc-protocol.md) splits result installation from native-tail quiescence, requires independent epoch channels if successor service overlaps predecessor tails, and locates root-release ACK in the reached generated completion landing. Its22-control slice does not reinterpret prior23 controls as proof of those previously atomic steps; immutable receipts remain unchanged.
