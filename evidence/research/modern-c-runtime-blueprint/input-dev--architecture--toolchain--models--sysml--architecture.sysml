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
}
