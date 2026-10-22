/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRuntimeComposition {
    private import ScalarValues::*;

    part def RuntimeComposition {
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
}
