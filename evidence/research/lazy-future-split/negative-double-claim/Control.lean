import LazySplitAst
open LazySplitAst
def witness : State := {initial with phase:=1,claims:=1}
example : claimSplitGuard (initial) := by simp [claimSplitGuard,initial]
example : witness = claimSplitNext (initial) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : claimSplitGuard witness := by simp [claimSplitGuard,witness,initial]
example : ¬ (Safe (claimSplitNext witness)) := by simp [Safe,claimSplitNext,witness,initial]
example : Safe (claimSplitNext witness) := by simp [Safe,claimSplitNext,witness,initial]
