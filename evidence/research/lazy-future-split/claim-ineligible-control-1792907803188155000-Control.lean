import LazySplitAst
open LazySplitAst
def witness : State := {initial with eligible:=0}
example : denyParallelProfileGuard (initial) := by simp [denyParallelProfileGuard,initial]
example : witness = denyParallelProfileNext (initial) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : claimSplitGuard witness := by simp [claimSplitGuard,witness,initial]
example : ¬ (Safe (claimSplitNext witness)) := by simp [Safe,claimSplitNext,witness,initial]
example : Safe (claimSplitNext witness) := by simp [Safe,claimSplitNext,witness,initial]
