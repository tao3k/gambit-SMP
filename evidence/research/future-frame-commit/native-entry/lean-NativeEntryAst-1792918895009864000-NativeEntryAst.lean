import Std
namespace NativeEntryAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 host : Int
 sourcePin : Int
 sourceRoot : Int
 carrierRoot : Int
 registry : Int
 guard : Int
 inflight : Int
 nested : Int
 unknown : Int
 outcome : Int
 epoch : Int
 sourceEpoch : Int
 carrierEpoch : Int
 frozen : Int
 scanned : Int
 entryOpen : Int
 writeOpen : Int
 written : Int
 marker : Int
 receipt : Int
 registrationUnknown : Int
 scanAdmission : Int
 grace : Int
 rejected : Int
 holder : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(7)) ∧ (q.holder≥(0)) ∧ (q.holder≤(2)) ∧ (q.host≥(0)) ∧ (q.host≤(1)) ∧ (q.sourcePin≥(0)) ∧ (q.sourcePin≤(1)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.carrierRoot≥(0)) ∧ (q.carrierRoot≤(1)) ∧ (q.registry≥(0)) ∧ (q.registry≤(1)) ∧ (q.guard≥(0)) ∧ (q.guard≤(1)) ∧ (q.inflight≥(0)) ∧ (q.inflight≤(1)) ∧ (q.nested≥(0)) ∧ (q.nested≤(1)) ∧ (q.unknown≥(0)) ∧ (q.unknown≤(1)) ∧ (q.outcome≥(0)) ∧ (q.outcome≤(1)) ∧ (q.epoch≥(0)) ∧ (q.sourceEpoch≥(0)) ∧ (q.carrierEpoch≥(0)) ∧ (q.frozen≥(0)) ∧ (q.frozen≤(1)) ∧ (q.scanned≥(0)) ∧ (q.scanned≤(1)) ∧ (q.entryOpen≥(0)) ∧ (q.entryOpen≤(1)) ∧ (q.writeOpen≥(0)) ∧ (q.writeOpen≤(1)) ∧ (q.written≥(0)) ∧ (q.written≤(1)) ∧ (q.marker≥(0)) ∧ (q.marker≤(1)) ∧ (q.receipt≥(0)) ∧ (q.receipt≤(1)) ∧ (q.registrationUnknown≥(0)) ∧ (q.registrationUnknown≤(1)) ∧ (q.scanAdmission≥(0)) ∧ (q.scanAdmission≤(1)) ∧ (q.grace≥(0)) ∧ (q.grace≤(1)) ∧ (q.rejected≥(0)) ∧ (q.rejected≤(1)) ∧ (q.sourcePin=q.sourceRoot) ∧ (q.registry=q.carrierRoot) ∧ (q.registry=q.guard) ∧ (q.sourceEpoch≤q.epoch) ∧ (q.carrierEpoch≤q.epoch) ∧ (((q.phase≥(1)) ∧ (q.phase≤(6))) → ((q.sourceRoot+q.carrierRoot)≥(1))) ∧ (((q.phase≥(3)) ∧ (q.phase≤(5))) → ((q.host=(1)) ∧ (q.registry=(1)) ∧ (q.carrierRoot=(1)) ∧ (q.guard=(1)) ∧ (q.holder≥(1)))) ∧ (((q.phase≥(4)) ∧ (q.phase≤(5))) → (q.inflight=(1))) ∧ ((q.inflight=(1)) → ((q.phase≥(4)) ∧ (q.phase≤(5)) ∧ (q.registry=(1)))) ∧ ((q.unknown=(1)) → ((q.phase=(5)) ∧ (q.inflight=(1)) ∧ (q.registry=(1)) ∧ (q.carrierRoot=(1)) ∧ (q.guard=(1)) ∧ (q.holder=(2)))) ∧ ((q.nested=(1)) → ((q.phase=(5)) ∧ (q.inflight=(1)))) ∧ (((q.marker=(1)) ∧ (q.phase≤(5))) → (q.registry=(1))) ∧ ((q.registrationUnknown=(1)) → ((q.phase=(3)) ∧ (q.registry=(1)) ∧ (q.sourceRoot=(1)))) ∧ ((q.receipt=(1)) → ((q.sourceRoot=(1)) ∧ (q.carrierRoot=(1)) ∧ (q.registry=(1)) ∧ (q.carrierEpoch=q.epoch) ∧ (q.frozen=(0)))) ∧ ((q.phase=(7)) → ((q.sourceRoot=(0)) ∧ (q.sourcePin=(0)) ∧ (q.carrierRoot=(0)) ∧ (q.registry=(0)) ∧ (q.guard=(0)) ∧ (q.inflight=(0)) ∧ (q.nested=(0)) ∧ (q.unknown=(0)) ∧ (q.holder=(0)) ∧ (q.entryOpen=(0)) ∧ (q.scanAdmission=(0)) ∧ (q.grace=(1)) ∧ (q.frozen=(0)) ∧ (q.receipt=(0)))) ∧ ((q.frozen=(1)) → ((q.writeOpen=(0)) ∧ (q.epoch≥(1)) ∧ (q.phase≥(1)) ∧ (q.phase≤(6)))) ∧ (((q.frozen=(0)) ∧ (q.sourceRoot=(1))) → (q.sourceEpoch=q.epoch)) ∧ (((q.frozen=(0)) ∧ (q.carrierRoot=(1))) → (q.carrierEpoch=q.epoch)) ∧ (((q.scanned=(1)) ∧ (q.sourceRoot=(1))) → (q.sourceEpoch=q.epoch)) ∧ (((q.scanned=(1)) ∧ (q.carrierRoot=(1))) → (q.carrierEpoch=q.epoch)) ∧ ((q.grace=(1)) → ((q.phase≥(6)) ∧ (q.entryOpen=(0)) ∧ (q.scanAdmission=(0)) ∧ (q.frozen=(0)))) ∧ ((q.phase=(0)) → ((q.epoch=(0)) ∧ (q.sourceRoot=(0)) ∧ (q.registry=(0)) ∧ (q.inflight=(0)))) ∧ (((q.phase≥(1)) ∧ (q.phase≤(3))) → (q.sourceRoot=(1))) ∧ ((q.phase≤(2)) → ((q.registry=(0)) ∧ (q.inflight=(0)) ∧ (q.registrationUnknown=(0)))) ∧ ((q.phase=(6)) → ((q.inflight=(0)) ∧ (q.nested=(0)) ∧ (q.unknown=(0)))) ∧ ((q.phase≤(3)) → ((q.written=(0)) ∧ (q.marker=(0)))) ∧ ((q.phase=(4)) → (q.marker=(0))))
def initial : State := {phase:=(0), host:=(0), sourcePin:=(0), sourceRoot:=(0), carrierRoot:=(0), registry:=(0), guard:=(0), inflight:=(0), nested:=(0), unknown:=(0), outcome:=(0), epoch:=(0), sourceEpoch:=(0), carrierEpoch:=(0), frozen:=(0), scanned:=(0), entryOpen:=(1), writeOpen:=(1), written:=(0), marker:=(0), receipt:=(0), registrationUnknown:=(0), scanAdmission:=(1), grace:=(0), rejected:=(0), holder:=(0)}
def pinSourceGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.entryOpen=(1)))
def pinSourceNext (q : State) : State := {q with phase:=(1), sourcePin:=(1), sourceRoot:=(1)}
def reserveCarrierGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.frozen=(0)))
def reserveCarrierNext (q : State) : State := {q with phase:=(2)}
def qualifyHostGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.frozen=(0)))
def qualifyHostNext (q : State) : State := {q with host:=(1)}
def publishCarrierGuard (q : State) : Prop := (((((q.phase=(2)) ∧ (q.host=(1))) ∧ (q.writeOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.sourceRoot=(1)))
def publishCarrierNext (q : State) : State := {q with phase:=(3), carrierRoot:=(1), registry:=(1), guard:=(1), carrierEpoch:=q.sourceEpoch, holder:=(1)}
def loseRegistrationAckGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.registrationUnknown=(0)))
def loseRegistrationAckNext (q : State) : State := {q with registrationUnknown:=(1)}
def confirmSameRegistrationGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.registrationUnknown=(1))) ∧ (q.registry=(1)))
def confirmSameRegistrationNext (q : State) : State := {q with registrationUnknown:=(0)}
def jointIssueGuard (q : State) : Prop := ((((((((((q.phase=(3)) ∧ (q.entryOpen=(1))) ∧ (q.writeOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.registrationUnknown=(0))) ∧ (q.host=(1))) ∧ (q.registry=(1))) ∧ (q.guard=(1))) ∧ (q.carrierRoot=(1))) ∧ (q.carrierEpoch=q.epoch))
def jointIssueNext (q : State) : State := {q with phase:=(4), inflight:=(1)}
def writeEntryStateGuard (q : State) : Prop := ((((q.phase=(4)) ∧ (q.frozen=(0))) ∧ (q.writeOpen=(1))) ∧ (q.written=(0)))
def writeEntryStateNext (q : State) : State := {q with written:=(1)}
def allocateMarkerGuard (q : State) : Prop := ((((q.phase=(4)) ∧ (q.frozen=(0))) ∧ (q.writeOpen=(1))) ∧ (q.written=(1)))
def allocateMarkerNext (q : State) : State := {q with phase:=(5), marker:=(1)}
def certifyTransferGuard (q : State) : Prop := ((((((((q.phase≥(4)) ∧ (q.phase≤(6))) ∧ (q.sourcePin=(1))) ∧ (q.sourceRoot=(1))) ∧ (q.registry=(1))) ∧ (q.carrierRoot=(1))) ∧ (q.carrierEpoch=q.epoch)) ∧ (q.frozen=(0)))
def certifyTransferNext (q : State) : State := {q with receipt:=(1)}
def releaseSourceGuard (q : State) : Prop := (((((q.phase≥(4)) ∧ (q.phase≤(6))) ∧ (q.receipt=(1))) ∧ (q.sourcePin=(1))) ∧ (q.frozen=(0)))
def releaseSourceNext (q : State) : State := {q with sourcePin:=(0), sourceRoot:=(0), receipt:=(0)}
def closeIngressGuard (q : State) : Prop := ((q.phase<(7)) ∧ (q.entryOpen=(1)))
def closeIngressNext (q : State) : State := {q with entryOpen:=(0)}
def exhaustCarrierGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.frozen=(0)))
def exhaustCarrierNext (q : State) : State := {q with phase:=(6), rejected:=(1)}
def rejectClosedGuard (q : State) : Prop := (((((q.phase≥(1)) ∧ (q.phase≤(3))) ∧ (q.entryOpen=(0))) ∧ (q.frozen=(0))) ∧ (q.registrationUnknown=(0)))
def rejectClosedNext (q : State) : State := {q with phase:=(6), rejected:=(1)}
def freezeWritersGuard (q : State) : Prop := ((((q.phase≥(1)) ∧ (q.phase≤(6))) ∧ (q.frozen=(0))) ∧ (q.scanAdmission=(1)))
def freezeWritersNext (q : State) : State := {q with epoch:=(q.epoch+(1)), frozen:=(1), writeOpen:=(0), scanned:=(0), receipt:=(0)}
def scanSourceGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.sourceRoot=(1))) ∧ (q.carrierRoot=(0)))
def scanSourceNext (q : State) : State := {q with sourceEpoch:=q.epoch, scanned:=(1)}
def scanBothGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.sourceRoot=(1))) ∧ (q.carrierRoot=(1)))
def scanBothNext (q : State) : State := {q with sourceEpoch:=q.epoch, carrierEpoch:=q.epoch, scanned:=(1)}
def scanCarrierGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.sourceRoot=(0))) ∧ (q.carrierRoot=(1)))
def scanCarrierNext (q : State) : State := {q with carrierEpoch:=q.epoch, scanned:=(1)}
def thawWritersGuard (q : State) : Prop := ((q.frozen=(1)) ∧ (q.scanned=(1)))
def thawWritersNext (q : State) : State := {q with frozen:=(0), writeOpen:=(1)}
def enterNestedGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.entryOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.unknown=(0))) ∧ (q.nested=(0)))
def enterNestedNext (q : State) : State := {q with nested:=(1)}
def leaveNestedGuard (q : State) : Prop := (((q.phase=(5)) ∧ (q.nested=(1))) ∧ (q.frozen=(0)))
def leaveNestedNext (q : State) : State := {q with nested:=(0)}
def recordOutcomeGuard (q : State) : Prop := ((((q.phase=(5)) ∧ (q.unknown=(0))) ∧ (q.frozen=(0))) ∧ (q.outcome=(0)))
def recordOutcomeNext (q : State) : State := {q with outcome:=(1)}
def loseCompletionGuard (q : State) : Prop := ((q.phase=(5)) ∧ (q.unknown=(0)))
def loseCompletionNext (q : State) : State := {q with unknown:=(1), holder:=(2)}
def landNestedGuard (q : State) : Prop := ((((q.phase=(5)) ∧ (q.nested=(1))) ∧ (q.unknown=(1))) ∧ (q.frozen=(0)))
def landNestedNext (q : State) : State := {q with nested:=(0)}
def settleKnownGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.outcome=(1))) ∧ (q.unknown=(0))) ∧ (q.nested=(0))) ∧ (q.frozen=(0)))
def settleKnownNext (q : State) : State := {q with phase:=(6), inflight:=(0)}
def recoverRecordedGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.outcome=(1))) ∧ (q.unknown=(1))) ∧ (q.nested=(0))) ∧ (q.frozen=(0)))
def recoverRecordedNext (q : State) : State := {q with phase:=(6), inflight:=(0), unknown:=(0), holder:=(1)}
def closeScanAdmissionGuard (q : State) : Prop := (((q.phase=(6)) ∧ (q.entryOpen=(0))) ∧ (q.scanAdmission=(1)))
def closeScanAdmissionNext (q : State) : State := {q with scanAdmission:=(0)}
def confirmGraceGuard (q : State) : Prop := ((((((((q.phase=(6)) ∧ (q.entryOpen=(0))) ∧ (q.scanAdmission=(0))) ∧ (q.frozen=(0))) ∧ (q.inflight=(0))) ∧ (q.nested=(0))) ∧ (q.unknown=(0))) ∧ (q.registrationUnknown=(0)))
def confirmGraceNext (q : State) : State := {q with grace:=(1)}
def retireCarrierGuard (q : State) : Prop := (((((((((q.phase=(6)) ∧ (q.entryOpen=(0))) ∧ (q.scanAdmission=(0))) ∧ (q.grace=(1))) ∧ (q.frozen=(0))) ∧ (q.registrationUnknown=(0))) ∧ (q.unknown=(0))) ∧ (q.inflight=(0))) ∧ (q.nested=(0)))
def retireCarrierNext (q : State) : State := {q with phase:=(7), sourcePin:=(0), sourceRoot:=(0), carrierRoot:=(0), registry:=(0), guard:=(0), holder:=(0), receipt:=(0), writeOpen:=(0)}
def Step (q r : State) : Prop := (pinSourceGuard q ∧ r=pinSourceNext q) ∨ (reserveCarrierGuard q ∧ r=reserveCarrierNext q) ∨ (qualifyHostGuard q ∧ r=qualifyHostNext q) ∨ (publishCarrierGuard q ∧ r=publishCarrierNext q) ∨ (loseRegistrationAckGuard q ∧ r=loseRegistrationAckNext q) ∨ (confirmSameRegistrationGuard q ∧ r=confirmSameRegistrationNext q) ∨ (jointIssueGuard q ∧ r=jointIssueNext q) ∨ (writeEntryStateGuard q ∧ r=writeEntryStateNext q) ∨ (allocateMarkerGuard q ∧ r=allocateMarkerNext q) ∨ (certifyTransferGuard q ∧ r=certifyTransferNext q) ∨ (releaseSourceGuard q ∧ r=releaseSourceNext q) ∨ (closeIngressGuard q ∧ r=closeIngressNext q) ∨ (exhaustCarrierGuard q ∧ r=exhaustCarrierNext q) ∨ (rejectClosedGuard q ∧ r=rejectClosedNext q) ∨ (freezeWritersGuard q ∧ r=freezeWritersNext q) ∨ (scanSourceGuard q ∧ r=scanSourceNext q) ∨ (scanBothGuard q ∧ r=scanBothNext q) ∨ (scanCarrierGuard q ∧ r=scanCarrierNext q) ∨ (thawWritersGuard q ∧ r=thawWritersNext q) ∨ (enterNestedGuard q ∧ r=enterNestedNext q) ∨ (leaveNestedGuard q ∧ r=leaveNestedNext q) ∨ (recordOutcomeGuard q ∧ r=recordOutcomeNext q) ∨ (loseCompletionGuard q ∧ r=loseCompletionNext q) ∨ (landNestedGuard q ∧ r=landNestedNext q) ∨ (settleKnownGuard q ∧ r=settleKnownNext q) ∨ (recoverRecordedGuard q ∧ r=recoverRecordedNext q) ∨ (closeScanAdmissionGuard q ∧ r=closeScanAdmissionNext q) ∨ (confirmGraceGuard q ∧ r=confirmGraceNext q) ∨ (retireCarrierGuard q ∧ r=retireCarrierNext q) ∨ r=q
end NativeEntryAst
