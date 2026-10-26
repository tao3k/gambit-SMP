import Std
namespace PrimitiveHeaderAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 demand : Int
 headerDemand : Int
 member : Bool
 prm : Bool
 glo : Bool
 spec : Bool
 coverage : Bool
 closed : Bool
 receipt : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(6)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.headerDemand≥(0)) ∧ (q.headerDemand≤(2)) ∧ ((q.phase≥(1)) → (q.member=true)) ∧ ((q.prm=true) → ((q.phase≥(2)) ∧ (q.demand=(1)))) ∧ ((q.phase≥(2)) → (q.prm=true)) ∧ ((q.glo=true) → ((q.phase≥(3)) ∧ (q.prm=true))) ∧ ((q.phase≥(3)) → (q.glo=true)) ∧ ((q.spec=true) → ((q.phase≥(4)) ∧ (q.glo=true))) ∧ ((q.phase≥(4)) → (q.spec=true)) ∧ ((q.coverage=true) → (q.spec=true)) ∧ ((q.closed=true) → (q.spec=true)) ∧ ((q.receipt=true) → (((q.phase=(5)) ∧ (q.coverage=true)) ∧ (q.closed=true))) ∧ ((q.phase=(5)) → (q.receipt=true)))
def initial : State := {phase:=(0), demand:=(0), headerDemand:=(0), member:=false, prm:=false, glo:=false, spec:=false, coverage:=false, closed:=false, receipt:=false}
def seedSupplyGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.member=true))
def seedSupplyNext (q : State) : State := {q with member:=true}
def seedDemandGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.member=true)
def seedDemandNext (q : State) : State := {q with demand:=(1)}
def seedOtherDemandGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.member=true)
def seedOtherDemandNext (q : State) : State := {q with demand:=(2)}
def writeHeaderGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.member=true)
def writeHeaderNext (q : State) : State := {q with phase:=(1), headerDemand:=q.demand}
def emitPrmGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.member=true)
def emitPrmNext (q : State) : State := {q with phase:=(2), prm:=true, demand:=(1)}
def emitGloGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.prm=true)
def emitGloNext (q : State) : State := {q with phase:=(3), glo:=true, demand:=(1)}
def sealSpecGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.glo=true)
def sealSpecNext (q : State) : State := {q with phase:=(4), spec:=true}
def checkCoverageGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.spec=true)
def checkCoverageNext (q : State) : State := {q with coverage:=true}
def closePairGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.spec=true)
def closePairNext (q : State) : State := {q with closed:=true}
def issueGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.coverage=true) ∧ True
def issueNext (q : State) : State := {q with phase:=(5), receipt:=true}
def unknownOutputGuard (q : State) : Prop := (q.phase=(4))
def unknownOutputNext (q : State) : State := {q with phase:=(6)}
def rejectLateUseGuard (q : State) : Prop := (q.phase≥(1))
def rejectLateUseNext (q : State) : State := {q with demand:=q.demand}
def Step (q r : State) : Prop := (seedSupplyGuard q ∧ r=seedSupplyNext q) ∨ (seedDemandGuard q ∧ r=seedDemandNext q) ∨ (seedOtherDemandGuard q ∧ r=seedOtherDemandNext q) ∨ (writeHeaderGuard q ∧ r=writeHeaderNext q) ∨ (emitPrmGuard q ∧ r=emitPrmNext q) ∨ (emitGloGuard q ∧ r=emitGloNext q) ∨ (sealSpecGuard q ∧ r=sealSpecNext q) ∨ (checkCoverageGuard q ∧ r=checkCoverageNext q) ∨ (closePairGuard q ∧ r=closePairNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (unknownOutputGuard q ∧ r=unknownOutputNext q) ∨ (rejectLateUseGuard q ∧ r=rejectLateUseNext q) ∨ r=q
end PrimitiveHeaderAst
