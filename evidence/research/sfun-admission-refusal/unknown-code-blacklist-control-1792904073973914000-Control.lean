import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := {initial with phase:=5,sourcePin:=0,sourceDrops:=1,root:=1,guard:=1,guardCreates:=1,marker:=1,markerCreates:=1,allocs:=1,origin:=2,code:=1}
example : witness = opaqueConversionFailureNext (allocateMarkerNext (ackHandoffNext (reserveGuardNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : ¬ recoverGoodGuard witness := by simp [recoverGoodGuard,witness,initial]
example : recoverGoodGuard witness := by simp [recoverGoodGuard,witness,initial]
