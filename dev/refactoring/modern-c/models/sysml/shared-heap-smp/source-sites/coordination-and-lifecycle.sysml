/* Model-owned source-sites/coordination-and-lifecycle declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpCoordinationLifecycleSources {
 private import GambitSharedHeapSmp::*;

 part packetObserverRouteLifetime:SourceSite {
  attribute :>> id="packetObserverRouteLifetime";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="___BOOL ___lifecycle_enter";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="lifecycle_enter briefly takes a registry reader, verifies the VM and current physical owner, increments that owner's execution entry and releases the registry reader. The interface requires current PSTATE and is not a metadata-only observer admission.";
  attribute :>> required="A source observer needs a checked route/incarnation and VM-local lifetime admission without impersonating an execution owner. Transfer from a short registry lookup to VM/source-local protection before ending lookup; never retain the global registry reader through RC lock waits, GC or pending ACK. Close observer admission before physical VM/source cleanup and separately drain admitted local readers.";
  attribute :>> gap="No current observer-role route/pin transfer exists. A saved VM/source address or reused execution/member entry counter cannot prove it. Unknown route admission cannot be upgraded to absence or physical death.";
  ref part :>> question=cutSource;
 }
 part packetActivationObserverRetirement:SourceSite {
  attribute :>> id="packetActivationObserverRetirement";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="void ___lifecycle_marker_abort";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="marker_prepare/abort own the active activation list and idle slot cooperatively; abort unlinks, returns roots, resets the record and reuses/frees it before dropping its entry. Terminal lifecycle_close_context also walks and frees activations. GC workers currently do not inspect that list.";
  attribute :>> required="Metadata observation introduces another reader: protect active-list/idle-slot publication, lookup pins, unlink and reinitialization by the same source/control protocol. Close new observations, retain installed-root/ACK results and drain actual readers before IDLE/free; do not overwrite uncertain records or force native root cleanup under a source lock.";
  attribute :>> gap="Existing owner-only list discipline is insufficient for helper observation. Root-return/free must be staged outside nonrecursive source lock with an exclusive cleanup reservation; normal abort, terminal cleanup, cached-record reacquisition and failed setup must share the guard.";
  ref part :>> question=cutSource;
 }

 part minorResizeLoan:SourceSite {
  attribute :>> id="minorResizeLoan";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="cell=___borrow_rc_root(___ps,root);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Resize passes an RC cell through OP_VM_RESIZE and retries inside TRY after GC, then returns the borrow.";
  attribute :>> required="Keep registered root custody while raw data access is closed. Reload after repair and keep source until target install and ACK.";
  attribute :>> gap="Force nested throw, late raw write and lost ACK; capture retained owners and actual reloaded slot.";
  ref part :>> question=boundarySource;
 }

 part workerPostGcRootWake:SourceSite {
  attribute :>> id="workerPostGcRootWake";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___WORD_STORE_RELEASE(&ps->field,val);";
  attribute :>> role="minor-admission";
  attribute :>> observed="The DEV-only scoped crossover keeps the memory object and FIFO protocol fixed. Moving processor zero's post-GC tree notification before recipient mutex release changes no-probe TFIB body time by minus 11.24 and minus 0.57 percent in opposite-order pairs. GCBench changes by plus 6.06 and minus 34.69 percent. Both map replay arms match the retained output byte for byte, including eleven complete collections at R3 W2.";
  attribute :>> required="Publish the predicate under the existing recipient mutex. Signal exactly once for each tree send. The receiver tests the predicate under the same mutex before sleeping and after reacquisition. Keep this intervention separate from FIFO task and idle authorization.";
  attribute :>> gap="In a separate recorder-off probe crossover, TFIB pause p99 moves from 5.216 to 2.286 ms and from 12.194 to 3.955 ms. Carrier two inclusive barrier p99 moves from 3.293 to 1.447 and from 9.495 to 2.821 ms. Post-collector resume p99 moves from 0.206 to 0.148 and from 0.414 to 0.307 ms. All four initial TFIB buffers overflowed and were rejected. The repeat uses the prior 131072-slot buffer, adding 12582912 bytes of static probe capacity, with runtime budgets unchanged. The intervention occurs after collector completion in that GC round. A smaller collector envelope in the same campaign does not identify same-round causality. The no-probe reconstructed historical controls give TFIB role gaps of -4.64 and -6.02 percent. The treatment changes the candidate-to-baseline ratio by +68.92 and +27.26 percent, so it does not close the role gap. GCBench ratio interactions are -13.33 and -39.02 percent. The first common benchmark-object link returned 71 for the older role and was rejected. Matching each role to its compiled benchmark objects yields sixteen natural exits. Rebuilding setup.o means these role contrasts cannot be substituted for the exact historical archives. Direct OS wake attribution, mutex residency and peak RSS remain open.";
  ref part :>> question=nativeAcceptance;
 }

 part workerPostGcRootWakeGcc:SourceSite {
  attribute :>> id="workerPostGcRootWakeGcc";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___HIDDEN int barrier_sync_op";
  attribute :>> role="minor-admission";
  attribute :>> observed="Both historical setup.o objects rebuild byte-identically using the recorded GCC 16.2 C23 invocation. Treatment preserves archive order and all other 25 members in each role. Historical and relinked controls match before the signature after normalizing only UUID and signature size metadata. Clean TFIB control role gaps are -25.15, +4.89, -11.99 percent; the notification treatment changes those ratios by +60.84, +6.70, -50.32 percent. GCBench interactions are -26.46, -0.69, +18.76, -16.01 percent. The explicit sync argument removes the treatment-specific emulated TLS symbol. Its TFIB interactions are +95.98, -7.20 percent and its GCBench interactions are +134.08, +24.42 percent. The argument overlay reproduces the retained map and PBT replay byte for byte at R3 W2 with eleven full collections.";
  attribute :>> required="Maintain one synchronization predicate release, one signal and one mutex unlock per send. Keep the producer FIFO and worker idle protocol fixed. Compare same-role benchmark objects under the original budget and retain every unsuccessful or overlapped cell.";
  attribute :>> gap="One TFIB block overlaps the GCC compilation of the argument variant and is retained outside the clean timing summary. The TLS variant moves notification and adds an emulated TLS slot. Neither a mixed interaction nor a correlated pause change identifies historical causal mediation. Direct recipient wake latency and peak RSS remain unmeasured.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibJoinEpochReceipt:SourceSite {
  attribute :>> id="tfibJoinEpochReceipt";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));";
  attribute :>> role="minor-admission";
  attribute :>> observed="In sixteen qualified official runs the DEV root samples join counts after both child offers and before reply publication. Each child records acquire before ACK against the release-published epoch ticket. TFIB has 3618 to 3854 complete R3 receipts per run. Publication-to-acquire p99 changes from 0.272 to 0.225, 0.345 to 0.298, 0.244 to 0.263, and 0.230 to 0.209 ms. Capture-share deltas between cuts are plus 0.130, minus 0.027, minus 0.070 and plus 0.432 percentage points. GCBench has zero joins and mixed receipt p99.";
  attribute :>> required="Account for joins before the first cut, between consecutive cuts, and after the last cut. Preserve ticket identity through acquire before ACK. Reject overflow, duplicate or missing receipts and negative or overlapping epoch clocks. Report predicate observation separately from condition return and OS dispatch.";
  attribute :>> gap="The slowest one percent of publication-to-acquire epochs precede lower capture shares than the remaining epochs in all eight TFIB cells. This post-selection is descriptive. The next interval includes other scheduled Scheme and collector work. Neither an individual join dependency nor the no-probe historical effect is identified. The static 8192-row trace costs 917504 bytes and does not qualify peak RSS.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibReceiveRoute:SourceSite {
  attribute :>> id="tfibReceiveRoute";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="#define SYNC_GET_MSG(expr)";
  attribute :>> role="minor-admission";
  attribute :>> observed="The DEV overlay classifies each reply by deepest receive route. Of 631 TFIB receipts in the slowest one percent per run, 630 entered the condition wait and one only attempted the mutex. No pure spin receipt enters this tail. Recipient publication-to-acquire p99 changes from 318 to 209, 298 to 281, 246 to 122 and 248 to 171 us in four scope-matched treatment pairs. All sixteen official workloads exit naturally. The existing R3 W2 map replay again matches eleven full collections.";
  attribute :>> required="Keep acquire before ACK and classify condition calls even after a spurious return. Report receipt rank per recipient separately from epoch max. Disambiguate scheduler runnable delay from condition return and mutex reacquisition before assigning a wait cause.";
  attribute :>> gap="A condition call witnesses the route but not time spent blocked, runnable, or reacquiring. Probe-on improvements in these pairs do not establish the uninstrumented historical throughput mechanism. Route recording adds 65536 bytes of static BSS and peak RSS is unmeasured.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibConditionReturnCut:SourceSite {
  attribute :>> id="tfibConditionReturnCut";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);";
  attribute :>> role="minor-admission";
  attribute :>> observed="All 619 TFIB slowest-percent receive receipts overlap publication with their last condition call. Summed publication-to-acquire time is 314912 us, of which 314398 us lies inside the observed condition-call envelope and 514 us follows return. The treatment p99 moves 246 to 288, 228 to 244, 207 to 228, and 237 to 233 us. Three increases contrast with four decreases in the route-only campaign.";
  attribute :>> required="Bracket the last actual condition invocation and preserve the ticket to receiver acquire. Attribute an interval to that call only after intersecting its timestamps with publication-to-acquire. Report OS runnable delay and mutex reacquisition separately only when the same receipt has qualified OS evidence.";
  attribute :>> gap="The call envelope includes scheduling, condition completion and mutex reacquisition. Both three-second System Trace arms reported a successful save, but the shell observed 145 after constructor stop. A waitpid control failed to write terminal custody when the diagnostic directory disappeared. No OS join from this attempt is admitted. Comparison across probe designs and campaigns cannot identify whether the reversal is perturbation or host variability. Historical no-probe causality remains open. The extra timestamps add 262144 bytes of static BSS and peak RSS is unmeasured.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibConditionOsState:SourceSite {
  attribute :>> id="tfibConditionOsState";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);";
  attribute :>> role="minor-admission";
  attribute :>> observed="The corrected System Trace pair has two natural workload exits, two successful recorder saves and six successful exports. Same-thread anchor and continuous-state checks admit 3193 of 8636 control receipts and 1071 of 9908 treatment receipts. Among the observed top-percent waits, 16 of 87 and 18 of 100 are admitted. Runnable accounts for 85.32 and 64.78 percent of their respective complete kernel wait envelopes.";
  attribute :>> required="Require the trace event thread field to match the carrier TID, preserve both wait anchors, and reject gaps or overlaps in the thread-state table. Keep admitted and unobserved tails separate. Use a sender publication anchor to isolate the post-publication portion.";
  attribute :>> gap="The complete condition envelopes can start before publication. Unequal capture coverage prevents comparing these percentages as a treatment effect. Mutex reacquisition and historical no-probe mediation remain unresolved. No production throughput or peak RSS claim.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibPublicationOsBounds:SourceSite {
  attribute :>> id="tfibPublicationOsBounds";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___WORD_STORE_RELEASE(&ps->field,val);";
  attribute :>> role="minor-admission";
  attribute :>> observed="The sender markers share the OS trace clock and bracket the release store. In the successful control, 2169 of 10009 receipts have unique matching sender and receiver anchors and complete thread state. Of 101 tail receipts, 23 qualify. Their summed post-release Runnable time has equal lower and upper bounds of 22530206 ns. The treatment prints its result and then exits by SIGSEGV with no complete user receipt.";
  attribute :>> required="Match the ticket and both TIDs. Clip only actual Runnable intervals and report bounds using both sender markers. Count this as recipient time rather than VM wall time. Preserve a failed treatment as a failed pair.";
  attribute :>> gap="The successful control observes 5035 reply envelopes with a summed conservative bound of 640051000 ns, or 3.81 percent of the instrumented body. This is an upper bound on this observed direct path rather than an estimated saving. In the same-binary reverse run both arms exit naturally. The control admits 2574 of 8677 receipts and 25 of 87 tail receipts, with 27411791 ns post-release Runnable in the admitted tail. The treatment admits 1970 of 9623 receipts and 17 of 97 tail receipts, with bounds of 21239959 to 21502500 ns. Entire observed reply-envelope sums are 400969000 and 701722000 ns. Different tail sets prevent treating their sums as a saving. The earlier failure remains in the matrix; the archived disassembly and registers bind it to blr x1 with target minus four in ___call. The source writer and historical no-probe mediation remain open.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibReplyWallBounds:SourceSite {
  attribute :>> id="tfibReplyWallBounds";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));";
  attribute :>> role="minor-admission";
  attribute :>> observed="Re-reduction of three exact recorded receipt streams removes 380829000, 209684000 and 387238000 ns of double-counted carrier overlap. The reply interval unions are 3.69, 3.27 and 4.19 percent of their own instrumented body times.";
  attribute :>> required="For an epoch hold publication and other work fixed. Advance each recipient acquire by at most its measured post-release Runnable time, clipped to its own reply span, then take the maximum adjusted acquire. For missing OS coverage, use zero in the lower scenario and the full reply span in the upper scenario. Count wall progress once per epoch.";
  attribute :>> gap="Conditional observed lower scenarios are 0.84, 0.62 and 0.77 percent. Optimistic missing-coverage upper scenarios are 3.54, 3.06 and 3.88 percent. All cross the magnitude of the historical 2.93 percent, so these data cannot decide whether the reply path explains that gap. The model holds downstream work fixed and does not represent mediation in the historical probe-free runs.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibLastWaitWallBounds:SourceSite {
  attribute :>> id="tfibLastWaitWallBounds";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Capping unknown receiver intervals at the last measured condition call tightens optimistic wall scenarios to 3.52, 3.01 and 3.83 percent. All unadmitted nonempty last-wait receipts lie outside the respective admitted epoch ranges 1465 to 2550, 1032 to 2343 and 1187 to 2175. Neighboring same-TID evidence tightens only five receipt bounds and saves 583 ns from the second wall bound.";
  attribute :>> required="Use the last wait and publication intersection for its scope. Admit neighboring markers only when program order bounds the call. Leave unknown state, gaps and conflicting rows as possible Runnable time. Apply the recipient bounds before taking the last acquire per epoch.";
  attribute :>> gap="All three last-wait upper scenarios remain above 2.93 percent. The short OS capture omits whole epoch regions. Additional join logic inside the existing capture cannot supply those absent events. The bound concerns the instrumented last call and does not decide historical throughput causality.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibLateAttachCoverage:SourceSite {
  attribute :>> id="tfibLateAttachCoverage";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___WORD_STORE_RELEASE(&ps->field,val);";
  attribute :>> role="minor-admission";
  attribute :>> observed="With the same binaries and a three-second recording limit, a later attach admits 2188 treatment receipts across epochs 3037 to 4146. The earlier treatment recorded epochs 1187 to 2175. Both late workloads naturally exit. The late control has no matching sender or receiver anchors despite successful export.";
  attribute :>> required="Treat the attachment windows as different runs. Keep exact launch, exits and coverage. Do not substitute another run's events for missing state. Report the total user reply prefix separately from OS evidence.";
  attribute :>> gap="The direct reply envelope totals 173149000 ns for the late control or 2.40 percent of its body. In the late treatment the narrower last-condition Runnable wall upper is 207569261 ns or 2.59 percent. Both are below the historical 2.93 percent magnitude in these runs only. Asymmetric coverage and changed execution times prevent a causal verdict about the historical no-probe comparison.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibHistoricalRoleTrace:SourceSite {
  attribute :>> id="tfibHistoricalRoleTrace";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___WORD_STORE_RELEASE(&ps->field,val);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Both archived roles use identical probe cuts and signal after unlock. The baseline setup and thread members rebuild byte-identically, and each role uses its exact historical TFIB objects. Both workloads naturally exit. The baseline and candidate reply p99 values are 358 and 333 us, and timed bodies are 6.523 and 5.473 seconds. This instrumented comparison does not reproduce the historical slowdown.";
  attribute :>> required="Inspect actual epoch coverage and maintain distinct role receipts. Baseline admits 4536 of 7864 eligible receipts over epochs 930 to 3217. Candidate admits 1315 of 7479 over epochs 3234 to 3899. Compare whole user reply envelopes separately from sparse OS-state observations.";
  attribute :>> gap="The OS coverage ranges are disjoint even though recorder limits and launch procedure match. An OS role-effect comparison requires a shared relative execution region, with coverage verified from events. The full user reply envelopes do not bind the historical no-probe regression to the collector or wake path.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibPhaseAlignedWall:SourceSite {
  attribute :>> id="tfibPhaseAlignedWall";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));";
  attribute :>> role="minor-admission";
  attribute :>> observed="For the 30 to 40 percent progress bin, the fixed-other last-acquire advance is 2.158 ms for the baseline and 63.381 and 29.188 ms for the two candidate recordings. At 40 to 50 percent it is 18.300 versus 69.709 and 13.536 ms. The candidate-minus-baseline sums across the two bins are 112.631 and 22.266 ms.";
  attribute :>> required="Clip last-call Runnable to each recipient interval before reducing the maximum acquire per epoch. Sum only eligible phase-aligned bins. Validate all receipt hashes and keep the same baseline dependence explicit.";
  attribute :>> gap="These phase-local differences are 1.73 and 0.34 percent of the recorded baseline body. They are scale comparisons with fixed other work, not inferred savings. They neither cover all progress bins nor estimate historical no-probe mediation.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibHistoricalEarlyReverse:SourceSite {
  attribute :>> id="tfibHistoricalEarlyReverse";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));";
  attribute :>> role="minor-admission";
  attribute :>> observed="Both existing historical probe images exit naturally in reverse order. TFIB body grows from 9.099337 to 10.063493 seconds, while the summed reply envelope decreases from 285.614 to 280.476 ms. The 10 to 20 and 20 to 30 percent join-progress bins have complete eligible coverage in both arms, with opposite signs for their conditional last-acquire differences.";
  attribute :>> required="Preserve exact executable hashes and all terminal recorder evidence. With other work fixed, charge the whole candidate reply envelope once as the direct removal ceiling. Keep five-percent progress sensitivity separate from the primary ten-percent comparison.";
  attribute :>> gap="The 964.156 ms recorded body gap leaves at least 683.680 ms under the fixed-other scenario even if the entire observed candidate reply prefix is removed. This falsifies direct reply sufficiency in this recorded pair. Other barrier phases, changed work, and the historical probe-free attribution remain open.";
  ref part :>> question=nativeAcceptance;
 }

 part workerClaimFailureRoundDisposition:SourceSite {
  attribute :>> id="workerClaimFailureRoundDisposition";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="sop_ptr->arg[0] = ___garbage_collect_pstate (___ps, sop_ptr->arg[0]);";
  attribute :>> role="minor-admission";
  attribute :>> observed="The setup API copies the caller fatal hook into GSTATE and defaults it to null. The hook can be supplied externally even though no in-tree assignment is found. Both OP_GARBAGE_COLLECT and resize capacity GC consume the collection return as overflow. Normal return follows arena restoration, continuation movement and root reopening.";
  attribute :>> required="Keep known unclaimed contention on the retry path. After a claim invariant failure, publish the affected round, gate and claim custody before any effect. A stopped or unknown writer cannot authorize a peer to enter normal restoration. An ordinary overflow result requires a valid restored heap and does not represent quarantine after forwarding or field repair.";
  attribute :>> gap="A diagnostic hook with unproved effects cannot run inside the collector gate or reenter a frozen VM. A future recoverable refusal needs a separate end-to-end disposition through both callers, a common decision for every participant, and a verified resume seal. Current source does not establish that path. Process termination is a separate failure outcome.";
  ref part :>> question=nativeAcceptance;
 }

 part workerRoundBarrierPublication:SourceSite {
  attribute :>> id="workerRoundBarrierPublication";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));";
  attribute :>> role="minor-admission";
  attribute :>> observed="setup.h maps BARRIER to barrier_sync_noop for SMP. In setup.c the tree receives child arrivals with acquire before forwarding them with release, and propagates the coordinator reply with release after acquiring its parent reply. SYNC_GET_MSG rechecks the acquire predicate under the receiver mutex before sleeping. Condition delivery prompts observation; the acquired edge publishes prior writes. OP_GARBAGE_COLLECT exports a Boolean through the synchronous service; resize separately converts that Boolean to its collective capacity result before proceeding to reserve slots.";
  attribute :>> required="For one stable roster and nonoverlapping SPSC edge generations, each restoration write precedes the first barrier arrival and is visible at the coordinator before root_round_end. The coordinator's successful seal precedes the second barrier's downward release chain; each participant acquires that chain before using restored state. Reuse the existing publication edge when its roster and lifetime qualify. Any typed result must reach both GC consumers without mapping retained custody to ordinary overflow. Keep worker work-wakeup separate from roster resume.";
  attribute :>> gap="This conditional happens-before chain requires the actual atomic provider to implement matching acquire and release, correct edge reuse and a stable roster through both barriers. A lost claim, missing participant or held writer cannot be settled by signaling or entering another barrier. The proof explains visibility on successful completion, not progress under unknown exit or the tfib performance effect.";
  ref part :>> question=nativeAcceptance;
 }

 part workerRoundEdgeReuse:SourceSite {
  attribute :>> id="workerRoundEdgeReuse";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="SYNC_ACK_MSG(___ps->sync_id0);";
  attribute :>> role="minor-admission";
  attribute :>> observed="On the stable tree the parent copies the upward payload and ACKs it before releasing its downward reply. The child acquires that reply before it can publish a new upward arrival. Conversely the child copies and ACKs the downward payload before publishing its next upward arrival; the parent acquires that arrival before overwriting the downward payload. The send path releases the message under the receiver mutex, unlocks and only then signals the receiver condition.";
  attribute :>> required="Keep the reverse-edge handshake as the reuse authority for each direction while roster and slot incarnation are stable. A condition signal can run after the receiver has observed the payload and reset the slot. Keep the receiver condition and its containing storage alive through the last sender's signal return, or transfer them into retained custody. Bind retirement to sender and waiter exclusion as well as message settlement. A spurious or delayed notification only prompts a predicate recheck.";
  attribute :>> gap="The stable-tree proof does not apply when a replacement worker reuses a slot under a different roster or a sender disappears between unlock and signal return. Empty SYNC_WAITING, copied reply and a participant's local exit are insufficient retirement evidence. Qualify the actual resize and cleanup last users before reuse; unknown sender exit retains the affected synchronization resource. This source inference gives no latency credit.";
  ref part :>> question=nativeAcceptance;
 }

 part workerRoundSyncResourceLifetime:SourceSite {
  attribute :>> id="workerRoundSyncResourceLifetime";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="static ___BOOL cleanup_sync_op_vmstate(___virtual_machine_state vm)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Resize shrink changes membership at the old-tree rendezvous, then the retiring owner cleans processor data and publishes data_closed before thread exit. Join uncertainty remains on the launch record even if data_closed lets surviving members proceed. Processor cleanup preserves the VM-owned sync pair. Slot setup initializes mutex and condition only when the construction bits are absent, and resets message words after the old-set rendezvous and receiver join. vm-lifecycle.inc rejects uncertain launches at normal VM close; disposal destroys sync pairs and only then removes the VM registry entry. Unpublished constructor abort uses its own no-user path.";
  attribute :>> required="Reuse the VM-owned pair for delayed notifications under the existing stable storage contract. Separate message reset, roster removal, data closure and final notification-resource retirement. A detached worker needs its own last-use closure or the VM must retain its synchronization resources until joined. Qualify both the waiter and every remote sender through signal return before destruction; ensure roster exclusion also protects any reused plain payload fields.";
  attribute :>> gap="Existing source supports the carrier-bound lifetime split. It does not prove last-use exclusion for an independently transferred worker or a new wake channel. Native join uncertainty with data_closed is not permission to reuse the launch slot or free the sync pair. No tfib throughput credit follows from retained-resource safety.";
  ref part :>> question=nativeAcceptance;
 }

 part minorGcPauseBoundary:SourceSite {
  attribute :>> id="minorGcPauseBoundary";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="int winner_id = barrier_sync_op (___PSP &sop);";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV setup overlay records request before interrupt, arrival at the selected GC rendezvous, collector entry and return, and synchronization-loop drain. Missing and merged rounds cannot become complete pause samples.";
  attribute :>> required="Pair arrivals by VM and collector interval, charge dispatch and release separately, and keep traced throughput separate from uninstrumented controls.";
  attribute :>> gap="Product pause admission requires mutator resumption and native owner wait attribution beyond the synchronization-loop boundary.";
  ref part :>> question=nativeAcceptance;
 }
 part minorTakeoverStop:SourceSite {
  attribute :>> id="minorTakeoverStop";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="int error=pthread_join(thread->thread_id,NULL);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Join distinguishes error from success and alone cannot recover partial scan effects.";
  attribute :>> required="Require closed executor/helper write and publication access plus an exact frontier or retain old custody.";
  attribute :>> gap="Compare cooperative stop and unknown exit, late access, no-store next round and budget exhaustion.";
  ref part :>> question=nativeAcceptance;
 }

 part startupBorrowCaller:SourceSite {
  attribute :>> id="startupBorrowCaller";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="cell=___borrow_rc_root(___ps,root);";
  attribute :>> role="caller";
  attribute :>> observed="Startup borrows a registered source slot; later invokes make_sfun_stack_marker_root with that cell";
  attribute :>> required="Preserve the same source slot through GC and TRY exits; reload only with restored data access; return borrow before final source retirement";
  attribute :>> gap="This located startup caller does not cover every queued callback, raw SFUN conversion or asynchronous native borrower";
  ref part :>> question=cutSource;
 }
 part vmDomainEntry:SourceSite {
  attribute :>> id="vmDomainEntry";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="___BOOL ___lifecycle_enter(___processor_state ps)";
  attribute :>> role="admission";
  attribute :>> observed="Registry membership, live phase and indexed entry counter precede binding context admission";
  attribute :>> required="Separate VM lifetime entry from message ownership, control-shot domain and native activation/resource affinity";
  attribute :>> gap="A valid VM entry is not evidence a captured continuation or foreign resource may cross heap boundaries";
  ref part :>> question=boundarySource;
 }
 part lifecycleRootExit:SourceSite {
  attribute :>> id="lifecycleRootExit";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-lifecycle.inc";
  attribute :>> anchor="___BOOL ___lifecycle_cleanup_pstate";
  attribute :>> role="exit";
  attribute :>> observed="Entry close, RC prepare, foreign detach and drain precede physical PSTATE cleanup";
  attribute :>> required="A logical close is not physical stop; uncertain join/cleanup retains the source and its synchronization facilities";
  attribute :>> gap="Unknown same-heap writers still veto moving GC; independent VM progress must not depend on guessing death";
  ref part :>> question=cutSource;
 }
 part barrierRootPublication:SourceSite {
  attribute :>> id="barrierRootPublication";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___HIDDEN int barrier_sync_op";
  attribute :>> role="publication";
  attribute :>> observed="Tree synchronization owns a current processor population and payload/ACK lifetime";
  attribute :>> required="Final source stores precede tree release; acquired matching incarnation ACK precedes scan publication and edge reuse";
  attribute :>> gap="Compiler barrier, stack-trip interrupt and OS join are not substitutes for the whole configured publication chain";
  ref part :>> question=cutSource;
 }
 part nativeJoinSource:SourceSite {
  attribute :>> id="nativeJoinSource";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="___SCMOBJ ___thread_join";
  attribute :>> role="exit";
  attribute :>> observed="POSIX/Windows join returns platform success or error; caller owns consequence for lifetime";
  attribute :>> required="Only successful source-bound physical stop can permit memory/gate retirement; failed/unknown join retains debt";
  attribute :>> gap="A timed-out observer or returned error does not settle unknown memory accesses or grant stop authority";
  ref part :>> question=cutSource;
 }

 part startupSlotInstall:SourceSite {
  attribute :>> id="startupSlotInstall";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="slot->cell=___borrow_rc_root(___ps,slot->root);";
  attribute :>> role="handoff-call-boundary";
  attribute :>> observed="Resize coordinator initializes target slot RC root and borrows canonical payload before PSTATE setup/native launch";
  attribute :>> required="Target storage and inherited loan remain rooted across launch/GC until child root installation or known rollback; keep launch/VM/lifecycle/gate alive through actual native last use even before RUN acceptance";
  attribute :>> gap="Known synchronous path exists; no complete lost-return/partial-launch acknowledgment protocol or pre-RUN VM-control last-use proof is established; data_closed precedes gate unlock";
  ref part :>> question=cutSource;
 }
 part bulkIdleReuseConsumer:SourceSite {
  attribute :>> id="bulkIdleReuseConsumer";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="record=ps->mem.rc_domain_->idle_activation;";
  attribute :>> role="current-clean-record-reuse-caller";
  attribute :>> observed="Prepare reuses a checked IDLE record or allocates; abort clears and offers one idle record; RC cleanup later frees it";
  attribute :>> required="Close writer admission and drain already granted activation permits and record references before offer/reuse/free. Query uses held operation identity, never IDLE address. Preserve owner-only slot and lifecycle entry";
  attribute :>> gap="This concurrent runtime change is observed, not authored or performance-qualified here; clean legacy fields are insufficient for future bulk debts";
  ref part :>> question=cutSource;
 }
 part bulkMarkerRevocation:SourceSite {
  attribute :>> id="bulkMarkerRevocation";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="if(record->kind==___ACTIVATION_SFUN_ACTIVE)record->kind=___ACTIVATION_SFUN_REVOKED;";
  attribute :>> role="actual-revocation-with-live-c-extent";
  attribute :>> observed="Marker kill clears marker but active SFUN is only revoked; its C extent still owns bank/borrow/entry until explicit end";
  attribute :>> required="Keep return-destination revocation separate from physical stop and purpose-aware settlement";
  attribute :>> gap="No generic early release or bulk owner transfer follows from REVOKED";
  ref part :>> question=cutSource;
 }
 part bulkNestedCallEntry:SourceSite {
  attribute :>> id="bulkNestedCallEntry";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___call)";
  attribute :>> role="actual-independent-call-entry";
  attribute :>> observed="call takes its own lifecycle entry and releases it on normal or thrown exit; activation preparation owns a different entry";
  attribute :>> required="Keep nested call and activation/root obligations separately balanced; no aggregate entry count authorizes data access or root retirement";
  attribute :>> gap="Complete nonlocal/unknown native exit and bulk-purpose settlement still require source/native qualification";
  ref part :>> question=cutSource;
 }
 part bulkAbortLoanConsumer:SourceSite {
  attribute :>> id="bulkAbortLoanConsumer";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="void ___lifecycle_marker_abort(___activation_record *record)";
  attribute :>> role="actual-accepted-roots-abort-consumer";
  attribute :>> observed="Current abort unlinks activation, returns/releases nonzero accepted roots, clears owner/marker/roots/next and sets IDLE; it offers the record to the RC-domain idle slot or frees it, then leaves lifecycle";
  attribute :>> required="Keep private owned-output distinct from accepted borrowed roots and dispatch unknown registration separately before generic abort Extend current clean-IDLE qualification and source teardown to exclude all future prepared-output/intent/query/native debts before caching as well as before free.";
  attribute :>> gap="Using record->roots as an early raw output sink would add an unaccepted-loan/double-free risk; actual field/consumer migration is required";
  ref part :>> question=cutSource;
 }
 part bulkStartupCoreCaller:SourceSite {
  attribute :>> id="bulkStartupCoreCaller";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="sop.op=OP_NOOP;execute_sync_op_loop(___PSP &sop,0);";
  attribute :>> role="actual-startup-core-argument";
  attribute :>> observed="Startup descriptor establishes PSTATE/thread identity before direct sync loop entry with first_iter zero";
  attribute :>> required="Preserve startup-specific interrupt/reset semantics in extracted core; no implicit normalization to ordinary service mode";
  attribute :>> gap="Current startup does not supply proposed rooted bulk outcome sink";
  ref part :>> question=cutSource;
 }
 part bulkRequestExitCaller:SourceSite {
  attribute :>> id="bulkRequestExitCaller";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___WORD pending=___WORD_LOAD_ACQUIRE(&life->requests[requester]);";
  attribute :>> role="request-counter-and-exception-custody";
  attribute :>> observed="on_all_processors increments request counter, enters TRY, decrements it after sync returns or throws, then propagates error";
  attribute :>> required="Restricted/ordinary core consumers preserve request count cleanup and lifetime on all outcomes";
  attribute :>> gap="New deferred/unknown return state cannot skip decrement or confuse request consumption with effect completion";
  ref part :>> question=cutSource;
 }
 part bulkPendingErrorProducer:SourceSite {
  attribute :>> id="bulkPendingErrorProducer";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="void ___run_and_throw_error_on_processor_0";
  attribute :>> role="real-pending-error-producer";
  attribute :>> observed="Startup result is sent as OP_PROCESSOR_0_THROW_ERROR through on_all_processors; sender continues future synchronization";
  attribute :>> required="Preserve first-error arbitration, designated VM initiator delivery and rooted/nonmoving representation before further GC";
  attribute :>> gap="Generalized deferred Scheme payloads require reserved roots; no bulk pending-state service is implemented";
  ref part :>> question=cutSource;
 }
 part bulkCoreOutcome:SourceSite {
  attribute :>> id="bulkCoreOutcome";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="*sop_ptr = sop; /* return result */";
  attribute :>> role="request-completion-not-effect-delivery";
  attribute :>> observed="Winner or combining request copies result and sets local request OP_NOOP inside loop, before cleanup and throw postlude";
  attribute :>> required="Track request consumption, round restoration, pending error and cleanup outcomes separately without suppressing ordinary caller behavior";
  attribute :>> gap="No current bulk-specific complete outcome record or lost-return query exists";
  ref part :>> question=cutSource;
 }
 part bulkSyncDispatch:SourceSite {
  attribute :>> id="bulkSyncDispatch";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="void execute_sync_op_loop";
  attribute :>> role="collective-and-effect-dispatch";
  attribute :>> observed="Synchronizes pending combined VM operations, resets sync interrupt, executes resize/GC and ends with lifecycle_drain plus possible throw";
  attribute :>> required="Keep required collective participation while separating permitted memory/root work from user/native effect delivery at compatible boundary";
  attribute :>> gap="Calling existing loop is not GC-only; masking control operations risks a blocked collective";
  ref part :>> question=cutSource;
 }
 part bulkStageExitDispatch:SourceSite {
  attribute :>> id="bulkStageExitDispatch";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-lifecycle.inc";
  attribute :>> anchor="static int lifecycle_close_context";
  attribute :>> role="terminal-activation-exit-consumer";
  attribute :>> observed="Terminal path walks activations and generically returns root borrow, releases root and frees record";
  attribute :>> required="Dispatch a real bulk purpose to settle or transfer pending physical effects before root release/PSTATE retirement";
  attribute :>> gap="No bulk settlement or arbitrary dead-owner recovery is implemented by generic abort";
  ref part :>> question=cutSource;
 }
 part takeProviderSetup:SourceSite {
  attribute :>> id="takeProviderSetup";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="___SCMOBJ ___setup_thread_module";
  attribute :>> role="provider-resource-construction-and-failure";
  attribute :>> observed="First thread-module setup initializes emulation hash mutexes before incrementing module refcount; initialization failure returns without successful admission";
  attribute :>> required="Successful provider setup precedes every slot atomic operation; setup rollback excludes unpublished and late native users before destroying initialized mutex prefixes";
  attribute :>> gap="Thread-module refcount is not a per-accessor borrow count; slot/native call admission and rollback last users require concrete refinement";
  ref part :>> question=cutSource;
 }
 part takeProviderRetire:SourceSite {
  attribute :>> id="takeProviderRetire";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="void ___cleanup_thread_module";
  attribute :>> role="global-emulated-provider-last-use";
  attribute :>> observed="Thread-module cleanup reaching refcount zero destroys emulated hash mutexes; raw address admission alone does not retain these global synchronization objects";
  attribute :>> required="Global cleanup waits the enclosing admission/last-use cut covering every retained VM/slot/query/helper and fatal/native postlude, not only RC node or module reference counts";
  attribute :>> gap="No take-slot last-user integration exists. Unknown access retains the provider dependency and forbids final teardown; this does not alone block unrelated VM GC or prove its progress";
  ref part :>> question=cutSource;
 }
 part takeGlobalDrain:SourceSite {
  attribute :>> id="takeGlobalDrain";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-lifecycle.inc";
  attribute :>> anchor="static ___BOOL cleanup_runtime(int terminal)";
  attribute :>> role="vm-retention-to-final-provider-disposal";
  attribute :>> observed="Global cleanup checks VM registry/resize/lifecycle disposal before cleanup_os_and_mem; that function cleans memory before OS modules including the thread module";
  attribute :>> required="Unknown take users retain their VM/control/provider dependency through final registry and module teardown; no registry success may bypass actual slot grace";
  attribute :>> gap="No take-specific last-user dependency is implemented; preserve final global refusal without turning retention into an assertion that a shared gate or unknown writer is safe";
  ref part :>> question=cutSource;
 }
 part takeEmulatedRmw:SourceSite {
  attribute :>> id="takeEmulatedRmw";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="___WORD ___emulated_compare_and_swap_word";
  attribute :>> role="same-field-provider-interoperability";
  attribute :>> observed="Emulated RMW selects a hash mutex from the address and accesses pointed storage under it. Checkout now uses unsigned-bit-pattern/memcpy add and a C23 seq_cst fence; historical cache has signed add and an empty barrier. Its observed native+sync selection excludes this emulated branch";
  attribute :>> required="Qualify the actual selected combination of ordered-word and full-RMW providers on each slot field. All concurrent accesses need one interoperable service; source-only queue fields remain gate-exclusive";
  attribute :>> gap="No selected-provider preprocessing/code-generation packet or actual take slot exists; native atomic operations cannot be assumed to synchronize with mutex-only ordinary accesses";
  ref part :>> question=cutSource;
 }
 part checkedIncarnationPattern:SourceSite {
  attribute :>> id="checkedIncarnationPattern";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> anchor="if(vm_incarnation==___MAX_FIX)";
  attribute :>> role="existing-fail-before-generation-wrap";
  attribute :>> observed="VM construction refuses at its checked incarnation bound before incrementing or publishing a new instance";
  attribute :>> required="Take operation/helper generations need equally explicit checked bounds and full-key grace before reset; use no unrelated new configuration limit";
  attribute :>> gap="No take generation fields or headroom census are implemented; existing VM check alone does not prove take-slot exhaustion handling";
  ref part :>> question=cutSource;
 }
 part emulatedCollectorBarrier:SourceSite {
  attribute :>> id="emulatedCollectorBarrier";
  attribute :>> artifact="vendor/gambit/lib/os_thread.c";
  attribute :>> anchor="void ___emulated_shared_memory_barrier";
  attribute :>> role="backend-qualification-boundary";
  attribute :>> observed="Checkout standalone emulated barrier now uses atomic_thread_fence(memory_order_seq_cst); historical captured cache has an empty implementation. CAS and clear use the same address-selected hash mutex; neither fence establishes thread death or plain/atomic access interoperability";
  attribute :>> required="Establish same gate address and hash-mutex lifetime, unlock/lock synchronization for payload and queue accesses; a standalone fence alone does not establish the full required publication/last-use chain or legalize racing ordinary access";
  attribute :>> gap="Neither automatically reject the gate-protected path nor admit every emulated publication; full callsite/backend closure remains OPEN";
  ref part :>> question=cutSource;
 }
 part launchDataClosed:SourceSite {
  attribute :>> id="launchDataClosed";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___HIDDEN void start_processor_execution";
  attribute :>> role="native-stop-versus-resource-lifetime";
  attribute :>> observed="Rejected entry stores data_closed before releasing lifecycle gate and returning; resize retirement stores data_closed before thread_exit and separately records failed join uncertainty";
  attribute :>> required="Data access closure, native stop and descriptor/VM/mutex last use are distinct permissions; unknown join retains native/control resources even where root/PSTATE access is excluded";
  attribute :>> gap="No generic safe worker migration follows from this launch flag; actual remaining last-user paths and independently healthy VM progress need source and native qualification";
  ref part :>> question=cutSource;
 }
 part startupActivationAck:SourceSite {
  attribute :>> id="startupActivationAck";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="static ___SCMOBJ run_startup_root";
  attribute :>> role="handoff-call-boundary";
  attribute :>> observed="Child builds a marker from borrowed cell and releases startup RC custody only on the success branch; TRY cleanup handles the retained owner";
  attribute :>> required="Successful target marker/activation protection precedes parent RC borrow/ref release; unknown partial completion preserves the appropriate holder";
  attribute :>> gap="Complete asynchronous/exception/physical-stop coverage remains unproved; existing local owner variable is not a generic durable query record";
  ref part :>> question=cutSource;
 }

 part packetActivationAckLayout:SourceSite {
  attribute :>> id="packetActivationAckLayout";
  attribute :>> artifact="vendor/gambit/lib/lifecycle.h";
  attribute :>> anchor="typedef struct ___activation_record_struct {";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="The existing activation contains next, owner, marker, roots and kind; lifecycle entries count execution borrows and the active/idle records have owner-confined mutation.";
  attribute :>> required="Extend the existing record with generation, two admission cuts, short readers, exact transfer phase/key and exclusive cleanup reservation. One outstanding transfer per activation, nested calls use separate records. Factor same-source ACK/counter-only loan discharge and guard normal/terminal/reuse paths.";
  attribute :>> gap="Selected layout/commit design only; C implementation, selected backend ordering, complete callers and real-cut native/cost evidence remain open.";
  ref part :>> question=cutSource;
 }

 part packetObserverAtomicOrder:SourceSite {
  attribute :>> id="packetObserverAtomicOrder";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="#define ___WORD_CAS_ACQUIRE(p,expected,v)";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Native GCC ordered-word CAS has acquire success and relaxed failure. Release fetch-add and release-store exist; fallback paths differ. lifecycle_cas delegates to the existing compare-and-swap backend. A macro definition is not a selected-TU backend receipt.";
  attribute :>> required="A checked local observer WORD uses closed bit0 plus two per pin. Admit acquires lifetime; last-use publication releases; close preserves pins with a qualified acq_rel or full RMW; retirement acquires closed-zero. Reuse/extend the same service, never assume acquire-only CAS supplies release. Route pin attempt must not block while registry reader is retained.";
  attribute :>> gap="No actual local observer protocol or selected GCC/C23 TU/mutex backend proof is implemented here. Final close release semantics and all atomic accesses must be qualified together; current source location is not concurrency acceptance.";
  ref part :>> question=cutSource;
 }
}
