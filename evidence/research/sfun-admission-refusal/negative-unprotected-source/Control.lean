import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := initial
example : witness = initial := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : ackHandoffGuard witness := by simp [ackHandoffGuard,witness,initial]
example : ¬ (Safe (ackHandoffNext witness)) := by simp [Safe,ackHandoffNext,witness,initial]
example : Safe (ackHandoffNext witness) := by simp [Safe,ackHandoffNext,witness,initial]
