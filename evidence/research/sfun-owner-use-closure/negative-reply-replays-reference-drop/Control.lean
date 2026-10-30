import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=7,owner:=1,epoch:=1,terminal:=1,active:=0,gate:=0,valid:=0,ref:=0,effects:=1,done:=1,closeOwner:=1,closeEpoch:=1,completed:=1,origin:=0,captured:=0,shots:=0,borrowers:=0,escrow:=0,exitAck:=0,root:=1,code:=1,gc:=0,critical:=0,reply:=1,oldOwner:=0,oldEpoch:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : queryClosureGuard witness := by simp [queryClosureGuard,witness,initial]
example : ¬ (Safe (queryClosureNext witness)) := by simp [Safe,queryClosureNext,witness,initial]
example : Safe (queryClosureNext witness) := by simp [Safe,queryClosureNext,witness,initial]
