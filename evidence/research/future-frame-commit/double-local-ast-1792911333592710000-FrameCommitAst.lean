import Std
namespace FrameCommitAst
set_option maxRecDepth 10000
structure State where
 decision : Int
 claims : Int
 done : Int
 resultRoot : Int
 sourceRoot : Int
 destRoot : Int
 childRoot : Int
 copyReady : Int
 copyRev : Int
 viewRev : Int
 viewGen : Int
 viewLease : Int
 patchReady : Int
 patchRev : Int
 patchGen : Int
 patchLease : Int
 gate : Int
 admitted : Int
 generation : Int
 grantGen : Int
 lease : Int
 revision : Int
 sourceHeap : Int
 localGrants : Int
 remoteGrants : Int
 copyOps : Int
 validations : Int
 probes : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.decision≥(0)) ∧ (q.decision≤(3)) ∧ (q.claims≥(0)) ∧ (q.claims≤(1)) ∧ (q.done≥(0)) ∧ (q.done≤(1)) ∧ (q.resultRoot≥(0)) ∧ (q.resultRoot≤(1)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.destRoot≥(0)) ∧ (q.destRoot≤(1)) ∧ (q.childRoot≥(0)) ∧ (q.childRoot≤(1)) ∧ (q.copyReady≥(0)) ∧ (q.copyReady≤(1)) ∧ (q.copyRev≥(0)) ∧ (q.viewRev≥(0)) ∧ (q.viewGen≥(0)) ∧ (q.viewLease≥(0)) ∧ (q.patchReady≥(0)) ∧ (q.patchReady≤(1)) ∧ (q.patchRev≥(0)) ∧ (q.patchGen≥(0)) ∧ (q.patchLease≥(0)) ∧ (q.gate≥(0)) ∧ (q.gate≤(2)) ∧ (q.admitted≥(0)) ∧ (q.admitted≤(1)) ∧ (q.generation≥(0)) ∧ (q.grantGen≥(0)) ∧ (q.lease≥(0)) ∧ (q.revision≥(0)) ∧ (q.sourceHeap≥(0)) ∧ (q.sourceHeap≤(1)) ∧ (q.localGrants≥(0)) ∧ (q.localGrants≤(1)) ∧ (q.remoteGrants≥(0)) ∧ (q.remoteGrants≤(1)) ∧ (q.copyOps≥(0)) ∧ (q.validations≥(0)) ∧ (q.probes≥(0)) ∧ (q.copyOps≤(1)) ∧ ((q.copyOps=(1)) → ((q.copyReady=(1)) ∨ (q.decision=(3)))) ∧ (q.generation≥(1)) ∧ (q.viewRev≤q.revision) ∧ (q.copyRev≤q.revision) ∧ (q.patchRev≤q.revision) ∧ (q.viewGen≤q.generation) ∧ (q.patchGen≤q.generation) ∧ (q.grantGen≤q.generation) ∧ (q.viewLease≤q.lease) ∧ (q.patchLease≤q.lease) ∧ (q.childRoot=(1)) ∧ ((q.sourceRoot+q.destRoot)≥(1)) ∧ ((q.localGrants+q.remoteGrants)≤(1)) ∧ ((q.done=(1)) → (q.resultRoot=(1))) ∧ ((q.resultRoot=(1)) → (q.done=(1))) ∧ ((q.decision=(0)) → ((((((q.claims=(0)) ∧ (q.sourceRoot=(1))) ∧ (q.destRoot=(0))) ∧ (q.copyReady=(0))) ∧ (q.localGrants=(0))) ∧ (q.remoteGrants=(0)))) ∧ ((q.decision=(1)) → ((((q.claims=(1)) ∧ (q.sourceRoot=(1))) ∧ (q.localGrants=(0))) ∧ (q.remoteGrants=(0)))) ∧ ((q.decision=(2)) → (((((q.claims=(1)) ∧ (q.sourceRoot=(0))) ∧ (q.destRoot=(1))) ∧ (q.copyReady=(1))) ∧ (q.localGrants=(0)))) ∧ ((q.decision=(3)) → ((((q.sourceRoot=(1)) ∧ (q.destRoot=(0))) ∧ (q.copyReady=(0))) ∧ (q.remoteGrants=(0)))) ∧ ((q.copyReady=(1)) → (((q.destRoot=(1)) ∧ ((q.decision=(1)) ∨ (q.decision=(2)))) ∧ (q.copyRev=q.revision))) ∧ ((q.destRoot=(1)) → ((q.claims=(1)) ∧ ((q.decision=(1)) ∨ (q.decision=(2))))) ∧ ((q.localGrants=(1)) → (((q.decision=(3)) ∧ (q.done=(1))) ∧ (q.resultRoot=(1)))) ∧ ((q.remoteGrants=(1)) → (((q.decision=(2)) ∧ (q.done=(1))) ∧ (q.resultRoot=(1)))) ∧ ((q.gate≥(1)) → (q.grantGen=q.generation)) ∧ ((q.gate=(1)) → (q.lease≥(1))) ∧ ((q.patchReady=(1)) → ((q.copyReady=(1)) ∧ (q.destRoot=(1)))) ∧ ((q.copyOps=(0)) → ((q.copyReady=(0)) ∧ (q.patchReady=(0)))))
def initial : State := {decision:=(0), claims:=(0), done:=(0), resultRoot:=(0), sourceRoot:=(1), destRoot:=(0), childRoot:=(1), copyReady:=(0), copyRev:=(0), viewRev:=(0), viewGen:=(0), viewLease:=(0), patchReady:=(0), patchRev:=(0), patchGen:=(0), patchLease:=(0), gate:=(0), admitted:=(1), generation:=(1), grantGen:=(0), lease:=(0), revision:=(0), sourceHeap:=(0), localGrants:=(0), remoteGrants:=(0), copyOps:=(0), validations:=(0), probes:=(0)}
def reserveSplitGuard (q : State) : Prop := (((q.decision=(0)) ∧ (q.done=(0))) ∧ (q.admitted=(1)))
def reserveSplitNext (q : State) : State := {q with decision:=(1), claims:=(q.claims+(1))}
def childDoneGuard (q : State) : Prop := ((q.done=(0)) ∧ (q.gate≠(2)))
def childDoneNext (q : State) : State := {q with done:=(1), resultRoot:=(1)}
def closeLocalGuard (q : State) : Prop := (((q.decision=(0)) ∧ (q.done=(1))) ∧ (q.gate=(0)))
def closeLocalNext (q : State) : State := {q with decision:=(3)}
def allocateRootedCopyGuard (q : State) : Prop := ((((q.decision=(1)) ∧ (q.destRoot=(0))) ∧ (q.gate=(0))) ∧ (q.admitted=(1)))
def allocateRootedCopyNext (q : State) : State := {q with destRoot:=(1)}
def enterRuntimeGuard (q : State) : Prop := (((q.gate=(0)) ∧ (q.admitted=(1))) ∧ (q.decision≥(1)))
def enterRuntimeNext (q : State) : State := {q with gate:=(1), lease:=(q.lease+(1)), grantGen:=q.generation}
def resolveCanonicalGuard (q : State) : Prop := ((q.gate=(1)) ∧ (q.grantGen=q.generation))
def resolveCanonicalNext (q : State) : State := {q with viewRev:=q.revision, viewGen:=q.generation, viewLease:=q.lease}
def initializeCopyGuard (q : State) : Prop := (((((((((q.decision=(1)) ∧ (q.destRoot=(1))) ∧ (q.copyReady=(0))) ∧ (q.sourceRoot=(1))) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def initializeCopyNext (q : State) : State := {q with copyReady:=(1), copyRev:=q.revision, copyOps:=(q.copyOps+(1)), patchReady:=(0)}
def validateCopyGuard (q : State) : Prop := (((((((((q.decision=(1)) ∧ (q.destRoot=(1))) ∧ (q.copyReady=(1))) ∧ (q.copyRev=q.revision)) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def validateCopyNext (q : State) : State := {q with validations:=(q.validations+(1)), patchReady:=(0)}
def prepareReturnGuard (q : State) : Prop := (((((((((q.decision=(1)) ∧ (q.destRoot=(1))) ∧ (q.copyReady=(1))) ∧ (q.copyRev=q.revision)) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def prepareReturnNext (q : State) : State := {q with patchReady:=(1), patchRev:=q.revision, patchGen:=q.generation, patchLease:=q.lease}
def commitSplitGuard (q : State) : Prop := (((((((((((((q.decision=(1)) ∧ (q.copyReady=(1))) ∧ (q.destRoot=(1))) ∧ (q.copyRev=q.revision)) ∧ (q.patchReady=(1))) ∧ (q.patchRev=q.revision)) ∧ (q.patchGen=q.generation)) ∧ (q.patchLease=q.lease)) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def commitSplitNext (q : State) : State := {q with decision:=(2), sourceRoot:=(0)}
def abortSplitGuard (q : State) : Prop := ((((((q.decision=(1)) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def abortSplitNext (q : State) : State := {q with decision:=(3), destRoot:=(0), copyReady:=(0), copyRev:=(0), patchReady:=(0)}
def grantLocalGuard (q : State) : Prop := True
def grantLocalNext (q : State) : State := {q with localGrants:=(q.localGrants+(1))}
def grantRemoteGuard (q : State) : Prop := ((((((((((q.decision=(2)) ∧ (q.done=(1))) ∧ (q.remoteGrants=(0))) ∧ (q.copyReady=(1))) ∧ (q.copyRev=q.revision)) ∧ (q.gate=(1))) ∧ (q.grantGen=q.generation)) ∧ (q.viewGen=q.generation)) ∧ (q.viewLease=q.lease)) ∧ (q.viewRev=q.revision))
def grantRemoteNext (q : State) : State := {q with remoteGrants:=(q.remoteGrants+(1))}
def leaveRuntimeGuard (q : State) : Prop := (q.gate=(1))
def leaveRuntimeNext (q : State) : State := {q with gate:=(0)}
def enterGcGuard (q : State) : Prop := ((q.gate=(0)) ∧ (q.admitted=(1)))
def enterGcNext (q : State) : State := {q with gate:=(2), grantGen:=q.generation}
def forwardNoCopyGuard (q : State) : Prop := ((q.gate=(2)) ∧ (q.copyReady=(0)))
def forwardNoCopyNext (q : State) : State := {q with revision:=(q.revision+(1)), sourceHeap:=(1)}
def forwardWithCopyGuard (q : State) : Prop := (((q.gate=(2)) ∧ (q.copyReady=(1))) ∧ (q.destRoot=(1)))
def forwardWithCopyNext (q : State) : State := {q with revision:=(q.revision+(1)), copyRev:=(q.revision+(1)), sourceHeap:=(1)}
def leaveGcGuard (q : State) : Prop := (q.gate=(2))
def leaveGcNext (q : State) : State := {q with gate:=(0)}
def closeDomainGuard (q : State) : Prop := (q.admitted=(1))
def closeDomainNext (q : State) : State := {q with admitted:=(0)}
def resetDomainGuard (q : State) : Prop := ((q.admitted=(0)) ∧ (q.gate=(0)))
def resetDomainNext (q : State) : State := {q with generation:=(q.generation+(1)), admitted:=(1)}
def failedProbeGuard (q : State) : Prop := (q.decision≠(0))
def failedProbeNext (q : State) : State := {q with probes:=(q.probes+(1))}
def Step (q r : State) : Prop := (reserveSplitGuard q ∧ r=reserveSplitNext q) ∨ (childDoneGuard q ∧ r=childDoneNext q) ∨ (closeLocalGuard q ∧ r=closeLocalNext q) ∨ (allocateRootedCopyGuard q ∧ r=allocateRootedCopyNext q) ∨ (enterRuntimeGuard q ∧ r=enterRuntimeNext q) ∨ (resolveCanonicalGuard q ∧ r=resolveCanonicalNext q) ∨ (initializeCopyGuard q ∧ r=initializeCopyNext q) ∨ (validateCopyGuard q ∧ r=validateCopyNext q) ∨ (prepareReturnGuard q ∧ r=prepareReturnNext q) ∨ (commitSplitGuard q ∧ r=commitSplitNext q) ∨ (abortSplitGuard q ∧ r=abortSplitNext q) ∨ (grantLocalGuard q ∧ r=grantLocalNext q) ∨ (grantRemoteGuard q ∧ r=grantRemoteNext q) ∨ (leaveRuntimeGuard q ∧ r=leaveRuntimeNext q) ∨ (enterGcGuard q ∧ r=enterGcNext q) ∨ (forwardNoCopyGuard q ∧ r=forwardNoCopyNext q) ∨ (forwardWithCopyGuard q ∧ r=forwardWithCopyNext q) ∨ (leaveGcGuard q ∧ r=leaveGcNext q) ∨ (closeDomainGuard q ∧ r=closeDomainNext q) ∨ (resetDomainGuard q ∧ r=resetDomainNext q) ∨ (failedProbeGuard q ∧ r=failedProbeNext q) ∨ r=q
end FrameCommitAst
