import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := initial
example : witness = initial := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : allocateMarkerGuard witness := by simp [allocateMarkerGuard,witness,initial]
example : ¬ (Safe (allocateMarkerNext witness)) := by simp [Safe,allocateMarkerNext,witness,initial]
example : Safe (allocateMarkerNext witness) := by simp [Safe,allocateMarkerNext,witness,initial]
