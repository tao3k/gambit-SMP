import Std
namespace RcReaderGraceAst
set_option maxRecDepth 10000
structure State where
 admission : Int
 lookup : Int
 claimed : Int
 done : Int
 domainLive : Int
 registered : Int
 scan : Int
 saved : Int
 diagLease : Int
 diagGate : Int
 fault : Int
 escrow : Int
 retired : Int
 denied : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.admission≥(0)) ∧ (q.lookup≥(0)) ∧ (q.claimed≥(0)) ∧ (q.done≥(0)) ∧ (q.domainLive≥(0)) ∧ (q.registered≥(0)) ∧ (q.scan≥(0)) ∧ (q.saved≥(0)) ∧ (q.diagLease≥(0)) ∧ (q.diagGate≥(0)) ∧ (q.fault≥(0)) ∧ (q.escrow≥(0)) ∧ (q.retired≥(0)) ∧ (q.denied≥(0)) ∧ (q.admission≤(1)) ∧ (q.lookup≤(1)) ∧ (q.claimed≤(1)) ∧ (q.done≤(1)) ∧ (q.domainLive≤(1)) ∧ (q.registered≤(1)) ∧ (q.scan≤(1)) ∧ (q.saved≤(1)) ∧ (q.diagLease≤(1)) ∧ (q.diagGate≤(1)) ∧ (q.fault≤(1)) ∧ (q.escrow≤(1)) ∧ (q.retired≤(1)) ∧ (q.denied≤(1)) ∧ ((q.scan=(1)) → ((q.claimed=(1)) ∧ (q.registered=(1)) ∧ (q.domainLive=(1)))) ∧ (q.saved=q.fault) ∧ (q.escrow=q.fault) ∧ ((q.fault=(1)) → ((q.scan=(1)) ∧ (q.claimed=(1)) ∧ (q.registered=(1)) ∧ (q.domainLive=(1)))) ∧ ((q.diagLease=(1)) → ((q.saved=(1)) ∧ (q.domainLive=(1)))) ∧ ((q.lookup=(1)) → (q.domainLive=(1))) ∧ ((q.claimed=(1)) → ((q.domainLive=(1)) ∧ (q.done=(0)))) ∧ ((q.done=(1)) → ((q.claimed=(0)) ∧ (q.scan=(0)) ∧ (q.fault=(0)))) ∧ ((q.admission=(1)) → (q.domainLive=(1))) ∧ ((q.domainLive=(0)) → ((q.admission=(0)) ∧ (q.lookup=(0)) ∧ (q.claimed=(0)) ∧ (q.scan=(0)) ∧ (q.fault=(0)) ∧ (q.registered=(0)) ∧ (q.diagLease=(0)) ∧ (q.diagGate=(0)) ∧ (q.done=(1)) ∧ (q.retired=(1)))) ∧ ((q.retired=(1)) → (q.domainLive=(0))))
def initial : State := {admission:=(1), lookup:=(0), claimed:=(0), done:=(0), domainLive:=(1), registered:=(1), scan:=(0), saved:=(0), diagLease:=(0), diagGate:=(1), fault:=(0), escrow:=(0), retired:=(0), denied:=(0)}
def enterLookupGuard (q : State) : Prop := (((q.admission=(1)) ∧ (q.lookup=(0))) ∧ (q.domainLive=(1)))
def enterLookupNext (q : State) : State := {q with lookup:=(1)}
def claimLookupGuard (q : State) : Prop := (((q.lookup=(1)) ∧ (q.done=(0))) ∧ (q.claimed=(0)))
def claimLookupNext (q : State) : State := {q with lookup:=(0), claimed:=(1)}
def failClaimGuard (q : State) : Prop := ((q.lookup=(1)) ∧ ((q.done=(1)) ∨ (q.claimed=(1))))
def failClaimNext (q : State) : State := {q with lookup:=(0)}
def completeClaimGuard (q : State) : Prop := (((q.claimed=(1)) ∧ (q.scan=(0))) ∧ (q.fault=(0)))
def completeClaimNext (q : State) : State := {q with claimed:=(0), done:=(1)}
def closeAdmissionGuard (q : State) : Prop := (q.admission=(1))
def closeAdmissionNext (q : State) : State := {q with admission:=(0)}
def rejectLateGuard (q : State) : Prop := ((q.admission=(0)) ∧ (q.denied=(0)))
def rejectLateNext (q : State) : State := {q with denied:=(1)}
def beginScanGuard (q : State) : Prop := ((((q.claimed=(1)) ∧ (q.registered=(1))) ∧ (q.scan=(0))) ∧ (q.fault=(0)))
def beginScanNext (q : State) : State := {q with scan:=(1)}
def endScanGuard (q : State) : Prop := ((q.scan=(1)) ∧ (q.fault=(0)))
def endScanNext (q : State) : State := {q with scan:=(0)}
def saveDiagnosticGuard (q : State) : Prop := (((q.scan=(1)) ∧ (q.saved=(0))) ∧ (q.fault=(0)))
def saveDiagnosticNext (q : State) : State := {q with saved:=(1), fault:=(1), escrow:=(1)}
def borrowDiagnosticGuard (q : State) : Prop := ((((q.saved=(1)) ∧ (q.diagGate=(1))) ∧ (q.diagLease=(0))) ∧ (q.domainLive=(1)))
def borrowDiagnosticNext (q : State) : State := {q with diagLease:=(1)}
def returnDiagnosticGuard (q : State) : Prop := (q.diagLease=(1))
def returnDiagnosticNext (q : State) : State := {q with diagLease:=(0)}
def closeDiagnosticGuard (q : State) : Prop := (q.diagGate=(1))
def closeDiagnosticNext (q : State) : State := {q with diagGate:=(0)}
def unlinkNodeGuard (q : State) : Prop := (((q.registered=(1)) ∧ (q.scan=(0))) ∧ (q.fault=(0)))
def unlinkNodeNext (q : State) : State := {q with registered:=(0)}
def retireDomainGuard (q : State) : Prop := ((((((((((q.admission=(0)) ∧ (q.lookup=(0))) ∧ (q.claimed=(0))) ∧ (q.done=(1))) ∧ (q.scan=(0))) ∧ (q.fault=(0))) ∧ (q.registered=(0))) ∧ (q.diagLease=(0))) ∧ (q.diagGate=(0))) ∧ (q.domainLive=(1)))
def retireDomainNext (q : State) : State := {q with domainLive:=(0), retired:=(1)}
def Step (q r : State) : Prop := (enterLookupGuard q ∧ r=enterLookupNext q) ∨ (claimLookupGuard q ∧ r=claimLookupNext q) ∨ (failClaimGuard q ∧ r=failClaimNext q) ∨ (completeClaimGuard q ∧ r=completeClaimNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (rejectLateGuard q ∧ r=rejectLateNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (saveDiagnosticGuard q ∧ r=saveDiagnosticNext q) ∨ (borrowDiagnosticGuard q ∧ r=borrowDiagnosticNext q) ∨ (returnDiagnosticGuard q ∧ r=returnDiagnosticNext q) ∨ (closeDiagnosticGuard q ∧ r=closeDiagnosticNext q) ∨ (unlinkNodeGuard q ∧ r=unlinkNodeNext q) ∨ (retireDomainGuard q ∧ r=retireDomainNext q) ∨ r=q
end RcReaderGraceAst
