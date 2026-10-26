import StorageIndexAst
open StorageIndexAst
def witness : State := {initial with a:=2, aLease:=1, aGeneration:=1, aRoot:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : revokeAGuard witness := by simp [revokeAGuard,witness,initial]
example : ¬ (Safe (revokeANext witness)) := by simp [Safe,revokeANext,witness,initial]
example : Safe (revokeANext witness) := by simp [Safe,revokeANext,witness,initial]
