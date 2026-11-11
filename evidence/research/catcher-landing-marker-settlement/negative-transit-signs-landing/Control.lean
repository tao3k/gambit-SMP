import CatcherSettlementAst
open CatcherSettlementAst
def witness : State := {initial with phase:=5,prepared:=2,escrow:=1,issued:=1,targetActive:=1,errorClass:=1,caught:=2,current:=2,validated:=0,receipt:=0,reply:=0,refI:=1,refO:=1,doneI:=0,doneO:=0,effectsI:=0,effectsO:=0,critical:=0,root:=1,descriptor:=1,captured:=1,reader:=0,copyReady:=1,scanStage:=0,slot:=1,cache:=0,borrow:=0,version:=0,shotActive:=0,shotTicket:=0,contextSlot:=0,closed:=0,rootRetired:=0,grace:=0,guard:=2,unknown:=0,leafPermit:=1,validI:=0,validO:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : restoreInnerCatcherGuard witness := by simp [restoreInnerCatcherGuard,witness,initial]
example : ¬ (Safe (restoreInnerCatcherNext witness)) := by simp [Safe,restoreInnerCatcherNext,witness,initial]
example : Safe (restoreInnerCatcherNext witness) := by simp [Safe,restoreInnerCatcherNext,witness,initial]
