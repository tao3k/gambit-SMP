import Std
namespace SfunOwnerAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 owner : Int
 epoch : Int
 terminal : Int
 active : Int
 gate : Int
 valid : Int
 ref : Int
 effects : Int
 done : Int
 closeOwner : Int
 closeEpoch : Int
 completed : Int
 origin : Int
 captured : Int
 shots : Int
 borrowers : Int
 escrow : Int
 exitAck : Int
 root : Int
 code : Int
 gc : Int
 critical : Int
 reply : Int
 oldOwner : Int
 oldEpoch : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.stage≥(0)) ∧ (q.owner≥(0)) ∧ (q.epoch≥(0)) ∧ (q.terminal≥(0)) ∧ (q.active≥(0)) ∧ (q.gate≥(0)) ∧ (q.valid≥(0)) ∧ (q.ref≥(0)) ∧ (q.effects≥(0)) ∧ (q.done≥(0)) ∧ (q.closeOwner≥(0)) ∧ (q.closeEpoch≥(0)) ∧ (q.completed≥(0)) ∧ (q.origin≥(0)) ∧ (q.captured≥(0)) ∧ (q.shots≥(0)) ∧ (q.borrowers≥(0)) ∧ (q.escrow≥(0)) ∧ (q.exitAck≥(0)) ∧ (q.root≥(0)) ∧ (q.code≥(0)) ∧ (q.gc≥(0)) ∧ (q.critical≥(0)) ∧ (q.reply≥(0)) ∧ (q.oldOwner≥(0)) ∧ (q.oldEpoch≥(0)) ∧ (q.stage≤(10)) ∧ (q.owner≤(2)) ∧ (q.epoch≤(4)) ∧ (q.terminal≤(1)) ∧ (q.active≤(1)) ∧ (q.gate≤(1)) ∧ (q.valid≤(1)) ∧ (q.ref≤(1)) ∧ (q.effects≤(1)) ∧ (q.done≤(1)) ∧ (q.closeOwner≤(2)) ∧ (q.closeEpoch≤(4)) ∧ (q.completed≤(4)) ∧ (q.origin≤(4)) ∧ (q.captured≤(1)) ∧ (q.shots≤(2)) ∧ (q.borrowers≤(1)) ∧ (q.escrow≤(1)) ∧ (q.exitAck≤(1)) ∧ (q.root≤(1)) ∧ (q.code≤(1)) ∧ (q.gc≤(1)) ∧ (q.critical≤(1)) ∧ (q.reply≤(1)) ∧ (q.oldOwner≤(1)) ∧ (q.oldEpoch≤(4)) ∧ (q.owner≥(1)) ∧ ((q.terminal=(1)) → (((q.stage≥(4)) ∧ (q.completed=q.epoch)) ∧ (q.epoch>(0)))) ∧ ((q.stage≤(3)) → (q.terminal=(0))) ∧ (((q.closeOwner>(0)) ∧ (q.escrow=(0))) → (q.terminal=(1))) ∧ (((q.closeOwner>(0)) ∧ (q.escrow=(1))) → (q.exitAck=(1))) ∧ ((q.ref+q.effects)=(1)) ∧ (q.done≤q.effects) ∧ (q.completed≤q.epoch) ∧ ((q.active=(1)) → (((q.stage=(1)) ∧ (q.epoch>(0))) ∧ (q.completed<q.epoch))) ∧ ((q.stage=(1)) → (((q.active=(1)) ∧ (q.gate=(1))) ∧ (q.valid=(1)))) ∧ ((q.stage≠(1)) → (q.active=(0))) ∧ ((q.stage=(0)) → ((q.epoch=(0)) ∧ (q.completed=(0)))) ∧ (((q.stage=(2)) ∨ (q.stage=(4))) → ((q.epoch>(0)) ∧ (q.completed=q.epoch))) ∧ ((q.stage=(3)) → (q.completed=q.epoch)) ∧ ((q.stage≤(3)) → (q.gate=(1))) ∧ ((q.gate=(1)) → ((q.stage≤(4)) ∧ (q.valid=(1)))) ∧ ((q.stage=(4)) → (q.borrowers=(0))) ∧ (((q.stage≥(5)) ∧ (q.stage≤(9))) → ((((((q.gate=(0)) ∧ (q.valid=(0))) ∧ (q.active=(0))) ∧ (q.borrowers=(0))) ∧ (q.closeOwner=q.owner)) ∧ (q.closeEpoch=q.epoch))) ∧ (((q.stage≤(4)) ∨ (q.stage=(10))) → (((((((q.closeOwner=(0)) ∧ (q.closeEpoch=(0))) ∧ (q.ref=(1))) ∧ (q.effects=(0))) ∧ (q.done=(0))) ∧ (q.critical=(0))) ∧ (q.valid=(1)))) ∧ ((q.stage=(5)) → (((q.ref=(1)) ∧ (q.effects=(0))) ∧ (q.done=(0)))) ∧ ((q.stage=(6)) → ((((q.ref=(0)) ∧ (q.effects=(1))) ∧ (q.done=(0))) ∧ (q.critical=(1)))) ∧ (((q.stage≥(7)) ∧ (q.stage≤(9))) → ((((q.ref=(0)) ∧ (q.effects=(1))) ∧ (q.done=(1))) ∧ (q.critical=(0)))) ∧ ((q.done=(1)) → ((((q.stage≥(7)) ∧ (q.stage≤(9))) ∧ (q.closeOwner=q.owner)) ∧ (q.closeEpoch=q.epoch))) ∧ ((q.effects=(1)) → ((q.stage≥(6)) ∧ (q.stage≤(9)))) ∧ ((q.closeOwner>(0)) → (((((q.stage≥(5)) ∧ (q.stage≤(9))) ∧ (q.gate=(0))) ∧ (q.active=(0))) ∧ (q.borrowers=(0)))) ∧ ((q.critical=(1)) → (((((((q.stage=(5)) ∨ (q.stage=(6))) ∧ (q.gc=(0))) ∧ (q.borrowers=(0))) ∧ (q.reply=(0))) ∧ (q.root=(1))) ∧ (q.code=(1)))) ∧ ((q.gc=(1)) → (((q.root=(1)) ∧ (q.code=(1))) ∧ (q.critical=(0)))) ∧ ((q.captured=(1)) → ((((q.origin>(0)) ∧ (q.origin≤q.epoch)) ∧ (q.root=(1))) ∧ (q.code=(1)))) ∧ ((q.captured=(0)) → (q.origin=(0))) ∧ ((q.borrowers=(1)) → (((q.stage=(1)) ∨ (q.stage=(2))) ∨ (q.stage=(10)))) ∧ ((q.stage=(10)) → (((q.escrow=(1)) ∧ (q.gate=(0))) ∧ (q.active=(0)))) ∧ ((q.exitAck=(1)) → ((((q.escrow=(1)) ∧ (q.gate=(0))) ∧ (q.borrowers=(0))) ∧ (q.stage≥(5)))) ∧ ((q.escrow=(0)) → (q.exitAck=(0))) ∧ ((q.stage≤(4)) → ((q.escrow=(0)) ∧ (q.exitAck=(0)))) ∧ ((q.root=(0)) → (((((((q.stage=(8)) ∨ (q.stage=(9))) ∧ (q.captured=(0))) ∧ (q.done=(1))) ∧ (q.gc=(0))) ∧ (q.gate=(0))) ∧ (q.borrowers=(0)))) ∧ ((q.code=(0)) → (((((q.stage=(9)) ∧ (q.root=(0))) ∧ (q.captured=(0))) ∧ (q.done=(1))) ∧ (q.gc=(0)))) ∧ (((q.stage≤(7)) ∨ (q.stage=(10))) → ((q.root=(1)) ∧ (q.code=(1)))) ∧ ((q.stage=(8)) → ((q.root=(0)) ∧ (q.code=(1)))) ∧ ((q.stage=(9)) → ((q.root=(0)) ∧ (q.code=(0)))) ∧ (((q.stage≥(8)) ∧ (q.stage≤(9))) → ((q.captured=(0)) ∧ (q.gc=(0)))) ∧ ((q.reply=(1)) → (((q.stage=(5)) ∨ (q.stage=(7))) ∧ (q.critical=(0)))) ∧ ((q.owner=(1)) → ((q.oldOwner=(0)) ∧ (q.oldEpoch=(0)))) ∧ ((q.owner=(2)) → (q.oldOwner=(1))) ∧ (q.oldOwner<q.owner))
def initial : State := {stage:=(0), owner:=(1), epoch:=(0), terminal:=(0), active:=(0), gate:=(1), valid:=(1), ref:=(1), effects:=(0), done:=(0), closeOwner:=(0), closeEpoch:=(0), completed:=(0), origin:=(0), captured:=(0), shots:=(0), borrowers:=(0), escrow:=(0), exitAck:=(0), root:=(1), code:=(1), gc:=(0), critical:=(0), reply:=(0), oldOwner:=(0), oldEpoch:=(0)}
def bodyCallGuard (q : State) : Prop := ((q.stage=(0)) ∧ (q.gc=(0)))
def bodyCallNext (q : State) : State := {q with stage:=(1), active:=(1), epoch:=(1)}
def inputConversionFailsGuard (q : State) : Prop := ((q.stage=(0)) ∧ (q.gc=(0)))
def inputConversionFailsNext (q : State) : State := {q with stage:=(3)}
def captureCurrentGuard (q : State) : Prop := (((q.stage=(1)) ∧ (q.captured=(0))) ∧ (q.gc=(0)))
def captureCurrentNext (q : State) : State := {q with captured:=(1), origin:=q.epoch}
def callReturnsGuard (q : State) : Prop := (((q.stage=(1)) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def callReturnsNext (q : State) : State := {q with stage:=(2), active:=(0), completed:=q.epoch,ref:=(0),effects:=(1),valid:=(0)}
def resultConversionFailsGuard (q : State) : Prop := (((q.stage=(2)) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def resultConversionFailsNext (q : State) : State := {q with stage:=(3)}
def retryHandlerGuard (q : State) : Prop := ((((q.stage=(3)) ∧ (q.epoch<(4))) ∧ (q.gc=(0))) ∧ (q.borrowers=(0)))
def retryHandlerNext (q : State) : State := {q with stage:=(1), active:=(1), epoch:=(q.epoch+(1))}
def resultConversionSucceedsGuard (q : State) : Prop := (((q.stage=(2)) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def resultConversionSucceedsNext (q : State) : State := {q with stage:=(4), terminal:=(1)}
def closeAdmissionGuard (q : State) : Prop := (((q.stage=(4)) ∧ (q.gate=(1))) ∧ (q.gc=(0)))
def closeAdmissionNext (q : State) : State := {q with gate:=(0)}
def signLocalClosureGuard (q : State) : Prop := ((((q.stage=(4)) ∧ (q.gate=(0))) ∧ (q.terminal=(1))) ∧ (q.gc=(0)))
def signLocalClosureNext (q : State) : State := {q with stage:=(5), valid:=(0), closeOwner:=q.owner, closeEpoch:=q.epoch}
def enterNestedGuard (q : State) : Prop := ((((q.stage=(1)) ∨ (q.stage=(2))) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def enterNestedNext (q : State) : State := {q with borrowers:=(1)}
def leaveNestedGuard (q : State) : Prop := ((((q.stage=(1)) ∨ (q.stage=(2))) ∧ (q.borrowers=(1))) ∧ (q.gc=(0)))
def leaveNestedNext (q : State) : State := {q with borrowers:=(0)}
def outwardUnknownGuard (q : State) : Prop := (((q.stage≤(4)) ∧ (q.stage≥(1))) ∧ (q.gc=(0)))
def outwardUnknownNext (q : State) : State := {q with stage:=(10), active:=(0), gate:=(0), escrow:=(1)}
def drainDescendantGuard (q : State) : Prop := (((q.stage=(10)) ∧ (q.borrowers=(1))) ∧ (q.gc=(0)))
def drainDescendantNext (q : State) : State := {q with borrowers:=(0)}
def ackNativeExitGuard (q : State) : Prop := (((q.stage=(10)) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def ackNativeExitNext (q : State) : State := {q with exitAck:=(1)}
def signEscapedClosureGuard (q : State) : Prop := (((q.stage=(10)) ∧ (q.exitAck=(1))) ∧ (q.gc=(0)))
def signEscapedClosureNext (q : State) : State := {q with stage:=(5), valid:=(0), closeOwner:=q.owner, closeEpoch:=q.epoch}
def beginReleaseGuard (q : State) : Prop := ((((((q.stage=(5)) ∧ (q.critical=(0))) ∧ (q.gc=(0))) ∧ (q.reply=(0))) ∧ (q.closeOwner=q.owner)) ∧ (q.closeEpoch=q.epoch))
def beginReleaseNext (q : State) : State := {q with critical:=(1)}
def physicalDropGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.critical=(1)))
def physicalDropNext (q : State) : State := {q with stage:=(6), ref:=(0), effects:=(1)}
def commitDropGuard (q : State) : Prop := ((q.stage=(6)) ∧ (q.critical=(1)))
def commitDropNext (q : State) : State := {q with stage:=(7), done:=(1), critical:=(0)}
def loseClosureReplyGuard (q : State) : Prop := ((((q.stage=(5)) ∨ (q.stage=(7))) ∧ (q.reply=(0))) ∧ (q.critical=(0)))
def loseClosureReplyNext (q : State) : State := {q with reply:=(1)}
def queryClosureGuard (q : State) : Prop := (((q.stage=(5)) ∨ (q.stage=(7))) ∧ (q.reply=(1)))
def queryClosureNext (q : State) : State := {q with reply:=(0)}
def observeOldInvocationGuard (q : State) : Prop := ((((q.stage=(1)) ∧ (q.completed>(0))) ∧ (q.completed<q.epoch)) ∧ (q.gc=(0)))
def observeOldInvocationNext (q : State) : State := {q with completed:=q.completed}
def observeOldOwnerGuard (q : State) : Prop := ((((q.owner=(2)) ∧ (q.oldOwner=(1))) ∧ (q.gate=(1))) ∧ (q.gc=(0)))
def observeOldOwnerNext (q : State) : State := {q with oldOwner:=q.oldOwner}
def resumeOldReturnGuard (q : State) : Prop := (((((q.stage=(1)) ∧ (q.captured=(1))) ∧ (q.shots<(2))) ∧ (q.borrowers=(0))) ∧ (q.gc=(0)))
def resumeOldReturnNext (q : State) : State := {q with stage:=(2), active:=(0), completed:=q.epoch, shots:=(q.shots+(1))}
def resumeExpiredPrefixGuard (q : State) : Prop := ((((q.stage=(7)) ∧ (q.captured=(1))) ∧ (q.shots<(2))) ∧ (q.gc=(0)))
def resumeExpiredPrefixNext (q : State) : State := {q with shots:=(q.shots+(1))}
def rejectExpiredReturnGuard (q : State) : Prop := (((q.stage=(7)) ∧ (q.captured=(1))) ∧ (q.gc=(0)))
def rejectExpiredReturnNext (q : State) : State := {q with shots:=q.shots}
def dropCapturedGuard (q : State) : Prop := (((q.stage=(7)) ∧ (q.captured=(1))) ∧ (q.gc=(0)))
def dropCapturedNext (q : State) : State := {q with captured:=(0), origin:=(0)}
def beginGcGuard (q : State) : Prop := ((((q.root=(1)) ∧ (q.code=(1))) ∧ (q.critical=(0))) ∧ (q.gc=(0)))
def beginGcNext (q : State) : State := {q with gc:=(1)}
def endGcGuard (q : State) : Prop := (q.gc=(1))
def endGcNext (q : State) : State := {q with gc:=(0)}
def retireRootsGuard (q : State) : Prop := ((((q.stage=(7)) ∧ (q.captured=(0))) ∧ (q.gc=(0))) ∧ (q.reply=(0)))
def retireRootsNext (q : State) : State := {q with stage:=(8), root:=(0)}
def retireCodeGuard (q : State) : Prop := (q.stage=(8))
def retireCodeNext (q : State) : State := {q with stage:=(9), code:=(0)}
def newOwnerGuard (q : State) : Prop := ((q.stage=(9)) ∧ (q.owner=(1)))
def newOwnerNext (q : State) : State := {q with stage:=(0), owner:=(2), epoch:=(0), terminal:=(0), active:=(0), gate:=(1), valid:=(1), ref:=(1), effects:=(0), done:=(0), closeOwner:=(0), closeEpoch:=(0), completed:=(0), origin:=(0), captured:=(0), shots:=(0), borrowers:=(0), escrow:=(0), exitAck:=(0), root:=(1), code:=(1), gc:=(0), critical:=(0), reply:=(0), oldOwner:=q.closeOwner, oldEpoch:=q.closeEpoch}
def Step (q r : State) : Prop := (bodyCallGuard q ∧ r=bodyCallNext q) ∨ (inputConversionFailsGuard q ∧ r=inputConversionFailsNext q) ∨ (captureCurrentGuard q ∧ r=captureCurrentNext q) ∨ (callReturnsGuard q ∧ r=callReturnsNext q) ∨ (resultConversionFailsGuard q ∧ r=resultConversionFailsNext q) ∨ (retryHandlerGuard q ∧ r=retryHandlerNext q) ∨ (resultConversionSucceedsGuard q ∧ r=resultConversionSucceedsNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (signLocalClosureGuard q ∧ r=signLocalClosureNext q) ∨ (enterNestedGuard q ∧ r=enterNestedNext q) ∨ (leaveNestedGuard q ∧ r=leaveNestedNext q) ∨ (outwardUnknownGuard q ∧ r=outwardUnknownNext q) ∨ (drainDescendantGuard q ∧ r=drainDescendantNext q) ∨ (ackNativeExitGuard q ∧ r=ackNativeExitNext q) ∨ (signEscapedClosureGuard q ∧ r=signEscapedClosureNext q) ∨ (beginReleaseGuard q ∧ r=beginReleaseNext q) ∨ (physicalDropGuard q ∧ r=physicalDropNext q) ∨ (commitDropGuard q ∧ r=commitDropNext q) ∨ (loseClosureReplyGuard q ∧ r=loseClosureReplyNext q) ∨ (queryClosureGuard q ∧ r=queryClosureNext q) ∨ (observeOldInvocationGuard q ∧ r=observeOldInvocationNext q) ∨ (observeOldOwnerGuard q ∧ r=observeOldOwnerNext q) ∨ (resumeOldReturnGuard q ∧ r=resumeOldReturnNext q) ∨ (resumeExpiredPrefixGuard q ∧ r=resumeExpiredPrefixNext q) ∨ (rejectExpiredReturnGuard q ∧ r=rejectExpiredReturnNext q) ∨ (dropCapturedGuard q ∧ r=dropCapturedNext q) ∨ (beginGcGuard q ∧ r=beginGcNext q) ∨ (endGcGuard q ∧ r=endGcNext q) ∨ (retireRootsGuard q ∧ r=retireRootsNext q) ∨ (retireCodeGuard q ∧ r=retireCodeNext q) ∨ (newOwnerGuard q ∧ r=newOwnerNext q) ∨ r=q
end SfunOwnerAst
