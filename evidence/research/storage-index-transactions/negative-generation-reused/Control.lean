import StorageIndexAst
open StorageIndexAst
def witness : State := {initial with opened:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : reuseGuard witness := by simp [reuseGuard,witness,initial]
example : ¬ ((reuseNext witness).generation > witness.generation) := by simp [Safe,reuseNext,witness,initial]
example : (reuseNext witness).generation > witness.generation := by simp [Safe,reuseNext,witness,initial]
