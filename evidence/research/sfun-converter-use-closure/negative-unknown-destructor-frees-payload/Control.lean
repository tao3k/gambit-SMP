import ConverterUseAst
open ConverterUseAst
def witness : State := {phase:=11,privateCopy:=0,payload:=1,inputRef:=0,active:=0,result:=2,gate:=0,valid:=0,receipt:=1,marker:=0,effects:=1,settled:=1,critical:=0,captured:=0,dtor:=1,code:=1,roots:=1,gc:=0,exitAck:=0,reply:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : destructorUnknownGuard witness := by simp [destructorUnknownGuard,witness,initial]
example : ¬ (Safe (destructorUnknownNext witness)) := by simp [Safe,destructorUnknownNext,witness,initial]
example : Safe (destructorUnknownNext witness) := by simp [Safe,destructorUnknownNext,witness,initial]
