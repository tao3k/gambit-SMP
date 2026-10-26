import Std
namespace EscrowCriticalTailAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 free : Int
 slot : Int
 external : Int
 registered : Int
 queued : Int
 cancel : Int
 supervisor : Int
 lock : Int
 pin : Int
 tailQualified : Int
 nodeReceipt : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.stage≥(0)) ∧ (q.free≥(0)) ∧ (q.slot≥(0)) ∧ (q.external≥(0)) ∧ (q.registered≥(0)) ∧ (q.queued≥(0)) ∧ (q.cancel≥(0)) ∧ (q.supervisor≥(0)) ∧ (q.lock≥(0)) ∧ (q.pin≥(0)) ∧ (q.tailQualified≥(0)) ∧ (q.nodeReceipt≥(0)) ∧ (q.stage≤(9)) ∧ (q.free≤(1)) ∧ (q.slot≤(1)) ∧ (q.external≤(1)) ∧ (q.registered≤(2)) ∧ (q.queued≤(1)) ∧ (q.cancel≤(3)) ∧ (q.supervisor≤(1)) ∧ (q.lock≤(2)) ∧ (q.pin≤(2)) ∧ (q.tailQualified≤(1)) ∧ (q.nodeReceipt≤(1)) ∧ (((q.free+q.slot)+q.external)=(1)) ∧ ((q.stage=(0)) → ((q.slot=(0)) ∧ (q.registered=(0)) ∧ (q.queued=(1)))) ∧ ((q.stage=(1)) → ((q.slot=(1)) ∧ (q.registered=(0)) ∧ (q.queued=(1)) ∧ (q.cancel=(1)))) ∧ ((q.stage=(2)) → ((q.slot=(1)) ∧ ((q.registered=(1)) ∨ (q.registered=(2))) ∧ (q.queued=(1)) ∧ (q.cancel=(1)))) ∧ (((q.stage≥(3)) ∧ (q.stage≤(8))) → ((q.slot=(1)) ∧ (q.registered=(1)) ∧ (q.queued=(0)))) ∧ (((q.stage≥(3)) ∧ (q.stage≤(7))) → (q.cancel=(1))) ∧ ((q.stage=(9)) → ((q.slot=(0)) ∧ (q.registered=(0)) ∧ (q.queued=(0)) ∧ (q.cancel=(3)) ∧ (q.supervisor=(0)) ∧ (q.lock=(0)) ∧ (q.pin=(0)))) ∧ ((q.registered≥(1)) → (q.slot=(1))) ∧ ((q.lock≥(1)) → ((q.cancel=(1)) ∧ (q.registered=(1)) ∧ (q.slot=(1)))) ∧ ((q.pin≥(1)) → ((q.registered=(1)) ∧ (q.slot=(1)) ∧ (q.cancel=(1)))) ∧ ((q.pin=(2)) → (q.lock=(2))) ∧ ((q.tailQualified=(1)) → (q.stage≥(5))) ∧ ((q.nodeReceipt=(1)) → (q.stage≥(7))) ∧ ((q.stage≥(7)) → (q.nodeReceipt=(1))) ∧ ((q.supervisor=(1)) → (q.stage=(8))) ∧ ((q.cancel≥(2)) → ((q.stage≥(8)) ∧ (q.lock=(0)) ∧ (q.pin=(0)))) ∧ ((q.cancel=(2)) → ((q.stage=(8)) ∧ (q.supervisor=(1)) ∧ (q.slot=(1)) ∧ (q.registered=(1)))))
def initial : State := {stage:=(0), free:=(1), slot:=(0), external:=(0), registered:=(0), queued:=(1), cancel:=(0), supervisor:=(0), lock:=(0), pin:=(0), tailQualified:=(0), nodeReceipt:=(0)}
def disableCancelGuard (q : State) : Prop := ((q.stage=(0)) ∧ (q.cancel=(0)))
def disableCancelNext (q : State) : State := {q with cancel:=(1)}
def exhaustPoolGuard (q : State) : Prop := ((q.stage=(0)) ∧ (q.free=(1)))
def exhaustPoolNext (q : State) : State := {q with free:=(0), external:=(1)}
def returnExternalSlotGuard (q : State) : Prop := (q.external=(1))
def returnExternalSlotNext (q : State) : State := {q with free:=(1), external:=(0)}
def claimSlotGuard (q : State) : Prop := (((q.stage=(0)) ∧ (q.cancel=(1))) ∧ (q.free=(1)))
def claimSlotNext (q : State) : State := {q with stage:=(1), free:=(0), slot:=(1)}
def releaseUnpublishedSlotGuard (q : State) : Prop := ((q.stage=(1)) ∧ (q.registered=(0)))
def releaseUnpublishedSlotNext (q : State) : State := {q with stage:=(0), free:=(1), slot:=(0)}
def registerKnownGuard (q : State) : Prop := ((q.stage=(1)) ∧ (q.registered=(0)))
def registerKnownNext (q : State) : State := {q with stage:=(2), registered:=(1)}
def registerUnknownGuard (q : State) : Prop := ((q.stage=(1)) ∧ (q.registered=(0)))
def registerUnknownNext (q : State) : State := {q with stage:=(2), registered:=(2)}
def reconcileRegistrationGuard (q : State) : Prop := ((q.stage=(2)) ∧ (q.registered=(2)))
def reconcileRegistrationNext (q : State) : State := {q with registered:=(1)}
def popKnownEscrowGuard (q : State) : Prop := (((q.stage=(2)) ∧ (q.registered=(1))) ∧ (q.cancel=(1)))
def popKnownEscrowNext (q : State) : State := {q with stage:=(3), queued:=(0)}
def escapeTokenGuard (q : State) : Prop := (q.stage=(3))
def escapeTokenNext (q : State) : State := {q with stage:=(4)}
def knownTokenEndpointGuard (q : State) : Prop := ((q.stage=(3)) ∨ (q.stage=(4)))
def knownTokenEndpointNext (q : State) : State := {q with stage:=(5)}
def qualifyNodeTailGuard (q : State) : Prop := (((q.stage=(5)) ∧ (q.cancel=(1))) ∧ (q.tailQualified=(0)))
def qualifyNodeTailNext (q : State) : State := {q with tailQualified:=(1)}
def completeQualifiedNodeTailGuard (q : State) : Prop := (((q.stage=(5)) ∧ (q.cancel=(1))) ∧ (q.tailQualified=(1)))
def completeQualifiedNodeTailNext (q : State) : State := {q with stage:=(7), nodeReceipt:=(1)}
def unknownNodeCompletionGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.tailQualified=(0)))
def unknownNodeCompletionNext (q : State) : State := {q with stage:=(6)}
def knownNodeBackendReceiptGuard (q : State) : Prop := (q.stage=(6))
def knownNodeBackendReceiptNext (q : State) : State := {q with stage:=(7), nodeReceipt:=(1)}
def publishDoneGuard (q : State) : Prop := ((q.stage=(7)) ∧ (q.nodeReceipt=(1)))
def publishDoneNext (q : State) : State := {q with stage:=(8)}
def acquireMapGuard (q : State) : Prop := (((q.cancel=(1)) ∧ (q.registered=(1))) ∧ (q.lock=(0)))
def acquireMapNext (q : State) : State := {q with lock:=(1)}
def issuePinGuard (q : State) : Prop := ((q.lock=(1)) ∧ (q.pin=(0)))
def issuePinNext (q : State) : State := {q with pin:=(1)}
def unlockMapGuard (q : State) : Prop := (q.lock=(1))
def unlockMapNext (q : State) : State := {q with lock:=(0)}
def escapeHoldingMapGuard (q : State) : Prop := (q.lock=(1))
def escapeHoldingMapNext (q : State) : State := {q with lock:=(2)}
def knownOwnerLandingGuard (q : State) : Prop := ((q.lock=(2)) ∧ (q.pin≤(1)))
def knownOwnerLandingNext (q : State) : State := {q with lock:=(1)}
def returnPinKnownGuard (q : State) : Prop := (((q.lock=(1)) ∧ (q.pin=(1))) ∧ (q.cancel=(1)))
def returnPinKnownNext (q : State) : State := {q with pin:=(0)}
def returnPinUnknownGuard (q : State) : Prop := (((q.lock=(1)) ∧ (q.pin=(1))) ∧ (q.cancel=(1)))
def returnPinUnknownNext (q : State) : State := {q with pin:=(2), lock:=(2)}
def knownPinReturnLandingGuard (q : State) : Prop := ((q.lock=(2)) ∧ (q.pin=(2)))
def knownPinReturnLandingNext (q : State) : State := {q with pin:=(0), lock:=(1)}
def handoffSupervisorGuard (q : State) : Prop := (((((q.stage=(8)) ∧ (q.cancel=(1))) ∧ (q.lock=(0))) ∧ (q.pin=(0))) ∧ (q.supervisor=(0)))
def handoffSupervisorNext (q : State) : State := {q with supervisor:=(1)}
def beginRestoreCancelGuard (q : State) : Prop := (((((q.stage=(8)) ∧ (q.cancel=(1))) ∧ (q.supervisor=(1))) ∧ (q.lock=(0))) ∧ (q.pin=(0)))
def beginRestoreCancelNext (q : State) : State := {q with cancel:=(2)}
def knownRestoreReturnGuard (q : State) : Prop := ((q.cancel=(2)) ∧ (q.supervisor=(1)))
def knownRestoreReturnNext (q : State) : State := {q with cancel:=(3)}
def retireSlotGuard (q : State) : Prop := (((((((q.stage=(8)) ∧ (q.cancel=(3))) ∧ (q.supervisor=(1))) ∧ (q.lock=(0))) ∧ (q.pin=(0))) ∧ (q.registered=(1))) ∧ (q.slot=(1)))
def retireSlotNext (q : State) : State := {q with stage:=(9), free:=(1), slot:=(0), registered:=(0), supervisor:=(0)}
def Step (q r : State) : Prop := (disableCancelGuard q ∧ r=disableCancelNext q) ∨ (exhaustPoolGuard q ∧ r=exhaustPoolNext q) ∨ (returnExternalSlotGuard q ∧ r=returnExternalSlotNext q) ∨ (claimSlotGuard q ∧ r=claimSlotNext q) ∨ (releaseUnpublishedSlotGuard q ∧ r=releaseUnpublishedSlotNext q) ∨ (registerKnownGuard q ∧ r=registerKnownNext q) ∨ (registerUnknownGuard q ∧ r=registerUnknownNext q) ∨ (reconcileRegistrationGuard q ∧ r=reconcileRegistrationNext q) ∨ (popKnownEscrowGuard q ∧ r=popKnownEscrowNext q) ∨ (escapeTokenGuard q ∧ r=escapeTokenNext q) ∨ (knownTokenEndpointGuard q ∧ r=knownTokenEndpointNext q) ∨ (qualifyNodeTailGuard q ∧ r=qualifyNodeTailNext q) ∨ (completeQualifiedNodeTailGuard q ∧ r=completeQualifiedNodeTailNext q) ∨ (unknownNodeCompletionGuard q ∧ r=unknownNodeCompletionNext q) ∨ (knownNodeBackendReceiptGuard q ∧ r=knownNodeBackendReceiptNext q) ∨ (publishDoneGuard q ∧ r=publishDoneNext q) ∨ (acquireMapGuard q ∧ r=acquireMapNext q) ∨ (issuePinGuard q ∧ r=issuePinNext q) ∨ (unlockMapGuard q ∧ r=unlockMapNext q) ∨ (escapeHoldingMapGuard q ∧ r=escapeHoldingMapNext q) ∨ (knownOwnerLandingGuard q ∧ r=knownOwnerLandingNext q) ∨ (returnPinKnownGuard q ∧ r=returnPinKnownNext q) ∨ (returnPinUnknownGuard q ∧ r=returnPinUnknownNext q) ∨ (knownPinReturnLandingGuard q ∧ r=knownPinReturnLandingNext q) ∨ (handoffSupervisorGuard q ∧ r=handoffSupervisorNext q) ∨ (beginRestoreCancelGuard q ∧ r=beginRestoreCancelNext q) ∨ (knownRestoreReturnGuard q ∧ r=knownRestoreReturnNext q) ∨ (retireSlotGuard q ∧ r=retireSlotNext q) ∨ r=q
end EscrowCriticalTailAst
