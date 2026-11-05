import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := {initial with phase:=6,sourcePin:=0,sourceDrops:=1,root:=1,guard:=1,guardCreates:=1,marker:=1,markerCreates:=1,allocs:=1,bodyEntries:=1,origin:=5}
example : witness = finishSuccessNext (beginBodyNext (allocateMarkerNext (ackHandoffNext (reserveGuardNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : deliverGuard witness := by simp [deliverGuard,witness,initial]
example : ¬ (Safe (deliverNext witness)) := by simp [Safe,deliverNext,witness,initial]
example : Safe (deliverNext witness) := by simp [Safe,deliverNext,witness,initial]
