import GuardAdmissionAst
open GuardAdmissionAst
def witness : State := {initial with phase:=6,mask:=1,guard:=1,sourceRoot:=1,targetRoot:=1,ack:=1,tls:=0,supervisor:=1,childGuard:=0,childRoot:=0,childSource:=0,childAck:=0,application:=0,closed:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : releaseSourceRootGuard witness := by simp [releaseSourceRootGuard,witness,initial]
example : ¬ (Safe (releaseSourceRootNext witness)) := by simp [Safe,releaseSourceRootNext,witness,initial]
example : Safe (releaseSourceRootNext witness) := by simp [Safe,releaseSourceRootNext,witness,initial]
