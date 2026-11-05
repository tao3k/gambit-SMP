import GuardAdmissionAst
open GuardAdmissionAst
def witness : State := {initial with phase:=13,mask:=1,guard:=1,sourceRoot:=0,targetRoot:=1,ack:=1,tls:=1,supervisor:=2,childGuard:=0,childRoot:=0,childSource:=0,childAck:=0,application:=1,closed:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : restoreDoesNotReturnGuard witness := by simp [restoreDoesNotReturnGuard,witness,initial]
example : ¬ (Safe (restoreDoesNotReturnNext witness)) := by simp [Safe,restoreDoesNotReturnNext,witness,initial]
example : Safe (restoreDoesNotReturnNext witness) := by simp [Safe,restoreDoesNotReturnNext,witness,initial]
