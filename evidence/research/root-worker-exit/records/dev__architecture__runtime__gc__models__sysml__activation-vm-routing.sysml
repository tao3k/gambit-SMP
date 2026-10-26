/* Modern C semantic authority; design and models only. */
package GambitActivationVmRouting { private import ScalarValues::*;
part history:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-H";
attribute :>> kind="interleaving";
attribute :>> subjectPath="models/gambit/activation_vm_routing.qnt";
attribute :>> subjectScope="activation_vm_routing:two-origin-two-cell-two-session-single-VM;seed17";
attribute :>> premise="Atomic origin/locator transaction, pinned route, externally established frozen source/child/admin receipts; bounded histories and sampling, not exhaustive or C/unload/liveness proof.";
}
part induction:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-I";
attribute :>> kind="induction";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="GambitSMP.ActivationVmRouting:conditional-origin-route-and-budget-laws";
attribute :>> premise="Selective locator, resident epoch, reader, admin, child and fixed-budget laws; not complete QNT induction or source/C refinement.";
}
part originDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-ORIGIN";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-ORIGIN:pre-admitted-base-and-parent-origin-mailboxes";
attribute :>> premise="Generated caller already holds bounded origin slot/generation, complete mapped source and durable bind serial; no origin discovered by FP/thread ID/callsite; initial entry/host permits must be separately admitted.";
}
part bindingDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-BIND";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-BIND:claim-journal-locator-and-lost-return-recovery";
attribute :>> premise="Same control transaction reserves canonical cell and publishes recoverable locator into fixed origin journal before effects; Binding retains source; retry follows locator and never creates another cell; child retains parent journal.";
}
part routerDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-ROUTER";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-ROUTER:resident-anchor-fixed-VM-slot-session-and-pin";
attribute :>> premise="Anchor persists outside GSTATE teardown; check slot/session/VM generation before reading VM pointer; lifetime pin before dereference; fixed VM capacity and checked counters, no historical VM map.";
}
part lifecycleDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-LIFECYCLE";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-LIFECYCLE:repeated-setup-cleanup-and-status-drain";
attribute :>> premise="Offline/Starting/Online/Quiescing/Detached; consume session even on setup failure; repeated live setup rejects; status drain allowed while new effects close; detach before reader-safe free.";
}
part teardownDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="AV-TEARDOWN";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-TEARDOWN:reserved-shrink-lane-and-explicit-cleanup-result";
attribute :>> premise="Real cleanup calls current_vm_resize(false,1); dedicated per-VM administrative credit must survive ordinary window exhaustion; unknown shrink/child results retain debt and resumable cleanup state.";
}
part orderDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
attribute :>> obligationId="AV-ORDER";
attribute :>> kind="native-memory-order";
attribute :>> subjectPath="models/gambit/lean/ActivationVmRouting.lean";
attribute :>> subjectScope="AV-ORDER:origin-bind-router-lock-and-effect-close-C-order";
attribute :>> premise="Concrete C journal commit and recovery, router/session pin vs removal, domain effect gate recheck, root scanner publication and lock hierarchy; arbitrary owner-stop/torn stores require explicit receipts.";
}
ref part priorWindow=GambitRequestRetirement::windowDuty;
ref part priorOom=GambitRequestRetirement::oomDuty;
ref part priorReclaim=GambitRequestRetirement::reclaimDuty;
ref part priorExit=GambitBootstrapRootRecovery::unwindDuty;
ref part priorRestore=GambitBootstrapRootRecovery::restoreDuty;
ref part priorMembers=GambitResizeBootstrapAdmission::membership;
ref part priorGate=GambitResizeBootstrapAdmission::gate;
part dependency0:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=originDuty; ref part :>> prerequisite=history; }
part dependency1:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=originDuty; ref part :>> prerequisite=induction; }
part dependency2:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=history; }
part dependency3:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=induction; }
part dependency4:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=routerDuty; ref part :>> prerequisite=history; }
part dependency5:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=routerDuty; ref part :>> prerequisite=induction; }
part dependency6:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifecycleDuty; ref part :>> prerequisite=history; }
part dependency7:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifecycleDuty; ref part :>> prerequisite=induction; }
part dependency8:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=teardownDuty; ref part :>> prerequisite=history; }
part dependency9:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=teardownDuty; ref part :>> prerequisite=induction; }
part dependency10:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=history; }
part dependency11:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=induction; }
part dependency12:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=originDuty; ref part :>> prerequisite=priorOom; }
part dependency13:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=originDuty; ref part :>> prerequisite=priorRestore; }
part dependency14:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=originDuty; }
part dependency15:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=priorWindow; }
part dependency16:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=priorExit; }
part dependency17:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=priorReclaim; }
part dependency18:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bindingDuty; ref part :>> prerequisite=orderDuty; }
part dependency19:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=routerDuty; ref part :>> prerequisite=orderDuty; }
part dependency20:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifecycleDuty; ref part :>> prerequisite=routerDuty; }
part dependency21:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifecycleDuty; ref part :>> prerequisite=bindingDuty; }
part dependency22:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifecycleDuty; ref part :>> prerequisite=teardownDuty; }
part dependency23:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=teardownDuty; ref part :>> prerequisite=priorMembers; }
part dependency24:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=teardownDuty; ref part :>> prerequisite=priorGate; }
part dependency25:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=priorGate; }
part def CallerRow {  attribute callerId:String; attribute sourceAnchors:String; attribute actualChain:String; attribute hazard:String; attribute replacement:String; }
part caller0:CallerRow { attribute :>> callerId="GENERATOR-HOME"; attribute :>> sourceAnchors="vendor/gambit/gsc/_ptree2.scm:2850-2874,2902-2925,3238-3251;lib/_kernel.c:6258-6288,26338-26368"; attribute :>> actualChain="Mapped Scheme argument and complete CFUN context exist, but no stable origin journal is emitted"; attribute :>> hazard="Generate OriginPermit/PointId/effect state and recoverable bind locator before native side effect"; attribute :>> replacement="No callsite-only or moving physical frame address identity"; }
part caller1:CallerRow { attribute :>> callerId="LOCAL-RESIZE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:1050-1112,1155-1178"; attribute :>> actualChain="Local sop copies thunk and result; collected error can throw after effect"; attribute :>> hazard="Replace raw thunk ownership with same canonical locator; ordinary return is observation only"; attribute :>> replacement="Unknown return never issues a fresh activation silently"; }
part caller2:CallerRow { attribute :>> callerId="NATIVE-ENTRY-EXIT"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:763-810,3276-3423,6395-6440;include/gambit.h.in:10325-10404"; attribute :>> actualChain="Two run families, marker/catcher and conversion-dependent normal cleanup"; attribute :>> hazard="Pre-admit base origins for main/worker entry; nested activation holds parent journal and VM escrow"; attribute :>> replacement="No new native origin when only an untracked C local protects payload"; }
part caller3:CallerRow { attribute :>> callerId="SETUP-RESET"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:6240-6290,6320-6333;include/gambit.h.in:12116-12126"; attribute :>> actualChain="setup reassigns parameters/setup_state, processor_count and VM list mutex/links"; attribute :>> hazard="Resident anchor gates repeated setup and consumes fresh session before ready publication"; attribute :>> replacement="Existing integer setup_state and reused vmstate0 address are not incarnation identity"; }
part caller4:CallerRow { attribute :>> callerId="CLEANUP-SHRINK"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:4834-4883"; attribute :>> actualChain="cleanup marks setup_state2 then shrinks through current_vm_resize(false,1), tears PSTATE/VM and list mutex down"; attribute :>> hazard="Quiesce user effects but retain status/admin lane and resumable cleanup debt"; attribute :>> replacement="Do not reject cleanup by closing its own ordinary resize route"; }
part caller5:CallerRow { attribute :>> callerId="PHYSICAL-VM-FREE"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:4937-4988;include/gambit.h.in:11947-11979"; attribute :>> actualChain="GC locks/condvar destroyed, PSTATE0 cleanup, msections free and circular list unlink"; attribute :>> hazard="Detach router entry and drain router/source/GC/native readers before physical teardown"; attribute :>> replacement="VM circular list mutex cannot protect late lookup after its own destruction"; }
part caller6:CallerRow { attribute :>> callerId="VM-INIT-ERROR"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:4773-4831,6350-6440"; attribute :>> actualChain="setup_vmstate initializes VM, calls setup_os_and_mem_vmstate without checking returned value, then returns setup_pstate status"; attribute :>> hazard="Typed staged construction records each acquired resource and controls ready publication"; attribute :>> replacement="Source inspection is not a claim that existing partial setup/cleanup is transactional or repeat-safe"; }
part def PathRow {  attribute pathId:String; attribute sourceAnchors:String; attribute actualPath:String; attribute contract:String; attribute failure:String; attribute custodian:String; }
part path0:PathRow { attribute :>> pathId="ORIGIN-PRECONDITION"; attribute :>> sourceAnchors="_ptree2.scm:3238-3251;_kernel.c:26338-26368"; attribute :>> actualPath="Natural Scheme caller is mapped; new stable mailbox is not already implemented"; attribute :>> contract="Base execution context/host permit pre-owns bounded VM origin journal; nested parent cell contains one child journal"; attribute :>> failure="No complete pre-admitted origin means no managed effect"; attribute :>> custodian="Natural source/root owner until VM accepts exact frozen view"; }
part path1:PathRow { attribute :>> pathId="BIND-RECOVERY"; attribute :>> sourceAnchors="setup.c:1155-1178;gambit.h.in:10325-10404"; attribute :>> actualPath="Native result can be bypassed by throw/catcher; raw FP may later change"; attribute :>> contract="Prepared -> Binding(cell reserved + locator recorded) -> Bound; recover same origin serial/locator"; attribute :>> failure="Unknown mid-write commit needs stopped writer/progress receipt, never blind re-reserve"; attribute :>> custodian="VM bind journal and exact source view until final resolution"; }
part path2:PathRow { attribute :>> pathId="NESTED-CHILD"; attribute :>> sourceAnchors="setup.c:3276-3423;lib/_kernel.scm:1026-1066"; attribute :>> actualPath="Native activation and Scheme continuation extents differ"; attribute :>> contract="Child close/result/source/read drain precedes parent journal reuse; same-live restore reloads binding"; attribute :>> failure="Captured old handle is metadata, not permission to resurrect a C stack"; attribute :>> custodian="Parent activation and VM escrow jointly keep child origin backing"; }
part path3:PathRow { attribute :>> pathId="ROUTER-PIN"; attribute :>> sourceAnchors="setup.c:6240-6290,4834-4883;mem.c:4937-4988"; attribute :>> actualPath="vmstate0 address repeats and VM/list synchronization may be destroyed"; attribute :>> contract="Stable resident anchor checks numeric namespace before pointer read, then pins exact VM incarnation"; attribute :>> failure="Wrong/old key rejects without GSTATE/VM access or new record creation"; attribute :>> custodian="Resident router cell until pin drain; logical detach is not physical free"; }
part path4:PathRow { attribute :>> pathId="STATUS-DRAIN"; attribute :>> sourceAnchors="setup.c:4834-4883,1050-1112"; attribute :>> actualPath="cleanup closes prior state early but live effects/status may remain"; attribute :>> contract="Quiescing permits exact existing status settlement while new effects are denied; old user pins recheck domain close"; attribute :>> failure="Result/source debts cannot be erased by cleanup_state or timeout"; attribute :>> custodian="Canonical VM/source records remain until every actual completion gate closes"; }
part path5:PathRow { attribute :>> pathId="ADMIN-CREDIT"; attribute :>> sourceAnchors="setup.c:4858-4862,942-1001"; attribute :>> actualPath="cleanup reuses resize; thread/member outcomes can be unknown"; attribute :>> contract="Pre-reserved per-VM teardown lane, authority and result storage outside ordinary W cells"; attribute :>> failure="Unknown join/shrink result cannot infer stop, detach or reset session"; attribute :>> custodian="VM administrative debt plus imported member/resource custodian"; }
part path6:PathRow { attribute :>> pathId="SESSION-REUSE"; attribute :>> sourceAnchors="setup.c:6240-6290;gambit.h.in:12116-12126"; attribute :>> actualPath="Global state holds mutable setup fields, no managed non-reused router session"; attribute :>> contract="Fresh checked session on every setup attempt; failed setup burns identity; fixed routing slot reuse needs new generation"; attribute :>> failure="No managed dlclose/reload with anchor/code authority gone; exhaustion refuses"; attribute :>> custodian="Resident anchor survives cleanup; remaining raw old capabilities refuse unload"; }
part def OrderRow {  attribute edgeId:String; attribute orderContract:String; attribute rejectedShortcut:String; }
part orderRow0:OrderRow { attribute :>> edgeId="ORIGIN-FIRST"; attribute :>> orderContract="Complete mapped source, bounded origin permit and immutable bind serial precede claim; no source-root registration bootstrap is silently assumed."; attribute :>> rejectedShortcut="No fresh unbounded origin-to-key map or reconstruction from moving FP."; }
part orderRow1:OrderRow { attribute :>> edgeId="BIND-COMMIT"; attribute :>> orderContract="Initialize safe record and link exact locator in origin journal in one control cut before Bound/effect visibility; publish ready last."; attribute :>> rejectedShortcut="Lost ordinary return does not erase committed locator; torn C stores require actual progress/stop proof."; }
part orderRow2:OrderRow { attribute :>> edgeId="ROUTE-PIN"; attribute :>> orderContract="Under resident anchor lock compare full namespace and attach VM lifetime pin before exposing pointer; release lock before domain operation."; attribute :>> rejectedShortcut="Do not dereference GSTATE or freed VM merely to test incarnation."; }
part orderRow3:OrderRow { attribute :>> edgeId="CLOSE-RECHECK"; attribute :>> orderContract="Quiescing stops new user pins/effects; a pre-close user pin must recheck effect admission under domain control; status/admin remain typed roles."; attribute :>> rejectedShortcut="Router lifetime pin grants storage lifetime, not authority to execute after close."; }
part orderRow4:OrderRow { attribute :>> edgeId="DETACH-FREE"; attribute :>> orderContract="All activation/source/result/child/admin/GC duties close before router detach; existing router readers drain before destroying VM locks or heap."; attribute :>> rejectedShortcut="No waiting for owner/callback/GC under anchor or domain lock; no setup while detached readers remain."; }
part orderRow5:OrderRow { attribute :>> edgeId="SESSION-COMMIT"; attribute :>> orderContract="Resident anchor increments checked session before any fallible setup; cleanup mutates GSTATE but never resets anchor; publish Online only on fully initialized VM."; attribute :>> rejectedShortcut="Rejected/failed setup cannot recycle old session; dlclose is not ordinary cleanup."; }
part def CostRow {  attribute capability:String; attribute removedWork:String; attribute bound:String; attribute addedCost:String; attribute condition:String; }
part cost0:CostRow { attribute :>> capability="Activation lookup"; attribute :>> removedWork="Remove historical activation-to-request dictionary"; attribute :>> bound="Direct fixed origin locator; canonical cell/request share first-cut storage"; attribute :>> addedCost="Bounded base mailboxes O plus W embedded child journals and bind stamps"; attribute :>> condition="Pre-admitted origin/child capacity is a new explicit cost, not a free property of CFUN_ARG."; }
part cost1:CostRow { attribute :>> capability="Lost registration reply"; attribute :>> removedWork="Reuse canonical binding without re-evaluating Scheme input"; attribute :>> bound="At most one cell per live origin serial; recovery adds 0 control allocations by design"; attribute :>> addedCost="Origin journal read, locator/tag/intent validation and query pins"; attribute :>> condition="Unknown torn bind cannot be called absent; source/VM journal stays owned."; }
part cost2:CostRow { attribute :>> capability="Cross-setup routing"; attribute :>> removedWork="Avoid keeping every dead VM in a history map"; attribute :>> bound="R resident VM slots plus non-reset checked session/generation counters"; attribute :>> addedCost="Resident anchor + router locks/pins + R lifecycle cells"; attribute :>> condition="First model covers one VM slot/two sessions; multi-VM/unload refinement remains open."; }
part cost3:CostRow { attribute :>> capability="Cleanup independence"; attribute :>> removedWork="Remove capacity dependence on ordinary request window"; attribute :>> bound="One pre-reserved administrative lane per admitted VM"; attribute :>> addedCost="R admin cells and typed role/result/debt gates"; attribute :>> condition="No proof of successful stop from ignored join or ordinary resize return."; }
part cost4:CostRow { attribute :>> capability="Nested activation"; attribute :>> removedWork="Avoid separate unbounded callback identity graph"; attribute :>> bound="One child mailbox per parent activation, plus bounded base/host origins"; attribute :>> addedCost="Parent cell remains until child closes; nesting can consume W and refuse new entry"; attribute :>> condition="A full window is backpressure; first slice admits one recoverable request and synchronous child per activation."; }
part cost5:CostRow { attribute :>> capability="Peak storage"; attribute :>> removedWork="Replace history-sized maps with fixed admission-controlled support"; attribute :>> bound="Control = anchor + R*router + O*baseMailbox + W*completeCell + bitmap + R*admin"; attribute :>> addedCost="Old VM backing and frozen sources retained through unknown outcomes/readers"; attribute :>> condition="W cells include child journal and bind/result/exit state; count aliases/backing once; no total heap/CPU gain proved."; }
part cost6:CostRow { attribute :>> capability="Modern C leverage"; attribute :>> removedWork="Move lifecycle/identity/effect policy out of accidental C stack/list cleanup"; attribute :>> bound="Generated FrameSpec/PointId origin protocol and typed VM service"; attribute :>> addedCost="Generator changes, stable anchor, lock-order proof and root/FFI consumer migration"; attribute :>> condition="Retire old raw sop ownership, normal-only cleanup and late raw VM lookup only after complete source gates."; }
part def IdentityField { ref part need:GambitAssuranceRouting::ModelNeed; attribute fieldId:String; attribute sourceAnchors:String; attribute valueContract:String; attribute invalidShortcut:String; attribute failureCustodian:String; }
part fieldRow0:IdentityField { ref part :>> need=GambitActivationVmRouting::originDuty; attribute :>> fieldId="ORIGIN-PERMIT"; attribute :>> sourceAnchors="_ptree2.scm:2850-2874;_kernel.c:26338-26368"; attribute :>> valueContract="Session/VM slot-generation/base-or-parent mailbox/checked bind serial; already owned before managed claim"; attribute :>> invalidShortcut="Moving FP, thread ID, callsite-only label or new registry on every retry"; attribute :>> failureCustodian="Base VM origin or parent activation journal"; }
part fieldRow1:IdentityField { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> fieldId="BIND-LOCATOR"; attribute :>> sourceAnchors="setup.c:1155-1178"; attribute :>> valueContract="Canonical sequence/full slot tag and immutable intent installed before effect; retained independently from C return"; attribute :>> invalidShortcut="Observation loss resets key or creates another request"; attribute :>> failureCustodian="VM-owned bounded bind journal plus source lease"; }
part fieldRow2:IdentityField { ref part :>> need=GambitActivationVmRouting::routerDuty; attribute :>> fieldId="ROUTE-TOKEN"; attribute :>> sourceAnchors="gambit.h.in:11947-11979,12116-12126"; attribute :>> valueContract="Resident anchor identity/session/VM slot-generation, then activation locator"; attribute :>> invalidShortcut="vmstate0 pointer or setup_state integer is full identity"; attribute :>> failureCustodian="Pinned resident router record"; }
part fieldRow3:IdentityField { ref part :>> need=GambitActivationVmRouting::lifecycleDuty; attribute :>> fieldId="SESSION-PHASE"; attribute :>> sourceAnchors="setup.c:6240-6290,4834-4883"; attribute :>> valueContract="Offline/Starting/Online/Quiescing/Detached; failed attempts consume non-reused session"; attribute :>> invalidShortcut="Setup reinitializes live mutex or cleanup flips a Boolean and frees everything"; attribute :>> failureCustodian="Resident anchor outside GSTATE cleanup"; }
part fieldRow4:IdentityField { ref part :>> need=GambitActivationVmRouting::teardownDuty; attribute :>> fieldId="TEARDOWN-AUTHORITY"; attribute :>> sourceAnchors="setup.c:4858-4862"; attribute :>> valueContract="Exact current VM/session reserved administrative request/result debt"; attribute :>> invalidShortcut="Ordinary caller marks itself administrative to bypass close"; attribute :>> failureCustodian="VM cleanup coordinator and member/root custodian"; }
part def Transition { ref part need:GambitAssuranceRouting::ModelNeed; attribute fromPhase:String; attribute toPhase:String; attribute qntStep:String; attribute guardContract:String; attribute leanLaw:String; attribute sourceAnchors:String; }
part transition0:Transition { ref part :>> need=GambitActivationVmRouting::lifecycleDuty; attribute :>> fromPhase="Offline"; attribute :>> toPhase="Starting"; attribute :>> qntStep="startSetup"; attribute :>> guardContract="Fresh checked session; no old pointer-bearing readers or live VM"; attribute :>> leanLaw="newSetupHasFreshEpoch"; attribute :>> sourceAnchors="setup.c:6240-6290"; }
part transition1:Transition { ref part :>> need=GambitActivationVmRouting::lifecycleDuty; attribute :>> fromPhase="Starting"; attribute :>> toPhase="OfflineOrOnline"; attribute :>> qntStep="setupFail / initializeVm / publishVm"; attribute :>> guardContract="Failed setup consumes identity; Online only after full construction"; attribute :>> leanLaw="cleanupKeepsResidentEpoch"; attribute :>> sourceAnchors="setup.c:4773-4831,6320-6440"; }
part transition2:Transition { ref part :>> need=GambitActivationVmRouting::originDuty; attribute :>> fromPhase="MappedCaller"; attribute :>> toPhase="PreparedOrigin"; attribute :>> qntStep="prepare"; attribute :>> guardContract="Previously admitted base/parent permit and stable bind serial"; attribute :>> leanLaw="identityExcludesObservation"; attribute :>> sourceAnchors="_ptree2.scm:3238-3251;_kernel.c:26338-26368"; }
part transition3:Transition { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> fromPhase="PreparedOrigin"; attribute :>> toPhase="BindingWithLocator"; attribute :>> qntStep="claimBind"; attribute :>> guardContract="Safe canonical slot and origin locator published together before native effect"; attribute :>> leanLaw="bindRecover"; attribute :>> sourceAnchors="setup.c:1155-1178;proposed bind journal"; }
part transition4:Transition { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> fromPhase="BindingOrLostReply"; attribute :>> toPhase="SameCanonicalBinding"; attribute :>> qntStep="findByOrigin / finishBind / retryClaim"; attribute :>> guardContract="Exact session/origin/serial/tag; query never creates"; attribute :>> leanLaw="retryBoundNeverCreates"; attribute :>> sourceAnchors="setup.c:1050-1112;gambit.h.in:10402"; }
part transition5:Transition { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> fromPhase="Binding"; attribute :>> toPhase="VmEscrowOnExit"; attribute :>> qntStep="takeEscrow / closeActivation / exceptionalExit"; attribute :>> guardContract="Source view/initialization and original disposition retained before physical unwind"; attribute :>> leanLaw="unknownKeepsBindingCoverage"; attribute :>> sourceAnchors="setup.c:3276-3423;mem.c:4529-4561"; }
part transition6:Transition { ref part :>> need=GambitActivationVmRouting::routerDuty; attribute :>> fromPhase="OnlineOrStatusDrain"; attribute :>> toPhase="PinnedVm"; attribute :>> qntStep="pinRoute / readPinned / unpinRoute"; attribute :>> guardContract="Lifetime pin before pointer; old session rejects without dereference"; attribute :>> leanLaw="oldSessionRejects"; attribute :>> sourceAnchors="setup.c:4834-4883;mem.c:4937-4988"; }
part transition7:Transition { ref part :>> need=GambitActivationVmRouting::lifecycleDuty; attribute :>> fromPhase="Online"; attribute :>> toPhase="Quiescing"; attribute :>> qntStep="beginCleanup"; attribute :>> guardContract="User effect gate closes even for preexisting user pins; status role preserved"; attribute :>> leanLaw="closeBlocksUser"; attribute :>> sourceAnchors="setup.c:4834-4862"; }
part transition8:Transition { ref part :>> need=GambitActivationVmRouting::teardownDuty; attribute :>> fromPhase="Quiescing"; attribute :>> toPhase="AdminDebtResolved"; attribute :>> qntStep="adminProgress / adminUnknown / ackAdmin"; attribute :>> guardContract="Pre-reserved administrative credit; only actual external stop/result receipt clears debt"; attribute :>> leanLaw="unknownAdminPreventsDetach"; attribute :>> sourceAnchors="setup.c:4858-4862,942-1001"; }
part transition9:Transition { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> fromPhase="TerminalActivation"; attribute :>> toPhase="ReusableOriginAndSlot"; attribute :>> qntStep="sourceAck / releaseSource / ackResult / retire / advance"; attribute :>> guardContract="Source/result/reader/child duties close before locator cleared or slot reused"; attribute :>> leanLaw="childKeepsParentJournal"; attribute :>> sourceAnchors="setup.c:3276-3423;mem.c:3970-3988"; }
part transition10:Transition { ref part :>> need=GambitActivationVmRouting::routerDuty; attribute :>> fromPhase="Quiescing"; attribute :>> toPhase="DetachedThenOffline"; attribute :>> qntStep="detach / unpinRoute / freeVm"; attribute :>> guardContract="All root/admin/source debts close; route visibility removed; existing readers drain before physical teardown"; attribute :>> leanLaw="readerPreventsFree"; attribute :>> sourceAnchors="mem.c:4937-4988;setup.c:4880"; }
part def SourceRoute { ref part need:GambitAssuranceRouting::ModelNeed; attribute sourceAnchors:String; attribute projection:String; attribute failureCustodian:String; attribute status:String; }
part route0:SourceRoute { ref part :>> need=GambitActivationVmRouting::originDuty; attribute :>> sourceAnchors="_ptree2.scm:3238-3251;_kernel.c:26338-26368"; attribute :>> projection="Base execution context/host permit pre-owns bounded VM origin journal; nested parent cell contains one child journal"; attribute :>> failureCustodian="Natural source/root owner until VM accepts exact frozen view"; attribute :>> status="source-and-C-order-refinement-open"; }
part route1:SourceRoute { ref part :>> need=GambitActivationVmRouting::bindingDuty; attribute :>> sourceAnchors="setup.c:1155-1178;gambit.h.in:10325-10404"; attribute :>> projection="Prepared -> Binding(cell reserved + locator recorded) -> Bound; recover same origin serial/locator"; attribute :>> failureCustodian="VM bind journal and exact source view until final resolution"; attribute :>> status="source-and-C-order-refinement-open"; }
part route2:SourceRoute { ref part :>> need=GambitActivationVmRouting::routerDuty; attribute :>> sourceAnchors="setup.c:6240-6290,4834-4883;mem.c:4937-4988"; attribute :>> projection="Stable resident anchor checks numeric namespace before pointer read, then pins exact VM incarnation"; attribute :>> failureCustodian="Resident router cell until pin drain; logical detach is not physical free"; attribute :>> status="source-and-C-order-refinement-open"; }
part route3:SourceRoute { ref part :>> need=GambitActivationVmRouting::lifecycleDuty; attribute :>> sourceAnchors="setup.c:4834-4883,1050-1112"; attribute :>> projection="Quiescing permits exact existing status settlement while new effects are denied; old user pins recheck domain close"; attribute :>> failureCustodian="Canonical VM/source records remain until every actual completion gate closes"; attribute :>> status="source-and-C-order-refinement-open"; }
part route4:SourceRoute { ref part :>> need=GambitActivationVmRouting::teardownDuty; attribute :>> sourceAnchors="setup.c:4858-4862,942-1001"; attribute :>> projection="Pre-reserved per-VM teardown lane, authority and result storage outside ordinary W cells"; attribute :>> failureCustodian="VM administrative debt plus imported member/resource custodian"; attribute :>> status="source-and-C-order-refinement-open"; }
part route5:SourceRoute { ref part :>> need=GambitActivationVmRouting::orderDuty; attribute :>> sourceAnchors="setup.c:6240-6290;gambit.h.in:12116-12126"; attribute :>> projection="Fresh checked session on every setup attempt; failed setup burns identity; fixed routing slot reuse needs new generation"; attribute :>> failureCustodian="Resident anchor survives cleanup; remaining raw old capabilities refuse unload"; attribute :>> status="source-and-C-order-refinement-open"; }
part def DiagramNode {  attribute nodeId:String; attribute labelText:String; }
part node0:DiagramNode { attribute :>> nodeId="anchor"; attribute :>> labelText="Resident fixed VM router outside GSTATE"; }
part node1:DiagramNode { attribute :>> nodeId="setup"; attribute :>> labelText="Checked fresh setup session"; }
part node2:DiagramNode { attribute :>> nodeId="ready"; attribute :>> labelText="Fully initialized Online VM"; }
part node3:DiagramNode { attribute :>> nodeId="origin"; attribute :>> labelText="Pre-admitted base or parent origin mailbox"; }
part node4:DiagramNode { attribute :>> nodeId="bind"; attribute :>> labelText="Reserve cell and authoritative locator"; }
part node5:DiagramNode { attribute :>> nodeId="recover"; attribute :>> labelText="Lost reply reads same journal"; }
part node6:DiagramNode { attribute :>> nodeId="effect"; attribute :>> labelText="Bound activation and rechecked user effect gate"; }
part node7:DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Quiescing: status only for user requests"; }
part node8:DiagramNode { attribute :>> nodeId="admin"; attribute :>> labelText="Reserved administrative cleanup lane"; }
part node9:DiagramNode { attribute :>> nodeId="settle"; attribute :>> labelText="Child/source/result/GC readers drain"; }
part node10:DiagramNode { attribute :>> nodeId="detach"; attribute :>> labelText="Router detach; old pins retain storage"; }
part node11:DiagramNode { attribute :>> nodeId="free"; attribute :>> labelText="Physical GSTATE/VM cleanup"; }
part node12:DiagramNode { attribute :>> nodeId="restart"; attribute :>> labelText="Fresh session rejects old keys"; }
part node13:DiagramNode { attribute :>> nodeId="late"; attribute :>> labelText="Late token checked before VM dereference"; }
part def DiagramEdge { ref part producer:DiagramNode; ref part consumer:DiagramNode; attribute labelText:String; }
part edge0:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="anchor outlives every setup attempt"; }
part edge1:DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="complete staged construction"; }
part edge2:DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="bounded root/host entry permit"; }
part edge3:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="one live serial per origin"; }
part edge4:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="normal return may be lost"; }
part edge5:DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node4; attribute :>> labelText="reuse locator; never re-reserve"; }
part edge6:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node6; attribute :>> labelText="Bound before native effects"; }
part edge7:DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node7; attribute :>> labelText="cleanup closes new user effects"; }
part edge8:DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="independent of W user capacity"; }
part edge9:DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node9; attribute :>> labelText="exact source and result settlement"; }
part edge10:DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="stop/result receipt required"; }
part edge11:DiagramEdge { ref part :>> producer=node9; ref part :>> consumer=node10; attribute :>> labelText="all debts known closed"; }
part edge12:DiagramEdge { ref part :>> producer=node10; ref part :>> consumer=node11; attribute :>> labelText="only after router pins drain"; }
part edge13:DiagramEdge { ref part :>> producer=node11; ref part :>> consumer=node12; attribute :>> labelText="anchor epoch is not reset"; }
part edge14:DiagramEdge { ref part :>> producer=node12; ref part :>> consumer=node13; attribute :>> labelText="old session/slot tag rejects"; }
part edge15:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node13; attribute :>> labelText="stable gate before any VM read"; }
part def ResearchGate { attribute gateId:String; }
part def GateNeed { ref part gate:ResearchGate; ref part need:GambitAssuranceRouting::ModelNeed; }
part gateRow0:ResearchGate { attribute :>> gateId="origin-binding"; }
part gateNeed0:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::originDuty; }
part gateNeed1:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::bindingDuty; }
part gateNeed2:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::orderDuty; }
part gateNeed3:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::priorWindow; }
part gateNeed4:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::priorOom; }
part gateNeed5:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitActivationVmRouting::priorRestore; }
part gateRow1:ResearchGate { attribute :>> gateId="router-lifecycle"; }
part gateNeed6:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitActivationVmRouting::routerDuty; }
part gateNeed7:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitActivationVmRouting::lifecycleDuty; }
part gateNeed8:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitActivationVmRouting::teardownDuty; }
part gateNeed9:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitActivationVmRouting::orderDuty; }
part gateNeed10:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitActivationVmRouting::priorMembers; }
part gateRow2:ResearchGate { attribute :>> gateId="first-cut"; }
part gateNeed11:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::originDuty; }
part gateNeed12:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::bindingDuty; }
part gateNeed13:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::routerDuty; }
part gateNeed14:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::lifecycleDuty; }
part gateNeed15:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::teardownDuty; }
part gateNeed16:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::orderDuty; }
part gateNeed17:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::priorExit; }
part gateNeed18:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::priorReclaim; }
part gateNeed19:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitActivationVmRouting::priorGate; }
part def AdmissionCut { attribute phase:Integer; attribute initialized:Boolean; attribute matchingIdentity:Boolean; attribute routerReaders:Integer; attribute activeBindings:Integer; attribute adminDebt:Boolean; attribute userAllowed:Boolean=phase==2 and initialized and matchingIdentity; attribute statusAllowed:Boolean=(phase==2 or phase==3) and initialized and matchingIdentity; attribute adminAllowed:Boolean=phase==3 and initialized and matchingIdentity and adminDebt; attribute canDetach:Boolean=phase==3 and activeBindings==0 and not adminDebt; attribute canFree:Boolean=phase==4 and routerReaders==0 and activeBindings==0 and not adminDebt; attribute extraHistoryMaps:Integer=0; }
part online:AdmissionCut { attribute :>> phase=2; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=0; attribute :>> activeBindings=1; attribute :>> adminDebt=true; }
part oldToken:AdmissionCut { attribute :>> phase=2; attribute :>> initialized=true; attribute :>> matchingIdentity=false; attribute :>> routerReaders=0; attribute :>> activeBindings=1; attribute :>> adminDebt=true; }
part closingUser:AdmissionCut { attribute :>> phase=3; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=1; attribute :>> activeBindings=1; attribute :>> adminDebt=true; }
part statusDrain:AdmissionCut { attribute :>> phase=3; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=0; attribute :>> activeBindings=1; attribute :>> adminDebt=false; }
part detachReady:AdmissionCut { attribute :>> phase=3; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=0; attribute :>> activeBindings=0; attribute :>> adminDebt=false; }
part readerPinned:AdmissionCut { attribute :>> phase=4; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=1; attribute :>> activeBindings=0; attribute :>> adminDebt=false; }
part freeReady:AdmissionCut { attribute :>> phase=4; attribute :>> initialized=true; attribute :>> matchingIdentity=true; attribute :>> routerReaders=0; attribute :>> activeBindings=0; attribute :>> adminDebt=false; }
part def ControlCapacity { attribute vmSlots:Integer; attribute baseOrigins:Integer; attribute activationCells:Integer; attribute rootJournals:Integer=baseOrigins; attribute embeddedChildJournals:Integer=activationCells; attribute adminCells:Integer=vmSlots; attribute separateHistoryMaps:Integer=0; attribute postBindControlAllocations:Integer=0; }
part finite:ControlCapacity { attribute :>> vmSlots=1; attribute :>> baseOrigins=1; attribute :>> activationCells=2; }
part broader:ControlCapacity { attribute :>> vmSlots=2; attribute :>> baseOrigins=8; attribute :>> activationCells=64; }
}
