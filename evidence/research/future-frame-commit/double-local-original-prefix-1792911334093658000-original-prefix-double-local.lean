import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=3,done:=1,resultRoot:=1,viewGen:=1,viewLease:=1,gate:=1,grantGen:=1,lease:=1,localGrants:=1}
example : childDoneGuard (initial) := by simp [childDoneGuard,initial]
example : closeLocalGuard (childDoneNext (initial)) := by simp [closeLocalGuard,initial,childDoneNext]
example : enterRuntimeGuard (closeLocalNext (childDoneNext (initial))) := by simp [enterRuntimeGuard,initial,childDoneNext,closeLocalNext]
example : resolveCanonicalGuard (enterRuntimeNext (closeLocalNext (childDoneNext (initial)))) := by simp [resolveCanonicalGuard,initial,childDoneNext,closeLocalNext,enterRuntimeNext]
example : grantLocalGuard (resolveCanonicalNext (enterRuntimeNext (closeLocalNext (childDoneNext (initial))))) := by simp [grantLocalGuard,initial,childDoneNext,closeLocalNext,enterRuntimeNext,resolveCanonicalNext]
example : witness = grantLocalNext (resolveCanonicalNext (enterRuntimeNext (closeLocalNext (childDoneNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : ¬ grantLocalGuard witness := by simp [grantLocalGuard,witness,initial]
