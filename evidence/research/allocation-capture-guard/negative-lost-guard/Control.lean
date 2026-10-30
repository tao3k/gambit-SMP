import AllocationCaptureAst
open AllocationCaptureAst
def witness : State := {initial with phase:=4,guard:=1,disabled:=1,owner:=1,root:=1,calls:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : unrecordedEscapeGuard witness := by simp [unrecordedEscapeGuard,witness,initial]
example : ¬ (Safe (unrecordedEscapeNext witness)) := by simp [Safe,unrecordedEscapeNext,witness,initial]
example : Safe (unrecordedEscapeNext witness) := by simp [Safe,unrecordedEscapeNext,witness,initial]
