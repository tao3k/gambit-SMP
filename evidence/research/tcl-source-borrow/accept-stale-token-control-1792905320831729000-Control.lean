import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with generation:=2}
example : witness = reuseStorageNext (releaseWriterNext (freeSourceNext (dropRevokedRootsNext (acquireWriterNext (revokeNext (initial)))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : selectDispatchGuard witness := by simp [selectDispatchGuard,witness,initial]
example : ¬ (Safe (selectDispatchNext witness)) := by simp [Safe,selectDispatchNext,witness,initial]
example : Safe (selectDispatchNext witness) := by simp [Safe,selectDispatchNext,witness,initial]
