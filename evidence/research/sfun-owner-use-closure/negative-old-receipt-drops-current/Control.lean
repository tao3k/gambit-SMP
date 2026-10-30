import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=1,owner:=1,epoch:=2,terminal:=0,active:=1,gate:=1,valid:=1,ref:=1,effects:=0,done:=0,closeOwner:=0,closeEpoch:=0,completed:=1,origin:=0,captured:=0,shots:=0,borrowers:=0,escrow:=0,exitAck:=0,root:=1,code:=1,gc:=0,critical:=0,reply:=0,oldOwner:=0,oldEpoch:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : observeOldInvocationGuard witness := by simp [observeOldInvocationGuard,witness,initial]
example : ¬ (Safe (observeOldInvocationNext witness)) := by simp [Safe,observeOldInvocationNext,witness,initial]
example : Safe (observeOldInvocationNext witness) := by simp [Safe,observeOldInvocationNext,witness,initial]
