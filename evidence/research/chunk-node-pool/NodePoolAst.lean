import Std
namespace NodePoolAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 capacity : Int
 budget : Int
 issued : Int
 privateNodes : Int
 sealedNodes : Int
 queued : Int
 owned : Int
 done : Int
 debt : Int
 receipts : Int
 borrowers : Int
 kind : Int
 rootsClosed : Bool
 usersClosed : Bool
 headAttached : Bool
 admitted : Bool
 alive : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(5)) ∧ (q.capacity≥(0)) ∧ (q.budget≥(0)) ∧ (q.issued≥(0)) ∧ (q.issued≤q.capacity) ∧ (q.issued≤q.budget) ∧ (q.privateNodes≥(0)) ∧ (q.sealedNodes≥(0)) ∧ (q.queued≥(0)) ∧ (q.owned≥(0)) ∧ (q.done≥(0)) ∧ (q.receipts≥(0)) ∧ (q.receipts≤q.issued) ∧ (q.borrowers≥(0)) ∧ (q.issued=((((q.privateNodes+q.sealedNodes)+q.queued)+q.owned)+q.done)) ∧ (q.debt=(((q.privateNodes+q.sealedNodes)+q.queued)+q.owned)) ∧ (q.kind≥(-(1))) ∧ (q.kind≤(4)) ∧ ((q.admitted=true) → (q.capacity≥q.budget)) ∧ (((q.phase≥(1)) ∧ (q.phase≤(4))) → (q.admitted=true)) ∧ (((q.phase=(0)) ∨ (q.phase=(5))) → ((q.issued=(0)) ∧ (¬(q.admitted=true)))) ∧ (((q.phase≥(2)) ∧ (q.phase≤(4))) → ((q.rootsClosed=true) ∧ (q.debt=(0)))) ∧ ((q.usersClosed=true) → ((q.phase≥(2)) ∧ (q.phase≤(4)))) ∧ ((¬(q.headAttached=true)) → (q.usersClosed=true)) ∧ (((q.phase=(3)) ∨ (q.phase=(4))) → ((((q.usersClosed=true) ∧ (¬(q.headAttached=true))) ∧ (q.receipts=(0))) ∧ (q.borrowers=(0)))) ∧ ((q.phase≠(4)) → (q.alive=true)) ∧ ((q.phase=(4)) → (¬(q.alive=true))))
def initial : State := {phase:=(0), capacity:=(3), budget:=(3), issued:=(0), privateNodes:=(0), sealedNodes:=(0), queued:=(0), owned:=(0), done:=(0), debt:=(0), receipts:=(0), borrowers:=(0), kind:=(-(1)), rootsClosed:=false, usersClosed:=false, headAttached:=true, admitted:=false, alive:=true}
def admitGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.capacity≥q.budget)
def admitNext (q : State) : State := {q with phase:=(1), admitted:=true}
def rejectGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.capacity<q.budget)
def rejectNext (q : State) : State := {q with phase:=(5)}
def reserveGuard (q : State) : Prop := (q.phase=(1)) ∧ (¬(q.rootsClosed=true)) ∧ (q.issued<q.budget)
def reserveNext (q : State) : State := {q with issued:=(q.issued+(1)), privateNodes:=(q.privateNodes+(1)), debt:=(q.debt+(1)), receipts:=(q.receipts+(1)), kind:=(4)}
def deriveGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.debt>(0)) ∧ (q.issued<q.budget)
def deriveNext (q : State) : State := {q with issued:=(q.issued+(1)), privateNodes:=(q.privateNodes+(1)), debt:=(q.debt+(1)), receipts:=(q.receipts+(1))}
def sealGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.privateNodes>(0))
def sealNext (q : State) : State := {q with privateNodes:=(q.privateNodes-(1)), sealedNodes:=(q.sealedNodes+(1))}
def publishGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.sealedNodes>(0))
def publishNext (q : State) : State := {q with sealedNodes:=(q.sealedNodes-(1)), queued:=(q.queued+(1))}
def claimGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.queued>(0))
def claimNext (q : State) : State := {q with queued:=(q.queued-(1)), owned:=(q.owned+(1))}
def finishGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.owned>(0))
def finishNext (q : State) : State := {q with owned:=(q.owned-(1)), done:=(q.done+(1)), debt:=(q.debt-(1))}
def observeGuard (q : State) : Prop := (q.phase≥(1)) ∧ (q.phase≤(2)) ∧ (q.receipts>(0))
def observeNext (q : State) : State := {q with receipts:=(q.receipts-(1))}
def borrowGuard (q : State) : Prop := (q.phase=(1))
def borrowNext (q : State) : State := {q with borrowers:=(q.borrowers+(1))}
def returnBorrowGuard (q : State) : Prop := (q.phase≥(1)) ∧ (q.phase≤(2)) ∧ (q.borrowers>(0))
def returnBorrowNext (q : State) : State := {q with borrowers:=(q.borrowers-(1))}
def closeRootsGuard (q : State) : Prop := (q.phase=(1))
def closeRootsNext (q : State) : State := {q with rootsClosed:=true}
def completeGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.rootsClosed=true) ∧ (q.debt=(0))
def completeNext (q : State) : State := {q with phase:=(2)}
def closeUsersGuard (q : State) : Prop := (q.phase=(2))
def closeUsersNext (q : State) : State := {q with usersClosed:=true}
def detachHeadGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.usersClosed=true)
def detachHeadNext (q : State) : State := {q with headAttached:=false}
def certifyGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.usersClosed=true) ∧ (¬(q.headAttached=true)) ∧ (q.receipts=(0)) ∧ (q.borrowers=(0))
def certifyNext (q : State) : State := {q with phase:=(3)}
def reclaimGuard (q : State) : Prop := (q.phase=(3))
def reclaimNext (q : State) : State := {q with phase:=(4), alive:=false}
def Step (q r : State) : Prop := (admitGuard q ∧ r=admitNext q) ∨ (rejectGuard q ∧ r=rejectNext q) ∨ (reserveGuard q ∧ r=reserveNext q) ∨ (deriveGuard q ∧ r=deriveNext q) ∨ (sealGuard q ∧ r=sealNext q) ∨ (publishGuard q ∧ r=publishNext q) ∨ (claimGuard q ∧ r=claimNext q) ∨ (finishGuard q ∧ r=finishNext q) ∨ (observeGuard q ∧ r=observeNext q) ∨ (borrowGuard q ∧ r=borrowNext q) ∨ (returnBorrowGuard q ∧ r=returnBorrowNext q) ∨ (closeRootsGuard q ∧ r=closeRootsNext q) ∨ (completeGuard q ∧ r=completeNext q) ∨ (closeUsersGuard q ∧ r=closeUsersNext q) ∨ (detachHeadGuard q ∧ r=detachHeadNext q) ∨ (certifyGuard q ∧ r=certifyNext q) ∨ (reclaimGuard q ∧ r=reclaimNext q) ∨ r=q
end NodePoolAst
