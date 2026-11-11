import CatcherSettlementAst
open CatcherSettlementAst
def witness : State := {initial with phase:=14,prepared:=2,escrow:=1,issued:=1,targetActive:=0,errorClass:=1,caught:=1,current:=0,validated:=1,receipt:=1,reply:=0,refI:=0,refO:=0,doneI:=1,doneO:=1,effectsI:=1,effectsO:=1,critical:=0,root:=1,descriptor:=1,captured:=1,reader:=1,copyReady:=1,scanStage:=1,slot:=2,cache:=1,borrow:=0,version:=1,shotActive:=1,shotTicket:=1,contextSlot:=1,closed:=0,rootRetired:=0,grace:=0,guard:=3,unknown:=0,leafPermit:=1,validI:=0,validO:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : finishGcGuard witness := by simp [finishGcGuard,witness,initial]
example : ¬ (Safe (finishGcNext witness)) := by simp [Safe,finishGcNext,witness,initial]
example : Safe (finishGcNext witness) := by simp [Safe,finishGcNext,witness,initial]
