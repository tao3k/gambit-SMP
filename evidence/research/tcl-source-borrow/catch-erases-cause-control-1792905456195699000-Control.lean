import TclRefusalAst
open TclRefusalAst
def witness : State := {initial with scope:=1,outerSticky:=1,eventSeen:=1,tclCode:=1,diagnostic:=1}
example : beginEvalGuard (initial) := by simp [beginEvalGuard,initial]
example : recordOuterRefusalGuard (beginEvalNext (initial)) := by simp [recordOuterRefusalGuard,initial,beginEvalNext]
example : publishOuterDiagnosticGuard (recordOuterRefusalNext (beginEvalNext (initial))) := by simp [publishOuterDiagnosticGuard,initial,beginEvalNext,recordOuterRefusalNext]
example : witness = publishOuterDiagnosticNext (recordOuterRefusalNext (beginEvalNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : catchOrResetResultGuard witness := by simp [catchOrResetResultGuard,witness,initial]
example : ¬ (Safe (catchOrResetResultNext witness)) := by simp [Safe,catchOrResetResultNext,witness,initial]
example : Safe (catchOrResetResultNext witness) := by simp [Safe,catchOrResetResultNext,witness,initial]
