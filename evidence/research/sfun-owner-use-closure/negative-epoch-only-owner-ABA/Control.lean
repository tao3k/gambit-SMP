import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=1,owner:=2,epoch:=1,terminal:=0,active:=1,gate:=1,valid:=1,ref:=1,effects:=0,done:=0,closeOwner:=0,closeEpoch:=0,completed:=0,origin:=0,captured:=0,shots:=0,borrowers:=0,escrow:=0,exitAck:=0,root:=1,code:=1,gc:=0,critical:=0,reply:=0,oldOwner:=1,oldEpoch:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : observeOldOwnerGuard witness := by simp [observeOldOwnerGuard,witness,initial]
example : ¬ (Safe (observeOldOwnerNext witness)) := by simp [Safe,observeOldOwnerNext,witness,initial]
example : Safe (observeOldOwnerNext witness) := by simp [Safe,observeOldOwnerNext,witness,initial]
