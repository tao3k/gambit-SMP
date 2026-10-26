import TclRefusalAst
open TclRefusalAst
def witness : State := {initial with scope:=1,outerSticky:=1,eventSeen:=1,tclCode:=1,diagnostic:=1}
example : witness = publishOuterDiagnosticNext (recordOuterRefusalNext (beginEvalNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : catchOrResetResultGuard witness := by simp [catchOrResetResultGuard,witness,initial]
example : ¬ (Safe (catchOrResetResultNext witness)) := by simp [Safe,catchOrResetResultNext,witness,initial]
example : Safe (catchOrResetResultNext witness) := by simp [Safe,catchOrResetResultNext,witness,initial]
