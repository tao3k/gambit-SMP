/* Modern-C component assurance. Native metadata owns projections, needs and dependencies;
 * no source refinement or runtime satisfaction is asserted. */
package GambitRuntimeAssurance {
    private import ScalarValues::*;
    part work : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/library/gc/CollectionContract.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse3;
        attribute :>> quintSource = "models/gambit/gc_work_contract.qnt";
        attribute :>> quintScope = "gc_work_contract:Test$";
        attribute :>> leanSource = "models/gambit/lean/WorkAccounting.lean";
        attribute :>> leanScope = "GambitSMP.WorkAccounting:zeroCountAndEmptyQueuesExcludeHiddenWork;reopenedWorkRevokesZeroCount";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceAnchors = "mem.c:3251-3307,3520-3625,6667-6770,6938-7048";
        attribute :>> stateProjection = "Private/queued/claimed/descendant obligations and phase-scoped counted owners -> collection work frontier";
        attribute :>> eventProjection = "claim/initialize/publish/acquire/scan/rescan/finish; source Tail and partial-copy states require extra relation";
        attribute :>> invariant = "Finish excludes every covered work class; preterminal rescan retains custody and closed epochs cannot reopen";
        attribute :>> abstractionBoundary = "One object/two roots with stopped mutators does not cover real chunk partitions, partial copies, weak producers or independently scheduled workers";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = work.component;
            attribute :>> obligationId = "GW-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = work.quintSource;
            attribute :>> subjectScope = work.quintScope;
            attribute :>> premise = "Positive and omission histories for Finish excludes every covered work class; preterminal rescan retains custody and closed epochs cannot reopen";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = work.component;
            attribute :>> obligationId = "GW-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = work.leanSource;
            attribute :>> subjectScope = work.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; One object/two roots with stopped mutators does not cover real chunk partitions, partial copies, weak producers or independently scheduled workers";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = work.component;
            attribute :>> obligationId = "GW-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = work.leanSource;
            attribute :>> subjectScope = "GW-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; claim/initialize/publish/acquire/scan/rescan/finish; source Tail and partial-copy states require extra relation";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = work.component;
            attribute :>> obligationId = "GW-M";
            attribute :>> kind = "native-memory-order";
            attribute :>> subjectPath = work.sourcePath;
            attribute :>> subjectScope = "GW-M:actual-source-refinement";
            attribute :>> premise = "Concrete atomics, root writes, lock order, callbacks/escapes, profile and physical last use";
        }
    }
    part workDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = work.source;
        ref part :>> prerequisite = work.history;
    }
    part workDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = work.source;
        ref part :>> prerequisite = work.induction;
    }
    part workDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = work.source;
        ref part :>> prerequisite = work.platform;
    }
    part roots : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/gambit/host_root_participation.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse4;
        attribute :>> quintSource = "models/gambit/host_roots_contract.qnt";
        attribute :>> quintScope = "host_roots_contract:Test$";
        attribute :>> leanSource = "models/gambit/lean/HostRootParticipation.lean";
        attribute :>> leanScope = "GambitSMP.HostRootParticipation:frozenHandoffComposesRelocation;recordPublicationIsNotParticipation;inactivePublicationStillExcludesMutation";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> sourceAnchors = "mem.c:674-829,3969-3986,6526-6538,6813-6873; c_intf.c:6511-6562; setup.c:770-840,3276-3422; cumulative.patch:524-548,714-768,2010-2029,3443-3460,4350-4501";
        attribute :>> stateProjection = "PSTATE RC ownership -> scanner-owned slot inventory; entry depth and final values -> frozen handoff/reload epoch";
        attribute :>> eventProjection = "protect/register before allocating marker; enter/freeze/acquire/relocate/reload/leave/release";
        attribute :>> invariant = "Same VM/owner and complete slot protection cover allocation, nested callbacks, blocked participation and return";
        attribute :>> abstractionBoundary = "Baseline P0-only RC scan and unprotected marker are changed by existing cumulative patch; retained-donor census, scratch extent, startup interval, unwind, binding and dynamic identity remain separate open source obligations in GambitHostRootsRefinement";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = roots.component;
            attribute :>> obligationId = "HR-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = roots.quintSource;
            attribute :>> subjectScope = roots.quintScope;
            attribute :>> premise = "Positive and omission histories for Same VM/owner and complete slot protection cover allocation, nested callbacks, blocked participation and return";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = roots.component;
            attribute :>> obligationId = "HR-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = roots.leanSource;
            attribute :>> subjectScope = roots.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; target registered bit does not discharge the six source routes owned by GambitHostRootsRefinement";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = roots.component;
            attribute :>> obligationId = "HR-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = roots.leanSource;
            attribute :>> subjectScope = "HR-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; protect/register before allocating marker; enter/freeze/acquire/relocate/reload/leave/release";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = roots.component;
            attribute :>> obligationId = "HR-M";
            attribute :>> kind = "native-memory-order";
            attribute :>> subjectPath = roots.sourcePath;
            attribute :>> subjectScope = "HR-M:actual-source-refinement";
            attribute :>> premise = "Concrete atomics, root writes, lock order, callbacks/escapes, profile and physical last use";
        }
    }
    part rootsDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = roots.source;
        ref part :>> prerequisite = roots.history;
    }
    part rootsDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = roots.source;
        ref part :>> prerequisite = roots.induction;
    }
    part rootsDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = roots.source;
        ref part :>> prerequisite = roots.platform;
    }
    part control : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/gambit/continuation_saved_stack_origin.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse5;
        attribute :>> quintSource = "models/gambit/continuation_contract.qnt";
        attribute :>> quintScope = "continuation_contract:Test$";
        attribute :>> leanSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
        attribute :>> leanScope = "GambitSMP.SavedStackRetirementWindow:nonConsumingUsePreservesRawOrigin;completeOriginsBoundLastRawAccess";
        attribute :>> sourcePath = "vendor/gambit/include/gambit.h.in";
        attribute :>> sourceAnchors = "gambit.h.in:6314-6405; mem.c:3898-3966,4096-4105; continuation frame writer census";
        attribute :>> stateProjection = "Current break links and separately captured origins -> FrameSpec slot/root coordinates and backing leases";
        attribute :>> eventProjection = "save/restore/current-root copy/queue saved continuation/traverse; graft is not destructive consumption";
        attribute :>> invariant = "Current-root coverage cannot discard untraversed saved origins; no backing reuse before complete last-user closure";
        attribute :>> abstractionBoundary = "Selected origin IDs do not model every frame, denv mutation, serialization, dynamic-wind, FFI writer or generated descriptor";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = control.component;
            attribute :>> obligationId = "CO-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = control.quintSource;
            attribute :>> subjectScope = control.quintScope;
            attribute :>> premise = "Positive and omission histories for Current-root coverage cannot discard untraversed saved origins; no backing reuse before complete last-user closure";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = control.component;
            attribute :>> obligationId = "CO-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = control.leanSource;
            attribute :>> subjectScope = control.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; Selected origin IDs do not model every frame, denv mutation, serialization, dynamic-wind, FFI writer or generated descriptor";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = control.component;
            attribute :>> obligationId = "CO-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = control.leanSource;
            attribute :>> subjectScope = "CO-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; save/restore/current-root copy/queue saved continuation/traverse; graft is not destructive consumption";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = control.component;
            attribute :>> obligationId = "CO-M";
            attribute :>> kind = "native-memory-order";
            attribute :>> subjectPath = control.sourcePath;
            attribute :>> subjectScope = "CO-M:actual-source-refinement";
            attribute :>> premise = "Concrete atomics, root writes, lock order, callbacks/escapes, profile and physical last use";
        }
    }
    part controlDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = control.source;
        ref part :>> prerequisite = control.history;
    }
    part controlDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = control.source;
        ref part :>> prerequisite = control.induction;
    }
    part controlDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = control.source;
        ref part :>> prerequisite = control.platform;
    }
    part release : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/gambit/saved_stack_retirement_window.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse6;
        attribute :>> quintSource = "models/gambit/resource_exit_contract.qnt";
        attribute :>> quintScope = "resource_exit_contract:Test$";
        attribute :>> leanSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
        attribute :>> leanScope = "GambitSMP.SavedStackRetirementWindow:emptyWitnessNeedsStableWindow;phaseCompletionOrdersReuse;foreignFrameClosureDoesNotEmptySchemeQueue";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceAnchors = "mem.c:4370-4455,4933-4960; os_io.c:device cleanup owner audit";
        attribute :>> stateProjection = "Ingress closed plus actual borrowers, strong/weak/cleanup and target identity -> reclaim permit";
        attribute :>> eventProjection = "freeze/last-use/drain/issue permit/reclaim; unknown outcomes retain custody; reopened generation invalidates permit";
        attribute :>> invariant = "Only same-generation permit with complete producer and user drain allows reclaim";
        attribute :>> abstractionBoundary = "Coarse last-user protocol does not establish foreign destructor effects, owner-thread dispatch, device fd closure or physical release acknowledgements";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = release.component;
            attribute :>> obligationId = "RX-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = release.quintSource;
            attribute :>> subjectScope = release.quintScope;
            attribute :>> premise = "Positive and omission histories for Only same-generation permit with complete producer and user drain allows reclaim";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = release.component;
            attribute :>> obligationId = "RX-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = release.leanSource;
            attribute :>> subjectScope = release.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; Coarse last-user protocol does not establish foreign destructor effects, owner-thread dispatch, device fd closure or physical release acknowledgements";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = release.component;
            attribute :>> obligationId = "RX-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = release.leanSource;
            attribute :>> subjectScope = "RX-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; freeze/last-use/drain/issue permit/reclaim; unknown outcomes retain custody; reopened generation invalidates permit";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = release.component;
            attribute :>> obligationId = "RX-M";
            attribute :>> kind = "native-memory-order";
            attribute :>> subjectPath = release.sourcePath;
            attribute :>> subjectScope = "RX-M:actual-source-refinement";
            attribute :>> premise = "Concrete atomics, root writes, lock order, callbacks/escapes, profile and physical last use";
        }
    }
    part releaseDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = release.source;
        ref part :>> prerequisite = release.history;
    }
    part releaseDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = release.source;
        ref part :>> prerequisite = release.induction;
    }
    part releaseDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = release.source;
        ref part :>> prerequisite = release.platform;
    }
}

