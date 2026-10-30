import RcStorageAst
open RcStorageAst
def witness : State := {initial with phase:=8, operation:=1, index:=4, known:=1, frees:=1, keyGeneration:=1, checked:=1, grace:=1, effects:=1, owner:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : reuseAddressGuard witness := by simp [reuseAddressGuard,witness,initial]
example : ¬ ((reuseAddressNext witness).generation > witness.generation) := by simp [Safe,reuseAddressNext,witness,initial]
example : (reuseAddressNext witness).generation > witness.generation := by simp [Safe,reuseAddressNext,witness,initial]
