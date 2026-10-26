import AllocationCaptureAst
open AllocationCaptureAst
def witness : State := {initial with phase:=8,captured:=1,guard:=1,owner:=2,root:=1,calls:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : nestedEnterGuard witness := by simp [nestedEnterGuard,witness,initial]
example : ¬ (Safe (nestedEnterNext witness)) := by simp [Safe,nestedEnterNext,witness,initial]
example : Safe (nestedEnterNext witness) := by simp [Safe,nestedEnterNext,witness,initial]
