/* Same-wait settlement source adapter; QNT/Lean responsibilities unchanged. */
package GambitSharedHeapSmpCompletionSettlement {
 private import GambitSharedHeapSmp::*;
 part settlementParkEmission:SourceSite {
  attribute :>> id="settlementParkEmission";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-jump-inline \"##thread-park!\"";
  attribute :>> role="request-service-design";
  attribute :>> observed="Park/restore lowering runs end-of-block checks and adjusts stack before emitted root macros.";
  attribute :>> required="Make all selected source/destination/conversion operands semantically live before checks, reload repaired roots and preserve exact normal/RETI maps.";
  attribute :>> gap="No typed post-registration conversion/query lowering exists.";
  ref part :>> question=cutSource;
 }
 part settlementGeneratedResume:SourceSite {
  attribute :>> id="settlementGeneratedResume";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="___DEF_GLBL(___L4__23__23_mutex_2d_wait_21_)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Generated wait allocates five-field closure, checks heap and selects register versus PARK2 from closure fields.";
  attribute :>> required="Measure original allocation and late replacement independently of first registration/repark; regenerate same-cohort C for implementation acceptance.";
  attribute :>> gap="Checked generated text is not a new producer/native receipt.";
  ref part :>> question=cutSource;
 }
 part settlementRootPark:SourceSite {
  attribute :>> id="settlementRootPark";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___THREAD_PARK";
  attribute :>> role="request-service-design";
  attribute :>> observed="Park writes break.next and Thread.cont.frame then invokes callback; neither root store is wait-registration commit.";
  attribute :>> required="Retain complete source/destination roots through real source freeze; publish executable conversion only after roots and same-wait authority.";
  attribute :>> gap="No same-wait receipt/query is supplied by existing macro stores.";
  ref part :>> question=cutSource;
 }
 part settlementRootRestore:SourceSite {
  attribute :>> id="settlementRootRestore";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___THREAD_RESTORE";
  attribute :>> role="request-service-design";
  attribute :>> observed="Restore transfers Thread.cont.frame to break.next then clears original frame field.";
  attribute :>> required="ACK target must bind repaired active/break/captured ancestry and survive next roster, not depend on the cleared wrapper.";
  attribute :>> gap="No conversion ACK or last-user proof follows from restore macro.";
  ref part :>> question=cutSource;
 }
 part settlementWakeOutcome:SourceSite {
  attribute :>> id="settlementWakeOutcome";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##mutex-unlock-out-of-line! mutex first-thread)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Wake removes queues, sets actual ownership or abandonment and fixed resume outcome, then publishes runnable Thread.";
  attribute :>> required="Conversion revalidates same physical wait and selected outcome under existing locks; no replay/overwriting grant with stale retry.";
  attribute :>> gap="Current registration fields have no atomic conversion receipt/query.";
  ref part :>> question=cutSource;
 }
 part settlementCachedAction:SourceSite {
  attribute :>> id="settlementCachedAction";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-resume-execution!)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Dispatcher caches resume-thunk before draining arbitrary interrupts and invokes cached local afterward.";
  attribute :>> required="Cover the cached action as actual rooted last user and preserve invocation/outcome semantics through conversion, reflection and GC.";
  attribute :>> gap="Changing Thread.resume-thunk alone does not revoke local alias or prove old graph retirement.";
  ref part :>> question=cutSource;
 }
 part settlementStackSource:SourceSite {
  attribute :>> id="settlementStackSource";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___BOOL ___root_task_scan_stack";
  attribute :>> role="request-service-design";
  attribute :>> observed="Stack task scans task.origin.source.stack active/break/captured ancestry under its scan lease.";
  attribute :>> required="After ACK owner exit target binding must survive every next W<R source roster and canonical repair; scanner completion is not resume/retirement permit.";
  attribute :>> gap="No native end-to-end conversion/next-round source coverage exists.";
  ref part :>> question=cutSource;
 }
 part settlementRcSource:SourceSite {
  attribute :>> id="settlementRcSource";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-roots.inc";
  attribute :>> anchor="___HIDDEN ___BOOL mark_rc";
  attribute :>> role="request-service-design";
  attribute :>> observed="Frozen RC scan visits h.data and all root_count payload words under source gate/lease.";
  attribute :>> required="If native conversion/query needs root handles, actually register writer/freeze/exit-safe canonical homes; a raw SCM metadata field is not a root.";
  attribute :>> gap="A lifetime pin protects record storage, not moving pointer stability or write permission.";
  ref part :>> question=cutSource;
 }
 part settlementThreadExit:SourceSite {
  attribute :>> id="settlementThreadExit";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-end! thread exception? result)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Thread end removes queues, clears continuation/denv/cache, and does not establish death of user-captured frames or cached action.";
  attribute :>> required="Retain unresolved source/destination and query records with existing VM/source custody until actual last users/writers drain; fresh user shot needs fresh physical authority.";
  attribute :>> gap="No current conversion exit/reader retirement implementation is qualified.";
  ref part :>> question=cutSource;
 }
 part completionSettlementCoverage:AdapterClause {
  attribute :>> id="completionSettlementCoverage";
  attribute :>> kind="coverage";
  attribute :>> rule="Complete source/destination/selected operands, active/captured/cached/RC homes and edge maps precede checks/freeze";
  attribute :>> missing="No typed lowering or complete source adaptation";
  attribute :>> acceptance="Independent slot oracle before freeze/after repair at W<R, including cleared Thread.cont";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementParkEmission;
 }
 part completionSettlementExclude:AdapterClause {
  attribute :>> id="completionSettlementExclude";
  attribute :>> kind="exclusion";
  attribute :>> rule="Bounded commit revalidates same shot/wait/outcome; no allocation/hooks/queue reinsertion or reversed source/queue lock order";
  attribute :>> missing="No converted writer/exclusion protocol";
  attribute :>> acceptance="Race grant, reflection and cached action through commit without replay or changed selected outcome";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementWakeOutcome;
 }
 part completionSettlementPublish:AdapterClause {
  attribute :>> id="completionSettlementPublish";
  attribute :>> kind="publication";
  attribute :>> rule="Complete GC-visible destination precedes execution authority and immutable receipt; ACK releases only transfer hold";
  attribute :>> missing="No actual same-wait publication/query/ACK implementation";
  attribute :>> acceptance="Lose all responses and scan both graphs; query never executes wait or creates second registration";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementRootPark;
 }
 part completionSettlementReenter:AdapterClause {
  attribute :>> id="completionSettlementReenter";
  attribute :>> kind="reentry";
  attribute :>> rule="Within-shot query/retry uses original claim; new user shot gets fresh physical authority with same specified logical sharing";
  attribute :>> missing="No multi-shot transfer/metadata and post-ACK next-round adapter";
  attribute :>> acceptance="Two restores across GC plus no new writes and owner exit; do not reuse captured physical token";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementRootRestore;
 }
 part completionSettlementFailure:AdapterClause {
  attribute :>> id="completionSettlementFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Unknown partial transfer remains source/VM-owned and queryable until closed writers and last readers; generation cannot wrap with old users";
  attribute :>> missing="No exit/query pin/slot retirement implementation";
  attribute :>> acceptance="Lost ACK, stale query, cached reader, owner exit and exhausted reserve preserve custody without changing budgets";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementThreadExit;
 }
 part completionSettlementValidate:AdapterClause {
  attribute :>> id="completionSettlementValidate";
  attribute :>> kind="validation";
  attribute :>> rule="Reconcile E=G+A and A=Q_closed+L+P; count equivalent facade allocations, actual frame/root deltas and censored lifetimes";
  attribute :>> missing="No actual alpha/elimination or native cost observations";
  attribute :>> acceptance="Real generated cuts plus independent completion/queue/slot controls, counter overflow invalidation and no-probe paired timing";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementGeneratedResume;
 }
 part completionSettlementRefinement:SourceCase {
  attribute :>> id="completionSettlementRefinement";
  attribute :>> precondition="Bound source/module/FrameSpec and selected synchronization backend; complete source/destination homes and preinstalled stable lookup; actual wait/outcome authority and bounded records";
  attribute :>> argument="Prepared destination is rooted before execution authority changes under original wait locks. Commit revalidates same registration/outcome; immutable conversion receipt is distinct from later physical outcome/version, and lost response queries original resident identity without grant authority. Restore moves roots to break ancestry and ACK drops transfer hold only. Captured/cached/query aliases and next-roster roots survive until actual last use; fresh user shots instantiate new physical authority without changing logical sharing. Unknown work remains source/VM-owned. Independent cuts reconcile actual eliminated versus pending/materialized entries and all new frame/root work.";
  attribute :>> conclusion="One whole same-wait conversion, query/ACK, next-round and observation implementation boundary is specified; not a proof of current C or native benefit";
  attribute :>> missing="Joint generated conversion, outcome/cached-action adapter, source publication, query/ACK, pin retirement and full native observations absent";
  attribute :>> acceptance="Five-gate campaign at real C cuts: lose each return, race grant/escape/GC, restore twice, exit after ACK and retain last reader; reconcile populations and no-probe paired cost under original limits";
  attribute :>> formalBoundary="Existing QNT exclusively owns partial commit/lost reply/last-use histories; existing Lean exclusively owns slot/alias/representation/interval laws. Source mapping does not duplicate either proof.";
  attribute :>> counterexample="ACK uses cleared Thread.cont; converter overwrites fixed grant; cached resume closure survives Thread update; second shot reuses physical token; Q includes still-live unobserved aliases; lost query interpreted as rollback";
  ref part :>> clause=completionSettlementPublish; ref part :>> entrySite=settlementParkEmission; ref part :>> exitSite=settlementThreadExit;
 }
 part completionSettlementFlow0:Flow { ref part :>> producer=control; ref part :>> consumer=roots; attribute :>> contract="Repair9: same-wait conversion publishes complete rooted destination before execution/receipt/ACK"; }
 part completionSettlementFlow1:Flow { ref part :>> producer=roots; ref part :>> consumer=collector; attribute :>> contract="Repair9: restore moves canonical roots to active/break ancestry; next W<R roster survives source exit"; }
 part completionSettlementFlow2:Flow { ref part :>> producer=messages; ref part :>> consumer=retirement; attribute :>> contract="Repair9: outcome and cached action are last users; ACK is not complete captured-graph retirement"; }
 part completionSettlementFlow3:Flow { ref part :>> producer=execution; ref part :>> consumer=control; attribute :>> contract="Repair9: query deduplicates within shot, never user multi-shot invocation; closed/materialized/pending alpha populations remain separate"; }
 part settleWaitInstall:HandoffPoint {
  attribute :>> id="settleWaitInstall";
  attribute :>> caller="typed S/generic producer -> THREAD_PARK root homes -> same-registration conversion commit";
  attribute :>> precondition="Preknown same-wait/shot/VM key, complete source and destination root homes, current physical registration and selected outcome authority";
  attribute :>> linearization="Complete target root install precedes authority commit and matching ACK; root stores alone are not queue commit";
  attribute :>> missing="No generated S destination publication/installation receipt exists";
  attribute :>> unknown="Lost install return retains both homes; query uses the preknown key, not an unreceived returned generation, and never repeats registration";
  attribute :>> acceptance="Install while GC closes and while grant wins; no duplicate wait";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementRootPark; ref part :>> clause=completionSettlementPublish;
 }
 part settleWaitInstallUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="parent-ack"; attribute :>> condition="Only with same wait/shot/source scope and Preknown same-wait/shot/VM key, complete source and destination root homes, current physical registration and selected outcome authority; current missing adapter stays OPEN"; ref part :>> point=settleWaitInstall; ref part :>> receipt=installedRoot; }
 part settleWaitAccess:HandoffPoint {
  attribute :>> id="settleWaitAccess";
  attribute :>> caller="GVM operand maps -> check/adjust -> typed decode -> park/restore macro";
  attribute :>> precondition="Complete caller/selected operands and exact epoch permissions";
  attribute :>> linearization="Close raw accesses at a complete collecting checkpoint; keep canonical lifetime roots";
  attribute :>> missing="No typed corridor/checkpoint or raw access-stop adapter exists";
  attribute :>> unknown="Unknown access closure retains data authority debt and excludes unsafe move";
  attribute :>> acceptance="Collect before decode and during preparation; every saved register/root repaired";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementParkEmission; ref part :>> clause=completionSettlementExclude;
 }
 part settleWaitAccessUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="access-stopped"; attribute :>> condition="Only with same wait/shot/source scope and Complete caller/selected operands and exact epoch permissions; current missing adapter stays OPEN"; ref part :>> point=settleWaitAccess; ref part :>> receipt=parkedBorrow; }
 part settleWaitProducers:HandoffPoint {
  attribute :>> id="settleWaitProducers";
  attribute :>> caller="mutex-wait-register!/wake outcome -> source freeze -> restored wait owner";
  attribute :>> precondition="Same wait/shot and explicit producer population for this collection cut";
  attribute :>> linearization="All admitted root/action writes for this cut precede freeze; late work retains an admitted owned source";
  attribute :>> missing="All writer/freeze ordering and selected atomic backend not qualified";
  attribute :>> unknown="Unknown writer close retains its source/work; no fabricated global stop";
  attribute :>> acceptance="Race final action publication, registration and freeze without changing scheduling policy";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementWakeOutcome; ref part :>> clause=completionSettlementExclude;
 }
 part settleWaitProducersUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="producer-closed"; attribute :>> condition="Only with same wait/shot/source scope and Same wait/shot and explicit producer population for this collection cut; current missing adapter stays OPEN"; ref part :>> point=settleWaitProducers; ref part :>> receipt=sealedProducers; }
 part settleWaitScan:HandoffPoint {
  attribute :>> id="settleWaitScan";
  attribute :>> caller="RootTask source stack plus registered RC/native homes -> scan/repair";
  attribute :>> precondition="Matching source/epoch/task lease and current assigned worker";
  attribute :>> linearization="Complete local canonical scan under actual frozen source; progress is not ACK/resume";
  attribute :>> missing="No native conversion destination scan or independent slot-oracle evidence";
  attribute :>> unknown="Partial scan stays task/source-owned until authorized continuation";
  attribute :>> acceptance="R3 W2 member2 source scanned by worker0; missing cache/RC home negative";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementStackSource; ref part :>> clause=completionSettlementCoverage;
 }
 part settleWaitScanUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="scan-status"; attribute :>> condition="Only with same wait/shot/source scope and Matching source/epoch/task lease and current assigned worker; current missing adapter stays OPEN"; ref part :>> point=settleWaitScan; ref part :>> receipt=scanProgress; }
 part settleWaitObserve:HandoffPoint {
  attribute :>> id="settleWaitObserve";
  attribute :>> caller="cached action/registration recovery -> resident same-wait query -> receipt/ACK observation";
  attribute :>> precondition="Stable preknown lookup identity and admitted storage pin; root handles cover SCM results";
  attribute :>> linearization="Acquire a consistent status/receipt under the existing authority; SCM payloads need GC-visible handles and repaired reload. Query executes no wait, service, resume closure or resolver";
  attribute :>> missing="No same-wait resident query/pin/generation or lost-response implementation";
  attribute :>> unknown="Missing/unknown record is not absent; retain pending root and query debt";
  attribute :>> acceptance="Lose commit/query/ACK responses and hold cached local alias across interrupts";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementCachedAction; ref part :>> clause=completionSettlementFailure;
 }
 part settleWaitObserveUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="observe-origin"; attribute :>> condition="Only with same wait/shot/source scope and Stable preknown lookup identity and admitted storage pin; root handles cover SCM results; current missing adapter stays OPEN"; ref part :>> point=settleWaitObserve; ref part :>> receipt=originObservation; }
 part settleWaitResume:HandoffPoint {
  attribute :>> id="settleWaitResume";
  attribute :>> caller="actual GC restoration -> THREAD_RESTORE break.next -> user/static/generic landing";
  attribute :>> precondition="Whole applicable round restored; same-shot recovery retains the original registration and selected outcome, while a new user shot receives fresh physical authority";
  attribute :>> linearization="Acquire repaired target and decode current ancestry after restore, not cleared Thread.cont";
  attribute :>> missing="No exact S/generic resume and two-shot adapter exists";
  attribute :>> unknown="Unknown restoration keeps execution permission closed and roots owned";
  attribute :>> acceptance="Two restores across GC, ACK then owner exit and next W<R roster";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementRootRestore; ref part :>> clause=completionSettlementReenter;
 }
 part settleWaitResumeUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="reload-after-resume"; attribute :>> condition="Only with same wait/shot/source scope and Whole applicable round restored; same-shot recovery retains the original registration and selected outcome, while a new user shot receives fresh physical authority; current missing adapter stays OPEN"; ref part :>> point=settleWaitResume; ref part :>> receipt=roundResume; }
 part settleWaitRetire:HandoffPoint {
  attribute :>> id="settleWaitRetire";
  attribute :>> caller="Thread exit/cached action last use/query pin release -> VM custody -> record reuse";
  attribute :>> precondition="Closed writers, settled accepted keys and actual last readers; target roots survive future cuts";
  attribute :>> linearization="Drop transfer hold only after matching ACK; record reuse only after all record users drain";
  attribute :>> missing="No complete same-wait source-exit/query/cached-action drain protocol";
  attribute :>> unknown="Unknown exit/last use retains source or VM custody; ACK drops only transfer hold, never cached alias, result root, code pin or final-reader duty";
  attribute :>> acceptance="Retain final query reader/captured alias, reject stale generation and prove one authorized release";
  ref part :>> protocol=rootHandoff; ref part :>> site=settlementThreadExit; ref part :>> clause=completionSettlementFailure;
 }
 part settleWaitRetireUse:HandoffUse { attribute :>> role="requires"; attribute :>> purpose="retire-storage"; attribute :>> condition="Only with same wait/shot/source scope and Closed writers, settled accepted keys and actual last readers; target roots survive future cuts; current missing adapter stays OPEN"; ref part :>> point=settleWaitRetire; ref part :>> receipt=sourceRetired; }
 part settlementNativeBridge:SourceSite {
  attribute :>> id="settlementNativeBridge";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-transfer.scm";
  attribute :>> anchor="(define (transfer-trial commands fault?)";
  attribute :>> role="request-service-design";
  attribute :>> observed="DEV overlay on verified cached GCC/C23 producer passes one real blocked wait/interrupted callback, actual RC roots across two GC calls, lost committed/ACK response queries and last-reader-controlled release. Eight stateful histories compare all phases and shrink omitted-reader negative to commit/ACK/retire.";
  attribute :>> required="Keep test-owned record separate from production S/registration conversion; native snapshots and exact producer/flags/stdout are bound in completion-wait-transfer-native.json.";
  attribute :>> gap="No S emitter, production queue conversion, same-transferred-continuation multi-shot or original-load alpha/cost evidence; cached-action hold is conservative through actual worker join, not a new production stop receipt.";
  ref part :>> question=cutSource;
 }
 part settlementNativeRecord:SourceSite {
  attribute :>> id="settlementNativeRecord";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-transfer.h";
  attribute :>> anchor="static int wait_transfer_ack(int generation, int lost)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Native test record uses actual alloc_rc/try_set_data_rc/release_rc source and target, generation-checked query and idempotent ACK/retire; calls run on controller outside GC while ordinary Thread/callback can stay alive.";
  attribute :>> required="Validate native controlled graph/record behavior without promoting serial test calls to C concurrent authority proof. Generation bound matches int API.";
  attribute :>> gap="Test-owned state/reader hold does not implement all actual root writers, source-freeze admission, lost partial-store recovery or scheduler grant arbitration.";
  ref part :>> question=cutSource;
 }
 part completionNativeBridgeFlow:Flow { ref part :>> producer=roots; ref part :>> consumer=retirement; attribute :>> contract="Repair9: actual RC/full-GC/wait DEV bridge validates controlled query/ACK and reader exclusion; production S/queue authority and native whole-gate evidence stay OPEN"; }
 part settlementActualRestore:SourceSite {
  attribute :>> id="settlementActualRestore";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="(define (restore-wait-case converted?)";
  attribute :>> role="request-service-design";
  attribute :>> observed="On verified cached GCC/C23 collector, control and converted roots each restore the same captured wait/service continuation twice after its original worker exits; explicit escape lands before old physical registration, with exact winding and one worker completion.";
  attribute :>> required="Production integration must bind S and each physical shot to the same logical ancestry, preserve fresh physical authority and all supported exposures; controlled restore is not queue-conversion proof.";
  attribute :>> gap="No actual S emitter or production resume/registration replacement; cross-shot landing is deliberately controlled and all arbitrary user/native exits remain open.";
  ref part :>> question=cutSource;
 }
 part settlementReflectiveFrame:SourceSite {
  attribute :>> id="settlementReflectiveFrame";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="(define (wait-frame-slot k)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Real live-slot traversal finds tagged lexical cell; frame-set! replaces the captured heap slot, GC preserves the escaped frame/value identities, old alias remains7 and restores observe9 then11.";
  attribute :>> required="Preserve captured-slot versus old-value alias distinction and fresh coordinate reload; reflectively exposed continuations cannot silently qualify immutable-S assumptions.";
  attribute :>> gap="Serializer, arbitrary setters, FFI aliases and all generated writer coverage remain unqualified.";
  ref part :>> question=cutSource;
 }
 part settlementMeasuredFrameCost:SourceSite {
  attribute :>> id="settlementMeasuredFrameCost";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="(define (frame-cost k)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Native diagnostic counts unique materialized frames, ordinary live slots and actual header/body words before/after shots. Control observes7/8/45 and converted5/7/35; record40B, RC header56B, peak direct root slots1 versus2 then1.";
  attribute :>> required="Distinguish whole captured chain variability from incremental S cost; report real RC overlap56B plus1 slot, native allocator overhead unknown, static entries/eliminated closures0 and original alpha unmeasured.";
  attribute :>> gap="No causal allocation/peak/speedup claim from different frame chains or diagnostic counters; actual S frame, exclusive scan counts and original workload cost still absent.";
  ref part :>> question=cutSource;
 }
 part completionActualRestoreFlow:Flow { ref part :>> producer=roots; ref part :>> consumer=execution; attribute :>> contract="Repair9: actual wait continuation survives original owner exit and two GC-separated user shots; real reflective slot replacement and old alias semantics remain mandatory, not immutable-S admission"; }
 part settlementActualSerdes:SourceSite {
  attribute :>> id="settlementActualSerdes";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (serdes-wait-case converted? #!optional (lifetime? #f))";
  attribute :>> role="request-service-design";
  attribute :>> observed="Native control/converted cases preserve default error-exception refusal; explicit existing transform reconstructs actual wait k with repeated k/cell sharing and original mutex identity. Same-VM8-resource scope and named block-compiled code are required.";
  attribute :>> required="Keep default rejection separate from opt-in same-VM reconstruction; no queue claim/resource creation or portable Thread serialization; resolver must remain rooted and identity-bound.";
  attribute :>> gap="Cross-VM/expired resolver, malformed metadata, arbitrary resource graphs and actual S emission remain open.";
  ref part :>> question=cutSource;
 }
 part settlementSerdeException:SourceSite {
  attribute :>> id="settlementSerdeException";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (serdes-restored-handler exception)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Encoder/decoder failures retain original state; post-setup exception is matched across roles; ACK then original worker abnormal exit preserves target; rebuilt normal and raised shots use captured handler/winding and explicit escape before old queue path.";
  attribute :>> required="Preserve dynamic handler environment, source/destination roots and reader lifetime under every collecting/exception edge, without re-enqueue or pretending Scheme unwind proves native writer death.";
  attribute :>> gap="Test-owned serial record does not implement production concurrent query/ACK or arbitrary native partial-store recovery.";
  ref part :>> question=cutSource;
 }
 part settlementSerdeCounterexample:SourceSite {
  attribute :>> id="settlementSerdeCounterexample";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (resource? x)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Actual repeated-mutex alias control rejected a large-fixnum token codec at exit70: large exact-int serialization uses share/alloc and shared-ref skips transform. Final direct-byte [-128,-1] tokens pass both collision orders and exact aliases.";
  attribute :>> required="Bind token admissibility to real serializer encoding, collision/capacity refusal and same-VM resolver; retain failed source diff/stdout rather than infer all fixnums bypass sharing.";
  attribute :>> gap="No universal custom-transform identity theorem; byte-format change invalidates codec/source qualification.";
  ref part :>> question=cutSource;
 }
 part completionSerdeFlow:Flow { ref part :>> producer=roots; ref part :>> consumer=control; attribute :>> contract="Repair9: real wait serde preserves native refusal or explicit same-VM identity, captured exception/winding and post-ACK root custody; shared-token alias counterexample stays retained"; }
 part resolverAcceptedLifetime:SourceSite {
  attribute :>> id="resolverAcceptedLifetime";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (admit manifest)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Native transform closes admission during accepted decode and GC; two late requests reject, accepted result query does not decode twice, ACK closes payload right and clears registry bindings.";
  attribute :>> required="Separate new admission, accepted result/query rights and live executable-result code scope; explicit pending is not absence or resume permission.";
  attribute :>> gap="Test-owned Scheme tickets do not implement concurrent C service or physical module unload.";
  ref part :>> question=cutSource;
 }
 part resolverCodeIdentity:SourceSite {
  attribute :>> id="resolverCodeIdentity";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (code-manifest k)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Actual version and six named return-point/id/fs/link rows bound; mismatched/revoked admission and native serialized version mismatch reject; rebuilt shots survive registry close/owner exit.";
  attribute :>> required="No image release from ticket ACK alone; source/captured/native/global module references have independent owners.";
  attribute :>> gap="Static image remains loaded; all physical code owners/layout migration are unqualified.";
  ref part :>> question=cutSource;
 }
 part resolverCostValidity:SourceSite {
  attribute :>> id="resolverCostValidity";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (serdes-wait-case converted?";
  attribute :>> role="request-service-design";
  attribute :>> observed="Native frame/root observations pass but control allocation delta is negative; raw values retained and no allocation comparison admitted.";
  attribute :>> required="Reject nonmonotone measurement and keep original-load alpha/S cost/peak unmeasured, not substitute a source/model pass.";
  attribute :>> gap="Counter cause unresolved; no performance or original-workload acceptance.";
  ref part :>> question=cutSource;
 }
 part resolverLifetimeFlow:Flow { ref part :>> producer=control; ref part :>> consumer=retirement; attribute :>> contract="Repair9: close resolver admission while accepted requests/results retain rooted code/resource scope; ACK ends payload query rights, not physical module lifetime"; }

 part settlementPhysicalRegistration:SourceSite {
  attribute :>> id="settlementPhysicalRegistration";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##mutex-wait-register! current-thread mutex timeout new-owner resume)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current helper has three physical outcomes: immediate acquisition, immediate timeout, or queue insertion with resume publication and scheduling; the general caller still captures and builds recursive resume.";
  attribute :>> required="Separate admission before first registration from recovery of an existing registration; late fallback preserves the selected grant/timeout/abandon outcome. After proven service withdrawal, an unsatisfied durable wait may rearm through the helper under a fresh physical arm of the same logical wait; unknown completion cannot authorize blind reinsertion.";
  attribute :>> gap="No production typed same-wait conversion/recovery landing is emitted. Source helper existence is not capture elimination.";
  ref part :>> question=cutSource;
 }
 part settlementOverlayEscape:SourceSite {
  attribute :>> id="settlementOverlayEscape";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="(escape (list answer (vector-ref cell 1)))";
  attribute :>> role="request-service-design";
  attribute :>> observed="Restored captured callback exits through a fresh escape before the old physical queue path. Two-shot graph/winding/alias checks are real but do not execute production wait conversion.";
  attribute :>> required="Retain this graph control and separately exercise generated normal wait completion, timeout, abandonment and post-registration fallback without the escape landing before claiming production closure.";
  attribute :>> gap="Original workload, production static entry and independent final result oracle remain unexecuted/unimplemented.";
  ref part :>> question=cutSource;
 }
 part sameWaitImplementation:SourceCase {
  attribute :>> id="sameWaitImplementation";
  attribute :>> precondition="One qualified generator/runtime cohort; eligible logical wait; preknown stable key; exact semantic operands/FrameSpec; bounded metadata reserve before registration; complete canonical source roots";
  attribute :>> argument="Before registration failed admission chooses the general path once. After registration prepare and publish a rooted replacement without blind replay; selected terminal outcome wins conversion races. Known service withdrawal can authorize one new physical arm for an unsatisfied durable predicate under the same logical wait. Lost returns query the original key, ACK releases only transfer custody, and cached/escaped users retain their own roots. Checks repair all homes before decode; within-shot retry never becomes a user continuation shot. Fresh user shots preserve logical sharing and get new physical ownership.";
  attribute :>> conclusion="A complete implementation boundary for one existing mutex wait, generated static retry, late general landing, root repair and last-user exit is specified; it is not an emitted implementation or native acceptance";
  attribute :>> missing="Production S semantic lowering and materialization on exposure; branch-complete conversion/query/ACK; actual atomic/lock refinements; generated normal-path and original-load acceptance with valid cost counters";
  attribute :>> acceptance="Existing five gates jointly cover pre/post registration, grant/timeout/abandon, reflection/serde/multi-shot, cached alias, lost return, W<R repair, owner exit and metadata exhaustion, then original workload completion/cost/peak";
  attribute :>> formalBoundary="Reuse interrupt_request_lifecycle waitControlSafe/requestSafe and shared_heap_cut ordering; existing Lean slot/alias/interval laws remain their sole owners. Source relation and C publication premises are adapter obligations, not additional proofs.";
  attribute :>> counterexample="Generic late fallback creates two simultaneous physical arms, query calls old resume, returned generation is the only lookup key, ACK frees a cached root, or static frame omits a variable kept alive by the old closure";
  ref part :>> clause=completionSettlementPublish;
  ref part :>> entrySite=settlementPhysicalRegistration;
  ref part :>> exitSite=settlementOverlayEscape;
 }
 part sameWaitGeneratorDependency:CaseDependency { attribute :>> condition="Complete semantic operand, physical frame/checkpoint and exposure plan before static entry can replace capture"; ref part :>> dependent=sameWaitImplementation; ref part :>> prerequisite=completionGeneratorRefinement; }
 part sameWaitFallbackDependency:CaseDependency { attribute :>> condition="Late general landing preserves the selected terminal result or proves old-arm withdrawal before one authorized rearm; user multi-shot semantics remain distinct"; ref part :>> dependent=sameWaitImplementation; ref part :>> prerequisite=completionFallbackRefinement; }
 part sameWaitSettlementDependency:CaseDependency { attribute :>> condition="Root install/query/ACK and cached-action last-user custody hold across GC and exit"; ref part :>> dependent=sameWaitImplementation; ref part :>> prerequisite=completionSettlementRefinement; }
 part sameWaitImplementationFlow:Flow { ref part :>> producer=control; ref part :>> consumer=roots; attribute :>> contract="Repair9: pre-registration general fallback differs from post-registration same-wait recovery; query never re-registers and ACK never revokes cached/escaped root users"; }
}
