import CatcherSettlementAst
open CatcherSettlementAst
def witness : State := {initial with phase:=1,prepared:=1,escrow:=0,issued:=0,targetActive:=1,errorClass:=0,caught:=0,current:=2,validated:=0,receipt:=0,reply:=0,refI:=1,refO:=1,doneI:=0,doneO:=0,effectsI:=0,effectsO:=0,critical:=0,root:=1,descriptor:=1,captured:=1,reader:=0,copyReady:=1,scanStage:=0,slot:=1,cache:=0,borrow:=0,version:=0,shotActive:=0,shotTicket:=0,contextSlot:=0,closed:=0,rootRetired:=0,grace:=0,guard:=1,unknown:=0,leafPermit:=1,validI:=1,validO:=1}
example : Safe witness := by simp [Safe,witness,initial]
example : rollbackPartialGuard witness := by simp [rollbackPartialGuard,witness,initial]
example : ¬ (Safe (rollbackPartialNext witness)) := by simp [Safe,rollbackPartialNext,witness,initial]
example : Safe (rollbackPartialNext witness) := by simp [Safe,rollbackPartialNext,witness,initial]
