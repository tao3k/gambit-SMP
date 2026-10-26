import Std
namespace AllocationCaptureAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 captured : Int
 guard : Int
 disabled : Int
 owner : Int
 root : Int
 child : Int
 calls : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.phase=(0)) ∧ (q.captured=(0)) ∧ (q.guard=(0)) ∧ (q.disabled=(0)) ∧ (q.owner=(0)) ∧ (q.root=(0)) ∧ (q.child=(0)) ∧ (q.calls=(0))) ∨ ((q.phase=(1)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(0))) ∨ ((q.phase=(2)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(0))) ∨ ((q.phase=(3)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(4)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(5)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(6)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(7)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(8)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(8)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(1)) ∧ (q.calls=(1))) ∨ ((q.phase=(8)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(2)) ∧ (q.calls=(1))) ∨ ((q.phase=(9)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(9)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(0)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(2)) ∧ (q.calls=(1))) ∨ ((q.phase=(10)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(10)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(2)) ∧ (q.calls=(1))) ∨ ((q.phase=(10)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(3)) ∧ (q.calls=(1))) ∨ ((q.phase=(11)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(3)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(12)) ∧ (q.captured=(0)) ∧ (q.guard=(0)) ∧ (q.disabled=(0)) ∧ (q.owner=(0)) ∧ (q.root=(0)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(13)) ∧ (q.captured=(0)) ∧ (q.guard=(0)) ∧ (q.disabled=(0)) ∧ (q.owner=(0)) ∧ (q.root=(0)) ∧ (q.child=(0)) ∧ (q.calls=(0))) ∨ ((q.phase=(14)) ∧ (q.captured=(1)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(15)) ∧ (q.captured=(1)) ∧ (q.guard=(0)) ∧ (q.disabled=(0)) ∧ (q.owner=(4)) ∧ (q.root=(0)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(15)) ∧ (q.captured=(1)) ∧ (q.guard=(0)) ∧ (q.disabled=(0)) ∧ (q.owner=(4)) ∧ (q.root=(0)) ∧ (q.child=(2)) ∧ (q.calls=(1))) ∨ ((q.phase=(16)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(1)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))) ∨ ((q.phase=(17)) ∧ (q.captured=(0)) ∧ (q.guard=(1)) ∧ (q.disabled=(2)) ∧ (q.owner=(2)) ∧ (q.root=(1)) ∧ (q.child=(0)) ∧ (q.calls=(1))))
def initial : State := {phase:=(0), captured:=(0), guard:=(0), disabled:=(0), owner:=(0), root:=(0), child:=(0), calls:=(0)}
def issueGuard (q : State) : Prop := (q.phase=(0))
def issueNext (q : State) : State := {q with phase:=(1), captured:=(0), guard:=(1), disabled:=(0), owner:=(1), root:=(1), child:=(0), calls:=(0)}
def metadataRejectGuard (q : State) : Prop := (q.phase=(0))
def metadataRejectNext (q : State) : State := {q with phase:=(13), captured:=(0), guard:=(0), disabled:=(0), owner:=(0), root:=(0), child:=(0), calls:=(0)}
def maskRejectGuard (q : State) : Prop := (q.phase=(1))
def maskRejectNext (q : State) : State := {q with phase:=(13), captured:=(0), guard:=(0), disabled:=(0), owner:=(0), root:=(0), child:=(0), calls:=(0)}
def cancelBeforeMaskGuard (q : State) : Prop := (q.phase=(1))
def cancelBeforeMaskNext (q : State) : State := {q with phase:=(13), captured:=(0), guard:=(0), disabled:=(0), owner:=(0), root:=(0), child:=(0), calls:=(0)}
def maskConfirmedGuard (q : State) : Prop := (q.phase=(1))
def maskConfirmedNext (q : State) : State := {q with phase:=(2), captured:=(0), guard:=(1), disabled:=(1), owner:=(1), root:=(1), child:=(0), calls:=(0)}
def invokeGuard (q : State) : Prop := (q.phase=(2))
def invokeNext (q : State) : State := {q with phase:=(3), captured:=(0), guard:=(1), disabled:=(1), owner:=(1), root:=(1), child:=(0), calls:=(1)}
def nativeReturnGuard (q : State) : Prop := (q.phase=(3))
def nativeReturnNext (q : State) : State := {q with phase:=(4), captured:=(0), guard:=(1), disabled:=(1), owner:=(1), root:=(1), child:=(0), calls:=(1)}
def captureGuard (q : State) : Prop := (q.phase=(4))
def captureNext (q : State) : State := {q with phase:=(5), captured:=(1), guard:=(1), disabled:=(1), owner:=(1), root:=(1), child:=(0), calls:=(1)}
def armExitOwnerGuard (q : State) : Prop := (q.phase=(5))
def armExitOwnerNext (q : State) : State := {q with phase:=(6), captured:=(1), guard:=(1), disabled:=(1), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def restoreReturnsGuard (q : State) : Prop := (q.phase=(6))
def restoreReturnsNext (q : State) : State := {q with phase:=(7), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def restoreAbandonsGuard (q : State) : Prop := (q.phase=(6))
def restoreAbandonsNext (q : State) : State := {q with phase:=(10), captured:=(1), guard:=(1), disabled:=(2), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def restoreUnknownGuard (q : State) : Prop := (q.phase=(6))
def restoreUnknownNext (q : State) : State := {q with phase:=(14), captured:=(1), guard:=(1), disabled:=(2), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def nativeNullGuard (q : State) : Prop := (q.phase=(3))
def nativeNullNext (q : State) : State := {q with phase:=(16), captured:=(0), guard:=(1), disabled:=(1), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def finishNullGuard (q : State) : Prop := (q.phase=(16))
def finishNullNext (q : State) : State := {q with phase:=(12), captured:=(0), guard:=(0), disabled:=(0), owner:=(0), root:=(0), child:=(0), calls:=(1)}
def restoreNullAbandonsGuard (q : State) : Prop := (q.phase=(16))
def restoreNullAbandonsNext (q : State) : State := {q with phase:=(17), captured:=(0), guard:=(1), disabled:=(2), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def startLoggerGuard (q : State) : Prop := (q.phase=(7))
def startLoggerNext (q : State) : State := {q with phase:=(8), captured:=(0), guard:=(1), disabled:=(0), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def skipLoggerGuard (q : State) : Prop := (q.phase=(7))
def skipLoggerNext (q : State) : State := {q with phase:=(9), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), child:=(0), calls:=(1)}
def loggerReturnsGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.child≠(1)))
def loggerReturnsNext (q : State) : State := {q with phase:=(9), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), calls:=(1)}
def loggerErrorGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.child≠(1)))
def loggerErrorNext (q : State) : State := {q with phase:=(9), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), calls:=(1)}
def nestedEnterGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.child=(0)))
def nestedEnterNext (q : State) : State := {q with phase:=(8), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), child:=(1), calls:=(1)}
def nestedKnownExitGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.child=(1)))
def nestedKnownExitNext (q : State) : State := {q with phase:=(8), captured:=(1), guard:=(1), disabled:=(0), owner:=(2), root:=(1), child:=(2), calls:=(1)}
def nestedUnknownExitGuard (q : State) : Prop := ((q.phase=(8)) ∧ (q.child=(1)))
def nestedUnknownExitNext (q : State) : State := {q with phase:=(10), captured:=(1), guard:=(1), disabled:=(2), owner:=(2), root:=(1), child:=(3), calls:=(1)}
def capturedThrowGuard (q : State) : Prop := ((((q.phase=(7)) ∨ (q.phase=(8))) ∨ (q.phase=(9))) ∧ (q.child≠(1)))
def capturedThrowNext (q : State) : State := {q with phase:=(10), captured:=(1), guard:=(1), disabled:=(2), owner:=(2), root:=(1), calls:=(1)}
def handoffGuard (q : State) : Prop := (q.phase=(9))
def handoffNext (q : State) : State := {q with phase:=(15), captured:=(1), guard:=(0), disabled:=(0), owner:=(4), root:=(0), calls:=(1)}
def unrecordedEscapeGuard (q : State) : Prop := (q.phase=(4))
def unrecordedEscapeNext (q : State) : State := {q with phase:=(11), captured:=(0), guard:=(1), disabled:=(2), owner:=(3), root:=(1), child:=(0), calls:=(1)}
def inflightEscapeGuard (q : State) : Prop := (q.phase=(3))
def inflightEscapeNext (q : State) : State := {q with phase:=(11), captured:=(0), guard:=(1), disabled:=(2), owner:=(3), root:=(1), child:=(0), calls:=(1)}
def Step (q r : State) : Prop := (issueGuard q ∧ r=issueNext q) ∨ (metadataRejectGuard q ∧ r=metadataRejectNext q) ∨ (maskRejectGuard q ∧ r=maskRejectNext q) ∨ (cancelBeforeMaskGuard q ∧ r=cancelBeforeMaskNext q) ∨ (maskConfirmedGuard q ∧ r=maskConfirmedNext q) ∨ (invokeGuard q ∧ r=invokeNext q) ∨ (nativeReturnGuard q ∧ r=nativeReturnNext q) ∨ (captureGuard q ∧ r=captureNext q) ∨ (armExitOwnerGuard q ∧ r=armExitOwnerNext q) ∨ (restoreReturnsGuard q ∧ r=restoreReturnsNext q) ∨ (restoreAbandonsGuard q ∧ r=restoreAbandonsNext q) ∨ (restoreUnknownGuard q ∧ r=restoreUnknownNext q) ∨ (nativeNullGuard q ∧ r=nativeNullNext q) ∨ (finishNullGuard q ∧ r=finishNullNext q) ∨ (restoreNullAbandonsGuard q ∧ r=restoreNullAbandonsNext q) ∨ (startLoggerGuard q ∧ r=startLoggerNext q) ∨ (skipLoggerGuard q ∧ r=skipLoggerNext q) ∨ (loggerReturnsGuard q ∧ r=loggerReturnsNext q) ∨ (loggerErrorGuard q ∧ r=loggerErrorNext q) ∨ (nestedEnterGuard q ∧ r=nestedEnterNext q) ∨ (nestedKnownExitGuard q ∧ r=nestedKnownExitNext q) ∨ (nestedUnknownExitGuard q ∧ r=nestedUnknownExitNext q) ∨ (capturedThrowGuard q ∧ r=capturedThrowNext q) ∨ (handoffGuard q ∧ r=handoffNext q) ∨ (unrecordedEscapeGuard q ∧ r=unrecordedEscapeNext q) ∨ (inflightEscapeGuard q ∧ r=inflightEscapeNext q) ∨ r=q
end AllocationCaptureAst
