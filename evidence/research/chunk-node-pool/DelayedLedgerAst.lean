import Std
namespace DelayedLedgerAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 chunk : Int
 debt : Int
 accepted : Int
 settled : Int
 children : Int
 kind : Int
 strongDebt : Int
 strongClosed : Bool
 da : Bool
 db : Bool
 rootsClosed : Bool
 sealed : Bool
 headPin : Bool
 receiptPin : Bool
 futureClosed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(4)) ∧ (q.chunk≥(0)) ∧ (q.chunk≤(5)) ∧ (q.strongDebt≥(0)) ∧ (q.strongDebt≤(1)) ∧ (q.debt≥(0)) ∧ (q.children≥(0)) ∧ (q.settled≥(0)) ∧ (q.accepted≥q.settled) ∧ (q.debt=(q.accepted-q.settled)) ∧ (q.kind≥(-(1))) ∧ (q.kind≤(4)) ∧ (((q.chunk≥(1)) ∧ (q.chunk≤(4))) → (q.debt=(q.children+(1)))) ∧ (((q.chunk=(0)) ∨ (q.chunk=(5))) → (q.debt=q.children)) ∧ ((q.chunk≥(2)) → (q.sealed=true)) ∧ ((q.phase≥(1)) → ((q.strongClosed=true) ∧ (q.strongDebt=(0)))) ∧ (((q.da=true) ∨ (q.db=true)) → (q.strongClosed=true)) ∧ ((q.phase≥(2)) → ((q.da=true) ∧ (q.db=true))) ∧ ((q.debt>(0)) → (q.phase=(2))) ∧ ((q.rootsClosed=true) → (q.phase≥(2))) ∧ ((q.phase≥(3)) → ((q.rootsClosed=true) ∧ (q.debt=(0)))) ∧ ((q.phase≤(2)) → (q.headPin=true)) ∧ ((q.futureClosed=true) → (q.phase≥(3))) ∧ ((q.receiptPin=true) → (q.chunk≥(1))) ∧ (((q.chunk=(1)) ∨ (q.chunk=(2))) → (q.receiptPin=true)) ∧ ((q.phase=(4)) → (((¬(q.headPin=true)) ∧ (¬(q.receiptPin=true))) ∧ (q.futureClosed=true))))
def initial : State := {phase:=(0), chunk:=(0), debt:=(0), accepted:=(0), settled:=(0), children:=(0), kind:=(-(1)), strongDebt:=(1), strongClosed:=false, da:=false, db:=false, rootsClosed:=false, sealed:=false, headPin:=true, receiptPin:=false, futureClosed:=false}
def drainStrongGuard (q : State) : Prop := (q.phase=(0))
def drainStrongNext (q : State) : State := {q with strongDebt:=(0)}
def freezeStrongGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.strongDebt=(0))
def freezeStrongNext (q : State) : State := {q with phase:=(1), strongClosed:=true}
def classifyAGuard (q : State) : Prop := (q.phase=(1))
def classifyANext (q : State) : State := {q with da:=true}
def classifyBGuard (q : State) : Prop := (q.phase=(1))
def classifyBNext (q : State) : State := {q with db:=true}
def enterWeakGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.da=true) ∧ (q.db=true)
def enterWeakNext (q : State) : State := {q with phase:=(2)}
def acceptDelayedGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true)) ∧ (q.chunk=(0)) ∧ (q.debt=(0))
def acceptDelayedNext (q : State) : State := {q with chunk:=(1), debt:=(q.debt+(1)), accepted:=(q.accepted+(1)), receiptPin:=true, kind:=(4)}
def sealDelayedGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.chunk=(1))
def sealDelayedNext (q : State) : State := {q with chunk:=(2), sealed:=true}
def publishAcceptedGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.chunk=(2)) ∧ (q.sealed=true)
def publishAcceptedNext (q : State) : State := {q with chunk:=(3)}
def observeReceiptGuard (q : State) : Prop := (q.chunk≥(3)) ∧ (q.receiptPin=true)
def observeReceiptNext (q : State) : State := {q with receiptPin:=false}
def claimGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.chunk=(3))
def claimNext (q : State) : State := {q with chunk:=(4)}
def deriveChildGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.chunk=(4))
def deriveChildNext (q : State) : State := {q with children:=(q.children+(1)), debt:=(q.debt+(1)), accepted:=(q.accepted+(1))}
def settleParentGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.chunk=(4))
def settleParentNext (q : State) : State := {q with chunk:=(5), debt:=(q.debt-(1)), settled:=(q.settled+(1))}
def settleChildGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.children>(0))
def settleChildNext (q : State) : State := {q with children:=(q.children-(1)), debt:=(q.debt-(1)), settled:=(q.settled+(1))}
def closeRootsGuard (q : State) : Prop := (q.phase=(2))
def closeRootsNext (q : State) : State := {q with rootsClosed:=true}
def finishWeakGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.rootsClosed=true) ∧ (q.debt=(0))
def finishWeakNext (q : State) : State := {q with phase:=(3)}
def closeFutureUsersGuard (q : State) : Prop := (q.phase=(3))
def closeFutureUsersNext (q : State) : State := {q with futureClosed:=true}
def releaseHeadGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.futureClosed=true)
def releaseHeadNext (q : State) : State := {q with headPin:=false}
def retireEpochGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.futureClosed=true) ∧ (¬(q.headPin=true)) ∧ (¬(q.receiptPin=true))
def retireEpochNext (q : State) : State := {q with phase:=(4)}
def Step (q r : State) : Prop := (drainStrongGuard q ∧ r=drainStrongNext q) ∨ (freezeStrongGuard q ∧ r=freezeStrongNext q) ∨ (classifyAGuard q ∧ r=classifyANext q) ∨ (classifyBGuard q ∧ r=classifyBNext q) ∨ (enterWeakGuard q ∧ r=enterWeakNext q) ∨ (acceptDelayedGuard q ∧ r=acceptDelayedNext q) ∨ (sealDelayedGuard q ∧ r=sealDelayedNext q) ∨ (publishAcceptedGuard q ∧ r=publishAcceptedNext q) ∨ (observeReceiptGuard q ∧ r=observeReceiptNext q) ∨ (claimGuard q ∧ r=claimNext q) ∨ (deriveChildGuard q ∧ r=deriveChildNext q) ∨ (settleParentGuard q ∧ r=settleParentNext q) ∨ (settleChildGuard q ∧ r=settleChildNext q) ∨ (closeRootsGuard q ∧ r=closeRootsNext q) ∨ (finishWeakGuard q ∧ r=finishWeakNext q) ∨ (closeFutureUsersGuard q ∧ r=closeFutureUsersNext q) ∨ (releaseHeadGuard q ∧ r=releaseHeadNext q) ∨ (retireEpochGuard q ∧ r=retireEpochNext q) ∨ r=q
end DelayedLedgerAst
