import Std
namespace ImageEnrollmentAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 epoch : Int
 vm1 : Int
 incarnation : Int
 ticketEpoch : Int
 receiptEpoch0 : Int
 receiptEpoch1 : Int
 receiptInc1 : Int
 users0 : Int
 users1 : Int
 observers : Int
 denied : Int
 helperKnown : Bool
 membersSealed : Bool
 mappingQualified : Bool
 ownedFacade : Bool
 rawEscape : Bool
 expected1 : Bool
 closed0 : Bool
 closed1 : Bool
 receipt0 : Bool
 receipt1 : Bool
 externalDrained : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(2)) ∧ (q.epoch≥(1)) ∧ (q.epoch≤(2)) ∧ (q.vm1≥(0)) ∧ (q.vm1≤(4)) ∧ (q.incarnation≥(1)) ∧ (q.incarnation≤(2)) ∧ (q.ticketEpoch≥(0)) ∧ (q.ticketEpoch≤q.epoch) ∧ (q.receiptEpoch0≥(0)) ∧ (q.receiptEpoch0≤q.epoch) ∧ (q.receiptEpoch1≥(0)) ∧ (q.receiptEpoch1≤q.epoch) ∧ (q.receiptInc1≥(0)) ∧ (q.receiptInc1≤q.incarnation) ∧ (q.users0≥(0)) ∧ (q.users0≤(1)) ∧ (q.users1≥(0)) ∧ (q.users1≤(1)) ∧ (q.observers≥(0)) ∧ (q.observers≤(1)) ∧ (q.denied≥(0)) ∧ ((q.membersSealed=true) → ((q.helperKnown=true) ∧ (q.mappingQualified=true))) ∧ ((q.receipt0=true) → ((((q.phase≥(1)) ∧ (q.closed0=true)) ∧ (q.users0=(0))) ∧ (q.receiptEpoch0=q.epoch))) ∧ ((q.receipt1=true) → ((((((q.phase≥(1)) ∧ (q.closed1=true)) ∧ (q.users1=(0))) ∧ (q.receiptEpoch1=q.epoch)) ∧ (q.receiptInc1=q.incarnation)) ∧ ((q.vm1=(2)) ∨ (q.vm1=(3))))) ∧ ((q.phase≥(1)) → ((q.expected1=true) ↔ (q.vm1≠(0)))) ∧ ((q.phase=(2)) → (((((((((q.membersSealed=true) ∧ (q.ownedFacade=true)) ∧ (¬(q.rawEscape=true))) ∧ (q.receipt0=true)) ∧ ((q.expected1=true) → (q.receipt1=true))) ∧ (q.observers=(0))) ∧ (q.externalDrained=true)) ∧ (q.vm1≠(1))) ∧ (q.vm1≠(4)))) ∧ ((q.vm1=(0)) → (q.users1=(0))) ∧ ((q.vm1=(3)) → (q.users1=(0))) ∧ ((q.vm1=(1)) → (q.users1=(0))))
def initial : State := {phase:=(0), epoch:=(1), vm1:=(0), incarnation:=(1), ticketEpoch:=(0), receiptEpoch0:=(0), receiptEpoch1:=(0), receiptInc1:=(0), users0:=(1), users1:=(0), observers:=(0), denied:=(0), helperKnown:=false, membersSealed:=false, mappingQualified:=true, ownedFacade:=false, rawEscape:=false, expected1:=false, closed0:=false, closed1:=false, receipt0:=false, receipt1:=false, externalDrained:=true}
def enumerateHelperGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.membersSealed=true))
def enumerateHelperNext (q : State) : State := {q with helperKnown:=true}
def sealMembersGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.helperKnown=true) ∧ (q.mappingQualified=true)
def sealMembersNext (q : State) : State := {q with membersSealed:=true}
def prepareOwnedGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.membersSealed=true)
def prepareOwnedNext (q : State) : State := {q with ownedFacade:=true}
def exposeRawGuard (q : State) : Prop := (q.phase=(0))
def exposeRawNext (q : State) : State := {q with rawEscape:=true}
def reserveOwnerGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.vm1=(0))
def reserveOwnerNext (q : State) : State := {q with vm1:=(1), ticketEpoch:=q.epoch}
def commitOpenGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.vm1=(1))
def commitOpenNext (q : State) : State := {q with vm1:=(2), users1:=(1), closed1:=false}
def closeGlobalGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.membersSealed=true)
def closeGlobalNext (q : State) : State := {q with phase:=(1), epoch:=(2), expected1:=(decide (q.vm1≠(0)))}
def commitClosingGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.expected1=true) ∧ (q.vm1=(1))
def commitClosingNext (q : State) : State := {q with vm1:=(2), users1:=(1), closed1:=true}
def abortReservedGuard (q : State) : Prop := (q.vm1=(1)) ∧ (q.phase≤(1))
def abortReservedNext (q : State) : State := {q with vm1:=(3), closed1:=true}
def unknownOwnerGuard (q : State) : Prop := ((q.vm1=(1)) ∨ (q.vm1=(2))) ∧ (q.phase≤(1))
def unknownOwnerNext (q : State) : State := {q with vm1:=(4), closed1:=true, receipt1:=false}
def close0Guard (q : State) : Prop := (q.phase=(1))
def close0Next (q : State) : State := {q with closed0:=true}
def close1Guard (q : State) : Prop := (q.vm1=(2)) ∧ (q.phase≤(1))
def close1Next (q : State) : State := {q with closed1:=true}
def return0Guard (q : State) : Prop := (q.users0=(1))
def return0Next (q : State) : State := {q with users0:=(0)}
def return1Guard (q : State) : Prop := (q.users1=(1))
def return1Next (q : State) : State := {q with users1:=(0)}
def exitKnownGuard (q : State) : Prop := (q.vm1=(2)) ∧ (q.closed1=true) ∧ (q.users1=(0)) ∧ (q.phase≤(1))
def exitKnownNext (q : State) : State := {q with vm1:=(3)}
def reuseBeforeCloseGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.vm1=(3)) ∧ (q.incarnation=(1))
def reuseBeforeCloseNext (q : State) : State := {q with vm1:=(0), incarnation:=(2), closed1:=false, ticketEpoch:=(0)}
def issue0Guard (q : State) : Prop := (q.phase=(1)) ∧ (q.closed0=true) ∧ (q.users0=(0))
def issue0Next (q : State) : State := {q with receipt0:=true, receiptEpoch0:=q.epoch}
def issue1Guard (q : State) : Prop := (q.phase=(1)) ∧ (q.expected1=true) ∧ (q.closed1=true) ∧ (q.users1=(0)) ∧ ((q.vm1=(2)) ∨ (q.vm1=(3)))
def issue1Next (q : State) : State := {q with receipt1:=true, receiptEpoch1:=q.epoch, receiptInc1:=q.incarnation}
def observeGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.observers=(0))
def observeNext (q : State) : State := {q with observers:=(1)}
def retireObserverGuard (q : State) : Prop := (q.observers=(1))
def retireObserverNext (q : State) : State := {q with observers:=(0)}
def borrow0Guard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.closed0=true)) ∧ (q.users0=(0))
def borrow0Next (q : State) : State := {q with users0:=(1)}
def borrow1Guard (q : State) : Prop := (q.phase=(0)) ∧ (q.vm1=(2)) ∧ (¬(q.closed1=true)) ∧ (q.users1=(0))
def borrow1Next (q : State) : State := {q with users1:=(1)}
def rejectLateGuard (q : State) : Prop := (q.phase≥(1))
def rejectLateNext (q : State) : State := {q with denied:=(q.denied+(1))}
def rejectStaleGuard (q : State) : Prop := (q.phase≥(1))
def rejectStaleNext (q : State) : State := {q with denied:=(q.denied+(1))}
def unknownExternalGuard (q : State) : Prop := (q.phase≤(1))
def unknownExternalNext (q : State) : State := {q with externalDrained:=false}
def permitGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.membersSealed=true) ∧ (q.ownedFacade=true) ∧ (¬(q.rawEscape=true)) ∧ (q.receipt0=true) ∧ ((¬(q.expected1=true)) ∨ (q.receipt1=true)) ∧ (q.observers=(0)) ∧ (q.externalDrained=true) ∧ (q.vm1≠(1)) ∧ (q.vm1≠(4))
def permitNext (q : State) : State := {q with phase:=(2)}
def invalidateMembershipGuard (q : State) : Prop := (q.phase≤(1))
def invalidateMembershipNext (q : State) : State := {q with membersSealed:=false, mappingQualified:=false}
def Step (q r : State) : Prop := (enumerateHelperGuard q ∧ r=enumerateHelperNext q) ∨ (sealMembersGuard q ∧ r=sealMembersNext q) ∨ (prepareOwnedGuard q ∧ r=prepareOwnedNext q) ∨ (exposeRawGuard q ∧ r=exposeRawNext q) ∨ (reserveOwnerGuard q ∧ r=reserveOwnerNext q) ∨ (commitOpenGuard q ∧ r=commitOpenNext q) ∨ (closeGlobalGuard q ∧ r=closeGlobalNext q) ∨ (commitClosingGuard q ∧ r=commitClosingNext q) ∨ (abortReservedGuard q ∧ r=abortReservedNext q) ∨ (unknownOwnerGuard q ∧ r=unknownOwnerNext q) ∨ (close0Guard q ∧ r=close0Next q) ∨ (close1Guard q ∧ r=close1Next q) ∨ (return0Guard q ∧ r=return0Next q) ∨ (return1Guard q ∧ r=return1Next q) ∨ (exitKnownGuard q ∧ r=exitKnownNext q) ∨ (reuseBeforeCloseGuard q ∧ r=reuseBeforeCloseNext q) ∨ (issue0Guard q ∧ r=issue0Next q) ∨ (issue1Guard q ∧ r=issue1Next q) ∨ (observeGuard q ∧ r=observeNext q) ∨ (retireObserverGuard q ∧ r=retireObserverNext q) ∨ (borrow0Guard q ∧ r=borrow0Next q) ∨ (borrow1Guard q ∧ r=borrow1Next q) ∨ (rejectLateGuard q ∧ r=rejectLateNext q) ∨ (rejectStaleGuard q ∧ r=rejectStaleNext q) ∨ (unknownExternalGuard q ∧ r=unknownExternalNext q) ∨ (permitGuard q ∧ r=permitNext q) ∨ (invalidateMembershipGuard q ∧ r=invalidateMembershipNext q) ∨ r=q
end ImageEnrollmentAst
