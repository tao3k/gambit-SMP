import RcStorageAst
open RcStorageAst
def witness : State := {initial with phase:=4, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, contextClosing:=1, keyGeneration:=1, index:=2, committed:=1, base:=1, checked:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : exitContextGuard witness := by simp [exitContextGuard,witness,initial]
example : ¬ (Safe (exitContextNext witness)) := by simp [Safe,exitContextNext,witness,initial]
example : Safe (exitContextNext witness) := by simp [Safe,exitContextNext,witness,initial]
