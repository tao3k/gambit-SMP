import TclRefusalAst
open TclRefusalAst
def witness : State := {initial with scope:=1,outerSticky:=1,eventSeen:=1,tclCode:=1,diagnostic:=1,done:=1}
example : witness = finishEvalNext (publishOuterDiagnosticNext (recordOuterRefusalNext (beginEvalNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : translateOrdinaryErrorGuard witness := by simp [translateOrdinaryErrorGuard,witness,initial]
example : ¬ (Safe (translateOrdinaryErrorNext witness)) := by simp [Safe,translateOrdinaryErrorNext,witness,initial]
example : Safe (translateOrdinaryErrorNext witness) := by simp [Safe,translateOrdinaryErrorNext,witness,initial]
