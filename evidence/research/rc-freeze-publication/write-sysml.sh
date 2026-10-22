#!/bin/bash
set -euo pipefail
out=dev/architecture/runtime/ffi/models/sysml/rc-freeze-publication.sysml
cat > "$out" <<'EOF'
/* Modern C target contract; baseline source closure remains open. */
package GambitRcFreezePublication {
    private import ScalarValues::*;
    part def FreezeContract {
        attribute identity : String;
        attribute preparation : String;
        attribute close : String;
        attribute receipt : String;
        attribute publication : String;
        attribute mutation : String;
        attribute collector : String;
        attribute deletion : String;
        attribute cleanup : String;
        attribute unknown : String;
    }
    part protocol : FreezeContract {
        attribute :>> identity = "VM/domain/generation/layoutRevision/rootEpoch and writer-inventory digest; storage lease differs from raw-value borrow";
        attribute :>> preparation = "Initialize all root slots and reserve native-only release custody before pin admission; incomplete preparation retains source custody";
        attribute :>> close = "Close mutator ingress, park raw Scheme borrows, finish admitted root writes; storage leases may remain";
        attribute :>> receipt = "Known final writer inventory; writers zero, raw borrows parked; initialized enrolled domain and exact generation/layout; no unknown raw escape";
        attribute :>> publication = "Final slot stores release before scanner acquire; domain enrollment before executor removal and scan snapshot seal; pin excludes unlink and layout transfer";
        attribute :>> mutation = "Mutator RootWrite permit and generational dirty publication; no hidden GC from bounded barrier; revoke receipt on reentry or identity change";
        attribute :>> collector = "Collector relocation authority writes enrolled slots while mutator ingress is closed; post-GC acquire/reload before raw use";
        attribute :>> deletion = "Request close without waiting for own callback; exact nested tokens settle before physical release; exception/nonlocal exit needs acknowledged cleanup";
        attribute :>> cleanup = "Preclassified native-only task custody accepted before wrapper clear/free; collector never waits for a task awaiting its epoch pin";
        attribute :>> unknown = "Retain root/header/backing and unresolved delivery debt; quarantine allocating reentry without freeze; no receipt from failed/unknown join alone";
    }
    part def CensusRoute {
        attribute routeId : String;
        attribute sourceAnchors : String;
        attribute authority : String;
        attribute obligation : String;
        attribute boundary : String;
    }
EOF
need() {
 local name=$1 id=$2 kind=$3 subject=$4 scope=$5 premise=$6
 cat >> "$out" <<EOF
    part $name : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "$id";
        attribute :>> kind = "$kind";
        attribute :>> subjectPath = "$subject";
        attribute :>> subjectScope = "$scope";
        attribute :>> premise = "$premise";
    }
EOF
}
need history FZ-H interleaving models/gambit/rc_freeze_publication.qnt 'rc_freeze_publication:Test$' 'Thirteen finite target histories; storage/raw separation, publication and modeled wait omissions; not native reachability'
need induction FZ-I induction models/gambit/lean/RcFreezePublication.lean 'GambitSMP.RcFreezePublication:issueRequiresFinalValues;issueBindsGeneration;storageLeaseDoesNotBlockFreeze;publicationPrecedesReceipt;collectorCanUpdateFrozenRoots;waitPathIncreases;noRankedWaitCycle' 'Conditional issuance and arbitrary finite ranked wait paths; no source wait-graph completeness proof'
need census FZ-CENSUS source-refinement models/gambit/lean/RcFreezePublication.lean 'FZ-CENSUS:actual-source-refinement' 'All native root writers, generated conversion exits, borrowed aliases and external escapes mediated or profile rejected'
need freeze FZ-FREEZE source-refinement models/gambit/lean/RcFreezePublication.lean 'FZ-FREEZE:actual-source-refinement' 'Final-value park, root-slot inventory and identity-bound receipt; no waiting for callback storage lifetime to end'
need publication FZ-PUBLISH source-refinement models/gambit/lean/RcFreezePublication.lean 'FZ-PUBLISH:actual-source-refinement' 'Root domain initialization/enrollment precedes executor removal and scan cut; collector writes remain authorized'
need callback FZ-CALLBACK source-refinement models/gambit/lean/RcFreezePublication.lean 'FZ-CALLBACK:actual-source-refinement' 'Creation failure, nested callback/delete, marker protection, reload and all exceptional exits settle exact custody'
need cleanup FZ-CLEANUP source-refinement models/gambit/lean/RcFreezePublication.lean 'FZ-CLEANUP:actual-source-refinement' 'Manual release versus GC cleanup policies; preaccepted native-only deferred custody and full last-user drain; no pin wait cycle'
need memoryOrder FZ-MEMORY native-memory-order vendor/gambit/lib/mem.c 'FZ-MEMORY:actual-source-refinement' 'C release/acquire, scan/update/unlink exclusion, lock order and all external/native wait paths remain unrefined'
idx=0
dep() {
 cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = $1;
        ref part :>> prerequisite = $2;
    }
EOF
 idx=$((idx+1))
}
for n in history induction census freeze publication callback cleanup memoryOrder; do dep GambitRetainedRcScan::membership "$n"; done
for n in census freeze publication callback cleanup; do
 for p in history induction memoryOrder; do dep "$n" "$p"; done
done
dep GambitRetainedRcScan::lifetime cleanup
dep GambitRetainedRcScan::lifetime callback
dep GambitRetainedRcScan::commitState publication
dep GambitHostRootsRefinement::dynamic callback
dep GambitHostRootsRefinement::dynamic census
dep memoryOrder GambitRetainedRcScan::memoryOrder
route() {
 cat >> "$out" <<EOF
    part $1 : CensusRoute {
        attribute :>> routeId = "$2";
        attribute :>> sourceAnchors = "$3";
        attribute :>> authority = "$4";
        attribute :>> obligation = "$5";
        attribute :>> boundary = "$6";
    }
EOF
}
route primitive RC-API 'mem.c:674-829,3969-3986; gambit.h.in:11309-11315,11413' 'Mutator list/data writes; collector relocation; raw header aliases' 'FZ-CENSUS' '116 lexical occurrences in 9 files is not external-C caller closure'
route converter CONVERSION 'c_intf.c:1633-1809,2887-2940,3233-3613; gambit.h.in:9838-9894,10476-10522' 'Function/string/list lifetime; generated normal-exit cleanup; count and payload readers' 'FZ-CENSUS' 'refcount==1 is not concurrent exclusion; nonlocal exits and foreign-held aliases need contracts'
route dynamic DYNAMIC 'os_dyn.c:744-795,1045-1053; c_intf.c:6511-6562' 'Native function pointer invocation and RC data read; marker may allocate' 'FZ-CALLBACK' 'Global c_closure_self and unqualified external release remain source obligations'
route tcl TCL 'examples/tcltk/tcltk.scm:90-97,125-195,217-227,288-342' 'Callback, delete callback, retained Tcl result buffer and creation setup' 'FZ-CALLBACK' 'Tcl command lifetime does not prove ClientData ownership; failure and nonlocal exits unresolved'
route release FOREIGN 'c_intf.c:1683-1710,5287-5381; mem.c:4387-4455; _kernel.scm:3884-3894' 'Manual result-bearing release; conversion-error release; GC ignores destructor error then frees wrapper' 'FZ-CLEANUP' 'Existing release_fn return cannot acknowledge deferred custody after wrapper clear/free'
route resources RESOURCE 'os_io.c:3948-3971,4199-4558,7099-7143; os_files.c:1189; examples/Xlib-simple/Xlib.scm:68-104,332,381,739' 'TLS/event/native payload cleanup and creation-error paths' 'FZ-CLEANUP' 'Platform branches are inventory only; SSL/Tcl/Xlib effects and owner thread not qualified'
route exports EXPORT 'setup.c:5900-5922; gambit.h.in:13232-13255,14575-14598' 'Public function tables and imports expose all RC primitives' 'FZ-CENSUS' 'Unmediated external C or pointer writes reject freeze issuance'
echo '}' >> "$out"
out=dev/architecture/runtime/gc/models/sysml/generational-admission.sysml
cat > "$out" <<'EOF'
/* Generational modernization candidate implemented in generated modern C.
 * Native SysML owns candidate policy and cross-component proof dependencies. */
package GambitGenerationalAdmission {
    private import ScalarValues::*;
    part def CollectorPolicy {
        attribute allocation : String;
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
        attribute :>> allocation = "Execution-context nursery allocation; VM-wide epoch and independently granted collector work contexts";
        attribute :>> minor = "Coordinated STW parallel young evacuation; direct promotion candidate; cross-context young references allowed under VM-wide cut";
        attribute :>> mature = "Nonmoving mature/pinned space candidate; existing still/permanent semantics retained explicitly, not equated with object age";
        attribute :>> stores = "Scheme generator emits InitStore/MutateStore/RootWrite/BulkWrite/CAS/Relocate semantic operations; modern C consumers own validated layout and barrier lowering";
        attribute :>> overflow = "Preallocated card coverage or bounded log; before any uncovered store publish conservative full-mature-scan fallback; no implicit GC from store";
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
EOF
idx=0
for p in history induction GambitRuntimeAssurance::work.source GambitRuntimeAssurance::control.source GambitRuntimeAssurance::roots.source GambitRetainedRcScan::membership GambitRcFreezePublication::freeze; do dep source "$p"; done
# Typed view records are owned here; jq only serializes them into D2.
cat >> "$out" <<'EOF'
    part def ViewNode { attribute nodeId : String; attribute labelText : String; }
    part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
EOF
node() { cat >> "$out" <<EOF
    part $1 : ViewNode { attribute :>> nodeId = "$1"; attribute :>> labelText = "$2"; }
EOF
}
edge() { cat >> "$out" <<EOF
    part edge$1 : ViewEdge { ref part :>> producer = $2; ref part :>> consumer = $3; attribute :>> labelText = "$4"; }
EOF
}
node scheme 'Scheme semantics + FrameSpec'
node stores 'Generated modern C: semantic stores'
node nursery 'Context nurseries'
node remembered 'BarrierLog / dirty source slots'
node domains 'RootRegistry / final-value freeze'
node minor 'VM-wide parallel minor epoch'
node mature 'Nonmoving mature + pinned/still policies'
node major 'Complete major / weak / wills'
node release 'ReleaseCoordinator: native custody'
node ffi 'Native callback storage lease / parked raw borrow'
edge 0 scheme stores 'generated contract'
edge 1 stores nursery 'InitStore before publication'
edge 2 stores remembered 'MutateStore / Bulk / CAS'
edge 3 ffi domains 'RootWrite / park / reload'
edge 4 remembered minor 'sealed dirty set or fallback'
edge 5 domains minor 'published slot inventory'
edge 6 nursery minor 'young closure'
edge 7 minor mature 'promote and rewrite all source slots'
edge 8 mature major 'less frequent full tracing'
edge 9 major release 'preaccepted native-only custody'
edge 10 release ffi 'owner drain after pins released'
edge 11 minor domains 'collector relocation / epoch release'
echo '}' >> "$out"
