import Std
namespace LazySplitAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 eligible : Int
 claims : Int
 probes : Int
 childRuns : Int
 childDone : Int
 sourceRoot : Int
 copyRoot : Int
 ready : Int
 queueRoot : Int
 restoreRoot : Int
 contextRoot : Int
 resultRoot : Int
 placeholder : Int
 materialized : Int
 split : Int
 parentOwner : Int
 prefixRuns : Int
 parentRuns : Int
 captured : Int
 captureRoot : Int
 exited : Int
 descriptor : Int
 gcOpen : Int
 frozen : Int
 scanning : Int
 scanned : Int
 epoch : Int
 vSource : Int
 vCopy : Int
 vQueue : Int
 vRestore : Int
 vContext : Int
 vResult : Int
 vCapture : Int
 resultPublished : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(9)) ∧ (q.eligible≥(0)) ∧ (q.eligible≤(1)) ∧ (q.claims≥(0)) ∧ (q.claims≤(1)) ∧ (q.probes≥(0)) ∧ (q.childRuns≥(0)) ∧ (q.childRuns≤(1)) ∧ (q.childDone≥(0)) ∧ (q.childDone≤(1)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.copyRoot≥(0)) ∧ (q.copyRoot≤(1)) ∧ (q.ready≥(0)) ∧ (q.ready≤(1)) ∧ (q.queueRoot≥(0)) ∧ (q.queueRoot≤(1)) ∧ (q.restoreRoot≥(0)) ∧ (q.restoreRoot≤(1)) ∧ (q.contextRoot≥(0)) ∧ (q.contextRoot≤(1)) ∧ (q.resultRoot≥(0)) ∧ (q.resultRoot≤(1)) ∧ (q.placeholder≥(0)) ∧ (q.placeholder≤(1)) ∧ (q.materialized≥(0)) ∧ (q.materialized≤(1)) ∧ (q.split≥(0)) ∧ (q.split≤(1)) ∧ (q.parentOwner≥(0)) ∧ (q.parentOwner≤(3)) ∧ (q.prefixRuns≥(0)) ∧ (q.prefixRuns≤(1)) ∧ (q.parentRuns≥(0)) ∧ (q.captured≥(0)) ∧ (q.captured≤(1)) ∧ (q.captureRoot≥(0)) ∧ (q.captureRoot≤(1)) ∧ (q.exited≥(0)) ∧ (q.exited≤(1)) ∧ (q.descriptor≥(0)) ∧ (q.descriptor≤(1)) ∧ (q.gcOpen≥(0)) ∧ (q.gcOpen≤(1)) ∧ (q.frozen≥(0)) ∧ (q.frozen≤(1)) ∧ (q.scanning≥(0)) ∧ (q.scanning≤(1)) ∧ (q.scanned≥(0)) ∧ (q.scanned≤(1)) ∧ (q.epoch≥(0)) ∧ (q.vSource≥(0)) ∧ (q.vSource≤(1)) ∧ (q.vCopy≥(0)) ∧ (q.vCopy≤(1)) ∧ (q.vQueue≥(0)) ∧ (q.vQueue≤(1)) ∧ (q.vRestore≥(0)) ∧ (q.vRestore≤(1)) ∧ (q.vContext≥(0)) ∧ (q.vContext≤(1)) ∧ (q.vResult≥(0)) ∧ (q.vResult≤(1)) ∧ (q.vCapture≥(0)) ∧ (q.vCapture≤(1)) ∧ (q.resultPublished≥(0)) ∧ (q.resultPublished≤(1)) ∧ (q.epoch≥(1)) ∧ (q.childRuns=(1)) ∧ (((q.phase≤(3)) ∨ (q.phase=(6))) → (q.sourceRoot=(1))) ∧ (((q.phase≥(1)) ∧ (q.phase≤(5))) → ((q.claims=(1)) ∧ (q.eligible=(1)))) ∧ ((q.phase=(0)) → ((((((q.split=(0)) ∧ (q.ready=(0))) ∧ (q.copyRoot=(0))) ∧ (q.queueRoot=(0))) ∧ (q.parentOwner=(0))) ∧ (q.placeholder=(0)))) ∧ ((q.phase=(1)) → (((q.ready=(0)) ∧ (q.queueRoot=(0))) ∧ (q.split=(0)))) ∧ ((q.phase=(2)) → ((((q.copyRoot=(1)) ∧ (q.ready=(1))) ∧ (q.queueRoot=(0))) ∧ (q.split=(0)))) ∧ ((q.phase=(3)) → ((((q.copyRoot=(1)) ∧ (q.ready=(1))) ∧ (q.queueRoot=(1))) ∧ (q.split=(0)))) ∧ ((q.phase=(4)) → (((((q.copyRoot=(1)) ∧ (q.ready=(1))) ∧ (q.queueRoot=(1))) ∧ (q.split=(1))) ∧ (q.parentOwner=(1)))) ∧ ((q.phase=(5)) → ((((((q.copyRoot=(1)) ∧ (q.ready=(1))) ∧ (q.queueRoot=(0))) ∧ (q.restoreRoot=(1))) ∧ (q.split=(1))) ∧ (q.parentOwner=(2)))) ∧ ((q.phase=(6)) → ((((q.childDone=(1)) ∧ (q.resultRoot=(1))) ∧ (q.split=(0))) ∧ (q.parentOwner=(0)))) ∧ ((q.phase=(7)) → (((((((q.contextRoot=(1)) ∧ (q.copyRoot=(0))) ∧ (q.restoreRoot=(0))) ∧ (q.queueRoot=(0))) ∧ (q.split=(1))) ∧ (q.parentOwner=(3))) ∧ (q.ready=(1)))) ∧ ((q.phase<(8)) → (q.descriptor=(1))) ∧ ((q.phase≥(8)) → ((((((((((q.sourceRoot=(0)) ∧ (q.copyRoot=(0))) ∧ (q.queueRoot=(0))) ∧ (q.restoreRoot=(0))) ∧ (q.contextRoot=(0))) ∧ (q.resultRoot=(0))) ∧ (q.captureRoot=(0))) ∧ (q.captured=(0))) ∧ (q.placeholder=(0))) ∧ (q.exited=(1)))) ∧ ((q.queueRoot=(1)) → ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ ((q.copyRoot=(1)) → ((((q.placeholder=(1)) ∧ (q.materialized=(1))) ∧ (q.phase≥(1))) ∧ (q.phase≤(5)))) ∧ ((q.restoreRoot=(1)) → (q.phase=(5))) ∧ ((q.contextRoot=(1)) → (q.phase=(7))) ∧ ((q.ready=(1)) → (((q.phase≥(2)) ∧ (q.phase≤(7))) ∧ (q.phase≠(6)))) ∧ ((q.split=(1)) → (((q.phase≥(4)) ∧ (q.claims=(1))) ∧ (q.materialized=(1)))) ∧ ((q.parentOwner≥(1)) → (q.split=(1))) ∧ (((q.childDone=(1)) ∧ (q.phase<(8))) → (q.resultRoot=(1))) ∧ ((q.resultPublished=(1)) → ((q.childDone=(1)) ∧ (q.split=(1)))) ∧ ((q.parentRuns≥(1)) → (((q.phase≥(6)) ∧ (q.childDone=(1))) ∧ (q.prefixRuns=(1)))) ∧ (((q.parentRuns≥(1)) ∧ (q.split=(1))) → (q.resultPublished=(1))) ∧ ((q.captured=(1)) → ((((q.captureRoot=(1)) ∧ (q.parentRuns≥(1))) ∧ ((q.phase=(6)) ∨ (q.phase=(7)))) ∧ (q.exited=(0)))) ∧ ((q.captureRoot=(1)) → (q.captured=(1))) ∧ ((q.phase<(6)) → ((((q.parentRuns=(0)) ∧ (q.prefixRuns=(0))) ∧ (q.captured=(0))) ∧ (q.exited=(0)))) ∧ ((q.exited=(1)) → ((q.parentRuns≥(1)) ∧ (q.captured=(0)))) ∧ ((q.materialized=(1)) → (q.claims=(1))) ∧ ((q.frozen=(1)) → ((((((((q.gcOpen=(0)) ∧ (q.sourceRoot=q.vSource)) ∧ (q.copyRoot=q.vCopy)) ∧ (q.queueRoot=q.vQueue)) ∧ (q.restoreRoot=q.vRestore)) ∧ (q.contextRoot=q.vContext)) ∧ (q.resultRoot=q.vResult)) ∧ (q.captureRoot=q.vCapture))) ∧ ((q.scanning=(1)) → ((q.frozen=(1)) ∧ (q.scanned=(0)))) ∧ ((q.scanned=(1)) → ((q.frozen=(1)) ∧ (q.scanning=(0)))))
def initial : State := {phase:=(0), eligible:=(1), claims:=(0), probes:=(0), childRuns:=(1), childDone:=(0), sourceRoot:=(1), copyRoot:=(0), ready:=(0), queueRoot:=(0), restoreRoot:=(0), contextRoot:=(0), resultRoot:=(0), placeholder:=(0), materialized:=(0), split:=(0), parentOwner:=(0), prefixRuns:=(0), parentRuns:=(0), captured:=(0), captureRoot:=(0), exited:=(0), descriptor:=(1), gcOpen:=(1), frozen:=(0), scanning:=(0), scanned:=(0), epoch:=(1), vSource:=(0), vCopy:=(0), vQueue:=(0), vRestore:=(0), vContext:=(0), vResult:=(0), vCapture:=(0), resultPublished:=(0)}
def denyParallelProfileGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.claims=(0)))
def denyParallelProfileNext (q : State) : State := {q with eligible:=(0)}
def claimSplitGuard (q : State) : Prop := ((((((q.phase=(0)) ∧ (q.eligible=(1))) ∧ (q.claims=(0))) ∧ (q.childDone=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def claimSplitNext (q : State) : State := {q with phase:=(1), claims:=(q.claims+(1))}
def failedProbeGuard (q : State) : Prop := (q.descriptor=(1))
def failedProbeNext (q : State) : State := {q with probes:=(q.probes+(1))}
def allocateCopyGuard (q : State) : Prop := ((((q.phase=(1)) ∧ (q.copyRoot=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def allocateCopyNext (q : State) : State := {q with copyRoot:=(1), placeholder:=(1), materialized:=(1)}
def initializeCopyGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.copyRoot=(1))) ∧ (q.sourceRoot=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def initializeCopyNext (q : State) : State := {q with phase:=(2), ready:=(1)}
def publishReadyGuard (q : State) : Prop := (((((q.phase=(2)) ∧ (q.ready=(1))) ∧ (q.copyRoot=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def publishReadyNext (q : State) : State := {q with phase:=(3), queueRoot:=(1)}
def commitSplitGuard (q : State) : Prop := ((((((q.phase=(3)) ∧ (q.ready=(1))) ∧ (q.copyRoot=(1))) ∧ (q.queueRoot=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def commitSplitNext (q : State) : State := {q with phase:=(4), sourceRoot:=(0), split:=(1), parentOwner:=(1)}
def abortPrivateGuard (q : State) : Prop := (((((q.phase=(1)) ∨ (q.phase=(2))) ∧ (q.queueRoot=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def abortPrivateNext (q : State) : State := {q with phase:=(0), copyRoot:=(0), placeholder:=(0), ready:=(0)}
def localChildDoneGuard (q : State) : Prop := ((((q.phase=(0)) ∧ (q.childDone=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def localChildDoneNext (q : State) : State := {q with phase:=(6), childDone:=(1), resultRoot:=(1)}
def localAfterAbortDoneGuard (q : State) : Prop := ((((q.phase=(0)) ∧ (q.childDone=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def localAfterAbortDoneNext (q : State) : State := {q with phase:=(6)}
def childDoneInSplitGuard (q : State) : Prop := ((((((q.phase≥(1)) ∧ (q.phase≤(5))) ∨ (q.phase=(7))) ∧ (q.childDone=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def childDoneInSplitNext (q : State) : State := {q with childDone:=(1), resultRoot:=(1)}
def dequeueParentGuard (q : State) : Prop := True
def dequeueParentNext (q : State) : State := {q with phase:=(5), queueRoot:=(0), restoreRoot:=(1), parentOwner:=(2)}
def restoreParentGuard (q : State) : Prop := ((((((q.phase=(5)) ∧ (q.copyRoot=(1))) ∧ (q.restoreRoot=(1))) ∧ (q.ready=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def restoreParentNext (q : State) : State := {q with phase:=(7), contextRoot:=(1), copyRoot:=(0), restoreRoot:=(0), parentOwner:=(3)}
def publishResultGuard (q : State) : Prop := (((((((q.split=(1)) ∧ (q.childDone=(1))) ∧ (q.resultRoot=(1))) ∧ (q.resultPublished=(0))) ∧ (q.phase<(8))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def publishResultNext (q : State) : State := {q with resultPublished:=(1)}
def runParentPrefixGuard (q : State) : Prop := (((((q.phase=(7)) ∧ (q.parentOwner=(3))) ∧ (q.prefixRuns=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def runParentPrefixNext (q : State) : State := {q with prefixRuns:=(1)}
def consumeSplitResultGuard (q : State) : Prop := ((((((q.phase=(7)) ∧ (q.prefixRuns=(1))) ∧ (q.resultPublished=(1))) ∧ (q.parentRuns=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def consumeSplitResultNext (q : State) : State := {q with parentRuns:=(1)}
def runLocalParentGuard (q : State) : Prop := (((((q.phase=(6)) ∧ (q.childDone=(1))) ∧ (q.parentRuns=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def runLocalParentNext (q : State) : State := {q with prefixRuns:=(1), parentRuns:=(1)}
def captureAfterValueGuard (q : State) : Prop := ((((((q.phase=(6)) ∨ (q.phase=(7))) ∧ (q.parentRuns≥(1))) ∧ (q.exited=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def captureAfterValueNext (q : State) : State := {q with captured:=(1), captureRoot:=(1)}
def restoreAfterValueGuard (q : State) : Prop := (((((((q.phase=(6)) ∨ (q.phase=(7))) ∧ (q.captured=(1))) ∧ (q.captureRoot=(1))) ∧ (q.parentRuns≥(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def restoreAfterValueNext (q : State) : State := {q with parentRuns:=(q.parentRuns+(1))}
def dropCapturedGuard (q : State) : Prop := (((q.captured=(1)) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def dropCapturedNext (q : State) : State := {q with captured:=(0), captureRoot:=(0)}
def exitParentGuard (q : State) : Prop := ((((((q.phase=(6)) ∨ (q.phase=(7))) ∧ (q.parentRuns≥(1))) ∧ (q.captured=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def exitParentNext (q : State) : State := {q with exited:=(1)}
def retireTaskRootsGuard (q : State) : Prop := ((((((q.phase=(6)) ∨ (q.phase=(7))) ∧ (q.exited=(1))) ∧ (q.captured=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def retireTaskRootsNext (q : State) : State := {q with phase:=(8), sourceRoot:=(0), copyRoot:=(0), contextRoot:=(0), resultRoot:=(0), placeholder:=(0), ready:=(0)}
def retireDescriptorGuard (q : State) : Prop := ((((((((((q.phase=(8)) ∧ (q.sourceRoot=(0))) ∧ (q.copyRoot=(0))) ∧ (q.queueRoot=(0))) ∧ (q.restoreRoot=(0))) ∧ (q.contextRoot=(0))) ∧ (q.captureRoot=(0))) ∧ (q.resultRoot=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0)))
def retireDescriptorNext (q : State) : State := {q with phase:=(9), descriptor:=(0)}
def closeGcGuard (q : State) : Prop := (q.gcOpen=(1))
def closeGcNext (q : State) : State := {q with gcOpen:=(0)}
def freezeRootsGuard (q : State) : Prop := ((q.gcOpen=(0)) ∧ (q.frozen=(0)))
def freezeRootsNext (q : State) : State := {q with frozen:=(1), vSource:=q.sourceRoot, vCopy:=q.copyRoot, vQueue:=q.queueRoot, vRestore:=q.restoreRoot, vContext:=q.contextRoot, vResult:=q.resultRoot, vCapture:=q.captureRoot}
def beginScanGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(0)))
def beginScanNext (q : State) : State := {q with scanning:=(1)}
def endScanGuard (q : State) : Prop := (q.scanning=(1))
def endScanNext (q : State) : State := {q with scanning:=(0), scanned:=(1)}
def resumeGcGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(1)))
def resumeGcNext (q : State) : State := {q with frozen:=(0), gcOpen:=(1), scanned:=(0), epoch:=(q.epoch+(1))}
def Step (q r : State) : Prop := (denyParallelProfileGuard q ∧ r=denyParallelProfileNext q) ∨ (claimSplitGuard q ∧ r=claimSplitNext q) ∨ (failedProbeGuard q ∧ r=failedProbeNext q) ∨ (allocateCopyGuard q ∧ r=allocateCopyNext q) ∨ (initializeCopyGuard q ∧ r=initializeCopyNext q) ∨ (publishReadyGuard q ∧ r=publishReadyNext q) ∨ (commitSplitGuard q ∧ r=commitSplitNext q) ∨ (abortPrivateGuard q ∧ r=abortPrivateNext q) ∨ (localChildDoneGuard q ∧ r=localChildDoneNext q) ∨ (localAfterAbortDoneGuard q ∧ r=localAfterAbortDoneNext q) ∨ (childDoneInSplitGuard q ∧ r=childDoneInSplitNext q) ∨ (dequeueParentGuard q ∧ r=dequeueParentNext q) ∨ (restoreParentGuard q ∧ r=restoreParentNext q) ∨ (publishResultGuard q ∧ r=publishResultNext q) ∨ (runParentPrefixGuard q ∧ r=runParentPrefixNext q) ∨ (consumeSplitResultGuard q ∧ r=consumeSplitResultNext q) ∨ (runLocalParentGuard q ∧ r=runLocalParentNext q) ∨ (captureAfterValueGuard q ∧ r=captureAfterValueNext q) ∨ (restoreAfterValueGuard q ∧ r=restoreAfterValueNext q) ∨ (dropCapturedGuard q ∧ r=dropCapturedNext q) ∨ (exitParentGuard q ∧ r=exitParentNext q) ∨ (retireTaskRootsGuard q ∧ r=retireTaskRootsNext q) ∨ (retireDescriptorGuard q ∧ r=retireDescriptorNext q) ∨ (closeGcGuard q ∧ r=closeGcNext q) ∨ (freezeRootsGuard q ∧ r=freezeRootsNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (resumeGcGuard q ∧ r=resumeGcNext q) ∨ r=q
end LazySplitAst
