import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with current:=2,newRoot:=1,writer:=1,otherOld:=1}
example : witness = commitSetterNext (prepareSetterNext (acquireWriterNext (otherBorrowOldNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : dropOldVersionGuard witness := by simp [dropOldVersionGuard,witness,initial]
example : ¬ (Safe (dropOldVersionNext witness)) := by simp [Safe,dropOldVersionNext,witness,initial]
example : Safe (dropOldVersionNext witness) := by simp [Safe,dropOldVersionNext,witness,initial]
