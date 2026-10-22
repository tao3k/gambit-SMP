#!/bin/bash
set -euo pipefail
out=dev/architecture/runtime/ffi/models/sysml/retained-rc-scan.sysml
cat > "$out" <<'EOF'
/* Modern C target. Root domains outlive execution membership. No satisfaction claim. */
package GambitRetainedRcScan {
    private import ScalarValues::*;
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-H";
        attribute :>> kind = "interleaving";
        attribute :>> premise = "Fifteen target histories plus bounded positive-step invariant sampling; no native reachability";
        attribute :>> subjectPath = "models/gambit/retained_rc_scan.qnt";
        attribute :>> subjectScope = "retained_rc_scan:Test$";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "RC-I";
        attribute :>> kind = "induction";
        attribute :>> premise = "Reader/exclusive-writer kernel step and trace preservation; full GC phase and C refinement open";
        attribute :>> subjectPath = "models/gambit/lean/RetainedRcScan.lean";
        attribute :>> subjectScope = "GambitSMP.RetainedRcScan:retainedEnrollmentCoverage;pinPreserves;preparePreserves;commitPreserves;releasePreserves;stepPreserves;tracePreserves;pinnedSnapshotStable;readerExcludesTransfer;fullPhaseClosure;committedOwnerSurvivesLostAck";
    }
    part def DomainContract {
        ref part rootComponent : GambitAssuranceRelations::ComponentModelUse;
        ref part collectorComponent : GambitAssuranceRelations::ComponentModelUse;
        attribute identity : String;
        attribute membership : String;
        attribute freeze : String;
        attribute scanSnapshot : String;
        attribute trace : String;
        attribute commit : String;
        attribute acknowledgement : String;
        attribute physicalLifetime : String;
        attribute capacity : String;
        attribute memoryOrder : String;
        attribute quarantine : String;
    }
    part protocol : DomainContract {
        ref part :>> rootComponent = GambitRuntimeAssurance::roots.component;
        ref part :>> collectorComponent = GambitRuntimeAssurance::work.component;
        attribute :>> identity = "VM/domainId/generation; layoutRevision and TransferId are separate; no slot reuse while borrowed";
        attribute :>> membership = "Publish retained root domain before executor removal; root domains do not increase barrier or scan worker count";
        attribute :>> freeze = "Final native root writers and borrowers closed with witnessed release/acquire; failed join is no stopped proof";
        attribute :>> scanSnapshot = "Pin exact domain/layout once per GC epoch; unique slot scan assignment; immutable worker cohort";
        attribute :>> trace = "Alive collector uses its own copying context and queues; retained still prepare, strong, weak and cleanup included";
        attribute :>> commit = "Allocation-free list/counter commit under exclusive layout authority after epoch pins drain; no join or GC under registry mutex";
        attribute :>> acknowledgement = "Prepared failure retains donor; committed unknown queried by TransferId; no blind splice retry";
        attribute :>> physicalLifetime = "Retain roots, native headers and backing through all consumers; joined donor cleanup only after receiver acceptance and drain";
        attribute :>> capacity = "Charge retained still live/deferred words once and active collector copies once; stale donor allocation cursors are not current live occupancy";
        attribute :>> memoryOrder = "Short registry mutex serializes pin/writer admission; release/acquire orders freeze and updated roots; source native macros unproved";
        attribute :>> quarantine = "Without freeze or valid backing evidence, close allocating/reentry ingress and refuse unsafe collection; availability loss explicit";
    }
EOF
while IFS=$'\t' read -r name id kind premise source patch projection custody; do
subject_path=models/gambit/lean/RetainedRcScan.lean
if test "$kind" = native-memory-order; then subject_path=vendor/gambit/lib/mem.c; fi
cat >> "$out" <<EOF
    part $name : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "$id";
        attribute :>> kind = "$kind";
        attribute :>> premise = "$premise";
        attribute :>> subjectPath = "$subject_path";
        attribute :>> subjectScope = "$id:actual-source-refinement";
    }
    part ${name}Route : GambitHostRootsRefinement::Route {
        ref part :>> need = $name;
        attribute :>> sourceAnchors = "$source";
        attribute :>> patchAnchors = "$patch";
        attribute :>> projection = "$projection";
        attribute :>> failureCustodian = "$custody";
        attribute :>> status = "target-adapter-specified-concrete-refinement-open";
    }
EOF
done <<'EOF'
joinResult	RC-JOIN	source-refinement	Classify raw join result and unique join owner; stop/freeze evidence independent of failed or unknown status	os_thread.c:546-572; os_base.c:1050-1076; setup.c:978	cumulative.patch:4350-4381,4489-4501,5084-5095	joinFailed/joinUnknown/joinSuccess; errno fallback is unknown, not successful termination	lifecycle owner retains join and storage obligations; no concurrent join retry
membership	RC-DOMAIN	source-refinement	Every live retained RC/still domain enrolled before executor removal; complete native writer freeze or quarantine	setup.c:546-667,1193-1200; mem.c:674-829,6813-6873	cumulative.patch:4301-4317,4424-4483; no retained-domain GC adapter	freezeWriters/retire/beginGC; domain census separate from worker cohort	root-domain registry retains roots even when execution slot leaves
tracing	RC-TRACE	source-refinement	Proxy uses active copying context and queues; retained still initialization, descendant and weak closure complete	mem.c:3410-3460,3490-3663,3969-3986,4210-4245,6678-6770,6775-6810	cumulative.patch:3443-3460; active processor scanner only	prepareStill/scanRoots/drainTrace/weakComplete; donor PSTATE cannot impersonate active collector	active collector owns produced work; domain pin retains slots and native backing
commitState	RC-COMMIT	source-refinement	Full link/counter commit excludes every epoch reader and root writer; resolve lost acknowledgement by identity	mem.c:723-829,3969-3986; setup.c:975-980	cumulative.patch:3160-3234,4350-4381,4490-4501	prepareTransfer/commitTransfer/abortPrepared/resolveCommitted; logical atomic step hides no observed partial links	donor before commit; receiver after commit; unresolved observer retains resolution debt
lifetime	RC-LIFETIME	source-refinement	Still preparation, foreign cleanup, native borrower drain and retained capacity charged exactly once before backing release	mem.c:4370-4455,4933-4960,6255-6314,6920-6937	cumulative.patch:3181-3200,3223-3234,4490-4501	cleanupAccount/finishGC/cleanupDonor; release only after root and descendant last use	domain custodian retains headers and backing; foreign release deferred if owner thread not qualified
memoryOrder	RC-MEMORY	native-memory-order	Prove source pin/writer gate, freeze and collector publication happens-before without blocking progress	mem.c:378-385,723-829,3969-3986; setup.c:546-710	cumulative.patch:3178-3223,4265-4277,4475-4499	pin/exclusive exclusion and stable snapshot; existing splice mutex is not a scan lease	coordinator retains unknown outcome; raw non-atomic list mutation requires real exclusion
EOF
idx=0
for need in history induction joinResult membership tracing commitState lifetime memoryOrder; do
cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitHostRootsRefinement::rc;
        ref part :>> prerequisite = $need;
    }
EOF
idx=$((idx+1))
done
for need in joinResult membership tracing commitState lifetime; do
 for prior in history induction memoryOrder; do
cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = $need;
        ref part :>> prerequisite = $prior;
    }
EOF
idx=$((idx+1))
 done
done
while IFS=' ' read -r dependent prerequisite; do
cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = $dependent;
        ref part :>> prerequisite = $prerequisite;
    }
EOF
idx=$((idx+1))
done <<'EOF'
memoryOrder GambitRuntimeAssurance::roots.platform
tracing membership
lifetime tracing
commitState joinResult
commitState lifetime
EOF
printf '}\n' >> "$out"
test "$idx" = 28
