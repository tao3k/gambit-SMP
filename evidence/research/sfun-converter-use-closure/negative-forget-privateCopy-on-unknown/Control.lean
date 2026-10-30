import ConverterUseAst
open ConverterUseAst
def witness : State := {phase:=2,privateCopy:=1,payload:=0,inputRef:=0,active:=0,result:=0,gate:=1,valid:=1,receipt:=0,marker:=1,effects:=0,settled:=0,critical:=0,captured:=0,dtor:=0,code:=1,roots:=1,gc:=0,exitAck:=0,reply:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : wrapFailureUnknownGuard witness := by simp [wrapFailureUnknownGuard,witness,initial]
example : ¬ (Safe (wrapFailureUnknownNext witness)) := by simp [Safe,wrapFailureUnknownNext,witness,initial]
example : Safe (wrapFailureUnknownNext witness) := by simp [Safe,wrapFailureUnknownNext,witness,initial]
