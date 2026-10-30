import SlotIssuanceAst
open SlotIssuanceAst
def witness : State := {initial with storage:=3, backing:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : reuseStorageGuard witness := by simp [reuseStorageGuard,witness,initial]
example : ¬ ((reuseStorageNext witness).generation > witness.generation) := by simp [Safe,reuseStorageNext,witness,initial]
example : (reuseStorageNext witness).generation > witness.generation := by simp [Safe,reuseStorageNext,witness,initial]
