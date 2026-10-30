import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with scope:=1,borrower:=1,borrowCreated:=1,selected:=1,current:=2,newRoot:=1,writer:=1}
example : witness = commitSetterNext (prepareSetterNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : dropOldVersionGuard witness := by simp [dropOldVersionGuard,witness,initial]
example : ¬ (Safe (dropOldVersionNext witness)) := by simp [Safe,dropOldVersionNext,witness,initial]
example : Safe (dropOldVersionNext witness) := by simp [Safe,dropOldVersionNext,witness,initial]
