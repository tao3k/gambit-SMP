import NestedDomainAst
open NestedDomainAst
def witness : State := {initial with source:=0,target:=1,ack:=1,pubReply:=0,innerSource:=0,innerTarget:=1,innerAck:=1,outerGuard:=2,innerGuard:=2,outerRight:=0,innerRight:=0,unwind:=2,landed:=0,captured:=1,gcReader:=0,descriptor:=1,rootClosed:=0,rootGrace:=0,rootRetired:=0,codeClosed:=0,codeGrace:=0,detached:=0,outcome:=0,shotGuard:=0,shotTicket:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : landingObservedGuard witness := by simp [landingObservedGuard,witness,initial]
example : ¬ (Safe (landingObservedNext witness)) := by simp [Safe,landingObservedNext,witness,initial]
example : Safe (landingObservedNext witness) := by simp [Safe,landingObservedNext,witness,initial]
