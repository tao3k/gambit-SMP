import TclBorrowAst
open TclBorrowAst
def witness : State := {initial with newRoot:=1,writer:=1,gcClosed:=1,prepared:=1}
example : witness = closeGcGateNext (prepareSetterNext (acquireWriterNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freezeRootsGuard witness := by simp [freezeRootsGuard,witness,initial]
example : ¬ (Safe (freezeRootsNext witness)) := by simp [Safe,freezeRootsNext,witness,initial]
example : Safe (freezeRootsNext witness) := by simp [Safe,freezeRootsNext,witness,initial]
