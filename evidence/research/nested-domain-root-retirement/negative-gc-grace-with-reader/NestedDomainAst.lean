import Std
namespace NestedDomainAst
set_option maxRecDepth 10000
structure State where
 source : Int
 target : Int
 ack : Int
 pubReply : Int
 innerSource : Int
 innerTarget : Int
 innerAck : Int
 outerGuard : Int
 innerGuard : Int
 outerRight : Int
 innerRight : Int
 unwind : Int
 landed : Int
 captured : Int
 gcReader : Int
 descriptor : Int
 rootClosed : Int
 rootGrace : Int
 rootRetired : Int
 codeClosed : Int
 codeGrace : Int
 detached : Int
 outcome : Int
 shotGuard : Int
 shotTicket : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.source≥(0)) ∧ (q.target≥(0)) ∧ (q.ack≥(0)) ∧ (q.pubReply≥(0)) ∧ (q.innerSource≥(0)) ∧ (q.innerTarget≥(0)) ∧ (q.innerAck≥(0)) ∧ (q.outerGuard≥(0)) ∧ (q.innerGuard≥(0)) ∧ (q.outerRight≥(0)) ∧ (q.innerRight≥(0)) ∧ (q.unwind≥(0)) ∧ (q.landed≥(0)) ∧ (q.captured≥(0)) ∧ (q.gcReader≥(0)) ∧ (q.descriptor≥(0)) ∧ (q.rootClosed≥(0)) ∧ (q.rootGrace≥(0)) ∧ (q.rootRetired≥(0)) ∧ (q.codeClosed≥(0)) ∧ (q.codeGrace≥(0)) ∧ (q.detached≥(0)) ∧ (q.outcome≥(0)) ∧ (q.shotGuard≥(0)) ∧ (q.shotTicket≥(0)) ∧ (q.source≤(1)) ∧ (q.target≤(1)) ∧ (q.ack≤(1)) ∧ (q.pubReply≤(1)) ∧ (q.innerSource≤(1)) ∧ (q.innerTarget≤(1)) ∧ (q.innerAck≤(1)) ∧ (q.outerGuard≤(3)) ∧ (q.innerGuard≤(3)) ∧ (q.outerRight≤(1)) ∧ (q.innerRight≤(1)) ∧ (q.unwind≤(3)) ∧ (q.landed≤(1)) ∧ (q.captured≤(1)) ∧ (q.gcReader≤(1)) ∧ (q.descriptor≤(1)) ∧ (q.rootClosed≤(1)) ∧ (q.rootGrace≤(1)) ∧ (q.rootRetired≤(1)) ∧ (q.codeClosed≤(1)) ∧ (q.codeGrace≤(1)) ∧ (q.detached≤(1)) ∧ (q.outcome≤(1)) ∧ (q.shotGuard≤(1)) ∧ (q.shotTicket≤(2)) ∧ ((q.innerSource=(1)) → ((((q.outerGuard=(1)) ∧ (q.innerGuard=(0))) ∧ (q.target=(1))) ∧ (q.descriptor=(1)))) ∧ ((q.innerAck=(1)) → ((q.innerTarget=(1)) ∨ (q.rootRetired=(1)))) ∧ ((q.innerGuard>(0)) → ((q.innerAck=(1)) ∧ (q.innerSource=(0)))) ∧ (((q.innerGuard=(1)) ∨ (q.innerGuard=(2))) → (q.innerTarget=(1))) ∧ ((q.innerTarget=(1)) → (q.descriptor=(1))) ∧ (((q.source=(1)) ∨ (q.target=(1))) ∨ (q.rootRetired=(1))) ∧ ((q.pubReply=(1)) → (((q.source=(1)) ∧ (q.ack=(0))) ∧ (q.outerGuard=(0)))) ∧ ((q.ack=(1)) → ((q.target=(1)) ∨ (q.rootRetired=(1)))) ∧ ((q.outerGuard>(0)) → ((q.ack=(1)) ∧ (q.source=(0)))) ∧ ((q.innerGuard>(0)) → (q.outerGuard>(0))) ∧ ((((((q.outerGuard=(1)) ∨ (q.outerGuard=(2))) ∨ (q.innerGuard=(1))) ∨ (q.innerGuard=(2))) ∨ (q.shotGuard=(1))) → (((q.target=(1)) ∧ (q.descriptor=(1))) ∧ (q.rootRetired=(0)))) ∧ ((q.outerRight=(1)) → (((q.outerGuard=(1)) ∧ (q.unwind=(0))) ∧ (q.landed=(0)))) ∧ ((q.innerRight=(1)) → ((q.innerGuard=(1)) ∧ (q.outerRight=(1)))) ∧ ((q.outerGuard=(1)) → ((q.outerRight=(1)) ∧ (q.unwind=(0)))) ∧ ((q.innerGuard=(1)) → ((q.innerRight=(1)) ∧ (q.outerGuard=(1)))) ∧ (((q.outerGuard=(2)) ∨ (q.innerGuard=(2))) → (q.unwind≥(1))) ∧ ((q.unwind≥(1)) → ((((q.outerRight=(0)) ∧ (q.innerRight=(0))) ∧ (q.outerGuard≥(2))) ∧ (q.innerGuard≥(2)))) ∧ (((q.unwind=(1)) ∨ (q.unwind=(2))) → ((((q.outerGuard=(2)) ∧ (q.innerGuard=(2))) ∧ (q.landed=(0))) ∧ (q.captured=(1)))) ∧ ((q.landed=(1)) → ((q.unwind=(3)) ∧ (q.outcome=(0)))) ∧ ((q.unwind=(3)) → (q.landed=(1))) ∧ ((q.innerGuard=(3)) → (q.landed=(1))) ∧ ((q.outerGuard=(3)) → (q.innerGuard=(3))) ∧ ((q.outcome=(1)) → ((((q.unwind=(2)) ∧ (q.landed=(0))) ∧ (q.outerGuard=(2))) ∧ (q.innerGuard=(2)))) ∧ ((q.captured=(1)) → ((((q.target=(1)) ∧ (q.innerTarget=(1))) ∧ (q.descriptor=(1))) ∧ (q.rootClosed=(0)))) ∧ ((q.gcReader=(1)) → ((((q.target=(1)) ∧ (q.descriptor=(1))) ∧ (q.rootGrace=(0))) ∧ (q.codeGrace=(0)))) ∧ ((q.rootClosed=(1)) → (((((((((q.source=(0)) ∧ (q.innerSource=(0))) ∧ (q.innerAck=(1))) ∧ (q.ack=(1))) ∧ (q.landed=(1))) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3))) ∧ (q.captured=(0))) ∧ (q.shotGuard=(0)))) ∧ ((q.rootGrace=(1)) → ((q.rootClosed=(1)) ∧ (q.gcReader=(0)))) ∧ ((q.codeClosed=(1)) → (q.rootClosed=(1))) ∧ ((q.codeGrace=(1)) → ((q.codeClosed=(1)) ∧ (q.gcReader=(0)))) ∧ ((q.rootRetired=(1)) → ((((((q.target=(0)) ∧ (q.innerTarget=(0))) ∧ (q.source=(0))) ∧ (q.rootClosed=(1))) ∧ (q.rootGrace=(1))) ∧ (q.gcReader=(0)))) ∧ ((q.descriptor=(0)) → ((((q.rootRetired=(1)) ∧ (q.codeClosed=(1))) ∧ (q.codeGrace=(1))) ∧ (q.gcReader=(0)))) ∧ ((q.detached=(1)) → (((q.descriptor=(0)) ∧ (q.rootRetired=(1))) ∧ (q.landed=(1)))) ∧ ((q.shotGuard=(1)) → (((((q.landed=(1)) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3))) ∧ (q.captured=(1))) ∧ (q.shotTicket≥(1)))) ∧ ((q.shotTicket>(0)) → (((q.landed=(1)) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3)))))
def initial : State := {source:=(1), target:=(0), ack:=(0), pubReply:=(0), innerSource:=(0), innerTarget:=(0), innerAck:=(0), outerGuard:=(0), innerGuard:=(0), outerRight:=(0), innerRight:=(0), unwind:=(0), landed:=(0), captured:=(0), gcReader:=(0), descriptor:=(1), rootClosed:=(0), rootGrace:=(0), rootRetired:=(0), codeClosed:=(0), codeGrace:=(0), detached:=(0), outcome:=(0), shotGuard:=(0), shotTicket:=(0)}
def publishRootsGuard (q : State) : Prop := (((q.source=(1)) ∧ (q.target=(0))) ∧ (q.pubReply=(0)))
def publishRootsNext (q : State) : State := {q with target:=(1)}
def publicationReplyLostGuard (q : State) : Prop := (((q.source=(1)) ∧ (q.target=(0))) ∧ (q.pubReply=(0)))
def publicationReplyLostNext (q : State) : State := {q with target:=(1), pubReply:=(1)}
def publicationAbsentUnknownGuard (q : State) : Prop := (((q.source=(1)) ∧ (q.target=(0))) ∧ (q.pubReply=(0)))
def publicationAbsentUnknownNext (q : State) : State := {q with pubReply:=(1)}
def resolvePublicationGuard (q : State) : Prop := (q.pubReply=(1))
def resolvePublicationNext (q : State) : State := {q with pubReply:=(0)}
def acknowledgeRootsGuard (q : State) : Prop := ((((q.target=(1)) ∧ (q.pubReply=(0))) ∧ (q.ack=(0))) ∧ (q.gcReader=(0)))
def acknowledgeRootsNext (q : State) : State := {q with ack:=(1)}
def releaseSourceGuard (q : State) : Prop := ((((q.source=(1)) ∧ (q.target=(1))) ∧ (q.ack=(1))) ∧ (q.pubReply=(0)))
def releaseSourceNext (q : State) : State := {q with source:=(0)}
def enterOuterGuard (q : State) : Prop := ((((((q.outerGuard=(0)) ∧ (q.source=(0))) ∧ (q.target=(1))) ∧ (q.ack=(1))) ∧ (q.rootClosed=(0))) ∧ (q.codeClosed=(0)))
def enterOuterNext (q : State) : State := {q with outerGuard:=(1), outerRight:=(1)}
def reserveInnerOfferGuard (q : State) : Prop := (((((q.outerGuard=(1)) ∧ (q.innerGuard=(0))) ∧ (q.innerSource=(0))) ∧ (q.innerTarget=(0))) ∧ (q.innerAck=(0)))
def reserveInnerOfferNext (q : State) : State := {q with innerSource:=(1)}
def publishInnerRootsGuard (q : State) : Prop := ((q.innerSource=(1)) ∧ (q.innerTarget=(0)))
def publishInnerRootsNext (q : State) : State := {q with innerTarget:=(1)}
def acknowledgeInnerRootsGuard (q : State) : Prop := (((q.innerTarget=(1)) ∧ (q.innerAck=(0))) ∧ (q.gcReader=(0)))
def acknowledgeInnerRootsNext (q : State) : State := {q with innerAck:=(1)}
def releaseInnerSourceGuard (q : State) : Prop := (((q.innerSource=(1)) ∧ (q.innerTarget=(1))) ∧ (q.innerAck=(1)))
def releaseInnerSourceNext (q : State) : State := {q with innerSource:=(0)}
def enterInnerGuard (q : State) : Prop := ((((((((q.outerGuard=(1)) ∧ (q.outerRight=(1))) ∧ (q.innerGuard=(0))) ∧ (q.innerSource=(0))) ∧ (q.innerTarget=(1))) ∧ (q.innerAck=(1))) ∧ (q.rootClosed=(0))) ∧ (q.codeClosed=(0)))
def enterInnerNext (q : State) : State := {q with innerGuard:=(1), innerRight:=(1)}
def captureInnerGuard (q : State) : Prop := ((q.innerGuard=(1)) ∧ (q.captured=(0)))
def captureInnerNext (q : State) : State := {q with captured:=(1)}
def startGcReaderGuard (q : State) : Prop := (((((q.target=(1)) ∧ (q.descriptor=(1))) ∧ (q.rootClosed=(0))) ∧ (q.codeClosed=(0))) ∧ (q.gcReader=(0)))
def startGcReaderNext (q : State) : State := {q with gcReader:=(1)}
def finishGcReaderGuard (q : State) : Prop := (q.gcReader=(1))
def finishGcReaderNext (q : State) : State := {q with gcReader:=(0)}
def escrowOuterUnwindGuard (q : State) : Prop := ((((q.outerGuard=(1)) ∧ (q.innerGuard=(1))) ∧ (q.captured=(1))) ∧ (q.unwind=(0)))
def escrowOuterUnwindNext (q : State) : State := {q with outerGuard:=(2), innerGuard:=(2), outerRight:=(0), innerRight:=(0), unwind:=(1)}
def issueOuterUnwindGuard (q : State) : Prop := (q.unwind=(1))
def issueOuterUnwindNext (q : State) : State := {q with unwind:=(2)}
def landingObservedGuard (q : State) : Prop := ((q.unwind=(2)) ∧ (q.outcome=(0)))
def landingObservedNext (q : State) : State := {q with unwind:=(3), landed:=(1)}
def landingReplyLostGuard (q : State) : Prop := ((q.unwind=(2)) ∧ (q.outcome=(0)))
def landingReplyLostNext (q : State) : State := {q with outcome:=(1)}
def reconcileLandingGuard (q : State) : Prop := ((q.unwind=(2)) ∧ (q.outcome=(1)))
def reconcileLandingNext (q : State) : State := {q with unwind:=(3), landed:=(1), outcome:=(0)}
def settleInnerGuardGuard (q : State) : Prop := ((q.unwind=(3)) ∧ (q.innerGuard=(2)))
def settleInnerGuardNext (q : State) : State := {q with innerGuard:=(3)}
def settleOuterGuardGuard (q : State) : Prop := (((q.unwind=(3)) ∧ (q.innerGuard=(3))) ∧ (q.outerGuard=(2)))
def settleOuterGuardNext (q : State) : State := {q with outerGuard:=(3)}
def resumeCapturedGuard (q : State) : Prop := (((((((q.captured=(1)) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3))) ∧ (q.shotGuard=(0))) ∧ (q.shotTicket<(2))) ∧ (q.rootClosed=(0))) ∧ (q.codeClosed=(0)))
def resumeCapturedNext (q : State) : State := {q with shotGuard:=(1), shotTicket:=(q.shotTicket+(1))}
def rejectInnerReturnGuard (q : State) : Prop := ((q.shotGuard=(1)) ∧ (q.innerRight=(0)))
def rejectInnerReturnNext (q : State) : State := {q with }
def finishResumptionGuard (q : State) : Prop := (q.shotGuard=(1))
def finishResumptionNext (q : State) : State := {q with shotGuard:=(0)}
def closeCapturedHoldersGuard (q : State) : Prop := ((((q.captured=(1)) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3))) ∧ (q.shotGuard=(0)))
def closeCapturedHoldersNext (q : State) : State := {q with captured:=(0)}
def closeRootAdmissionGuard (q : State) : Prop := (((((q.captured=(0)) ∧ (q.outerGuard=(3))) ∧ (q.innerGuard=(3))) ∧ (q.shotGuard=(0))) ∧ (q.rootClosed=(0)))
def closeRootAdmissionNext (q : State) : State := {q with rootClosed:=(1)}
def closeCodeAdmissionGuard (q : State) : Prop := ((q.rootClosed=(1)) ∧ (q.codeClosed=(0)))
def closeCodeAdmissionNext (q : State) : State := {q with codeClosed:=(1)}
def ackRootGraceGuard (q : State) : Prop := (((q.rootClosed=(1)) ∧ True) ∧ (q.rootGrace=(0)))
def ackRootGraceNext (q : State) : State := {q with rootGrace:=(1)}
def retireRootSlotsGuard (q : State) : Prop := ((((q.rootClosed=(1)) ∧ (q.rootGrace=(1))) ∧ (q.gcReader=(0))) ∧ (q.target=(1)))
def retireRootSlotsNext (q : State) : State := {q with target:=(0), innerTarget:=(0), rootRetired:=(1)}
def ackCodeGraceGuard (q : State) : Prop := (((q.codeClosed=(1)) ∧ (q.gcReader=(0))) ∧ (q.codeGrace=(0)))
def ackCodeGraceNext (q : State) : State := {q with codeGrace:=(1)}
def retireDescriptorGuard (q : State) : Prop := (((((q.rootRetired=(1)) ∧ (q.codeClosed=(1))) ∧ (q.codeGrace=(1))) ∧ (q.gcReader=(0))) ∧ (q.descriptor=(1)))
def retireDescriptorNext (q : State) : State := {q with descriptor:=(0)}
def detachNativeOwnerGuard (q : State) : Prop := ((((q.rootRetired=(1)) ∧ (q.descriptor=(0))) ∧ (q.gcReader=(0))) ∧ (q.detached=(0)))
def detachNativeOwnerNext (q : State) : State := {q with detached:=(1)}
def Step (q r : State) : Prop := (publishRootsGuard q ∧ r=publishRootsNext q) ∨ (publicationReplyLostGuard q ∧ r=publicationReplyLostNext q) ∨ (publicationAbsentUnknownGuard q ∧ r=publicationAbsentUnknownNext q) ∨ (resolvePublicationGuard q ∧ r=resolvePublicationNext q) ∨ (acknowledgeRootsGuard q ∧ r=acknowledgeRootsNext q) ∨ (releaseSourceGuard q ∧ r=releaseSourceNext q) ∨ (enterOuterGuard q ∧ r=enterOuterNext q) ∨ (reserveInnerOfferGuard q ∧ r=reserveInnerOfferNext q) ∨ (publishInnerRootsGuard q ∧ r=publishInnerRootsNext q) ∨ (acknowledgeInnerRootsGuard q ∧ r=acknowledgeInnerRootsNext q) ∨ (releaseInnerSourceGuard q ∧ r=releaseInnerSourceNext q) ∨ (enterInnerGuard q ∧ r=enterInnerNext q) ∨ (captureInnerGuard q ∧ r=captureInnerNext q) ∨ (startGcReaderGuard q ∧ r=startGcReaderNext q) ∨ (finishGcReaderGuard q ∧ r=finishGcReaderNext q) ∨ (escrowOuterUnwindGuard q ∧ r=escrowOuterUnwindNext q) ∨ (issueOuterUnwindGuard q ∧ r=issueOuterUnwindNext q) ∨ (landingObservedGuard q ∧ r=landingObservedNext q) ∨ (landingReplyLostGuard q ∧ r=landingReplyLostNext q) ∨ (reconcileLandingGuard q ∧ r=reconcileLandingNext q) ∨ (settleInnerGuardGuard q ∧ r=settleInnerGuardNext q) ∨ (settleOuterGuardGuard q ∧ r=settleOuterGuardNext q) ∨ (resumeCapturedGuard q ∧ r=resumeCapturedNext q) ∨ (rejectInnerReturnGuard q ∧ r=rejectInnerReturnNext q) ∨ (finishResumptionGuard q ∧ r=finishResumptionNext q) ∨ (closeCapturedHoldersGuard q ∧ r=closeCapturedHoldersNext q) ∨ (closeRootAdmissionGuard q ∧ r=closeRootAdmissionNext q) ∨ (closeCodeAdmissionGuard q ∧ r=closeCodeAdmissionNext q) ∨ (ackRootGraceGuard q ∧ r=ackRootGraceNext q) ∨ (retireRootSlotsGuard q ∧ r=retireRootSlotsNext q) ∨ (ackCodeGraceGuard q ∧ r=ackCodeGraceNext q) ∨ (retireDescriptorGuard q ∧ r=retireDescriptorNext q) ∨ (detachNativeOwnerGuard q ∧ r=detachNativeOwnerNext q) ∨ r=q
end NestedDomainAst
