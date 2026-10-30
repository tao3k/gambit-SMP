import AllocationTicketAst
open AllocationTicketAst
def witness : State := {initial with phase:=2,ticket:=1,owner:=1,calls:=1,reserved:=1,sourceHold:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : allocatorOutcomeUnknownGuard witness := by simp [allocatorOutcomeUnknownGuard,witness,initial]
example : ¬ (Safe (allocatorOutcomeUnknownNext witness)) := by simp [Safe,allocatorOutcomeUnknownNext,witness,initial]
example : Safe (allocatorOutcomeUnknownNext witness) := by simp [Safe,allocatorOutcomeUnknownNext,witness,initial]
