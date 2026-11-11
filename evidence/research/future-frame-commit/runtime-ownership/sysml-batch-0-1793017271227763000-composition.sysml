/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRuntimeComposition {
    private import ScalarValues::*;

    part def RuntimeComposition {
        part foundation : T0CollectionBoundary;
        ref part ownershipContract : GambitRuntimeOwnership::CompositionContract = GambitRuntimeOwnership::contract;
        part roleContracts : GambitRuntimeRoles::RoleContractGraph;
        part membershipRevocation : GambitMembershipRevocation::ClosureGraph;
        part publicationClose : GambitPublicationClose::PublicationGraph;
        part synchronousPublication : GambitSynchronousPublication::AssuranceGraph;
        part execution : GambitRuntime::ExecutionBoundary;
        part collector : GambitGc::CollectorBoundary;
        part control : GambitControl::ResumptionBoundary;
        part foreign : GambitFfi::ForeignBoundary;
        part rootHandoff : GambitRuntimeInterfaces::RootHandoff;
        part controlOrigins : GambitRuntimeInterfaces::ControlOrigins;
        part retirement : GambitRuntimeInterfaces::RetirementWindow;
        part completion : GambitRuntimeInterfaces::WorkClosure;
    }


    /* Blueprint metadata: design only; no satisfied or implemented contract. */
    part def BlueprintModule {
        attribute moduleId : String;
        attribute label : String;
        attribute ownerPath : String;
        attribute owns : String;
        attribute provides : String;
        attribute excludes : String;
        attribute painIds : String;
        attribute structureModel : String;
    }
    part def BlueprintInterface {
        attribute interfaceId : String;
        attribute producerId : String;
        attribute consumerId : String;
        attribute payload : String;
        attribute orderedContract : String;
        attribute failureCustody : String;
        attribute existingContracts : String;
        attribute disposition : String;
    }
    part def BlueprintSource {
        attribute factId : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute observation : String;
        attribute limit : String;
    }
    part blueprintModule0 : BlueprintModule {
        attribute :>> moduleId = "semantic";
        attribute :>> label = "Scheme semantic planner";
        attribute :>> ownerPath = "dev/architecture/compiler";
        attribute :>> owns = "Normalization, GVM semantic completion, effects, FrameSpec, PointId and primitive/FFI legality";
        attribute :>> provides = "Closed semantic plan and ordered module contract";
        attribute :>> excludes = "Does not choose execution scheduling or native resource ownership";
        attribute :>> painIds = "generation; frames";
        attribute :>> structureModel = "dev/architecture/compiler/models/sysml/architecture.sysml";
    }
    part blueprintModule1 : BlueprintModule {
        attribute :>> moduleId = "native";
        attribute :>> label = "Modern generated C";
        attribute :>> ownerPath = "dev/refactoring/modern-c";
        attribute :>> owns = "Mechanical lowering and generated frame/root/layout/entry declarations from completed plan";
        attribute :>> provides = "C ABI, trampoline and exact layout adapters";
        attribute :>> excludes = "Does not invent a second Scheme semantic policy";
        attribute :>> painIds = "generation; frames; ffi";
        attribute :>> structureModel = "dev/refactoring/modern-c/models/sysml/architecture.sysml";
    }
    part blueprintModule2 : BlueprintModule {
        attribute :>> moduleId = "execution";
        attribute :>> label = "VM and execution admission";
        attribute :>> ownerPath = "dev/architecture/runtime/execution";
        attribute :>> owns = "Execution grants, park/reentry, participant membership, resize and exit admission";
        attribute :>> provides = "Stable context identity with explicit join/leave and last-user closure";
        attribute :>> excludes = "A descriptor or published TLS pointer is not an execution grant";
        attribute :>> painIds = "exit; work";
        attribute :>> structureModel = "dev/architecture/runtime/execution/models/sysml/architecture.sysml";
    }
    part blueprintModule3 : BlueprintModule {
        attribute :>> moduleId = "roots";
        attribute :>> label = "Root and lifetime interface";
        attribute :>> ownerPath = "dev/architecture/runtime/interfaces";
        attribute :>> owns = "Cross-owner root-cut, slot-update and last-reader agreement; execution/FFI remain value custodians, GC remains scanner";
        attribute :>> provides = "Epoch-bound root slots and scan grants with reload obligations";
        attribute :>> excludes = "Does not take semantic ownership away from producer and scanner modules";
        attribute :>> painIds = "work; ffi; frames";
        attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
    }
    part blueprintModule4 : BlueprintModule {
        attribute :>> moduleId = "collector";
        attribute :>> label = "Allocation and collection";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> owns = "Heap layout, allocation budgets, copy/scan tasks, phases, promotion and reclaim decisions";
        attribute :>> provides = "Complete work context with parent/child/Tail custody and phase closure";
        attribute :>> excludes = "Worker identity does not imply processor or native-thread identity";
        attribute :>> painIds = "work; copy; release";
        attribute :>> structureModel = "dev/architecture/runtime/gc/models/sysml/architecture.sysml";
    }
    part blueprintModule5 : BlueprintModule {
        attribute :>> moduleId = "control";
        attribute :>> label = "Continuation and dynamic control";
        attribute :>> ownerPath = "dev/architecture/runtime/control";
        attribute :>> owns = "Captured/current/saved frame interpretation, denv mutation, restore and supported nonlocal exits";
        attribute :>> provides = "Root-complete frame traversal and resumption origins";
        attribute :>> excludes = "Gambit continuations are not silently restricted to one-shot effect resumptions";
        attribute :>> painIds = "frames; copy";
        attribute :>> structureModel = "dev/architecture/runtime/control/models/sysml/architecture.sysml";
    }
    part blueprintModule6 : BlueprintModule {
        attribute :>> moduleId = "foreign";
        attribute :>> label = "Foreign entry and blocking";
        attribute :>> ownerPath = "dev/architecture/runtime/ffi";
        attribute :>> owns = "Borrow scopes, root protection before marker allocation, nested callback origin and acquired-effect cleanup";
        attribute :>> provides = "Admitted host entry, block transition and explicit result/control boundary";
        attribute :>> excludes = "Raw C pointers do not survive moving GC by language interoperability alone";
        attribute :>> painIds = "ffi; frames; exit";
        attribute :>> structureModel = "dev/architecture/runtime/ffi/models/sysml/architecture.sysml";
    }
    part blueprintModule7 : BlueprintModule {
        attribute :>> moduleId = "release";
        attribute :>> label = "Resource release coordination";
        attribute :>> ownerPath = "dev/architecture/runtime/ffi";
        attribute :>> owns = "Classified release effects, thread-affine jobs, WaitContext, derived-task accounting and shutdown drain";
        attribute :>> provides = "Accepted task custody and exactly owned completion/result disposition";
        attribute :>> excludes = "A drained GC phase is not proof that external resources or borrowers drained";
        attribute :>> painIds = "release; exit";
        attribute :>> structureModel = "dev/architecture/runtime/ffi/models/sysml/architecture.sysml";
    }
    part blueprintModule8 : BlueprintModule {
        attribute :>> moduleId = "build";
        attribute :>> label = "Incremental build engine and artifact graph";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> owns = "Rule planning, dependencies, rebuild decision, CPU/memory scheduling and transactional artifact publication";
        attribute :>> provides = "Source/plan/generated/object/link lineage and effective multicore ABI";
        attribute :>> excludes = "Does not define Scheme unit semantics or count build threads as runtime processors";
        attribute :>> painIds = "profile; generation";
        attribute :>> structureModel = "dev/architecture/toolchain/models/sysml/architecture.sysml";
    }
    part blueprintInterface0 : BlueprintInterface {
        attribute :>> interfaceId = "PlanAbi";
        attribute :>> producerId = "semantic";
        attribute :>> consumerId = "native";
        attribute :>> payload = "CompletedPlan, ordered modules, FrameSpec, PointId, effects and target projection";
        attribute :>> orderedContract = "Semantic completion and coverage close before emission; generated consumers match schema";
        attribute :>> failureCustody = "Reject emission or invalidate affected products; no partially guessed semantic plan";
        attribute :>> existingContracts = "GambitCompiler::TransformLaw; GambitCompiler::ProductLaw";
        attribute :>> disposition = "proposed composition; BF-SCHEMA";
    }
    part blueprintInterface1 : BlueprintInterface {
        attribute :>> interfaceId = "RootCut";
        attribute :>> producerId = "roots";
        attribute :>> consumerId = "collector";
        attribute :>> payload = "VM/context incarnation, collection epoch, slot IDs, value publication and reload debt";
        attribute :>> orderedContract = "Freeze legal producers; publish slots before scan admission; moving updates before reentry acquire";
        attribute :>> failureCustody = "Producer retains roots until accepted handoff; unknown outcome retains custody";
        attribute :>> existingContracts = "ROOT-HANDOFF";
        attribute :>> disposition = "existing binding; full writer and weak-memory refinement open";
    }
    part blueprintInterface2 : BlueprintInterface {
        attribute :>> interfaceId = "ControlRoots";
        attribute :>> producerId = "control";
        attribute :>> consumerId = "collector";
        attribute :>> payload = "FrameSpec identity, current/saved/captured origins, denv edges and supported mutation writers";
        attribute :>> orderedContract = "Seal origins and mutation coverage before mature-scan exclusion; preserve relocated frame interpretation";
        attribute :>> failureCustody = "Opaque mutation uses explicitly sound scan fallback; uncovered bypass blocks scan exclusion";
        attribute :>> existingContracts = "CONTROL-ORIGIN";
        attribute :>> disposition = "existing binding; BF-GENERATION adds full writer closure";
    }
    part blueprintInterface3 : BlueprintInterface {
        attribute :>> interfaceId = "Participation";
        attribute :>> producerId = "foreign";
        attribute :>> consumerId = "execution";
        attribute :>> payload = "Exclusive execution grant, park acknowledgement, root-cut epoch and resumed-value reload";
        attribute :>> orderedContract = "Publish roots and end managed borrow before park; reacquire ownership and reload after GC before callback";
        attribute :>> failureCustody = "Rollback only effects actually acquired on the live origin; no unsafe forced participant removal";
        attribute :>> existingContracts = "GambitFfi::ParkLaw; GambitFfi::ReentryLaw";
        attribute :>> disposition = "proposed composition; BF-PARTICIPATION";
    }
    part blueprintInterface4 : BlueprintInterface {
        attribute :>> interfaceId = "WorkClosure";
        attribute :>> producerId = "execution";
        attribute :>> consumerId = "collector";
        attribute :>> payload = "Producer census, context/grant IDs, private and queued work, parent children, Tail and phase epoch";
        attribute :>> orderedContract = "Membership transition accounts every private task and descendant; no finish based only on empty queue";
        attribute :>> failureCustody = "Reject retains original work; unknown transfer freezes source execution while custody and region pins survive";
        attribute :>> existingContracts = "GC-WORK-CLOSURE";
        attribute :>> disposition = "existing binding; native refinement and independent-worker admission open";
    }
    part blueprintInterface5 : BlueprintInterface {
        attribute :>> interfaceId = "ReleaseDrain";
        attribute :>> producerId = "collector";
        attribute :>> consumerId = "release";
        attribute :>> payload = "Resource class, rooted payload, accepted task ID, WaitContext and descendant count";
        attribute :>> orderedContract = "Accept custody before source teardown; close external producers, drain accepted descendants, then reclaim";
        attribute :>> failureCustody = "Failed accept leaves source responsible; accepted failure retains result policy and exactly one final owner";
        attribute :>> existingContracts = "GambitFfi::ParkLaw";
        attribute :>> disposition = "proposed extension; BF-RELEASE; ParkLaw alone does not prove drain";
    }
    part blueprintInterface6 : BlueprintInterface {
        attribute :>> interfaceId = "OutcomeLifetime";
        attribute :>> producerId = "release";
        attribute :>> consumerId = "execution";
        attribute :>> payload = "Original Scheme outcome, independent completion owner, native release result and last-user state";
        attribute :>> orderedContract = "Seal callback/error admission while receiver live; retain admitted outcomes through resource and OS-user drain";
        attribute :>> failureCustody = "Late outcome has declared recipient/disposition; never drop error or retry an invalidated release function";
        attribute :>> existingContracts = "RETIRE-WINDOW";
        attribute :>> disposition = "existing binding plus BF-EXIT extension; no whole-shutdown theorem";
    }
    part blueprintInterface7 : BlueprintInterface {
        attribute :>> interfaceId = "ArtifactClosure";
        attribute :>> producerId = "build";
        attribute :>> consumerId = "native";
        attribute :>> payload = "Effective profile, schema and frame/root ABI, tool identity, ordered argv/env/cwd and output manifest";
        attribute :>> orderedContract = "Complete relevant dependency cut and successful multi-output transaction before reuse/link publication";
        attribute :>> failureCustody = "Failed/cancelled attempt cannot publish success; discard staging and preserve negative receipt";
        attribute :>> existingContracts = "GambitToolchain::NativeArtifactProfileLaw; GambitToolchain::EffectiveMulticoreProfileLaw";
        attribute :>> disposition = "proposed build composition; BF-BUILD-CUT; BF-BUILD-BUDGET";
    }
    part blueprintSource0 : BlueprintSource {
        attribute :>> factId = "processor-storage";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "277-318";
        attribute :>> observation = "Collector queues, cursors, RC and weak work are selected through PSTATE aliases";
        attribute :>> limit = "Source coupling; does not alone establish a defect";
    }
    part blueprintSource1 : BlueprintSource {
        attribute :>> factId = "copy-progress";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "3572-3625";
        attribute :>> observation = "Winner forwarding, incoming redirect, cell rebinding, payload loop and chunk publication are ordered C steps";
        attribute :>> limit = "Any resumable adapter must preserve complete pending state; no native migration hook exists here";
    }
    part blueprintSource2 : BlueprintSource {
        attribute :>> factId = "root-scan";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "3969-3988";
        attribute :>> observation = "mark_rc scans data slots and permits collector relocation updates";
        attribute :>> limit = "Registration/scanning/transfer complete caller closure remains open";
    }
    part blueprintSource3 : BlueprintSource {
        attribute :>> factId = "foreign-release";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "4387-4453";
        attribute :>> observation = "Still cleanup calls foreign release then frees storage";
        attribute :>> limit = "Moving it to a worker requires effect and payload lifetime qualification";
    }
    part blueprintSource4 : BlueprintSource {
        attribute :>> factId = "marker";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> sourceRanges = "6511-6547";
        attribute :>> observation = "Marker allocation precedes a TODO about protecting incoming proc_or_false";
        attribute :>> limit = "Actual legal callers and exception paths must be enumerated";
    }
    part blueprintSource5 : BlueprintSource {
        attribute :>> factId = "checkpoint";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceRanges = "4505-4524";
        attribute :>> observation = "Return address and cached roots are written before wait and reloaded afterward";
        attribute :>> limit = "Existing protocol must be reused, not reapplied as a new missing fix";
    }
    part blueprintSource6 : BlueprintSource {
        attribute :>> factId = "semantic-entry";
        attribute :>> sourcePath = "vendor/gambit/gsc/_front.scm";
        attribute :>> sourceRanges = "225-250";
        attribute :>> observation = "Compilation context creates environment and C interface before normalization";
        attribute :>> limit = "Immutable export is a new producer contract, not a current file cache";
    }
    part blueprintSource7 : BlueprintSource {
        attribute :>> factId = "module-link";
        attribute :>> sourcePath = "vendor/gambit/gsc/_t-c-1.scm";
        attribute :>> sourceRanges = "880-1015;1086-1105";
        attribute :>> observation = "Linker checks/merges module demand, supply, flags and metadata";
        attribute :>> limit = "C/object-only keys lose semantic-link obligations";
    }
    part blueprintSource8 : BlueprintSource {
        attribute :>> factId = "ocaml-exit";
        attribute :>> sourcePath = "vendor/ocaml/runtime/domain.c";
        attribute :>> sourceRanges = "2262-2360";
        attribute :>> observation = "Domain exit finishes work, orphans ephemerons/finalizers, rechecks new work and locks participant removal";
        attribute :>> limit = "Learning reference at pinned source; cannot transplant its domain or continuation ABI";
    }
    part blueprintSource9 : BlueprintSource {
        attribute :>> factId = "ocaml-remembered";
        attribute :>> sourcePath = "vendor/ocaml/runtime/minor_gc.c";
        attribute :>> sourceRanges = "533-642";
        attribute :>> observation = "Parallel promotion divides remembered-set work across participating domains";
        attribute :>> limit = "Gambit writer coverage and capacity contracts still need their own argument";
    }
    part blueprintSource10 : BlueprintSource {
        attribute :>> factId = "ocaml-barrier";
        attribute :>> sourcePath = "vendor/ocaml/runtime/memory.c";
        attribute :>> sourceRanges = "176-222";
        attribute :>> observation = "Write barrier combines major marking concerns with major-to-minor remembered slots";
        attribute :>> limit = "Algorithm-specific memory order must not be copied as a general C rule";
    }

    part generatedEntryInterface : BlueprintInterface {
        attribute :>> interfaceId = "GeneratedCheckpoint";
        attribute :>> producerId = "native";
        attribute :>> consumerId = "execution";
        attribute :>> payload = "FrameSpec, PointId, entry/return labels, root maps, module setup and exact frame/runtime ABI";
        attribute :>> orderedContract = "Validate module/descriptor identity before entry; generated checkpoints materialize roots and restore relocated state under an execution grant";
        attribute :>> failureCustody = "Reject mismatched ABI before invocation; preserve actual acquired roots/effects on exceptional return";
        attribute :>> existingContracts = "GambitCompiler::ProductLaw; GambitRuntime::ExecutionAdmissionLaw";
        attribute :>> disposition = "proposed native/runtime composition; BF-SCHEMA; BF-PARTICIPATION";
    }
    part def ComposedRuntimeAcceptance {
        attribute accepted : Boolean;
        attribute semanticAbiClosed : Boolean;
        attribute rootAndControlClosed : Boolean;
        attribute participationAndWorkClosed : Boolean;
        attribute foreignAndResourceClosed : Boolean;
        attribute artifactClosureClosed : Boolean;
        attribute weakMemoryRefined : Boolean;
        attribute nativeQualified : Boolean;
        attribute benefitQualified : Boolean;
    }
    requirement def ComposedRuntimeAcceptanceLaw {
        subject design : ComposedRuntimeAcceptance;
        require constraint { not design.accepted or
            (design.semanticAbiClosed and design.rootAndControlClosed and
             design.participationAndWorkClosed and design.foreignAndResourceClosed and
             design.artifactClosureClosed and design.weakMemoryRefined and
             design.nativeQualified and design.benefitQualified) }
    }

    part def T0FoundationLane {
        attribute laneId : String;
        attribute label : String;
        attribute blueprintModules : String;
        attribute targetDesign : String;
        attribute retiringResponsibility : String;
        attribute frameContract : String;
        attribute migrationStages : String;
        attribute sharedContracts : String;
        attribute frameLawRefs : String;
        attribute necessaryAndAddedCost : String;
        attribute openArchitecture : String;
        attribute sourceRefs : String;
    }
    part foundationLane0 : T0FoundationLane {
        attribute :>> laneId = "T0-EXECUTION";
        attribute :>> label = "Execution and participation separation";
        attribute :>> blueprintModules = "execution; roots";
        attribute :>> targetDesign = "VmDomain + ExecutionContext grant + separate ParticipantRecord and membership epoch";
        attribute :>> retiringResponsibility = "Replace assumption that processor/PSTATE identity alone authorizes execution, root participation or removal";
        attribute :>> frameContract = "Explicit owner grant, park/reentry and final-root handoff; frame addresses alone grant nothing";
        attribute :>> migrationStages = "workCore; entryPark; exitLifecycle";
        attribute :>> sharedContracts = "ROOT-HANDOFF; RETIRE-WINDOW";
        attribute :>> frameLawRefs = "FL-HANDOFF; FL-T0";
        attribute :>> necessaryAndAddedCost = "Context/epoch descriptors and acquisition checks; existing parking/root flush remains required";
        attribute :>> openArchitecture = "Full supported participant census and same-VM multi-thread progress; distinct VM capability is not shared-VM SMP";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:276-311; vendor/gambit/lib/_kernel.scm:4505-4524";
    }
    part foundationLane1 : T0FoundationLane {
        attribute :>> laneId = "T0-ROOTS";
        attribute :>> label = "Generated root and frame contract";
        attribute :>> blueprintModules = "semantic; native; roots";
        attribute :>> targetDesign = "One completed FrameSpec with generated encode/decode, slot transforms and RootCut view";
        attribute :>> retiringResponsibility = "Replace independent layout/root interpretations across generator, live scanner, heap scanner, control and FFI";
        attribute :>> frameContract = "FrameSpec is the common interface; root coverage includes control/register/foreign routes";
        attribute :>> migrationStages = "schema; entryPark; workCore";
        attribute :>> sharedContracts = "ROOT-HANDOFF; CONTROL-ORIGIN";
        attribute :>> frameLawRefs = "FL-ENCODE; FL-BIND; FL-COORD; FL-INTERNAL; FL-MAP; FL-COVERAGE; FL-HANDOFF";
        attribute :>> necessaryAndAddedCost = "Generated projections and admission validation; precise metadata/lifetime cost charged against current maps";
        attribute :>> openArchitecture = "No standalone new GC model copied into DEV; source liveness and actual C refinement still required";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-2.scm:825-904; vendor/gambit/lib/mem.c:3896-3968; vendor/gambit/lib/mem.c:4104-4155";
    }
    part foundationLane2 : T0FoundationLane {
        attribute :>> laneId = "T0-WORK";
        attribute :>> label = "Collector work independent of mutator storage";
        attribute :>> blueprintModules = "collector; execution";
        attribute :>> targetDesign = "CollectorWorkContext + task/copy custody + root-scan grants + phase coordinator";
        attribute :>> retiringResponsibility = "Retire PSTATE-selected queues/cursors as universal ownership; worker need not be its source mutator";
        attribute :>> frameContract = "A scanner carries VM/epoch/FrameSpec view and lease; reassigning work never implicitly resumes/migrates Scheme";
        attribute :>> migrationStages = "workCore; generation";
        attribute :>> sharedContracts = "GC-WORK-CLOSURE; ROOT-HANDOFF";
        attribute :>> frameLawRefs = "FL-COVERAGE; FL-UPDATE; FL-HANDOFF; FL-T0";
        attribute :>> necessaryAndAddedCost = "Task/context records, queue/handoff and cache-line traffic; gain requires actual load-balance/work reduction";
        attribute :>> openArchitecture = "Root participants and collector workers are distinct sets; producer closure, resize common result and independent-worker capacity remain obligations";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:276-311; vendor/gambit/lib/mem.c:6830-6870; vendor/gambit/lib/mem.c:7014-7048";
    }
    part foundationLane3 : T0FoundationLane {
        attribute :>> laneId = "T0-HEAP";
        attribute :>> label = "Allocation, generations and capacity ownership";
        attribute :>> blueprintModules = "collector; roots";
        attribute :>> targetDesign = "Context allocation grants + VM capacity epoch + remembered-edge protocol + accepted promotion policy";
        attribute :>> retiringResponsibility = "Replace conflated allocation/worker/context accounting; skip old-frame scans only for writer-complete admitted classes";
        attribute :>> frameContract = "All frame/denv/foreign writes obey root/store contract; FrameSpec is necessary but does not prove barrier closure";
        attribute :>> migrationStages = "generation; workCore";
        attribute :>> sharedContracts = "ROOT-HANDOFF; GC-WORK-CLOSURE";
        attribute :>> frameLawRefs = "FL-COVERAGE; FL-WRITERS";
        attribute :>> necessaryAndAddedCost = "Barriers, remembered logs, promotion reserve and overflow handling; full-scan baseline retained where required";
        attribute :>> openArchitecture = "Do not copy OCaml algorithm by name; compare actual repeated scan work against barrier/promotion/cache cost";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:288-311; vendor/gambit/lib/mem.c:6300-6365; vendor/gambit/lib/_kernel.scm:3439-3597";
    }
    part foundationLane4 : T0FoundationLane {
        attribute :>> laneId = "T0-CONTROL";
        attribute :>> label = "Continuation and frame lifetime independent of carrier";
        attribute :>> blueprintModules = "control; roots; native";
        attribute :>> targetDesign = "Logical continuation chain + current/saved/heap origins + descriptor/image leases";
        attribute :>> retiringResponsibility = "Replace implicit offsets/origin/lifetime and one carrier equated with one continuation owner";
        attribute :>> frameContract = "Same coordinate, root, control-edge and lease laws across capture, restore, serialize and frame mutation";
        attribute :>> migrationStages = "schema; entryPark; exitLifecycle";
        attribute :>> sharedContracts = "CONTROL-ORIGIN; RETIRE-WINDOW";
        attribute :>> frameLawRefs = "FL-COORD; FL-INTERNAL; FL-COVERAGE; FL-UPDATE; FL-WRITERS; FL-T0";
        attribute :>> necessaryAndAddedCost = "Origin/lease metadata and governed writers; necessary copy and dynamic-wind effects remain";
        attribute :>> openArchitecture = "Preserve supported multi-shot Scheme behavior; cross-VM movement is not granted by worker migration";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3667-3809; vendor/gambit/lib/_kernel.scm:1170-1278; vendor/gambit/lib/_io.scm:11688-11730";
    }
    part foundationLane5 : T0FoundationLane {
        attribute :>> laneId = "T0-FOREIGN";
        attribute :>> label = "Root-safe host ownership and resource release";
        attribute :>> blueprintModules = "foreign; release; execution";
        attribute :>> targetDesign = "Native borrow/root handles + blocking participation + nested callback custody + owner-qualified release";
        attribute :>> retiringResponsibility = "Replace implicit marker/root/OS-thread assumptions and ungoverned callback cleanup roles";
        attribute :>> frameContract = "Frame view and native roots compose; unknown aliases must be governed, conservatively covered or refused";
        attribute :>> migrationStages = "entryPark; releaseDrain; exitLifecycle";
        attribute :>> sharedContracts = "ROOT-HANDOFF; RETIRE-WINDOW";
        attribute :>> frameLawRefs = "FL-COVERAGE; FL-WRITERS; FL-HANDOFF";
        attribute :>> necessaryAndAddedCost = "Root/borrow records, callback admission and deferred release bookkeeping; old required root protection is baseline";
        attribute :>> openArchitecture = "Do not run arbitrary foreign destructor on a GC worker; actual owner/cancel/exception callers remain gates";
        attribute :>> sourceRefs = "vendor/gambit/lib/c_intf.c:6511-6547; vendor/gambit/lib/_kernel.scm:4505-4524; vendor/gambit/lib/_io.scm:11705-11730";
    }
    part foundationLane6 : T0FoundationLane {
        attribute :>> laneId = "T0-PROGRESS";
        attribute :>> label = "Whole SMP safety plus progress and scalability";
        attribute :>> blueprintModules = "collector; execution; control; release";
        attribute :>> targetDesign = "Epoch-coherent participant/root cuts + independent work closure + reclaim permits + fairness/wait graph";
        attribute :>> retiringResponsibility = "Replace equating local queue-empty, fixed BARRIER population or successful finite safety with global completion";
        attribute :>> frameContract = "Frame coverage is only one rely/guarantee input; no waits may conceal a root/task required by the awaited GC";
        attribute :>> migrationStages = "workCore; exitLifecycle; qualification";
        attribute :>> sharedContracts = "GC-WORK-CLOSURE; ROOT-HANDOFF; CONTROL-ORIGIN; RETIRE-WINDOW";
        attribute :>> frameLawRefs = "FL-T0; FL-HANDOFF";
        attribute :>> necessaryAndAddedCost = "Coordinator/ack/progress machinery, contention and drain latency; per-epoch capacity publication must be consistent";
        attribute :>> openArchitecture = "No forced single processor/global lock as the gain claim; build parallelism and separate VMs do not establish same-VM SMP";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:6938-6958; vendor/gambit/lib/mem.c:7014-7048";
    }

    part def T0BaselineReuse {
        attribute bindingId : String;
        attribute role : String;
        attribute targetGap : String;
    }
    part baselineReuse0 : T0BaselineReuse {
        attribute :>> bindingId = "ROOT-HANDOFF";
        attribute :>> role = "Reuse exact existing root model/library and scoped conditional receipt";
        attribute :>> targetGap = "New context/work ownership and C memory-order adapters still require refinement";
    }
    part baselineReuse1 : T0BaselineReuse {
        attribute :>> bindingId = "CONTROL-ORIGIN";
        attribute :>> role = "Reuse current/saved/captured origin correspondence and existing limitations";
        attribute :>> targetGap = "Target migration/lease and generated frame maps do not follow from a filename";
    }
    part baselineReuse2 : T0BaselineReuse {
        attribute :>> bindingId = "RETIRE-WINDOW";
        attribute :>> role = "Reuse last-user/backing-retirement obligation";
        attribute :>> targetGap = "Target descriptor/image users and weak-memory lifetime must be completed";
    }
    part baselineReuse3 : T0BaselineReuse {
        attribute :>> bindingId = "GC-WORK-CLOSURE";
        attribute :>> role = "Reuse selected task/phase/accounting model and preserved counterexamples";
        attribute :>> targetGap = "Target worker/participant split, full producer census, capacity result and global progress remain open";
    }

    /* Target GC/SMP protocol boundary, reusing shared record definitions.
     * Necessary guards only; no concrete instance, satisfaction or behavior proof. */
    part def T0CollectionBoundary {
        part vm : GambitSharedRuntime::VmRecord;
        part context : GambitSharedRuntime::ContextRecord;
        part roots : GambitSharedRuntime::RootCarrierRecord;
        attribute scannerVmId : Integer;
        attribute rootContextId : Integer;
        attribute scanContextId : Integer;
        attribute workerGrantVmId : Integer;
        attribute workerGrantEpoch : Integer;
        attribute workClosureEpoch : Integer;
        attribute capacityEpoch : Integer;
        attribute scannerEpoch : Integer;
        attribute rootCutEpoch : Integer;
        attribute scanGranted : Boolean;
        attribute finalRootsObserved : Boolean;
        attribute conflictingMutationStopped : Boolean;
        attribute workerTaskGrantLive : Boolean;
        attribute descriptorLeaseLive : Boolean;
        attribute resumeGranted : Boolean;
        attribute wholeGcCompleted : Boolean;
        attribute completeRootParticipantCensus : Boolean;
        attribute allWorkProducersClosed : Boolean;
        attribute privateWorkDrained : Boolean;
        attribute queuedWorkDrained : Boolean;
        attribute claimedWorkDrained : Boolean;
        attribute descendantDebtDrained : Boolean;
        attribute weakAndCleanupCompleted : Boolean;
        attribute commonCapacityAccepted : Boolean;
        attribute participantMembershipConsistent : Boolean;
        attribute reclaimGranted : Boolean;
        attribute targetIngressClosed : Boolean;
        attribute allTargetUsersDrained : Boolean;
        attribute targetSpecificPermit : Boolean;
    }
    requirement def T0ScannerAdmissionLaw {
        subject witness : T0CollectionBoundary;
        require constraint { not witness.scanGranted or
            (witness.context.vmId == witness.vm.vmId and witness.roots.vmId == witness.vm.vmId and
             witness.scannerVmId == witness.vm.vmId and witness.scannerEpoch == witness.rootCutEpoch and
             witness.scannerEpoch == witness.vm.requestEpoch and
             witness.rootContextId == witness.context.contextId and witness.scanContextId == witness.context.contextId and
             witness.workerGrantVmId == witness.scannerVmId and witness.workerGrantEpoch == witness.scannerEpoch and
             witness.finalRootsObserved and witness.conflictingMutationStopped and
             witness.workerTaskGrantLive and witness.descriptorLeaseLive and witness.roots.scannerCustodianLive) }
    }
    requirement def T0ManagedResumeLaw {
        subject witness : T0CollectionBoundary;
        require constraint { not witness.resumeGranted or
            (witness.context.vmId == witness.vm.vmId and witness.context.executionOwned and
             witness.context.requestReconciled and witness.context.allRequiredValuesReloaded and
             witness.context.oldAliasesInvalidated and witness.descriptorLeaseLive and
             witness.context.loadedRelocationEpoch == witness.vm.completedRelocationEpoch) }
    }
    requirement def T0WholeCompletionLaw {
        subject witness : T0CollectionBoundary;
        require constraint { not witness.wholeGcCompleted or
            (witness.rootCutEpoch == witness.vm.requestEpoch and witness.workClosureEpoch == witness.vm.requestEpoch and
             witness.capacityEpoch == witness.vm.requestEpoch and
             witness.completeRootParticipantCensus and witness.allWorkProducersClosed and
             witness.privateWorkDrained and witness.queuedWorkDrained and witness.claimedWorkDrained and
             witness.descendantDebtDrained and witness.weakAndCleanupCompleted and
             witness.commonCapacityAccepted and witness.participantMembershipConsistent) }
    }
    requirement def T0TargetReclaimLaw {
        subject witness : T0CollectionBoundary;
        require constraint { not witness.reclaimGranted or
            (witness.targetIngressClosed and witness.allTargetUsersDrained and
             witness.targetSpecificPermit and witness.roots.noScannerUsers) }
    }
    /* Native OpenSysML view boundary. References reuse the target records above.
     * Connections show architectural dependencies, not execution order or proved protocols. */
    part def T0TargetGraph {
        ref part execution : T0FoundationLane = foundationLane0;
        ref part roots : T0FoundationLane = foundationLane1;
        ref part work : T0FoundationLane = foundationLane2;
        ref part heap : T0FoundationLane = foundationLane3;
        ref part control : T0FoundationLane = foundationLane4;
        ref part foreign : T0FoundationLane = foundationLane5;
        ref part progress : T0FoundationLane = foundationLane6;
        connection executionRootCut connect execution to roots;
        connection rootsScanGrant connect roots to work;
        connection workCapacity connect work to heap;
        connection heapCompletion connect heap to execution;
        connection controlOrigins connect control to roots;
        connection foreignParticipation connect foreign to execution;
        connection foreignRoots connect foreign to roots;
        connection workClosure connect work to progress;
        connection commonCompletion connect progress to execution;
    }

}
