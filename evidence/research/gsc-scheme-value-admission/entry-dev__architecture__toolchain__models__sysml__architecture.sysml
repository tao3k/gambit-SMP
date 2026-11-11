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

    /* Complete generation inventory. Values are authored organization metadata;
     * the view tool checks correspondence to the frozen Make template. */
    part def GenerationTarget {
        attribute moduleName : String;
        attribute role : String;
        attribute populationNode : String;
        attribute selectedNode : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute inputCut : String;
        attribute projectionBoundary : String;
    }
    part generationTarget0 : GenerationTarget {
        attribute :>> moduleName = "_host";
        attribute :>> role = "library";
        attribute :>> populationNode = "0";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget1 : GenerationTarget {
        attribute :>> moduleName = "_utils";
        attribute :>> role = "library";
        attribute :>> populationNode = "1";
        attribute :>> selectedNode = "1 / object 3";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget2 : GenerationTarget {
        attribute :>> moduleName = "_source";
        attribute :>> role = "library";
        attribute :>> populationNode = "2";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget3 : GenerationTarget {
        attribute :>> moduleName = "_parms";
        attribute :>> role = "library";
        attribute :>> populationNode = "3";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget4 : GenerationTarget {
        attribute :>> moduleName = "_env";
        attribute :>> role = "library";
        attribute :>> populationNode = "4";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget5 : GenerationTarget {
        attribute :>> moduleName = "_ptree1";
        attribute :>> role = "library";
        attribute :>> populationNode = "5";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget6 : GenerationTarget {
        attribute :>> moduleName = "_ptree2";
        attribute :>> role = "library";
        attribute :>> populationNode = "6";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget7 : GenerationTarget {
        attribute :>> moduleName = "_gvm";
        attribute :>> role = "library";
        attribute :>> populationNode = "7";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget8 : GenerationTarget {
        attribute :>> moduleName = "_back";
        attribute :>> role = "library";
        attribute :>> populationNode = "8";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget9 : GenerationTarget {
        attribute :>> moduleName = "_front";
        attribute :>> role = "library";
        attribute :>> populationNode = "9";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget10 : GenerationTarget {
        attribute :>> moduleName = "_prims";
        attribute :>> role = "library";
        attribute :>> populationNode = "10";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget11 : GenerationTarget {
        attribute :>> moduleName = "_assert";
        attribute :>> role = "library";
        attribute :>> populationNode = "11";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget12 : GenerationTarget {
        attribute :>> moduleName = "_asm";
        attribute :>> role = "library";
        attribute :>> populationNode = "12";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget13 : GenerationTarget {
        attribute :>> moduleName = "_x86";
        attribute :>> role = "library";
        attribute :>> populationNode = "13";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget14 : GenerationTarget {
        attribute :>> moduleName = "_arm";
        attribute :>> role = "library";
        attribute :>> populationNode = "14";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget15 : GenerationTarget {
        attribute :>> moduleName = "_riscv";
        attribute :>> role = "library";
        attribute :>> populationNode = "15";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget16 : GenerationTarget {
        attribute :>> moduleName = "_codegen";
        attribute :>> role = "library";
        attribute :>> populationNode = "16";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget17 : GenerationTarget {
        attribute :>> moduleName = "_t-univ-1";
        attribute :>> role = "library";
        attribute :>> populationNode = "17";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget18 : GenerationTarget {
        attribute :>> moduleName = "_t-univ-2";
        attribute :>> role = "library";
        attribute :>> populationNode = "18";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget19 : GenerationTarget {
        attribute :>> moduleName = "_t-univ-3";
        attribute :>> role = "library";
        attribute :>> populationNode = "19";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget20 : GenerationTarget {
        attribute :>> moduleName = "_t-univ-4";
        attribute :>> role = "library";
        attribute :>> populationNode = "20";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget21 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-abstract-machine";
        attribute :>> role = "library";
        attribute :>> populationNode = "21";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget22 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-primitives";
        attribute :>> role = "library";
        attribute :>> populationNode = "22";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget23 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-object-desc";
        attribute :>> role = "library";
        attribute :>> populationNode = "23";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget24 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-utils";
        attribute :>> role = "library";
        attribute :>> populationNode = "24";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget25 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-backend-x86";
        attribute :>> role = "library";
        attribute :>> populationNode = "25";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget26 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-backend-arm";
        attribute :>> role = "library";
        attribute :>> populationNode = "26";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget27 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu-backend-riscv";
        attribute :>> role = "library";
        attribute :>> populationNode = "27";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget28 : GenerationTarget {
        attribute :>> moduleName = "_t-cpu";
        attribute :>> role = "library";
        attribute :>> populationNode = "28";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget29 : GenerationTarget {
        attribute :>> moduleName = "_t-c-1";
        attribute :>> role = "library";
        attribute :>> populationNode = "29";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget30 : GenerationTarget {
        attribute :>> moduleName = "_t-c-2";
        attribute :>> role = "library";
        attribute :>> populationNode = "30";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget31 : GenerationTarget {
        attribute :>> moduleName = "_t-c-3";
        attribute :>> role = "library";
        attribute :>> populationNode = "31";
        attribute :>> selectedNode = "0 / object 2";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget32 : GenerationTarget {
        attribute :>> moduleName = "_gsclib";
        attribute :>> role = "library";
        attribute :>> populationNode = "32";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "Ordered library metadata and object vector";
    }
    part generationTarget33 : GenerationTarget {
        attribute :>> moduleName = "_gsc";
        attribute :>> role = "executable";
        attribute :>> populationNode = "33";
        attribute :>> selectedNode = "external boundary only";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;289-346";
        attribute :>> inputCut = "Scheme source; shared declared prerequisites including fixnum.scm; observed include closure; boot/profile identity";
        attribute :>> projectionBoundary = "_gsc.c feeds executable linkfile 71 and object 67; never _gsc_.c";
    }
    part def BuildCorrectnessContract {
        attribute contractId : String;
        attribute dependsOn : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute mechanism : String;
        attribute quintSymbols : String;
        attribute leanSymbols : String;
        attribute obligationId : String;
        attribute openPremise : String;
        attribute counterexample : String;
        attribute retirement : String;
        attribute benefit : String;
        attribute addedCost : String;
        attribute paperURL : String;
        attribute status : String;
    }
    part buildCorrectness0 : BuildCorrectnessContract {
        attribute :>> contractId = "B-CLOSURE";
        attribute :>> dependsOn = "";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "419-466";
        attribute :>> mechanism = "A complete replayable read trace includes ordered selector reads, failed extension probes, resolved paths and compile-time effects; monotone discovery is local to one immutable attempt";
        attribute :>> quintSymbols = "dependency_cut.needed; observeInput; sealCut";
        attribute :>> leanSymbols = "agreementOnSmallerCut; completeCutCanGrow; affectedEdgeExtension";
        attribute :>> obligationId = "BF-BUILD-CUT";
        attribute :>> openPremise = "Prove read mediation and producer extensionality; finite trace completion is not semantic closure; dependency cycles require rejection or an independently proved evaluator";
        attribute :>> counterexample = "Record chosen .scm only; a previously absent higher-priority extension appears, changing top-level source resolution";
        attribute :>> retirement = "Broad dependencies retire only after complete managed read mediation; keep conservative invalidation for untracked effects";
        attribute :>> benefit = "Avoid generation only outside the actual semantic read closure; shared fixnum remains 34 candidates";
        attribute :>> addedCost = "Read/probe manifests, namespace identity, restart or suspend policy, retained failure traces";
        attribute :>> paperURL = "https://www.mathematik.uni-marburg.de/~seba/publications/pluto-incremental-build.pdf";
        attribute :>> status = "open-source-refinement; conditional-algebra";
    }
    part buildCorrectness1 : BuildCorrectnessContract {
        attribute :>> contractId = "B-SNAPSHOT";
        attribute :>> dependsOn = "B-CLOSURE";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "419-466";
        attribute :>> mechanism = "Bind read image, resolved namespace, tool/profile and dependency output groups to one cohort; epoch invalidation and publication use one linearization authority";
        attribute :>> quintSymbols = "dependency_cut.beginCut; worldWrite; restartCut; cutPublicationSafe";
        attribute :>> leanSymbols = "immutableReadExtendsTrace; receiptReuseMatchesClean";
        attribute :>> obligationId = "BF-BUILD-CUT";
        attribute :>> openPremise = "All relevant writes must revoke authority before visibility; same epoch number does not prove isolation; no unmanaged-live-path fallback";
        attribute :>> counterexample = "Read A before change and B after change; final A/B hashes restored by ABA; no coherent consumed input cohort";
        attribute :>> retirement = "Live-path rereads and duplicate currentness decisions retire only inside a qualified snapshot owner";
        attribute :>> benefit = "Prevent mixed-cohort publication; retain successful unchanged groups across unrelated attempt cancellation as historical only";
        attribute :>> addedCost = "Immutable input storage, attempt leases, revocation serialization, staged group retention";
        attribute :>> paperURL = "https://arxiv.org/abs/2007.12737";
        attribute :>> status = "open-issuer-and-filesystem-refinement; conditional-algebra";
    }
    part buildCorrectness2 : BuildCorrectnessContract {
        attribute :>> contractId = "B-CUTOFF";
        attribute :>> dependsOn = "B-CLOSURE;B-SNAPSHOT";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-925;1086-1110";
        attribute :>> mechanism = "Consumer-specific extensional projections; generated C bytes for C compiler; parsed ordered full linker record including validated producer/target for metadata consumer";
        attribute :>> quintSymbols = "incremental_build.signature; calculate";
        attribute :>> leanSymbols = "projectionCutoff; allConsumerCutoff";
        attribute :>> obligationId = "BF-BUILD-CUT";
        attribute :>> openPremise = "Prove each actual consumer factors through its projection; the integer meta field is not a proof of actual targ-link-info equivalence";
        attribute :>> counterexample = "Equal module names but changed supply/demand, flags or metadata; descriptor reused with changed initialization order";
        attribute :>> retirement = "Timestamp-only dirty propagation and repeated descriptor emission retire only when edge observations are qualified";
        attribute :>> benefit = "Stable linker observations can stop descriptor/linkfile propagation even if implementation bytes change";
        attribute :>> addedCost = "Explicit producer/schema identity; parser parity; all-consumer coverage; exact equality or collision policy";
        attribute :>> paperURL = "https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf";
        attribute :>> status = "open-consumer-factorization; conditional-algebra";
    }
    part buildCorrectness3 : BuildCorrectnessContract {
        attribute :>> contractId = "B-GROUP";
        attribute :>> dependsOn = "B-SNAPSHOT;B-CUTOFF";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "281-305";
        attribute :>> mechanism = "One successful manifest owns complete output group, names, mode, ordered side products and receipt; publish atomically through a manifest pointer, rather than claiming multi-file rename atomicity";
        attribute :>> quintSymbols = "dependency_cut.stageGroup; publishCut; incremental_build.publish";
        attribute :>> leanSymbols = "receiptReuseMatchesClean";
        attribute :>> obligationId = "BF-BUILD-CUT";
        attribute :>> openPremise = "Prove successful producer exit, expected-group completeness, unique writer, retained-reader lifetime and crash recovery; Lean does not prove filesystem commit";
        attribute :>> counterexample = "New metadata with old C after partial rename; output bytes unchanged but a required side product deleted";
        attribute :>> retirement = "Repeated existence-based acceptance and scattered publication owners retire only after complete-group replacement";
        attribute :>> benefit = "Reuse only required complete products; avoid rebuilding valid groups merely to repeat orchestration";
        attribute :>> addedCost = "Staging, side-product schema, leases, atomic manifest authority, old-group reclamation";
        attribute :>> paperURL = "https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf";
        attribute :>> status = "open-publication-refinement";
    }
    part buildCorrectness4 : BuildCorrectnessContract {
        attribute :>> contractId = "B-POPULATION";
        attribute :>> dependsOn = "B-CLOSURE;B-CUTOFF;B-GROUP";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215;268-346";
        attribute :>> mechanism = "Inject ten selected actions into a 74-action GSC slice; 31 omitted library modules and executable module remain explicit boundary vectors, never silently folded into one representative";
        attribute :>> quintSymbols = "gsc_population.PopulationNodes; populationDeps; selectedInjection; missingBoundaryEdges";
        attribute :>> leanSymbols = "projectedStepPreserves";
        attribute :>> obligationId = "BF-BUILD-CUT";
        attribute :>> openPremise = "Related initial cache origins; ordered boundary observations; omitted-step stutter; simulation of selected transitions; full budget includes omitted running jobs; shared macro invalidates boundary certification until omitted groups revalidate; output equality is not refuted by source change alone";
        attribute :>> counterexample = "fixnum changes omitted _gsc.c while selected two-module model reuses executable linkfile; invalid stutter";
        attribute :>> retirement = "Small-population acceptance cannot retire any whole-chain dependency; migrate all concrete targets and cross-directory callers";
        attribute :>> benefit = "Precise population prevents false 34-to-2 or 74-to-10 savings; permits scoped leaf reasoning";
        attribute :>> addedCost = "Per-target identity and ordered vectors; full parameterized scheduler/refinement still required";
        attribute :>> paperURL = "https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf";
        attribute :>> status = "open-forward-simulation; inventory-established";
    }
    part buildCorrectness5 : BuildCorrectnessContract {
        attribute :>> contractId = "B-PROGRESS";
        attribute :>> dependsOn = "B-CLOSURE;B-SNAPSHOT;B-GROUP;B-POPULATION";
        attribute :>> sourcePath = "vendor/gambit/makefile.in";
        attribute :>> sourceRanges = "105-149";
        attribute :>> mechanism = "Finite acyclic closed cohort, terminating producers, fair ready admission and shared weighted budget; retry work charged separately from validated nodes";
        attribute :>> quintSymbols = "incremental_build.start; finish; step; dependency_cut.restartCut";
        attribute :>> leanSymbols = "budgetStepPreserves; budgetTracePreserves";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
        attribute :>> openPremise = "Discovery may restart arbitrarily; separate finite safety from liveness and work minimality; preserve recursive jobserver ownership";
        attribute :>> counterexample = "Parent holds final token awaiting dynamically discovered child; or repeated invalidation prevents completion";
        attribute :>> retirement = "Phase envelopes retire only after complete cross-directory dependency and child-drain proof; current within-phase jobserver remains";
        attribute :>> benefit = "Cross-phase overlap reduces critical path only when independent jobs and credits actually exist";
        attribute :>> addedCost = "Ready queue, suspend/restart policy, weight accounting, fairness/drain; no assumed measured speedup";
        attribute :>> paperURL = "https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf";
        attribute :>> status = "open-progress-and-native-scheduler-refinement";
    }
    part chainFact9 : SourceChainFact {
        attribute :>> factId = "active-read-source";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "419-466";
        attribute :>> observation = "Active read-source uses the current readtable and optional extension search; active include passes false";
        attribute :>> limit = "Quoted tail at 1386-1642 is historical data, not this call path";
    }
    part chainFact10 : SourceChainFact {
        attribute :>> factId = "top-source-reader";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "200-223";
        attribute :>> observation = "compile-source input path calls read-source with true for extension search";
        attribute :>> limit = "Literal GSC suffix recipe passes explicit .scm; extension search applies only to extensionless path inputs, not ordinary include false or in-memory input";
    }
    part chainFact11 : SourceChainFact {
        attribute :>> factId = "quoted-reader-history";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "1384-1396;1553-1563";
        attribute :>> observation = "Quoted datum starts at 1386 and contains the later same-name include definition";
        attribute :>> limit = "Do not infer active probe/reopen behavior from this historical copy";
    }
    part chainFact12 : SourceChainFact {
        attribute :>> factId = "extension-order";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "10506-10513";
        attribute :>> observation = "Current runtime extension list orders .sld before .scm before .six and has a setter";
        attribute :>> limit = "The host fallback table differs; actual active producer context must be bound";
    }
    part chainFact13 : SourceChainFact {
        attribute :>> factId = "reader-path-primitive";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1145-1194";
        attribute :>> observation = "Current reader builds path settings with EOL encoding and invokes generic file open via psettings";
        attribute :>> limit = "Path/open error details and primitive read authority require their own mediation; no snapshot isolation proved";
    }

    /* Read/capability and refinement contracts; no runtime receipt issuer exists here. */
    part def GscReadBoundary {
        attribute readId : String;
        attribute calls : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute caller : String;
        attribute observation : String;
        attribute existingSupport : String;
        attribute missingClosure : String;
        attribute managedChange : String;
        attribute obligationId : String;
    }
    part gscRead0 : GscReadBoundary {
        attribute :>> readId = "R-RECIPE";
        attribute :>> calls = "R-WRAP;R-ROOT;R-LINK";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "255-257;289-308";
        attribute :>> caller = "gsc suffix and link recipes";
        attribute :>> observation = "Explicit .scm argument, prelude bytes, boot executable, dynamic-loader setup, alias roots, options and cwd";
        attribute :>> existingSupport = "Existing independent suffix recipe and phase jobserver";
        attribute :>> missingClosure = "Configured substitutions and actual boot producer closure are unbound in this template study";
        attribute :>> managedChange = "Bind one resolved native request and fixed compiler stage; source image must preserve logical alias/path observations";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead1 : GscReadBoundary {
        attribute :>> readId = "R-WRAP";
        attribute :>> calls = "R-HEADER;R-EXPAND";
        attribute :>> sourcePath = "vendor/gambit/gsi/main.scm";
        attribute :>> sourceRanges = "367-437";
        attribute :>> caller = "CLI installs c#wrap-program before compile-source";
        attribute :>> observation = "Prelude/postlude strings become source with derived .prelude/.postlude locations; include header before source body";
        attribute :>> existingSupport = "Existing option parsing and wrapper preserve program order";
        attribute :>> missingClosure = "Actual prelude expansion reads are not a closed trace; pooled compiler global-hook reset not proved";
        attribute :>> managedChange = "Keep Scheme wrapper semantics; bind options, logical locations and initial hook state, not just leaf bytes";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead2 : GscReadBoundary {
        attribute :>> readId = "R-ROOT";
        attribute :>> calls = "R-READER;R-WRAP";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "184-223;317-350";
        attribute :>> caller = "compile-frontend -> compile-frontend-aux";
        attribute :>> observation = "read-source path or already-materialized source; mutable wrap/expand hooks and compilation options/context";
        attribute :>> existingSupport = "Existing env/ptree/virtual/target setup and teardown";
        attribute :>> missingClosure = "These resets do not prove evaluator globals, hooks or effects are reset; exceptions need lifecycle custody";
        attribute :>> managedChange = "Use declared initial compiler state; fresh process alone does not mediate arbitrary host effects";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead3 : GscReadBoundary {
        attribute :>> readId = "R-INCLUDE";
        attribute :>> calls = "R-READER";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "419-466";
        attribute :>> caller = "Active include-expr->source and read-source";
        attribute :>> observation = "Source-relative path reference; ordinary include passes false; explicit GSC .scm root skips extension search";
        attribute :>> existingSupport = "Current Scheme read-source API is reusable";
        attribute :>> missingClosure = "A callback recording include names misses reader effects, resolved path and other evaluator I/O";
        attribute :>> managedChange = "Mediate logical/resolved read identities and outcomes while preserving source locations and reader settings";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead4 : GscReadBoundary {
        attribute :>> readId = "R-EXPAND";
        attribute :>> calls = "R-INCLUDE;R-MACRO";
        attribute :>> sourcePath = "vendor/gambit/gsc/_ptree1.scm";
        attribute :>> sourceRanges = "705-724;1502-1564";
        attribute :>> caller = "parse-exprs / extract-defs";
        attribute :>> observation = "Included expression is inserted into stream under current env; macro/declaration/namespace order affects later requests";
        attribute :>> existingSupport = "Scheme semantic environment and recursive expansion stay";
        attribute :>> missingClosure = "Literal include scanning does not account for expanded includes or macro context; recursive calls are not an acyclic action graph";
        attribute :>> managedChange = "Trace actual request order and closure; retain semantic sequencing in Scheme";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead5 : GscReadBoundary {
        attribute :>> readId = "R-MACRO";
        attribute :>> calls = "R-HOST";
        attribute :>> sourcePath = "vendor/gambit/gsc/_ptree1.scm";
        attribute :>> sourceRanges = "1004-1015;2931-2978";
        attribute :>> caller = "add-macro + macro-expand";
        attribute :>> observation = "Macro procedure creation through scheme-global-eval; expander is invoked with source/expression";
        attribute :>> existingSupport = "Existing evaluator and transformer application";
        attribute :>> missingClosure = "No local proof that macro procedures only use read-source; arbitrary host effect path remains open";
        attribute :>> managedChange = "Admit only declared/mediated evaluator capabilities; otherwise volatile or reject reusable receipt";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead6 : GscReadBoundary {
        attribute :>> readId = "R-HOST";
        attribute :>> calls = "";
        attribute :>> sourcePath = "vendor/gambit/gsc/_host.scm";
        attribute :>> sourceRanges = "842-853";
        attribute :>> caller = "Active Gambit evaluator adapter";
        attribute :>> observation = "scheme-global-eval invokes eval; quoted fallback near line 26 is not this active adapter";
        attribute :>> existingSupport = "C-facing host interface remains Scheme-owned";
        attribute :>> missingClosure = "Interpreted procedure may read env/files or invoke native code outside include adapter; no exhaustive effect census";
        attribute :>> managedChange = "A reusable managed profile needs evaluator/readtable/FFI mediation or enforced capability exclusion";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead7 : GscReadBoundary {
        attribute :>> readId = "R-READER";
        attribute :>> calls = "R-OPEN;R-READLOOP";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1145-1216";
        attribute :>> caller = "read-all from path and psettings";
        attribute :>> observation = "EOL encoding, current readtable, wrapper/unwrapper, path start syntax, errors and resolved-open continuation";
        attribute :>> existingSupport = "Existing path settings and reader code";
        attribute :>> missingClosure = "Final source container originates from logical path; content-only relocation may change observable locations";
        attribute :>> managedChange = "Separate immutable storage path from virtual logical path; bind reader options and all callbacks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead8 : GscReadBoundary {
        attribute :>> readId = "R-READLOOP";
        attribute :>> calls = "";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1216-1264";
        attribute :>> caller = "read-all-as-a-begin-expr-from-port";
        attribute :>> observation = "Readtable copy, read-datum, script marker, close on normal/error path, source/port names";
        attribute :>> existingSupport = "Existing exception catcher and port close";
        attribute :>> missingClosure = "Shallow readtable copy is not a proof of callback purity or global snapshot isolation";
        attribute :>> managedChange = "Pin reader capabilities and port lifetime; preserve original error and script behavior";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead9 : GscReadBoundary {
        attribute :>> readId = "R-OPEN";
        attribute :>> calls = "";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "9916-9942";
        attribute :>> caller = "open-file-generic-from-psettings";
        attribute :>> observation = "path-resolve, device flags/permissions, OS open result and port path-unresolve";
        attribute :>> existingSupport = "Existing C-backed file device and error continuation";
        attribute :>> missingClosure = "Live OS open does not issue a coherent image; symlink/name races and native bypass closure are unresolved";
        attribute :>> managedChange = "Route admitted opens through one immutable namespace owner; unknown outcome retains attempt custody";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead10 : GscReadBoundary {
        attribute :>> readId = "R-HEADER";
        attribute :>> calls = "R-HEADER-CLOSURE;R-INCLUDE";
        attribute :>> sourcePath = "vendor/gambit/lib/header.scm";
        attribute :>> sourceRanges = "7-10";
        attribute :>> caller = "Recipe prelude includes header.scm";
        attribute :>> observation = "Includes gambit#.scm and _gambit#.scm before module body";
        attribute :>> existingSupport = "Shared source prelude is already declared in Make";
        attribute :>> missingClosure = "Source includes are broader than a leaf ADT list; alias roots and transitive definitions must be covered";
        attribute :>> managedChange = "Reuse one cohort image while preserving per-compilation macro environments";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead11 : GscReadBoundary {
        attribute :>> readId = "R-HEADER-CLOSURE";
        attribute :>> calls = "R-INCLUDE;R-MACRO";
        attribute :>> sourcePath = "vendor/gambit/lib/_gambit#.scm";
        attribute :>> sourceRanges = "7-16;1485-1495";
        attribute :>> caller = "Header transitive Scheme definitions";
        attribute :>> observation = "Loads ~~lib/_define-syntax.scm and multiple subsystem # definitions including _fifo# and _module#";
        attribute :>> existingSupport = "Existing header organization; no replacement of semantic macro library";
        attribute :>> missingClosure = "An include-name excerpt is not an exhaustive producer trace or proof of current Make incompleteness";
        attribute :>> managedChange = "Include exact transitive answers in trace; missing literal Make entry alone does not establish a current bug";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscRead12 : GscReadBoundary {
        attribute :>> readId = "R-LINK";
        attribute :>> calls = "";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-925;1086-1110";
        attribute :>> caller = "targ-link-info / targ-link";
        attribute :>> observation = "Generated C metadata opened/read separately; compiler/target guard and ordered records/flags";
        attribute :>> existingSupport = "Existing validated Scheme metadata reader";
        attribute :>> missingClosure = "A read-source hook misses this path; integer meta oracle does not establish factorization";
        attribute :>> managedChange = "Bind generated group catalogue and qualified full metadata projection; retain other link inputs";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part def SnapshotIssueCondition {
        attribute conditionId : String;
        attribute dependsOn : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute credential : String;
        attribute issueGuard : String;
        attribute failureCustody : String;
        attribute proofTarget : String;
        attribute addedSupport : String;
        attribute retirement : String;
        attribute benefitBoundary : String;
        attribute obligationId : String;
    }
    part snapshotIssue0 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-IMAGE";
        attribute :>> dependsOn = "";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "9916-9942";
        attribute :>> credential = "CoherentSourceImageReceipt";
        attribute :>> issueGuard = "Coherent namespace/content acquisition; immutable answers and virtual logical path identity; all admitted external writers excluded or serialized";
        attribute :>> failureCustody = "Materializer retains storage/view lease on partial acquisition; no live fallback";
        attribute :>> proofTarget = "Prove acquisition yields one image, and read adapter preserves names/errors; source currently uses live OS open";
        attribute :>> addedSupport = "Source namespace manifest, immutable storage, leases and writer policy";
        attribute :>> retirement = "Retire duplicate copy/currentness owners only after all admitted paths route through this issuer";
        attribute :>> benefitBoundary = "One image may be shared by 34 generators; does not eliminate their separate semantic reads";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue1 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-PRODUCER";
        attribute :>> dependsOn = "I-IMAGE";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "317-350";
        attribute :>> credential = "ProducerContextReceipt";
        attribute :>> issueGuard = "Exact boot stage/tool closure, target/options/prelude/env/cwd; controlled initial evaluator/reader/hook state; successful or explicitly failed lifecycle";
        attribute :>> failureCustody = "Owner retains process and hook/reset responsibility until children, ports and callbacks settle";
        attribute :>> proofTarget = "Prove initialization and exceptional cleanup restore/terminate the admitted context; env.begin/end alone is insufficient";
        attribute :>> addedSupport = "Typed context fingerprint and fresh/pooled admission policy";
        attribute :>> retirement = "Replace repeated ad hoc effective-config interpretation only after parity";
        attribute :>> benefitBoundary = "Fresh producer isolates previous mutable state but neither proves deterministic macros nor blocks host effects";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue2 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-MEDIATION";
        attribute :>> dependsOn = "I-PRODUCER";
        attribute :>> sourcePath = "vendor/gambit/gsc/_ptree1.scm";
        attribute :>> sourceRanges = "1004-1015;2952-2969";
        attribute :>> credential = "ReadCapabilityReceipt";
        attribute :>> issueGuard = "Every effect influencing requests/output is mediated or explicitly fixed; untracked macro/readtable/native capabilities denied for reusable profile";
        attribute :>> failureCustody = "Unclassified effect revokes reusable attempt; retain original failure/result semantics without issuing success";
        attribute :>> proofTarget = "Translate admitted Scheme evaluator path to closed ReadProgram; prove all macro and reader callbacks obey capability policy";
        attribute :>> addedSupport = "Evaluator/readtable/native capability boundary plus audit trail";
        attribute :>> retirement = "An include-only recorder cannot retire conservative host-effect handling";
        attribute :>> benefitBoundary = "Can reduce false dependencies only when mediation is complete; tracing overhead remains";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue3 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-CATALOG";
        attribute :>> dependsOn = "I-IMAGE";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "281-305";
        attribute :>> credential = "DependencyGroupReceipt";
        attribute :>> issueGuard = "Required producer validated under same image and stage; complete immutable group; unique committed identity and leased lifetime before dependent read";
        attribute :>> failureCustody = "Uncommitted or unknown group remains producer-owned; consumer waits/restarts without consuming stale output";
        attribute :>> proofTarget = "Prove producer-before-file-read and append-only group catalogue with conflicting-commit invalidation";
        attribute :>> addedSupport = "Group manifests, pending dependency ownership, reader leases";
        attribute :>> retirement = "Replace scattered product-existence acceptance only when all concrete consumers migrate";
        attribute :>> benefitBoundary = "Metadata cutoff can reuse observations after revalidation; changed bytes still require native object work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue4 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-TRACE";
        attribute :>> dependsOn = "I-MEDIATION;I-CATALOG";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1216-1264";
        attribute :>> credential = "CompletedReadTraceReceipt";
        attribute :>> issueGuard = "Successful finite mediated run; ordered answer trace; no unresolved dependency reads/effects; same initial producer context; every consumed answer tied to image/group receipts";
        attribute :>> failureCustody = "Failed/unfinished trace is historical diagnostic evidence, not reusable success; leases stay with attempt until drain";
        attribute :>> proofTarget = "adaptiveTraceReplay and adaptiveOutputUnique are checked only for the abstract reader; actual translation is open";
        attribute :>> addedSupport = "Ordered trace plus dependency/effect completion and failure records";
        attribute :>> retirement = "Retire duplicate dynamic dependency recording only after one trace owner covers every path";
        attribute :>> benefitBoundary = "Old trace can validate an adaptive branch without rerunning a closed producer; cannot infer closure from no new edges";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue5 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-SEAL";
        attribute :>> dependsOn = "I-TRACE;I-PRODUCER";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "337-350";
        attribute :>> credential = "StagedAttemptReceipt";
        attribute :>> issueGuard = "Successful producer exit, complete output group/schema and settled I/O; receipts bind all source and catalogue observations; no outstanding authority borrowers";
        attribute :>> failureCustody = "Attempt owner retains staging and borrowed resources on partial failure; no synthetic success";
        attribute :>> proofTarget = "Prove source result lifecycle and complete-group custody; current frontend return is not a publication receipt";
        attribute :>> addedSupport = "Staging owner, output/schema inventory, process/IO drain";
        attribute :>> retirement = "Retire scattered success/exit translation only after complete caller replacement";
        attribute :>> benefitBoundary = "Avoid repeated wrapper decisions; no promise of zero validation work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue6 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-ADMIT";
        attribute :>> dependsOn = "I-SEAL";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "9916-9942";
        attribute :>> credential = "CurrentBuildManifestReceipt";
        attribute :>> issueGuard = "Under same issuer linearization authority: source cohort not revoked, dependency receipts current, group complete; publish one manifest pointer";
        attribute :>> failureCustody = "Writer first rejects admission; publisher first creates valid historical group later revocable; unknown commit retains single custody";
        attribute :>> proofTarget = "Prove writer-before-visibility and admission atomicity imply CutAgreement at commit; epochs/watches alone insufficient";
        attribute :>> addedSupport = "One revocation/commit owner, manifest CAS and reader lifetime policy";
        attribute :>> retirement = "Retire multiple currentness issuers only after no bypass remains";
        attribute :>> benefitBoundary = "Prevents stale publication; atomic manifest is a design, not an implemented Darwin guarantee";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part snapshotIssue7 : SnapshotIssueCondition {
        attribute :>> conditionId = "I-REPLAY";
        attribute :>> dependsOn = "I-TRACE;I-CATALOG;I-PRODUCER";
        attribute :>> sourcePath = "vendor/gambit/gsc/_source.scm";
        attribute :>> sourceRanges = "419-466";
        attribute :>> credential = "RevalidatedCacheReceipt";
        attribute :>> issueGuard = "Valid successful origin; same producer/context; old ordered requests receive equal answers from new coherent image/catalogue; new admission receipt required";
        attribute :>> failureCustody = "Any changed answer or missing group falls back to actual evaluation; no old generation credential reuse";
        attribute :>> proofTarget = "receiptBackedAdaptiveReuse is conditional; source mediation and group commit remain open";
        attribute :>> addedSupport = "Validated answer lookup and new receipt, even for equal output bytes";
        attribute :>> retirement = "Retire timestamp-only dirty propagation when semantic consumers and currentness ownership are qualified";
        attribute :>> benefitBoundary = "Input credential invalidation differs from observed output change; full revalidation work must be counted";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part def BuildRefinementStep {
        attribute stepId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute concreteEvent : String;
        attribute abstractEvent : String;
        attribute relationPremise : String;
        attribute leanSupport : String;
        attribute openProof : String;
        attribute costEffect : String;
        attribute obligationId : String;
    }
    part buildRefinement0 : BuildRefinementStep {
        attribute :>> stepId = "P-INITIAL";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;195-215";
        attribute :>> concreteEvent = "74-action cohort with real groups, provenance and native dependency order";
        attribute :>> abstractEvent = "Ten selected phases / selected indices 31,1,65,35,68,69,70,71,72,73";
        attribute :>> relationPremise = "Valid related cache origins, exact selected graph injection, ordered external observations, common source/producer cohort";
        attribute :>> leanSupport = "selectedIndexInjective; selectedEdgesExact";
        attribute :>> openProof = "Construct semantic output relation to integer calculate/signature and concrete safety reflection; zero initial integers are not real producer origins";
        attribute :>> costEffect = "Initial-state relation has no performance implication";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement1 : BuildRefinementStep {
        attribute :>> stepId = "P-READY";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "289-305";
        attribute :>> concreteEvent = "All selected and omitted predecessors validated before concrete start/reuse";
        attribute :>> abstractEvent = "ready(k) plus boundaryReady(k)";
        attribute :>> relationPremise = "PhaseRelated; BoundaryReady includes 31 generated records, 31 objects and the executable pair across selected consumers";
        attribute :>> leanSupport = "fullReadyProjects; selectedAndBoundaryReady";
        attribute :>> openProof = "Map real pending/generated dependencies to phases; list order and source/tool inputs remain separate obligations";
        attribute :>> costEffect = "64 boundary edges cannot disappear from actual validation accounting";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement2 : BuildRefinementStep {
        attribute :>> stepId = "P-START";
        attribute :>> sourcePath = "vendor/gambit/makefile.in";
        attribute :>> sourceRanges = "105-149";
        attribute :>> concreteEvent = "Ready admitted concrete job acquires actual weighted host credits";
        attribute :>> abstractEvent = "start(k), selected running count increases";
        attribute :>> relationPremise = "Full used = selected + omitted credits; weights and nested jobserver ownership mapped; input trace eligible";
        attribute :>> leanSupport = "fullBudgetBoundsSelected; budgetStepPreserves";
        attribute :>> openProof = "Current unit-weight ten-node model does not represent arbitrary weights, nested children or actual CPU/memory scheduling";
        attribute :>> costEffect = "Omitted jobs consume budget even if selected phase view stutters";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part buildRefinement3 : BuildRefinementStep {
        attribute :>> stepId = "P-FINISH";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "337-350";
        attribute :>> concreteEvent = "Producer exit/IO drain creates staged complete group, releases owned credit";
        attribute :>> abstractEvent = "finish(k), staged state before publish";
        attribute :>> relationPremise = "Phase and custody relation includes success/failure, staging completeness and all borrowed resources";
        attribute :>> leanSupport = "budgetStepPreserves; relationalTraceSafety";
        attribute :>> openProof = "Prove true process/reader/exception cleanup and group completeness; model finish is not process completion evidence";
        attribute :>> costEffect = "Failed attempts and retries remain charged work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement4 : BuildRefinementStep {
        attribute :>> stepId = "P-PUBLISH";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-925;1086-1110";
        attribute :>> concreteEvent = "New manifest/group and validated ordered observations become available";
        attribute :>> abstractEvent = "publish(k) with related output and saved signature";
        attribute :>> relationPremise = "I-ADMIT; per-consumer factorization; exact input receipt and metadata schema correspondence";
        attribute :>> leanSupport = "receiptBackedAdaptiveReuse; relationalTraceSafety; concreteSafetyFromRefinement";
        attribute :>> openProof = "Prove actual compiler/link producer quotient, concrete reuse/publication property reflection and atomic commit; matching graph labels cannot supply this";
        attribute :>> costEffect = "Unchanged metadata may cut descriptor work; changed objects still propagate";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement5 : BuildRefinementStep {
        attribute :>> stepId = "P-OMITTED";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "93-111;289-308";
        attribute :>> concreteEvent = "Omitted generation/object step and any external observation validation";
        attribute :>> abstractEvent = "Selected projection stutter only within a related state";
        attribute :>> relationPremise = "Related selected phases, bound pending groups, resource accounting and frozen external observations; safety relation may require boundary recertification";
        attribute :>> leanSupport = "relationalTraceSafety";
        attribute :>> openProof = "Construct step-or-stutter relation; equality of integer phases alone does not preserve output, freshness, resource or progress meaning";
        attribute :>> costEffect = "Safety stutter does not mean zero generation, time, bytes or retries";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement6 : BuildRefinementStep {
        attribute :>> stepId = "P-SHARED-MACRO";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "312-346";
        attribute :>> concreteEvent = "fixnum.scm changes; all 34 declared generation inputs become candidates";
        attribute :>> abstractEvent = "No unconditional ten-node whole-build transition";
        attribute :>> relationPremise = "Old input receipts invalid until all needed omitted groups revalidate; equal observations can recertify restricted safety, changed boundary observation rejects FrozenBoundary";
        attribute :>> leanSupport = "adaptiveTraceReplay; changedBoundaryRejectsFrozen";
        attribute :>> openProof = "Source change alone does not prove output difference; must validate full population; static 74 inventory is not its operational scheduler";
        attribute :>> costEffect = "Even if boundary equality is restored, omitted work prevents transfer of symbolic 0/4/10 total-work counts";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part buildRefinement7 : BuildRefinementStep {
        attribute :>> stepId = "P-REVOKE";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "9916-9942";
        attribute :>> concreteEvent = "Cohort invalidation/cancellation and admitted-versus-historical result custody";
        attribute :>> abstractEvent = "invalidate/cancel/discard with matching phase and receipt generation";
        attribute :>> relationPremise = "Common revoke/commit authority; old historical group remains retained for readers but cannot be CURRENT";
        attribute :>> leanSupport = "relationalTraceSafety";
        attribute :>> openProof = "Prove actual writer/revoke ordering and late child/unknown commit drain; no source primitive currently supplies the receipt";
        attribute :>> costEffect = "No liveness/work bound under infinite invalidation; never erase discarded work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }

    /* Capability gates and output observations: design contracts, no accepted issuer. */
    part def GscCapabilityGate {
        attribute capabilityId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute actualCaller : String;
        attribute capability : String;
        attribute admitCondition : String;
        attribute refuseCondition : String;
        attribute remainingClosure : String;
        attribute supportAndBenefit : String;
        attribute obligationId : String;
    }
    part gscCapability0 : GscCapabilityGate {
        attribute :>> capabilityId = "C-MACRO";
        attribute :>> sourcePath = "vendor/gambit/gsc/_ptree1.scm";
        attribute :>> sourceRanges = "1004-1015;2952-2978";
        attribute :>> actualCaller = "add-macro / macro-expand";
        attribute :>> capability = "Evaluate macro procedure and invoke closure";
        attribute :>> admitCondition = "Bind procedure code, evaluator globals and all called capabilities to same admitted context; include caller and callback trace";
        attribute :>> refuseCondition = "Unknown/replaced expander or effects outside controlled trace; an include-only trace cannot certify it";
        attribute :>> remainingClosure = "Arbitrary closure bodies cannot be enumerated from these callsites; actual boot definitions must match";
        attribute :>> supportAndBenefit = "Reuse Scheme macro semantics; add capability/context ownership rather than rewrite expander semantics";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability1 : GscCapabilityGate {
        attribute :>> capabilityId = "C-EVAL";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "5097-5107;5342-5379";
        attribute :>> actualCaller = "eval-global -> ##eval -> ##eval-top";
        attribute :>> capability = "Global or namespace-qualified evaluation";
        attribute :>> admitCondition = "Bind actual eval hooks/environment and all module/effect dependencies before reusable success";
        attribute :>> refuseCondition = "Unmanaged evaluator replacement, namespace state or native capability; symbol allowlist alone is insufficient";
        attribute :>> remainingClosure = "Public env choices do not enforce host capability confinement";
        attribute :>> supportAndBenefit = "Existing evaluator stays; no full purity claim from fresh process or namespace separation";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability2 : GscCapabilityGate {
        attribute :>> capabilityId = "C-REQUIRE";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1334-1336;5097-5100";
        attribute :>> actualCaller = "setup-requirements-and-run";
        attribute :>> capability = "Load demanded modules, then run code";
        attribute :>> admitCondition = "Module demand resolver, loaded code and initialization effects belong to same producer/capability closure";
        attribute :>> refuseCondition = "Unregistered module resolution, initialization, dynamic library closure or unknown load outcome";
        attribute :>> remainingClosure = "Selected load-modules call is established; complete dynamic resolution caller chain remains open";
        attribute :>> supportAndBenefit = "Represent required code/groups as managed dependencies; do not omit them from successful trace";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability3 : GscCapabilityGate {
        attribute :>> capabilityId = "C-LOAD";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "5448-5467;5569-5603";
        attribute :>> actualCaller = "load-binary -> load-object-file -> os-load-object-file";
        attribute :>> capability = "Load native object and register module descriptors";
        attribute :>> admitCondition = "Only qualified loaded closure with audited initialization and mediated transitive effects";
        attribute :>> refuseCondition = "Unknown native object, constructor/initialization effects, unresolved dependent library or callback ownership";
        attribute :>> remainingClosure = "This callable load path is real; its execution by the selected GSC inputs is not established";
        attribute :>> supportAndBenefit = "Retain loader semantics; qualification requires more than hashing requested object bytes";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability4 : GscCapabilityGate {
        attribute :>> capabilityId = "C-CHAR";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "12533-12547;12694-12699";
        attribute :>> actualCaller = "read-datum-or-label-or-none-or-dot";
        attribute :>> capability = "Indirect character handler procedure call";
        attribute :>> admitCondition = "Freeze handler table identity and govern handler closure, state and nested capabilities";
        attribute :>> refuseCondition = "Unknown handler or mutable state not included in producer context; missing callback trace";
        attribute :>> remainingClosure = "Standard handler installation is reusable support, not a proof about every procedure value";
        attribute :>> supportAndBenefit = "Use existing reader; shallow table copies do not isolate closure state";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability5 : GscCapabilityGate {
        attribute :>> capabilityId = "C-SHARP";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "13310-13328";
        attribute :>> actualCaller = "read-sharp -> read-sharp-aux";
        attribute :>> capability = "Indirect sharp-character handler call";
        attribute :>> admitCondition = "Bind sharp handler, reader parameters and all nested effect answers";
        attribute :>> refuseCondition = "Unknown sharp procedure or effect bypass, even if source file bytes match";
        attribute :>> remainingClosure = "All configured reader syntax and callbacks still require coverage";
        attribute :>> supportAndBenefit = "Standard parser dispatch remains; govern callback entries rather than replacing parsing";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability6 : GscCapabilityGate {
        attribute :>> capabilityId = "C-COMMENT";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "13286-13307";
        attribute :>> actualCaller = "skip-comment-done";
        attribute :>> capability = "Invoke procedure-valued comment handler";
        attribute :>> admitCondition = "Record exact handler/context and governed callback trace when procedure-valued";
        attribute :>> refuseCondition = "Dropping comments as semantically irrelevant while comment callback effects are untracked";
        attribute :>> remainingClosure = "A non-procedure comment setting does not imply arbitrary reader callbacks absent";
        attribute :>> supportAndBenefit = "Preserve callback behavior; comment-only edits are not universally output-irrelevant";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability7 : GscCapabilityGate {
        attribute :>> capabilityId = "C-SHARP-DOT";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "13560-13580;15888-15895";
        attribute :>> actualCaller = "Conditional read-sharp-dot";
        attribute :>> capability = "Read-time ##eval";
        attribute :>> admitCondition = "Admit only when compile feature and actual readtable flag are bound and eval closure is qualified";
        attribute :>> refuseCondition = "Enabled read-time eval with unmanaged effects; do not assume selected profile enables the branch";
        attribute :>> remainingClosure = "Both enable-sharp-dot and eval-allowed guard matter; native configured occurrence remains unresolved";
        attribute :>> supportAndBenefit = "Disabled branch is excluded only with profile evidence; no blanket reader-eval claim";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability8 : GscCapabilityGate {
        attribute :>> capabilityId = "C-BUFFER";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "2054-2102;2205-2238";
        attribute :>> actualCaller = "Byte-port buffer refill and drain";
        attribute :>> capability = "Call device read/write; retry or wait on errors";
        attribute :>> admitCondition = "View-bound device/offset/decoder ownership, preserved EOF/error behavior and governed wait/timeout callbacks";
        attribute :>> refuseCondition = "Live/inherited mutable device, shared offset race, untracked wait callback or unsettled buffered output";
        attribute :>> remainingClosure = "Port buffering and normal retry logic are visible; full callback/borrow census remains open";
        attribute :>> supportAndBenefit = "Reuse buffered IO and close paths; add handle/view and completion evidence";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability9 : GscCapabilityGate {
        attribute :>> capabilityId = "C-FFI";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceRanges = "4264-4280;4302-4335;4681-4685";
        attribute :>> actualCaller = "Primitive c-lambda bindings";
        attribute :>> capability = "Native read/write/open, raw FD/process and loader entries";
        attribute :>> admitCondition = "Qualified C ABI/provider and approved transitive capability behavior; use runtime root/VM contracts";
        attribute :>> refuseCondition = "Unknown native symbol/provider or transitive syscall, inherited capability or unsupervised callback";
        attribute :>> remainingClosure = "Scheme-level hook coverage is not native FFI closure";
        attribute :>> supportAndBenefit = "Modern C is core; audited C adapters are required, not forbidden merely for being native";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability10 : GscCapabilityGate {
        attribute :>> capabilityId = "C-C-READ";
        attribute :>> sourcePath = "vendor/gambit/lib/os_io.c";
        attribute :>> sourceRanges = "2138-2173;7494-7560;7720-7742;9784-9813";
        attribute :>> actualCaller = "os_device_stream_read -> device stream virtual dispatch -> file implementation";
        attribute :>> capability = "Read actual device bytes and errors; POSIX branch calls read";
        attribute :>> admitCondition = "Bound backend flags, immutable-view handle identity, file position and raw result conversion";
        attribute :>> refuseCondition = "Unbound backend/foreign device or active unqualified read pump, live fd reuse/alias, missing source/image lifetime or unknown result";
        attribute :>> remainingClosure = "Read wrapper may take USE_PUMPS non-null read_pump into nonblocking pipe before virtual dispatch; file path requires that branch excluded or governed; device universe remains open";
        attribute :>> supportAndBenefit = "Retain existing C device architecture; profile-specific virtual dispatch must be qualified";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability11 : GscCapabilityGate {
        attribute :>> capabilityId = "C-C-OPEN";
        attribute :>> sourcePath = "vendor/gambit/lib/os_io.c";
        attribute :>> sourceRanges = "10480-10546";
        attribute :>> actualCaller = "os_device_stream_open_path";
        attribute :>> capability = "Native path conversion, device setup, foreign wrapper and cleanup";
        attribute :>> admitCondition = "Resolved logical namespace maps to image; device and GC/VM lifetime tied to same attempt";
        attribute :>> refuseCondition = "Live namespace bypass, native pointer escape, failed wrapper ownership not settled";
        attribute :>> remainingClosure = "C setup/cleanup path is visible; no coherent snapshot issuer implemented here";
        attribute :>> supportAndBenefit = "Reuse conversion and failure cleanup; snapshot-backed provider is additional support";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability12 : GscCapabilityGate {
        attribute :>> capabilityId = "C-NATIVE-TEXT";
        attribute :>> sourcePath = "vendor/gambit/gsc/_ptree1.scm";
        attribute :>> sourceRanges = "1593-1611";
        attribute :>> actualCaller = "extract-defs add-c-decl / add-c-init";
        attribute :>> capability = "Collect C declaration/initialization text for generated artifact";
        attribute :>> admitCondition = "Include exact text, phase role and ABI/profile in output observation; separately qualify native compile/load phases";
        attribute :>> refuseCondition = "Do not reject just for C text; reject reusable execution only when an actual unmanaged build-time effect occurs";
        attribute :>> remainingClosure = "Text collection does not prove any later native initialization effects safe";
        attribute :>> supportAndBenefit = "Keep C friendliness and existing emitter; distinguish artifact data from executed effects";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscCapability13 : GscCapabilityGate {
        attribute :>> capabilityId = "C-EMIT";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "337-389;1170-1206;1297-1307;1393-1397";
        attribute :>> actualCaller = "targ-dump / targ-start-dump / targ-end-dump";
        attribute :>> capability = "Write metadata and C body to same output stream and close";
        attribute :>> admitCondition = "Attempt-owned staged group, successful close/exit, complete manifest and linearized admission";
        attribute :>> refuseCondition = "Partial/truncated output, unknown write/close result or publication without success/group custody";
        attribute :>> remainingClosure = "Normal file close is not transactional group publication; exceptional completion is still open";
        attribute :>> supportAndBenefit = "Reuse C emitter and syntax; replace scattered success/currentness decisions only after complete caller migration";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part def GscOutputObservation {
        attribute observationId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute consumer : String;
        attribute requiredValue : String;
        attribute modelCorrespondence : String;
        attribute fidelityObligation : String;
        attribute refuseEquality : String;
        attribute benefitBoundary : String;
        attribute obligationId : String;
    }
    part gscObservation0 : GscOutputObservation {
        attribute :>> observationId = "O-C-BYTES";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "1170-1206;1297-1317;1393-1397";
        attribute :>> consumer = "C compiler / native producer";
        attribute :>> requiredValue = "Exact complete generated C bytes plus logical filename, target/compiler/configured headers/options and group identity";
        attribute :>> modelCorrespondence = "New QNT rawC List[int] is a byte-sequence token under a proved encoding; old bytes:int is only scenario data";
        attribute :>> fidelityObligation = "Prove byte encoding equality and complete consumer context; c-declare/c-initialize are included as bytes";
        attribute :>> refuseEquality = "Same length/sum/hash without collision policy, or equal metadata with changed body";
        attribute :>> benefitBoundary = "Can stop C compilation only when actual bytes and all other compile inputs agree";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscObservation1 : GscOutputObservation {
        attribute :>> observationId = "O-LINK-DATUM";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-925;1086-1110;1317-1388";
        attribute :>> consumer = "targ-link-info / targ-get-mod / targ-link";
        attribute :>> requiredValue = "Accepted first-line marker, full typed Scheme record, compiler/target checks, logical file/flags and ordered input composition";
        attribute :>> modelCorrespondence = "New linkDatum List[int] denotes faithful typed datum encoding plus consumer context; not a field count";
        attribute :>> fidelityObligation = "Prove parser/serializer acceptance and all consumed fields/order; no JSON normalization or symbol/string conflation";
        attribute :>> refuseEquality = "Equal module name or partial metadata while supply/demand, flags, resources or meta-info differ";
        attribute :>> benefitBoundary = "Qualified unchanged link view may stop descriptor/linkfile work despite changed C body";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscObservation2 : GscOutputObservation {
        attribute :>> observationId = "O-ROLE-GROUP";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "337-389;1201-1206;1253-1269";
        attribute :>> consumer = "All artifact consumers";
        attribute :>> requiredValue = "Successful complete group with product role, schema/context, aliases/mode and leased provenance when observable";
        attribute :>> modelCorrespondence = "Artifact role/schema and Receipt success/complete/current are necessary QNT predicates; issuer proof remains external";
        attribute :>> fidelityObligation = "Prove role-specific group completeness and currentness; native module/descriptor/executable products cannot be interchanged";
        attribute :>> refuseEquality = "Existing primary file only, missing side product, mismatched role/context or caller-set true flags";
        attribute :>> benefitBoundary = "Avoid repeat wrappers/existence checks only after one trusted group owner replaces all acceptance paths";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscObservation3 : GscOutputObservation {
        attribute :>> observationId = "O-INTEGER-SCENARIO";
        attribute :>> sourcePath = "models/build/incremental_build.qnt";
        attribute :>> sourceRanges = "1-47";
        attribute :>> consumer = "Original ten-node calculate/signature scenario";
        attribute :>> requiredValue = "Integers and additive oracle intentionally define bounded synthetic behavior";
        attribute :>> modelCorrespondence = "Keep original scenario unchanged; do not force real artifacts into bytes/meta integers or addition";
        attribute :>> fidelityObligation = "Construct a commuting producer relation if transferring that scenario; otherwise use structured observation protocol and an independent oracle";
        attribute :>> refuseEquality = "Length/sum encoding loses ordering; even injective exact integer coding does not prove calculate commutes with GSC";
        attribute :>> benefitBoundary = "Symbolic 0/4/10 counts remain scenario-only, including after exact selected-graph facts";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscObservation4 : GscOutputObservation {
        attribute :>> observationId = "O-REFLECTION";
        attribute :>> sourcePath = "models/build/IncrementalBuild.lean";
        attribute :>> sourceRanges = "293-373";
        attribute :>> consumer = "Concrete reuse/publication/resource safety";
        attribute :>> requiredValue = "Related actual and clean groups must have equal complete observations; source closures and admission authority separately proven";
        attribute :>> modelCorrespondence = "observationEqualityReflection plus concreteSafetyFromRefinement give only conditional transfer";
        attribute :>> fidelityObligation = "Prove actual clean origin, output fidelity, error/epoch/group reflection, full-budget and capability mapping";
        attribute :>> refuseEquality = "Abstract badReuse=false or current=true without a concrete failure-to-flag/receipt relation";
        attribute :>> benefitBoundary = "Safety, work savings and progress require distinct reflection; no benefit from hiding omitted work";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }

    part def GscFidelityObligation {
        attribute diagramLabel : String;
        attribute dependsOn : String;
        attribute fidelityId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute concreteBoundary : String;
        attribute encodingRule : String;
        attribute cleanControl : String;
        attribute failureMapping : String;
        attribute reflectionDuty : String;
        attribute benefitBoundary : String;
        attribute leanSupport : String;
        attribute quintSupport : String;
        attribute obligationId : String;
    }
    part gscFidelity0 : GscFidelityObligation {
        attribute :>> fidelityId = "L-CHAIN";
        attribute :>> diagramLabel = "Real _host generation / library composition";
        attribute :>> dependsOn = "";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "77-78;289-308";
        attribute :>> concreteBoundary = "_host.scm -> _host.c -> configured GAMBIT_GSC_LIB_C via incremental -link -preload; _gsc_.c is a subsequent distinct composition";
        attribute :>> encodingRule = "Bind ordered library inputs plus base library, expansion roots, compilation/prelude options and resolved configured tool; make template is not an executed invocation";
        attribute :>> cleanControl = "Fresh logical output namespace and fresh semantic context under same sealed input/provider closure; preserve logical output filename";
        attribute :>> failureMapping = "No successful group from a file left by failed recipe; make prerequisites alone cannot issue provenance";
        attribute :>> reflectionDuty = "Actual command selection, CLI-to-linker correspondence, omitted base/library group closure and full caller completion remain open";
        attribute :>> benefitBoundary = "One selected library composition may be avoided only after the entire ordered input context and consumer observations revalidate";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "linkCutoff";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity1 : GscFidelityObligation {
        attribute :>> fidelityId = "L-READ";
        attribute :>> diagramLabel = "Target / extension resolution and parser";
        attribute :>> dependsOn = "L-WRITE";
        attribute :>> sourcePath = "vendor/gambit/gsc/_back.scm";
        attribute :>> sourceRanges = "604-715";
        attribute :>> concreteBoundary = "link-modules -> get-link-info -> target-link-info; target begin/end and extension search";
        attribute :>> encodingRule = "Bind extension resolution, target identity, logical filename, flags, port decoder/readtable and provider; absent-path answers are dependencies";
        attribute :>> cleanControl = "Same immutable namespace must reproduce both successful and negative resolver answers";
        attribute :>> failureMapping = "Missing/invalid info calls compiler-error; reader or vector exceptions remain distinct from false; cleanup is not guaranteed by these normal-return paths";
        attribute :>> reflectionDuty = "Prove ordered input triples preserve callsite/context and actual failures map to non-success rather than empty success";
        attribute :>> benefitBoundary = "Reuse existing target dispatch; replace duplicate acceptance only when one group owner covers resolver and failure edges";
        attribute :>> leanSupport = "reflectedFailureExcluded";
        attribute :>> quintSupport = "failureBlocks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity2 : GscFidelityObligation {
        attribute :>> fidelityId = "L-WRITE";
        attribute :>> diagramLabel = "Gambit datum writer and port codec";
        attribute :>> dependsOn = "L-CHAIN";
        attribute :>> sourcePath = "vendor/gambit/gsc/_host.scm";
        attribute :>> sourceRanges = "760-812";
        attribute :>> concreteBoundary = "Preserving-case port setup and write-returning-len-without-read-macros";
        attribute :>> encodingRule = "Specify lexical datum codec separately from port text-to-byte codec; standard readtable creation and quote controls are source-backed, decoder settings still bind context";
        attribute :>> cleanControl = "Do not assume host locale/encoding or shared readtable state equals a clean context; canonical port profile requires qualification";
        attribute :>> failureMapping = "Unrepresentable/unreadable datum, unknown charset or conversion error refuses typed credential; raw-byte comparison has a separate scope";
        attribute :>> reflectionDuty = "Prove parser(writer(d)) consumer-equivalent on admitted finite domain, then typed codec left inverse; not every Scheme object has the required round trip";
        attribute :>> benefitBoundary = "Reuse Gambit writer/reader; a new parser adds proof and maintenance until genuine owner replacement";
        attribute :>> leanSupport = "admittedCodecInjective; atomTagsSeparate";
        attribute :>> quintSupport = "linkEligible";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity3 : GscFidelityObligation {
        attribute :>> fidelityId = "L-HEADER";
        attribute :>> diagramLabel = "Shallow acceptance is insufficient";
        attribute :>> dependsOn = "L-READ";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-894";
        attribute :>> concreteBoundary = "targ-link-info opens, reads marker, reads one datum, closes, checks limited shape/version/target";
        attribute :>> encodingRule = "Shallow header acceptance is a separate predicate from fullRecord; do not confuse skipped escaped comments with datum fields";
        attribute :>> cleanControl = "Clean parser must run the same acceptance/error rules and target/compiler identities";
        attribute :>> failureMapping = "A two-element list with matching version and target-list passes shown checks yet lacks fields 2-11; malformed read may raise; accepted metadata may precede incomplete C body";
        attribute :>> reflectionDuty = "Prove actual shallow acceptance and deeper validator correspondence; no implied record length/body completeness";
        attribute :>> benefitBoundary = "Prevents invalid cache hits; does not itself avoid any producer execution";
        attribute :>> leanSupport = "reflectedFailureExcluded";
        attribute :>> quintSupport = "malformedBlocks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity4 : GscFidelityObligation {
        attribute :>> fidelityId = "L-FIELDS";
        attribute :>> diagramLabel = "Full typed record / framed domain codec";
        attribute :>> dependsOn = "L-HEADER; D-PRODUCER; D-CODEC; D-SCALAR";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "1086-1136;1317-1388";
        attribute :>> concreteBoundary = "targ-get-mod indexes positions 2-11; targ-start-dump writes twelve top-level fields";
        attribute :>> encodingRule = "Tagged finite datum grammar preserves nil, boolean, signed integer, character, string, interned symbol, keyword, pair and vector; payload lengths and boundaries are explicit; unsupported graph/opaque/float forms refuse until specified";
        attribute :>> cleanControl = "Observe the actual parsed output datum; do not assume original in-memory meta-info equals its serialized/read value";
        attribute :>> failureMapping = "A managed twelve-field schema may reject legacy-accepted extension records; this is reuse qualification, not a change to legacy language acceptance";
        attribute :>> reflectionDuty = "Complete recursive codec/decoder, scalar unit fidelity, malformed-token rejection and admitted domain closure remain open; framed atom facts cover only a small layer";
        attribute :>> benefitBoundary = "Typed equality can refine raw comparison only for a proven consumer; no JSON, hash-only or sorted-set shortcut";
        attribute :>> leanSupport = "framedAtomInjective; atomTagsSeparate; admittedCodecInjective";
        attribute :>> quintSupport = "linkCutoff";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity5 : GscFidelityObligation {
        attribute :>> fidelityId = "L-ORDER";
        attribute :>> diagramLabel = "Ordered siblings / base / flags / metadata";
        attribute :>> dependsOn = "L-FIELDS";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "906-1039;1086-1110";
        attribute :>> concreteBoundary = "Ordered map of modules; append flags; assq-first meta attributes and last effective script-line";
        attribute :>> encodingRule = "Preserve input order, duplicate entries, dotted preload pairs, field types and flags-before-module-flags; warnings and extension mode are context";
        attribute :>> cleanControl = "Use all ordered siblings and base plus same root/linker name/options; isolated _host record is insufficient";
        attribute :>> failureMapping = "Unknown duplicate/identity semantics or reordered flags/resources refuses coarse equality";
        attribute :>> reflectionDuty = "Prove consumer factors through complete observation including diagnostic/effect policy; pure return-value equality alone does not cover observable warnings";
        attribute :>> benefitBoundary = "Body-only changes may spare this one metadata-driven composition; native object work still propagates";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "linkCutoff";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity6 : GscFidelityObligation {
        attribute :>> fidelityId = "L-ARTIFACT";
        attribute :>> diagramLabel = "Stored bytes: layout only; origin unknown";
        attribute :>> dependsOn = "L-CHAIN";
        attribute :>> sourcePath = "vendor/gambit/gsc/_host.c";
        attribute :>> sourceRanges = "1-9;410-422;6103-6107";
        attribute :>> concreteBoundary = "Existing distribution _host.c has marker, 409008, (C), _host and empty meta-info; #else at line 418";
        attribute :>> encodingRule = "Bind whole file digest and exact byte length; lexical inspection is evidence of layout, not an independent Scheme parse or boot receipt";
        attribute :>> cleanControl = "No retained clean counterpart or producing command is established for this artifact; do not label it current or freshly generated";
        attribute :>> failureMapping = "Header-only truncation is source-reachable as an acceptance gap; no native truncation experiment is claimed";
        attribute :>> reflectionDuty = "Actual file-to-byte acquisition and parser/codec mapping remain unqualified despite concrete stored bytes";
        attribute :>> benefitBoundary = "Existing artifacts ground examples and identity; they yield zero demonstrated reuse savings";
        attribute :>> leanSupport = "byteEncodingInjective";
        attribute :>> quintSupport = "bytesWellFormed";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity7 : GscFidelityObligation {
        attribute :>> fidelityId = "L-CLEAN";
        attribute :>> diagramLabel = "Independent qualified clean-origin relation";
        attribute :>> dependsOn = "L-CHAIN";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "354-456";
        attribute :>> concreteBoundary = "compile-program obtains metadata, compiles, invokes target.dump then optional dump-c-intf";
        attribute :>> encodingRule = "Clean reference is same logical request/input/provider closure, isolated mutable compiler state, no inherited cache artifacts, complete successful manifest and mapped outcome";
        attribute :>> cleanControl = "Require qualified old origin and a clean-producer relation or independent clean run; equal old/new cache tokens alone are circular; no clean run here";
        attribute :>> failureMapping = "Unknown clean result, optional side-output failure, cancelled attempt or mutable provider yields no reference success";
        attribute :>> reflectionDuty = "Prove deterministic or explicitly chosen outcome relation, initial state equivalence, adaptive read closure and both observation witnesses";
        attribute :>> benefitBoundary = "A qualified recipe hit avoids one generation; validation and the clean-oracle construction cost stay explicit";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "linkEligible";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity8 : GscFidelityObligation {
        attribute :>> fidelityId = "L-FAIL";
        attribute :>> diagramLabel = "Eight outcomes; failure custody retained";
        attribute :>> dependsOn = "L-READ";
        attribute :>> sourcePath = "vendor/gambit/gsc/_utils.scm";
        attribute :>> sourceRanges = "426-437;442-454;506-507";
        attribute :>> concreteBoundary = "with-exception-handling continuation and compiler-abort #f";
        attribute :>> encodingRule = "Model Success, Missing, Rejected, Malformed, IoFailure, ProducerFailure, Cancelled and Unknown separately; error stage and custody retained in evidence";
        attribute :>> cleanControl = "Clean failure cannot certify success; preserving exact legacy messages/handlers requires additional observable-result mapping";
        attribute :>> failureMapping = "No exception/#f/nonzero/signal/unknown outcome becomes successful empty bytes; external process exit mapping remains open";
        attribute :>> reflectionDuty = "Each actual failing edge must imply a non-success/bad model state; normal-return closure does not prove exception cleanup";
        attribute :>> benefitBoundary = "Failure evidence prevents stale-file reuse; failure caching/replay is outside this success-only profile";
        attribute :>> leanSupport = "nonSuccessCannotIssue; reflectedFailureExcluded";
        attribute :>> quintSupport = "failureBlocks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity9 : GscFidelityObligation {
        attribute :>> fidelityId = "L-ISSUE";
        attribute :>> diagramLabel = "Success / complete / current / settled issuer";
        attribute :>> dependsOn = "L-ORDER; L-CLEAN; L-FAIL; L-REFLECT";
        attribute :>> sourcePath = "models/build/incremental_build.qnt";
        attribute :>> sourceRanges = "231-260";
        attribute :>> concreteBoundary = "gsc_link_fidelity explicit admission and cutoff predicates";
        attribute :>> encodingRule = "Success plus shallow/full/codec/group/settlement/current/effect/origin conditions; exact ordered context and datum equality; raw bytes additionally range-checked";
        attribute :>> cleanControl = "Both observations must be backed by qualified actual origins and current context; caller-set booleans are not witnesses";
        attribute :>> failureMapping = "All seven non-success outcomes and incomplete record block admission by definition; no executed state explorer proof claimed";
        attribute :>> reflectionDuty = "Provide concrete issuers and source failure-to-predicate reflection; these definitions do not enforce a native adapter";
        attribute :>> benefitBoundary = "One shared issuer can retire scattered existence checks only after complete caller migration; currently none retire";
        attribute :>> leanSupport = "nonSuccessCannotIssue";
        attribute :>> quintSupport = "linkEligible; linkCutoff; cCutoff; failureBlocks; malformedBlocks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity10 : GscFidelityObligation {
        attribute :>> fidelityId = "L-REFLECT";
        attribute :>> diagramLabel = "Encoding facts + conditional safety reflection";
        attribute :>> dependsOn = "L-ARTIFACT; D-BRIDGE";
        attribute :>> sourcePath = "models/build/IncrementalBuild.lean";
        attribute :>> sourceRanges = "373-437";
        attribute :>> concreteBoundary = "Exact byte widening and atom framing facts plus conditional domain codec, clean cutoff and failure reflection";
        attribute :>> encodingRule = "Injective encoding preserves observed datum distinctions; consumer factorization and failure reflection are independent obligations";
        attribute :>> cleanControl = "Supply actual read results, admitted-domain witnesses, clean provenance and same governed effect context";
        attribute :>> failureMapping = "Abstract safe flag with no actual failure reflection cannot prove concrete success/currentness; safety stutter does not prove termination";
        attribute :>> reflectionDuty = "Seven new theorems do not implement/verify Scheme reader, recursive wire codec, producer simulation, diagnostics or native process delivery";
        attribute :>> benefitBoundary = "Real compiler/parser and publication bridge proof remains necessary in modern C and optional Zig";
        attribute :>> leanSupport = "byteEncodingInjective; framedAtomInjective; atomTagsSeparate; admittedCodecInjective; cleanConsumerCutoff; nonSuccessCannotIssue; reflectedFailureExcluded";
        attribute :>> quintSupport = "linkCutoff; failureBlocks";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity11 : GscFidelityObligation {
        attribute :>> fidelityId = "L-WORK";
        attribute :>> diagramLabel = "Cut only proven consumer; charge other work";
        attribute :>> dependsOn = "L-ISSUE";
        attribute :>> sourcePath = "vendor/gambit/gsc/makefile.in";
        attribute :>> sourceRanges = "289-308";
        attribute :>> concreteBoundary = "One library composition and separate object/native link consumers";
        attribute :>> encodingRule = "Charge all 34 generation candidates, 34 native compilations and six composition actions from the established source slice; selected ten-node projection cannot hide omitted work";
        attribute :>> cleanControl = "Same comparison cohort and complete actual execution/accounting would be needed for speedup; not run here";
        attribute :>> failureMapping = "A refusal or changed body can increase necessary work even when metadata is stable";
        attribute :>> reflectionDuty = "Prove cost/progress reflection separately; per-consumer observation equality is not whole-build equality or performance";
        attribute :>> benefitBoundary = "At most the selected one composition is cut by its own equality credential; additional savings require each downstream consumer proof, not a global multiplier";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "linkCutoff; cCutoff";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }

    part gscFidelity12 : GscFidelityObligation {
        attribute :>> fidelityId = "D-PRODUCER";
        attribute :>> diagramLabel = "Actual metadata macro: key checked, values unrestricted";
        attribute :>> dependsOn = "";
        attribute :>> sourcePath = "vendor/gambit/lib/_nonstd.scm";
        attribute :>> sourceRanges = "166-184";
        attribute :>> concreteBoundary = "##expand-meta-info strips symbolic key, desourcifies values and calls compilation-meta-info-add!";
        attribute :>> encodingRule = "Do not assume string-only values; actual literal/expander/provider universe and object identity require admission";
        attribute :>> cleanControl = "Same syntax/expander and complete actual value construction under isolated compilation context";
        attribute :>> failureMapping = "Unsupported opaque/cyclic/uninterned or unreadable value denies typed reuse; legacy evaluation remains available";
        attribute :>> reflectionDuty = "Actual Scheme value to finite wire tree mapping is not proved; key symbol check does not imply a closed scalar domain";
        attribute :>> benefitBoundary = "Retain Scheme expansion; avoid a second string-dictionary protocol that loses legal values";
        attribute :>> leanSupport = "admittedCodecInjective";
        attribute :>> quintSupport = "scalarPayloadShape";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity13 : GscFidelityObligation {
        attribute :>> fidelityId = "D-MUTABLE";
        attribute :>> diagramLabel = "Metadata store retains values and mutates lists";
        attribute :>> dependsOn = "D-PRODUCER";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1437-1445;1489-1516";
        attribute :>> concreteBoundary = "Compilation context owns eq?-key table; values are stored/accumulated without a deep freeze here";
        attribute :>> encodingRule = "Prove stable object view and key identity before encoding; do not infer immutable payload from a copied table";
        attribute :>> cleanControl = "Old and clean observations require same admitted value semantics and settled ownership";
        attribute :>> failureMapping = "Aliased mutable payload or context change during observation denies credential; no native data-race occurrence claimed";
        attribute :>> reflectionDuty = "Borrow/freeze and actual object lifetime contracts remain open; tree erasure must preserve all consumer-visible identity";
        attribute :>> benefitBoundary = "One shared observation owner may replace duplicated traversals only after all value writers are governed";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "frameShape";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity14 : GscFidelityObligation {
        attribute :>> fidelityId = "D-POLICIES";
        attribute :>> diagramLabel = "Last-value / ordered equal?-set / append are distinct";
        attribute :>> dependsOn = "D-MUTABLE";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1489-1532";
        attribute :>> concreteBoundary = "meta-info-combine! keeps last script-line; option keys use equal? ordered set; other keys append; table->list has TODO sort";
        attribute :>> encodingRule = "Preserve per-key policy, duplicates and encounter order; key-table enumeration is not a promised canonical order";
        attribute :>> cleanControl = "Do not assume fresh table enumeration gives identical serialized output; normalize only after per-consumer proof";
        attribute :>> failureMapping = "Sorting values, using identity instead of equal? or treating all keys as last-wins denies equivalence";
        attribute :>> reflectionDuty = "Actual producer policy and consumer result projection must be proved independently; no canonical-order theorem supplied";
        attribute :>> benefitBoundary = "Typed comparison can tolerate only proven irrelevant differences; raw equality stays conservative and may miss reuse";
        attribute :>> leanSupport = "cleanConsumerCutoff";
        attribute :>> quintSupport = "frameShape";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity15 : GscFidelityObligation {
        attribute :>> fidelityId = "D-WRITER";
        attribute :>> diagramLabel = "Writer output and read-back are separate from stored values";
        attribute :>> dependsOn = "D-POLICIES";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "1358-1388;1419-1424";
        attribute :>> concreteBoundary = "Emitter writes key/value lists with protective block comments and Scheme writer";
        attribute :>> encodingRule = "Observe actual read-back datum or prove admitted writer-reader law; comments are not datum tokens";
        attribute :>> cleanControl = "Same qualified port codec/readtable and logical context; actual serialized shape must match admitted schema";
        attribute :>> failureMapping = "Unreadable value, unknown graph/float representation or parse error denies typed credential";
        attribute :>> reflectionDuty = "Actual Gambit read/write bridge remains open even when the mathematical wire inverse is established";
        attribute :>> benefitBoundary = "Reuse Gambit reader/writer; a mathematical decoder is no retired native parser";
        attribute :>> leanSupport = "decodeWholeEncoded";
        attribute :>> quintSupport = "frameShape";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity16 : GscFidelityObligation {
        attribute :>> fidelityId = "D-CODEC";
        attribute :>> diagramLabel = "Recursive wire inverse / injection proved in the model";
        attribute :>> dependsOn = "D-WRITER";
        attribute :>> sourcePath = "models/build/IncrementalBuild.lean";
        attribute :>> sourceRanges = "437-613";
        attribute :>> concreteBoundary = "RecursiveDatum and DatumSequence use uniform tag/body-length framing; fuel-bounded parser returns suffix or whole tree";
        attribute :>> encodingRule = "Every node is [tag, body-token-length, body...]; pair body has two values; vector body is a sequence; seven atom tags retain payload units";
        attribute :>> cleanControl = "Sufficient model fuel yields decode(encode(tree)) and suffix preservation for any finite modeled tree";
        attribute :>> failureMapping = "Negative/short frame, unknown tag, malformed children or trailing tokens cannot provide a whole-parse witness; None also covers insufficient fuel";
        attribute :>> reflectionDuty = "Eight new theorem statements concern this wire algebra; actual Scheme representation, scalar validation and concrete GSC reflection remain open";
        attribute :>> benefitBoundary = "Closes the recursive wire injection premise under its model, not end-to-end producer reuse";
        attribute :>> leanSupport = "readDatumFrameAppend; recursiveRoundtrip; recursiveEncodingInjective; decodeWholeEncoded; trailingTokensRejected; shortFrameRejected; emptyDatumRejected; emptyPairFrameRejected";
        attribute :>> quintSupport = "frameDatum; frameShape";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity17 : GscFidelityObligation {
        attribute :>> fidelityId = "D-SCALAR";
        attribute :>> diagramLabel = "Frame shape is weaker than full semantic admission";
        attribute :>> dependsOn = "D-CODEC";
        attribute :>> sourcePath = "models/build/incremental_build.qnt";
        attribute :>> sourceRanges = "263-275";
        attribute :>> concreteBoundary = "QNT frameDatum/shape and scalarPayloadShape describe one syntax layer; frameShape([7,0]) holds";
        attribute :>> encodingRule = "Tree round trip allows syntactic atom payloads; separately validate nil/bool/int/character/text/interning and actual wire/domain mapping";
        attribute :>> cleanControl = "Same role/schema and complete context; a valid frame alone cannot bind the actual Scheme consumer";
        attribute :>> failureMapping = "Empty pair frame is rejected by Lean whole decoder despite QNT shallow shape; fuel failure must not be misreported as proven native malformed input";
        attribute :>> reflectionDuty = "Actual fullRecord/codecFaithful issuance still requires recursive and scalar semantic bridge, not caller-set shape flags";
        attribute :>> benefitBoundary = "Blocks false qualification from shallow shape; does not itself save an execution";
        attribute :>> leanSupport = "emptyPairFrameRejected; reflectedFailureExcluded";
        attribute :>> quintSupport = "scalarPayloadShape; shallowPairCounterexample";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity18 : GscFidelityObligation {
        attribute :>> fidelityId = "D-BRIDGE";
        attribute :>> diagramLabel = "Selected linker observes five metadata keys plus other fields";
        attribute :>> dependsOn = "D-SCALAR";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "934-1010;1086-1136;1426-1463";
        attribute :>> concreteBoundary = "combine-meta-info projects five keys; targ-get-mod retains all fields and filename-derived global resources; SCRIPT_LINE consumes its result";
        attribute :>> encodingRule = "Keep full record observation until real factorization proves a smaller view; unknown-key irrelevance is consumer-specific";
        attribute :>> cleanControl = "Ordered base/siblings, first-match assq, last effective script line, flags, filenames and diagnostics remain bound";
        attribute :>> failureMapping = "Dropping arbitrary keys or filenames across every consumer without a factorization proof denies cutoff";
        attribute :>> reflectionDuty = "No actual targ-link factorization or diagnostic/effect equivalence is kernel-proved; tree injection cannot supply these premises";
        attribute :>> benefitBoundary = "Only the one selected composition may be cut; object/native consumers remain separate";
        attribute :>> leanSupport = "cleanConsumerCutoff; concreteSafetyFromRefinement";
        attribute :>> quintSupport = "linkCutoff";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part gscFidelity19 : GscFidelityObligation {
        attribute :>> fidelityId = "D-COST";
        attribute :>> diagramLabel = "Format cost explicit; list proof algorithm is not a fast codec";
        attribute :>> dependsOn = "D-BRIDGE";
        attribute :>> sourcePath = "models/build/IncrementalBuild.lean";
        attribute :>> sourceRanges = "437-613";
        attribute :>> concreteBoundary = "Each tree node contributes two framing integers; recursive list length/take/drop/append may repeat work";
        attribute :>> encodingRule = "For N datum nodes and U scalar payload units, mathematical stream length is 2N+U; recursive list definitions may cost quadratic even for a long vector";
        attribute :>> cleanControl = "No native timing or Lean work-cost theorem supplied; modern C cursor/span and precomputed measure are future algorithm/proof obligations";
        attribute :>> failureMapping = "Fuel exhaustion is nonqualification until cause is known; large integers, scalar conversion and allocation cannot be treated as free";
        attribute :>> reflectionDuty = "Linear traversal needs a separate resource/termination refinement and governed buffer lifetime; no production implementation here";
        attribute :>> benefitBoundary = "Count validation and encoding against avoided recipe cost; Zig has no extra saving proved by this syntax theorem";
        attribute :>> leanSupport = "recursiveRoundtrip";
        attribute :>> quintSupport = "frameDatum";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
}
