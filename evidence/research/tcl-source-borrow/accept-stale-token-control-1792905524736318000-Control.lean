import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with generation:=2}
example : revokeGuard (initial) := by simp [revokeGuard,initial]
example : acquireWriterGuard (revokeNext (initial)) := by simp [acquireWriterGuard,initial,revokeNext]
example : dropRevokedRootsGuard (acquireWriterNext (revokeNext (initial))) := by simp [dropRevokedRootsGuard,initial,revokeNext,acquireWriterNext]
example : freeSourceGuard (dropRevokedRootsNext (acquireWriterNext (revokeNext (initial)))) := by simp [freeSourceGuard,initial,revokeNext,acquireWriterNext,dropRevokedRootsNext]
example : releaseWriterGuard (freeSourceNext (dropRevokedRootsNext (acquireWriterNext (revokeNext (initial))))) := by simp [releaseWriterGuard,initial,revokeNext,acquireWriterNext,dropRevokedRootsNext,freeSourceNext]
example : reuseStorageGuard (releaseWriterNext (freeSourceNext (dropRevokedRootsNext (acquireWriterNext (revokeNext (initial)))))) := by simp [reuseStorageGuard,initial,revokeNext,acquireWriterNext,dropRevokedRootsNext,freeSourceNext,releaseWriterNext]
example : witness = reuseStorageNext (releaseWriterNext (freeSourceNext (dropRevokedRootsNext (acquireWriterNext (revokeNext (initial)))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : selectDispatchGuard witness := by simp [selectDispatchGuard,witness,initial]
example : ¬ (Safe (selectDispatchNext witness)) := by simp [Safe,selectDispatchNext,witness,initial]
example : Safe (selectDispatchNext witness) := by simp [Safe,selectDispatchNext,witness,initial]
