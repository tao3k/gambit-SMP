import Std
namespace WeakAdmissionAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 strongDebt : Int
 active : Int
 kind : Int
 strongClosed : Bool
 da : Bool
 db : Bool
 rootsClosed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(4)) ∧ (q.strongDebt≥(0)) ∧ (q.strongDebt≤(1)) ∧ (q.active≥(0)) ∧ (q.kind≥(-(1))) ∧ (q.kind≤(5)) ∧ ((q.phase≥(1)) → ((q.strongClosed=true) ∧ (q.strongDebt=(0)))) ∧ (((q.da=true) ∨ (q.db=true)) → (q.strongClosed=true)) ∧ ((q.phase≥(2)) → ((q.da=true) ∧ (q.db=true))) ∧ ((q.active>(0)) → (q.phase=(2))) ∧ ((q.phase≥(3)) → ((q.rootsClosed=true) ∧ (q.active=(0)))) ∧ ((q.rootsClosed=true) → (q.phase≥(2))))
def initial : State := {phase:=(0), strongDebt:=(1), active:=(0), kind:=(-(1)), strongClosed:=false, da:=false, db:=false, rootsClosed:=false}
def drainStrongGuard (q : State) : Prop := (q.phase=(0))
def drainStrongNext (q : State) : State := {q with strongDebt:=(0)}
def freezeStrongGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.strongDebt=(0))
def freezeStrongNext (q : State) : State := {q with phase:=(1), strongClosed:=true}
def classifyAGuard (q : State) : Prop := (q.phase=(1))
def classifyANext (q : State) : State := {q with da:=true}
def classifyBGuard (q : State) : Prop := (q.phase=(1))
def classifyBNext (q : State) : State := {q with db:=true}
def openWeakGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.da=true) ∧ (q.db=true)
def openWeakNext (q : State) : State := {q with phase:=(2)}
def listProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def listProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(0)}
def repairProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def repairProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(1)}
def freshWillProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def freshWillProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(2)}
def graphProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def graphProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(3)}
def continuationProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def continuationProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(4)}
def stillProducerGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.rootsClosed=true))
def stillProducerNext (q : State) : State := {q with active:=(q.active+(1)), kind:=(5)}
def deriveChildGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.active>(0))
def deriveChildNext (q : State) : State := {q with active:=(q.active+(1))}
def settleTaskGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.active>(0))
def settleTaskNext (q : State) : State := {q with active:=(q.active-(1))}
def closeRootsGuard (q : State) : Prop := (q.phase=(2))
def closeRootsNext (q : State) : State := {q with rootsClosed:=true}
def finishWeakGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.rootsClosed=true) ∧ (q.active=(0))
def finishWeakNext (q : State) : State := {q with phase:=(3)}
def cleanupGuard (q : State) : Prop := (q.phase=(3))
def cleanupNext (q : State) : State := {q with phase:=(4)}
def Step (q r : State) : Prop := (drainStrongGuard q ∧ r=drainStrongNext q) ∨ (freezeStrongGuard q ∧ r=freezeStrongNext q) ∨ (classifyAGuard q ∧ r=classifyANext q) ∨ (classifyBGuard q ∧ r=classifyBNext q) ∨ (openWeakGuard q ∧ r=openWeakNext q) ∨ (listProducerGuard q ∧ r=listProducerNext q) ∨ (repairProducerGuard q ∧ r=repairProducerNext q) ∨ (freshWillProducerGuard q ∧ r=freshWillProducerNext q) ∨ (graphProducerGuard q ∧ r=graphProducerNext q) ∨ (continuationProducerGuard q ∧ r=continuationProducerNext q) ∨ (stillProducerGuard q ∧ r=stillProducerNext q) ∨ (deriveChildGuard q ∧ r=deriveChildNext q) ∨ (settleTaskGuard q ∧ r=settleTaskNext q) ∨ (closeRootsGuard q ∧ r=closeRootsNext q) ∨ (finishWeakGuard q ∧ r=finishWeakNext q) ∨ (cleanupGuard q ∧ r=cleanupNext q) ∨ r=q
end WeakAdmissionAst
