import Std
namespace GlobalUnloadAst
set_option maxRecDepth 10000
structure State where
 epoch : Int
 phase : Int
 users0 : Int
 users1 : Int
 nativeUsers : Int
 tasks : Int
 observers : Int
 stamp0 : Int
 stamp1 : Int
 denied : Int
 closed0 : Bool
 closed1 : Bool
 ready0 : Bool
 ready1 : Bool
 receipt0 : Bool
 receipt1 : Bool
 pendingChild : Bool
 unknownResult : Bool
 scopeComplete : Bool
 teardownQualified : Bool
 loaderPin : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.epoch≥(1)) ∧ (q.epoch≤(2)) ∧ (q.phase≥(0)) ∧ (q.phase≤(5)) ∧ (q.users0≥(0)) ∧ (q.users1≥(0)) ∧ (q.nativeUsers≥(0)) ∧ (q.tasks≥(0)) ∧ (q.observers≥(0)) ∧ (q.stamp0≥(0)) ∧ (q.stamp1≥(0)) ∧ (q.denied≥(0)) ∧ (q.users0≤(1)) ∧ (q.users1≤(1)) ∧ (q.nativeUsers≤(1)) ∧ (q.tasks≤(1)) ∧ (q.observers≤(1)) ∧ (q.stamp0≤q.epoch) ∧ (q.stamp1≤q.epoch) ∧ ((q.pendingChild=true) → (q.users0=(1))) ∧ ((q.ready0=true) → ((((q.phase≥(1)) ∧ (q.closed0=true)) ∧ (q.users0=(0))) ∧ (q.stamp0=q.epoch))) ∧ ((q.ready1=true) → ((((q.phase≥(1)) ∧ (q.closed1=true)) ∧ (q.users1=(0))) ∧ (q.stamp1=q.epoch))) ∧ ((q.receipt0=true) → (q.ready0=true)) ∧ ((q.receipt1=true) → (q.ready1=true)) ∧ (((q.phase≥(2)) ∧ (q.phase≤(4))) → (((((((((((q.closed0=true) ∧ (q.closed1=true)) ∧ (q.receipt0=true)) ∧ (q.receipt1=true)) ∧ (q.nativeUsers=(0))) ∧ (q.tasks=(0))) ∧ (q.observers=(0))) ∧ (¬(q.pendingChild=true))) ∧ (¬(q.unknownResult=true))) ∧ (q.scopeComplete=true)) ∧ (q.teardownQualified=true))) ∧ ((q.phase=(3)) → (q.loaderPin=true)) ∧ ((q.phase=(4)) → (¬(q.loaderPin=true))) ∧ ((q.phase=(5)) → ((q.unknownResult=true) ∧ (q.loaderPin=true))))
def initial : State := {epoch:=(1), phase:=(0), users0:=(1), users1:=(1), nativeUsers:=(0), tasks:=(0), observers:=(0), stamp0:=(0), stamp1:=(0), denied:=(0), closed0:=false, closed1:=false, ready0:=false, ready1:=false, receipt0:=false, receipt1:=false, pendingChild:=false, unknownResult:=false, scopeComplete:=true, teardownQualified:=true, loaderPin:=false}
def borrow0Guard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.closed0=true)) ∧ (q.users0=(0))
def borrow0Next (q : State) : State := {q with users0:=(1)}
def borrow1Guard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.closed1=true)) ∧ (q.users1=(0))
def borrow1Next (q : State) : State := {q with users1:=(1)}
def observeGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.observers=(0))
def observeNext (q : State) : State := {q with observers:=(1)}
def closeGlobalGuard (q : State) : Prop := (q.phase=(0))
def closeGlobalNext (q : State) : State := {q with phase:=(1), epoch:=(2)}
def closeLocal0Guard (q : State) : Prop := (q.phase=(1))
def closeLocal0Next (q : State) : State := {q with closed0:=true}
def closeLocal1Guard (q : State) : Prop := (q.phase=(1))
def closeLocal1Next (q : State) : State := {q with closed1:=true}
def return0Guard (q : State) : Prop := (q.users0=(1)) ∧ (¬(q.pendingChild=true))
def return0Next (q : State) : State := {q with users0:=(0)}
def return1Guard (q : State) : Prop := (q.users1=(1))
def return1Next (q : State) : State := {q with users1:=(0)}
def issueLocal0Guard (q : State) : Prop := (q.phase=(1)) ∧ (q.closed0=true) ∧ (q.users0=(0))
def issueLocal0Next (q : State) : State := {q with ready0:=true, stamp0:=q.epoch}
def issueLocal1Guard (q : State) : Prop := (q.phase=(1)) ∧ (q.closed1=true) ∧ (q.users1=(0))
def issueLocal1Next (q : State) : State := {q with ready1:=true, stamp1:=q.epoch}
def deliver0Guard (q : State) : Prop := (q.ready0=true) ∧ (q.stamp0=q.epoch)
def deliver0Next (q : State) : State := {q with receipt0:=true}
def deliver1Guard (q : State) : Prop := (q.ready1=true) ∧ (q.stamp1=q.epoch)
def deliver1Next (q : State) : State := {q with receipt1:=true}
def rejectStaleGuard (q : State) : Prop := (q.phase=(1))
def rejectStaleNext (q : State) : State := {q with denied:=(q.denied+(1))}
def rejectLateGuard (q : State) : Prop := (q.phase≥(1))
def rejectLateNext (q : State) : State := {q with denied:=(q.denied+(1))}
def nativeBorrowGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.nativeUsers=(0))
def nativeBorrowNext (q : State) : State := {q with nativeUsers:=(1)}
def nativeReturnGuard (q : State) : Prop := (q.nativeUsers=(1)) ∧ (¬(q.unknownResult=true))
def nativeReturnNext (q : State) : State := {q with nativeUsers:=(0)}
def unknownNativeGuard (q : State) : Prop := (q.nativeUsers=(1)) ∧ (q.phase≤(1))
def unknownNativeNext (q : State) : State := {q with unknownResult:=true}
def observerRetireGuard (q : State) : Prop := (q.observers=(1))
def observerRetireNext (q : State) : State := {q with observers:=(0)}
def beginChildGuard (q : State) : Prop := (q.users0=(1)) ∧ (¬(q.ready0=true)) ∧ (q.phase≤(1)) ∧ (q.tasks=(0))
def beginChildNext (q : State) : State := {q with pendingChild:=true}
def commitChildGuard (q : State) : Prop := (q.pendingChild=true) ∧ (q.users0=(1)) ∧ (q.tasks=(0)) ∧ (¬(q.unknownResult=true))
def commitChildNext (q : State) : State := {q with pendingChild:=false, users0:=(0), tasks:=(1)}
def rejectChildGuard (q : State) : Prop := (q.pendingChild=true)
def rejectChildNext (q : State) : State := {q with pendingChild:=false}
def unknownChildGuard (q : State) : Prop := (q.pendingChild=true) ∧ (q.phase≤(1))
def unknownChildNext (q : State) : State := {q with unknownResult:=true}
def taskDoneGuard (q : State) : Prop := (q.tasks=(1)) ∧ (¬(q.unknownResult=true))
def taskDoneNext (q : State) : State := {q with tasks:=(0)}
def permitGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.closed0=true) ∧ (q.closed1=true) ∧ (q.receipt0=true) ∧ (q.receipt1=true) ∧ (q.stamp0=q.epoch) ∧ (q.stamp1=q.epoch) ∧ (q.nativeUsers=(0)) ∧ (q.tasks=(0)) ∧ (q.observers=(0)) ∧ (¬(q.pendingChild=true)) ∧ (¬(q.unknownResult=true)) ∧ (q.scopeComplete=true) ∧ (q.teardownQualified=true)
def permitNext (q : State) : State := {q with phase:=(2)}
def beginUnloadGuard (q : State) : Prop := (q.phase=(2))
def beginUnloadNext (q : State) : State := {q with phase:=(3), loaderPin:=true}
def closeKnownGuard (q : State) : Prop := (q.phase=(3))
def closeKnownNext (q : State) : State := {q with phase:=(4), loaderPin:=false}
def closeUnknownGuard (q : State) : Prop := (q.phase=(3))
def closeUnknownNext (q : State) : State := {q with phase:=(5), unknownResult:=true}
def rejectIncompleteGuard (q : State) : Prop := (q.phase≤(1))
def rejectIncompleteNext (q : State) : State := {q with scopeComplete:=false}
def Step (q r : State) : Prop := (borrow0Guard q ∧ r=borrow0Next q) ∨ (borrow1Guard q ∧ r=borrow1Next q) ∨ (observeGuard q ∧ r=observeNext q) ∨ (closeGlobalGuard q ∧ r=closeGlobalNext q) ∨ (closeLocal0Guard q ∧ r=closeLocal0Next q) ∨ (closeLocal1Guard q ∧ r=closeLocal1Next q) ∨ (return0Guard q ∧ r=return0Next q) ∨ (return1Guard q ∧ r=return1Next q) ∨ (issueLocal0Guard q ∧ r=issueLocal0Next q) ∨ (issueLocal1Guard q ∧ r=issueLocal1Next q) ∨ (deliver0Guard q ∧ r=deliver0Next q) ∨ (deliver1Guard q ∧ r=deliver1Next q) ∨ (rejectStaleGuard q ∧ r=rejectStaleNext q) ∨ (rejectLateGuard q ∧ r=rejectLateNext q) ∨ (nativeBorrowGuard q ∧ r=nativeBorrowNext q) ∨ (nativeReturnGuard q ∧ r=nativeReturnNext q) ∨ (unknownNativeGuard q ∧ r=unknownNativeNext q) ∨ (observerRetireGuard q ∧ r=observerRetireNext q) ∨ (beginChildGuard q ∧ r=beginChildNext q) ∨ (commitChildGuard q ∧ r=commitChildNext q) ∨ (rejectChildGuard q ∧ r=rejectChildNext q) ∨ (unknownChildGuard q ∧ r=unknownChildNext q) ∨ (taskDoneGuard q ∧ r=taskDoneNext q) ∨ (permitGuard q ∧ r=permitNext q) ∨ (beginUnloadGuard q ∧ r=beginUnloadNext q) ∨ (closeKnownGuard q ∧ r=closeKnownNext q) ∨ (closeUnknownGuard q ∧ r=closeUnknownNext q) ∨ (rejectIncompleteGuard q ∧ r=rejectIncompleteNext q) ∨ r=q
end GlobalUnloadAst
