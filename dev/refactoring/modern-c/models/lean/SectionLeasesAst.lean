import Std
namespace SectionLeasesAst
set_option maxRecDepth 10000
structure State where
 n : Int
 p : Int
 cursor : Int
 fresh : Int
 shared : Int
 visits : Int
 owner4 : Int
 owner5 : Int
 heap0 : Int
 heap1 : Int
 denied : Int
 shared0 : Bool
 shared1 : Bool
 certified : Bool
 retained : Bool
 closed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.n=(6)) ∧ (q.p=(2)) ∧ (q.cursor≥(4)) ∧ (q.cursor≤(6)) ∧ (q.fresh=(q.cursor-(4))) ∧ (q.shared≥(0)) ∧ (q.shared≤(2)) ∧ (q.visits=(((2)+q.fresh)+q.shared)) ∧ (q.denied≥(0)) ∧ (q.owner4≥(-(1))) ∧ (q.owner4≤(1)) ∧ (q.owner5≥(-(1))) ∧ (q.owner5≤(1)) ∧ ((q.cursor=(4)) → ((q.owner4=(-(1))) ∧ (q.owner5=(-(1))))) ∧ ((q.cursor=(5)) → ((q.owner4≥(0)) ∧ (q.owner5=(-(1))))) ∧ ((q.cursor=(6)) → ((q.owner4≥(0)) ∧ (q.owner5≥(0)))) ∧ (((¬(q.shared0=true)) ∧ (¬(q.shared1=true))) → (q.shared=(0))) ∧ (((q.shared0=true) ∧ (¬(q.shared1=true))) → (q.shared=(1))) ∧ (((¬(q.shared0=true)) ∧ (q.shared1=true)) → (q.shared=(1))) ∧ (((q.shared0=true) ∧ (q.shared1=true)) → (q.shared=(2))) ∧ ((((q.heap0=(0)) ∨ (q.heap0=(1))) ∨ (q.heap0=(4))) ∨ (q.heap0=(5))) ∧ ((((q.heap1=(2)) ∨ (q.heap1=(3))) ∨ (q.heap1=(4))) ∨ (q.heap1=(5))) ∧ ((q.heap0=(0)) → (q.shared0=true)) ∧ ((q.shared0=true) → (q.heap0=(0))) ∧ ((q.heap1=(2)) → (q.shared1=true)) ∧ ((q.shared1=true) → (q.heap1=(2))) ∧ ((q.heap0=(4)) → (q.owner4=(0))) ∧ ((q.heap1=(4)) → (q.owner4=(1))) ∧ ((q.heap0=(5)) → (q.owner5=(0))) ∧ ((q.heap1=(5)) → (q.owner5=(1))) ∧ ((q.shared0=true) → (q.cursor=(6))) ∧ ((q.shared1=true) → (q.cursor=(6))) ∧ ((q.closed=true) → (¬(q.certified=true))) ∧ ((q.retained=true) → (¬(q.certified=true))))
def initial : State := {n:=(6), p:=(2), cursor:=(4), fresh:=(0), shared:=(0), visits:=(2), owner4:=(-(1)), owner5:=(-(1)), heap0:=(1), heap1:=(3), denied:=(0), shared0:=false, shared1:=false, certified:=true, retained:=false, closed:=false}
def fresh4worker0Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(4)) ∧ (¬(q.shared0=true))
def fresh4worker0Next (q : State) : State := {q with cursor:=(5), fresh:=(q.fresh+(1)), visits:=(q.visits+(1)), owner4:=(0), heap0:=(4)}
def fresh4worker1Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(4)) ∧ (¬(q.shared1=true))
def fresh4worker1Next (q : State) : State := {q with cursor:=(5), fresh:=(q.fresh+(1)), visits:=(q.visits+(1)), owner4:=(1), heap1:=(4)}
def fresh5worker0Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(5)) ∧ (¬(q.shared0=true))
def fresh5worker0Next (q : State) : State := {q with cursor:=(6), fresh:=(q.fresh+(1)), visits:=(q.visits+(1)), owner5:=(0), heap0:=(5)}
def fresh5worker1Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(5)) ∧ (¬(q.shared1=true))
def fresh5worker1Next (q : State) : State := {q with cursor:=(6), fresh:=(q.fresh+(1)), visits:=(q.visits+(1)), owner5:=(1), heap1:=(5)}
def shareWorker0Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(6)) ∧ (¬(q.shared0=true))
def shareWorker0Next (q : State) : State := {q with shared0:=true, heap0:=(0), shared:=(q.shared+(1)), visits:=(q.visits+(1))}
def shareWorker1Guard (q : State) : Prop := (q.certified=true) ∧ (q.cursor=(6)) ∧ (¬(q.shared1=true))
def shareWorker1Next (q : State) : State := {q with shared1:=true, heap1:=(2), shared:=(q.shared+(1)), visits:=(q.visits+(1))}
def denyStackRebindGuard (q : State) : Prop := (q.certified=true)
def denyStackRebindNext (q : State) : State := {q with denied:=(q.denied+(1))}
def denyGrowGuard (q : State) : Prop := (q.certified=true)
def denyGrowNext (q : State) : State := {q with denied:=(q.denied+(1))}
def denyReentryGuard (q : State) : Prop := (q.certified=true)
def denyReentryNext (q : State) : State := {q with denied:=(q.denied+(1))}
def unknownWriterGuard (q : State) : Prop := (q.certified=true)
def unknownWriterNext (q : State) : State := {q with certified:=false, retained:=true}
def exhaustedShared0Guard (q : State) : Prop := (q.certified=true) ∧ (q.shared0=true)
def exhaustedShared0Next (q : State) : State := {q with certified:=false, retained:=true}
def closeAllocatorsGuard (q : State) : Prop := (q.certified=true)
def closeAllocatorsNext (q : State) : State := {q with closed:=true, certified:=false}
def Step (q r : State) : Prop := (fresh4worker0Guard q ∧ r=fresh4worker0Next q) ∨ (fresh4worker1Guard q ∧ r=fresh4worker1Next q) ∨ (fresh5worker0Guard q ∧ r=fresh5worker0Next q) ∨ (fresh5worker1Guard q ∧ r=fresh5worker1Next q) ∨ (shareWorker0Guard q ∧ r=shareWorker0Next q) ∨ (shareWorker1Guard q ∧ r=shareWorker1Next q) ∨ (denyStackRebindGuard q ∧ r=denyStackRebindNext q) ∨ (denyGrowGuard q ∧ r=denyGrowNext q) ∨ (denyReentryGuard q ∧ r=denyReentryNext q) ∨ (unknownWriterGuard q ∧ r=unknownWriterNext q) ∨ (exhaustedShared0Guard q ∧ r=exhaustedShared0Next q) ∨ (closeAllocatorsGuard q ∧ r=closeAllocatorsNext q) ∨ r=q
end SectionLeasesAst
