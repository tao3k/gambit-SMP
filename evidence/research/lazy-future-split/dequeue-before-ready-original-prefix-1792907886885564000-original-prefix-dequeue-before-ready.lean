import LazySplitAst
open LazySplitAst
def witness : State := {initial with phase:=2,claims:=1,copyRoot:=1,ready:=1,placeholder:=1,materialized:=1}
example : claimSplitGuard (initial) := by simp [claimSplitGuard,initial]
example : allocateCopyGuard (claimSplitNext (initial)) := by simp [allocateCopyGuard,initial,claimSplitNext]
example : initializeCopyGuard (allocateCopyNext (claimSplitNext (initial))) := by simp [initializeCopyGuard,initial,claimSplitNext,allocateCopyNext]
example : witness = initializeCopyNext (allocateCopyNext (claimSplitNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
