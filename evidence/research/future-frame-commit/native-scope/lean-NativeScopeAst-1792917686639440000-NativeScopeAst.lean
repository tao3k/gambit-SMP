import Std
namespace NativeScopeAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 generation : Int
 thread : Int
 cap : Int
 nested : Int
 gate : Int
 pending : Int
 unknown : Int
 pins : Int
 roots : Int
 descriptors : Int
 custodian : Int
 closedWorld : Int
 pub : Int
 view : Int
 rf : Int
 observed : Int
 floor0 : Int
 floor1 : Int
 handoffRelease : Int
 targetAcquired : Int
 returnRight : Int
 recorded : Int
 callGen : Int
 responseGen : Int
 rejected : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(3)) ∧ (q.generation≥(1)) ∧ (q.generation≤(2)) ∧ (q.thread≥(0)) ∧ (q.thread≤(1)) ∧ (q.cap≥(0)) ∧ (q.cap≤q.generation) ∧ (q.callGen≥(0)) ∧ (q.callGen≤q.generation) ∧ (q.custodian≥(0)) ∧ (q.custodian≤(3)) ∧ (q.responseGen≥(0)) ∧ (q.responseGen≤q.generation) ∧ (q.nested≥(0)) ∧ (q.nested≤(1)) ∧ (q.gate≥(0)) ∧ (q.gate≤(1)) ∧ (q.pending≥(0)) ∧ (q.pending≤(1)) ∧ (q.unknown≥(0)) ∧ (q.unknown≤(1)) ∧ (q.pins≥(0)) ∧ (q.pins≤(1)) ∧ (q.roots≥(0)) ∧ (q.roots≤(1)) ∧ (q.descriptors≥(0)) ∧ (q.descriptors≤(1)) ∧ (q.closedWorld≥(0)) ∧ (q.closedWorld≤(1)) ∧ (q.pub≥(0)) ∧ (q.pub≤(1)) ∧ (q.view≥(0)) ∧ (q.view≤(1)) ∧ (q.rf≥(0)) ∧ (q.rf≤(1)) ∧ (q.observed≥(0)) ∧ (q.observed≤(1)) ∧ (q.floor0≥(0)) ∧ (q.floor0≤(1)) ∧ (q.floor1≥(0)) ∧ (q.floor1≤(1)) ∧ (q.handoffRelease≥(0)) ∧ (q.handoffRelease≤(1)) ∧ (q.targetAcquired≥(0)) ∧ (q.targetAcquired≤(1)) ∧ (q.returnRight≥(0)) ∧ (q.returnRight≤(1)) ∧ (q.recorded≥(0)) ∧ (q.recorded≤(1)) ∧ (q.rejected≥(0)) ∧ (q.rejected≤(1)) ∧ (q.unknown≤q.pending) ∧ ((q.phase≠(3)) → ((q.pins=(1)) ∧ (q.roots=(1)) ∧ (q.descriptors=(1)) ∧ (q.custodian≥(1)))) ∧ ((q.unknown=(1)) → ((q.phase=(1)) ∧ (q.custodian=(2)) ∧ (q.cap=(0)) ∧ (q.view=(0)))) ∧ ((q.pending=(1)) → (q.phase=(1))) ∧ ((q.nested=(1)) → (q.phase=(1))) ∧ ((q.view=(1)) → ((q.phase=(1)) ∧ (q.cap=q.generation) ∧ (q.pub=(1)) ∧ (q.rf=(1)) ∧ (q.observed=(1)) ∧ (q.closedWorld=(1)) ∧ (q.unknown=(0)))) ∧ ((q.phase=(2)) → ((q.pending=(0)) ∧ (q.nested=(0)) ∧ (q.cap=(0)) ∧ (q.returnRight=(0)) ∧ (q.handoffRelease=(1)))) ∧ ((q.thread=(1)) → ((q.generation=(2)) ∧ (q.targetAcquired=(1)) ∧ (q.returnRight=(0)))) ∧ ((q.phase=(3)) → ((q.gate=(1)) ∧ (q.pending=(0)) ∧ (q.nested=(0)) ∧ (q.pins=(0)) ∧ (q.roots=(0)) ∧ (q.descriptors=(0)) ∧ (q.cap=(0)) ∧ (q.custodian=(0)) ∧ (q.view=(0)))) ∧ ((q.closedWorld=(0)) → ((q.phase=(1)) ∧ (q.gate=(1)) ∧ (q.pending=(0)) ∧ (q.nested=(0)) ∧ (q.view=(0)) ∧ (q.cap=(0)))))
def initial : State := {phase:=(0), generation:=(1), thread:=(0), cap:=(0), nested:=(0), gate:=(0), pending:=(0), unknown:=(0), pins:=(1), roots:=(1), descriptors:=(1), custodian:=(1), closedWorld:=(1), pub:=(0), view:=(0), rf:=(0), observed:=(0), floor0:=(0), floor1:=(0), handoffRelease:=(0), targetAcquired:=(0), returnRight:=(1), recorded:=(0), callGen:=(0), responseGen:=(0), rejected:=(0)}
def issueGuard (q : State) : Prop := ((((q.phase=(0)) ∧ (q.closedWorld=(1))) ∧ (q.roots=(1))) ∧ (q.pins=(1)))
def issueNext (q : State) : State := {q with phase:=(1), cap:=q.generation}
def beginWriteGuard (q : State) : Prop := ((((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.gate=(0))) ∧ (q.pending=(0))) ∧ (q.nested=(0)))
def beginWriteNext (q : State) : State := {q with pending:=(1), callGen:=q.generation, recorded:=(0), view:=(0), rf:=(0), observed:=(0)}
def publishReleaseGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.pending=(1))) ∧ (q.pub=(0)))
def publishReleaseNext (q : State) : State := {q with pub:=(1)}
def recordOutcomeGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.pending=(1))) ∧ (q.recorded=(0)))
def recordOutcomeNext (q : State) : State := {q with recorded:=(1), responseGen:=q.callGen}
def deliverOutcomeGuard (q : State) : Prop := ((((((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.pending=(1))) ∧ (q.recorded=(1))) ∧ (q.nested=(0))) ∧ (q.callGen=q.generation)) ∧ (q.responseGen=q.callGen))
def deliverOutcomeNext (q : State) : State := {q with pending:=(0)}
def loseResponseGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.pending=(1))) ∧ (q.unknown=(0)))
def loseResponseNext (q : State) : State := {q with unknown:=(1), custodian:=(2), cap:=(0), view:=(0), rf:=(0), observed:=(0)}
def recoverRecordedGuard (q : State) : Prop := ((((((q.phase=(1)) ∧ (q.unknown=(1))) ∧ (q.recorded=(1))) ∧ (q.nested=(0))) ∧ (q.callGen=q.generation)) ∧ (q.responseGen=q.callGen))
def recoverRecordedNext (q : State) : State := {q with unknown:=(0), pending:=(0), custodian:=(1), cap:=q.generation}
def enterNestedGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.gate=(0))) ∧ (q.nested=(0)))
def enterNestedNext (q : State) : State := {q with nested:=(1), view:=(0), rf:=(0), observed:=(0)}
def leaveNestedGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.nested=(1)))
def leaveNestedNext (q : State) : State := {q with nested:=(0)}
def catcherSubtreeGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.nested=(1))) ∧ (q.unknown=(1)))
def catcherSubtreeNext (q : State) : State := {q with nested:=(0)}
def acquire0Guard (q : State) : Prop := (((((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.thread=(0))) ∧ (q.pub=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0)))
def acquire0Next (q : State) : State := {q with view:=(1), cap:=q.generation, rf:=(1), observed:=(1), floor0:=(1)}
def acquire1Guard (q : State) : Prop := (((((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.thread=(1))) ∧ (q.pub=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0)))
def acquire1Next (q : State) : State := {q with view:=(1), cap:=q.generation, rf:=(1), observed:=(1), floor1:=(1)}
def closeAdmissionGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.gate=(0)))
def closeAdmissionNext (q : State) : State := {q with gate:=(1)}
def renewSameThreadGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0)))
def renewSameThreadNext (q : State) : State := {q with view:=(0), rf:=(0), observed:=(0)}
def prepareMigrationGuard (q : State) : Prop := ((((((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.thread=(0))) ∧ (q.generation=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0))) ∧ (q.gate=(0)))
def prepareMigrationNext (q : State) : State := {q with phase:=(2), generation:=(2), cap:=(0), view:=(0), rf:=(0), observed:=(0), returnRight:=(0), handoffRelease:=(1)}
def targetAcquireGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.handoffRelease=(1))) ∧ (q.targetAcquired=(0)))
def targetAcquireNext (q : State) : State := {q with thread:=(1), targetAcquired:=(1)}
def issueTargetGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.targetAcquired=(1))) ∧ (q.thread=(1)))
def issueTargetNext (q : State) : State := {q with phase:=(1), cap:=q.generation, custodian:=(3)}
def rejectStaleDeliveryGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.thread=(1))) ∧ (q.responseGen=(1))) ∧ (q.generation=(2))) ∧ (q.rejected=(0)))
def rejectStaleDeliveryNext (q : State) : State := {q with rejected:=(1)}
def rawInterferenceGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.unknown=(0))) ∧ (q.closedWorld=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0)))
def rawInterferenceNext (q : State) : State := {q with closedWorld:=(0), gate:=(1), cap:=(0), view:=(0), rf:=(0), observed:=(0)}
def retireGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.gate=(1))) ∧ (q.pending=(0))) ∧ (q.nested=(0))) ∧ (q.closedWorld=(1)))
def retireNext (q : State) : State := {q with phase:=(3), pins:=(0), roots:=(0), descriptors:=(0), cap:=(0), view:=(0), rf:=(0), observed:=(0), custodian:=(0), returnRight:=(0)}
def Step (q r : State) : Prop := (issueGuard q ∧ r=issueNext q) ∨ (beginWriteGuard q ∧ r=beginWriteNext q) ∨ (publishReleaseGuard q ∧ r=publishReleaseNext q) ∨ (recordOutcomeGuard q ∧ r=recordOutcomeNext q) ∨ (deliverOutcomeGuard q ∧ r=deliverOutcomeNext q) ∨ (loseResponseGuard q ∧ r=loseResponseNext q) ∨ (recoverRecordedGuard q ∧ r=recoverRecordedNext q) ∨ (enterNestedGuard q ∧ r=enterNestedNext q) ∨ (leaveNestedGuard q ∧ r=leaveNestedNext q) ∨ (catcherSubtreeGuard q ∧ r=catcherSubtreeNext q) ∨ (acquire0Guard q ∧ r=acquire0Next q) ∨ (acquire1Guard q ∧ r=acquire1Next q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (renewSameThreadGuard q ∧ r=renewSameThreadNext q) ∨ (prepareMigrationGuard q ∧ r=prepareMigrationNext q) ∨ (targetAcquireGuard q ∧ r=targetAcquireNext q) ∨ (issueTargetGuard q ∧ r=issueTargetNext q) ∨ (rejectStaleDeliveryGuard q ∧ r=rejectStaleDeliveryNext q) ∨ (rawInterferenceGuard q ∧ r=rawInterferenceNext q) ∨ (retireGuard q ∧ r=retireNext q) ∨ r=q
end NativeScopeAst
