import AllocationTicketAst
open AllocationTicketAst
def witness : State := {initial with phase:=4,ticket:=1,owner:=2,effect:=1,calls:=1,reserved:=1,sourceHold:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : retryCommitQueryGuard witness := by simp [retryCommitQueryGuard,witness,initial]
example : ¬ (Safe (retryCommitQueryNext witness)) := by simp [Safe,retryCommitQueryNext,witness,initial]
example : Safe (retryCommitQueryNext witness) := by simp [Safe,retryCommitQueryNext,witness,initial]
