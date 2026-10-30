import CatcherSettlementAst
open CatcherSettlementAst
def witness : State := {initial with phase:=11,prepared:=2,escrow:=1,issued:=1,targetActive:=1,errorClass:=1,caught:=1,current:=0,validated:=1,receipt:=1,reply:=1,refI:=0,refO:=1,doneI:=1,doneO:=0,effectsI:=1,effectsO:=0,critical:=0,root:=1,descriptor:=1,captured:=1,reader:=0,copyReady:=1,scanStage:=0,slot:=1,cache:=1,borrow:=0,version:=0,shotActive:=0,shotTicket:=0,contextSlot:=0,closed:=0,rootRetired:=0,grace:=0,guard:=2,unknown:=0,leafPermit:=1,validI:=0,validO:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : queryInnerReleaseGuard witness := by simp [queryInnerReleaseGuard,witness,initial]
example : ¬ (Safe (queryInnerReleaseNext witness)) := by simp [Safe,queryInnerReleaseNext,witness,initial]
example : Safe (queryInnerReleaseNext witness) := by simp [Safe,queryInnerReleaseNext,witness,initial]
