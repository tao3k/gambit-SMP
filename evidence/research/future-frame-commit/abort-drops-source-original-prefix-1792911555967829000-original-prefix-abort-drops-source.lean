import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=1,claims:=1,destRoot:=1,copyReady:=1,viewGen:=1,viewLease:=1,gate:=1,grantGen:=1,lease:=1,copyOps:=1}
example : reserveSplitGuard (initial) := by simp [reserveSplitGuard,initial]
example : allocateRootedCopyGuard (reserveSplitNext (initial)) := by simp [allocateRootedCopyGuard,initial,reserveSplitNext]
example : enterRuntimeGuard (allocateRootedCopyNext (reserveSplitNext (initial))) := by simp [enterRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext]
example : resolveCanonicalGuard (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext]
example : initializeCopyGuard (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))) := by simp [initializeCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext]
example : witness = initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
