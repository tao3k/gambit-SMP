import NestedDomainAst
open NestedDomainAst
def witness : State := {initial with source:=0,target:=1,ack:=1,pubReply:=0,innerSource:=1,innerTarget:=1,innerAck:=1,outerGuard:=1,innerGuard:=0,outerRight:=1,innerRight:=0,unwind:=0,landed:=0,captured:=0,gcReader:=0,descriptor:=1,rootClosed:=0,rootGrace:=0,rootRetired:=0,codeClosed:=0,codeGrace:=0,detached:=0,outcome:=0,shotGuard:=0,shotTicket:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : releaseInnerSourceGuard witness := by simp [releaseInnerSourceGuard,witness,initial]
example : ¬ (Safe (releaseInnerSourceNext witness)) := by simp [Safe,releaseInnerSourceNext,witness,initial]
example : Safe (releaseInnerSourceNext witness) := by simp [Safe,releaseInnerSourceNext,witness,initial]
