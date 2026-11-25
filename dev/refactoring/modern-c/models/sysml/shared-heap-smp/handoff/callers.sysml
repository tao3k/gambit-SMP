/* Model-owned handoff/callers declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpHandoffCallers {
 private import GambitSharedHeapSmp::*;

 part emitRootPrelude:HandoffPoint {
  attribute :>> id="emitRootPrelude";
  attribute :>> caller="_ptree2 c-make-function/root-arguments -> foreign_conversion BEGIN_SFUN_VOID/SCMOBJ/general -> begin_sfun -> SFUN_ROOT_ARG/sfun_arg -> sfun_marker -> conversions/SFUN_ARG -> call_sfun -> END_SFUN/end_sfun -> propagate_error";
  attribute :>> precondition="Caller/source root protection already valid before raw argument access; allocator/lock window is qualified noncollecting and nonreentrant";
  attribute :>> linearization="Enter the parent/source loan before begin_sfun and any raw moving input; after all raw procedure/argument stores succeed commit stable raw-entry-ready before marker/conversion. ACK releases only the matching loan, with physical clearing and scope exit separately guarded; converted values reload canonical cells after any GC.";
  attribute :>> missing="Map every raw proc/argument and generated result/error variant to a protected pre-registration prefix and installed target payload. begin_sfun reaches native metadata allocation/registration before ROOT_ARG; its noncollecting claim still needs selected backend, native-reentry and concurrent-freeze proof. Keep permanent/FAL-closure and moving-procedure branches distinct, without imposing a redundant allocation on the admitted permanent no-argument branch.";
  attribute :>> unknown="Unknown producer/registration result preserves parent and potential target protection; do not infer absence or skip a stale branch";
  attribute :>> acceptance="Actual selected emitter/macro/native consumer identity and all raw/void/result/error parameter variants";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=foreignRootEmitter;
  ref part :>> clause=freezeRoster;
 }
 part enrollTargetSlot:HandoffPoint {
  attribute :>> id="enrollTargetSlot";
  attribute :>> caller="begin_sfun -> alloc_rc_roots -> alloc_rc_no_register/private initialized span -> register_rc/source list -> try_set_data_rc/store_rc_root -> sfun_arg/argument span -> borrow_rc_root -> sfun_marker; startup run_startup_root borrows its launch root separately";
  attribute :>> precondition="Private node and source lifetime held; valid source data authority and incoming root loan";
  attribute :>> linearization="Target source gate commits initialized canonical membership, complete raw-slot readiness and installed revision with durable target lifetime. Registration alone or FAL value is not installed; no partial high-water proof. Release gate before any collecting marker/conversion.";
  attribute :>> missing="No general initialized-root/enrollment observation protocol across all lost returns and partial failure; ordinary synchronous success has bounded support";
  attribute :>> unknown="Keep parent and possible registered target for partial/lost return; lookup uses the preknown exact activation/install key. An uncertain partially initialized span cannot authorize ACK.";
  attribute :>> acceptance="GC-closing/failure/lost-return at private/link/set/ACK cuts; no FAL sentinel and no arbitrary asynchronous kill assumed safe";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=firstRootRegistration;
  ref part :>> clause=freezePublish;
 }
 part reloadSfunArgument:HandoffPoint {
  attribute :>> id="reloadSfunArgument";
  attribute :>> caller="SFUN_ROOT_ARG / SFUN_ARG / END_SFUN macro consumers";
  attribute :>> precondition="Every incoming Scheme-bearing value has qualified source protection; conversion results retain their declared holds";
  attribute :>> linearization="Reload actual registered payload into canonical stack after conversions/any GC; end macros release only after final use";
  attribute :>> missing="Complete selected expansion, caller frame/root span, error scratch and nonlocal exit coverage remains open";
  attribute :>> unknown="Retain installed argument/result roots and marker/entry debt until known last use or owned exceptional transfer";
  attribute :>> acceptance="All NARGS/type/result/error/CFUN variants; frame/liveness consumers, nested callback and actual implementation PBT";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=foreignRootMacros;
  ref part :>> clause=freezeAccess;
 }
 part installMarkerTarget:HandoffPoint {
  attribute :>> id="installMarkerTarget";
  attribute :>> caller="make_sfun_stack_marker[_root] and make_sfun_stack_marker";
  attribute :>> precondition="Preprotected proc/source slot and correct VM/activation entry; all native payload access is admitted";
  attribute :>> linearization="Allocate marker, reload root after potential GC, initialize payload and install record->marker before reporting success";
  attribute :>> missing="Every raw proc/closure-self/immutable/rooted variant and failed/unknown exit has not been unified into whole-source proof";
  attribute :>> unknown="Known failure preserves old source until cleanup; unknown target installation cannot release caller loan by error code alone";
  attribute :>> acceptance="Marker GC/error/nested entry and rooted/raw caller variants under unchanged profiles";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=markerTargetInstall;
  ref part :>> clause=freezePublish;
 }
 part requestResizeWithRoot:HandoffPoint {
  attribute :>> id="requestResizeWithRoot";
  attribute :>> caller="current_vm_resize -> on_all_processors -> optional GC/retry -> return_rc_root/release_rc";
  attribute :>> precondition="Input thunk has parent/source protection until requester RC payload and borrow are installed";
  attribute :>> linearization="Carry stable canonical cell through collective; after complete GC/restore reload cell before uses; release after last synchronous/exceptional use";
  attribute :>> missing="Global borrower parking and acquired reentry/last-use coverage is not established for every counterpart and error branch";
  attribute :>> unknown="Retain request/source/borrow while outcome unknown; never replay completed user work or reuse a copied pre-GC thunk";
  attribute :>> acceptance="Concurrent resize, GC/retry, refusal and exceptional exit using actual original manifests and fixed limits";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=startupBorrowCaller;
  ref part :>> clause=freezeAccess;
 }
 part publishStartupSlot:HandoffPoint {
  attribute :>> id="publishStartupSlot";
  attribute :>> caller="Resize slot root/cell initialization -> setup_pstate -> native launch publication";
  attribute :>> precondition="Requester loan remains valid; native descriptor/source record survives partial setup and allocation failure";
  attribute :>> linearization="Install each RC root and lifetime borrow before any executable child can read it; child admission/launch identity is separate";
  attribute :>> missing="No complete generic lost-install-result, partial-create or changed-generation observation/ACK protocol";
  attribute :>> unknown="Retain slot/root/descriptor according to actual initialization stage; no source release from thread-created status";
  attribute :>> acceptance="Known failure versus uncertain create/join, late start and rollback with exact generation and original budget";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=startupSlotInstall;
  ref part :>> clause=freezeRoster;
 }
 part ackStartupMarker:HandoffPoint {
  attribute :>> id="ackStartupMarker";
  attribute :>> caller="run_startup_root -> rooted marker -> release_startup_activation_root -> call/TRY cleanup";
  attribute :>> precondition="Startup slot loan is held and child has valid data/VM entry; marker rooted by its activation/still lifetime";
  attribute :>> linearization="On known marker success, target protection precedes return_rc_root/release_rc; owner local prevents normal double cleanup";
  attribute :>> missing="Bounded normal path exists; complete source handoff evidence for nested/unknown/nonlocal exits and future observers remains open";
  attribute :>> unknown="If target result unknown retain source/target and activation debt; no inference from slot clearing or owner variable after unsupported interruption";
  attribute :>> acceptance="Real startup multi-shot/GC/error path; known success and failure branches, exact one borrowed-root return";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=startupActivationAck;
  ref part :>> clause=freezeReentry;
 }
 part freezeSourceUnion:HandoffPoint {
  attribute :>> id="freezeSourceUnion";
  attribute :>> caller="root_round_begin/freeze/publish and current source ACK callers";
  attribute :>> precondition="Every writer/borrower has complete root view and closed data access; record and source identities/epochs match";
  attribute :>> linearization="Under each source metadata gate seal view_epoch/view_held and node/slot topology after data-write closure, then publish/claim task authority. Release before traversal; hold frozen source lifetime until actual restore or known pre-copy refusal and scanner last use. Member and coordinator gates never nest.";
  attribute :>> missing="RC phase/cooperative predicate alone does not prove every native or supplemental writer is closed";
  attribute :>> unknown="Unknown stop or publication keeps pins/parent loans and rejects unsafe moving cut; do not merely wait longer";
  attribute :>> acceptance="Configured barrier/mutex acquire-release and complete six-kind plus supplemental source coverage; W<R";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=rootEpoch;
  ref part :>> clause=freezeAccess;
 }
 part sealStillPrefix:HandoffPoint {
  attribute :>> id="sealStillPrefix";
  attribute :>> caller="still_obj_refcount_inc/dec / addref-release_scmobj -> setup_still_objs_to_scan -> scan transport";
  attribute :>> precondition="External count/list/payload producers quiescent or admitted by a proved same-epoch late-work path";
  attribute :>> linearization="Seal selection prefix before consuming count-based strong roots; account every admitted late root and work item";
  attribute :>> missing="Plain count writes and current selection do not implement a general producer-seal/late-work protocol";
  attribute :>> unknown="Keep rooting source and pending work; no raw-pointer resurrection or atomic-count-only closure claim";
  attribute :>> acceptance="All holds/releases/conversion/client cleanup, zero/nonzero selection, weak/will and actual late-operation negative controls";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=stillRootProducer;
  ref part :>> clause=freezeRoster;
 }
 part completeWorkerScan:HandoffPoint {
  attribute :>> id="completeWorkerScan";
  attribute :>> caller="root_task_claim/scan/finish/completed and assigned RootTask consumers";
  attribute :>> precondition="Matching frozen source, task epoch, single scan lease and actual current assigned executor";
  attribute :>> linearization="Worker alone changes progress; DONE returns local lease after canonical root updates";
  attribute :>> missing="Current worker-private API is not a publisher query or a proof all copy/weak/restore work drained";
  attribute :>> unknown="Unknown partial scan keeps task/frontier/copy/source debt; no reset READY or blind destructive replay";
  attribute :>> acceptance="W<R strided assignment, partial progress/failure and canonical root/continuation cases";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=workerCompletionQuery;
  ref part :>> clause=freezeReentry;
 }
 part observeSourceOrigin:HandoffPoint {
  attribute :>> id="observeSourceOrigin";
  attribute :>> caller="Generated parent/startup recovery -> pinned source observer in the existing root service -> installation/query ACK; worker completed/claim/finish remain worker-role operations";
  attribute :>> precondition="Exact VM/source incarnation protected by a route-to-local observer handoff before registry read ends. Actual short source/record pin admitted under its gate; existing accepted-key settlement survives logical owner close. No unpinned record address is dereferenced.";
  attribute :>> linearization="Under bound source gate pin, copy exact installation/task/round scalar observations, end read and drop pin before reply. Distinct facts require matching epochs, not an invented atomic aggregate. Fresh key lookup searches retained active/retiring records; only preprotected direct handles avoid that traversal.";
  attribute :>> missing="Actual local observer admission backend, all guarded task/control writers, checked reader/generation counts, both close cuts and queryable retained installed/ACK records. No existing observer implementation or native C-cut evidence establishes these guarantees.";
  attribute :>> unknown="Unknown retains loan and old-observer pin; no false==absent, executor substitution or record reuse while stale observers exist";
  attribute :>> acceptance="Actual R3 W2 member2 source observed before/after worker0 claim and DONE; no PSTATE impersonation. Include initialized legal FAL, lost install return/ACK, query versus cleanup, source owner exit and next-round reuse; all scan/restore/payload permissions remain distinct. Preserve existing worker-only API negative controls.";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=workerSourceAssignment;
  ref part :>> clause=freezeFailure;
 }
 part resumeSourceAndReload:HandoffPoint {
  attribute :>> id="resumeSourceAndReload";
  attribute :>> caller="reopen_rc_roots -> restored collective -> root_round_end -> binding_context_admit -> payload users";
  attribute :>> precondition="Required scan/copy/Tail/strong/weak/memory work settled; accepted physical restore and current source owner/assignment";
  attribute :>> linearization="Acquire completed root/view revisions before reload and new semantic access; scan executor may differ from reopening owner";
  attribute :>> missing="Normal W<R restoration checks exist; full native borrower and exceptional reentry mapping remains open";
  attribute :>> unknown="Unknown restore keeps source/data permission closed; affine effects retain custody for after owner resume";
  attribute :>> acceptance="All source owners and borrowers, frame/marker/resize GC restoration; no stale copied address or GC/owner callback wait cycle";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=borrowReentry;
  ref part :>> clause=freezeReentry;
 }
 part retireSourceAndQueries:HandoffPoint {
  attribute :>> id="retireSourceAndQueries";
  attribute :>> caller="lifecycle_close_context / rc_prepare_cleanup / cleanup_rc and native last-use callbacks";
  attribute :>> precondition="Known data-write closure and settled payload/borrow/query/initializer debts; supported native stop assumptions";
  attribute :>> linearization="Close new operations while preserving accepted-key settlement. After all keys terminal and their result consumers have consumed or safely abandoned the accepted query right, close final settlement and drain short readers; reserve sole cleanup under source gate, run controlled root/marker/free postlude outside it, then publish known clean IDLE or physical detach. Same-source ACK decision and one counter-only loan discharge commit under parent gate; cross-source durable target capture precedes it and target settlement follows unlocked.";
  attribute :>> missing="No complete arbitrary native-death recovery or source-query last-reader protocol; broader affinity/FFI owners remain necessary";
  attribute :>> unknown="Lost replies after completed unlock query exact recorded key without repeating release. Unknown locked/allocator/cleanup prefix retains all possible holders and reservation; only qualified physical-stop/progress evidence permits takeover. No timeout clears pins or resets generation.";
  attribute :>> acceptance="Real abort/terminal/idle reuse, delayed query, duplicate/stale ACK, partial installation, lost committed replies, next full-GC target coverage, view drain and overflow/exhaustion under R3/W2; no missing-hook pass.";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=lifecycleRootExit;
  ref part :>> clause=freezeFailure;
 }

 part externalClientHandoff:HandoffPoint {
  attribute :>> id="externalClientHandoff";
  attribute :>> caller="Tcl scheme_create_cmd / scheme_call_cmd / scheme_delete_cmd -> Scheme command-payload loader";
  attribute :>> precondition="ClientData RC identity and installation lifetime are held before payload access; each load or release has admitted VM/root/count authority";
  attribute :>> linearization="Construction roots proc before allocation then installs vector; callback pins native identity before entering Scheme and loading payload; deletion drops only owned holds after last use";
  attribute :>> missing="Whole callback/delete/constructor rejection/escape population lacks a unified source/park/strong-hold settlement proof; broader Tcl policy stays separately owned";
  attribute :>> unknown="Keep ClientData node, possible payload/marker, still-hold and callback debt until known root handoff or final release; no deletion means callback physically stopped inference";
  attribute :>> acceptance="Actual constructor success/failure, nested deletion/callback and GC root holds under declared owner; existing implementation PBT and native manifests, no new Tcl cancellation policy";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=externalClientData;
  ref part :>> clause=freezeAccess;
 }
 part bulkStageInstall:HandoffPoint {
  attribute :>> id="bulkStageInstall";
  attribute :>> caller="Candidate alloc_rc_roots/register_rc -> bulk input commit; existing parent source keeps original inputs";
  attribute :>> precondition="Real bulk purpose and parent source roots; initialized fixed count and registered lifetime precede staged input";
  attribute :>> linearization="Input-ready revision is published only after every required root slot is valid; FAL registration alone is not parent ACK";
  attribute :>> missing="Bulk-purpose input store/ready publication and owner validation are absent";
  attribute :>> unknown="Registration/result loss retains original roots and stage owner until exact query settles";
  attribute :>> acceptance="Register/fill/ready failures and lost ACK preserve one operation and no lost source roots";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=typedStagingSource;
  ref part :>> clause=freezeRoster;
 }
 part bulkStageCloseWrites:HandoffPoint {
  attribute :>> id="bulkStageCloseWrites";
  attribute :>> caller="Candidate bulk stage/destination span close -> existing root_task_publish";
  attribute :>> precondition="Known scan-valid stage and destination, closed new writes, all prior physical writers drained";
  attribute :>> linearization="Existing RC freeze publication consumes bulk closure before READY; release/acquire accompanies qualified source exclusion";
  attribute :>> missing="No active bulk span integration exists in source publication";
  attribute :>> unknown="Unknown writer retains affected source/destination, rooted input and operation; do not sign stopped";
  attribute :>> acceptance="Race late source/destination writes, stale helper and freeze; lock must not be held while waiting for GC";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkStageFreeze;
  ref part :>> clause=freezePublish;
 }
 part bulkStageScan:HandoffPoint {
  attribute :>> id="bulkStageScan";
  attribute :>> caller="Existing mark_rc -> future bulk source/destination/staging consumer";
  attribute :>> precondition="Matching frozen task/epoch/executor and scan-valid fixed payload; physical write access stopped";
  attribute :>> linearization="Scanner repairs every typed root and publishes only local scan progress";
  attribute :>> missing="RC scanner exists; destination torn-slot repair and bulk readiness premises are unimplemented";
  attribute :>> unknown="Partial scan keeps the existing scan/copy/source debt and rooted stage, never reset progress blindly";
  attribute :>> acceptance="Move source/destination and stage referents after ready; wrong task or incomplete input must refuse scan";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=rootScan;
  ref part :>> clause=freezePublish;
 }
 part bulkStageObserve:HandoffPoint {
  attribute :>> id="bulkStageObserve";
  attribute :>> caller="Proposed lifecycle_bulk_query(held operation/query ref, value key, native observation_out); new lost-result recovery caller at prepare/install/ACK/exit, absent from current runtime";
  attribute :>> precondition="Control/VM and operation/query lifetime held before any dereference; exact incarnation/attempt/revision; status output is native metadata only, not Scheme/root payload";
  attribute :>> linearization="COMMITTED query means consistent snapshot only; observation target/effect/ACK fields may still be UNKNOWN or partial. STALE grants nothing and never establishes absence Registration status comes from actual qualified completion/ownership, never domain zero, same-domain repeat success, linked shape or debug allocation counts; inaccessible or uncertain native lock/output remains UNKNOWN. Lost reply after published witness can query the same completion; loss before witness publication remains UNKNOWN. Query cannot reconstruct missing registration from header/list/debug counters or normalize a lock/allocator interruption.";
  attribute :>> missing="No lifecycle_bulk_query(held_ref,key,observation_out) exists; proposed status vocabulary cannot infer absence or grant payload access";
  attribute :>> unknown="Unknown remains retained; no false-as-absent, blind overlap replay or storage reuse";
  attribute :>> acceptance="Lose replies before and after metadata publication; repeat exact pinned query without replay. A delayed stale helper must fail before payload access, including after IDLE reuse";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkStageUnlink;
  ref part :>> clause=freezeFailure;
 }
 part bulkStageResume:HandoffPoint {
  attribute :>> id="bulkStageResume";
  attribute :>> caller="Candidate GC-only park -> existing reopen_rc_roots/whole-round restore -> bulk reload";
  attribute :>> precondition="Whole round and physical restoration complete, operation outcome settled or explicitly retained; current authorized source owner";
  attribute :>> linearization="Acquire refreshed source epoch and canonical source/destination/stage values before deriving addresses for next span";
  attribute :>> missing="No GC-only bulk continuation adapter or bulk-purpose reopen exists";
  attribute :>> unknown="No stale physical pointer or shared completed cursor may authorize a new Scheme shot";
  attribute :>> acceptance="GC-only park resumes same call; real map restoration preserves aliases; unsupported callback/capture in native span refuses admission";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=borrowReentry;
  ref part :>> clause=freezeReentry;
 }
 part bulkStageRetire:HandoffPoint {
  attribute :>> id="bulkStageRetire";
  attribute :>> caller="Proposed lifecycle_bulk_settle_exit(actual executor, held operation ref, exit_reason); insertion at lifecycle_close_context plus cleanup_pstate, resize rollback/shrink and final VM cleanup callers";
  attribute :>> precondition="Exact outcome/root ownership and known physical writers/helpers stopped; effect affinity and C return eligibility; target coverage if transferred; ordinary OPEN or explicit exclusive maintenance authority for clearing Classify prepared private/registered ownership, accepted bank loan, marker still reference, lifecycle entry and external query/helper obligations separately; no duplicated decrement or treating REVOKED as physical stop. Any offer to current idle_activation reuse slot requires no prepared allocation, unresolved registration/intent/reply, stale query/helper or return-affinity debt, in addition to clean old fields.";
  attribute :>> linearization="COMMITTED grants only the stated exit/retirement postcondition after clearing and last use; IN_PROGRESS/UNKNOWN retain custodian. Neither generic activation abort nor rc_can_close may bypass staged effect/query debt";
  attribute :>> missing="Generic terminal activation cleanup does not implement this dispatch";
  attribute :>> unknown="Pending effect or late native user transfers explicit VM custody or keeps source/PSTATE dependencies retained REGISTERING/unknown output is not released via the domain-zero private branch; no return_rc_root before actual loan acquisition; ambiguous node/count/gate state remains retained.";
  attribute :>> acceptance="Prewrite abort, already committed unknown return, cancel after partial write and terminal cleanup must not lose or duplicate effects";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkStageCloseGuard;
  ref part :>> clause=freezeFailure;
 }

 part bulkParkEffectBoundary:HandoffPoint {
  attribute :>> id="bulkParkEffectBoundary";
  attribute :>> caller="Proposed execute_sync_op_core(current ps, ___sync_op_struct *borrowed_sop, ___BOOL first_iter, rooted outcome_sink); real callers service_sync_op/on_all_processors pass 1, start_processor_execution passes 0";
  attribute :>> precondition="Actual current ps and member/lifecycle authority; full frame and held bulk operation; borrowed sop cannot outlive its stack; pending-value sink rooted before later GC; physical spans closed and no source lock held";
  attribute :>> linearization="COMMITTED means exact core request/restore outcome published, not effects delivered. Preserve first_iter interrupt-reset behavior, all collective participation and on_all_processors TRY/request decrement before rethrow";
  attribute :>> missing="Actual dispatcher/effect split, deferred-error roots and no new callback/capture semantics are absent";
  attribute :>> unknown="Uncertain effect or collective outcome retains operation/roots and prevents unqualified raw resume";
  attribute :>> acceptance="Combined GC/resize and pending hooks/cleanup must neither invoke effects midcopy nor skip collective participation";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkSyncDispatch;
  ref part :>> clause=freezeReentry;
 }
 part bulkVmRootInstall:HandoffPoint {
  attribute :>> id="bulkVmRootInstall";
  attribute :>> caller="Candidate lifecycle_bulk_prepare/install/query/ack private handlers: one held target intent -> actual surviving RC source -> continuous coverage -> source ACK";
  attribute :>> precondition="Old data writers stopped, both source lifetimes held, target owner admitted; current roster is not being mutated mid-round";
  attribute :>> linearization="Independent target span has installed canonical endpoint/input roots and live operation/query owner; future round includes it before original ACK";
  attribute :>> missing="No qualified root-copy/query/ACK service; register_rc cannot reparent old block and active roster excludes orphan domains";
  attribute :>> unknown="Target failure or lost ACK retains original and possible target roots; no owner/PSTATE cleanup from metadata ownership alone";
  attribute :>> acceptance="Test refusal/unknown target, next-round scan, no double effects and unchanged root identity through target movement";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkRootTransferGuard;
  ref part :>> clause=freezeFailure;
 }
 part bulkDeliverDeferredEffects:HandoffPoint {
  attribute :>> id="bulkDeliverDeferredEffects";
  attribute :>> caller="Proposed deliver_sync_postlude(current ps, held outcome, operation ref) from ordinary sync wrapper or bulk semantic completion; actual consumers lifecycle_drain and Scheme interrupt delivery";
  attribute :>> precondition="Recipient/affinity exact, rooted outcome and known operation lifetime, restored memory and permitted effect boundary; no raw body span or held source lock";
  attribute :>> linearization="Postlude result separately records pending/inflight/uncertain/settled; nested drain true and cleared FOREIGN fields do not mean COMMITTED effect. Ordinary cleanup-before-designated-throw behavior remains";
  attribute :>> missing="No bulk-purpose effect-safe completion dispatch or general unknown callback recovery is implemented";
  attribute :>> unknown="Effect outcome unknown remains owned; a destructor/callback is never replayed as internal idempotent work";
  attribute :>> acceptance="Nested callback/GC/exception and owner exit retain exact resources/winding; no suppression of pending interrupts";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkOwnerEffectDispatch;
  ref part :>> clause=freezeFailure;
 }

 part bulkCollectiveOutcome:HandoffPoint {
  attribute :>> id="bulkCollectiveOutcome";
  attribute :>> caller="Startup error producer / execute_sync_op_loop request result -> candidate deferred core outcome";
  attribute :>> precondition="Exact request/VM incarnation and complete pre-reserved roots or proved nonmoving pending error; physical spans closed";
  attribute :>> linearization="Record memory/request completion independently of first pending error and cleanup status, retaining existing designated delivery ordering";
  attribute :>> missing="No bulk-specific bounded outcome record/query or effect-restricted postlude exists";
  attribute :>> unknown="Lost return retains first error/result roots and possible request completion; never rerun effectful collective from unknown";
  attribute :>> acceptance="Two pending errors plus cleanup failure/nesting and lost ACK distinguish request completion, memory resume and actual effect delivery";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkCoreOutcome;
  ref part :>> clause=freezeFailure;
 }
 part bulkCleanupObserve:HandoffPoint {
  attribute :>> id="bulkCleanupObserve";
  attribute :>> caller="lifecycle_defer -> lifecycle_drain -> release_foreign -> retained inflight result";
  attribute :>> precondition="Actual effect owner, original callback/payload and lifetime known; compatible semantic boundary and no raw bulk span";
  attribute :>> linearization="Publish known callback outcome separately from pre-invocation field clearing and nested-drain observation";
  attribute :>> missing="No general recovery for unknown native side effects; ignored drain boolean is not a completion attestation";
  attribute :>> unknown="Keep original inflight/callback/opaque payload state uncertain; do not retry from either cleared shell or saved callback";
  attribute :>> acceptance="Known success/error, nonlocal escape and nested GC preserve one effect and exact root/resource responsibility";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkForeignInvocation;
  ref part :>> clause=freezeFailure;
 }
 part bulkTargetNextScan:HandoffPoint {
  attribute :>> id="bulkTargetNextScan";
  attribute :>> caller="Between-round target installation/ACK -> root_round_begin/freeze/publish/scan -> mark_rc";
  attribute :>> precondition="Complete target slots and operation lifetime, actual surviving source/roster member, protected membership before original source release";
  attribute :>> linearization="Next round scans and rewrites target under assigned worker; install ACK relies on continuous coverage, not future scan DONE";
  attribute :>> missing="Target root-copy/admission/query/ACK and source/target retirement exclusion are not implemented";
  attribute :>> unknown="Target existence/coverage unknown retains original and possible target roots, all late writer and query dependencies";
  attribute :>> acceptance="Race install and retire against roster freeze; defer ACK if sealed round lacks coverage. No intervening GC before ACK and physical owner exit; target index >= W in next W<R round must be claimed/scanned/finished by strided worker; reload moved target slots and resume map twice";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkTargetScanChain;
  ref part :>> clause=freezePublish;
 }

 part bulkPurposeWrite:HandoffPoint {
  attribute :>> id="bulkPurposeWrite";
  attribute :>> caller="Generalize existing private store_rc_root(___processor_state,void*,___SIZE_T,___SCMOBJ,real purpose record); existing callers ___sfun_arg and ___store_rc_root remain actual legacy result adapters";
  attribute :>> precondition="Real current ps/domain and SFUN or BULK owner, exact span/key and fixed valid index; rooted value in noncollecting span; zero primary index and positive payload indices retain separate checks";
  attribute :>> linearization="COMMITTED is a known single slot store or admitted same-value no-op. Legacy BOOL/SFUN error code maps only known return outcomes; a nonlocal unknown write is retained by bulk operation, never silently projected to false/refusal";
  attribute :>> missing="No real BULK branch or purpose-aware positive-index authority exists; SFUN admission must remain intact";
  attribute :>> unknown="Wrong/stale purpose refuses before this store; native interruption with unknown store retains span/root/repair debt";
  attribute :>> acceptance="Wrong purpose, root pointer, source, epoch/index and GC-close races cannot bypass checks; successful slot write alone cannot ACK target";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=rcReferenceStore;
  ref part :>> clause=freezeAccess;
 }
 part bulkTargetPrepare:HandoffPoint {
  attribute :>> id="bulkTargetPrepare";
  attribute :>> caller="Proposed lifecycle_bulk_prepare(actual target ps, held operation ref, value key, ___SIZE_T checked count); source allocator currently called by begin_sfun and has no bulk caller yet";
  attribute :>> precondition="One prepublished intent with VM/operation and target lifetimes; checked count equals fixed declared layout; target current owner, no locks over allocation, original roots held Owned_out is a typed allocation-status sink, separate from record->roots until any required root loan is known accepted; partial registration cannot enter generic abort/release. Registration starts from a known fresh unlinked private output or consumes an already known complete witness for this same attempt; re-registering an UNKNOWN attempt cannot manufacture completion.";
  attribute :>> linearization="Issue embedded registration/adoption witness only after the same attempt has a qualified normal register_rc return, usable released source exclusion, captured/adopted output and any required accepted loan. Then publish PREPARED under the metadata guard/release discipline. Ordinary prewrite refusal stays known; interior native/return-to-publication loss without witness stays UNKNOWN.";
  attribute :>> missing="No bulk target service or common owned_out adoption seam exists. Proposed private alloc_rc_roots sink requires rc.h/current begin_sfun caller migration and keeps native result-loss/partial registration windows UNKNOWN when no witness exists";
  attribute :>> unknown="Lost allocation result remains UNKNOWN; no second possible target or false known absence";
  attribute :>> acceptance="Allocation/register failure, lost result before owned pointer publication and repeated prepare preserve original roots and one attempt";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=typedStagingSource;
  ref part :>> clause=freezeRoster;
 }
 part bulkTargetInstall:HandoffPoint {
  attribute :>> id="bulkTargetInstall";
  attribute :>> caller="Proposed lifecycle_bulk_install(actual target ps, held operation ref, value key, qualified canonical source_view); planned bulk writer/retiring-owner adapter, no existing C call site";
  attribute :>> precondition="Source_view has held source lifetime, known data closure and canonical fixed ranges/counts; target purpose/key/current owner valid; both sources at qualified cut, not raw pre-GC slot addresses Known registration witness and explicit allocation owner/accepted-loan facts precede filling target; no assignment to accepted roots before a loan is actually acquired.";
  attribute :>> linearization="IN_PROGRESS identifies valid partial prefix and retained source; COMMITTED only after all endpoint/input/error slots and exact revision are published. Relocation rewrites addresses without changing input revision";
  attribute :>> missing="Cross-source read maintenance, target-purpose writes and atomic complete-payload publication are absent";
  attribute :>> unknown="Partial target remains owned and scannable if valid; original roots stay authoritative; no destructive overlap/effect retry";
  attribute :>> acceptance="Partial fill, source/target movement, late writer and lost commit must not issue complete installation early";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkRootTransferGuard;
  ref part :>> clause=freezePublish;
 }
 part bulkTargetAck:HandoffPoint {
  attribute :>> id="bulkTargetAck";
  attribute :>> caller="Proposed lifecycle_bulk_ack(admitted source ps or explicit stopped-source maintenance authority, held operation ref, key, target_commit observation); planned owner-exit handoff consumer, absent from runtime";
  attribute :>> precondition="Known exact installed target revision, protected live target membership and all-prefix coverage; old data closure and original root/query lifetimes; no fabricated current PSTATE Target native allocation, full registration, adopted owner/reference and required loan are known complete; list membership and payload equality alone are insufficient.";
  attribute :>> linearization="COMMITTED records idempotent ACK, not source clearing/free. Unknown/lost response keeps original and possible target; original owner can exit before next actual GC only after separate source-removal and native last-use guards Return means the target obligation is recorded for the exact installed revision; future scan coverage must follow from stable admitted target lifetime, not a stale registration-round equality or marker revocation.";
  attribute :>> missing="No actual stable commit/ACK/last-user adapter exists; original registration cannot act as ACK";
  attribute :>> unknown="Unknown ACK keeps original and possible target roots until query settles; stale key grants nothing";
  attribute :>> acceptance="Install under target membership/freeze exclusion; close and drain writers before certifying exact revision. ACK then physical original owner exit before next W<R GC; duplicate ACK repeats no effects; target retirement preserves coverage";
  ref part :>> protocol=rootHandoff;
  ref part :>> site=bulkRootTransferGuard;
  ref part :>> clause=freezeFailure;
 }
}
