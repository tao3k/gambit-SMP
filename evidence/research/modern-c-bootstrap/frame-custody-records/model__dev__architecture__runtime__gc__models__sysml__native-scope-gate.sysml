/* MC-SCOPE concrete source protocol; activation/GC source refinements remain open. */
package GambitNativeScopeGate { private import ScalarValues::*;
part history:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-H";
attribute :>> kind="interleaving";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/quint/native_scope_gate.qnt";
attribute :>> subjectScope="native_scope_gate:one-record-eight-roles-three-generations;seed17";
attribute :>> premise="Exact header tuple read/CAS, close race, spent roles, late CAS and old release; role/actor assignment, VM lifetime and last-write release external; finite sampling not native proof.";
}
part induction:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-I";
attribute :>> kind="induction";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="GambitSMP.NativeScopeGate:conditional-tag-permit-and-drain-laws";
attribute :>> premise="Selective gate closure, spent-role, idempotent release, generation identity and writer coverage laws; not complete QNT/C induction.";
}
part lastUse:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-LAST";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-LAST:all-source-last-write-and-borrow-release";
attribute :>> premise="Future generated SFUN/CFUN/catcher and thread exit must settle exact last writes, borrows and cleanup debt before releasing roles; present first patch adds no such callers.";
}
part identity:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-ID";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-ID:exclusive-resident-actor-role-and-prepared-intent";
attribute :>> premise="Candidates pre-recorded before CAS; bounded exclusive actors 1..255 and one producer per role; no processor-id shortcut or destroyed-VM query. Identity allocator and result journal are not implemented here.";
}
part casDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-CAS";
attribute :>> kind="native-memory-order";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-CAS:packed-word-encoding-and-C-backend-refinement";
attribute :>> premise="Full header CAS contains tag, closed, spent/live bits; source uses existing full-barrier backend. Encoding injectivity, emulation/platform ordering and compiler qualification remain open; sequential backend only without sharing.";
}
part vmDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-VM";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-VM:exclusive-init-and-storage-borrow-before-cleanup";
attribute :>> premise="64 fixed VM records initialize before processor exposure. No Scheme payload/root scanning. All access requires live VM storage borrow; cleanup/router drain and repeated setup lifetime are separate gates.";
}
part activation:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-ACT";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-ACT:connected-managed-activation-not-enabled";
attribute :>> premise="First patch installs source primitive/build/test target and VM initialization only. Marker pre-root, nonzero processor root scan, generated exit funnel and lifecycle closure precede activation of managed callers.";
}
part lifeTarget:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-LIFECYCLE";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-LIFECYCLE:patched-baseline-to-transactional-member-lifecycle";
attribute :>> premise="Inherit 8/12 repairs. Replace constructor/rollback/pending join/old-handler custody with canonical membership transactions and real stop/drain receipts. MC-SCOPE is necessary authority support, not native recovery evidence.";
}
part gcTarget:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-GCFFI";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-GCFFI:precise-roots-entry-construction-and-GC-participation";
attribute :>> premise="RootRegistry/FrameSpec, marker-before-allocation root protection, typed constructor publication and participating native entry must replace actual implicit consumers. C gate has no Scheme root fields and proves none of this.";
}
part gerbilTarget:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-GERBIL";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-GERBIL:causal-invalid-structure-repair-and-whole-consumer";
attribute :>> premise="Existing stdlib invalid type read has unresolved corruption/structure/error-reporting alternatives. Trace concrete producer and root/writer violation before selecting a repair; stable native scope alone cannot prove cause or cure.";
}
part perfTarget:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="NS-PERF";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="dev/architecture/runtime/gc/models/lean/NativeScopeGate.lean";
attribute :>> subjectScope="NS-PERF:matched-whole-producer-cost-and-build-latency";
attribute :>> premise="Numerical generated-C compile deadline and release latency/build consumers need separate compiler/build/runtime work decomposition and matched unchanged gates. No causal dependency from a passing gate primitive to faster compilation.";
}
ref part priorStop=GambitWriterStopHandoff::helperDuty;
ref part priorRoot=GambitOriginBindCommit::rootDuty;
ref part priorOrder=GambitWriterStopHandoff::orderDuty;
part dependency0:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lastUse; ref part :>> prerequisite=history; }
part dependency1:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lastUse; ref part :>> prerequisite=induction; }
part dependency2:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=history; }
part dependency3:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=induction; }
part dependency4:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=casDuty; ref part :>> prerequisite=history; }
part dependency5:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=casDuty; ref part :>> prerequisite=induction; }
part dependency6:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=vmDuty; ref part :>> prerequisite=history; }
part dependency7:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=vmDuty; ref part :>> prerequisite=induction; }
part dependency8:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=history; }
part dependency9:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=induction; }
part dependency10:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=lastUse; }
part dependency11:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=identity; }
part dependency12:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=casDuty; }
part dependency13:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=vmDuty; }
part dependency14:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=priorStop; }
part dependency15:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=activation; ref part :>> prerequisite=priorRoot; }
part dependency16:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=casDuty; ref part :>> prerequisite=priorOrder; }
part dependency17:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifeTarget; ref part :>> prerequisite=activation; }
part dependency18:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gcTarget; ref part :>> prerequisite=activation; }
part def CallerRow {  attribute callerId:String; attribute sourceAnchors:String; attribute actualChain:String; attribute hazard:String; attribute replacement:String; }
part caller0:CallerRow { attribute :>> callerId="INITIALIZATION"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate"; attribute :>> actualChain="Calls native_scope_init_vmstate before processor_count/publication"; attribute :>> hazard="Implemented, no Scheme evaluation/allocation"; attribute :>> replacement="Concurrent reset and storage lifetime not permitted"; }
part caller1:CallerRow { attribute :>> callerId="GATE"; attribute :>> sourceAnchors="vendor/gambit/lib/native_scope.c;lib/native_scope.h"; attribute :>> actualChain="One word owns generation/actor, close, used/live bits; eight roles"; attribute :>> hazard="Implemented internal protocol; role never reused within generation"; attribute :>> replacement="Caller must hold VM storage and exclusive actor/role ownership"; }
part caller2:CallerRow { attribute :>> callerId="GENERATOR"; attribute :>> sourceAnchors="vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251"; attribute :>> actualChain="Cleanup selected by conversion types"; attribute :>> hazard="Future complete effect scope and stable journal before callback/marker"; attribute :>> replacement="No generated activation switch in first patch"; }
part caller3:CallerRow { attribute :>> callerId="CATCHER"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY"; attribute :>> actualChain="call can rethrow past normal marker kill"; attribute :>> hazard="Future exact-activation post-catcher last-use funnel"; attribute :>> replacement="Exit observation is not permit-release authority"; }
part caller4:CallerRow { attribute :>> callerId="THREAD"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit"; attribute :>> actualChain="Cleanup before exit; shrink ignores join result"; attribute :>> hazard="Future VM custody and verified stop/borrower drain"; attribute :>> replacement="No forced release on join failure/unknown"; }
part caller5:CallerRow { attribute :>> callerId="PATCHED-SFUN-ADMISSION"; attribute :>> sourceAnchors="patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> actualChain="Existing repair already uses a full-word VM gate CAS and PSTATE frame count"; attribute :>> hazard="New record adds per-activation actor/generation and split spent/live writer roles; it does not repair a missing CAS in that existing gate"; attribute :>> replacement="Old VM admission cannot retire until canonical VM epoch admission covers scope creation and all old readers; no permanent double tracking"; }
part def OrderRow {  attribute edgeId:String; attribute orderContract:String; attribute rejectedShortcut:String; }
part orderRow0:OrderRow { attribute :>> edgeId="ACQUIRE"; attribute :>> orderContract="Read full packed header; CAS exact word sets used and live together"; attribute :>> rejectedShortcut="No open-check/increment gap; failed CAS must retry full checks"; }
part orderRow1:OrderRow { attribute :>> edgeId="CLOSE"; attribute :>> orderContract="CAS closed in same word; earlier permits survive until real release"; attribute :>> rejectedShortcut="Close does not kill a native writer"; }
part orderRow2:OrderRow { attribute :>> edgeId="RELEASE"; attribute :>> orderContract="After last real store/borrow, CAS clears only role live bit and keeps used"; attribute :>> rejectedShortcut="Duplicate release cannot affect another role or a reused generation"; }
part orderRow3:OrderRow { attribute :>> edgeId="HANDOFF"; attribute :>> orderContract="CAS only on closed header with all live bits empty; increments checked generation and installs both owner permits"; attribute :>> rejectedShortcut="Tag includes actor, so competing candidates differ; missing reply never leaves an uncounted owner"; }
part orderRow4:OrderRow { attribute :>> edgeId="LOAD"; attribute :>> orderContract="Existing backend uses full-barrier RMW for snapshot and CAS for mutation"; attribute :>> rejectedShortcut="Snapshot/query causes cache-line traffic; no free acquire-load claim"; }
part def CostRow {  attribute capability:String; attribute removedWork:String; attribute bound:String; attribute addedCost:String; attribute condition:String; }
part cost0:CostRow { attribute :>> capability="Fixed record layout"; attribute :>> removedWork="One word per record, 64 VM slots"; attribute :>> bound="32-bit=256 bytes;64-bit=512 bytes, excludes existing VM padding effects"; attribute :>> addedCost="No dynamic allocation/GC pointers in this support"; attribute :>> condition="Size is layout arithmetic and compiler syntax evidence, not measured runtime peak"; }
part cost1:CostRow { attribute :>> capability="Permit lifecycle"; attribute :>> removedWork="Four control and four data roles; owner uses one of each"; attribute :>> bound="At most three delegates per class/generation; spent roles refuse reuse"; attribute :>> addedCost="Capacity refusal is explicit; future caller must reserve enough roles"; attribute :>> condition="Removing spent bits reintroduces duplicate-release ABA"; }
part cost2:CostRow { attribute :>> capability="Generation"; attribute :>> removedWork="25 low/actor bits and sign bit reserved"; attribute :>> bound="32-bit max63;64-bit max274877906943; exhaustion refuses"; attribute :>> addedCost="No wrapping, no historical identity map; live VM-borrow prerequisite"; attribute :>> condition="Not a destroyed-VM routing or arbitrary async-death solution"; }
part cost3:CostRow { attribute :>> capability="Atomic work"; attribute :>> removedWork="Uncontended acquire/close/release/handoff: one RMW read plus one CAS"; attribute :>> bound="Duplicate/stale query still performs RMW read; retry count unbounded"; attribute :>> addedCost="Full-barrier and cache-line contention costs; no starvation bound"; attribute :>> condition="A later C11 backend may optimize after independent memory-order proof"; }
part cost4:CostRow { attribute :>> capability="GC/peak benefit"; attribute :>> removedWork="This primitive stores zero Scheme root words"; attribute :>> bound="Zero old GC/marker/catcher paths retired; added VM budget256/512 bytes"; attribute :>> addedCost="Unknown permits retain custody; frozen-root adapter still needed"; attribute :>> condition="No whole-round peak reduction or GC speedup established"; }
part cost5:CostRow { attribute :>> capability="First source patch"; attribute :>> removedWork="New native_scope.c/.h, VM field/init, build and test target"; attribute :>> bound="Actual C code committed on modern-c; controls compiled/linked, not run"; attribute :>> addedCost="ABI rebuild required; multi-VM baseline source failure retained"; attribute :>> condition="Generated activation enablement awaits all source/C/native gates"; }
part def LayoutField {  attribute fieldId:String; attribute encoding:String; attribute contract:String; }
part field0:LayoutField { attribute :>> fieldId="gate"; attribute :>> encoding="signed WORD accessed by backend atomic RMW/CAS"; attribute :>> contract="One word, all tags nonnegative; volatile alone is not synchronization"; }
part field1:LayoutField { attribute :>> fieldId="closed"; attribute :>> encoding="bit0"; attribute :>> contract="No future registered permit acquisition after successful close CAS"; }
part field2:LayoutField { attribute :>> fieldId="live"; attribute :>> encoding="bits1..8"; attribute :>> contract="Outstanding permit roles; only exact producer last-use may clear"; }
part field3:LayoutField { attribute :>> fieldId="used"; attribute :>> encoding="bits9..16"; attribute :>> contract="Monotone per generation; prevents same-role reuse after release"; }
part field4:LayoutField { attribute :>> fieldId="actor"; attribute :>> encoding="bits17..24"; attribute :>> contract="Exclusive pre-registered activation identity1..255; no processor-id inference"; }
part field5:LayoutField { attribute :>> fieldId="generation"; attribute :>> encoding="bits25..WORD_WIDTH-2"; attribute :>> contract="Checked increment, never wrap; high sign bit stays zero"; }
part field6:LayoutField { attribute :>> fieldId="VM-array"; attribute :>> encoding="64 records by default"; attribute :>> contract="Exclusive init before publication; pointers do not extend VM lifetime"; }
part def Transition { ref part need:GambitAssuranceRouting::ModelNeed; attribute fromPhase:String; attribute toPhase:String; attribute qntStep:String; attribute guardContract:String; attribute leanLaw:String; attribute sourceAnchors:String; }
part transition0:Transition { ref part :>> need=casDuty; attribute :>> fromPhase="OpenSnapshot"; attribute :>> toPhase="ClosedHeader"; attribute :>> qntStep="readAcquire / close / failedCas"; attribute :>> guardContract="CAS compares all header fields; stale read cannot acquire"; attribute :>> leanLaw="closeRejectsAcquisition"; attribute :>> sourceAnchors="native_scope.c:try_acquire/close"; }
part transition1:Transition { ref part :>> need=lastUse; attribute :>> fromPhase="LiveRole"; attribute :>> toPhase="SpentRole"; attribute :>> qntStep="release"; attribute :>> guardContract="Release after actual last use; used bit remains set"; attribute :>> leanLaw="releaseIsIdempotent"; attribute :>> sourceAnchors="native_scope.c:release"; }
part transition2:Transition { ref part :>> need=casDuty; attribute :>> fromPhase="DrainedClosed"; attribute :>> toPhase="NextOwnerAccounted"; attribute :>> qntStep="take"; attribute :>> guardContract="Full-header CAS; checked generation; both owner class bits live"; attribute :>> leanLaw="newOwnerDataAccounted"; attribute :>> sourceAnchors="native_scope.c:try_handoff"; }
part transition3:Transition { ref part :>> need=identity; attribute :>> fromPhase="OldTag"; attribute :>> toPhase="NewGeneration"; attribute :>> qntStep="staleRelease"; attribute :>> guardContract="Old generation/actor cannot alter new helper live bits"; attribute :>> leanLaw="staleReleaseIsNoop"; attribute :>> sourceAnchors="native_scope.c:release"; }
part transition4:Transition { ref part :>> need=vmDuty; attribute :>> fromPhase="UnpublishedVm"; attribute :>> toPhase="InitializedEmptyRecords"; attribute :>> qntStep="init"; attribute :>> guardContract="Storage exclusive and initialized before first use"; attribute :>> leanLaw="advanceHasCoverage"; attribute :>> sourceAnchors="setup.c:setup_vmstate"; }
part def SourceRoute { ref part need:GambitAssuranceRouting::ModelNeed; attribute sourceAnchors:String; attribute projection:String; attribute failureCustodian:String; attribute status:String; }
part route0:SourceRoute { ref part :>> need=lastUse; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Future generated SFUN/CFUN/catcher and thread exit must settle exact last writes, borrows and cleanup debt before releasing roles; present first patch adds no such callers."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route1:SourceRoute { ref part :>> need=identity; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Candidates pre-recorded before CAS; bounded exclusive actors 1..255 and one producer per role; no processor-id shortcut or destroyed-VM query. Identity allocator and result journal are not implemented here."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route2:SourceRoute { ref part :>> need=casDuty; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Full header CAS contains tag, closed, spent/live bits; source uses existing full-barrier backend. Encoding injectivity, emulation/platform ordering and compiler qualification remain open; sequential backend only without sharing."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route3:SourceRoute { ref part :>> need=vmDuty; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="64 fixed VM records initialize before processor exposure. No Scheme payload/root scanning. All access requires live VM storage borrow; cleanup/router drain and repeated setup lifetime are separate gates."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route4:SourceRoute { ref part :>> need=activation; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="First patch installs source primitive/build/test target and VM initialization only. Marker pre-root, nonzero processor root scan, generated exit funnel and lifecycle closure precede activation of managed callers."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route5:SourceRoute { ref part :>> need=lifeTarget; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Inherit 8/12 repairs. Replace constructor/rollback/pending join/old-handler custody with canonical membership transactions and real stop/drain receipts. MC-SCOPE is necessary authority support, not native recovery evidence."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route6:SourceRoute { ref part :>> need=gcTarget; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="RootRegistry/FrameSpec, marker-before-allocation root protection, typed constructor publication and participating native entry must replace actual implicit consumers. C gate has no Scheme root fields and proves none of this."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route7:SourceRoute { ref part :>> need=gerbilTarget; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Existing stdlib invalid type read has unresolved corruption/structure/error-reporting alternatives. Trace concrete producer and root/writer violation before selecting a repair; stable native scope alone cannot prove cause or cure."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part route8:SourceRoute { ref part :>> need=perfTarget; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:setup_vmstate; vendor/gambit/lib/native_scope.c;lib/native_scope.h; vendor/gambit/gsc/_ptree2.scm:2902-2925,3238-3251; vendor/gambit/lib/setup.c:call,run,propagate_error;include/gambit.h.in:BEGIN_TRY/END_TRY; vendor/gambit/lib/setup.c:resize;lib/os_thread.c:thread_join,thread_exit; patches/fixtures/runtime-mutex-return-cumulative.patch:___sfun_frame_enter/leave"; attribute :>> projection="Numerical generated-C compile deadline and release latency/build consumers need separate compiler/build/runtime work decomposition and matched unchanged gates. No causal dependency from a passing gate primitive to faster compilation."; attribute :>> failureCustodian="Live VM storage and canonical external source/result journal; unknown permit remains live"; attribute :>> status="OPEN: source/C/native refinement"; }
part def DiagramNode {  attribute nodeId:String; attribute labelText:String; }
part node0:DiagramNode { attribute :>> nodeId="layout"; attribute :>> labelText="VM fixed records initialized before exposure"; }
part node1:DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Stable prepared actor candidate"; }
part node2:DiagramNode { attribute :>> nodeId="cas"; attribute :>> labelText="Single full-header handoff CAS"; }
part node3:DiagramNode { attribute :>> nodeId="owner"; attribute :>> labelText="New owner control and data permits live"; }
part node4:DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Close CAS rejects later acquisitions"; }
part node5:DiagramNode { attribute :>> nodeId="drain"; attribute :>> labelText="Real last-use release; spent bits retained"; }
part node6:DiagramNode { attribute :>> nodeId="next"; attribute :>> labelText="Drained closed header; next checked generation"; }
part node7:DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown writer stays live; no forced release"; }
part node8:DiagramNode { attribute :>> nodeId="future"; attribute :>> labelText="Future generator catcher thread last-use adapters"; }
part def DiagramEdge { ref part producer:DiagramNode; ref part consumer:DiagramNode; attribute labelText:String; }
part edge0:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="live VM storage required"; }
part edge1:DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="candidate retained before effect"; }
part edge2:DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="no unaccounted reply gap"; }
part edge3:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="exact-generation close"; }
part edge4:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="existing permits survive"; }
part edge5:DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="all roles drained"; }
part edge6:DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node1; attribute :>> labelText="helper can interrupt again"; }
part edge7:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node7; attribute :>> labelText="failed join or unknown store"; }
part edge8:DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node5; attribute :>> labelText="not enabled in first patch"; }
part def ResearchGate { attribute gateId:String; }
part def GateNeed { ref part gate:ResearchGate; ref part need:GambitAssuranceRouting::ModelNeed; }
part gateRow0:ResearchGate { attribute :>> gateId="source-protocol"; }
part gateNeed0:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=history; }
part gateNeed1:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=induction; }
part gateNeed2:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=casDuty; }
part gateNeed3:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=identity; }
part gateNeed4:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=vmDuty; }
part gateRow1:ResearchGate { attribute :>> gateId="managed-activation"; }
part gateNeed5:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=lastUse; }
part gateNeed6:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=identity; }
part gateNeed7:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=casDuty; }
part gateNeed8:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=vmDuty; }
part gateNeed9:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=activation; }
part gateNeed10:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=priorStop; }
part gateNeed11:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=priorRoot; }
part gateNeed12:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=priorOrder; }
part def Layout { attribute wordBytes:Integer; attribute capacity:Integer=64; attribute actorBits:Integer=8; attribute roleCount:Integer=8; attribute ownerRoles:Integer=2; attribute generationBits:Integer; attribute maxGeneration:Integer; attribute vmBytes:Integer=wordBytes*capacity; }
part narrow:Layout { attribute :>> wordBytes=4; attribute :>> generationBits=6; attribute :>> maxGeneration=63; }
part wide:Layout { attribute :>> wordBytes=8; attribute :>> generationBits=38; attribute :>> maxGeneration=274877906943; }
part def MilestoneTarget { ref part need:GambitAssuranceRouting::ModelNeed; attribute milestoneId:String; attribute currentEvidence:String; attribute replacement:String; attribute retirement:String; attribute boundary:String; }
part target0:MilestoneTarget { ref part :>> need=lifeTarget; attribute :>> milestoneId="lifecycle-failure-rollback"; attribute :>> currentEvidence="8/12 retained audit: actual pending/sticky joins and constructor retry pass; natural error-then-success join and old unadmitted-handler quiescence open"; attribute :>> replacement="Transactional VM/member lifecycle + explicit actor/borrower closure; retained cleanup as owned result"; attribute :>> retirement="All root/resource owners transfer before PSTATE destruction; genuine recovery and full failure inventory pass"; attribute :>> boundary="MC-SCOPE prevents registered late writes; it cannot prove physical stop or register unknown handlers"; }
part target1:MilestoneTarget { ref part :>> need=gcTarget; attribute :>> milestoneId="complete-gc-ffi"; attribute :>> currentEvidence="Official GC/FFI selected targets pass in retained successor; whole changed-producer inventory remains open"; attribute :>> replacement="Precise FrameSpec roots + RootRegistry + typed construction + native GC participation, then generational barrier architecture"; attribute :>> retirement="Switch all frame/root/FFI writers and retire old implicit ownership only after exact-source complete acceptance"; attribute :>> boundary="Permit gate has zero GC root payload; source-adapter work is mandatory"; }
part target2:MilestoneTarget { ref part :>> need=gerbilTarget; attribute :>> milestoneId="gerbil-correctness"; attribute :>> currentEvidence="stage0/stage1 pass; stdlib type-field fault remains; origin not established"; attribute :>> replacement="Source-causal object/continuation/FFI ownership diagnosis; repair proven producer rather than hide bad TYPEID read"; attribute :>> retirement="Actual downstream stdlib/libgerbil/lang/tools and complete tests on same candidate"; attribute :>> boundary="Not every Gerbil crash is a GC/SMP root defect; preserve alternate causes"; }
part target3:MilestoneTarget { ref part :>> need=perfTarget; attribute :>> milestoneId="release-performance"; attribute :>> currentEvidence="Numerical generated C about5.54MB and8008 labels recorded; compiled deadline and release gates open"; attribute :>> replacement="Modern generated C contracts + smaller correct units/dynamic-dependency snapshots/AOT reuse; runtime work and memory counted separately"; attribute :>> retirement="Unchanged numerical cap and matched whole-producer latency/build/test populations qualify; retire redundant expansion/compilation only when equivalent"; attribute :>> boundary="No modeled CAS safety or language change implies compiler/whole-build speedup"; }
}
