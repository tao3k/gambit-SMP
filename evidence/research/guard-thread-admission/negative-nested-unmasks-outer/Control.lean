import GuardAdmissionAst
open GuardAdmissionAst
def witness : State := {initial with phase:=11,mask:=1,guard:=1,sourceRoot:=0,targetRoot:=1,ack:=1,tls:=1,supervisor:=1,childGuard:=1,childRoot:=1,childSource:=0,childAck:=1,application:=1,closed:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : returnNestedGuard witness := by simp [returnNestedGuard,witness,initial]
example : ¬ (Safe (returnNestedNext witness)) := by simp [Safe,returnNestedNext,witness,initial]
example : Safe (returnNestedNext witness) := by simp [Safe,returnNestedNext,witness,initial]
