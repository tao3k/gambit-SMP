import Std
namespace CohortRetirementAst
set_option maxRecDepth 10000
structure State where
 admission : Int
 lookup : Int
 worker : Int
 external : Int
 fault : Int
 closed : Int
 drained : Int
 joined : Int
 unknown : Int
 retired : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.admission≥(0)) ∧ (q.lookup≥(0)) ∧ (q.worker≥(0)) ∧ (q.external≥(0)) ∧ (q.fault≥(0)) ∧ (q.closed≥(0)) ∧ (q.drained≥(0)) ∧ (q.joined≥(0)) ∧ (q.unknown≥(0)) ∧ (q.retired≥(0)) ∧ (q.admission≤(1)) ∧ (q.lookup≤(1)) ∧ (q.worker≤(1)) ∧ (q.external≤(1)) ∧ (q.fault≤(1)) ∧ (q.closed≤(1)) ∧ (q.drained≤(1)) ∧ (q.joined≤(1)) ∧ (q.unknown≤(1)) ∧ (q.retired≤(1)) ∧ ((q.admission+q.closed)=(1)) ∧ ((q.lookup=(1)) → (q.retired=(0))) ∧ ((q.external=(1)) → (q.retired=(0))) ∧ ((q.fault=(1)) → ((q.worker=(1)) ∧ (q.drained=(0)) ∧ (q.joined=(0)) ∧ (q.retired=(0)))) ∧ ((q.drained=(1)) → ((q.closed=(1)) ∧ (q.lookup=(0)) ∧ (q.fault=(0)))) ∧ ((q.worker=(0)) → ((q.closed=(1)) ∧ (q.drained=(1)) ∧ (q.fault=(0)))) ∧ ((q.joined=(1)) → ((q.closed=(1)) ∧ (q.worker=(0)) ∧ (q.drained=(1)) ∧ (q.unknown=(0)))) ∧ ((q.retired=(1)) → ((q.closed=(1)) ∧ (q.drained=(1)) ∧ (q.joined=(1)) ∧ (q.lookup=(0)) ∧ (q.external=(0)) ∧ (q.fault=(0)) ∧ (q.worker=(0)) ∧ (q.unknown=(0)))))
def initial : State := {admission:=(1), lookup:=(0), worker:=(1), external:=(0), fault:=(0), closed:=(0), drained:=(0), joined:=(0), unknown:=(0), retired:=(0)}
def enterLookupGuard (q : State) : Prop := ((q.admission=(1)) ∧ (q.lookup=(0)))
def enterLookupNext (q : State) : State := {q with lookup:=(1)}
def exitLookupGuard (q : State) : Prop := (q.lookup=(1))
def exitLookupNext (q : State) : State := {q with lookup:=(0)}
def acquireExternalGuard (q : State) : Prop := ((q.admission=(1)) ∧ (q.external=(0)))
def acquireExternalNext (q : State) : State := {q with external:=(1)}
def returnExternalGuard (q : State) : Prop := (q.external=(1))
def returnExternalNext (q : State) : State := {q with external:=(0)}
def closeRosterGuard (q : State) : Prop := (q.admission=(1))
def closeRosterNext (q : State) : State := {q with admission:=(0), closed:=(1)}
def escapeScannerGuard (q : State) : Prop := (((q.worker=(1)) ∧ (q.fault=(0))) ∧ (q.drained=(0)))
def escapeScannerNext (q : State) : State := {q with fault:=(1)}
def collectiveDrainGuard (q : State) : Prop := (((((q.closed=(1)) ∧ (q.lookup=(0))) ∧ (q.fault=(0))) ∧ (q.worker=(1))) ∧ (q.drained=(0)))
def collectiveDrainNext (q : State) : State := {q with drained:=(1)}
def exitWorkerGuard (q : State) : Prop := ((((q.closed=(1)) ∧ (q.drained=(1))) ∧ (q.worker=(1))) ∧ (q.fault=(0)))
def exitWorkerNext (q : State) : State := {q with worker:=(0)}
def joinUnknownGuard (q : State) : Prop := (((q.closed=(1)) ∧ (q.joined=(0))) ∧ (q.unknown=(0)))
def joinUnknownNext (q : State) : State := {q with unknown:=(1)}
def joinKnownGuard (q : State) : Prop := ((((q.closed=(1)) ∧ (q.worker=(0))) ∧ (q.fault=(0))) ∧ (q.joined=(0)))
def joinKnownNext (q : State) : State := {q with joined:=(1), unknown:=(0)}
def retireDomainGuard (q : State) : Prop := ((((((((q.closed=(1)) ∧ (q.drained=(1))) ∧ (q.joined=(1))) ∧ (q.lookup=(0))) ∧ (q.external=(0))) ∧ (q.fault=(0))) ∧ (q.unknown=(0))) ∧ (q.retired=(0)))
def retireDomainNext (q : State) : State := {q with retired:=(1)}
def Step (q r : State) : Prop := (enterLookupGuard q ∧ r=enterLookupNext q) ∨ (exitLookupGuard q ∧ r=exitLookupNext q) ∨ (acquireExternalGuard q ∧ r=acquireExternalNext q) ∨ (returnExternalGuard q ∧ r=returnExternalNext q) ∨ (closeRosterGuard q ∧ r=closeRosterNext q) ∨ (escapeScannerGuard q ∧ r=escapeScannerNext q) ∨ (collectiveDrainGuard q ∧ r=collectiveDrainNext q) ∨ (exitWorkerGuard q ∧ r=exitWorkerNext q) ∨ (joinUnknownGuard q ∧ r=joinUnknownNext q) ∨ (joinKnownGuard q ∧ r=joinKnownNext q) ∨ (retireDomainGuard q ∧ r=retireDomainNext q) ∨ r=q
end CohortRetirementAst
