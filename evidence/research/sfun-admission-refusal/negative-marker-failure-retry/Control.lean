import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := {initial with phase:=2,sourcePin:=0,sourceDrops:=1,root:=1,guard:=1,guardCreates:=1}
example : witness = ackHandoffNext (reserveGuardNext (initial)) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : markerFailureGuard witness := by simp [markerFailureGuard,witness,initial]
example : ¬ (Safe (markerFailureNext witness)) := by simp [Safe,markerFailureNext,witness,initial]
example : Safe (markerFailureNext witness) := by simp [Safe,markerFailureNext,witness,initial]
