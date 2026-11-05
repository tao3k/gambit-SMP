import Std
namespace ConverterUseAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 privateCopy : Int
 payload : Int
 inputRef : Int
 active : Int
 result : Int
 gate : Int
 valid : Int
 receipt : Int
 marker : Int
 effects : Int
 settled : Int
 critical : Int
 captured : Int
 dtor : Int
 code : Int
 roots : Int
 gc : Int
 exitAck : Int
 reply : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((((q.phase≤(4)) ∨ (q.phase=(9))) → (q.dtor=(0))) ∧ (q.phase≥(0)) ∧ (q.privateCopy≥(0)) ∧ (q.payload≥(0)) ∧ (q.inputRef≥(0)) ∧ (q.active≥(0)) ∧ (q.result≥(0)) ∧ (q.gate≥(0)) ∧ (q.valid≥(0)) ∧ (q.receipt≥(0)) ∧ (q.marker≥(0)) ∧ (q.effects≥(0)) ∧ (q.settled≥(0)) ∧ (q.critical≥(0)) ∧ (q.captured≥(0)) ∧ (q.dtor≥(0)) ∧ (q.code≥(0)) ∧ (q.roots≥(0)) ∧ (q.gc≥(0)) ∧ (q.exitAck≥(0)) ∧ (q.reply≥(0)) ∧ (q.phase≤(14)) ∧ (q.privateCopy≤(1)) ∧ (q.payload≤(1)) ∧ (q.inputRef≤(1)) ∧ (q.active≤(1)) ∧ (q.result≤(2)) ∧ (q.gate≤(1)) ∧ (q.valid≤(1)) ∧ (q.receipt≤(1)) ∧ (q.marker≤(1)) ∧ (q.effects≤(1)) ∧ (q.settled≤(1)) ∧ (q.critical≤(1)) ∧ (q.captured≤(1)) ∧ (q.dtor≤(3)) ∧ (q.code≤(1)) ∧ (q.roots≤(1)) ∧ (q.gc≤(1)) ∧ (q.exitAck≤(1)) ∧ (q.reply≤(1)) ∧ ((q.marker+q.effects)=(1)) ∧ (q.settled≤q.effects) ∧ ((q.phase=(0)) → (((((q.privateCopy=(0)) ∧ (q.payload=(0))) ∧ (q.inputRef=(0))) ∧ (q.active=(0))) ∧ (q.result=(0)))) ∧ (((q.phase=(1)) ∨ (q.phase=(2))) → (((((q.privateCopy=(1)) ∧ (q.payload=(0))) ∧ (q.inputRef=(0))) ∧ (q.active=(0))) ∧ (q.result=(0)))) ∧ ((q.phase=(3)) → (((((q.privateCopy=(0)) ∧ (q.payload=(1))) ∧ (q.inputRef=(1))) ∧ (q.active=(1))) ∧ (q.result=(0)))) ∧ ((q.phase=(4)) → (((((q.privateCopy=(0)) ∧ (q.payload=(1))) ∧ (q.inputRef=(1))) ∧ (q.active=(0))) ∧ (q.result≥(1)))) ∧ ((((q.phase=(5)) ∨ (q.phase=(6))) ∨ (q.phase=(7))) → (((q.privateCopy=(0)) ∧ (q.inputRef=(0))) ∧ (q.result≥(1)))) ∧ ((q.phase=(6)) → ((q.active=(1)) ∧ (q.result=(1)))) ∧ (((q.phase=(5)) ∨ (q.phase=(7))) → (q.active=(0))) ∧ ((q.phase=(7)) → (q.result=(2))) ∧ ((q.phase≤(7)) → (((((((q.gate=(1)) ∧ (q.valid=(1))) ∧ (q.receipt=(0))) ∧ (q.marker=(1))) ∧ (q.effects=(0))) ∧ (q.settled=(0))) ∧ (q.critical=(0)))) ∧ ((q.active=(1)) → ((q.phase=(3)) ∨ (q.phase=(6)))) ∧ ((q.privateCopy=(1)) → (((q.phase=(1)) ∨ (q.phase=(2))) ∨ (q.phase=(9)))) ∧ ((q.privateCopy=(1)) → ((q.code=(1)) ∧ (q.roots=(1)))) ∧ ((q.payload=(1)) → (((q.privateCopy=(0)) ∧ (q.code=(1))) ∧ (q.roots=(1)))) ∧ ((q.inputRef=(1)) → ((q.payload=(1)) ∧ (((q.phase=(3)) ∨ (q.phase=(4))) ∨ (q.phase=(13))))) ∧ ((q.captured=(1)) → (((q.payload=(1)) ∧ (q.code=(1))) ∧ (q.roots=(1)))) ∧ ((q.phase=(9)) → ((((((((((q.privateCopy=(1)) ∧ (q.payload=(0))) ∧ (q.gate=(0))) ∧ (q.valid=(1))) ∧ (q.receipt=(0))) ∧ (q.marker=(1))) ∧ (q.effects=(0))) ∧ (q.settled=(0))) ∧ (q.active=(0))) ∧ (q.critical=(0)))) ∧ ((q.phase=(13)) → (((((((((q.gate=(0)) ∧ (q.valid=(1))) ∧ (q.receipt=(0))) ∧ (q.marker=(1))) ∧ (q.effects=(0))) ∧ (q.settled=(0))) ∧ (q.active=(0))) ∧ (q.privateCopy=(0))) ∧ (q.critical=(0)))) ∧ ((q.receipt=(1)) → (((((q.phase=(8)) ∨ (q.phase=(10))) ∨ (q.phase=(11))) ∨ (q.phase=(12))) ∨ (q.phase=(14)))) ∧ ((q.receipt=(1)) → (((((q.privateCopy=(0)) ∧ (q.inputRef=(0))) ∧ (q.active=(0))) ∧ (q.gate=(0))) ∧ (q.valid=(0)))) ∧ (((q.receipt=(1)) ∧ (q.exitAck=(0))) → (q.result=(2))) ∧ ((q.phase=(8)) → ((((q.receipt=(1)) ∧ (q.marker=(1))) ∧ (q.effects=(0))) ∧ (q.settled=(0)))) ∧ ((q.phase=(10)) → (((((q.receipt=(1)) ∧ (q.marker=(0))) ∧ (q.effects=(1))) ∧ (q.settled=(0))) ∧ (q.critical=(1)))) ∧ ((((q.phase=(11)) ∨ (q.phase=(12))) ∨ (q.phase=(14))) → (((((q.receipt=(1)) ∧ (q.marker=(0))) ∧ (q.effects=(1))) ∧ (q.settled=(1))) ∧ (q.critical=(0)))) ∧ ((q.effects=(1)) → ((((q.phase=(10)) ∨ (q.phase=(11))) ∨ (q.phase=(12))) ∨ (q.phase=(14)))) ∧ ((q.critical=(1)) → ((((((q.phase=(8)) ∨ (q.phase=(10))) ∧ (q.gc=(0))) ∧ (q.code=(1))) ∧ (q.roots=(1))) ∧ (q.reply=(0)))) ∧ ((q.gc=(1)) → (((q.code=(1)) ∧ (q.roots=(1))) ∧ (q.critical=(0)))) ∧ (((q.dtor=(1)) ∨ (q.dtor=(2))) → (((((q.phase=(11)) ∧ (q.payload=(1))) ∧ (q.captured=(0))) ∧ (q.code=(1))) ∧ (q.roots=(1)))) ∧ ((q.dtor=(3)) → ((q.payload=(0)) ∧ (q.privateCopy=(0)))) ∧ ((q.reply=(1)) → (((q.phase=(8)) ∨ (q.phase=(11))) ∧ (q.critical=(0)))) ∧ ((q.phase=(12)) → ((((((q.roots=(0)) ∧ (q.code=(1))) ∧ (q.payload=(0))) ∧ (q.privateCopy=(0))) ∧ (q.captured=(0))) ∧ (q.gc=(0)))) ∧ ((q.phase=(14)) → ((((((q.roots=(0)) ∧ (q.code=(0))) ∧ (q.payload=(0))) ∧ (q.privateCopy=(0))) ∧ (q.captured=(0))) ∧ (q.gc=(0)))) ∧ (((q.phase≠(12)) ∧ (q.phase≠(14))) → ((q.code=(1)) ∧ (q.roots=(1)))) ∧ ((q.code=(0)) → (q.phase=(14))) ∧ ((q.roots=(0)) → ((q.phase=(12)) ∨ (q.phase=(14)))) ∧ ((q.exitAck=(1)) → (q.inputRef=(0))) ∧ (((q.exitAck=(1)) ∧ (q.receipt=(0))) → (q.phase=(13))))
def initial : State := {phase:=(0), privateCopy:=(0), payload:=(0), inputRef:=(0), active:=(0), result:=(0), gate:=(1), valid:=(1), receipt:=(0), marker:=(1), effects:=(0), settled:=(0), critical:=(0), captured:=(0), dtor:=(0), code:=(1), roots:=(1), gc:=(0), exitAck:=(0), reply:=(0)}
def reservePrivateGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.gc=(0)))
def reservePrivateNext (q : State) : State := {q with phase:=(1), privateCopy:=(1)}
def beginWrapGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.gc=(0)))
def beginWrapNext (q : State) : State := {q with phase:=(2)}
def wrapSuccessGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.gc=(0)))
def wrapSuccessNext (q : State) : State := {q with phase:=(3), privateCopy:=(0), payload:=(1), inputRef:=(1), active:=(1)}
def wrapFailureReturnedGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.gc=(0)))
def wrapFailureReturnedNext (q : State) : State := {q with phase:=(5), privateCopy:=(0), result:=(1), dtor:=(3)}
def wrapFailureUnknownGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.gc=(0)))
def wrapFailureUnknownNext (q : State) : State := {q with phase:=(9), gate:=(0)}
def auditPrivateDisposedGuard (q : State) : Prop := ((q.phase=(9)) ∧ (q.gc=(0)))
def auditPrivateDisposedNext (q : State) : State := {q with phase:=(13), privateCopy:=(0), dtor:=(3)}
def bodyBadResultGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.gc=(0)))
def bodyBadResultNext (q : State) : State := {q with phase:=(4), active:=(0), result:=(1)}
def bodyGoodResultGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.gc=(0)))
def bodyGoodResultNext (q : State) : State := {q with phase:=(4), active:=(0), result:=(2)}
def captureArgumentGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.gc=(0))) ∧ (q.captured=(0)))
def captureArgumentNext (q : State) : State := {q with captured:=(1)}
def dropInputReferenceGuard (q : State) : Prop := ((q.phase=(4)) ∧ (q.gc=(0)))
def dropInputReferenceNext (q : State) : State := {q with phase:=(5), inputRef:=(0),payload:=(0)}
def handlerCallGuard (q : State) : Prop := (((q.phase=(5)) ∧ (q.result=(1))) ∧ (q.gc=(0)))
def handlerCallNext (q : State) : State := {q with phase:=(6), active:=(1)}
def handlerBadResultGuard (q : State) : Prop := ((q.phase=(6)) ∧ (q.gc=(0)))
def handlerBadResultNext (q : State) : State := {q with phase:=(5), active:=(0), result:=(1)}
def handlerGoodResultGuard (q : State) : Prop := ((q.phase=(6)) ∧ (q.gc=(0)))
def handlerGoodResultNext (q : State) : State := {q with phase:=(5), active:=(0), result:=(2)}
def finishResultGuard (q : State) : Prop := (((q.phase=(5)) ∧ (q.result=(2))) ∧ (q.gc=(0)))
def finishResultNext (q : State) : State := {q with phase:=(7)}
def signFinalUseGuard (q : State) : Prop := ((q.phase=(7)) ∧ (q.gc=(0)))
def signFinalUseNext (q : State) : State := {q with phase:=(8), gate:=(0), valid:=(0), receipt:=(1)}
def escapeOwnerGuard (q : State) : Prop := ((((((q.phase=(3)) ∨ (q.phase=(4))) ∨ (q.phase=(5))) ∨ (q.phase=(6))) ∨ (q.phase=(7))) ∧ (q.gc=(0)))
def escapeOwnerNext (q : State) : State := {q with phase:=(13), gate:=(0), active:=(0)}
def drainInputFromGuardGuard (q : State) : Prop := (((q.phase=(13)) ∧ (q.inputRef=(1))) ∧ (q.gc=(0)))
def drainInputFromGuardNext (q : State) : State := {q with inputRef:=(0)}
def ackExitedOwnerGuard (q : State) : Prop := (((q.phase=(13)) ∧ (q.inputRef=(0))) ∧ (q.gc=(0)))
def ackExitedOwnerNext (q : State) : State := {q with exitAck:=(1)}
def signEscapedUseGuard (q : State) : Prop := (((q.phase=(13)) ∧ (q.exitAck=(1))) ∧ (q.gc=(0)))
def signEscapedUseNext (q : State) : State := {q with phase:=(8), valid:=(0), receipt:=(1)}
def beginMarkerReleaseGuard (q : State) : Prop := ((((q.phase=(8)) ∧ (q.critical=(0))) ∧ (q.gc=(0))) ∧ (q.reply=(0)))
def beginMarkerReleaseNext (q : State) : State := {q with critical:=(1)}
def markerDropGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.critical=(1)))
def markerDropNext (q : State) : State := {q with phase:=(10), marker:=(0), effects:=(1)}
def commitMarkerReleaseGuard (q : State) : Prop := ((q.phase=(10)) ∧ (q.critical=(1)))
def commitMarkerReleaseNext (q : State) : State := {q with phase:=(11), settled:=(1), critical:=(0)}
def loseReplyGuard (q : State) : Prop := ((((q.phase=(8)) ∨ (q.phase=(11))) ∧ (q.reply=(0))) ∧ (q.critical=(0)))
def loseReplyNext (q : State) : State := {q with reply:=(1)}
def queryReplyGuard (q : State) : Prop := (((q.phase=(8)) ∨ (q.phase=(11))) ∧ (q.reply=(1)))
def queryReplyNext (q : State) : State := {q with reply:=(0)}
def dropCapturedGuard (q : State) : Prop := (((q.phase=(11)) ∧ (q.captured=(1))) ∧ (q.gc=(0)))
def dropCapturedNext (q : State) : State := {q with captured:=(0)}
def beginDestructorGuard (q : State) : Prop := (((((q.phase=(11)) ∧ (q.payload=(1))) ∧ (q.captured=(0))) ∧ (q.dtor=(0))) ∧ (q.gc=(0)))
def beginDestructorNext (q : State) : State := {q with dtor:=(1)}
def destructorReturnedGuard (q : State) : Prop := (((q.phase=(11)) ∧ (q.dtor=(1))) ∧ (q.gc=(0)))
def destructorReturnedNext (q : State) : State := {q with dtor:=(3), payload:=(0)}
def destructorUnknownGuard (q : State) : Prop := (((q.phase=(11)) ∧ (q.dtor=(1))) ∧ (q.gc=(0)))
def destructorUnknownNext (q : State) : State := {q with dtor:=(2)}
def beginGcGuard (q : State) : Prop := ((((q.roots=(1)) ∧ (q.code=(1))) ∧ (q.critical=(0))) ∧ (q.gc=(0)))
def beginGcNext (q : State) : State := {q with gc:=(1)}
def finishGcGuard (q : State) : Prop := (q.gc=(1))
def finishGcNext (q : State) : State := {q with gc:=(0)}
def retireRootsGuard (q : State) : Prop := (((((q.phase=(11)) ∧ (q.payload=(0))) ∧ (q.captured=(0))) ∧ (q.gc=(0))) ∧ (q.reply=(0)))
def retireRootsNext (q : State) : State := {q with phase:=(12), roots:=(0)}
def retireCodeGuard (q : State) : Prop := (q.phase=(12))
def retireCodeNext (q : State) : State := {q with phase:=(14), code:=(0)}
def Step (q r : State) : Prop := (reservePrivateGuard q ∧ r=reservePrivateNext q) ∨ (beginWrapGuard q ∧ r=beginWrapNext q) ∨ (wrapSuccessGuard q ∧ r=wrapSuccessNext q) ∨ (wrapFailureReturnedGuard q ∧ r=wrapFailureReturnedNext q) ∨ (wrapFailureUnknownGuard q ∧ r=wrapFailureUnknownNext q) ∨ (auditPrivateDisposedGuard q ∧ r=auditPrivateDisposedNext q) ∨ (bodyBadResultGuard q ∧ r=bodyBadResultNext q) ∨ (bodyGoodResultGuard q ∧ r=bodyGoodResultNext q) ∨ (captureArgumentGuard q ∧ r=captureArgumentNext q) ∨ (dropInputReferenceGuard q ∧ r=dropInputReferenceNext q) ∨ (handlerCallGuard q ∧ r=handlerCallNext q) ∨ (handlerBadResultGuard q ∧ r=handlerBadResultNext q) ∨ (handlerGoodResultGuard q ∧ r=handlerGoodResultNext q) ∨ (finishResultGuard q ∧ r=finishResultNext q) ∨ (signFinalUseGuard q ∧ r=signFinalUseNext q) ∨ (escapeOwnerGuard q ∧ r=escapeOwnerNext q) ∨ (drainInputFromGuardGuard q ∧ r=drainInputFromGuardNext q) ∨ (ackExitedOwnerGuard q ∧ r=ackExitedOwnerNext q) ∨ (signEscapedUseGuard q ∧ r=signEscapedUseNext q) ∨ (beginMarkerReleaseGuard q ∧ r=beginMarkerReleaseNext q) ∨ (markerDropGuard q ∧ r=markerDropNext q) ∨ (commitMarkerReleaseGuard q ∧ r=commitMarkerReleaseNext q) ∨ (loseReplyGuard q ∧ r=loseReplyNext q) ∨ (queryReplyGuard q ∧ r=queryReplyNext q) ∨ (dropCapturedGuard q ∧ r=dropCapturedNext q) ∨ (beginDestructorGuard q ∧ r=beginDestructorNext q) ∨ (destructorReturnedGuard q ∧ r=destructorReturnedNext q) ∨ (destructorUnknownGuard q ∧ r=destructorUnknownNext q) ∨ (beginGcGuard q ∧ r=beginGcNext q) ∨ (finishGcGuard q ∧ r=finishGcNext q) ∨ (retireRootsGuard q ∧ r=retireRootsNext q) ∨ (retireCodeGuard q ∧ r=retireCodeNext q) ∨ r=q
end ConverterUseAst
