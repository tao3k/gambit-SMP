import SfunOwnerAst
open SfunOwnerAst
def witness : State := {stage:=10,owner:=1,epoch:=1,terminal:=0,active:=0,gate:=0,valid:=1,ref:=1,effects:=0,done:=0,closeOwner:=0,closeEpoch:=0,completed:=0,origin:=0,captured:=0,shots:=0,borrowers:=0,escrow:=1,exitAck:=0,root:=1,code:=1,gc:=0,critical:=0,reply:=0,oldOwner:=0,oldEpoch:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : signEscapedClosureGuard witness := by simp [signEscapedClosureGuard,witness,initial]
example : ¬ (Safe (signEscapedClosureNext witness)) := by simp [Safe,signEscapedClosureNext,witness,initial]
example : Safe (signEscapedClosureNext witness) := by simp [Safe,signEscapedClosureNext,witness,initial]
