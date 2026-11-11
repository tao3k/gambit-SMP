package GerbilPhaseReadiness {
 private import ScalarValues::*;
 /* This model refines the Gerbil module lane; no source simulation asserted. */
 part def ActionFamily {
  attribute key : String;
  attribute number : Integer;
  attribute predecessors : String;
  attribute sourceAnchor : String;
  attribute labelText : String;
  attribute contract : String;
 }
 part macroInterface : ActionFamily {
 attribute :>> key = "macroInterface";
 attribute :>> number = 0;
 attribute :>> predecessors = "Set()";
 attribute :>> sourceAnchor = "iter/macros.ss:4-39";
 attribute :>> labelText = "Coherent macro interface";
 attribute :>> contract = "Generated SSI plus producer and phase-input identity; file existence alone cannot execute for";
 }
 part phaseSupport : ActionFamily {
 attribute :>> key = "phaseSupport";
 attribute :>> number = 1;
 attribute :>> predecessors = "Set(0)";
 attribute :>> sourceAnchor = "iter/macros.ss:10-32,41-84; expander/module.ss:839-875";
 attribute :>> labelText = "Executable phase closure";
 attribute :>> contract = "Compiled transformer and all executed helpers, including required native/runtime support; full closure remains an admission premise";
 }
 part facade : ActionFamily {
 attribute :>> key = "facade";
 attribute :>> number = 2;
 attribute :>> predecessors = "Set(0, 1)";
 attribute :>> sourceAnchor = "iter/api.ss:4-24; iter.ss:4-5";
 attribute :>> labelText = "Re-exported phase program";
 attribute :>> contract = "Aggregate two re-export hops; fresh mutable context is constructed per consumer, not reused";
 }
 part expandA : ActionFamily {
 attribute :>> key = "expandA";
 attribute :>> number = 3;
 attribute :>> predecessors = "Set(2)";
 attribute :>> sourceAnchor = "string/misc.ss:34-35,227-234";
 attribute :>> labelText = "Expand string/misc";
 attribute :>> contract = "Candidate independent session; all other imports are fixed complete inputs";
 }
 part expandB : ActionFamily {
 attribute :>> key = "expandB";
 attribute :>> number = 4;
 attribute :>> predecessors = "Set(2)";
 attribute :>> sourceAnchor = "sync/wg.ss:4-6,37-38";
 attribute :>> labelText = "Expand sync/wg";
 attribute :>> contract = "Candidate independent session; channel and error dependency closure fixed and must not alias mutable expansion state";
 }
 part nativeA : ActionFamily {
 attribute :>> key = "nativeA";
 attribute :>> number = 5;
 attribute :>> predecessors = "Set(3)";
 attribute :>> sourceAnchor = "compiler/driver.ss:621-641,647-705";
 attribute :>> labelText = "Compile string/misc runtime";
 attribute :>> contract = "Native action includes all target ABI and consumed optimization inputs";
 }
 part nativeB : ActionFamily {
 attribute :>> key = "nativeB";
 attribute :>> number = 6;
 attribute :>> predecessors = "Set(4)";
 attribute :>> sourceAnchor = "compiler/driver.ss:621-641,647-705";
 attribute :>> labelText = "Compile sync/wg runtime";
 attribute :>> contract = "May overlap nativeA under declared budget; does not imply one-VM true parallelism";
 }
 part runtimeOnly : ActionFamily {
 attribute :>> key = "runtimeOnly";
 attribute :>> number = 7;
 attribute :>> predecessors = "Set(0)";
 attribute :>> sourceAnchor = "iter/iterators.ss:9-22; compiler/driver.ss:707-747";
 attribute :>> labelText = "Certified runtime-only remainder";
 attribute :>> contract = "Optional nonempty remainder only after separating every phase-executed helper; otherwise collapse into phaseSupport";
 }
 part link : ActionFamily {
 attribute :>> key = "link";
 attribute :>> number = 8;
 attribute :>> predecessors = "Set(5, 6, 7)";
 attribute :>> sourceAnchor = "std/make.ss:583-621";
 attribute :>> labelText = "Example combined load/link closure";
 attribute :>> contract = "Synthetic common request for both consumers; not a claimed existing executable target";
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GM-H";
 attribute :>> kind = "interleaving";
 attribute :>> subjectPath = "models/build/gerbil_phase_readiness.qnt";
 attribute :>> subjectScope = "gerbil_phase_readiness:Test$";
 attribute :>> premise = "Finite nine-family protocol: phase closure, reuse, independent starts, complete publication and cancellation; excludes arbitrary Scheme effects";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GM-I";
 attribute :>> kind = "induction";
 attribute :>> subjectPath = "models/build/GerbilPhaseReadiness.lean";
 attribute :>> subjectScope = "GerbilModuleBuild:stepPreserves;tracePreserves;concurrentEnabled;coherentEpoch;reusePreserves;positiveWork";
 attribute :>> premise = "Conditional pure state-transition lemmas; full QNT correspondence, Scheme state isolation and source observation fidelity remain open";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GM-S";
 attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/build/GerbilPhaseReadiness.lean";
 attribute :>> subjectScope = "GM-S:gerbil-source-simulation";
 attribute :>> premise = "Actual selected imports, phase helpers, optimizer/FFI effects and complete output manifests; optional runtime-only split requires audit";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GM-E";
 attribute :>> kind = "environment-refinement";
 attribute :>> subjectPath = "dev/architecture/toolchain/gerbil-macro-chain-design.org";
 attribute :>> subjectScope = "GM-E:darwin-linux-attribution";
 attribute :>> premise = "Installed gxi/gxc identity, actual phase artifacts, one-VM parallel capability and matched Darwin/Linux profiles remain unresolved";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = history;
 }
 part dependency1 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = induction;
 }
 part dependency2 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = platform;
 }
 part dependency3 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = GambitBuildAssurance::planner.source;
 }
 part dependency4 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = GambitBuildAssurance::scheduler.source;
 }
 part dependency5 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = source;
 ref part :>> prerequisite = GambitBuildAssurance::publisher.source;
 }
 attribute benefitRule : String = "R > H: removed repeated work must exceed validation, isolated-session initialization, IPC and publication work; no measured speedup";

    part def BenefitCase {
        attribute caseId : String;
        attribute condition : String;
        attribute workBoundary : String;
        attribute overhead : String;
        attribute retirement : String;
    }
    part benefit0 : BenefitCase {
        attribute :>> caseId = "noChange";
        attribute :>> condition = "All complete consumed keys match; no requested new live activation";
        attribute :>> workBoundary = "0 compile families";
        attribute :>> overhead = "Validation and manifest lookup; fresh activation charged separately";
        attribute :>> retirement = "Timestamp-only reuse authority retires only after complete cuts and successful-origin parity";
    }
    part benefit1 : BenefitCase {
        attribute :>> caseId = "runtimeBody";
        attribute :>> condition = "Only certified runtime-only body projection changes";
        attribute :>> workBoundary = "2 compile/link families (7,8); consumer expansion families spared";
        attribute :>> overhead = "Projection validation; runtime-only nonempty split remains unproved";
        attribute :>> retirement = "Whole-module wait can retire only for consumers proved independent of that body";
    }
    part benefit2 : BenefitCase {
        attribute :>> caseId = "optimizer";
        attribute :>> condition = "Consumer-visible optimizer projection changes";
        attribute :>> workBoundary = "5 families (3,4,5,6,8) remain eligible";
        attribute :>> overhead = "Optimization metadata identity and invalidation edges";
        attribute :>> retirement = "Do not retire optimizer-dependent invalidation on interface-name equality";
    }
    part benefit3 : BenefitCase {
        attribute :>> caseId = "macroHelper";
        attribute :>> condition = "Executed transformer/helper projection changes";
        attribute :>> workBoundary = "8 families (0-6,8) remain eligible in selected model";
        attribute :>> overhead = "Transitive phase closure and immutable program storage";
        attribute :>> retirement = "Unchanged runtime-only output may cut off; this is not a claim of eight real source commands";
    }
    part benefit4 : BenefitCase {
        attribute :>> caseId = "parallelConsumers";
        attribute :>> condition = "Common phase closure ready; other imports fixed; isolated effects";
        attribute :>> workBoundary = "2 independent consumer expansion jobs, not 12";
        attribute :>> overhead = "Fresh sessions, IPC or in-VM isolation and global CPU/memory admission";
        attribute :>> retirement = "Shared import lock retires only after every protected state mutation has a new owner";
    }
    part def LearningRecord {
        attribute mechanism : String;
        attribute primarySource : String;
        attribute evidence : String;
        attribute reflection : String;
        ref part sourceDuty : GambitAssuranceRouting::ModelNeed;
    }
    part learning0 : LearningRecord {
        attribute :>> mechanism = "Chez phase separation";
        attribute :>> primarySource = "https://cisco.github.io/ChezScheme/csug10.0/system.html";
        attribute :>> evidence = "visit and revisit separate compile-time and runtime portions of compiled code";
        attribute :>> reflection = "Gerbil needs separately credentialed phase execution and runtime activation; compiled program reuse is not mutable context reuse";
        ref part :>> sourceDuty = source;
    }
    part learning1 : LearningRecord {
        attribute :>> mechanism = "Chez loadability";
        attribute :>> primarySource = "https://cisco.github.io/ChezScheme/csug10.0/system.html";
        attribute :>> evidence = "verify-loadability checks relevant dependency compatibility without executing code";
        attribute :>> reflection = "Add phase-specific manifest validation; successful validation does not establish successful initialization or effect isolation";
        ref part :>> sourceDuty = source;
    }
    part learning2 : LearningRecord {
        attribute :>> mechanism = "OCaml product boundaries";
        attribute :>> primarySource = "https://ocaml.org/docs/compiler-backend";
        attribute :>> evidence = "Compiled interfaces, native objects and cross-module optimization information are distinct products";
        attribute :>> reflection = "Gerbil must distinguish exported syntax interfaces, executed phase helpers and optimizer inputs; SSI is not interchangeable with CMI";
        ref part :>> sourceDuty = source;
    }
    part learning3 : LearningRecord {
        attribute :>> mechanism = "Dune dependency-aware planning";
        attribute :>> primarySource = "https://dune.readthedocs.io/en/stable/explanation/tour/rule-generation.html";
        attribute :>> evidence = "Memo shares internal computations and tracks recomputation; Action_builder tracks action dependencies and targets";
        attribute :>> reflection = "Cache producer planning separately from generated/native artifacts; a persistent service still needs explicit phase effects and fresh session ownership";
        ref part :>> sourceDuty = source;
    }

 attribute cohort : String = "gerbil-gambit-bootstrap-audit@1cfb032c7a1612637da6205f5f8a15683eba3ba0; selected source hashes required";
}

