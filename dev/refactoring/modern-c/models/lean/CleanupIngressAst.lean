import Std
namespace CleanupIngressAst
set_option maxRecDepth 10000
structure State where
 gate : Int
 outer : Int
 child : Int
 permit : Int
 closed : Int
 guard : Int
 roots : Int
 settled : Int
 resultDebt : Int
 unknown : Int
 collective : Int
 joined : Int
 retired : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.gate≥(0)) ∧ (q.outer≥(0)) ∧ (q.child≥(0)) ∧ (q.permit≥(0)) ∧ (q.closed≥(0)) ∧ (q.guard≥(0)) ∧ (q.roots≥(0)) ∧ (q.settled≥(0)) ∧ (q.resultDebt≥(0)) ∧ (q.unknown≥(0)) ∧ (q.collective≥(0)) ∧ (q.joined≥(0)) ∧ (q.retired≥(0)) ∧ (q.gate≤(1)) ∧ (q.outer≤(1)) ∧ (q.child≤(1)) ∧ (q.permit≤(1)) ∧ (q.closed≤(1)) ∧ (q.guard≤(1)) ∧ (q.roots≤(1)) ∧ (q.settled≤(1)) ∧ (q.resultDebt≤(1)) ∧ (q.unknown≤(2)) ∧ (q.collective≤(1)) ∧ (q.joined≤(1)) ∧ (q.retired≤(1)) ∧ ((q.gate+q.closed)=(1)) ∧ ((q.outer+q.settled)=(1)) ∧ (q.guard=q.outer) ∧ (q.roots=q.outer) ∧ ((q.child=(1)) → (q.outer=(1))) ∧ ((q.permit=(1)) → (q.outer=(1))) ∧ ((q.child+q.permit)≤(1)) ∧ ((q.unknown=(1)) → (q.outer=(1))) ∧ ((q.unknown=(2)) → ((q.collective=(1)) ∧ (q.joined=(0)))) ∧ ((q.collective=(1)) → ((q.closed=(1)) ∧ (q.outer=(0)) ∧ (q.child=(0)) ∧ (q.permit=(0)) ∧ (q.guard=(0)) ∧ (q.roots=(0)) ∧ (q.settled=(1)))) ∧ ((q.joined=(1)) → ((q.collective=(1)) ∧ (q.unknown=(0)))) ∧ ((q.retired=(1)) → ((q.closed=(1)) ∧ (q.outer=(0)) ∧ (q.child=(0)) ∧ (q.permit=(0)) ∧ (q.guard=(0)) ∧ (q.roots=(0)) ∧ (q.settled=(1)) ∧ (q.resultDebt=(0)) ∧ (q.unknown=(0)) ∧ (q.collective=(1)) ∧ (q.joined=(1)))) ∧ ((q.resultDebt=(1)) → (q.retired=(0))))
def initial : State := {gate:=(1), outer:=(1), child:=(0), permit:=(0), closed:=(0), guard:=(1), roots:=(1), settled:=(0), resultDebt:=(0), unknown:=(0), collective:=(0), joined:=(0), retired:=(0)}
def reserveChildGuard (q : State) : Prop := (((((q.gate=(1)) ∧ (q.outer=(1))) ∧ (q.permit=(0))) ∧ (q.child=(0))) ∧ (q.unknown=(0)))
def reserveChildNext (q : State) : State := {q with permit:=(1)}
def enterChildGuard (q : State) : Prop := ((((q.permit=(1)) ∧ (q.outer=(1))) ∧ (q.child=(0))) ∧ (q.unknown=(0)))
def enterChildNext (q : State) : State := {q with permit:=(0), child:=(1)}
def returnChildGuard (q : State) : Prop := ((q.child=(1)) ∧ (q.unknown=(0)))
def returnChildNext (q : State) : State := {q with child:=(0)}
def cancelPermitGuard (q : State) : Prop := ((q.permit=(1)) ∧ (q.unknown=(0)))
def cancelPermitNext (q : State) : State := {q with permit:=(0)}
def requestCloseGuard (q : State) : Prop := (q.closed=(0))
def requestCloseNext (q : State) : State := {q with gate:=(0), closed:=(1)}
def loseBoundaryGuard (q : State) : Prop := ((q.outer=(1)) ∧ (q.unknown=(0)))
def loseBoundaryNext (q : State) : State := {q with unknown:=(1)}
def recoverLandingGuard (q : State) : Prop := ((q.unknown=(1)) ∧ (q.outer=(1)))
def recoverLandingNext (q : State) : State := {q with unknown:=(0)}
def exportResultGuard (q : State) : Prop := (((q.outer=(1)) ∧ (q.unknown=(0))) ∧ (q.resultDebt=(0)))
def exportResultNext (q : State) : State := {q with resultDebt:=(1)}
def releaseResultGuard (q : State) : Prop := (q.resultDebt=(1))
def releaseResultNext (q : State) : State := {q with resultDebt:=(0)}
def finishOuterGuard (q : State) : Prop := (((((q.outer=(1)) ∧ (q.child=(0))) ∧ (q.permit=(0))) ∧ (q.unknown=(0))) ∧ (q.settled=(0)))
def finishOuterNext (q : State) : State := {q with outer:=(0), guard:=(0), roots:=(0), settled:=(1)}
def drainCollectiveGuard (q : State) : Prop := ((((((q.closed=(1)) ∧ (q.outer=(0))) ∧ (q.child=(0))) ∧ (q.permit=(0))) ∧ (q.unknown=(0))) ∧ (q.collective=(0)))
def drainCollectiveNext (q : State) : State := {q with collective:=(1)}
def joinUnknownGuard (q : State) : Prop := (((q.collective=(1)) ∧ (q.joined=(0))) ∧ (q.unknown=(0)))
def joinUnknownNext (q : State) : State := {q with unknown:=(2)}
def joinKnownGuard (q : State) : Prop := (((q.collective=(1)) ∧ (q.joined=(0))) ∧ ((q.unknown=(0)) ∨ (q.unknown=(2))))
def joinKnownNext (q : State) : State := {q with joined:=(1), unknown:=(0)}
def retireDomainGuard (q : State) : Prop := ((((((((((((q.closed=(1)) ∧ (q.outer=(0))) ∧ (q.child=(0))) ∧ (q.permit=(0))) ∧ (q.guard=(0))) ∧ (q.roots=(0))) ∧ (q.settled=(1))) ∧ (q.resultDebt=(0))) ∧ (q.unknown=(0))) ∧ (q.collective=(1))) ∧ (q.joined=(1))) ∧ (q.retired=(0)))
def retireDomainNext (q : State) : State := {q with retired:=(1)}
def Step (q r : State) : Prop := (reserveChildGuard q ∧ r=reserveChildNext q) ∨ (enterChildGuard q ∧ r=enterChildNext q) ∨ (returnChildGuard q ∧ r=returnChildNext q) ∨ (cancelPermitGuard q ∧ r=cancelPermitNext q) ∨ (requestCloseGuard q ∧ r=requestCloseNext q) ∨ (loseBoundaryGuard q ∧ r=loseBoundaryNext q) ∨ (recoverLandingGuard q ∧ r=recoverLandingNext q) ∨ (exportResultGuard q ∧ r=exportResultNext q) ∨ (releaseResultGuard q ∧ r=releaseResultNext q) ∨ (finishOuterGuard q ∧ r=finishOuterNext q) ∨ (drainCollectiveGuard q ∧ r=drainCollectiveNext q) ∨ (joinUnknownGuard q ∧ r=joinUnknownNext q) ∨ (joinKnownGuard q ∧ r=joinKnownNext q) ∨ (retireDomainGuard q ∧ r=retireDomainNext q) ∨ r=q
end CleanupIngressAst
