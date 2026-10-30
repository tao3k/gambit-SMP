import AllocationCaptureAst
open AllocationCaptureAst
def witness : State := {initial with phase:=7,captured:=1,guard:=1,owner:=2,root:=1,calls:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : startLoggerGuard witness := by simp [startLoggerGuard,witness,initial]
example : ¬ (Safe (startLoggerNext witness)) := by simp [Safe,startLoggerNext,witness,initial]
example : Safe (startLoggerNext witness) := by simp [Safe,startLoggerNext,witness,initial]
