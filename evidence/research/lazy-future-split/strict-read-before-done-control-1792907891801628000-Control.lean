import LazySplitAst
open LazySplitAst
def witness : State := {initial with phase:=7,claims:=1,sourceRoot:=0,ready:=1,contextRoot:=1,placeholder:=1,materialized:=1,split:=1,parentOwner:=3,prefixRuns:=1}
example : claimSplitGuard (initial) := by simp [claimSplitGuard,initial]
example : allocateCopyGuard (claimSplitNext (initial)) := by simp [allocateCopyGuard,initial,claimSplitNext]
example : initializeCopyGuard (allocateCopyNext (claimSplitNext (initial))) := by simp [initializeCopyGuard,initial,claimSplitNext,allocateCopyNext]
example : publishReadyGuard (initializeCopyNext (allocateCopyNext (claimSplitNext (initial)))) := by simp [publishReadyGuard,initial,claimSplitNext,allocateCopyNext,initializeCopyNext]
example : commitSplitGuard (publishReadyNext (initializeCopyNext (allocateCopyNext (claimSplitNext (initial))))) := by simp [commitSplitGuard,initial,claimSplitNext,allocateCopyNext,initializeCopyNext,publishReadyNext]
example : dequeueParentGuard (commitSplitNext (publishReadyNext (initializeCopyNext (allocateCopyNext (claimSplitNext (initial)))))) := by simp [dequeueParentGuard,initial,claimSplitNext,allocateCopyNext,initializeCopyNext,publishReadyNext,commitSplitNext]
example : restoreParentGuard (dequeueParentNext (commitSplitNext (publishReadyNext (initializeCopyNext (allocateCopyNext (claimSplitNext (initial))))))) := by simp [restoreParentGuard,initial,claimSplitNext,allocateCopyNext,initializeCopyNext,publishReadyNext,commitSplitNext,dequeueParentNext]
example : runParentPrefixGuard (restoreParentNext (dequeueParentNext (commitSplitNext (publishReadyNext (initializeCopyNext (allocateCopyNext (claimSplitNext (initial)))))))) := by simp [runParentPrefixGuard,initial,claimSplitNext,allocateCopyNext,initializeCopyNext,publishReadyNext,commitSplitNext,dequeueParentNext,restoreParentNext]
example : witness = runParentPrefixNext (restoreParentNext (dequeueParentNext (commitSplitNext (publishReadyNext (initializeCopyNext (allocateCopyNext (claimSplitNext (initial)))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : consumeSplitResultGuard witness := by simp [consumeSplitResultGuard,witness,initial]
example : ¬ (Safe (consumeSplitResultNext witness)) := by simp [Safe,consumeSplitResultNext,witness,initial]
example : Safe (consumeSplitResultNext witness) := by simp [Safe,consumeSplitResultNext,witness,initial]
