/* Generational modernization candidate implemented in generated modern C.
 * Native SysML owns candidate policy and cross-component proof dependencies. */
package GambitGenerationalAdmission {
    private import ScalarValues::*;
    part def CollectorPolicy {
        attribute allocationPolicy : String;
        attribute minor : String;
        attribute mature : String;
        attribute stores : String;
        attribute overflow : String;
        attribute roots : String;
        attribute continuation : String;
        attribute ffi : String;
        attribute major : String;
        attribute retirement : String;
    }
    part candidate : CollectorPolicy {
        attribute :>> allocationPolicy = "Execution-context nursery allocation; VM-wide epoch and independently granted collector work contexts";
        attribute :>> minor = "Coordinated STW parallel young evacuation; direct promotion candidate; cross-context young references allowed under VM-wide cut";
        attribute :>> mature = "Nonmoving mature/pinned space candidate; existing still/permanent semantics retained explicitly, not equated with object age";
        attribute :>> stores = "Scheme generator emits InitStore/MutateStore/RootWrite/BulkWrite/CAS/Relocate semantic operations; modern C consumers own validated layout and barrier lowering";
        attribute :>> overflow = GambitGenerationalBarrier::protocol.overflow;
        attribute :>> roots = "Every active/retained domain and RC root scanned; skip clean mature interiors only with complete source-slot remembered coverage and stable scan cut";
        attribute :>> continuation = "FrameSpec root maps plus capture/mutation/denv/deserialization/restore and activation barriers; multi-shot Scheme continuation semantics retained";
        attribute :>> ffi = "RootWrite and explicit slot identities; park raw borrows, retain native storage; allocating safepoints protect/reload all handles; raw escapes rejected or conservative supported fallback";
        attribute :>> major = "Complete major strong/weak/will/finalization and reserve policy mandatory; concurrent major adds separate SATB/deletion-barrier and termination proof";
        attribute :>> retirement = "Replace implicit PSTATE root membership, unchecked stores and full-mature minor traversal only after source/ordering gates; full major and conservative fallback retained";
    }
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "GEN-H";
        attribute :>> kind = "interleaving";
        attribute :>> subjectPath = "models/gambit/generational_root_admission.qnt";
        attribute :>> subjectScope = "generational_root_admission:Test$";
        attribute :>> premise = "Nine finite target histories; four old source slots/two young nodes/one RC slot; reachability and source-slot coverage only";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "GEN-I";
        attribute :>> kind = "induction";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalRootAdmission.lean";
        attribute :>> subjectScope = "GambitSMP.GenerationalRootAdmission:youngReachabilityCovered;rememberedSlotsSelected;fallbackCoversOldSlots;minorSurvivorsRetained;residualYoungMustRemainRecorded";
        attribute :>> premise = "Arbitrary-graph young-boundary coverage and residual dirty obligations; source identity/update, weak phase and complete collector proof remain open";
    }
    part source : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "GC-GEN";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalRootAdmission.lean";
        attribute :>> subjectScope = "GC-GEN:actual-source-refinement";
        attribute :>> premise = "Complete generated and runtime writer closure, barrier nonallocation/overflow, address rewrite, capacity, continuation, weak/finalization and major/minor composition";
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
        ref part :>> prerequisite = GambitRuntimeAssurance::work.source;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = source;
        ref part :>> prerequisite = GambitRuntimeAssurance::control.source;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = source;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = source;
        ref part :>> prerequisite = GambitRetainedRcScan::membership;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = source;
        ref part :>> prerequisite = GambitRcFreezePublication::freeze;
    }
    part def ViewNode { attribute nodeId : String; attribute labelText : String; }
    part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
    part scheme : ViewNode { attribute :>> nodeId = "scheme"; attribute :>> labelText = "Scheme semantics + FrameSpec"; }
    part stores : ViewNode { attribute :>> nodeId = "stores"; attribute :>> labelText = "Generated modern C: semantic stores"; }
    part nursery : ViewNode { attribute :>> nodeId = "nursery"; attribute :>> labelText = "Context nurseries"; }
    part remembered : ViewNode { attribute :>> nodeId = "remembered"; attribute :>> labelText = "BarrierLog / dirty source slots"; }
    part domains : ViewNode { attribute :>> nodeId = "domains"; attribute :>> labelText = "RootRegistry / final-value freeze"; }
    part minor : ViewNode { attribute :>> nodeId = "minor"; attribute :>> labelText = "VM-wide parallel minor epoch"; }
    part mature : ViewNode { attribute :>> nodeId = "mature"; attribute :>> labelText = "Nonmoving mature + pinned/still policies"; }
    part major : ViewNode { attribute :>> nodeId = "major"; attribute :>> labelText = "Complete major / weak / wills"; }
    part release : ViewNode { attribute :>> nodeId = "release"; attribute :>> labelText = "ReleaseCoordinator: native custody"; }
    part ffi : ViewNode { attribute :>> nodeId = "ffi"; attribute :>> labelText = "Native callback storage lease / parked raw borrow"; }
    part edge0 : ViewEdge { ref part :>> producer = scheme; ref part :>> consumer = stores; attribute :>> labelText = "generated contract"; }
    part edge1 : ViewEdge { ref part :>> producer = stores; ref part :>> consumer = nursery; attribute :>> labelText = "InitStore before publication"; }
    part edge2 : ViewEdge { ref part :>> producer = stores; ref part :>> consumer = remembered; attribute :>> labelText = "MutateStore / Bulk / CAS"; }
    part edge3 : ViewEdge { ref part :>> producer = ffi; ref part :>> consumer = domains; attribute :>> labelText = "RootWrite / park / reload"; }
    part edge4 : ViewEdge { ref part :>> producer = remembered; ref part :>> consumer = minor; attribute :>> labelText = "sealed dirty set or fallback"; }
    part edge5 : ViewEdge { ref part :>> producer = domains; ref part :>> consumer = minor; attribute :>> labelText = "published slot inventory"; }
    part edge6 : ViewEdge { ref part :>> producer = nursery; ref part :>> consumer = minor; attribute :>> labelText = "young closure"; }
    part edge7 : ViewEdge { ref part :>> producer = minor; ref part :>> consumer = mature; attribute :>> labelText = "promote and rewrite all source slots"; }
    part edge8 : ViewEdge { ref part :>> producer = mature; ref part :>> consumer = major; attribute :>> labelText = "less frequent full tracing"; }
    part edge9 : ViewEdge { ref part :>> producer = major; ref part :>> consumer = release; attribute :>> labelText = "preaccepted native-only custody"; }
    part edge10 : ViewEdge { ref part :>> producer = release; ref part :>> consumer = ffi; attribute :>> labelText = "owner drain after pins released"; }
    part edge11 : ViewEdge { ref part :>> producer = minor; ref part :>> consumer = domains; attribute :>> labelText = "collector relocation / epoch release"; }
    part sourceRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = source;
        attribute :>> sourceAnchors = "mem.c:3410-3469,3490-3665,3969-3986,6678-6770; gambit.h.in:5482-5485; _kernel.scm:3154-3162,3439-3550; _t-c-2.scm:3356-3365";
        attribute :>> patchAnchors = "cumulative.patch:3443-3460; existing root repair is not a generational barrier";
        attribute :>> projection = candidate.roots;
        attribute :>> failureCustodian = "VM/root/collector custodian retains all regions, source slots and unfinished promotion debt";
        attribute :>> status = "candidate-only-current-source-is-full-copying";
    }
}
