/* Modern C target. Root domains outlive execution membership. No satisfaction claim. */
package GambitRetainedRcScan {
    private import ScalarValues::*;
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-H";
        attribute :>> kind = "interleaving";
        attribute :>> premise = "Fifteen target histories plus bounded positive-step invariant sampling; no native reachability";
        attribute :>> subjectPath = "models/gambit/retained_rc_scan.qnt";
        attribute :>> subjectScope = "retained_rc_scan:Test$";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-I";
        attribute :>> kind = "induction";
        attribute :>> premise = "Reader/exclusive-writer kernel step and trace preservation; full GC phase and C refinement open";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "GambitSMP.RetainedRcScan:retainedEnrollmentCoverage;pinPreserves;preparePreserves;commitPreserves;releasePreserves;stepPreserves;tracePreserves;pinnedSnapshotStable;readerExcludesTransfer;fullPhaseClosure;committedOwnerSurvivesLostAck";
    }
    part def DomainContract {
        ref part rootComponent : GambitAssuranceRelations::ComponentModelUse;
        ref part collectorComponent : GambitAssuranceRelations::ComponentModelUse;
        attribute identity : String;
        attribute membership : String;
        attribute freeze : String;
        attribute scanSnapshot : String;
        attribute trace : String;
        attribute commit : String;
        attribute acknowledgement : String;
        attribute physicalLifetime : String;
        attribute capacity : String;
        attribute memoryOrder : String;
        attribute quarantine : String;
    }
    part protocol : DomainContract {
        ref part :>> rootComponent = GambitRuntimeAssurance::roots.component;
        ref part :>> collectorComponent = GambitRuntimeAssurance::work.component;
        attribute :>> identity = "VM/domainId/generation; layoutRevision and TransferId are separate; no slot reuse while borrowed";
        attribute :>> membership = "Publish retained root domain before executor removal; root domains do not increase barrier or scan worker count";
        attribute :>> freeze = "Final native root writers and borrowers closed with witnessed release/acquire; failed join is no stopped proof";
        attribute :>> scanSnapshot = "Pin exact domain/layout once per GC epoch; unique slot scan assignment; immutable worker cohort";
        attribute :>> trace = "Alive collector uses its own copying context and queues; retained still prepare, strong, weak and cleanup included";
        attribute :>> commit = "Allocation-free list/counter commit under exclusive layout authority after epoch pins drain; no join or GC under registry mutex";
        attribute :>> acknowledgement = "Prepared failure retains donor; committed unknown queried by TransferId; no blind splice retry";
        attribute :>> physicalLifetime = "Retain roots, native headers and backing through all consumers; joined donor cleanup only after receiver acceptance and drain";
        attribute :>> capacity = "Charge retained still live/deferred words once and active collector copies once; stale donor allocation cursors are not current live occupancy";
        attribute :>> memoryOrder = "Short registry mutex serializes pin/writer admission; release/acquire orders freeze and updated roots; source native macros unproved";
        attribute :>> quarantine = "Without freeze or valid backing evidence, close allocating/reentry ingress and refuse unsafe collection; availability loss explicit";
    }
    part joinResult : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-JOIN";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Classify raw join result and unique join owner; stop/freeze evidence independent of failed or unknown status";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-JOIN:actual-source-refinement";
    }
    part joinResultRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = joinResult;
        attribute :>> sourceAnchors = "os_thread.c:546-572; os_base.c:1050-1076; setup.c:978";
        attribute :>> patchAnchors = "cumulative.patch:4350-4381,4489-4501,5084-5095";
        attribute :>> projection = "joinFailed/joinUnknown/joinSuccess; errno fallback is unknown, not successful termination";
        attribute :>> failureCustodian = "lifecycle owner retains join and storage obligations; no concurrent join retry";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part membership : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-DOMAIN";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Every live retained RC/still domain enrolled before executor removal; complete native writer freeze or quarantine";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-DOMAIN:actual-source-refinement";
    }
    part membershipRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = membership;
        attribute :>> sourceAnchors = "setup.c:546-667,1193-1200; mem.c:674-829,6813-6873";
        attribute :>> patchAnchors = "cumulative.patch:4301-4317,4424-4483; no retained-domain GC adapter";
        attribute :>> projection = "freezeWriters/retire/beginGC; domain census separate from worker cohort";
        attribute :>> failureCustodian = "root-domain registry retains roots even when execution slot leaves";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part tracing : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-TRACE";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Proxy uses active copying context and queues; retained still initialization, descendant and weak closure complete";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-TRACE:actual-source-refinement";
    }
    part tracingRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = tracing;
        attribute :>> sourceAnchors = "mem.c:3410-3460,3490-3663,3969-3986,4210-4245,6678-6770,6775-6810";
        attribute :>> patchAnchors = "cumulative.patch:3443-3460; active processor scanner only";
        attribute :>> projection = "prepareStill/scanRoots/drainTrace/weakComplete; donor PSTATE cannot impersonate active collector";
        attribute :>> failureCustodian = "active collector owns produced work; domain pin retains slots and native backing";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part commitState : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-COMMIT";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Full link/counter commit excludes every epoch reader and root writer; resolve lost acknowledgement by identity";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-COMMIT:actual-source-refinement";
    }
    part commitStateRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = commitState;
        attribute :>> sourceAnchors = "mem.c:723-829,3969-3986; setup.c:975-980";
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,4350-4381,4490-4501";
        attribute :>> projection = "prepareTransfer/commitTransfer/abortPrepared/resolveCommitted; logical atomic step hides no observed partial links";
        attribute :>> failureCustodian = "donor before commit; receiver after commit; unresolved observer retains resolution debt";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part lifetime : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-LIFETIME";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Still preparation, foreign cleanup, native borrower drain and retained capacity charged exactly once before backing release";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-LIFETIME:actual-source-refinement";
    }
    part lifetimeRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = lifetime;
        attribute :>> sourceAnchors = "mem.c:4370-4455,4933-4960,6255-6314,6920-6937";
        attribute :>> patchAnchors = "cumulative.patch:3181-3200,3223-3234,4490-4501";
        attribute :>> projection = "cleanupAccount/finishGC/cleanupDonor; release only after root and descendant last use";
        attribute :>> failureCustodian = "domain custodian retains headers and backing; foreign release deferred if owner thread not qualified";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part memoryOrder : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-MEMORY";
        attribute :>> kind = "native-memory-order";
        attribute :>> premise = "Prove source pin/writer gate, freeze and collector publication happens-before without blocking progress";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "RC-MEMORY:actual-source-refinement";
    }
    part memoryOrderRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = memoryOrder;
        attribute :>> sourceAnchors = "mem.c:378-385,723-829,3969-3986; setup.c:546-710";
        attribute :>> patchAnchors = "cumulative.patch:3178-3223,4265-4277,4475-4499";
        attribute :>> projection = "pin/exclusive exclusion and stable snapshot; existing splice mutex is not a scan lease";
        attribute :>> failureCustodian = "coordinator retains unknown outcome; raw non-atomic list mutation requires real exclusion";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = history;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = induction;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = joinResult;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = membership;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = tracing;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = commitState;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = lifetime;
    }
    part dependency7 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency8 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = joinResult;
        ref part :>> prerequisite = history;
    }
    part dependency9 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = joinResult;
        ref part :>> prerequisite = induction;
    }
    part dependency10 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = joinResult;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency11 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = membership;
        ref part :>> prerequisite = history;
    }
    part dependency12 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = membership;
        ref part :>> prerequisite = induction;
    }
    part dependency13 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = membership;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency14 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = tracing;
        ref part :>> prerequisite = history;
    }
    part dependency15 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = tracing;
        ref part :>> prerequisite = induction;
    }
    part dependency16 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = tracing;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency17 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = commitState;
        ref part :>> prerequisite = history;
    }
    part dependency18 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = commitState;
        ref part :>> prerequisite = induction;
    }
    part dependency19 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = commitState;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency20 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = lifetime;
        ref part :>> prerequisite = history;
    }
    part dependency21 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = lifetime;
        ref part :>> prerequisite = induction;
    }
    part dependency22 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = lifetime;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency23 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = memoryOrder;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency24 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = tracing;
        ref part :>> prerequisite = membership;
    }
    part dependency25 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = lifetime;
        ref part :>> prerequisite = tracing;
    }
    part dependency26 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = commitState;
        ref part :>> prerequisite = joinResult;
    }
    part dependency27 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = commitState;
        ref part :>> prerequisite = lifetime;
    }
}
