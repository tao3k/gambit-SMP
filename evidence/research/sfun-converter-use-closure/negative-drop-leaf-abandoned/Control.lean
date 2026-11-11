import ConverterUseAst
open ConverterUseAst
def witness : State := {phase:=8,privateCopy:=0,payload:=1,inputRef:=0,active:=0,result:=2,gate:=0,valid:=0,receipt:=1,marker:=1,effects:=0,settled:=0,critical:=1,captured:=0,dtor:=0,code:=1,roots:=1,gc:=0,exitAck:=0,reply:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : markerDropGuard witness := by simp [markerDropGuard,witness,initial]
example : ¬ (Safe (markerDropNext witness)) := by simp [Safe,markerDropNext,witness,initial]
example : Safe (markerDropNext witness) := by simp [Safe,markerDropNext,witness,initial]
