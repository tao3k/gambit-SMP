import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=6,owner:=1,epoch:=1,terminal:=1,active:=0,gate:=0,valid:=0,ref:=0,effects:=1,done:=0,closeOwner:=1,closeEpoch:=1,completed:=1,origin:=1,captured:=1,shots:=0,borrowers:=0,escrow:=0,exitAck:=0,root:=1,code:=1,gc:=0,critical:=1,reply:=0,oldOwner:=0,oldEpoch:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : commitDropGuard witness := by simp [commitDropGuard,witness,initial]
example : ¬ (Safe (commitDropNext witness)) := by simp [Safe,commitDropNext,witness,initial]
example : Safe (commitDropNext witness) := by simp [Safe,commitDropNext,witness,initial]
