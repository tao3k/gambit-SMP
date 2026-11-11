import RcStorageAst
open RcStorageAst
def witness : State := {initial with phase:=5, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, keyGeneration:=1, index:=3, committed:=1, effects:=1, checked:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : unpublishGuard witness := by simp [unpublishGuard,witness,initial]
example : ¬ (Safe (unpublishNext witness)) := by simp [Safe,unpublishNext,witness,initial]
example : Safe (unpublishNext witness) := by simp [Safe,unpublishNext,witness,initial]
