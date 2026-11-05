import Std
namespace SizeHoldAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 direction : Int
 x : Int
 created : Int
 hold : Int
 effects : Int
 root : Int
 captured : Int
 gc : Int
 reply : Int
 settled : Int
 critical : Int
 exited : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(6)) ∧ (q.direction≥(0)) ∧ (q.direction≤(1)) ∧ (q.created≥(0)) ∧ (q.created≤(1)) ∧ (q.hold≥(0)) ∧ (q.hold≤(1)) ∧ (q.effects≥(0)) ∧ (q.effects≤(1)) ∧ (q.root≥(0)) ∧ (q.root≤(1)) ∧ (q.captured≥(0)) ∧ (q.captured≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.reply≥(0)) ∧ (q.reply≤(1)) ∧ (q.settled≥(0)) ∧ (q.settled≤(1)) ∧ (q.critical≥(0)) ∧ (q.critical≤(1)) ∧ (q.exited≥(0)) ∧ (q.exited≤(1)) ∧ ((q.hold+q.effects)=q.created) ∧ (q.captured≤q.root) ∧ ((q.phase≤(1)) → ((((q.created=(0)) ∧ (q.effects=(0))) ∧ (q.root=(0))) ∧ (q.captured=(0)))) ∧ ((q.phase≤(4)) → ((q.effects=(0)) ∧ (q.settled=(0)))) ∧ ((q.phase≥(5)) → ((q.hold=(0)) ∧ (q.effects=q.created))) ∧ ((q.phase=(6)) → ((q.settled=(1)) ∧ (q.critical=(0)))) ∧ ((q.phase≠(6)) → ((q.settled=(0)) ∧ (q.reply=(0)))) ∧ ((q.critical=(1)) → (((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.gc=(0)))) ∧ (((q.phase=(4)) ∨ (q.phase=(5))) → (q.critical=(1))) ∧ ((q.phase≥(3)) → (q.exited=(1))) ∧ ((q.phase≤(2)) → (q.exited=(0))) ∧ (((((q.direction=(1)) ∧ (q.created=(1))) ∧ (q.phase≥(3))) ∧ (q.phase≤(5))) → (q.root=(1))))
def initial : State := {phase:=(0), direction:=(0), x:=(0), created:=(0), hold:=(0), effects:=(0), root:=(0), captured:=(0), gc:=(0), reply:=(0), settled:=(0), critical:=(0), exited:=(0)}
def selectSizeMaxGuard (q : State) : Prop := (q.phase=(0))
def selectSizeMaxNext (q : State) : State := {q with phase:=(1), x:=(18446744073709551615), direction:=(0)}
def selectSignedMinGuard (q : State) : Prop := (q.phase=(0))
def selectSignedMinNext (q : State) : State := {q with phase:=(1), x:=(-(9223372036854775808)), direction:=(0)}
def selectSignedMaxGuard (q : State) : Prop := (q.phase=(0))
def selectSignedMaxNext (q : State) : State := {q with phase:=(1), x:=(9223372036854775807), direction:=(1)}
def selectAboveFixGuard (q : State) : Prop := (q.phase=(0))
def selectAboveFixNext (q : State) : State := {q with phase:=(1), x:=(1152921504606846976), direction:=(1)}
def selectAtFixGuard (q : State) : Prop := (q.phase=(0))
def selectAtFixNext (q : State) : State := {q with phase:=(1), x:=(1152921504606846975), direction:=(0)}
def selectMinFixGuard (q : State) : Prop := (q.phase=(0))
def selectMinFixNext (q : State) : State := {q with phase:=(1), x:=(-(1152921504606846976)), direction:=(0)}
def selectBelowFixGuard (q : State) : Prop := (q.phase=(0))
def selectBelowFixNext (q : State) : State := {q with phase:=(1), x:=(-(1152921504606846977)), direction:=(1)}
def convertBoxedGuard (q : State) : Prop := ((q.phase=(1)) ∧ ((q.x<(-(1152921504606846976))) ∨ (q.x>(1152921504606846975))))
def convertBoxedNext (q : State) : State := {q with phase:=(2), created:=(1), hold:=(1)}
def convertImmediateGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.x≥(-(1152921504606846976)))) ∧ (q.x≤(1152921504606846975)))
def convertImmediateNext (q : State) : State := {q with phase:=(2)}
def conversionFailureGuard (q : State) : Prop := (q.phase=(1))
def conversionFailureNext (q : State) : State := {q with phase:=(2)}
def publishRootGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.root=(0))) ∧ (q.gc=(0)))
def publishRootNext (q : State) : State := {q with root:=(1)}
def captureArgumentGuard (q : State) : Prop := (((((q.phase=(2)) ∧ (q.direction=(0))) ∧ (q.root=(1))) ∧ (q.captured=(0))) ∧ (q.gc=(0)))
def captureArgumentNext (q : State) : State := {q with captured:=(1)}
def finishNativeGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.gc=(0))) ∧ (((q.direction=(0)) ∨ (q.root=(1))) ∨ (q.created=(0))))
def finishNativeNext (q : State) : State := {q with phase:=(3), exited:=(1)}
def enterDropGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.gc=(0))) ∧ (((q.direction=(0)) ∨ (q.root=(1))) ∨ (q.created=(0))))
def enterDropNext (q : State) : State := {q with phase:=(4), critical:=(1)}
def physicalDropGuard (q : State) : Prop := (((q.phase=(4)) ∧ (q.critical=(1))) ∧ (q.gc=(0)))
def physicalDropNext (q : State) : State := {q with phase:=(5), hold:=(0), effects:=q.created}
def commitDropGuard (q : State) : Prop := (((q.phase=(5)) ∧ (q.critical=(1))) ∧ (q.gc=(0)))
def commitDropNext (q : State) : State := {q with phase:=(6), critical:=(0), settled:=(1), reply:=(1)}
def loseReplyGuard (q : State) : Prop := ((q.phase=(6)) ∧ (q.reply=(1)))
def loseReplyNext (q : State) : State := {q with reply:=(0)}
def recoverReplyGuard (q : State) : Prop := ((q.phase=(6)) ∧ (q.reply=(0)))
def recoverReplyNext (q : State) : State := {q with reply:=(1)}
def dropCaptureGuard (q : State) : Prop := (((q.phase=(6)) ∧ (q.captured=(1))) ∧ (q.gc=(0)))
def dropCaptureNext (q : State) : State := {q with captured:=(0)}
def dropRootGuard (q : State) : Prop := ((((q.phase=(6)) ∧ (q.root=(1))) ∧ (q.captured=(0))) ∧ (q.gc=(0)))
def dropRootNext (q : State) : State := {q with root:=(0)}
def beginGcGuard (q : State) : Prop := True
def beginGcNext (q : State) : State := {q with gc:=(1)}
def finishGcGuard (q : State) : Prop := (q.gc=(1))
def finishGcNext (q : State) : State := {q with gc:=(0)}
def Step (q r : State) : Prop := (selectSizeMaxGuard q ∧ r=selectSizeMaxNext q) ∨ (selectSignedMinGuard q ∧ r=selectSignedMinNext q) ∨ (selectSignedMaxGuard q ∧ r=selectSignedMaxNext q) ∨ (selectAboveFixGuard q ∧ r=selectAboveFixNext q) ∨ (selectAtFixGuard q ∧ r=selectAtFixNext q) ∨ (selectMinFixGuard q ∧ r=selectMinFixNext q) ∨ (selectBelowFixGuard q ∧ r=selectBelowFixNext q) ∨ (convertBoxedGuard q ∧ r=convertBoxedNext q) ∨ (convertImmediateGuard q ∧ r=convertImmediateNext q) ∨ (conversionFailureGuard q ∧ r=conversionFailureNext q) ∨ (publishRootGuard q ∧ r=publishRootNext q) ∨ (captureArgumentGuard q ∧ r=captureArgumentNext q) ∨ (finishNativeGuard q ∧ r=finishNativeNext q) ∨ (enterDropGuard q ∧ r=enterDropNext q) ∨ (physicalDropGuard q ∧ r=physicalDropNext q) ∨ (commitDropGuard q ∧ r=commitDropNext q) ∨ (loseReplyGuard q ∧ r=loseReplyNext q) ∨ (recoverReplyGuard q ∧ r=recoverReplyNext q) ∨ (dropCaptureGuard q ∧ r=dropCaptureNext q) ∨ (dropRootGuard q ∧ r=dropRootNext q) ∨ (beginGcGuard q ∧ r=beginGcNext q) ∨ (finishGcGuard q ∧ r=finishGcNext q) ∨ r=q
end SizeHoldAst
