import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with scope:=1,borrower:=1,borrowCreated:=1,selected:=1,dest:=1,destVersion:=1,pending:=1,replyLost:=1,writer:=1}
example : selectDispatchGuard (initial) := by simp [selectDispatchGuard,initial]
example : acquireBorrowGuard (selectDispatchNext (initial)) := by simp [acquireBorrowGuard,initial,selectDispatchNext]
example : acquireWriterGuard (acquireBorrowNext (selectDispatchNext (initial))) := by simp [acquireWriterGuard,initial,selectDispatchNext,acquireBorrowNext]
example : publishDestinationGuard (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial)))) := by simp [publishDestinationGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext]
example : releaseWriterGuard (publishDestinationNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))) := by simp [releaseWriterGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext,publishDestinationNext]
example : loseReplyGuard (releaseWriterNext (publishDestinationNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial)))))) := by simp [loseReplyGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext,publishDestinationNext,releaseWriterNext]
example : acquireWriterGuard (loseReplyNext (releaseWriterNext (publishDestinationNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))))) := by simp [acquireWriterGuard,initial,selectDispatchNext,acquireBorrowNext,acquireWriterNext,publishDestinationNext,releaseWriterNext,loseReplyNext]
example : witness = acquireWriterNext (loseReplyNext (releaseWriterNext (publishDestinationNext (acquireWriterNext (acquireBorrowNext (selectDispatchNext (initial))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freeSourceGuard witness := by simp [freeSourceGuard,witness,initial]
example : ¬ (Safe (freeSourceNext witness)) := by simp [Safe,freeSourceNext,witness,initial]
example : Safe (freeSourceNext witness) := by simp [Safe,freeSourceNext,witness,initial]
