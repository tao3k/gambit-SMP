package GambitDarwinDevelopment {
    private import ScalarValues::*;
    private import GambitToolchain::*;
    /* Component history is not a current whole-build speedup witness. */
    part def DevelopmentQualification {
        attribute gainReported : Boolean;
        attribute matchedWholeRequest : Boolean;
        attribute semanticAndFailureParity : Boolean;
        attribute requiredEffectsPreserved : Boolean;
        attribute hostAndToolIdentityBound : Boolean;
        attribute noChangeAccepted : Boolean;
        attribute leafChangeAccepted : Boolean;
        attribute sharedMacroChangeAccepted : Boolean;
    }
    requirement def DevelopmentGainLaw {
        subject witness : DevelopmentQualification;
        require constraint { not witness.gainReported or
            (witness.matchedWholeRequest and witness.semanticAndFailureParity and
             witness.requiredEffectsPreserved and witness.hostAndToolIdentityBound and
             witness.noChangeAccepted and witness.leafChangeAccepted and witness.sharedMacroChangeAccepted) }
    }

    part duty0 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-SPEC";
        attribute :>> diagramLabel = "macOS development is a first-class modern C contract";
        attribute :>> dependsOn = "SV-REFINE; S-COST";
        attribute :>> sourcePath = "dev/architecture/toolchain/models/sysml/macos-development.sysml";
        attribute :>> sourceRanges = "1-22";
        attribute :>> concreteBoundary = "Cold, no-change, leaf, shared-macro, failure/cancel and first-output behavior need separate acceptance";
        attribute :>> encodingRule = "Use phase cost and invalidation identities rather than language substitution or more wrapper layers";
        attribute :>> cleanControl = "Historical receipts bind tool/profile/source/sample; no current build is executed";
        attribute :>> failureMapping = "A model count or cache HIT cannot replace whole-request and semantic acceptance";
        attribute :>> reflectionDuty = "Modernization architecture and work inequalities are design-only; platform causality and speedup remain open";
        attribute :>> benefitBoundary = "Require removed repeated work to exceed validation plus added support; preserve mandatory effects";
        attribute :>> leanSupport = "positiveDevelopmentWork; coordinatorWithoutRemovedWork";
        attribute :>> quintSupport = "positiveWork; oldWork; newWork";
        attribute :>> researchStatus = "conditional-development-contract";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part duty1 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-ATTRIBUTION";
        attribute :>> diagramLabel = "Do not conflate Scheme expansion, C provenance and first-output latency";
        attribute :>> dependsOn = "DX-SPEC";
        attribute :>> sourcePath = "../../patches/gerbil-v19-darwin/receipts/d802-darwin-gcc-frontend.json";
        attribute :>> sourceRanges = "1-49";
        attribute :>> concreteBoundary = "Historical large object 15.45 to 10.37 seconds; 8915 to 97 MiB GCC allocation with exact object parity";
        attribute :>> encodingRule = "Separate C macro diagnostic provenance from Scheme expansion and interface construction; first-output ceilings are not mandated sleeps";
        attribute :>> cleanControl = "Darwin/GNU historical profile only; current code/toolchains and whole-build gains are unqualified";
        attribute :>> failureMapping = "Reader-only, scheduling-only or universal five-second cooldown attribution is unsupported";
        attribute :>> reflectionDuty = "Other receipts narrow startup/reader attribution; no platform-wide causal fraction proved";
        attribute :>> benefitBoundary = "Retain low-risk configured provenance policy; structural lowering must remove repeated front-end work";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "parallelLatencyLowerBound";
        attribute :>> researchStatus = "historical-component-evidence";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part duty2 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-LOWERING";
        attribute :>> diagramLabel = "Move invariant ABI work out of per-module macro expansion";
        attribute :>> dependsOn = "DX-ATTRIBUTION";
        attribute :>> sourcePath = "../../patches/gerbil-v19-darwin/receipts/d861-gambit-header-pch-rejection.md";
        attribute :>> sourceRanges = "1-28";
        attribute :>> concreteBoundary = "PCH was rejected by per-module GLOCOUNT; larger header caching alone did not qualify";
        attribute :>> encodingRule = "Generate explicit per-module descriptors/constants and isolate invariant runtime ABI/helpers; keep Scheme tail/GC/frame semantics";
        attribute :>> cleanControl = "C header/module boundary, debug diagnostics and target configuration need independent parity; no C++ required";
        attribute :>> failureMapping = "Blind PCH, inline-everything, unqualified LLVM switch or lossy source maps cannot claim root fix";
        attribute :>> reflectionDuty = "Frame/root ABI, runtime call cost and actual reduced preprocessing require future design/refinement and matched evidence";
        attribute :>> benefitBoundary = "Can reduce repeated token work while adding helper calls/descriptors; quantify both and retire old macros by role";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "positiveWork";
        attribute :>> researchStatus = "architecture-hypothesis-native-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part duty3 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-REUSE";
        attribute :>> diagramLabel = "One validated native request must remove duplicate preparation";
        attribute :>> dependsOn = "DX-SPEC; SV-ISSUE";
        attribute :>> sourcePath = "../../patches/gerbil-v19-darwin/receipts/d1510-object-request-cost.md";
        attribute :>> sourceRanges = "1-45";
        attribute :>> concreteBoundary = "Existing scheduler already submits objects; all-hit coordinator regressed 0.88 to 1.59 seconds pair means";
        attribute :>> encodingRule = "Reuse scoped immutable tool/config/input snapshot without double preparation; phase/member invalidation and required effects stay bound";
        attribute :>> cleanControl = "One-change member result is separate from stable HIT/cold; do not revive unchanged denied coordinator";
        attribute :>> failureMapping = "All-hit status, extra workers or repeated tool hashing is not a gain; unknown inputs deny reuse";
        attribute :>> reflectionDuty = "Actual snapshot issuer, transitive reads, mutation rejection and net request work remain unqualified";
        attribute :>> benefitBoundary = "Modern C service should retire old preparation paths rather than wrap them; no duplicate C/Zig maintenance default";
        attribute :>> leanSupport = "coordinatorWithoutRemovedWork; positiveDevelopmentWork";
        attribute :>> quintSupport = "positiveWork";
        attribute :>> researchStatus = "historical-regression-and-conditional-design";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part duty4 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-ADMISSION";
        attribute :>> diagramLabel = "Developer gain requires bounded work, latency and memory across real scenarios";
        attribute :>> dependsOn = "DX-REUSE; DX-LOWERING";
        attribute :>> sourcePath = "../../patches/gerbil-v19-darwin/README.md";
        attribute :>> sourceRanges = "145-171;596-605";
        attribute :>> concreteBoundary = "Historical one-change gain coexists with slower stable HIT and unqualified whole-consumer gates";
        attribute :>> encodingRule = "Model DAG invalidation, CPU/memory budgets, critical path and failure custody; select existing process/context isolation until shared-VM SMP qualified";
        attribute :>> cleanControl = "Cold/no-change/leaf/shared macro/tool change/failure/cancel plus semantic outputs and real first progress remain distinct";
        attribute :>> failureMapping = "Do not add nested timings, turn a deadline observation into first-log time, or report component gains as package speedup";
        attribute :>> reflectionDuty = "Existing ten-node to 74-action refinement and native performance still open; QNT work projection is not timing evidence";
        attribute :>> benefitBoundary = "AOT construction programs may share code while contexts remain fresh; necessary instantiation and root work cannot vanish";
        attribute :>> leanSupport = "positiveDevelopmentWork; untouchedPayloadPreservesView";
        attribute :>> quintSupport = "positiveWork; parallelLatencyLowerBound";
        attribute :>> researchStatus = "conditional-whole-request-admission";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }

    /* Required architecture replacement roles, not compiler flag profiles. */
    part def CRefactorRole {
        attribute roleId : String;
        attribute diagramLabel : String;
        attribute sourceRefs : String;
        attribute schemeOwner : String;
        attribute nativeContract : String;
        attribute retiringRole : String;
        attribute retirementCondition : String;
        attribute gainAndCost : String;
        attribute obligationRefs : String;
        attribute dependsOn : String;
    }
    part def CRefactorQualification {
        attribute retired : Boolean;
        attribute producersMigrated : Boolean;
        attribute consumersMigrated : Boolean;
        attribute runtimeSemanticsAccepted : Boolean;
        attribute failureAndControlAccepted : Boolean;
        attribute singleRepresentationOwner : Boolean;
    }
    requirement def CRefactorRetirementLaw {
        subject witness : CRefactorQualification;
        require constraint { not witness.retired or
            (witness.producersMigrated and witness.consumersMigrated and
             witness.runtimeSemanticsAccepted and witness.failureAndControlAccepted and
             witness.singleRepresentationOwner) }
    }
    part replacement0 : CRefactorRole {
        attribute :>> roleId = "C-MODULE";
        attribute :>> diagramLabel = "Module data and invariant runtime ABI";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1189-1205; vendor/gambit/include/gambit.h.in:1244-1265; vendor/gambit/include/gambit.h.in:9328-9355";
        attribute :>> schemeOwner = "Symbol/global identity, supplied bindings and semantic module graph";
        attribute :>> nativeContract = "ModuleSpec plus one explicit native layout encoder and invariant ABI declarations";
        attribute :>> retiringRole = "Per-module count definitions controlling general header layout and repeated macro-generated tables";
        attribute :>> retirementCondition = "All emitters, module setup, bind-late modes and runtime consumers use the same accepted descriptor ABI; no shadow macro producer remains";
        attribute :>> gainAndCost = "Less repeated preprocessing; descriptor loads, relocations and changed inline policy remain charged";
        attribute :>> obligationRefs = "DX-LOWERING";
        attribute :>> dependsOn = "";
    }
    part replacement1 : CRefactorRole {
        attribute :>> roleId = "C-FRAME";
        attribute :>> diagramLabel = "Frame, root and return-point descriptors";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1938-1970; vendor/gambit/include/gambit.h.in:9294-9324";
        attribute :>> schemeOwner = "Liveness, frame slots, continuation kind and semantic return points";
        attribute :>> nativeContract = "FrameSpec and PointId encoded once under explicit layout and root-location laws";
        attribute :>> retiringRole = "DEF_LBL_RET / IFD / OFD string expansion as the cross-component representation contract";
        attribute :>> retirementCondition = "GC scanners, continuation capture/restore, stack walkers and all backends agree on frame/root maps and return identity; tail-call and mixed-edge obligations accepted";
        attribute :>> gainAndCost = "Less repeated descriptor expression expansion; possible decoding, table and source-map costs";
        attribute :>> obligationRefs = "DX-LOWERING";
        attribute :>> dependsOn = "C-MODULE";
    }
    part replacement2 : CRefactorRole {
        attribute :>> roleId = "C-LITERAL";
        attribute :>> diagramLabel = "Object and literal data lowering";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1634-1759";
        attribute :>> schemeOwner = "Literal value, interning/identity and constant graph decisions";
        attribute :>> nativeContract = "Typed object-data plan, relocations and target representation encoder";
        attribute :>> retiringRole = "Repeated textual CNS/SUB object-construction expansion where replaced completely";
        attribute :>> retirementCondition = "Every subtype, cyclic/shared identity, alignment, endian/word-size and module initialization consumer covered; generated data accepted by actual GC/object ABI";
        attribute :>> gainAndCost = "Fewer tokens and duplicate data preparation; relocation and initialization overhead may erase benefit";
        attribute :>> obligationRefs = "DX-LOWERING";
        attribute :>> dependsOn = "C-MODULE";
    }
    part replacement3 : CRefactorRole {
        attribute :>> roleId = "C-EMISSION";
        attribute :>> diagramLabel = "Request-owned emitter and publication lifecycle";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1286-1308; vendor/gambit/gsc/_t-c-1.scm:1393-1397; vendor/gambit/gsc/_utils.scm:426-437; vendor/gambit/gsc/_utils.scm:506-508";
        attribute :>> schemeOwner = "Diagnostics, source identity, observable writes and continuation/exception semantics";
        attribute :>> nativeContract = "Explicit EmissionContext with acquisition-owned port, source map and output-group completion";
        attribute :>> retiringRole = "Ambient targ-port and related mutable emission state as implicit request ownership; normal-close-only delivery assumption";
        attribute :>> retirementCondition = "All dynamic writers, recursive/reentrant emissions, exceptional exits and continuation reentry governed; unqualified extension paths refused rather than silently shared";
        attribute :>> gainAndCost = "Independent job contexts permit safe scheduling; guards, roots, cleanup and output staging are added work";
        attribute :>> obligationRefs = "SV-ISSUE; SV-RESUME; SV-CLEANUP";
        attribute :>> dependsOn = "";
    }
    part replacement4 : CRefactorRole {
        attribute :>> roleId = "C-LINK";
        attribute :>> diagramLabel = "Link observation and consumer protocol";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:880-897; vendor/gambit/gsc/_t-c-1.scm:1086-1125; vendor/gambit/gsc/_t-c-1.scm:1310-1391";
        attribute :>> schemeOwner = "Supplied/demanded modules, resource conflicts, metadata and script-line semantics";
        attribute :>> nativeContract = "One complete typed LinkObservation consumed by the semantic linker; governed serialization only where needed";
        attribute :>> retiringRole = "Embedded Scheme record as compulsory transport and repeated reader reconstruction at migrated consumers";
        attribute :>> retirementCondition = "Actual write/read roundtrip, aliases/FFI, ordered result/exception/effect traces and every consumer migrated; old artifact compatibility is an explicit acceptance question";
        attribute :>> gainAndCost = "Less redundant metadata reconstruction; encoding, validation and optional sidecar I/O charged; no mandatory double format";
        attribute :>> obligationRefs = "SV-ROUNDTRIP; SV-REFINE; DX-REUSE";
        attribute :>> dependsOn = "C-EMISSION; C-MODULE";
    }
}
