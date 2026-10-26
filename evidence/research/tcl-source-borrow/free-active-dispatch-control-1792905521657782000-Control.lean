import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with closed:=1,scope:=1,oldRoot:=0,writer:=1}
example : selectDispatchGuard (initial) := by simp [selectDispatchGuard,initial]
example : revokeGuard (selectDispatchNext (initial)) := by simp [revokeGuard,initial,selectDispatchNext]
example : acquireWriterGuard (revokeNext (selectDispatchNext (initial))) := by simp [acquireWriterGuard,initial,selectDispatchNext,revokeNext]
example : dropRevokedRootsGuard (acquireWriterNext (revokeNext (selectDispatchNext (initial)))) := by simp [dropRevokedRootsGuard,initial,selectDispatchNext,revokeNext,acquireWriterNext]
example : witness = dropRevokedRootsNext (acquireWriterNext (revokeNext (selectDispatchNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freeSourceGuard witness := by simp [freeSourceGuard,witness,initial]
example : ¬ (Safe (freeSourceNext witness)) := by simp [Safe,freeSourceNext,witness,initial]
example : Safe (freeSourceNext witness) := by simp [Safe,freeSourceNext,witness,initial]
