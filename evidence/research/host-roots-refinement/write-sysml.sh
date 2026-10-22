#!/bin/bash
set -euo pipefail
out=dev/architecture/runtime/ffi/models/sysml/host-roots-refinement.sysml
cat > "$out" <<'EOF'
/* Modern-C target research. Native metadata is authoritative; no satisfaction asserted. */
package GambitHostRootsRefinement {
    private import ScalarValues::*;
    part def Route {
        ref part need : GambitAssuranceRouting::ModelNeed;
        attribute sourceAnchors : String;
        attribute patchAnchors : String;
        attribute projection : String;
        attribute failureCustodian : String;
        attribute status : String;
    }
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-DH";
        attribute :>> kind = "interleaving";
        attribute :>> premise = "Fourteen explicit target histories; controls are not native reachability claims";
        attribute :>> subjectPath = "models/gambit/host_roots_refinement.qnt";
        attribute :>> subjectScope = "host_roots_refinement:Test$";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "HR-DI";
        attribute :>> kind = "induction";
        attribute :>> premise = "Conditional census, reload and LIFO settlement lemmas; no C-step simulation";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "GambitSMP.HostRootsRefinement:liveRcCoverage;retainedDoesNotImplyScanned;protectedReload;reservationSurvives;enterPreserves;settlePreserves;nestedSettlement;balancedIsNotBinding;lateRootCannotRepair";
    }
EOF
while IFS=$'\t' read -r name id premise source patch projection custody; do
cat >> "$out" <<EOF
    part $name : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::roots.component;
        attribute :>> obligationId = "$id";
        attribute :>> kind = "source-refinement";
        attribute :>> premise = "$premise";
        attribute :>> subjectPath = "models/gambit/lean/HostRootsRefinement.lean";
        attribute :>> subjectScope = "$id:actual-source-refinement";
    }
    part ${name}Route : Route {
        ref part :>> need = $name;
        attribute :>> sourceAnchors = "$source";
        attribute :>> patchAnchors = "$patch";
        attribute :>> projection = "$projection";
        attribute :>> failureCustodian = "$custody";
        attribute :>> status = "selected-source-edges-known-complete-refinement-open";
    }
EOF
done <<'EOF'
rc	HR-RC	Every live RC data slot belongs to the next scan census, including retained donors; splice and scan exclude concurrent mutation	mem.c:306,674-829,3969-3986,6813-6873,4933-4960	cumulative.patch:3160-3234,3443-3460,4350-4501	register/scan/retireUnknown/transferCommitted; RC data only, not arbitrary payload bytes	donor until stopped and receiver scan ownership accepted; failed join retains scan debt
marker	HR-MARKER	Reserved scratch extent covers allocation, all exits and reload; nested saved writers cannot clobber it	c_intf.c:6511-6562; gambit.h.in:8059-8086; mem.c:6526-6538	cumulative.patch:714-768,2010-2029	reserve/allocateMoving/reload/releaseSlot; exception cleanup revokes only its own token	activation owns input root until marker initialized or allocation unwind settled
boot	HR-BOOT	A movable startup thunk is rooted before the collective preceding run, or independently proven stable	setup.c:770-840,3398-3422,6418-6430	cumulative.patch:4334; ordinary run excluded at 749	preEntryMove then reserve is too late; entry lease cannot certify prior interval	startup producer retains root through collective and consumer acceptance
exitState	HR-EXIT	Every generated wrapper and direct run exit cleans its own marker and count exactly once before rethrow	setup.c:3276-3422; gambit.h.in:10043-10059; _kernel.scm:1019-1071	cumulative.patch:524-548,714-768	enter/settleTop; matched return, conversion handler, allocation throw and unmatched rethrow distinct	current activation until its cleanup completes; outer activation retains unmatched destination
bindingState	HR-BIND	Real PSTATE, effective binding, VM and catcher restore are separately established on every admitted exit	gambit.h.in:8708-8718; os_thread.c:697; setup.c:3276-3422	cumulative.patch:714-768 does not supply a VM binding stack	priorBindings and count are independent; no-switch same-owner admission first	owner activation retains binding snapshot; foreign longjmp and cancellation outside profile rejected
dynamic	HR-DYNAMIC	Dynamic closure identity and RC lifetime survive allocation and reentry on each qualified trampoline ABI	os_dyn.c:744-795; c_intf.c:6536; examples/tcltk/tcltk.scm:125-195	cumulative.patch:2010-2029 saves false, not closure self identity	FAL dynamic lookup requires separate identity premise; Tcl still indirection is a distinct case	closure publisher and in-flight borrower retain RC identity until callback and deletion drain
EOF
idx=0
for need in history induction rc marker boot exitState bindingState dynamic; do
cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::roots.source;
        ref part :>> prerequisite = $need;
    }
EOF
idx=$((idx+1))
done
for need in rc marker boot exitState bindingState dynamic; do
 for prerequisite in history induction GambitRuntimeAssurance::roots.platform; do
cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = $need;
        ref part :>> prerequisite = $prerequisite;
    }
EOF
idx=$((idx+1))
 done
done
printf '}\n' >> "$out"
