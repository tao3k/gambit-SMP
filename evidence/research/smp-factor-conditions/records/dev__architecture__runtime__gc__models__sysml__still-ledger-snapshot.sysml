/* Modern C target. Schema validation is not native qualification. */
package GambitStillLedgerSnapshot {
 private import ScalarValues::*;
 part def InventoryState { attribute publishedWords : Integer; attribute privateWords : Integer; attribute retiredHeldWords : Integer; attribute unbackedGrantWords : Integer; attribute capacityCharge : Integer; }
 requirement def InventoryLaw { subject i : InventoryState; require constraint { i.publishedWords>=0 and i.privateWords>=0 and i.retiredHeldWords>=0 and i.unbackedGrantWords>=0 and i.capacityCharge==i.publishedWords+i.privateWords+i.retiredHeldWords+i.unbackedGrantWords } }
 part def SnapshotState { attribute commitAllowed : Boolean; attribute ownerGenerationMatches : Boolean; attribute inventoryRevisionMatches : Boolean; attribute rootEpochMatches : Boolean; attribute ledgerRevisionMatches : Boolean; attribute nativeMutationClosed : Boolean; attribute admissionGateHeld : Boolean; }
 requirement def SnapshotLaw { subject s : SnapshotState; require constraint { not s.commitAllowed or (s.ownerGenerationMatches and s.inventoryRevisionMatches and s.rootEpochMatches and s.ledgerRevisionMatches and s.nativeMutationClosed and s.admissionGateHeld) } }
 part def ReclaimState { attribute creditAllowed : Boolean; attribute uniqueIntent : Boolean; attribute noBlockFailureKnown : Boolean; attribute physicalFreeAcknowledged : Boolean; attribute rawBorrowersClosed : Boolean; attribute nativeOutcomeKnown : Boolean; }
 requirement def ReclaimLaw { subject r : ReclaimState; require constraint { not r.creditAllowed or (r.uniqueIntent and r.rawBorrowersClosed and r.nativeOutcomeKnown and (r.noBlockFailureKnown or r.physicalFreeAcknowledged)) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_ledger_snapshot.qnt";
 attribute :>> subjectScope="still_ledger_snapshot:30-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Two two-word blocks/one intent, private publication, revision-bound handoff, mark/sweep/free and metadata/raw pins; allocation outcome witnesses are premises; no native liveness";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillLedgerSnapshot.lean";
 attribute :>> subjectScope="GambitSMP.StillLedgerSnapshot:physicalBound;attachConserves;publishConserves;retireConserves;retireIsNotFree;countersNotInjective;noCounterOnlyDecoder;staleRejected;mutationRejected;ownerOnlyChange;revisionAdvanceInvalidates;refundStepConserves;refundTraceConserves;emptyGrantCannotCredit;nativeExtentIncludesPadding;logicalRetirementPeak";
 attribute :>> premise="16 conditional statements including refund Step/Trace conservation and a noninjective legacy-counter witness; no C refinement or whole QNT induction";
 }
 part inventory : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-INVENTORY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillLedgerSnapshot.lean";
 attribute :>> subjectScope="LS-INVENTORY:actual-source-refinement";
 attribute :>> premise="Adopt only a closed valid inventory plus reservation/private/retired ledger; live/deferred/VM counters are not sufficient at arbitrary cuts; distinguish logical words, aligned allocator request bytes and unknown RSS";
 }
 part intent : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-INTENT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillLedgerSnapshot.lean";
 attribute :>> subjectScope="LS-INTENT:actual-source-refinement";
 attribute :>> premise="Pre-register one exact allocation intent and extent; preserve unknown malloc/free outcomes and capacity custody; refund only unique no-block/closed-call evidence, not stop alone or timeout";
 }
 part viewCut : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-SNAPSHOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillLedgerSnapshot.lean";
 attribute :>> subjectScope="LS-SNAPSHOT:actual-source-refinement";
 attribute :>> premise="Commit compares owner generation and inventory/root/ledger revisions under one admission gate; canonical mark authority unchanged; sweep/list/accounting mutation excludes commit and invalidates prepared views";
 }
 part reclaim : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="LS-RECLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillLedgerSnapshot.lean";
 attribute :>> subjectScope="LS-RECLAIM:actual-source-refinement";
 attribute :>> premise="Logical retirement retains held-block charge until backend-specific physical free acknowledgement; void code-free return discards munmap/VirtualFree status; metadata snapshots grant no payload authority; raw users/root and scan writers close first; foreign release and native allocator integrity remain explicit";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inventory; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inventory; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inventory; ref part :>> prerequisite=GambitStillAuthorityHandoff::closure; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inventory; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inventory; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=inventory; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=GambitStillOwnerRetirement::stop; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=GambitStillInitRecovery::progress; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=GambitRuntimeAssurance::work.source; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=inventory; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=intent; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=GambitGenerationalBarrier::scanCut; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=viewCut; ref part :>> prerequisite=GambitStillAuthorityHandoff::closure; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=viewCut; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=GambitRuntimeAssurance::release.source; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=GambitHostRootsRefinement::exitState; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillAuthorityHandoff::chain; ref part :>> prerequisite=inventory; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillAuthorityHandoff::chain; ref part :>> prerequisite=viewCut; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillAuthorityHandoff::admission; ref part :>> prerequisite=intent; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillAuthorityHandoff::admission; ref part :>> prerequisite=reclaim; }
 part inventoryRoute : GambitHostRootsRefinement::Route { ref part :>> need=inventory;
 attribute :>> sourceAnchors="lib/mem.c:300-306,360-371,486-499,516-534,554-599,657-667,1556-1708,4222-4245,4387-4456,6256-6293,6300-6505,6775-6805,6910-6937,7000-7049;lib/os_base.c:321-415,445-518;lib/setup.c:903-978,4572-4580,4665-4672;lib/c_intf.c:1683-1711";
 attribute :>> patchAnchors="Base vendor and retained cumulative fixture; no runtime patch or native test";
 attribute :>> projection="Adopt only a closed valid inventory plus reservation/private/retired ledger; live/deferred/VM counters are not sufficient at arbitrary cuts; distinguish logical words, aligned allocator request bytes and unknown RSS";
 attribute :>> failureCustodian="Canonical domain/intent service retains grants, private backing, retired blocks and immutable metadata; unknown raw allocator/free outcome cannot issue refund or cleanup authority";
 attribute :>> status="selected-callers-and-phase-cuts-known-C-and-allocator-refinement-open";
 }
 part intentRoute : GambitHostRootsRefinement::Route { ref part :>> need=intent;
 attribute :>> sourceAnchors="lib/mem.c:300-306,360-371,486-499,516-534,554-599,657-667,1556-1708,4222-4245,4387-4456,6256-6293,6300-6505,6775-6805,6910-6937,7000-7049;lib/os_base.c:321-415,445-518;lib/setup.c:903-978,4572-4580,4665-4672;lib/c_intf.c:1683-1711";
 attribute :>> patchAnchors="Base vendor and retained cumulative fixture; no runtime patch or native test";
 attribute :>> projection="Pre-register one exact allocation intent and extent; preserve unknown malloc/free outcomes and capacity custody; refund only unique no-block/closed-call evidence, not stop alone or timeout";
 attribute :>> failureCustodian="Canonical domain/intent service retains grants, private backing, retired blocks and immutable metadata; unknown raw allocator/free outcome cannot issue refund or cleanup authority";
 attribute :>> status="selected-callers-and-phase-cuts-known-C-and-allocator-refinement-open";
 }
 part viewCutRoute : GambitHostRootsRefinement::Route { ref part :>> need=viewCut;
 attribute :>> sourceAnchors="lib/mem.c:300-306,360-371,486-499,516-534,554-599,657-667,1556-1708,4222-4245,4387-4456,6256-6293,6300-6505,6775-6805,6910-6937,7000-7049;lib/os_base.c:321-415,445-518;lib/setup.c:903-978,4572-4580,4665-4672;lib/c_intf.c:1683-1711";
 attribute :>> patchAnchors="Base vendor and retained cumulative fixture; no runtime patch or native test";
 attribute :>> projection="Commit compares owner generation and inventory/root/ledger revisions under one admission gate; canonical mark authority unchanged; sweep/list/accounting mutation excludes commit and invalidates prepared views";
 attribute :>> failureCustodian="Canonical domain/intent service retains grants, private backing, retired blocks and immutable metadata; unknown raw allocator/free outcome cannot issue refund or cleanup authority";
 attribute :>> status="selected-callers-and-phase-cuts-known-C-and-allocator-refinement-open";
 }
 part reclaimRoute : GambitHostRootsRefinement::Route { ref part :>> need=reclaim;
 attribute :>> sourceAnchors="lib/mem.c:300-306,360-371,486-499,516-534,554-599,657-667,1556-1708,4222-4245,4387-4456,6256-6293,6300-6505,6775-6805,6910-6937,7000-7049;lib/os_base.c:321-415,445-518;lib/setup.c:903-978,4572-4580,4665-4672;lib/c_intf.c:1683-1711";
 attribute :>> patchAnchors="Base vendor and retained cumulative fixture; no runtime patch or native test";
 attribute :>> projection="Logical retirement retains held-block charge until backend-specific physical free acknowledgement; void code-free return discards munmap/VirtualFree status; metadata snapshots grant no payload authority; raw users/root and scan writers close first; foreign release and native allocator integrity remain explicit";
 attribute :>> failureCustodian="Canonical domain/intent service retains grants, private backing, retired blocks and immutable metadata; unknown raw allocator/free outcome cannot issue refund or cleanup authority";
 attribute :>> status="selected-callers-and-phase-cuts-known-C-and-allocator-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="small-still";
 attribute :>> sourceAnchors="mem.c:1571-1605";
 attribute :>> actualChain="Physical aligned allocation -> deferred counter -> chain link/header";
 attribute :>> hazard="Successful raw pointer can precede a counter/list record; counters alone cannot find it";
 attribute :>> replacement="Legacy adoption drains active allocators; future managed intent owns private allocation before exposure";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="large-still";
 attribute :>> sourceAnchors="mem.c:1610-1675";
 attribute :>> actualChain="Charge requested+deferred under VM lock -> allocator -> subtract only new words on failure";
 attribute :>> hazard="A reservation is not physical residency; old deferred objects remain charged on failure";
 attribute :>> replacement="Per-intent outcome/rollback token; do not refund prior deferred cohort";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="gc-request";
 attribute :>> sourceAnchors="mem.c:6300-6505;setup.c:903-916";
 attribute :>> actualChain="resize_heap recount -> pretend request live -> overflow rollback/zero -> retry";
 attribute :>> hazard="Temporary requested words affect capacity but do not denote a published block";
 attribute :>> replacement="Capture accounting phase and request settlement; no duplicate physical inventory item";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="scan-and-sweep";
 attribute :>> sourceAnchors="mem.c:4222-4245,4387-4427,6910-6937,7000-7049";
 attribute :>> actualChain="Mark refcounts/roots -> sweep/relink/free -> barrier -> resize recount";
 attribute :>> hazard="A list/live-counter read across sweep is not a single snapshot";
 attribute :>> replacement="Canonical epoch grants; revision-bound inventory and immutable ledger publication; stale commit refuses";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="recount-consumer";
 attribute :>> sourceAnchors="mem.c:6256-6293,360-371,486-499";
 attribute :>> actualChain="Sum per-processor live still totals; capacity and allocation-stat consumers";
 attribute :>> hazard="Live/deferred/global counts have phase-specific meanings; allocation stats are not physical extent";
 attribute :>> replacement="Replace processor-only census with canonical domains once; retain phase statistics separately";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="aligned-backing";
 attribute :>> sourceAnchors="mem.c:554-599,657-667;os_base.c:321-415,445-518";
 attribute :>> actualChain="Alignment-layer request -> heap wrapper (normal/code allocator) -> original container free";
 attribute :>> hazard="STILL_LENGTH omits alignment/container overhead; C free is not RSS release";
 attribute :>> replacement="Record checked requested byte extent and raw container identity; allocator/RSS remain separately bounded";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="foreign-free";
 attribute :>> sourceAnchors="mem.c:4398-4406,4442-4448;c_intf.c:1683-1711";
 attribute :>> actualChain="release_fn can execute native code before physical free";
 attribute :>> hazard="Destructor/allocator integrity is independent; void code-free wrappers discard backend return status";
 attribute :>> replacement="Explicit release receipt and allowed executor; unresolved free never retried from timeout";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="retirement";
 attribute :>> sourceAnchors="setup.c:903-978,4572-4580,4665-4672;mem.c:4928-4935";
 attribute :>> actualChain="PSTATE cleanup currently frees all still backing before native join";
 attribute :>> hazard="A copied counter/root cannot resurrect a destroyed chain or unknown private allocation";
 attribute :>> replacement="Adoption/commit precedes cleanup; old readers receive metadata-only capability or retain raw borrow debt";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="legacy reconstruction";
 attribute :>> removedWork="Obtain a truthful adoption cut instead of copying ambiguous counters";
 attribute :>> bound="O(N+I) inventory/intent audit at cut; legacy I must drain to known outcomes because existing malloc has no keyed query";
 attribute :>> addedCost="One-time block walk, checked extent reconstruction, allocator and scanner closure";
 attribute :>> condition="Current sweep already accumulates live lengths: zero extra current full-chain recount passes proved removable";
 }
 part cost1 : CostRow {
 attribute :>> capability="steady capacity aggregation";
 attribute :>> removedWork="Count each canonical domain once after processor retirement";
 attribute :>> bound="O(D) domain summary aggregation; old consumer is O(P) processors, not O(N) blocks";
 attribute :>> addedCost="Per-intent transitions, revisions and retained-domain summaries";
 attribute :>> condition="D may exceed P; no speedup follows from replacing one linear census with another";
 }
 part cost2 : CostRow {
 attribute :>> capability="unpublished allocation";
 attribute :>> removedWork="Retain a private block or its reservation without exposing garbage fields to GC";
 attribute :>> bound="For one bounded intent w words, unresolved liability retains up to its w-word capacity grant plus native padding";
 attribute :>> addedCost="Native intent/extent record, stable input roots and outcome witness";
 attribute :>> condition="No generic malloc result recovery; absent exact outcome/closure, adoption remains blocked";
 }
 part cost3 : CostRow {
 attribute :>> capability="snapshot handoff";
 attribute :>> removedWork="Zero payload copying at owner-only commit; reject mixed ledger/list states";
 attribute :>> bound="O(1) revision/owner commit only after a qualified snapshot; unchanged inventory allows canonical mark overlap";
 attribute :>> addedCost="Joint gate or reservation, immutable snapshot and retry/refresh on sweep revision";
 attribute :>> condition="No wait-free or bounded retry theorem; version check followed by unrelated owner CAS is insufficient";
 }
 part cost4 : CostRow {
 attribute :>> capability="retired and unknown free";
 attribute :>> removedWork="Avoid early credit and duplicate free after lost native outcome";
 attribute :>> bound="R retired-but-held words remain in capacity; one acknowledged free removes exactly its charge";
 attribute :>> addedCost="Quarantine/release receipts may prolong R and hold source metadata";
 attribute :>> condition="Logical retirement and free acknowledgement are different; unknown native free may still block GC/allocator progress";
 }
 part cost5 : CostRow {
 attribute :>> capability="physical peak accounting";
 attribute :>> removedWork="Separate logical words from requested C bytes and observed residency";
 attribute :>> bound="Alignment-layer request = extra+(w+modulus)*WS; peak includes private+published+retired backing and metadata once";
 attribute :>> addedCost="Alignment/container bytes plus allocator overhead; metadata pins retain snapshot versions";
 attribute :>> condition="No claimed RSS bound or peak reduction; pre-peak Qg must exceed added concurrent residency at actual peak";
 }
 part cost6 : CostRow {
 attribute :>> capability="modern C and Zig";
 attribute :>> removedWork="Use one Scheme-generated intent/snapshot/reclamation contract";
 attribute :>> bound="Same physical allocation, barriers, root coverage and unknown-outcome duties";
 attribute :>> addedCost="Modern C refactoring and checked arithmetic required; Zig adds another backend if selected";
 attribute :>> condition="No established incremental Zig saving in ledger reconstruction, payload copying or GC correctness";
 }
 part def Node { attribute nodeId : String; attribute labelText : String; }
 part def Edge { ref part producer : Node; ref part consumer : Node; attribute labelText : String; }
 part node0 : Node { attribute :>> nodeId="legacy"; attribute :>> labelText="Legacy counters\\nL / D / VM charge / request phase"; }
 part node1 : Node { attribute :>> nodeId="cut"; attribute :>> labelText="Closed adoption cut\\nvalid chain + settled native calls"; }
 part node2 : Node { attribute :>> nodeId="intent"; attribute :>> labelText="Allocation intent\\nunbacked grant or private backing"; }
 part node3 : Node { attribute :>> nodeId="domain"; attribute :>> labelText="Canonical inventory\\npublished / private / retired / grants"; }
 part node4 : Node { attribute :>> nodeId="mark"; attribute :>> labelText="Canonical mark service\\nowner change preserves scan grant"; }
 part node5 : Node { attribute :>> nodeId="sweep"; attribute :>> labelText="Sweep / relink / logical retirement\\nnew inventory revision"; }
 part node6 : Node { attribute :>> nodeId="view"; attribute :>> labelText="Revision-bound ledger view\\nnot a payload capability"; }
 part node7 : Node { attribute :>> nodeId="commit"; attribute :>> labelText="Owner-generation commit\\nshared admission gate"; }
 part node8 : Node { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown malloc/free outcome\\nretain custody; no blind retry"; }
 part node9 : Node { attribute :>> nodeId="release"; attribute :>> labelText="Physical free acknowledgement\\nremove charge once"; }
 part node10 : Node { attribute :>> nodeId="pins"; attribute :>> labelText="Old metadata pins / raw borrowers\\ndifferent lifetime obligations"; }
 part edge0 : Edge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="scalars cannot reconstruct arbitrary cut"; }
 part edge1 : Edge { ref part :>> producer=node1; ref part :>> consumer=node3; attribute :>> labelText="one-time inventory adoption"; }
 part edge2 : Edge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="attach without double charge"; }
 part edge3 : Edge { ref part :>> producer=node2; ref part :>> consumer=node8; attribute :>> labelText="outcome missing"; }
 part edge4 : Edge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="trace published admitted roots only"; }
 part edge5 : Edge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="mark/worker closure before sweep"; }
 part edge6 : Edge { ref part :>> producer=node5; ref part :>> consumer=node3; attribute :>> labelText="publish new revision"; }
 part edge7 : Edge { ref part :>> producer=node3; ref part :>> consumer=node6; attribute :>> labelText="capture same root/inventory/ledger epoch"; }
 part edge8 : Edge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="matching revision and no mutation grant"; }
 part edge9 : Edge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="invalidate prepared view"; }
 part edge10 : Edge { ref part :>> producer=node7; ref part :>> consumer=node4; attribute :>> labelText="mark authority unchanged"; }
 part edge11 : Edge { ref part :>> producer=node5; ref part :>> consumer=node9; attribute :>> labelText="retired charge retained until receipt"; }
 part edge12 : Edge { ref part :>> producer=node9; ref part :>> consumer=node3; attribute :>> labelText="debit held backing once"; }
 part edge13 : Edge { ref part :>> producer=node10; ref part :>> consumer=node6; attribute :>> labelText="pin immutable metadata only"; }
 part edge14 : Edge { ref part :>> producer=node10; ref part :>> consumer=node9; attribute :>> labelText="raw borrow must close before free"; }
 part edge15 : Edge { ref part :>> producer=node8; ref part :>> consumer=node1; attribute :>> labelText="block adoption until outcome/integrity known"; }
}
