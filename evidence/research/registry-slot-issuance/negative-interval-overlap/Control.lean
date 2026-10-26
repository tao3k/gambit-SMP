import SlotIssuanceAst
open SlotIssuanceAst
def witness : State := {initial with request:=3, lo:=6, hi:=10}
example : Safe witness := by simp [Safe,witness,initial]
example : issueFreshGuard witness := by simp [issueFreshGuard,witness,initial]
example : ¬ (Safe (issueFreshNext witness)) := by simp [Safe,issueFreshNext,witness,initial]
example : Safe (issueFreshNext witness) := by simp [Safe,issueFreshNext,witness,initial]
