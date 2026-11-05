import CatcherSettlementAst
open CatcherSettlementAst
def witness : State := {initial with phase:=13,prepared:=2,escrow:=1,issued:=1,targetActive:=0,errorClass:=1,caught:=1,current:=0,validated:=1,receipt:=1,reply:=0,refI:=0,refO:=0,doneI:=1,doneO:=1,effectsI:=1,effectsO:=1,critical:=0,root:=1,descriptor:=1,captured:=1,reader:=0,copyReady:=1,scanStage:=0,slot:=1,cache:=1,borrow:=0,version:=0,shotActive:=0,shotTicket:=0,contextSlot:=0,closed:=0,rootRetired:=0,grace:=0,guard:=2,unknown:=0,leafPermit:=1,validI:=0,validO:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : settleGuardsGuard witness := by simp [settleGuardsGuard,witness,initial]
example : ¬ (Safe (settleGuardsNext witness)) := by simp [Safe,settleGuardsNext,witness,initial]
example : Safe (settleGuardsNext witness) := by simp [Safe,settleGuardsNext,witness,initial]
