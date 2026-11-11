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
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1189-1205; vendor/gambit/include/_gambit/module_generation.h.in:1289-1310";
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
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1938-1970; vendor/gambit/include/_gambit/module_generation.h.in:1045-1096; vendor/gambit/include/_gambit/label_types.h.in:72-92";
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
    part duty5 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-CURRENT-COST";
        attribute :>> diagramLabel = "Attribute the actual modern-C bootstrap critical path";
        attribute :>> dependsOn = "DX-ATTRIBUTION; DX-ADMISSION";
        attribute :>> sourcePath = "evidence/research/bootstrap-cost/observations.json";
        attribute :>> sourceRanges = "1-15";
        attribute :>> concreteBoundary = "Successful whole465.719s, from-scratch366.941s, make-j12/GAMBOPTp1. Top-level commands393.236s; residual72.483s remains unattributed. Configured FLAGS_OBJ lacks macro-tracking-zero";
        attribute :>> encodingRule = "Separate two target passes, Scheme generation, C preprocessing/parsing/codegen, linking, artifact custody and supervisor latency; 600 is a ceiling, never a latency objective";
        attribute :>> cleanControl = "Existing Darwin force/configuration studies already retain macro-tracking-zero; its absence in this modern-c baseline is a configuration-lineage gap. Historical single-object figures cannot predict this whole build or peak RSS";
        attribute :>> failureMapping = "No native compilation occurred in a snapshot-check failure; do not call it a slow bootstrap or erase its denial";
        attribute :>> reflectionDuty = "Per-phase/per-TU time, critical path, CPU utilization, peak RSS and residual attribution remain open until observed";
        attribute :>> benefitBoundary = "Already-parallel work may still repeat or serialize at phase boundaries; CPU count alone cannot establish speedup or memory pressure";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "parallelLatencyLowerBound";
        attribute :>> researchStatus = "observed-envelope-and-source; inner-attribution-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-BUDGET";
    }
    part duty6 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-C23-DARWIN";
        attribute :>> diagramLabel = "C23 baseline must retire repeated C macro work by responsibility";
        attribute :>> dependsOn = "DX-CURRENT-COST; DX-LOWERING";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "1187-1208;1944-2010";
        attribute :>> concreteBoundary = "Scheme owns semantics and explicit module/frame plans; stable native ABI/helpers and per-module data have separate dependency identities";
        attribute :>> encodingRule = "Refine the existing ConfiguredNativeModel and M8/E05/E06/E13 obligations, not a new flag table. Common CFLAGS selects C23 for generated C and RTS paths; diagnostic policy is distinct from semantic macro expansion and invariant ABI lowering";
        attribute :>> cleanControl = "Private header organization preserves all public macro text and cannot itself claim reduced front-end work or PCH admission";
        attribute :>> failureMapping = "Do not conflate Scheme macros, C macro token work and GCC diagnostic tracking; do not flatten dynamic-wind, multi-shot continuation, GC roots or source diagnostics";
        attribute :>> reflectionDuty = "Whole-closure callers, layouts, generated metadata and scanner/restore/FFI consumers must migrate before the old macro responsibility retires";
        attribute :>> benefitBoundary = "Measure repeated token/parse reduction versus descriptor/helper/relocation/call costs; diagnostic quality, peak RSS and whole request remain acceptance dimensions";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "positiveWork";
        attribute :>> researchStatus = "required-C23-modernization-target; runtime-and-speedup-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty7 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-FEEDBACK-PATH";
        attribute :>> diagramLabel = "Separate full bootstrap qualification from incremental development work";
        attribute :>> dependsOn = "DX-C23-DARWIN; DX-REUSE";
        attribute :>> sourcePath = "vendor/gambit/makefile.in";
        attribute :>> sourceRanges = "109-144";
        attribute :>> concreteBoundary = "from-scratch intentionally cleans/builds twice; the development path must reuse independently qualified Scheme-generated C and native objects by their actual input projections";
        attribute :>> encodingRule = "Generated C key owns compiler/semantic/source/effect closure; object key owns C/header-layout/toolchain/flags/target; link key owns ordered object/module/runtime closure";
        attribute :>> cleanControl = "Keep both target passes for current complete-bootstrap acceptance; a warm development result must not be relabeled full bootstrap";
        attribute :>> failureMapping = "ABI changes invalidate all real consumers; compiler-stage identity or unknown macro/eval/native reads may forbid generation reuse even if files look unchanged";
        attribute :>> reflectionDuty = "Bind no-change, runtime-leaf, shared-macro, frame-ABI, cancellation and failure outcomes; record eliminated work counts as well as elapsed time";
        attribute :>> benefitBoundary = "No-change should perform zero generation/compile/link on an exact admitted artifact; leaf edits must not trigger unrelated Scheme generation. These are design targets, not measured latency promises";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "positiveWork";
        attribute :>> researchStatus = "incremental-projection-and-retirement-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty8 : GscFidelityObligation {
        attribute :>> fidelityId = "DX-NATIVE-POLICY";
        attribute :>> diagramLabel = "Existing configure and Make; no parallel profile or executor";
        attribute :>> dependsOn = "DX-C23-DARWIN; DX-FEEDBACK-PATH";
        attribute :>> sourcePath = "vendor/gambit/configure.ac";
        attribute :>> sourceRanges = "2978-3345";
        attribute :>> concreteBoundary = "Existing configure.ac owns captures and BUILD templates; existing Make performs compilation and links. Withdrawn native-profile, Scheme executor and recorder have no active role. The existing Bazel-derived Darwin flags plus C23 remain selected";
        attribute :>> encodingRule = "C23 probe covers generated and runtime C; diagnostic provenance compaction is restricted to supported Darwin GNU GCC. It does not eliminate semantic macro expansion";
        attribute :>> cleanControl = "Keep completed two-pass producer identity distinct from native-only Make rebuilds and map/GC tests. Require consecutive no-change and actual C-leaf controls in the same workspace";
        attribute :>> failureMapping = "An autoconf timeout cannot issue a configure reuse proof. Exact archived retired source inputs preserve history without recreating the experiment or admitting current outputs";
        attribute :>> reflectionDuty = "Observe autoconf within its existing 30-second cap; distinguish completed M4 expansion, postprocessing, process scheduling and tool launch. Count actual Make commands; old E01-E32 mode retirement remains unqualified";
        attribute :>> benefitBoundary = "Eliminate unnecessary configuration and generation through exact request reuse; charge hashing, process admission and tests. Native parameters compare with the preceding build in the fixed workspace, never repeatedly with its old seed";
        attribute :>> leanSupport = "positiveDevelopmentWork";
        attribute :>> quintSupport = "positiveWork";
        attribute :>> researchStatus = "existing-configure-make; typed-experiment-withdrawn; incremental-native-qualification-pending; M8-retirement-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part def NativeStageContract {
        attribute workspaceLifetime : String;
        attribute configurationOwner : String;
        attribute requestBoundary : String;
        attribute generationArtifact : String;
        attribute reuseGuard : String;
        attribute invalidate : String;
        attribute failureCustody : String;
        attribute qualification : String;
        attribute benefit : String;
        attribute proofOwnership : String;
    }
    part explicitNativeStage : NativeStageContract {
        attribute :>> workspaceLifetime = "One task-cache development workspace selected by an origin-bound route for first build, no-change rebuild and actual C-leaf edit; no per-run activation key, implicit clean, replacement tree or end-of-run full-tree snapshot. Origin replacement requires explicit rebase. Build entry reconciles active custody without global retention; native run returns its receipt without catalog evaluation";
        attribute :>> configurationOwner = "Existing configure_owned_source is the single owner of full output hashes and actual completed configure receipt. Same selected source/template/profile/tool/environment request skips aclocal/autoconf/configure; C leaf bodies are not configuration inputs. SDK/system replacement requires task-profile requalification; no general read-effect closure issued";
        attribute :>> requestBoundary = "Existing Make consumes explicit completed GeneratedCArtifact, native C leaf delta, ABI and the existing configured BUILD commands; no additional profile or executor. Never silently upgrade the compiler service or issue arbitrary Scheme-query freshness";
        attribute :>> generationArtifact = "One generation-artifact import replaces materialize plus completed-runtime. Authenticate the completed producer once, retain exact historical source bindings, actual generated/linker C and pinned gsc-boot; compare current core Scheme and generated ABI";
        attribute :>> reuseGuard = "Native-only phase3/phase4 replaces gsc-boot with a non-executable directory gate and restores it afterward; complete generated artifact and original producer hashes stay unchanged. Unexpected generation fails; fixture Scheme compilation is accounted separately";
        attribute :>> invalidate = "Changed/new Scheme, compiler service, ABI, unknown generation effect or artifact requires generation. Closed native binding/recipe projection excludes only known native lines from the generation cut; unknown/module/prelude/mixed lines remain. Effective native changes invalidate native outputs; explicit empty Make defaults equal old absent defaults only with overrides refused";
        attribute :>> failureCustody = "The fixed task-owned tree retains failed/partial state and its source-sync custody; preserve logs, reconcile unknown writers and restore the generator gate on ordinary failure. Never hide failure with another tree or auto-clean. The original immutable producer remains untouched";
        attribute :>> qualification = "Same workspace first build, second no-change build, then a real C-leaf edit. ASCENT incremental guards: same-workspace; authenticated-generation; same-config-no-processes; zero-core-generation; nochange-zero-native; cleaf-only-consumers; fixtures-pass; budgets-preserved. Record actual Make invocations, inode, copies, commands and generated artifact equality; never replay a successful native step as the no-change control. This does not establish fresh full-bootstrap or M8 mode equivalence";
        attribute :>> benefit = "Count actually omitted core generation recipes and retained artifacts separately from five fixture compilations; ordinary Make may already generate zero. Charge reconfiguration, source/hash validation, storage and tests; no historical225.93-second or unmatched whole-request speedup credit";
        attribute :>> proofOwnership = "Existing QNT owns invalidation and scheduling histories; existing Lean owns refinement/algebra; ASCENT checks source/native evidence gates. No duplicate state machine or theorem";
    }
    part def ValidationReuseContract {
        attribute checkId : String;
        attribute sourceRefs : String;
        attribute exactIdentity : String;
        attribute lifetime : String;
        attribute invalidators : String;
        attribute reuseStatus : String;
        attribute stillRequired : String;
    }
    part validationReuse0 : ValidationReuseContract {
        attribute :>> checkId = "configuration-proof";
        attribute :>> sourceRefs = "src/gambit_smp/native_capabilities.py::configure_owned_source; src/gambit_smp/native_development.py::configuration_request";
        attribute :>> exactIdentity = "Same configuration request, full generated output set and SHA, successful original command/process receipt, selected tools, flags and environment";
        attribute :>> lifetime = "qualified-task-profile";
        attribute :>> invalidators = "Changed source/templates/tools/flags/environment/output; failed or unknown configure; system/SDK replacement requires requalification";
        attribute :>> reuseStatus = "selected-reuse";
        attribute :>> stillRequired = "Read original receipt and current output SHA; no aclocal/autoconf/configure on a match; C leaf bodies are excluded";
    }
    part validationReuse1 : ValidationReuseContract {
        attribute :>> checkId = "leased-tree-identity";
        attribute :>> sourceRefs = "src/gambit_smp/recipes.py::LeasedTreeChecks; src/gambit_smp/suite_primitives.py::check_runtime";
        attribute :>> exactIdentity = "Held exclusive root dev/inode, full initial inventory SHA, unchanged complete inode/mode/link/size/mtime/ctime stamp, same live request scope";
        attribute :>> lifetime = "live-recipe-lease";
        attribute :>> invalidators = "Any file/tree/stamp change, root replacement, external link, closed scope or new request";
        attribute :>> reuseStatus = "selected-reuse";
        attribute :>> stillRequired = "Metadata walk at each reuse and full SHA at each capability's final verification. Timing counters never grant authority or replace checks";
    }
    part validationReuse2 : ValidationReuseContract {
        attribute :>> checkId = "completed-step";
        attribute :>> sourceRefs = "src/gambit_smp/recipes.py::run; src/gambit_smp/step_checkpoint.py::recovered_resumption";
        attribute :>> exactIdentity = "Original committed observation, same executor and declaration, complete inputs/tools, retained output identity, dependencies and custody";
        attribute :>> lifetime = "retained-observation";
        attribute :>> invalidators = "Changed engine/step/dependencies/inputs/tools/outputs; stale or unavailable custody; failed observation";
        attribute :>> reuseStatus = "retained-only";
        attribute :>> stillRequired = "Recheck checkpoint consumability; inherited work counters are not work executed now and a past PASS is not a fresh scheduling sample";
    }
    part validationReuse3 : ValidationReuseContract {
        attribute :>> checkId = "fixture-compilation";
        attribute :>> sourceRefs = "src/gambit_smp/native_capabilities.py::executable_test; ::shared_fixture; ::check_fixture_context; ::graph";
        attribute :>> exactIdentity = "Direct fresh producer in the same recipe; actual original compile command/receipt; exact source/output bytes, inode, times and modes; full runtime/header/library/helper tree and candidate receipt; sealed tools/frontend, environment, CPU and original cwd path/device/inode";
        attribute :>> lifetime = "same-recipe-compiled-artifact";
        attribute :>> invalidators = "Changed source/tool/runtime/ABI/command/environment/CPU/original cwd or output; alias, failed/unknown process, checkpoint-replayed or chained producer, different recipe. Refuse sharing without recompilation fallback";
        attribute :>> reuseStatus = "same-recipe-only";
        attribute :>> stillRequired = "Existing executable-test explicitly publishes compilation and consumers run that exact original artifact at its original cwd. Both sides retain pre/post context checks and five fresh process observations. No general compiler effect-closure, cross-request cache or hypothetical recompilation equivalence is issued";
    }
    part validationReuse4 : ValidationReuseContract {
        attribute :>> checkId = "smp-execution";
        attribute :>> sourceRefs = "src/gambit_smp/native_capabilities.py::executable_test; vendor/gambit/tests/frame-continuation-roots.scm; vendor/gambit/tests/smp/gc/worker-role-handoff.scm";
        attribute :>> exactIdentity = "Executable, runtime/link closure, fixture, topology/capacity, environment, parameters, transcript oracle and actual process observation";
        attribute :>> lifetime = "actual-execution";
        attribute :>> invalidators = "Changed execution inputs or oracle; new scheduling/GC observation requested; timeout or unknown exit";
        attribute :>> reuseStatus = "fresh-required";
        attribute :>> stillRequired = "Five fresh bounded executions for this acceptance demand; original PASS may remain historical evidence but cannot be labeled a new GC/continuation execution";
    }
    part validationReuse5 : ValidationReuseContract {
        attribute :>> checkId = "framework-controls";
        attribute :>> sourceRefs = "dev/modeling/tools/qualify-native-stage.py; evidence/research/darwin-native-stage/cost-controls.json";
        attribute :>> exactIdentity = "Exact executed test selection and assertion implementation/dependency closure, interpreter/platform/environment, successful retained log and process outcome";
        attribute :>> lifetime = "qualified-test-context";
        attribute :>> invalidators = "Changed test or imported helper, selection, interpreter, environment/platform or assertion dependencies; failed or partial log";
        attribute :>> reuseStatus = "conditional";
        attribute :>> stillRequired = "Explicit short source lists do not close arbitrary imported dependencies. Cost controls bind all framework modules, top-level Python tests and Python executable; fixture data and external runtime/environment closure are separate and still require qualification";
    }
    part def SharedFixtureContract {
        attribute scope : String;
        attribute sourceRefs : String;
        attribute producerConsumers : String;
        attribute identity : String;
        attribute failure : String;
        attribute qualification : String;
        attribute advantage : String;
        attribute proofOwnership : String;
    }
    part sharedFixture : SharedFixtureContract {
        attribute :>> scope = "Existing gambit.executable-test only; explicit same-recipe compilation artifact. No new executor/profile, source clone, cross-request compilation or test-result cache";
        attribute :>> sourceRefs = "src/gambit_smp/native_capabilities.py::graph, validate_executable_test, fixture_file_identity, fixture_compile_observation, shared_fixture, check_fixture_context, executable_test; tests/test_native_executable.py::SharedFixtureTests";
        attribute :>> producerConsumers = "wide-map -> wide-map-host; worker-roles -> worker-roles-host";
        attribute :>> identity = "Producer publishCompilation and consumer compilation reference require direct dependency and identical program/runtime/identity refs. Typed manifest binds same recipe run, fresh producer, source/output and cwd identity, successful quiescent process, tools/frontend/environment/CPU and full runtime tree. Consumers preserve original argv paths and cwd; no key normalization";
        attribute :>> failure = "Any identity, origin, process or alias mismatch refuses before execution with no compile fallback. Compilation or execution mutation cannot publish/pass; interpreter, chained and checkpoint-replayed producers refuse. Fresh terminal SHA checks remain";
        attribute :>> qualification = "ASCENT shared guards: direct-live-producer; source-and-artifact-match; toolchain-match; original-cwd-match; runtime-match; successful-compile; three-compiles-five-executions; same-workspace-budgets. Compare current-engine five-compile control with three-compile case; require five distinct successful execution PIDs and full transcripts";
        attribute :>> advantage = "One actual generated/native program supplies two topology experiments, isolating runtime topology while retaining Gambit map, multi-shot continuation, dynamic-wind and wide roots. Remove two Scheme/C/link fixture compilations; charge manifest/context validation; do not claim whole-runtime modernization or stable latency gain";
        attribute :>> proofOwnership = "SysML owns this artifact/lifetime cut and ASCENT joins actual source/native witnesses. Existing QNT scheduling/invalidation and Lean refinement/algebra remain unchanged; no duplicate formal model";
    }
    part def ArtifactBoundary {
        attribute role : String;
        attribute invalidators : String;
        attribute downstream : String;
        attribute inputProjection : String;
        attribute reuseCondition : String;
        attribute refusal : String;
        attribute workRemoved : String;
    }
    part generation : ArtifactBoundary {
        attribute :>> role = "Scheme generation";
        attribute :>> invalidators = "scheme-source; macro-read; compiler-stage; generation-option; generation-path; generation-effect";
        attribute :>> downstream = "Native compilation";
        attribute :>> inputProjection = "GSC executable plus transitive Scheme/include/macro/eval/reader/native-read and output-effect closure; options, logical paths, stage identity and generated metadata";
        attribute :>> reuseCondition = "Completed producer, immutable output digests, complete stable read/effect snapshot and same generation stage; compiler host reuse does not imply target-C reuse";
        attribute :>> refusal = "Unknown dynamic input/effect, incompatible stage, partial phase, changed generated metadata or unproved path relocation";
        attribute :>> workRemoved = "Only a fully admitted generated-C artifact can remove generation; current full from-scratch still requires both target passes";
    }
    part compilation : ArtifactBoundary {
        attribute :>> role = "Native compilation";
        attribute :>> invalidators = "generated-c; handwritten-c; header-abi; native-policy; native-toolchain; target";
        attribute :>> downstream = "Native linking";
        attribute :>> inputProjection = "Generated or handwritten C, actual headers/fragments/layouts, compiler/specs/SDK, target, ordered effective argv, cwd and relevant environment";
        attribute :>> reuseCondition = "Completed object under exact native projection; config policy changes invalidate affected objects without logically changing Scheme generation inputs";
        attribute :>> refusal = "Changed C23/macro policy, header ABI, compiler or unknown implicit native reads; broad configure identity must not be weakened to force a HIT";
        attribute :>> workRemoved = "Unchanged qualified objects may skip compilation; organizing a header alone removes no preprocessing or code generation";
    }
    part linking : ArtifactBoundary {
        attribute :>> role = "Native linking";
        attribute :>> invalidators = "native-object; native-runtime; link-policy; link-toolchain; module-binding";
        attribute :>> downstream = "";
        attribute :>> inputProjection = "Ordered objects/archive selection/module binding/runtime ABI, linker/SDK, link argv and observable output group";
        attribute :>> reuseCondition = "Complete successful link with current ordered dependency and binding identities; old compiler runtime is never linked into the new target";
        attribute :>> refusal = "Unknown or partial link, changed object/runtime/binding, or unproved natural-exit semantics";
        attribute :>> workRemoved = "Exact completed executable avoids relink; failed partial archives do not become a qualified runtime";
    }
    part def MutableProducerContract {
        attribute sourceRefs : String;
        attribute artifactIdentity : String;
        attribute instanceIdentity : String;
        attribute admission : String;
        attribute mutationLaw : String;
        attribute retirement : String;
        attribute benefitAndCost : String;
        attribute unresolved : String;
    }
    part bootstrapConstructor : MutableProducerContract {
        attribute :>> sourceRefs = "src/gambit_smp/bootstrap_artifacts.py:46-112; src/gambit_smp/workspace.py:604-625";
        attribute :>> artifactIdentity = "Completed configured/compiler/runtime outputs remain keyed by exact content and configuration; a producer activation is forbidden on completed roles";
        attribute :>> instanceIdentity = "Writable working roles additionally bind the verified durable run-header digest and exact step endpoint; input content alone is not mutable identity";
        attribute :>> admission = "Existing native case/history/prior and budget admission precedes construction; activation never enters the native case key or changes compiler flags";
        attribute :>> mutationLaw = "Same-activation drift still refuses; a later admitted producer cannot rewrite or alias the earlier partial work tree or immutable input";
        attribute :>> retirement = "Retire content-only mutable constructor lookup; preserve completed-output content reuse, independent copies and original failure receipts";
        attribute :>> benefitAndCost = "Remove false instance collisions and preserve valid input reuse; each genuinely mutating producer pays copy-on-write metadata and identity validation";
        attribute :>> unresolved = "Current full bootstrap, continuation/GC, failed-join retirement and independent successful-stage import without child receipt remain separately qualified";
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
