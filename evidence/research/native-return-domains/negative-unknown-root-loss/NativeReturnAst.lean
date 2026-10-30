import Std
namespace NativeReturnAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 threadLive : Int
 stackLive : Int
 returnRight : Int
 guard : Int
 root : Int
 shot : Int
 ticket : Int
 retained : Int
 closed : Int
 grace : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.phase=(0)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(0)) ∧ (q.ticket=(0)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(1)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(0)) ∧ (q.ticket=(1)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(2)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(0)) ∧ (q.ticket=(1)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(3)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(0)) ∧ (q.ticket=(1)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(4)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(5)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(6)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(7)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(8)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(9)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(10)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(0)) ∧ (q.closed=(1)) ∧ (q.grace=(0))) ∨ ((q.phase=(11)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(0)) ∧ (q.closed=(1)) ∧ (q.grace=(1))) ∨ ((q.phase=(12)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(0)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(0)) ∧ (q.closed=(1)) ∧ (q.grace=(1))) ∨ ((q.phase=(13)) ∧ (q.threadLive=(0)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(0)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(0)) ∧ (q.closed=(1)) ∧ (q.grace=(1))) ∨ ((q.phase=(14)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(2)) ∧ (q.returnRight=(2)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(15)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(16)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(0)) ∧ (q.ticket=(1)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(17)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(0)) ∧ (q.returnRight=(0)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(1)) ∧ (q.ticket=(2)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(18)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(1)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))) ∨ ((q.phase=(19)) ∧ (q.threadLive=(1)) ∧ (q.stackLive=(1)) ∧ (q.returnRight=(1)) ∧ (q.guard=(0)) ∧ (q.root=(1)) ∧ (q.shot=(2)) ∧ (q.ticket=(3)) ∧ (q.retained=(1)) ∧ (q.closed=(0)) ∧ (q.grace=(0))))
def initial : State := {phase:=(0), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(0), root:=(1), shot:=(0), ticket:=(0), retained:=(1), closed:=(0), grace:=(0)}
def enterGuardGuard (q : State) : Prop := (q.phase=(0))
def enterGuardNext (q : State) : State := {q with phase:=(1), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(1), root:=(1), shot:=(0), ticket:=(1), retained:=(1), closed:=(0), grace:=(0)}
def captureSchemeGuard (q : State) : Prop := (q.phase=(1))
def captureSchemeNext (q : State) : State := {q with phase:=(2), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(1), root:=(1), shot:=(0), ticket:=(1), retained:=(1), closed:=(0), grace:=(0)}
def leaveActivationGuard (q : State) : Prop := (q.phase=(2))
def leaveActivationNext (q : State) : State := {q with phase:=(3), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(0), root:=(1), shot:=(0), ticket:=(1), retained:=(1), closed:=(0), grace:=(0)}
def resumeFirstGuard (q : State) : Prop := (q.phase=(3))
def resumeFirstNext (q : State) : State := {q with phase:=(4), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(1), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def settleFirstGuard (q : State) : Prop := (q.phase=(4))
def settleFirstNext (q : State) : State := {q with phase:=(5), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(0), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def physicalReturnGuard (q : State) : Prop := (q.phase=(5))
def physicalReturnNext (q : State) : State := {q with phase:=(6), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def resumeSecondGuard (q : State) : Prop := (q.phase=(6))
def resumeSecondNext (q : State) : State := {q with phase:=(7), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(1), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def rejectStaleReturnGuard (q : State) : Prop := (q.phase=(7))
def rejectStaleReturnNext (q : State) : State := {q with phase:=(8), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(1), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def settleSecondGuard (q : State) : Prop := (q.phase=(8))
def settleSecondNext (q : State) : State := {q with phase:=(9), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def closeCaptureGuard (q : State) : Prop := (q.phase=(9))
def closeCaptureNext (q : State) : State := {q with phase:=(10), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(2), ticket:=(3), retained:=(0), closed:=(1), grace:=(0)}
def scanGraceGuard (q : State) : Prop := (q.phase=(10))
def scanGraceNext (q : State) : State := {q with phase:=(11), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(2), ticket:=(3), retained:=(0), closed:=(1), grace:=(1)}
def retireRootsGuard (q : State) : Prop := (q.phase=(11))
def retireRootsNext (q : State) : State := {q with phase:=(12), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(0), shot:=(2), ticket:=(3), retained:=(0), closed:=(1), grace:=(1)}
def detachThreadGuard (q : State) : Prop := (q.phase=(12))
def detachThreadNext (q : State) : State := {q with phase:=(13), threadLive:=(0), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(0), shot:=(2), ticket:=(3), retained:=(0), closed:=(1), grace:=(1)}
def unknownExitGuard (q : State) : Prop := (q.phase=(4))
def unknownExitNext (q : State) : State := {q with phase:=(14), threadLive:=(1), stackLive:=(2), returnRight:=(2), guard:=(1), root:=(0), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def rejectWrongOwnerGuard (q : State) : Prop := (q.phase=(4))
def rejectWrongOwnerNext (q : State) : State := {q with phase:=(15), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(1), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def settleRejectedOwnerGuard (q : State) : Prop := (q.phase=(15))
def settleRejectedOwnerNext (q : State) : State := {q with phase:=(5), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(0), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def earlyPhysicalReturnGuard (q : State) : Prop := (q.phase=(3))
def earlyPhysicalReturnNext (q : State) : State := {q with phase:=(16), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(0), ticket:=(1), retained:=(1), closed:=(0), grace:=(0)}
def resumeAfterReturnGuard (q : State) : Prop := (q.phase=(16))
def resumeAfterReturnNext (q : State) : State := {q with phase:=(17), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(1), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def settleAfterReturnGuard (q : State) : Prop := (q.phase=(17))
def settleAfterReturnNext (q : State) : State := {q with phase:=(6), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(1), ticket:=(2), retained:=(1), closed:=(0), grace:=(0)}
def resumeAgainLiveGuard (q : State) : Prop := (q.phase=(5))
def resumeAgainLiveNext (q : State) : State := {q with phase:=(18), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(1), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def settleAgainLiveGuard (q : State) : Prop := (q.phase=(18))
def settleAgainLiveNext (q : State) : State := {q with phase:=(19), threadLive:=(1), stackLive:=(1), returnRight:=(1), guard:=(0), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def returnAfterTwoGuard (q : State) : Prop := (q.phase=(19))
def returnAfterTwoNext (q : State) : State := {q with phase:=(9), threadLive:=(1), stackLive:=(0), returnRight:=(0), guard:=(0), root:=(1), shot:=(2), ticket:=(3), retained:=(1), closed:=(0), grace:=(0)}
def Step (q r : State) : Prop := (enterGuardGuard q ∧ r=enterGuardNext q) ∨ (captureSchemeGuard q ∧ r=captureSchemeNext q) ∨ (leaveActivationGuard q ∧ r=leaveActivationNext q) ∨ (resumeFirstGuard q ∧ r=resumeFirstNext q) ∨ (settleFirstGuard q ∧ r=settleFirstNext q) ∨ (physicalReturnGuard q ∧ r=physicalReturnNext q) ∨ (resumeSecondGuard q ∧ r=resumeSecondNext q) ∨ (rejectStaleReturnGuard q ∧ r=rejectStaleReturnNext q) ∨ (settleSecondGuard q ∧ r=settleSecondNext q) ∨ (closeCaptureGuard q ∧ r=closeCaptureNext q) ∨ (scanGraceGuard q ∧ r=scanGraceNext q) ∨ (retireRootsGuard q ∧ r=retireRootsNext q) ∨ (detachThreadGuard q ∧ r=detachThreadNext q) ∨ (unknownExitGuard q ∧ r=unknownExitNext q) ∨ (rejectWrongOwnerGuard q ∧ r=rejectWrongOwnerNext q) ∨ (settleRejectedOwnerGuard q ∧ r=settleRejectedOwnerNext q) ∨ (earlyPhysicalReturnGuard q ∧ r=earlyPhysicalReturnNext q) ∨ (resumeAfterReturnGuard q ∧ r=resumeAfterReturnNext q) ∨ (settleAfterReturnGuard q ∧ r=settleAfterReturnNext q) ∨ (resumeAgainLiveGuard q ∧ r=resumeAgainLiveNext q) ∨ (settleAgainLiveGuard q ∧ r=settleAgainLiveNext q) ∨ (returnAfterTwoGuard q ∧ r=returnAfterTwoNext q) ∨ r=q
end NativeReturnAst
