/* Modern-C component assurance. Native metadata owns projections, needs and dependencies;
 * no source refinement or runtime satisfaction is asserted. */
package GambitBuildAssurance {
    private import ScalarValues::*;
    part planner : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/build/incremental_build.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse0;
        attribute :>> quintSource = "models/build/planner_contract.qnt";
        attribute :>> quintScope = "planner_contract:Test$";
        attribute :>> leanSource = "models/build/IncrementalBuild.lean";
        attribute :>> leanScope = "GambitBuild:reuseMatchesClean;receiptBackedAdaptiveReuse;allConsumerCutoff";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceAnchors = "gsc/makefile.in:103-112,289-307,311-346; _front.scm:7-11; _t-c-3.scm:7-11";
        attribute :>> stateProjection = "Old trace/cut -> current immutable image and all consumer observations; graph selection -> 74-node population";
        attribute :>> eventProjection = "observe/validate/seal/reuse/start; node signature is only a candidate observation encoding";
        attribute :>> invariant = "Reuse requires complete mediated effects, stable image, successful origin and all-consumer equivalence";
        attribute :>> abstractionBoundary = "Integer outputs and selected ten nodes do not implement Scheme eval/reader/FFI capabilities or encode actual C/linker observations";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = planner.component;
            attribute :>> obligationId = "BP-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = planner.quintSource;
            attribute :>> subjectScope = planner.quintScope;
            attribute :>> premise = "Positive and omission histories for Reuse requires complete mediated effects, stable image, successful origin and all-consumer equivalence";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = planner.component;
            attribute :>> obligationId = "BP-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = planner.leanSource;
            attribute :>> subjectScope = planner.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; Integer outputs and selected ten nodes do not implement Scheme eval/reader/FFI capabilities or encode actual C/linker observations";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = planner.component;
            attribute :>> obligationId = "BP-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = planner.leanSource;
            attribute :>> subjectScope = "BP-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; observe/validate/seal/reuse/start; node signature is only a candidate observation encoding";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = planner.component;
            attribute :>> obligationId = "BP-E";
            attribute :>> kind = "environment-refinement";
            attribute :>> subjectPath = planner.sourcePath;
            attribute :>> subjectScope = "BP-E:actual-source-refinement";
            attribute :>> premise = "Complete effect/writer census, immutable read image, output group commit, argv/environment and failed I/O custody";
        }
    }
    part plannerDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = planner.source;
        ref part :>> prerequisite = planner.history;
    }
    part plannerDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = planner.source;
        ref part :>> prerequisite = planner.induction;
    }
    part plannerDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = planner.source;
        ref part :>> prerequisite = planner.platform;
    }
    part scheduler : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/build/incremental_build.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse1;
        attribute :>> quintSource = "models/build/scheduler_contract.qnt";
        attribute :>> quintScope = "scheduler_contract:Test$";
        attribute :>> leanSource = "models/build/IncrementalBuild.lean";
        attribute :>> leanScope = "GambitBuild:budgetStepPreserves;budgetTracePreserves;returnedCreditCannotIncrease;fullBudgetBoundsSelected";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceAnchors = "gsc/makefile.in:254-307; models/build/incremental_build.qnt:64-102";
        attribute :>> stateProjection = "Running phase and used credits -> host-owned budget; nested children require a disjoint token partition";
        attribute :>> eventProjection = "ready/start/finish/cancel/discard; cancellation request does not establish physical completion";
        attribute :>> invariant = "Used equals running weight, is bounded, and each terminal release is counted once";
        attribute :>> abstractionBoundary = "Unit-weight ten-node slice does not prove weighted host population, parent-await-child progress, OS cancellation or fairness";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = scheduler.component;
            attribute :>> obligationId = "BS-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = scheduler.quintSource;
            attribute :>> subjectScope = scheduler.quintScope;
            attribute :>> premise = "Positive and omission histories for Used equals running weight, is bounded, and each terminal release is counted once";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = scheduler.component;
            attribute :>> obligationId = "BS-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = scheduler.leanSource;
            attribute :>> subjectScope = scheduler.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; Unit-weight ten-node slice does not prove weighted host population, parent-await-child progress, OS cancellation or fairness";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = scheduler.component;
            attribute :>> obligationId = "BS-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = scheduler.leanSource;
            attribute :>> subjectScope = "BS-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; ready/start/finish/cancel/discard; cancellation request does not establish physical completion";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = scheduler.component;
            attribute :>> obligationId = "BS-E";
            attribute :>> kind = "environment-refinement";
            attribute :>> subjectPath = scheduler.sourcePath;
            attribute :>> subjectScope = "BS-E:actual-source-refinement";
            attribute :>> premise = "Complete effect/writer census, immutable read image, output group commit, argv/environment and failed I/O custody";
        }
    }
    part schedulerDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scheduler.source;
        ref part :>> prerequisite = scheduler.history;
    }
    part schedulerDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scheduler.source;
        ref part :>> prerequisite = scheduler.induction;
    }
    part schedulerDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scheduler.source;
        ref part :>> prerequisite = scheduler.platform;
    }
    part publisher : GambitAssuranceRouting::ComponentStudy {
        attribute :>> baselineModel = "models/build/incremental_build.qnt";
        ref part :>> component = GambitAssuranceRelations::modelUse2;
        attribute :>> quintSource = "models/build/publisher_contract.qnt";
        attribute :>> quintScope = "publisher_contract:Test$";
        attribute :>> leanSource = "models/build/IncrementalBuild.lean";
        attribute :>> leanScope = "GambitBuild:receiptReuseMatchesClean;nonSuccessCannotIssue;scriptFullObservationCongruence;cleanupDebtBlocksDelivery";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceAnchors = "gsc/makefile.in:289-307; _host.scm:196-249; _t-c-1.scm:880-895,910-1090";
        attribute :>> stateProjection = "Staged C and linker data plus source epoch -> one complete publication group and consumer trace";
        attribute :>> eventProjection = "stage/finish/revalidate/publish or discard; open/read/write/close and exceptions must refine trace events";
        attribute :>> invariant = "No current receipt from partial, failed, cancelled, revoked or unreflected output group";
        attribute :>> abstractionBoundary = "One integer node publication does not prove multi-file atomicity, script-line readback, diagnostic/effect reflection or filesystem durability";
        part history : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = publisher.component;
            attribute :>> obligationId = "BU-H";
            attribute :>> kind = "interleaving";
            attribute :>> subjectPath = publisher.quintSource;
            attribute :>> subjectScope = publisher.quintScope;
            attribute :>> premise = "Positive and omission histories for No current receipt from partial, failed, cancelled, revoked or unreflected output group";
        }
        part induction : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = publisher.component;
            attribute :>> obligationId = "BU-I";
            attribute :>> kind = "induction";
            attribute :>> subjectPath = publisher.leanSource;
            attribute :>> subjectScope = publisher.leanScope;
            attribute :>> premise = "Checked conditional lemmas only; One integer node publication does not prove multi-file atomicity, script-line readback, diagnostic/effect reflection or filesystem durability";
        }
        part source : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = publisher.component;
            attribute :>> obligationId = "BU-S";
            attribute :>> kind = "source-refinement";
            attribute :>> subjectPath = publisher.leanSource;
            attribute :>> subjectScope = "BU-S:actual-source-refinement";
            attribute :>> premise = "Initial relation, every real source action/stutter, concrete observation reflection and progress; stage/finish/revalidate/publish or discard; open/read/write/close and exceptions must refine trace events";
        }
        part platform : GambitAssuranceRouting::ModelNeed {
            ref part :>> owner = publisher.component;
            attribute :>> obligationId = "BU-E";
            attribute :>> kind = "environment-refinement";
            attribute :>> subjectPath = publisher.sourcePath;
            attribute :>> subjectScope = "BU-E:actual-source-refinement";
            attribute :>> premise = "Complete effect/writer census, immutable read image, output group commit, argv/environment and failed I/O custody";
        }
    }
    part publisherDependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publisher.source;
        ref part :>> prerequisite = publisher.history;
    }
    part publisherDependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publisher.source;
        ref part :>> prerequisite = publisher.induction;
    }
    part publisherDependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = publisher.source;
        ref part :>> prerequisite = publisher.platform;
    }
}

