import ConverterUseAst
open ConverterUseAst
def witness : State := {phase:=11,privateCopy:=0,payload:=1,inputRef:=0,active:=0,result:=2,gate:=0,valid:=0,receipt:=1,marker:=0,effects:=1,settled:=1,critical:=0,captured:=0,dtor:=0,code:=1,roots:=1,gc:=0,exitAck:=0,reply:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : queryReplyGuard witness := by simp [queryReplyGuard,witness,initial]
example : ¬ (Safe (queryReplyNext witness)) := by simp [Safe,queryReplyNext,witness,initial]
example : Safe (queryReplyNext witness) := by simp [Safe,queryReplyNext,witness,initial]
