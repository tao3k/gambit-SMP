import StorageIndexAst
open StorageIndexAst
def witness : State := {initial with a:=1, aLease:=1, aGeneration:=1, revision:=1, bSnapshot:=1, bSnapshotGeneration:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : reserveBGuard witness := by simp [reserveBGuard,witness,initial]
example : ¬ (Safe (reserveBNext witness)) := by simp [Safe,reserveBNext,witness,initial]
example : Safe (reserveBNext witness) := by simp [Safe,reserveBNext,witness,initial]
