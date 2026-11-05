import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=5,owner:=1,epoch:=1,terminal:=1,active:=0,gate:=0,valid:=0,ref:=1,effects:=0,done:=0,closeOwner:=1,closeEpoch:=1,completed:=1,origin:=0,captured:=0,shots:=0,borrowers:=0,escrow:=0,exitAck:=0,root:=1,code:=1,gc:=0,critical:=1,reply:=0,oldOwner:=0,oldEpoch:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : physicalDropGuard witness := by simp [physicalDropGuard,witness,initial]
example : ¬ (Safe (physicalDropNext witness)) := by simp [Safe,physicalDropNext,witness,initial]
example : Safe (physicalDropNext witness) := by simp [Safe,physicalDropNext,witness,initial]
