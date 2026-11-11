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
}
