/* Modern-C target research. Native metadata is authoritative; no satisfaction asserted. */
package GambitHostRootsRefinement {
    private import ScalarValues::*;
    part def Route {
        ref part need : GambitAssuranceRouting::ModelNeed;
        attribute sourceAnchors : String;
        attribute patchAnchors : String;
        attribute projection : String;
        attribute failureCustodian : String;
        attribute status : String;
    }
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-DH";
        attribute :>> kind = "interleaving";
        attribute :>> premise = "Fourteen explicit target histories; controls are not native reachability claims";
        attribute :>> subjectPath = "models/gambit/host_roots_refinement.qnt";
        attribute :>> subjectScope = "host_roots_refinement:Test$";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-DI";
        attribute :>> kind = "induction";
        attribute :>> premise = "Conditional census, reload and LIFO settlement lemmas; no C-step simulation";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "GambitSMP.HostRootsRefinement:liveRcCoverage;retainedDoesNotImplyScanned;protectedReload;reservationSurvives;enterPreserves;settlePreserves;nestedSettlement;balancedIsNotBinding;lateRootCannotRepair";
    }
    part rc : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-RC";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Every live RC data slot belongs to the next scan census, including retained donors; splice and scan exclude concurrent mutation";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-RC:actual-source-refinement";
    }
    part rcRoute : Route {
        ref part :>> need = rc;
        attribute :>> sourceAnchors = "mem.c:306,674-829,3969-3986,6813-6873,4933-4960";
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501";
        attribute :>> projection = "register/scan/retireUnknown/transferCommitted; RC data only, not arbitrary payload bytes";
        attribute :>> failureCustodian = "donor until stopped and receiver scan ownership accepted; failed join retains scan debt";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part marker : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-MARKER";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Reserved scratch extent covers allocation, all exits and reload; nested saved writers cannot clobber it";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-MARKER:actual-source-refinement";
    }
    part markerRoute : Route {
        ref part :>> need = marker;
        attribute :>> sourceAnchors = "c_intf.c:6511-6562; gambit.h.in:8059-8086; mem.c:6526-6538";
        attribute :>> patchAnchors = "cumulative.patch:714-768,2010-2029";
        attribute :>> projection = "reserve/allocateMoving/reload/releaseSlot; exception cleanup revokes only its own token";
        attribute :>> failureCustodian = "activation owns input root until marker initialized or allocation unwind settled";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part boot : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-BOOT";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "A movable startup thunk is rooted before the collective preceding run, or independently proven stable";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-BOOT:actual-source-refinement";
    }
    part bootRoute : Route {
        ref part :>> need = boot;
        attribute :>> sourceAnchors = "setup.c:770-840,3398-3422,6418-6430";
        attribute :>> patchAnchors = "cumulative.patch:4334; ordinary run excluded at 749";
        attribute :>> projection = "preEntryMove then reserve is too late; entry lease cannot certify prior interval";
        attribute :>> failureCustodian = "startup producer retains root through collective and consumer acceptance";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part exitState : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-EXIT";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Every generated wrapper and direct run exit cleans its own marker and count exactly once before rethrow";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-EXIT:actual-source-refinement";
    }
    part exitStateRoute : Route {
        ref part :>> need = exitState;
        attribute :>> sourceAnchors = "setup.c:3276-3422; gambit.h.in:10043-10059; _kernel.scm:1019-1071";
        attribute :>> patchAnchors = "cumulative.patch:524-548,714-768";
        attribute :>> projection = "enter/settleTop; matched return, conversion handler, allocation throw and unmatched rethrow distinct";
        attribute :>> failureCustodian = "current activation until its cleanup completes; outer activation retains unmatched destination";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part bindingState : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-BIND";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Real PSTATE, effective binding, VM and catcher restore are separately established on every admitted exit";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-BIND:actual-source-refinement";
    }
    part bindingStateRoute : Route {
        ref part :>> need = bindingState;
        attribute :>> sourceAnchors = "gambit.h.in:8708-8718; os_thread.c:697; setup.c:3276-3422";
        attribute :>> patchAnchors = "cumulative.patch:714-768 does not supply a VM binding stack";
        attribute :>> projection = "priorBindings and count are independent; no-switch same-owner admission first";
        attribute :>> failureCustodian = "owner activation retains binding snapshot; foreign longjmp and cancellation outside profile rejected";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part dynamic : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-DYNAMIC";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "Dynamic closure identity and RC lifetime survive allocation and reentry on each qualified trampoline ABI";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "HR-DYNAMIC:actual-source-refinement";
    }
    part dynamicRoute : Route {
        ref part :>> need = dynamic;
        attribute :>> sourceAnchors = "os_dyn.c:744-795; c_intf.c:6536; examples/tcltk/tcltk.scm:125-195";
        attribute :>> patchAnchors = "cumulative.patch:2010-2029 saves false, not closure self identity";
        attribute :>> projection = "FAL dynamic lookup requires separate identity premise; Tcl still indirection is a distinct case";
        attribute :>> failureCustodian = "closure publisher and in-flight borrower retain RC identity until callback and deletion drain";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = history;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = induction;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = rc;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = marker;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = boot;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = exitState;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = bindingState;
    }
    part dependency7 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = dynamic;
    }
    part dependency8 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = rc;
        ref part :>> prerequisite = history;
    }
    part dependency9 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = rc;
        ref part :>> prerequisite = induction;
    }
    part dependency10 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = rc;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency11 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = marker;
        ref part :>> prerequisite = history;
    }
    part dependency12 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = marker;
        ref part :>> prerequisite = induction;
    }
    part dependency13 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = marker;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency14 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = boot;
        ref part :>> prerequisite = history;
    }
    part dependency15 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = boot;
        ref part :>> prerequisite = induction;
    }
    part dependency16 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = boot;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency17 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = exitState;
        ref part :>> prerequisite = history;
    }
    part dependency18 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = exitState;
        ref part :>> prerequisite = induction;
    }
    part dependency19 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = exitState;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency20 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = bindingState;
        ref part :>> prerequisite = history;
    }
    part dependency21 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = bindingState;
        ref part :>> prerequisite = induction;
    }
    part dependency22 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = bindingState;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
    part dependency23 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = dynamic;
        ref part :>> prerequisite = history;
    }
    part dependency24 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = dynamic;
        ref part :>> prerequisite = induction;
    }
    part dependency25 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = dynamic;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.platform;
    }
}
