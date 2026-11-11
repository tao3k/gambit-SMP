import TclRefusalAst
open TclRefusalAst
def witness : State := {initial with scope:=2,childSticky:=1,eventSeen:=1}
example : witness = recordChildRefusalNext (beginNestedNext (beginEvalNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : popNestedGuard witness := by simp [popNestedGuard,witness,initial]
example : ¬ (Safe (popNestedNext witness)) := by simp [Safe,popNestedNext,witness,initial]
example : Safe (popNestedNext witness) := by simp [Safe,popNestedNext,witness,initial]
