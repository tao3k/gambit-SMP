import AllocationTicketAst
open AllocationTicketAst
def witness : State := {initial with phase:=7,ticket:=1,owner:=1,effect:=1,calls:=1,frees:=1,reserved:=1,sourceHold:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : privateFreeKnownGuard witness := by simp [privateFreeKnownGuard,witness,initial]
example : ¬ (Safe (privateFreeKnownNext witness)) := by simp [Safe,privateFreeKnownNext,witness,initial]
example : Safe (privateFreeKnownNext witness) := by simp [Safe,privateFreeKnownNext,witness,initial]
