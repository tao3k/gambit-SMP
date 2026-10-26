/* Modern C target contracts. No satisfied runtime instance or async-kill recovery. */
package GambitStillMaterializationCustody {
 private import ScalarValues::*;
 part def ShellState { attribute enrolled : Boolean; attribute headerValid : Boolean; attribute allTracedSlotsValid : Boolean; attribute domainLive : Boolean; attribute backingLive : Boolean; }
 requirement def ShellLaw { subject s : ShellState; require constraint { not s.enrolled or (s.headerValid and s.allTracedSlotsValid and s.domainLive and s.backingLive) } }
 part def WriteState { attribute scanAllowed : Boolean; attribute leaseLive : Boolean; attribute storePending : Boolean; attribute dirtyCoverage : Boolean; attribute youngEdge : Boolean; attribute inputsCurrent : Boolean; attribute storeAllowed : Boolean; }
 requirement def WriteLaw { subject w : WriteState; require constraint { (not w.scanAllowed or (not w.leaseLive and not w.storePending and (not w.youngEdge or w.dirtyCoverage))) and (not w.storeAllowed or (w.leaseLive and not w.scanAllowed and w.inputsCurrent and w.dirtyCoverage)) } }
 part def RecoveryState { attribute stopped : Boolean; attribute borrowersClosed : Boolean; attribute integralStores : Boolean; attribute backingRetained : Boolean; attribute guardReleased : Boolean; attribute receiverRoot : Boolean; attribute sourceRootReleased : Boolean; }
 requirement def RecoveryLaw { subject r : RecoveryState; require constraint { (not r.guardReleased or (r.stopped and r.borrowersClosed and r.integralStores and r.backingRetained)) and (not r.sourceRootReleased or r.receiverRoot) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_materialization_custody.qnt";
 attribute :>> subjectScope="still_materialization_custody:22-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Three traced slots, pending store and two relocation epochs; abort custody, root handoff and guarded stale aliases; no native liveness";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillMaterializationCustody.lean";
 attribute :>> subjectScope="GambitSMP.StillMaterializationCustody:shellAloneInsufficient;pendingBlocksScan;rootRequired;domainRequired;backingRequired;stopAloneInsufficient;tornStoreRefused;abortThenScan;rootStepPreserves;rootTracePreserves;acquireReloads;staleAliasRefused;predirtyCoversGap;noDirtyResetWhileRetained;sentinelWriteCost;coexistencePeak";
 attribute :>> premise="16 conditional statements and root Step/Trace induction; no whole QNT or C refinement";
 }
 part shell : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-SHELL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillMaterializationCustody.lean";
 attribute :>> subjectScope="MC-SHELL:actual-source-refinement";
 attribute :>> premise="Private block and valid ordinary pointer-slot sentinels before still-list/root-domain publication; subtype layout and allocator interruption closure required";
 }
 part writes : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-WRITE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillMaterializationCustody.lean";
 attribute :>> subjectScope="MC-WRITE:actual-source-refinement";
 attribute :>> premise="Epoch lease excludes scan, pre-dirty whole-object coverage precedes first young store and persists through unknown progress; reload inputs after GC; no implicit barrier GC";
 }
 part roots : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-ROOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillMaterializationCustody.lean";
 attribute :>> subjectScope="MC-ROOT:actual-source-refinement";
 attribute :>> premise="Independent domain and physical still-chain custody survive PSTATE cleanup; receiver root enrolled before operation root release; no rootless handoff";
 }
 part recovery : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="MC-RECOVER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillMaterializationCustody.lean";
 attribute :>> subjectScope="MC-RECOVER:actual-source-refinement";
 attribute :>> premise="Exact writer stop, delegated borrower drain, integral valid field stores and ordered guard closure before scanning; abort unpublished result without replaying ambiguous heap stores; unknown-live heap writer still blocks";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=shell; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=shell; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=writes; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=writes; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=shell; ref part :>> prerequisite=GambitStructurePollStillEnvelope::poll; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=shell; ref part :>> prerequisite=GambitGenerationalBarrier::writers; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=writes; ref part :>> prerequisite=shell; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=writes; ref part :>> prerequisite=GambitGenerationalBarrier::scanCut; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=writes; ref part :>> prerequisite=GambitGenerationalBarrier::memoryOrder; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitRcFreezePublication::publication; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=shell; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=writes; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=roots; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=GambitStillOwnerRetirement::stop; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=GambitStillInitRecovery::delivery; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=recovery; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=roots; }
 part shellRoute : GambitHostRootsRefinement::Route { ref part :>> need=shell;
 attribute :>> sourceAnchors="lib/mem.c:1487-1498,1677-1708,1743-1818,3490-3655,4016-4040,4170-4245,4432-4456,4928-4935;lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/c_intf.c:5413-5500,5678-5689,5732-5803;include/gambit.h.in:2021,4231,5328-5329,5477-5482,5835-5838,5926,8059-8086";
 attribute :>> patchAnchors="Base vendor source only; cumulative fixture retained unchanged; no runtime patch";
 attribute :>> projection="Private block and valid ordinary pointer-slot sentinels before still-list/root-domain publication; subtype layout and allocator interruption closure required";
 attribute :>> failureCustodian="Operation guardian retains shell, input handles, dirty coverage and physical backing; no detachment before writer closure; independent lifecycle service owns result receipt";
 attribute :>> status="selected-source-known-conditional-model-checked-native-refinement-open";
 }
 part writesRoute : GambitHostRootsRefinement::Route { ref part :>> need=writes;
 attribute :>> sourceAnchors="lib/mem.c:1487-1498,1677-1708,1743-1818,3490-3655,4016-4040,4170-4245,4432-4456,4928-4935;lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/c_intf.c:5413-5500,5678-5689,5732-5803;include/gambit.h.in:2021,4231,5328-5329,5477-5482,5835-5838,5926,8059-8086";
 attribute :>> patchAnchors="Base vendor source only; cumulative fixture retained unchanged; no runtime patch";
 attribute :>> projection="Epoch lease excludes scan, pre-dirty whole-object coverage precedes first young store and persists through unknown progress; reload inputs after GC; no implicit barrier GC";
 attribute :>> failureCustodian="Operation guardian retains shell, input handles, dirty coverage and physical backing; no detachment before writer closure; independent lifecycle service owns result receipt";
 attribute :>> status="selected-source-known-conditional-model-checked-native-refinement-open";
 }
 part rootsRoute : GambitHostRootsRefinement::Route { ref part :>> need=roots;
 attribute :>> sourceAnchors="lib/mem.c:1487-1498,1677-1708,1743-1818,3490-3655,4016-4040,4170-4245,4432-4456,4928-4935;lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/c_intf.c:5413-5500,5678-5689,5732-5803;include/gambit.h.in:2021,4231,5328-5329,5477-5482,5835-5838,5926,8059-8086";
 attribute :>> patchAnchors="Base vendor source only; cumulative fixture retained unchanged; no runtime patch";
 attribute :>> projection="Independent domain and physical still-chain custody survive PSTATE cleanup; receiver root enrolled before operation root release; no rootless handoff";
 attribute :>> failureCustodian="Operation guardian retains shell, input handles, dirty coverage and physical backing; no detachment before writer closure; independent lifecycle service owns result receipt";
 attribute :>> status="selected-source-known-conditional-model-checked-native-refinement-open";
 }
 part recoveryRoute : GambitHostRootsRefinement::Route { ref part :>> need=recovery;
 attribute :>> sourceAnchors="lib/mem.c:1487-1498,1677-1708,1743-1818,3490-3655,4016-4040,4170-4245,4432-4456,4928-4935;lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/c_intf.c:5413-5500,5678-5689,5732-5803;include/gambit.h.in:2021,4231,5328-5329,5477-5482,5835-5838,5926,8059-8086";
 attribute :>> patchAnchors="Base vendor source only; cumulative fixture retained unchanged; no runtime patch";
 attribute :>> projection="Exact writer stop, delegated borrower drain, integral valid field stores and ordered guard closure before scanning; abort unpublished result without replaying ambiguous heap stores; unknown-live heap writer still blocks";
 attribute :>> failureCustodian="Operation guardian retains shell, input handles, dirty coverage and physical backing; no detachment before writer closure; independent lifecycle service owns result receipt";
 attribute :>> status="selected-source-known-conditional-model-checked-native-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="still-enrollment";
 attribute :>> sourceAnchors="mem.c:1487-1498,1677-1708";
 attribute :>> actualChain="Allocate -> link still_objs -> metadata/header -> return uninitialized body";
 attribute :>> hazard="Refcount roots do not initialize traced slots; list append is not a crash-safe commit";
 attribute :>> replacement="Separate private allocation, scan-valid shell and epoch-qualified enrollment; retain old synchronous contract until replacement";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="generated-structure";
 attribute :>> sourceAnchors="_kernel.scm:43-112;_kernel.c:23864-23904";
 attribute :>> actualChain="SAVE1 type -> allocate -> RESTORE1 -> refcount dec -> INIT loop/memset -> result";
 attribute :>> hazard="Saved root is cleared after RESTORE; inserting GC in fill would need input and partial-result roots";
 attribute :>> replacement="Generated InitSpec and lease; root all input aliases and shell before any new checkpoint";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="native-pair-vector";
 attribute :>> sourceAnchors="mem.c:1743-1818;c_intf.c:5732-5803";
 attribute :>> actualChain="String child -> make_pair -> release children; vector plain fill";
 attribute :>> hazard="Native constructors require nonmovable input; no arbitrary movable-pointer admission";
 attribute :>> replacement="Keep raw ABI restrictions; managed facade uses updateable handles, no hidden GC in barrier";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="mutation-family";
 attribute :>> sourceAnchors="gambit.h.in:2021,4231,5328-5329,5477-5482,5835-5838,5926";
 attribute :>> actualChain="CAR/CDR, vector, structure type/slot and continuation frame setters are plain stores";
 attribute :>> hazard="These selected macros are not a generational remembered-set barrier; raw aliases escape them";
 attribute :>> replacement="Generated StoreSpec covers initialization and mutation; raw FFI borrows must be scoped or refused";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="collector-rewrite";
 attribute :>> sourceAnchors="mem.c:3490-3655,4170-4245";
 attribute :>> actualChain="mark_array loads cell and rewrites forwarding address; still scanner enumerates body";
 attribute :>> hazard="A stable still body can contain movable children; atomic valid slots alone do not prevent stale addresses";
 attribute :>> replacement="Mutator/scan exclusion plus complete handle reload and retained dirty coverage";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="atomic-conversion";
 attribute :>> sourceAnchors="mem.c:4016-4040;c_intf.c:5413-5500,5678-5689";
 attribute :>> actualChain="STRING payload fill or error -> release; success writes *obj";
 attribute :>> hazard="GC skips string payload but user-visible data must still be complete; no pointer-shell argument needed";
 attribute :>> replacement="Subtype-specific InitSpec; error is non-delivery, refcount release is not immediate free";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="physical-cleanup";
 attribute :>> sourceAnchors="mem.c:4432-4456,4928-4935;setup.c:903-978";
 attribute :>> actualChain="PSTATE cleanup frees all still blocks, then RC chain; resize joins afterward";
 attribute :>> hazard="Root record in another domain does not alone prevent physical free";
 attribute :>> replacement="Transfer or retain allocator-chain backing before cleanup; ownership domain survives executor";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="unknown-write";
 attribute :>> sourceAnchors="mem.c:1743-1818;_kernel.scm:92-112;os_thread.c:546-591";
 attribute :>> actualChain="Raw field fill has no operation-keyed store receipt";
 attribute :>> hazard="Join failure or lost result cannot certify closure; asynchronous kill may leave torn store or lock held";
 attribute :>> replacement="Reject GC detachment of unknown heap writer; use isolated native stage and controlled bounded commit lease";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="ordinary shell";
 attribute :>> removedWork="Remove dependency of scan validity on final semantic initialization";
 attribute :>> bound="a ordinary pointer fields: sentinel a + final a = 2a stores versus a";
 attribute :>> addedCost="Extra a stores; valid header/layout; no second mandatory body allocation";
 attribute :>> condition="Only admitted ordinary pointer layouts; weak/procedure/frame/foreign special layouts require separate InitSpec";
 }
 part cost1 : CostRow {
 attribute :>> capability="remembered coverage";
 attribute :>> removedWork="Remove per-field post-store ambiguity from minor admission";
 attribute :>> bound="One whole-object coverage reservation per initialization lifetime; scan up to a slots per minor while retained";
 attribute :>> addedCost="Sticky dirty entry, epoch pin, possible repeated full partial-object scans";
 attribute :>> condition="Must cover allocator overflow, reset/rearm and residual edges; no scalar speedup asserted";
 }
 part cost2 : CostRow {
 attribute :>> capability="managed commit lease";
 attribute :>> removedWork="Remove native helper from GC wait only before it acquires heap-write authority";
 attribute :>> bound="With batch b, at most b logical stores per cooperative lease; no wall-clock bound";
 attribute :>> addedCost="Acquire/release, input-handle reload and root-domain enumeration per lease";
 attribute :>> condition="Unknown-live raw writer or dead lock owner prevents bound; process-local recovery not qualified";
 }
 part cost3 : CostRow {
 attribute :>> capability="stopped-store abort";
 attribute :>> removedWork="Avoid replay of ambiguous heap-visible store and global semantic completion wait";
 attribute :>> bound="Zero additional final fill after abort; retain valid actual slots until collectible";
 attribute :>> addedCost="Stop/borrower closure, retained roots/backing, error result and later GC scan";
 attribute :>> condition="Only integrity-preserving stop; no arbitrary pthread_cancel, fault or process crash recovery";
 }
 part cost4 : CostRow {
 attribute :>> capability="root handoff";
 attribute :>> removedWork="Remove dependence on dead PSTATE result slot after domain transfer";
 attribute :>> bound="Source pin retained until receiver pin acknowledgement; zero rootless intervals";
 attribute :>> addedCost="Overlap pins and exact operation generation/result receipt";
 attribute :>> condition="Root registry transfer alone does not retain still block physically";
 }
 part cost5 : CostRow {
 attribute :>> capability="whole-round memory";
 attribute :>> removedWork="No mandatory payload allocation eliminated";
 attribute :>> bound="Peak >= max_t(stage_t + body_t + input_t + metadata_t) for those simultaneous terms";
 attribute :>> addedCost="S+B+E+M overlap plus shell scan/dirty/root metadata; sentinel uses same B";
 attribute :>> condition="Qg only lowers whole peak if max_t(P_t-Qg_t+A_t) < max_t(P_t); late refund cannot lower past peak";
 }
 part cost6 : CostRow {
 attribute :>> capability="modern C versus Zig";
 attribute :>> removedWork="One generated InitSpec/StoreSpec and runtime owner";
 attribute :>> bound="Same a/2a stores, barriers, scan and ownership duties in both languages";
 attribute :>> addedCost="C atomics/schema generator; Zig adds backend/toolchain/ABI maintenance if selected";
 attribute :>> condition="No incremental Zig GC correctness or work saving established; modern C remains selected";
 }
 part def Node { attribute nodeId : String; attribute labelText : String; }
 part def Edge { ref part producer : Node; ref part consumer : Node; attribute labelText : String; }
 part node0 : Node { attribute :>> nodeId="allocate"; attribute :>> labelText="Private block\\nallocator ledger"; }
 part node1 : Node { attribute :>> nodeId="shell"; attribute :>> labelText="Valid ordinary shell\\nnot user-visible"; }
 part node2 : Node { attribute :>> nodeId="roots"; attribute :>> labelText="Independent root domain\\nphysical backing retained"; }
 part node3 : Node { attribute :>> nodeId="lease"; attribute :>> labelText="Managed epoch lease\\npre-dirty + reload"; }
 part node4 : Node { attribute :>> nodeId="store"; attribute :>> labelText="Integral field stores\\npending outcome retained"; }
 part node5 : Node { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown raw writer\\nGC gate remains closed"; }
 part node6 : Node { attribute :>> nodeId="stop"; attribute :>> labelText="Authenticated stop\\nall borrowers closed"; }
 part node7 : Node { attribute :>> nodeId="abort"; attribute :>> labelText="Abort semantic result\\nretain actual valid slots"; }
 part node8 : Node { attribute :>> nodeId="scan"; attribute :>> labelText="GC scan / rewrite\\nno live write lease"; }
 part node9 : Node { attribute :>> nodeId="result"; attribute :>> labelText="Complete result\\nreceiver pin then source drop"; }
 part edge0 : Edge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="initialize before enrollment"; }
 part edge1 : Edge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="release publication / census"; }
 part edge2 : Edge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="acquire epoch"; }
 part edge3 : Edge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="no GC inside lease"; }
 part edge4 : Edge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="missing closure"; }
 part edge5 : Edge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="requires external evidence"; }
 part edge6 : Edge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="do not replay field"; }
 part edge7 : Edge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="guard cleared after closure"; }
 part edge8 : Edge { ref part :>> producer=node4; ref part :>> consumer=node8; attribute :>> labelText="normal release between batches"; }
 part edge9 : Edge { ref part :>> producer=node8; ref part :>> consumer=node3; attribute :>> labelText="reload relocated handles"; }
 part edge10 : Edge { ref part :>> producer=node4; ref part :>> consumer=node9; attribute :>> labelText="all fields complete; release"; }
 part edge11 : Edge { ref part :>> producer=node9; ref part :>> consumer=node8; attribute :>> labelText="root overlap"; }
 part edge12 : Edge { ref part :>> producer=node0; ref part :>> consumer=node8; attribute :>> labelText="unenrolled block excluded; ledger retained"; }
}
