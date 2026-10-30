import FrameCommitAst
open FrameCommitAst
def witness : State := {initial with decision:=1,claims:=1,destRoot:=1,copyReady:=1,viewGen:=1,viewLease:=2,patchReady:=1,patchGen:=1,patchLease:=1,gate:=1,grantGen:=1,lease:=2,copyOps:=1,validations:=1}
example : reserveSplitGuard (initial) := by simp [reserveSplitGuard,initial]
example : allocateRootedCopyGuard (reserveSplitNext (initial)) := by simp [allocateRootedCopyGuard,initial,reserveSplitNext]
example : enterRuntimeGuard (allocateRootedCopyNext (reserveSplitNext (initial))) := by simp [enterRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext]
example : resolveCanonicalGuard (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext]
example : initializeCopyGuard (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))) := by simp [initializeCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext]
example : validateCopyGuard (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))) := by simp [validateCopyGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext]
example : prepareReturnGuard (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))) := by simp [prepareReturnGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext]
example : leaveRuntimeGuard (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))))) := by simp [leaveRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext,prepareReturnNext]
example : enterRuntimeGuard (leaveRuntimeNext (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial))))))))) := by simp [enterRuntimeGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext,prepareReturnNext,leaveRuntimeNext]
example : resolveCanonicalGuard (enterRuntimeNext (leaveRuntimeNext (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))))))) := by simp [resolveCanonicalGuard,initial,reserveSplitNext,allocateRootedCopyNext,enterRuntimeNext,resolveCanonicalNext,initializeCopyNext,validateCopyNext,prepareReturnNext,leaveRuntimeNext,enterRuntimeNext]
example : witness = resolveCanonicalNext (enterRuntimeNext (leaveRuntimeNext (prepareReturnNext (validateCopyNext (initializeCopyNext (resolveCanonicalNext (enterRuntimeNext (allocateRootedCopyNext (reserveSplitNext (initial)))))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : commitSplitGuard witness := by simp [commitSplitGuard,witness,initial]
example : ¬ (witness.patchLease=witness.lease) := by simp [Safe,commitSplitNext,witness,initial]
example : witness.patchLease=witness.lease := by simp [Safe,commitSplitNext,witness,initial]
