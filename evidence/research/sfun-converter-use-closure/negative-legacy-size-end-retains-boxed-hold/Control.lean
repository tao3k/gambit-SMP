import ConverterUseAst
open ConverterUseAst
def witness : State := {phase:=4,privateCopy:=0,payload:=1,inputRef:=1,active:=0,result:=2,gate:=1,valid:=1,receipt:=0,marker:=1,effects:=0,settled:=0,critical:=0,captured:=1,dtor:=0,code:=1,roots:=1,gc:=0,exitAck:=0,reply:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : dropInputReferenceGuard witness := by simp [dropInputReferenceGuard,witness,initial]
example : ¬ (Safe (dropInputReferenceNext witness)) := by simp [Safe,dropInputReferenceNext,witness,initial]
example : Safe (dropInputReferenceNext witness) := by simp [Safe,dropInputReferenceNext,witness,initial]
