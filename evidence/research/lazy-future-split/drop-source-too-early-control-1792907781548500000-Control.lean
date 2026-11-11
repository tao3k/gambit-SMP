import LazySplitAst
open LazySplitAst
def witness : State := {initial with phase:=1,claims:=1}
example : claimSplitGuard (initial) := by simp [claimSplitGuard,initial]
example : witness = claimSplitNext (initial) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : commitSplitGuard witness := by simp [commitSplitGuard,witness,initial]
example : ¬ (Safe (commitSplitNext witness)) := by simp [Safe,commitSplitNext,witness,initial]
example : Safe (commitSplitNext witness) := by simp [Safe,commitSplitNext,witness,initial]
