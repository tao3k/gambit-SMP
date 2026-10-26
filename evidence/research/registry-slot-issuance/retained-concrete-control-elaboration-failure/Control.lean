import SlotIssuanceAst
open SlotIssuanceAst
def witness : State := {initial with reg:=3, mode:=1, lease:=1, boundGeneration:=1, known:=1, key:=1, keyGeneration:=1, lo:=2, hi:=4}
example : Safe witness := by decide
example : releaseRetiredAliasLeaseGuard witness := by decide
example : Safe (releaseRetiredAliasLeaseNext witness) := by decide
