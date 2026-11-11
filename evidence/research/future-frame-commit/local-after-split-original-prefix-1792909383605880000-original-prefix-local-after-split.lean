import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=2,claims:=1,done:=1,resultRoot:=1,sourceRoot:=0,destRoot:=1,copyReady:=1,viewGen:=1,viewLease:=1,patchReady:=1,patchGen:=1,patchLease:=1,gate:=1,grantGen:=1,lease:=1,copyOps:=1,validations:=1}
example : reserveSplitGuard (initial) := by simp [reserveSplitGuard,initial]
example : allocateRootedCopyGuard (reserveSplitNext (initial)) := by simp [allocateRootedCopyGuard,initial,reserveSplitNext]
example : enterRuntimeGuard (allocateRootedCopyNext (reserveSplitNext (initial))) := by simp [enterRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext]
example : resolveCanonicalGuard (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext]
example : initializeCopyGuard (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))) := by simp [initializeCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext]
example : validateCopyGuard (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))) := by simp [validateCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext]
example : prepareReturnGuard (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))) := by simp [prepareReturnGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext]
example : childDoneGuard (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))))) := by simp [childDoneGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext,prepareReturnNext]
example : commitSplitGuard (childDoneNext (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))))) := by simp [commitSplitGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext,prepareReturnNext,childDoneNext]
example : witness = commitSplitNext (childDoneNext (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
