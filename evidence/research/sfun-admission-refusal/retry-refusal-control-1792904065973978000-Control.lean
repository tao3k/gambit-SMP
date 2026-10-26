import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := {initial with phase:=6,domainOpen:=0,sourcePin:=0,sourceDrops:=1,root:=1,guard:=1,guardCreates:=1,marker:=1,markerCreates:=1,allocs:=1,origin:=1,code:=1,refused:=1}
example : witness = callRefusedNext (closeDomainNext (allocateMarkerNext (ackHandoffNext (reserveGuardNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : recoverBadGuard witness := by simp [recoverBadGuard,witness,initial]
example : ¬ (Safe (recoverBadNext witness)) := by simp [Safe,recoverBadNext,witness,initial]
example : Safe (recoverBadNext witness) := by simp [Safe,recoverBadNext,witness,initial]
