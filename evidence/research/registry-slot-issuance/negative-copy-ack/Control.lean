import SlotIssuanceAst
open SlotIssuanceAst
def witness : State := {initial with reg:=2, mode:=2, lease:=1, boundGeneration:=1, copy:=1, key:=1, keyGeneration:=1, lo:=2, hi:=4, fresh:=1, freshLo:=8, freshHi:=12}
example : Safe witness := by simp [Safe,witness,initial]
example : releaseCopyLeaseGuard witness := by simp [releaseCopyLeaseGuard,witness,initial]
example : ¬ (Safe (releaseCopyLeaseNext witness)) := by simp [Safe,releaseCopyLeaseNext,witness,initial]
example : Safe (releaseCopyLeaseNext witness) := by simp [Safe,releaseCopyLeaseNext,witness,initial]
