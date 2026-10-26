import NestedDomainAst
open NestedDomainAst
def witness : State := {initial with source:=0,target:=1,ack:=1,pubReply:=0,innerSource:=0,innerTarget:=1,innerAck:=1,outerGuard:=3,innerGuard:=3,outerRight:=0,innerRight:=0,unwind:=3,landed:=1,captured:=0,gcReader:=1,descriptor:=1,rootClosed:=1,rootGrace:=0,rootRetired:=0,codeClosed:=0,codeGrace:=0,detached:=0,outcome:=0,shotGuard:=0,shotTicket:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : ackRootGraceGuard witness := by simp [ackRootGraceGuard,witness,initial]
example : ¬ (Safe (ackRootGraceNext witness)) := by simp [Safe,ackRootGraceNext,witness,initial]
example : Safe (ackRootGraceNext witness) := by simp [Safe,ackRootGraceNext,witness,initial]
