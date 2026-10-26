import RcStorageAst
open RcStorageAst
def witness : State := {initial with phase:=2, operation:=1, owned:=1, base:=1, sourceHold:=1, owner:=1, keyGeneration:=1, checked:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : finishFreeGuard witness := by simp [finishFreeGuard,witness,initial]
example : ¬ (Safe (finishFreeNext witness)) := by simp [Safe,finishFreeNext,witness,initial]
example : Safe (finishFreeNext witness) := by simp [Safe,finishFreeNext,witness,initial]
