import Std
namespace SfunAdmissionAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 managed : Int
 domainOpen : Int
 pool : Int
 sourcePin : Int
 sourceDrops : Int
 root : Int
 guard : Int
 guardCreates : Int
 guardDrops : Int
 marker : Int
 markerCreates : Int
 markerDrops : Int
 allocs : Int
 bodyEntries : Int
 handlerEntries : Int
 legacyRetries : Int
 origin : Int
 code : Int
 refused : Int
 preRefused : Int
 refusalStamp : Int
 final : Int
 landing : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(8)) ∧ (q.managed≥(0)) ∧ (q.managed≤(1)) ∧ (q.domainOpen≥(0)) ∧ (q.domainOpen≤(1)) ∧ (q.pool≥(0)) ∧ (q.pool≤(1)) ∧ (q.sourcePin≥(0)) ∧ (q.sourcePin≤(1)) ∧ (q.sourceDrops≥(0)) ∧ (q.sourceDrops≤(1)) ∧ (q.root≥(0)) ∧ (q.root≤(1)) ∧ (q.guard≥(0)) ∧ (q.guard≤(1)) ∧ (q.guardCreates≥(0)) ∧ (q.guardCreates≤(1)) ∧ (q.guardDrops≥(0)) ∧ (q.guardDrops≤(1)) ∧ (q.marker≥(0)) ∧ (q.marker≤(1)) ∧ (q.markerCreates≥(0)) ∧ (q.markerCreates≤(1)) ∧ (q.markerDrops≥(0)) ∧ (q.markerDrops≤(1)) ∧ (q.allocs≥(0)) ∧ (q.allocs≤(1)) ∧ (q.bodyEntries≥(0)) ∧ (q.bodyEntries≤(1)) ∧ (q.handlerEntries≥(0)) ∧ (q.legacyRetries≥(0)) ∧ (q.origin≥(0)) ∧ (q.origin≤(5)) ∧ (q.code≥(0)) ∧ (q.code≤(3)) ∧ (q.refused≥(0)) ∧ (q.refused≤(1)) ∧ (q.preRefused≥(0)) ∧ (q.preRefused≤(1)) ∧ (q.refusalStamp≥(0)) ∧ (q.final≥(0)) ∧ (q.final≤(1)) ∧ (q.landing≥(0)) ∧ (q.landing≤(1)) ∧ (q.allocs=q.markerCreates) ∧ (((q.managed=(1)) ∧ (q.phase≤(2))) → (((((((((q.markerCreates=(0)) ∧ (q.allocs=(0))) ∧ (q.bodyEntries=(0))) ∧ (q.handlerEntries=(0))) ∧ (q.origin=(0))) ∧ (q.code=(0))) ∧ (q.refused=(0))) ∧ (q.preRefused=(0))) ∧ (q.landing=(0)))) ∧ (((q.managed=(1)) ∧ (q.preRefused=(1))) → ((q.refused=(1)) ∧ (q.phase≥(7)))) ∧ ((q.sourcePin+q.sourceDrops)=(1)) ∧ ((q.guard+q.guardDrops)=q.guardCreates) ∧ ((q.marker+q.markerDrops)=q.markerCreates) ∧ (q.refusalStamp≤q.handlerEntries) ∧ ((q.managed=(1)) → (q.legacyRetries=(0))) ∧ (((q.managed=(1)) ∧ (q.phase≤(6))) → ((q.sourcePin+q.root)≥(1))) ∧ (((q.managed=(1)) ∧ (q.guard=(1))) → (q.root=(1))) ∧ (((q.managed=(1)) ∧ (q.marker=(1))) → ((q.guard=(1)) ∧ (q.root=(1)))) ∧ (((q.managed=(1)) ∧ (q.phase=(0))) → ((((((q.guard=(0)) ∧ (q.marker=(0))) ∧ (q.root=(0))) ∧ (q.sourcePin=(1))) ∧ (q.guardCreates=(0))) ∧ (q.markerCreates=(0)))) ∧ (((q.managed=(1)) ∧ (q.phase=(1))) → ((((q.guard=(1)) ∧ (q.root=(1))) ∧ (q.marker=(0))) ∧ (q.sourcePin=(1)))) ∧ (((q.managed=(1)) ∧ (q.phase=(2))) → ((((q.guard=(1)) ∧ (q.root=(1))) ∧ (q.marker=(0))) ∧ (q.sourcePin=(0)))) ∧ (((q.managed=(1)) ∧ (((q.phase=(3)) ∨ (q.phase=(4))) ∨ (q.phase=(5)))) → ((((q.guard=(1)) ∧ (q.root=(1))) ∧ (q.marker=(1))) ∧ (q.sourcePin=(0)))) ∧ (((q.managed=(1)) ∧ (q.phase=(5))) → ((q.origin=(2)) ∧ (q.refused=(0)))) ∧ (((q.managed=(1)) ∧ (q.phase=(6))) → ((q.guard=(1)) ∧ (q.root=(1)))) ∧ (((q.managed=(1)) ∧ (q.phase≥(7))) → (((q.guard=(0)) ∧ (q.root=(0))) ∧ (q.marker=(0)))) ∧ (((q.managed=(1)) ∧ (q.refused=(1))) → (((q.handlerEntries=q.refusalStamp) ∧ (q.origin=(1))) ∧ (q.phase≥(6)))) ∧ (((q.managed=(1)) ∧ (q.preRefused=(1))) → (((((q.guardCreates=(0)) ∧ (q.markerCreates=(0))) ∧ (q.allocs=(0))) ∧ (q.bodyEntries=(0))) ∧ (q.handlerEntries=(0)))) ∧ (((q.managed=(1)) ∧ (q.final=(1))) → (((((q.phase=(8)) ∧ (q.guard=(0))) ∧ (q.marker=(0))) ∧ (q.root=(0))) ∧ (q.sourcePin=(0)))) ∧ (((q.managed=(1)) ∧ (q.phase≤(7))) → (q.final=(0))))
def initial : State := {phase:=(0), managed:=(1), domainOpen:=(1), pool:=(1), sourcePin:=(1), sourceDrops:=(0), root:=(0), guard:=(0), guardCreates:=(0), guardDrops:=(0), marker:=(0), markerCreates:=(0), markerDrops:=(0), allocs:=(0), bodyEntries:=(0), handlerEntries:=(0), legacyRetries:=(0), origin:=(0), code:=(0), refused:=(0), preRefused:=(0), refusalStamp:=(0), final:=(0), landing:=(0)}
def refuseBeforeEntryGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(0))) ∧ (q.domainOpen=(0)))
def refuseBeforeEntryNext (q : State) : State := {q with phase:=(7), origin:=(1), code:=(1), refused:=(1), preRefused:=(1), refusalStamp:=q.handlerEntries}
def exhaustPoolGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(0))) ∧ (q.pool=(1)))
def exhaustPoolNext (q : State) : State := {q with pool:=(0)}
def refuseNoRecordGuard (q : State) : Prop := ((((q.managed=(1)) ∧ (q.phase=(0))) ∧ (q.domainOpen=(1))) ∧ (q.pool=(0)))
def refuseNoRecordNext (q : State) : State := {q with phase:=(7), origin:=(3), code:=(2)}
def reserveGuardGuard (q : State) : Prop := ((((q.managed=(1)) ∧ (q.phase=(0))) ∧ (q.domainOpen=(1))) ∧ (q.pool=(1)))
def reserveGuardNext (q : State) : State := {q with phase:=(1), guard:=(1), guardCreates:=(1), root:=(1)}
def ackHandoffGuard (q : State) : Prop := ((((q.managed=(1)) ∧ (q.phase=(1))) ∧ (q.guard=(1))) ∧ (q.root=(1)))
def ackHandoffNext (q : State) : State := {q with phase:=(2), sourcePin:=(0), sourceDrops:=(1)}
def cancelBeforeAckGuard (q : State) : Prop := ((((q.managed=(1)) ∧ (q.phase=(1))) ∧ (q.guard=(1))) ∧ (q.root=(1)))
def cancelBeforeAckNext (q : State) : State := {q with phase:=(6), origin:=(4), code:=(3), landing:=(1)}
def allocateMarkerGuard (q : State) : Prop := (((((q.managed=(1)) ∧ (q.phase=(2))) ∧ (q.domainOpen=(1))) ∧ (q.guard=(1))) ∧ (q.root=(1)))
def allocateMarkerNext (q : State) : State := {q with phase:=(3), marker:=(1), markerCreates:=(1), allocs:=(1)}
def markerFailureGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(2))) ∧ (q.domainOpen=(1)))
def markerFailureNext (q : State) : State := {q with phase:=(6), origin:=(3), code:=(2)}
def beginBodyGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(3))) ∧ (q.domainOpen=(1)))
def beginBodyNext (q : State) : State := {q with phase:=(4), bodyEntries:=(1)}
def conversionFailureGuard (q : State) : Prop := (((q.managed=(1)) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.domainOpen=(1)))
def conversionFailureNext (q : State) : State := {q with phase:=(5), origin:=(2), code:=(2)}
def opaqueConversionFailureGuard (q : State) : Prop := (((q.managed=(1)) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.domainOpen=(1)))
def opaqueConversionFailureNext (q : State) : State := {q with phase:=(5), origin:=(2), code:=(1)}
def finishSuccessGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(4))) ∧ (q.domainOpen=(1)))
def finishSuccessNext (q : State) : State := {q with phase:=(6), origin:=(5), code:=(0)}
def callRefusedGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(3))) ∧ (q.domainOpen=(0)))
def callRefusedNext (q : State) : State := {q with phase:=(6), origin:=(1), code:=(1), refused:=(1), refusalStamp:=q.handlerEntries}
def handlerRefusedGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(5))) ∧ (q.domainOpen=(0)))
def handlerRefusedNext (q : State) : State := {q with phase:=(6), origin:=(1), code:=(1), refused:=(1), refusalStamp:=q.handlerEntries}
def recoverGoodGuard (q : State) : Prop := (((((q.managed=(1)) ∧ (q.phase=(5))) ∧ (q.origin=(2))) ∧ (q.domainOpen=(1))) ∧ (q.refused=(0)))
def recoverGoodNext (q : State) : State := {q with phase:=(6), origin:=(5), code:=(0), handlerEntries:=(q.handlerEntries+(1))}
def recoverBadGuard (q : State) : Prop := (((((q.managed=(1)) ∧ (q.phase=(5))) ∧ (q.origin=(2))) ∧ (q.domainOpen=(1))) ∧ (q.refused=(0)))
def recoverBadNext (q : State) : State := {q with phase:=(5), code:=(1), handlerEntries:=(q.handlerEntries+(1))}
def outerThrowGuard (q : State) : Prop := ((q.managed=(1)) ∧ ((((q.phase=(2)) ∨ (q.phase=(3))) ∨ (q.phase=(4))) ∨ (q.phase=(5))))
def outerThrowNext (q : State) : State := {q with phase:=(6), origin:=(4), code:=(3), landing:=(1)}
def releaseMarkerGuard (q : State) : Prop := (((((q.managed=(1)) ∧ (q.phase=(6))) ∧ (q.marker=(1))) ∧ (q.guard=(1))) ∧ (q.domainOpen=(1)))
def releaseMarkerNext (q : State) : State := {q with marker:=(0), markerDrops:=(q.markerDrops+(1))}
def closeGuardGuard (q : State) : Prop := (((((q.managed=(1)) ∧ (q.phase=(6))) ∧ (q.marker=(0))) ∧ (q.guard=(1))) ∧ (q.domainOpen=(1)))
def closeGuardNext (q : State) : State := {q with phase:=(7), guard:=(0), guardDrops:=(q.guardDrops+(1)), root:=(0)}
def dropRefusedSourceGuard (q : State) : Prop := (((q.managed=(1)) ∧ (q.phase=(7))) ∧ (q.sourcePin=(1)))
def dropRefusedSourceNext (q : State) : State := {q with sourcePin:=(0), sourceDrops:=(1)}
def deliverGuard (q : State) : Prop := ((((((q.managed=(1)) ∧ (q.phase=(7))) ∧ (q.sourcePin=(0))) ∧ (q.marker=(0))) ∧ (q.guard=(0))) ∧ (q.root=(0)))
def deliverNext (q : State) : State := {q with phase:=(8), final:=(1)}
def closeDomainGuard (q : State) : Prop := (q.domainOpen=(1))
def closeDomainNext (q : State) : State := {q with domainOpen:=(0)}
def resumeDomainGuard (q : State) : Prop := (q.domainOpen=(0))
def resumeDomainNext (q : State) : State := {q with domainOpen:=(1)}
def legacyMarkerSuccessGuard (q : State) : Prop := (((q.managed=(0)) ∧ (q.phase=(0))) ∧ (q.domainOpen=(0)))
def legacyMarkerSuccessNext (q : State) : State := {q with phase:=(3), marker:=(1), markerCreates:=(1), allocs:=(1)}
def legacyRejectCallGuard (q : State) : Prop := (((q.managed=(0)) ∧ (q.phase=(3))) ∧ (q.domainOpen=(0)))
def legacyRejectCallNext (q : State) : State := {q with phase:=(5), origin:=(1), code:=(1), refused:=(1)}
def legacyErrorRetryGuard (q : State) : Prop := ((((q.managed=(0)) ∧ (q.phase=(5))) ∧ (q.domainOpen=(0))) ∧ (q.code=(1)))
def legacyErrorRetryNext (q : State) : State := {q with legacyRetries:=(q.legacyRetries+(1))}
def legacyMarkerFailureGuard (q : State) : Prop := (((q.managed=(0)) ∧ (q.phase=(0))) ∧ (q.domainOpen=(0)))
def legacyMarkerFailureNext (q : State) : State := {q with phase:=(6), origin:=(3), code:=(2)}
def Step (q r : State) : Prop := (refuseBeforeEntryGuard q ∧ r=refuseBeforeEntryNext q) ∨ (exhaustPoolGuard q ∧ r=exhaustPoolNext q) ∨ (refuseNoRecordGuard q ∧ r=refuseNoRecordNext q) ∨ (reserveGuardGuard q ∧ r=reserveGuardNext q) ∨ (ackHandoffGuard q ∧ r=ackHandoffNext q) ∨ (cancelBeforeAckGuard q ∧ r=cancelBeforeAckNext q) ∨ (allocateMarkerGuard q ∧ r=allocateMarkerNext q) ∨ (markerFailureGuard q ∧ r=markerFailureNext q) ∨ (beginBodyGuard q ∧ r=beginBodyNext q) ∨ (conversionFailureGuard q ∧ r=conversionFailureNext q) ∨ (opaqueConversionFailureGuard q ∧ r=opaqueConversionFailureNext q) ∨ (finishSuccessGuard q ∧ r=finishSuccessNext q) ∨ (callRefusedGuard q ∧ r=callRefusedNext q) ∨ (handlerRefusedGuard q ∧ r=handlerRefusedNext q) ∨ (recoverGoodGuard q ∧ r=recoverGoodNext q) ∨ (recoverBadGuard q ∧ r=recoverBadNext q) ∨ (outerThrowGuard q ∧ r=outerThrowNext q) ∨ (releaseMarkerGuard q ∧ r=releaseMarkerNext q) ∨ (closeGuardGuard q ∧ r=closeGuardNext q) ∨ (dropRefusedSourceGuard q ∧ r=dropRefusedSourceNext q) ∨ (deliverGuard q ∧ r=deliverNext q) ∨ (closeDomainGuard q ∧ r=closeDomainNext q) ∨ (resumeDomainGuard q ∧ r=resumeDomainNext q) ∨ (legacyMarkerSuccessGuard q ∧ r=legacyMarkerSuccessNext q) ∨ (legacyRejectCallGuard q ∧ r=legacyRejectCallNext q) ∨ (legacyErrorRetryGuard q ∧ r=legacyErrorRetryNext q) ∨ (legacyMarkerFailureGuard q ∧ r=legacyMarkerFailureNext q) ∨ r=q
end SfunAdmissionAst
