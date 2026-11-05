import ExitDomainDrain
open ExitDomainDrainAst
def badState : State := {initial with phase:=6,admission:=0,keyGate:=0,tailDone:=1,deps:=1,key:=0}
example : ¬ Safe badState := by simp [Safe,badState,initial]
example : Safe badState := by simp [Safe,badState,initial]
