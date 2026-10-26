import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with scope:=1,borrower:=1,borrowCreated:=1,selected:=1,current:=2,newRoot:=1,writer:=1}
example : selectDispatchGuard (initial) := by simp [selectDispatchGuard,initial]
example : acquireBorrowGuard (selectDispatchNext (initial)) := by simp [acquireBorrowGuard,initial,selectDispatchNext]
example : acquireWriterGuard (acquireBorrowNext (selectDispatchNext (initial))) := by simp [acquireWriterGuard,initial,selectDispatchNext,acquireBorrowNext]
example : prepareSetterGuard (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial)))) := by simp [prepareSetterGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext]
example : commitSetterGuard (prepareSetterNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))) := by simp [commitSetterGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext,prepareSetterNext]
example : witness = commitSetterNext (prepareSetterNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : dropOldVersionGuard witness := by simp [dropOldVersionGuard,witness,initial]
example : ¬ (Safe (dropOldVersionNext witness)) := by simp [Safe,dropOldVersionNext,witness,initial]
example : Safe (dropOldVersionNext witness) := by simp [Safe,dropOldVersionNext,witness,initial]
