import NestedDomainAst
open NestedDomainAst
def witness : State := {initial with source:=0,target:=1,ack:=1,pubReply:=0,innerSource:=0,innerTarget:=1,innerAck:=1,outerGuard:=1,innerGuard:=1,outerRight:=1,innerRight:=1,unwind:=0,landed:=0,captured:=1,gcReader:=0,descriptor:=1,rootClosed:=0,rootGrace:=0,rootRetired:=0,codeClosed:=0,codeGrace:=0,detached:=0,outcome:=0,shotGuard:=0,shotTicket:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : escrowOuterUnwindGuard witness := by simp [escrowOuterUnwindGuard,witness,initial]
example : ¬ (Safe (escrowOuterUnwindNext witness)) := by simp [Safe,escrowOuterUnwindNext,witness,initial]
example : Safe (escrowOuterUnwindNext witness) := by simp [Safe,escrowOuterUnwindNext,witness,initial]
