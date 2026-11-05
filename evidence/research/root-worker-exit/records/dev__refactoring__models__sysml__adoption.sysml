/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRefactoring {
    private import ScalarValues::*;

    part def ReplacementDecision {
        attribute modernCRequired : Boolean;
        attribute cCapabilityPreserved : Boolean;
        attribute zigSelected : Boolean;
        attribute namedResponsibilityReplaced : Boolean;
        attribute incrementalBenefitEstablished : Boolean;
        attribute oldImplementationRetired : Boolean;
        attribute singleSemanticOwner : Boolean;
    }
    requirement def BaselineLaw {
        subject decision : ReplacementDecision;
        require constraint { decision.modernCRequired and
            decision.cCapabilityPreserved and decision.singleSemanticOwner }
    }
    requirement def ZigIncrementLaw {
        subject decision : ReplacementDecision;
        require constraint { not decision.zigSelected or
            (decision.namedResponsibilityReplaced and
             decision.incrementalBenefitEstablished and decision.oldImplementationRetired) }
    }


    /* Research motivation, not a present-defect or native-acceptance assertion. */
    part def RefactoringPressure {
        attribute painId : String;
        attribute problem : String;
        attribute sourcePath : String;
        attribute sourceRanges : String;
        attribute publicReference : String;
        attribute evidenceBoundary : String;
        attribute structuralCoupling : String;
        attribute repairLimit : String;
        attribute replacement : String;
        attribute retirement : String;
        attribute responsibleModule : String;
        attribute benefitMeasures : String;
        attribute newCosts : String;
    }
    part exitPressure : RefactoringPressure {
        attribute :>> painId = "exit";
        attribute :>> problem = "Error delivery and receiver lifetime";
        attribute :>> sourcePath = "docs/shutdown-error-handoff.md";
        attribute :>> sourceRanges = "11-48";
        attribute :>> publicReference = "https://github.com/gambit/gambit/issues/792";
        attribute :>> evidenceBoundary = "Historical reported crash; current source correspondence and native composition remain separate";
        attribute :>> structuralCoupling = "An asynchronous outcome can outlive the catcher or execution context selected to receive it";
        attribute :>> repairLimit = "A NULL guard alone can suppress a crash while losing an admitted outcome";
        attribute :>> replacement = "Explicit admission, retained outcome owner, drain and late-result disposition before receiver reclamation";
        attribute :>> retirement = "Remove implicit live-catcher assumption only after every legal sender and unwind path has a disposition";
        attribute :>> responsibleModule = "architecture/runtime/execution";
        attribute :>> benefitMeasures = "Lost outcomes; retained descriptors; completion latency";
        attribute :>> newCosts = "Retention and handoff synchronization; no zero-cost claim";
    }
    part workPressure : RefactoringPressure {
        attribute :>> painId = "work";
        attribute :>> problem = "GC work owner versus processor lifetime";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "277-318";
        attribute :>> publicReference = "";
        attribute :>> evidenceBoundary = "Current source aliases collector queues, cursors and RC lists through PSTATE";
        attribute :>> structuralCoupling = "Execution identity, collector storage, work custody and participation are coupled";
        attribute :>> repairLimit = "A per-site barrier or queue patch need not define last producers and post-exit consumers";
        attribute :>> replacement = "Explicit collector work context, producer closure and retained custody carrier with last-use reclamation";
        attribute :>> retirement = "Replace collector PSTATE aliases only after all roots, phase producers, resize paths and consumers are mapped";
        attribute :>> responsibleModule = "architecture/runtime/gc";
        attribute :>> benefitMeasures = "Barrier wait; orphan work; retained bytes; synchronization per collection";
        attribute :>> newCosts = "Additional descriptors and transfer traffic; independent workers remain unqualified";
    }
    part copyPressure : RefactoringPressure {
        attribute :>> painId = "copy";
        attribute :>> problem = "Hidden copy progress and pending scan continuation";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "3572-3625";
        attribute :>> publicReference = "";
        attribute :>> evidenceBoundary = "Current winner forwarding precedes the payload copy loop; no current migration API inferred";
        attribute :>> structuralCoupling = "Original slot, rebound Tail cell, payload progress and caller advance reside in local C control state";
        attribute :>> repairLimit = "Fixing one scan cursor does not define a complete resumable nested initializer";
        attribute :>> replacement = "Explicit phase-tagged copy subframe and parent continuation; preserve reservation before execution";
        attribute :>> retirement = "Retire implicit local-state recovery only after exact progress, publication, rejection and unknown-outcome adapters qualify";
        attribute :>> responsibleModule = "architecture/runtime/interfaces";
        attribute :>> benefitMeasures = "Lost or duplicate scan work; redundant copies; descriptor bytes; resume overhead";
        attribute :>> newCosts = "Frame materialization and custody accounting; no requirement to materialize at every word";
    }
    part ffiPressure : RefactoringPressure {
        attribute :>> painId = "ffi";
        attribute :>> problem = "Foreign entry roots and callback ownership";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> sourceRanges = "6511-6547";
        attribute :>> publicReference = "https://github.com/gambit/gambit/pull/1010";
        attribute :>> evidenceBoundary = "Current pinned source includes a TODO about proc_or_false across marker allocation; reachability requires callers";
        attribute :>> structuralCoupling = "Marker creation can allocate before its incoming Scheme value is independently protected";
        attribute :>> repairLimit = "A marker-site repair does not enumerate all callback roots, nested entries or VM binding restoration";
        attribute :>> replacement = "Generated root-safe entry plans with explicit owner, borrowed slots, block participation and acquired-effect cleanup";
        attribute :>> retirement = "Retire handwritten per-entry root choreography only after complete caller and exceptional-exit coverage";
        attribute :>> responsibleModule = "architecture/runtime/ffi";
        attribute :>> benefitMeasures = "Uncovered entry writers; root publications; callback entry and blocked-GC costs";
        attribute :>> newCosts = "Root slots, entry guards and revalidation; C still needs a moving-GC protocol";
    }
    part releasePressure : RefactoringPressure {
        attribute :>> painId = "release";
        attribute :>> problem = "Foreign cleanup effects and resource lifetime";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceRanges = "4387-4453";
        attribute :>> publicReference = "";
        attribute :>> evidenceBoundary = "Current collector calls foreign release before freeing still objects; no current error-policy violation inferred";
        attribute :>> structuralCoupling = "Arbitrary external effects, collector progress and native resource lifetime meet inside cleanup";
        attribute :>> repairLimit = "An at-most-once release guard alone does not specify thread affinity, blocking or derived tasks";
        attribute :>> replacement = "Effect-classified release service, explicit wait context and shutdown accounting for accepted descendants";
        attribute :>> retirement = "Retire inline cleanup only for declared resource classes after payload roots, task acceptance and final drain close";
        attribute :>> responsibleModule = "architecture/runtime/ffi";
        attribute :>> benefitMeasures = "Collector blocking; queued and in-flight releases; shutdown backlog; retained bytes";
        attribute :>> newCosts = "Queues and longer resource retention; ineligible finalizers must retain another explicit route";
    }
    part framesPressure : RefactoringPressure {
        attribute :>> painId = "frames";
        attribute :>> problem = "Cached frame state across GC-capable boundaries";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceRanges = "4505-4524";
        attribute :>> publicReference = "https://github.com/gambit/gambit/pull/783#issuecomment-1265436976";
        attribute :>> evidenceBoundary = "Current source already orders RA store, W_ALL, call, R_ALL and RA reload; historical fix is not missing here";
        attribute :>> structuralCoupling = "Compiler cache, physical frame, collector relocation and return interpretation must agree";
        attribute :>> repairLimit = "Reapplying the existing wrapper cannot prove all generated hosts or continuations safe";
        attribute :>> replacement = "One Scheme-owned FrameSpec and checkpoint contract generates C root writeback, reload and unwind metadata";
        attribute :>> retirement = "Retire duplicate frame decisions after every generator/runtime consumer shares schema and preserves supported continuations";
        attribute :>> responsibleModule = "architecture/compiler";
        attribute :>> benefitMeasures = "Duplicated semantic decisions; metadata mismatch; safepoint spill/reload and continuation costs";
        attribute :>> newCosts = "Metadata and spills; Gambit control semantics must be retained rather than copied from OCaml";
    }
    part profilePressure : RefactoringPressure {
        attribute :>> painId = "profile";
        attribute :>> problem = "Requested SMP versus effective native capability";
        attribute :>> sourcePath = "vendor/gambit/configure.ac";
        attribute :>> sourceRanges = "1252-1320;2230-2262";
        attribute :>> publicReference = "";
        attribute :>> evidenceBoundary = "Separate VM, same-VM threads and scheduler switches; missing thread backend can force single-thread configuration";
        attribute :>> structuralCoupling = "Requested options, effective headers, linked RTS and runtime population can diverge";
        attribute :>> repairLimit = "A successful build or make -j does not prove shared-VM multicore capability";
        attribute :>> replacement = "Typed effective profile and ABI-bound artifact graph, audited target projections and one shared CPU budget";
        attribute :>> retirement = "Retire string-only capability inference after configured-header, object, link and runtime witness coverage";
        attribute :>> responsibleModule = "architecture/toolchain";
        attribute :>> benefitMeasures = "Mismatched artifacts; regenerated bytes; compile jobs; CPU oversubscription; actual runtime processors";
        attribute :>> newCosts = "Variant keys and stronger invalidation; avoid invalidating semantic plans on irrelevant compiler changes";
    }
    part generationPressure : RefactoringPressure {
        attribute :>> painId = "generation";
        attribute :>> problem = "Scheme to generated C and linked runtime coherence";
        attribute :>> sourcePath = "docs/pr988-complete-source-audit.md";
        attribute :>> sourceRanges = "20-64";
        attribute :>> publicReference = "https://github.com/gambit/gambit/pull/988";
        attribute :>> evidenceBoundary = "Historical closed unmerged PR with retracted body; source inventory is useful, its success claims are not acceptance";
        attribute :>> structuralCoupling = "Scheme source, generated type/label identities, archive and executable are one affected dependency closure";
        attribute :>> repairLimit = "A reported interpreter or selected stress pass need not use the same runtime as compiled code";
        attribute :>> replacement = "Single semantic plan, generated declarations and manifests; bind the affected generated/header/link closure";
        attribute :>> retirement = "Retire manually synchronized emission/layout decisions after all consumers regenerate and reject stale closure";
        attribute :>> responsibleModule = "architecture/compiler";
        attribute :>> benefitMeasures = "Semantic owners per decision; stale links admitted; generation and C compilation work";
        attribute :>> newCosts = "Generator and schema maintenance; a new wrapper without owner retirement adds cost";
    }

    part def StructuralReplacement {
        attribute sourceConflictIdentified : Boolean;
        attribute replacementInvariantExplicit : Boolean;
        attribute allLegalConsumersMapped : Boolean;
        attribute oldOwnerRetired : Boolean;
        attribute cCapabilityPreserved : Boolean;
        attribute runtimeQualified : Boolean;
        attribute benefitQualified : Boolean;
        attribute replacementAccepted : Boolean;
    }
    requirement def StructuralReplacementLaw {
        subject change : StructuralReplacement;
        require constraint { not change.replacementAccepted or
            (change.sourceConflictIdentified and change.replacementInvariantExplicit and
             change.allLegalConsumersMapped and change.oldOwnerRetired and
             change.cCapabilityPreserved and change.runtimeQualified and change.benefitQualified) }
    }

    /* Blueprint metadata: design only; no satisfied or implemented contract. */
    part def MigrationStage {
        attribute stageId : String;
        attribute dependsOn : String;
        attribute deliverable : String;
        attribute gate : String;
        attribute ownerPath : String;
        attribute retirement : String;
    }
    part def BenefitCase {
        attribute painId : String;
        attribute stageIds : String;
        attribute removedWork : String;
        attribute addedCost : String;
        attribute positiveCondition : String;
        attribute refutation : String;
        attribute obligationIds : String;
    }
    part migration0 : MigrationStage {
        attribute :>> stageId = "sourceCut";
        attribute :>> dependsOn = "";
        attribute :>> deliverable = "Bind source, capability, writer/consumer and failure inventories";
        attribute :>> gate = "No native count reset; every legal boundary named";
        attribute :>> ownerPath = "dev/refactoring";
        attribute :>> retirement = "none: evidence is preserved, not retired";
    }
    part migration1 : MigrationStage {
        attribute :>> stageId = "schema";
        attribute :>> dependsOn = "sourceCut";
        attribute :>> deliverable = "Scheme semantic completion and generated frame/root/entry schema";
        attribute :>> gate = "All consumers and relevant target projection mapped";
        attribute :>> ownerPath = "dev/architecture/compiler";
        attribute :>> retirement = "Duplicated semantic decisions only after generated/native consumer parity";
    }
    part migration2 : MigrationStage {
        attribute :>> stageId = "buildGraph";
        attribute :>> dependsOn = "sourceCut";
        attribute :>> deliverable = "Semantic dependency graph, memoized planning, action cut and shared budget";
        attribute :>> gate = "Correct semantic units, dynamic dependencies and bootstrap compiler lineage explicit";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> retirement = "Coarse string-only invalidation and uncoordinated nested schedulers after equivalent graph qualification";
    }
    part migration3 : MigrationStage {
        attribute :>> stageId = "entryPark";
        attribute :>> dependsOn = "schema";
        attribute :>> deliverable = "Root-safe host entry, callback origin, park/reload and acquired-effect plans";
        attribute :>> gate = "Marker inputs protected before allocation; every nested and exceptional exit accounted";
        attribute :>> ownerPath = "dev/architecture/runtime/ffi";
        attribute :>> retirement = "Handwritten root/entry choreography for fully covered callers";
    }
    part migration4 : MigrationStage {
        attribute :>> stageId = "workCore";
        attribute :>> dependsOn = "schema; entryPark";
        attribute :>> deliverable = "Collector work context, producer close and parent/Tail handoff";
        attribute :>> gate = "Complete phase/resize/root census and transfer failure custody";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> retirement = "PSTATE-owned collector aliases only after all task and scan consumers migrate";
    }
    part migration5 : MigrationStage {
        attribute :>> stageId = "generation";
        attribute :>> dependsOn = "workCore; schema";
        attribute :>> deliverable = "Nursery/promotion, barriers and mature continuation scan policy";
        attribute :>> gate = "Every managed/FFI mutation covered or assigned a sound explicit fallback; promotion capacity reserved";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> retirement = "Repeated mature scans only for admitted writer-complete classes; full scan remains an explicit capability route";
    }
    part migration6 : MigrationStage {
        attribute :>> stageId = "releaseDrain";
        attribute :>> dependsOn = "workCore; entryPark";
        attribute :>> deliverable = "Resource classes, release acceptance, WaitContext and descendant drain";
        attribute :>> gate = "Payload remains rooted; owner thread and failure/result policies closed";
        attribute :>> ownerPath = "dev/architecture/runtime/ffi";
        attribute :>> retirement = "Inline GC release only for eligible resource classes; arbitrary existing C callbacks retain explicit supported handling";
    }
    part migration7 : MigrationStage {
        attribute :>> stageId = "exitLifecycle";
        attribute :>> dependsOn = "releaseDrain; workCore; entryPark";
        attribute :>> deliverable = "Outcome owner, participant removal, OS-user drain and final reclamation";
        attribute :>> gate = "Late errors/callbacks and unknown transfers retain one legal custodian";
        attribute :>> ownerPath = "dev/architecture/runtime/execution";
        attribute :>> retirement = "Implicit catcher/context/container lifetime only after last-user and error-disposition coverage";
    }
    part migration8 : MigrationStage {
        attribute :>> stageId = "nativeClosure";
        attribute :>> dependsOn = "buildGraph; schema; generation; exitLifecycle";
        attribute :>> deliverable = "Build one selected modern-C runtime with exact semantic/native ABI closure";
        attribute :>> gate = "Affected source/generated/header/object/link dependency closure complete";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> retirement = "Stale generated/archive/link routes after all actual callers use the manifest boundary";
    }
    part migration9 : MigrationStage {
        attribute :>> stageId = "qualification";
        attribute :>> dependsOn = "nativeClosure";
        attribute :>> deliverable = "Separate semantic, native stability, weak-memory and cost qualification";
        attribute :>> gate = "Same workload/capability/source controls; failures retained; no global-lock or single-processor substitute";
        attribute :>> ownerPath = "dev/research";
        attribute :>> retirement = "No retirement follows from documentation, structural models or finite safety alone";
    }
    part migration10 : MigrationStage {
        attribute :>> stageId = "retirement";
        attribute :>> dependsOn = "qualification";
        attribute :>> deliverable = "Remove each named old semantic or mechanism owner";
        attribute :>> gate = "Per-route consumer coverage plus correctness and benefit receipts; preserve C-facing capability";
        attribute :>> ownerPath = "dev/refactoring/modern-c";
        attribute :>> retirement = "Exactly the named migrated paths; no default permanent duplicate runtime";
    }
    part benefit0 : BenefitCase {
        attribute :>> painId = "exit";
        attribute :>> stageIds = "exitLifecycle";
        attribute :>> removedWork = "Duplicated admission/result-disposition decisions across error, join and cleanup paths; runtime work savings not yet established";
        attribute :>> addedCost = "Independent result/carrier, admission and last-use synchronization";
        attribute :>> positiveCondition = "Lost admitted outcomes = 0; duplicate final release = 0; retained descriptors and exit latency bounded by declared users";
        attribute :>> refutation = "If retained users never finish or memory grows without bound, safety alone does not establish positive benefit";
        attribute :>> obligationIds = "BF-EXIT";
    }
    part benefit1 : BenefitCase {
        attribute :>> painId = "work";
        attribute :>> stageIds = "workCore";
        attribute :>> removedWork = "Separate implicit phase/exit custody interpretations replaced by one explicit work census; wait/scan savings remain conditional";
        attribute :>> addedCost = "Context descriptors, census/epoch checks, handoff and accounting";
        attribute :>> positiveCondition = "Accounted tasks = accepted outstanding work; compare rendezvous wait plus handoff cost under equal work";
        attribute :>> refutation = "Added handoff/cache traffic may outweigh imbalance savings; forced single-processor execution is not a gain";
        attribute :>> obligationIds = "BF-WORK";
    }
    part benefit2 : BenefitCase {
        attribute :>> painId = "copy";
        attribute :>> stageIds = "workCore";
        attribute :>> removedWork = "Lost-progress rescans and duplicated Tail/child dispatch in a proposed worker split";
        attribute :>> addedCost = "Materialized subframes at admitted cuts, task IDs and retained source/destination regions";
        attribute :>> positiveCondition = "One canonical initializer and one execution per owned Tail; measure descriptor bytes and stores per copied live word";
        attribute :>> refutation = "Do not count a hypothetical migration defect as existing baseline overhead; per-word materialization may be unjustified";
        attribute :>> obligationIds = "BF-WORK";
    }
    part benefit3 : BenefitCase {
        attribute :>> painId = "ffi";
        attribute :>> stageIds = "entryPark";
        attribute :>> removedWork = "Duplicated callback root protection, owner restore and cleanup plans";
        attribute :>> addedCost = "Root slots, grants, publication/reload, nested-entry checks";
        attribute :>> positiveCondition = "All legal entry roots protected before allocating; enumerate publications and entry/park overhead";
        attribute :>> refutation = "Raw untracked mutation or callback escape prevents fast-path admission; slower sound handling remains necessary";
        attribute :>> obligationIds = "BF-PARTICIPATION";
    }
    part benefit4 : BenefitCase {
        attribute :>> painId = "release";
        attribute :>> stageIds = "releaseDrain";
        attribute :>> removedWork = "Repeated inline blocking and ad hoc shutdown rescans across resource producers";
        attribute :>> addedCost = "Release queues, WaitContext synchronization, rooted payload retention and descendant counts";
        attribute :>> positiveCondition = "Accepted = queued + running + completed/disposed; compare GC pause reduction against queue/retention costs";
        attribute :>> refutation = "Moving work later does not remove total release work; external thread affinity or unbounded blocking can defeat gain";
        attribute :>> obligationIds = "BF-RELEASE";
    }
    part benefit5 : BenefitCase {
        attribute :>> painId = "frames";
        attribute :>> stageIds = "schema";
        attribute :>> removedWork = "Duplicated frame/root/return-label decisions and unnecessary mature continuation traversal";
        attribute :>> addedCost = "Generated metadata, safepoint spill/reload and barrier/remembered scans";
        attribute :>> positiveCondition = "One semantic owner per decision; avoided mature visits exceed writes/logs/revisits/promotion costs";
        attribute :>> refutation = "Opaque mutation or incomplete origins forbids skipping graph scan; one-shot restriction is not equivalent Gambit support";
        attribute :>> obligationIds = "BF-SCHEMA; BF-GENERATION";
    }
    part benefit6 : BenefitCase {
        attribute :>> painId = "profile";
        attribute :>> stageIds = "buildGraph";
        attribute :>> removedWork = "Repeated full planning and over-broad rebuilds; nested CPU oversubscription";
        attribute :>> addedCost = "Input hashing, memo invalidation, dependency records and shared CPU/memory tokens";
        attribute :>> positiveCondition = "No-op eligible native actions = 0; active token demand <= host grant; exact affected graph for each declared delta";
        attribute :>> refutation = "Hash/planner cost can dominate small builds; keys excluding real inputs are invalid speedups";
        attribute :>> obligationIds = "BF-BUILD-CUT; BF-BUILD-BUDGET";
    }
    part benefit7 : BenefitCase {
        attribute :>> painId = "generation";
        attribute :>> stageIds = "schema; buildGraph";
        attribute :>> removedWork = "Redundant Scheme-to-C generation, unchanged downstream C compilation and manual linkage synchronization";
        attribute :>> addedCost = "Plan/action manifest and output digests; ABI/schema invalidation; staging publication";
        attribute :>> positiveCondition = "Identical valid output cuts off descendants; relink ordered closure only when its inputs change";
        attribute :>> refutation = "Bootstrap stages using different compilers or dynamic semantic effects cannot share merely by source filename";
        attribute :>> obligationIds = "BF-SCHEMA; BF-BUILD-CUT";
    }
}
