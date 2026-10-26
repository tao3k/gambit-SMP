import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=3,claims:=1,viewGen:=1,viewLease:=1,gate:=1,grantGen:=1,lease:=1}
example : reserveSplitGuard (initial) := by simp [reserveSplitGuard,initial]
example : enterRuntimeGuard (reserveSplitNext (initial)) := by simp [enterRuntimeGuard,initial,reserveSplitNext]
example : resolveCanonicalGuard (enterRuntimeNext (reserveSplitNext (initial))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,enterRuntimeNext]
example : abortSplitGuard (resolveCanonicalNext (enterRuntimeNext (reserveSplitNext (initial)))) := by simp [abortSplitGuard,initial,reserveSplitNext,enterRuntimeNext,resolveCanonicalNext]
example : witness = abortSplitNext (resolveCanonicalNext (enterRuntimeNext (reserveSplitNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
