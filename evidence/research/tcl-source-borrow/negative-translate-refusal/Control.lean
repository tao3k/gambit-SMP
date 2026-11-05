import TclRefusalAst
open TclRefusalAst
def witness : State := {initial with scope:=1,outerSticky:=1,eventSeen:=1,tclCode:=1,diagnostic:=1,done:=1}
example : beginEvalGuard (initial) := by simp [beginEvalGuard,initial]
example : recordOuterRefusalGuard (beginEvalNext (initial)) := by simp [recordOuterRefusalGuard,initial,beginEvalNext]
example : publishOuterDiagnosticGuard (recordOuterRefusalNext (beginEvalNext (initial))) := by simp [publishOuterDiagnosticGuard,initial,beginEvalNext,recordOuterRefusalNext]
example : finishEvalGuard (publishOuterDiagnosticNext (recordOuterRefusalNext (beginEvalNext (initial)))) := by simp [finishEvalGuard,initial,beginEvalNext,recordOuterRefusalNext,publishOuterDiagnosticNext]
example : witness = finishEvalNext (publishOuterDiagnosticNext (recordOuterRefusalNext (beginEvalNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : translateOrdinaryErrorGuard witness := by simp [translateOrdinaryErrorGuard,witness,initial]
example : ¬ (Safe (translateOrdinaryErrorNext witness)) := by simp [Safe,translateOrdinaryErrorNext,witness,initial]
example : Safe (translateOrdinaryErrorNext witness) := by simp [Safe,translateOrdinaryErrorNext,witness,initial]
