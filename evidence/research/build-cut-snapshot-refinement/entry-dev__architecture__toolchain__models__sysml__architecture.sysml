/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/toolchain/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitToolchain {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def ArtifactBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute cacheReuseRequested : Boolean;
        attribute allInputIdentitiesMatched : Boolean;
        attribute freshInstanceRequested : Boolean;
        attribute instanceInitializationComplete : Boolean;
    }

    requirement def ArtifactReuseLaw {
        subject boundary : ArtifactBoundary;
        require constraint { not boundary.cacheReuseRequested or boundary.allInputIdentitiesMatched }
    }

    requirement def InstanceLaw {
        subject boundary : ArtifactBoundary;
        require constraint { not boundary.freshInstanceRequested or boundary.instanceInitializationComplete }
    }


    part def MulticoreArtifactWitness {
        attribute sharedVmParallelismClaimed : Boolean;
        attribute effectiveThreadedVmVerified : Boolean;
        attribute effectiveSchedulerVerified : Boolean;
        attribute threadBackendVerified : Boolean;
        attribute processorBoundVerified : Boolean;
        attribute linkedRuntimeIdentityVerified : Boolean;
        attribute observedRuntimePopulationVerified : Boolean;
        attribute artifactReuseRequested : Boolean;
        attribute relevantInputProjectionMatched : Boolean;
        attribute frameRootAbiMatched : Boolean;
    }
    requirement def EffectiveMulticoreProfileLaw {
        subject witness : MulticoreArtifactWitness;
        require constraint { not witness.sharedVmParallelismClaimed or
            (witness.effectiveThreadedVmVerified and witness.effectiveSchedulerVerified and
             witness.threadBackendVerified and witness.processorBoundVerified and
             witness.linkedRuntimeIdentityVerified and witness.observedRuntimePopulationVerified) }
    }
    requirement def NativeArtifactProfileLaw {
        subject witness : MulticoreArtifactWitness;
        require constraint { not witness.artifactReuseRequested or
            (witness.relevantInputProjectionMatched and witness.frameRootAbiMatched) }
    }

    /* Blueprint metadata: design only; no satisfied or implemented contract. */
    part def BuildArtifactNode {
        attribute nodeId : String;
        attribute dependsOn : String;
        attribute product : String;
        attribute keyInputs : String;
        attribute reuseRule : String;
        attribute boundary : String;
    }
    part def BuildDeltaCase {
        attribute caseId : String;
        attribute change : String;
        attribute expectedWork : String;
        attribute limit : String;
    }
    part def BuildSource {
        attribute factId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute observation : String;
        attribute limit : String;
    }
    part buildNode0 : BuildArtifactNode {
        attribute :>> nodeId = "closure";
        attribute :>> dependsOn = "";
        attribute :>> product = "Scheme/Gerbil semantic dependency closure";
        attribute :>> keyInputs = "Ordered forms, includes/imports, phase/macro/FFI context, negative lookup and directory observations; producer identity";
        attribute :>> reuseRule = "One correct module or inseparable coupled group; mutable phase state requires widening";
        attribute :>> boundary = "Semantic cycles grouped only by real elaboration dependencies; do not merge ordinary runtime call cycles";
    }
    part buildNode1 : BuildArtifactNode {
        attribute :>> nodeId = "plan";
        attribute :>> dependsOn = "closure";
        attribute :>> product = "Completed semantic plan";
        attribute :>> keyInputs = "Closure digests, semantic compiler, options, module identity and relevant target projection";
        attribute :>> reuseRule = "Reuse only with complete semantic dependencies; fresh context instantiation remains separate";
        attribute :>> boundary = "Native compiler change need not invalidate a plan unless the plan reads its identity or relevant target decisions";
    }
    part buildNode2 : BuildArtifactNode {
        attribute :>> nodeId = "generated";
        attribute :>> dependsOn = "plan";
        attribute :>> product = "C, frame/root/layout metadata and module records";
        attribute :>> keyInputs = "Plan, generator/schema, target layout and ordered foreign text";
        attribute :>> reuseRule = "Publish as one generated output group; compare actual bytes before propagating";
        attribute :>> boundary = "Equivalent output early cutoff is valid only for every downstream-observed output, including metadata";
    }
    part buildNode3 : BuildArtifactNode {
        attribute :>> nodeId = "configured";
        attribute :>> dependsOn = "";
        attribute :>> product = "Configured RTS/header capability";
        attribute :>> keyInputs = "RTS source, configuration rules, target/SDK, configure inputs, requested and effective profile";
        attribute :>> reuseRule = "Requested flags and goal overlays are distinct from effective configured capability";
        attribute :>> boundary = "Profile mismatch invalidates affected declarations/objects and native acceptance";
    }
    part buildNode4 : BuildArtifactNode {
        attribute :>> nodeId = "objects";
        attribute :>> dependsOn = "generated; configured; linkPlan";
        attribute :>> product = "Module and runtime objects";
        attribute :>> keyInputs = "C/header/depfile closure, compiler/tool bytes, argv, env, cwd, target and ABI projection";
        attribute :>> reuseRule = "Compile independent ready objects under one CPU/memory budget";
        attribute :>> boundary = "A monolithic generated module remains a serial action until a semantics-safe producer split exists";
    }
    part buildNode5 : BuildArtifactNode {
        attribute :>> nodeId = "link";
        attribute :>> dependsOn = "objects; linkPlan";
        attribute :>> product = "Archives, shared libraries and executable";
        attribute :>> keyInputs = "Ordered module demand/supply/init data, objects, linker, flags and runtime ABI";
        attribute :>> reuseRule = "No alphabetical reordering or unordered set hashing of link inputs";
        attribute :>> boundary = "Successful interpreter behavior does not validate compiled archive identity";
    }
    part buildNode6 : BuildArtifactNode {
        attribute :>> nodeId = "publish";
        attribute :>> dependsOn = "link";
        attribute :>> product = "Complete artifact-set manifest";
        attribute :>> keyInputs = "All expected output bytes, successful exit, sealed input generation and lineage";
        attribute :>> reuseRule = "Atomic visibility of manifest after all products verify; attempt logs remain independent";
        attribute :>> boundary = "Cancellation or partial output never supplies a cache success or current native acceptance";
    }
    part semanticLinkPlan : BuildArtifactNode {
        attribute :>> nodeId = "linkPlan";
        attribute :>> dependsOn = "generated";
        attribute :>> product = "Semantic module link plan and generated linkfile C";
        attribute :>> keyInputs = "Ordered module demand/supply/init/flags metadata, semantic linker identity and relevant target projection";
        attribute :>> reuseRule = "Generate linkfile before its own object; independent module objects do not depend on this plan";
        attribute :>> boundary = "This is an artifact-family projection; instantiate only real per-product edges, never all-to-all family dependencies";
    }
    part buildDelta0 : BuildDeltaCase {
        attribute :>> caseId = "noOp";
        attribute :>> change = "All declared semantic/native inputs and expected outputs identical";
        attribute :>> expectedWork = "Validate previous dependency cut and output identity; no eligible generation/compile/link actions";
        attribute :>> limit = "Metadata/hash checking still costs work; live import/context instantiation not automatically reused";
    }
    part buildDelta1 : BuildDeltaCase {
        attribute :>> caseId = "leafScheme";
        attribute :>> change = "One independent module implementation changes";
        attribute :>> expectedWork = "Reelaborate correct semantic unit; regenerate it; compile changed output; link affected closure";
        attribute :>> limit = "If module metadata/semantic exports unchanged, avoid unrelated generation; strong dependencies still propagate";
    }
    part buildDelta2 : BuildDeltaCase {
        attribute :>> caseId = "macroOrInclude";
        attribute :>> change = "A used macro, include or compile-time dependency changes";
        attribute :>> expectedWork = "Invalidate its actual semantic consumers; regenerate their affected descendants";
        attribute :>> limit = "Unsealed dynamic context means widen unit or deny cache admission";
    }
    part buildDelta3 : BuildDeltaCase {
        attribute :>> caseId = "sameOutput";
        attribute :>> change = "A valid producer reruns and all consumed output bytes are unchanged";
        attribute :>> expectedWork = "Retain new lineage but stop downstream recomputation at output identity boundary";
        attribute :>> limit = "Compare C, side metadata and link records, not only one .c file";
    }
    part buildDelta4 : BuildDeltaCase {
        attribute :>> caseId = "compilerOnly";
        attribute :>> change = "Only native compiler identity or native flags change";
        attribute :>> expectedWork = "Recompile affected objects and relink; retain independently valid semantic plans";
        attribute :>> limit = "Target/layout effects read by plan or generator also invalidate those projections";
    }
    part buildDelta5 : BuildDeltaCase {
        attribute :>> caseId = "frameAbi";
        attribute :>> change = "Frame/root/layout schema changes";
        attribute :>> expectedWork = "Regenerate affected declarations and rebuild every ABI consumer through final link";
        attribute :>> limit = "Never mix old descriptors with new scanners or suppress this necessary rebuild";
    }
    part buildDelta6 : BuildDeltaCase {
        attribute :>> caseId = "linkOnly";
        attribute :>> change = "Only link mode or flags change";
        attribute :>> expectedWork = "Relink affected closure using ordered unchanged objects";
        attribute :>> limit = "LTO or codegen-affecting options may also invalidate object/backend stages";
    }
    part buildDelta7 : BuildDeltaCase {
        attribute :>> caseId = "bootstrapCompiler";
        attribute :>> change = "Bootstrap producer changes";
        attribute :>> expectedWork = "Distinct compiler-stage keys; rebuild their actual dependents";
        attribute :>> limit = "Two passes for qualification or self-hosting are not redundant merely because source is equal";
    }
    part buildDelta8 : BuildDeltaCase {
        attribute :>> caseId = "cancelOrFail";
        attribute :>> change = "A task fails, is cancelled, or loses input-generation validity";
        attribute :>> expectedWork = "Drain/cancel owned children, discard unpublished staging, retain failed attempt";
        attribute :>> limit = "Never mark old output current because a file happens to exist";
    }
    part buildDelta9 : BuildDeltaCase {
        attribute :>> caseId = "resourcePressure";
        attribute :>> change = "Nested generator/compiler/link work competes for CPU or memory";
        attribute :>> expectedWork = "Share one token pool; parent awaiting child returns or delegates capacity";
        attribute :>> limit = "Actual compiler-internal parallelism must be declared or conservatively bounded; no throughput claim here";
    }
    part buildSource0 : BuildSource {
        attribute :>> factId = "makePhases";
        attribute :>> sourcePath = "vendor/gambit/makefile.in";
        attribute :>> sourceRanges = "105-149";
        attribute :>> observation = "Make uses jobserver-sensitive phases and a global four-phase sequence; from-scratch explicitly cleans/builds twice";
        attribute :>> limit = "There is existing parallelism; necessity of each whole-phase edge must be audited before removing it";
    }
    part buildSource1 : BuildSource {
        attribute :>> factId = "moduleRules";
        attribute :>> sourcePath = "vendor/gambit/lib/makefile.in";
        attribute :>> sourceRanges = "184-202";
        attribute :>> observation = "Per-module Scheme-to-C rule and archive composition already exist";
        attribute :>> limit = "Preserve correct compilation units; do not replace with an opaque full-project action";
    }
    part buildSource2 : BuildSource {
        attribute :>> factId = "compilerRules";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "268-324";
        attribute :>> observation = "Generation, semantic linkfile and object/library/executable stages have distinct dependencies";
        attribute :>> limit = "Phase flattening needs explicit producer and bootstrap ordering, not deletion of all barriers";
    }
    part buildSource3 : BuildSource {
        attribute :>> factId = "cpuBudget";
        attribute :>> sourcePath = "src/gambit_smp/gambit_build_primitives.py";
        attribute :>> sourceRanges = "18-30;65-70";
        attribute :>> observation = "Current makeJobs and compilerProcessors share a host-derived CPU budget";
        attribute :>> limit = "Existing support should be reused; no proof of all downstream nested schedulers";
    }
    part buildSource4 : BuildSource {
        attribute :>> factId = "profileProjection";
        attribute :>> sourcePath = "src/gambit_smp/build_profile.py";
        attribute :>> sourceRanges = "18-43";
        attribute :>> observation = "Literal source profile and required threaded-VM overlay are distinct";
        attribute :>> limit = "No active configured-header or runtime capability inferred from flags alone";
    }
    part buildSource5 : BuildSource {
        attribute :>> factId = "streamExecutor";
        attribute :>> sourcePath = "../../patches/gerbil-v19-darwin/0002-gerbil-streaming-compile-executor.patch";
        attribute :>> sourceRanges = "1-20;59-79";
        attribute :>> observation = "Parent patch already streams native jobs and permits follow-up jobs while closing the producer";
        attribute :>> limit = "This is source/patch intent, not a newly qualified build speedup";
    }
    part buildSource6 : BuildSource {
        attribute :>> factId = "sourceToolchain";
        attribute :>> sourcePath = "../../tools/ci/build_source_toolchain.sh";
        attribute :>> sourceRanges = "55-62;101-134";
        attribute :>> observation = "Compiler/patch identity and phased construction exist; script checks artifacts after an upstream wrapper can hide failure";
        attribute :>> limit = "Extend actual support; no duplicate generic executor justified by ignoring these checks";
    }

    part def IncrementalBuildCut {
        attribute cacheSuccessPublished : Boolean;
        attribute relevantInputsSealed : Boolean;
        attribute dynamicDependenciesClosed : Boolean;
        attribute outputsComplete : Boolean;
        attribute sourceGenerationStable : Boolean;
        attribute actionSucceeded : Boolean;
        attribute schedulerAdmitted : Boolean;
        attribute sharedCpuGrantRespected : Boolean;
        attribute memoryAdmissionRespected : Boolean;
        attribute dependencyOrderPreserved : Boolean;
    }
    requirement def IncrementalBuildPublicationLaw {
        subject cut : IncrementalBuildCut;
        require constraint { not cut.cacheSuccessPublished or
            (cut.relevantInputsSealed and cut.dynamicDependenciesClosed and
             cut.outputsComplete and cut.sourceGenerationStable and cut.actionSucceeded) }
    }
    requirement def ParallelBuildAdmissionLaw {
        subject cut : IncrementalBuildCut;
        require constraint { not cut.schedulerAdmitted or
            (cut.sharedCpuGrantRespected and cut.memoryAdmissionRespected and cut.dependencyOrderPreserved) }
    }

    /* Source-chain and model associations; no native refinement asserted. */
    part def SourceChainNode {
        attribute nodeId : String;
        attribute dependsOn : String;
        attribute product : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute quintNode : String;
        attribute inputCut : String;
        attribute limit : String;
    }
    part def SourceChainDelta {
        attribute caseId : String;
        attribute change : String;
        attribute currentPath : String;
        attribute proposedWork : String;
        attribute mathematicalCount : String;
        attribute limit : String;
        attribute obligationId : String;
    }
    part def SourcePhaseCut {
        attribute phaseId : String;
        attribute currentRole : String;
        attribute proposedCut : String;
        attribute admission : String;
        attribute mustRetain : String;
        attribute retirement : String;
    }
    part def SourceChainFact {
        attribute factId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute observation : String;
        attribute limit : String;
    }
    part chainNode0 : SourceChainNode {
        attribute :>> nodeId = "genA";
        attribute :>> dependsOn = "";
        attribute :>> product = "_t-c-3.scm -> _t-c-3.c";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "307-308";
        attribute :>> quintNode = "0";
        attribute :>> inputCut = "Closed compilation context, generic/fixnum and include-adt inputs; frozen gsc-boot and target options";
        attribute :>> limit = "Only this implementation leaf changes; no reverse source include is inferred from library membership";
    }
    part chainNode1 : SourceChainNode {
        attribute :>> nodeId = "genB";
        attribute :>> dependsOn = "";
        attribute :>> product = "_utils.scm -> _utils.c";
        attribute :>> sourcePath = "vendor/gambit/gsc/_utils.scm";
        attribute :>> sourceRanges = "7-12";
        attribute :>> quintNode = "1";
        attribute :>> inputCut = "Fixnum and four ADT includes, same producer/profile";
        attribute :>> limit = "Representative independent unit; not a model of the remaining compiler units";
    }
    part chainNode2 : SourceChainNode {
        attribute :>> nodeId = "objA";
        attribute :>> dependsOn = "genA";
        attribute :>> product = "_t-c-3.c -> _t-c-3@obj@";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "304-305;346-346";
        attribute :>> quintNode = "2";
        attribute :>> inputCut = "Generated C plus gambit.h, actual compiler and flags";
        attribute :>> limit = "Can overlap other ready generation after phase-edge replacement qualifies";
    }
    part chainNode3 : SourceChainNode {
        attribute :>> nodeId = "objB";
        attribute :>> dependsOn = "genB";
        attribute :>> product = "_utils.c -> _utils@obj@";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "304-305;346-346";
        attribute :>> quintNode = "3";
        attribute :>> inputCut = "Same object contract for another module";
        attribute :>> limit = "No independent executor or new job budget";
    }
    part chainNode4 : SourceChainNode {
        attribute :>> nodeId = "libPlan";
        attribute :>> dependsOn = "genA; genB";
        attribute :>> product = "$(GAMBIT_GSC_LIB_C)";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "289-290";
        attribute :>> quintNode = "4";
        attribute :>> inputCut = "All 33 library modules in declared order plus runtime link metadata; two representative inputs in QNT";
        attribute :>> limit = "Other 31 inputs are frozen only in the small model; broad macro source refinement remains open";
    }
    part chainNode5 : SourceChainNode {
        attribute :>> nodeId = "libPlanObj";
        attribute :>> dependsOn = "libPlan";
        attribute :>> product = "$(GAMBIT_GSC_LIB_O)";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "304-305";
        attribute :>> quintNode = "5";
        attribute :>> inputCut = "Generated library metadata C and header ABI";
        attribute :>> limit = "Metadata equality can cut off this work only after a separate producer projection exists";
    }
    part chainNode6 : SourceChainNode {
        attribute :>> nodeId = "archive";
        attribute :>> dependsOn = "objA; objB; libPlanObj";
        attribute :>> product = "$(LIBRARY)";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "170-177;281-288";
        attribute :>> quintNode = "6";
        attribute :>> inputCut = "All library objects and generated descriptor object; archive/shared mode preserved";
        attribute :>> limit = "Unchanged omitted objects do not grant permission to omit changed macro consumers";
    }
    part chainNode7 : SourceChainNode {
        attribute :>> nodeId = "exePlan";
        attribute :>> dependsOn = "libPlan";
        attribute :>> product = "_gsc_.c";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "295-296";
        attribute :>> quintNode = "7";
        attribute :>> inputCut = "Executable-module metadata and library linkfile; ordered compiler link inputs";
        attribute :>> limit = "The executable wrapper _gsc.c is a distinct fixed input in the small model";
    }
    part chainNode8 : SourceChainNode {
        attribute :>> nodeId = "exePlanObj";
        attribute :>> dependsOn = "exePlan";
        attribute :>> product = "_gsc_@obj@";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "298-299";
        attribute :>> quintNode = "8";
        attribute :>> inputCut = "Executable linkfile C and configured headers";
        attribute :>> limit = "Not the _gsc@obj@ wrapper object";
    }
    part chainNode9 : SourceChainNode {
        attribute :>> nodeId = "executable";
        attribute :>> dependsOn = "archive; exePlanObj";
        attribute :>> product = "gsc@exe@";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "292-293";
        attribute :>> quintNode = "9";
        attribute :>> inputCut = "Full EXECUTABLE_OBJECTS and LINK_LIBS; exact configured link mode";
        attribute :>> limit = "Build product only; not a whole SMP or Gerbil correctness receipt";
    }
    part chainDelta0 : SourceChainDelta {
        attribute :>> caseId = "noChange";
        attribute :>> change = "All semantic inputs, producer/target, headers, ordered metadata and outputs unchanged";
        attribute :>> currentPath = "Make may revisit phony phases/stamp; Git stamp branch preserves unchanged bytes; non-Git branch rewrites stamp.h";
        attribute :>> proposedWork = "Validate complete cuts; zero eligible generation/compile/link work";
        attribute :>> mathematicalCount = "Abstract 10-node model: 0 executions if all saved signatures match";
        attribute :>> limit = "Fresh validation/planning and live context instantiation still cost work; changed bootstrap identity is not this case";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part chainDelta1 : SourceChainDelta {
        attribute :>> caseId = "leaf";
        attribute :>> change = "Implementation-only change to _t-c-3.scm under fixed bootstrap compiler; exported link metadata assumed unchanged";
        attribute :>> currentPath = "Its .scm.c recipe, library metadata targets and dependent object/library/executable recipes become eligible by timestamps";
        attribute :>> proposedWork = "Regenerate leaf, compile changed leaf C, rebuild affected library and executable; stop unchanged metadata descendants";
        attribute :>> mathematicalCount = "Abstract 10-node model: nodes 0,2,6,9 = 4 executions under its declared oracle";
        attribute :>> limit = "Current targ-link-info reads generated C; metadata-only reuse needs an explicit producer/projection. Archive/executable relink generally remains necessary";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part chainDelta2 : SourceChainDelta {
        attribute :>> caseId = "macro";
        attribute :>> change = "Semantic change to include-adt in fixnum.scm";
        attribute :>> currentPath = "MODULES_C explicitly depends on fixnum.scm: 33 library modules plus executable module, 34 generation targets";
        attribute :>> proposedWork = "Invalidate real semantic consumers; retain broad set until producer dependency closure proves a narrower set";
        attribute :>> mathematicalCount = "Two-unit model: up to all 10 nodes; real 34-unit impact is not certified by that projection";
        attribute :>> limit = "A shared macro can genuinely invalidate almost everything. No claimed N-to-1 generation speedup; unchanged downstream bytes may still cut off work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part phaseCut0 : SourcePhaseCut {
        attribute :>> phaseId = "phase1";
        attribute :>> currentRole = "Generate library and executable module C";
        attribute :>> proposedCut = "Reuse existing per-module generation tasks; replace blanket phase release only where true dependencies allow";
        attribute :>> admission = "Frozen producer and common inputs; independent compilation contexts; preserve module and bootstrap identities";
        attribute :>> mustRetain = "Keep macro/elaboration dependencies and all source readers";
        attribute :>> retirement = "Retire whole-phase generation envelope only after all actual units use explicit rules";
    }
    part phaseCut1 : SourcePhaseCut {
        attribute :>> phaseId = "phase2";
        attribute :>> currentRole = "Generate library and executable semantic linkfiles";
        attribute :>> proposedCut = "Separate library link-plan and executable link-plan tasks from unrelated object compilation";
        attribute :>> admission = "All ordered input metadata ready; executable plan waits for its actual library metadata";
        attribute :>> mustRetain = "Keep actual input readiness; do not reorder modules";
        attribute :>> retirement = "Retire the global phase barrier, not its true producer edges";
    }
    part phaseCut2 : SourcePhaseCut {
        attribute :>> phaseId = "phase3";
        attribute :>> currentRole = "Shared mode compiles library objects; static mode builds library";
        attribute :>> proposedCut = "Stream each ready object; archive/shared-library task waits for its exact object list";
        attribute :>> admission = "One compiler/jobserver budget; per-object header/ABI inputs closed";
        attribute :>> mustRetain = "Keep archive dependencies and configured shared/static differences";
        attribute :>> retirement = "Retire delayed object release and duplicate scheduling only after the old callers migrate";
    }
    part phaseCut3 : SourcePhaseCut {
        attribute :>> phaseId = "phase4";
        attribute :>> currentRole = "core library/executable construction";
        attribute :>> proposedCut = "Release final archive/link tasks when their actual inputs are committed";
        attribute :>> admission = "Exact semantic/native closure and preserved failure propagation";
        attribute :>> mustRetain = "Keep link and output-set completion, no partial publish";
        attribute :>> retirement = "Retire final blanket orchestration only after native/action parity, not from graph shape alone";
    }
    part phaseCut4 : SourcePhaseCut {
        attribute :>> phaseId = "bootstrap";
        attribute :>> currentRole = "from-scratch cleans/bootstrap/core and can change producer";
        attribute :>> proposedCut = "Model each compiler-producing stage with its own identity";
        attribute :>> admission = "Source and producing compiler lineage, boot/gsc-boot setup and runtime header closure";
        attribute :>> mustRetain = "Required self-hosting stage edges remain";
        attribute :>> retirement = "No retirement of a necessary second producer stage merely because source bytes repeat";
    }
    part chainFact0 : SourceChainFact {
        attribute :>> factId = "chain-make";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "73-85;93-111;170-177;268-308;312-346";
        attribute :>> observation = "Real module/descriptor/archive/executable rules and broad shared prerequisites";
        attribute :>> limit = "Template variables are not an inspected active Darwin link configuration";
    }
    part chainFact1 : SourceChainFact {
        attribute :>> factId = "phase-make";
        attribute :>> sourcePath = "vendor/gambit/makefile.in";
        attribute :>> sourceRanges = "105-149;193-205;226-227";
        attribute :>> observation = "Jobserver-sensitive phases, bootstrap choice and stamp call";
        attribute :>> limit = "Recursive recipe visits are not proof that native work reruns";
    }
    part chainFact2 : SourceChainFact {
        attribute :>> factId = "stamp";
        attribute :>> sourcePath = "vendor/gambit/include/makefile.in";
        attribute :>> sourceRanges = "301-331";
        attribute :>> observation = "Git branch compares stamp version; non-Git branch writes empty stamp.h";
        attribute :>> limit = "No-op cannot assume every source/export profile preserves timestamps";
    }
    part chainFact3 : SourceChainFact {
        attribute :>> factId = "leaf-inputs";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-3.scm";
        attribute :>> sourceRanges = "7-12";
        attribute :>> observation = "Generic and four ADT includes are real source inputs";
        attribute :>> limit = "Lexical includes alone are not complete dynamic compiler read closure";
    }
    part chainFact4 : SourceChainFact {
        attribute :>> factId = "other-inputs";
        attribute :>> sourcePath = "vendor/gambit/gsc/_utils.scm";
        attribute :>> sourceRanges = "7-12";
        attribute :>> observation = "Independent utility module includes fixnum and ADT sources";
        attribute :>> limit = "Representative control, not an independently executed control";
    }
    part chainFact5 : SourceChainFact {
        attribute :>> factId = "macro-implementation";
        attribute :>> sourcePath = "vendor/gambit/gsc/fixnum.scm";
        attribute :>> sourceRanges = "7-17";
        attribute :>> observation = "include-adt macro changes declarations and includes ../gsc/filename";
        attribute :>> limit = "Compiler-time state and file reads belong to the semantic cut";
    }
    part chainFact6 : SourceChainFact {
        attribute :>> factId = "generic-route";
        attribute :>> sourcePath = "vendor/gambit/gsc/generic.scm";
        attribute :>> sourceRanges = "7-9";
        attribute :>> observation = "Generic mode transitively includes fixnum";
        attribute :>> limit = "Do not treat generic.scm and fixnum.scm as independent inputs";
    }
    part chainFact7 : SourceChainFact {
        attribute :>> factId = "link-reader";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-925;1086-1105";
        attribute :>> observation = "targ-link-info reads leading generated-C metadata and validates compiler/target; link merges ordered module info";
        attribute :>> limit = "Metadata projection is semantic and producer-specific, not arbitrary text slicing";
    }
    part chainFact8 : SourceChainFact {
        attribute :>> factId = "driver-model";
        attribute :>> sourcePath = "models/gambit/native_build_driver_correspondence.qnt";
        attribute :>> sourceRanges = "1-44";
        attribute :>> observation = "Existing model admits a scoped budget investigation";
        attribute :>> limit = "Not an incremental-build dependency or parallel scheduler proof";
    }
}
