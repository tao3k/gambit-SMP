/* Modern C target contract; baseline source closure remains open. */
package GambitRcFreezePublication {
    private import ScalarValues::*;
    part def FreezeContract {
        attribute identity : String;
        attribute preparation : String;
        attribute close : String;
        attribute receipt : String;
        attribute publication : String;
        attribute mutation : String;
        attribute collector : String;
        attribute deletion : String;
        attribute cleanup : String;
        attribute unknown : String;
    }
    part protocol : FreezeContract {
        attribute :>> identity = "VM/domain/generation/layoutRevision/rootEpoch and writer-inventory digest; storage lease differs from raw-value borrow";
        attribute :>> preparation = "Initialize all root slots and reserve native-only release custody before pin admission; incomplete preparation retains source custody";
        attribute :>> close = "Close mutator ingress, park raw Scheme borrows, finish admitted root writes; storage leases may remain";
        attribute :>> receipt = "Known final writer inventory; writers zero, raw borrows parked; initialized enrolled domain and exact generation/layout; no unknown raw escape";
        attribute :>> publication = "Final slot stores release before scanner acquire; domain enrollment before executor removal and scan snapshot seal; pin excludes unlink and layout transfer";
        attribute :>> mutation = "Mutator RootWrite permit and generational dirty publication; no hidden GC from bounded barrier; revoke receipt on reentry or identity change";
        attribute :>> collector = "Collector relocation authority writes enrolled slots while mutator ingress is closed; post-GC acquire/reload before raw use";
        attribute :>> deletion = "Request close without waiting for own callback; exact nested tokens settle before physical release; exception/nonlocal exit needs acknowledged cleanup";
        attribute :>> cleanup = "Preclassified native-only task custody accepted before wrapper clear/free; collector never waits for a task awaiting its epoch pin";
        attribute :>> unknown = "Retain root/header/backing and unresolved delivery debt; quarantine allocating reentry without freeze; no receipt from failed/unknown join alone";
    }
    part def CensusRoute {
        attribute routeId : String;
        attribute sourceAnchors : String;
        attribute authority : String;
        attribute obligation : String;
        attribute boundary : String;
    }
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-H";
        attribute :>> kind = "interleaving";
        attribute :>> subjectPath = "models/gambit/rc_freeze_publication.qnt";
        attribute :>> subjectScope = "rc_freeze_publication:Test$";
        attribute :>> premise = "Thirteen finite target histories; storage/raw separation, publication and modeled wait omissions; not native reachability";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-I";
        attribute :>> kind = "induction";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "GambitSMP.RcFreezePublication:issueRequiresFinalValues;issueBindsGeneration;storageLeaseDoesNotBlockFreeze;publicationPrecedesReceipt;collectorCanUpdateFrozenRoots;waitPathIncreases;noRankedWaitCycle";
        attribute :>> premise = "Conditional issuance and arbitrary finite ranked wait paths; no source wait-graph completeness proof";
    }
    part census : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-CENSUS";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "FZ-CENSUS:actual-source-refinement";
        attribute :>> premise = "All native root writers, generated conversion exits, borrowed aliases and external escapes mediated or profile rejected";
    }
    part freeze : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-FREEZE";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "FZ-FREEZE:actual-source-refinement";
        attribute :>> premise = "Final-value park, root-slot inventory and identity-bound receipt; no waiting for callback storage lifetime to end";
    }
    part publication : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-PUBLISH";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "FZ-PUBLISH:actual-source-refinement";
        attribute :>> premise = "Root domain initialization/enrollment precedes executor removal and scan cut; collector writes remain authorized";
    }
    part callback : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-CALLBACK";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "FZ-CALLBACK:actual-source-refinement";
        attribute :>> premise = "Creation failure, nested callback/delete, marker protection, reload and all exceptional exits settle exact custody";
    }
    part cleanup : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-CLEANUP";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/RcFreezePublication.lean";
        attribute :>> subjectScope = "FZ-CLEANUP:actual-source-refinement";
        attribute :>> premise = "Manual release versus GC cleanup policies; preaccepted native-only deferred custody and full last-user drain; no pin wait cycle";
    }
    part memoryOrder : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "FZ-MEMORY";
        attribute :>> kind = "native-memory-order";
        attribute :>> subjectPath = "vendor/gambit/lib/mem.c";
        attribute :>> subjectScope = "FZ-MEMORY:actual-source-refinement";
        attribute :>> premise = "C release/acquire, scan/update/unlink exclusion, lock order and all external/native wait paths remain unrefined";
    }
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = history;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = induction;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = census;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = freeze;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = publication;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = callback;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = cleanup;
    }
    part dependency7 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::membership;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency8 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = census;
        ref part :>> prerequisite = history;
    }
    part dependency9 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = census;
        ref part :>> prerequisite = induction;
    }
    part dependency10 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = census;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency11 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = freeze;
        ref part :>> prerequisite = history;
    }
    part dependency12 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = freeze;
        ref part :>> prerequisite = induction;
    }
    part dependency13 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = freeze;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency14 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publication;
        ref part :>> prerequisite = history;
    }
    part dependency15 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publication;
        ref part :>> prerequisite = induction;
    }
    part dependency16 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publication;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency17 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = callback;
        ref part :>> prerequisite = history;
    }
    part dependency18 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = callback;
        ref part :>> prerequisite = induction;
    }
    part dependency19 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = callback;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency20 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = cleanup;
        ref part :>> prerequisite = history;
    }
    part dependency21 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = cleanup;
        ref part :>> prerequisite = induction;
    }
    part dependency22 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = cleanup;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency23 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::lifetime;
        ref part :>> prerequisite = cleanup;
    }
    part dependency24 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::lifetime;
        ref part :>> prerequisite = callback;
    }
    part dependency25 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRetainedRcScan::commitState;
        ref part :>> prerequisite = publication;
    }
    part dependency26 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::dynamic;
        ref part :>> prerequisite = callback;
    }
    part dependency27 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::dynamic;
        ref part :>> prerequisite = census;
    }
    part dependency28 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = memoryOrder;
        ref part :>> prerequisite = GambitRetainedRcScan::memoryOrder;
    }
    part primitive : CensusRoute {
        attribute :>> routeId = "RC-API";
        attribute :>> sourceAnchors = "mem.c:674-829,3969-3986; gambit.h.in:11309-11315,11413";
        attribute :>> authority = "Mutator list/data writes; collector relocation; raw header aliases";
        attribute :>> obligation = "FZ-CENSUS";
        attribute :>> boundary = "116 lexical occurrences in 9 files is not external-C caller closure";
    }
    part converter : CensusRoute {
        attribute :>> routeId = "CONVERSION";
        attribute :>> sourceAnchors = "c_intf.c:1633-1809,2887-2940,3233-3613; gambit.h.in:9838-9894,10476-10522";
        attribute :>> authority = "Function/string/list lifetime; generated normal-exit cleanup; count and payload readers";
        attribute :>> obligation = "FZ-CENSUS";
        attribute :>> boundary = "refcount==1 is not concurrent exclusion; nonlocal exits and foreign-held aliases need contracts";
    }
    part dynamic : CensusRoute {
        attribute :>> routeId = "DYNAMIC";
        attribute :>> sourceAnchors = "os_dyn.c:744-795,1045-1053; c_intf.c:6511-6562";
        attribute :>> authority = "Native function pointer invocation and RC data read; marker may allocate";
        attribute :>> obligation = "FZ-CALLBACK";
        attribute :>> boundary = "Global c_closure_self and unqualified external release remain source obligations";
    }
    part tcl : CensusRoute {
        attribute :>> routeId = "TCL";
        attribute :>> sourceAnchors = "examples/tcltk/tcltk.scm:90-97,125-195,217-227,288-342";
        attribute :>> authority = "Callback, delete callback, retained Tcl result buffer and creation setup";
        attribute :>> obligation = "FZ-CALLBACK";
        attribute :>> boundary = "Tcl command lifetime does not prove ClientData ownership; failure and nonlocal exits unresolved";
    }
    part release : CensusRoute {
        attribute :>> routeId = "FOREIGN";
        attribute :>> sourceAnchors = "c_intf.c:1683-1710,5287-5381; mem.c:4387-4455; _kernel.scm:3884-3894";
        attribute :>> authority = "Manual result-bearing release; conversion-error release; GC ignores destructor error then frees wrapper";
        attribute :>> obligation = "FZ-CLEANUP";
        attribute :>> boundary = "Existing release_fn return cannot acknowledge deferred custody after wrapper clear/free";
    }
    part resources : CensusRoute {
        attribute :>> routeId = "RESOURCE";
        attribute :>> sourceAnchors = "os_io.c:3948-3971,4199-4558,7099-7143; os_files.c:1189; examples/Xlib-simple/Xlib.scm:68-104,332,381,739";
        attribute :>> authority = "TLS/event/native payload cleanup and creation-error paths";
        attribute :>> obligation = "FZ-CLEANUP";
        attribute :>> boundary = "Platform branches are inventory only; SSL/Tcl/Xlib effects and owner thread not qualified";
    }
    part exports : CensusRoute {
        attribute :>> routeId = "EXPORT";
        attribute :>> sourceAnchors = "setup.c:5900-5922; gambit.h.in:13232-13255,14575-14598";
        attribute :>> authority = "Public function tables and imports expose all RC primitives";
        attribute :>> obligation = "FZ-CENSUS";
        attribute :>> boundary = "Unmediated external C or pointer writes reject freeze issuance";
    }
    part censusRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = census;
        attribute :>> sourceAnchors = primitive.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
    part freezeRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = freeze;
        attribute :>> sourceAnchors = primitive.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
    part publicationRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = publication;
        attribute :>> sourceAnchors = primitive.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
    part callbackRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = callback;
        attribute :>> sourceAnchors = dynamic.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
    part cleanupRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = cleanup;
        attribute :>> sourceAnchors = release.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
    part memoryOrderRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = memoryOrder;
        attribute :>> sourceAnchors = primitive.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
}
