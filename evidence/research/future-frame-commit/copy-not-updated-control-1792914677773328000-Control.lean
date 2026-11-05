import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=1,claims:=1,destRoot:=1,copyReady:=1,viewGen:=1,viewLease:=1,gate:=2,grantGen:=1,lease:=1,copyOps:=1}
example : reserveSplitGuard (initial) := by simp [reserveSplitGuard,initial]
example : allocateRootedCopyGuard (reserveSplitNext (initial)) := by simp [allocateRootedCopyGuard,initial,reserveSplitNext]
example : enterRuntimeGuard (allocateRootedCopyNext (reserveSplitNext (initial))) := by simp [enterRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext]
example : resolveCanonicalGuard (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext]
example : initializeCopyGuard (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))) := by simp [initializeCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext]
example : leaveRuntimeGuard (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))) := by simp [leaveRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext]
example : enterGcGuard (leaveRuntimeNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))) := by simp [enterGcGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,leaveRuntimeNext]
example : witness = enterGcNext (leaveRuntimeNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : forwardWithCopyGuard witness := by simp [forwardWithCopyGuard,witness,initial]
example : ¬ (Safe (forwardWithCopyNext witness)) := by simp [Safe,forwardWithCopyNext,witness,initial]
example : Safe (forwardWithCopyNext witness) := by simp [Safe,forwardWithCopyNext,witness,initial]
