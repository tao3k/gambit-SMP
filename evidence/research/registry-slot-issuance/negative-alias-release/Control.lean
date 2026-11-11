import SlotIssuanceAst
open SlotIssuanceAst
def witness : State := {initial with reg:=3, mode:=1, lease:=1, boundGeneration:=1, known:=1, key:=1, keyGeneration:=1, lo:=2, hi:=4}
example : Safe witness := by simp [Safe,witness,initial]
example : releaseRetiredAliasLeaseGuard witness := by simp [releaseRetiredAliasLeaseGuard,witness,initial]
example : ¬ (Safe (releaseRetiredAliasLeaseNext witness)) := by simp [Safe,releaseRetiredAliasLeaseNext,witness,initial]
example : Safe (releaseRetiredAliasLeaseNext witness) := by simp [Safe,releaseRetiredAliasLeaseNext,witness,initial]
