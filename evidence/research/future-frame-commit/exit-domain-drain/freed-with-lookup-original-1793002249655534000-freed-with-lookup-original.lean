import ExitDomainDrain
open ExitDomainDrainAst
def badState : State := {initial with phase:=4,admission:=0,keyGate:=0,lookupPin:=1,tailDone:=1,deps:=1}
example : ¬ Safe badState := by simp [Safe,badState,initial]
