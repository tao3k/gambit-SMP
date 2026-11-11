import Std
namespace SavedResultRetirementAst
set_option maxRecDepth 10000
structure State where
 a : Int
 b : Int
 c : Int
 complete : Int
 observerGate : Int
 observer : Int
 issuer : Int
 recordLive : Int
 generation : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.a≥(0)) ∧ (q.b≥(0)) ∧ (q.c≥(0)) ∧ (q.complete≥(0)) ∧ (q.observerGate≥(0)) ∧ (q.observer≥(0)) ∧ (q.issuer≥(0)) ∧ (q.recordLive≥(0)) ∧ (q.generation≥(0)) ∧ (q.a≤(6)) ∧ (q.b≤(4)) ∧ (q.c≤(4)) ∧ (q.complete≤(1)) ∧ (q.observerGate≤(1)) ∧ (q.observer≤(1)) ∧ (q.issuer≤(1)) ∧ (q.recordLive≤(1)) ∧ (q.generation≤(2)) ∧ (q.generation≥(1)) ∧ ((q.a=(0)) → ((q.b=(0)) ∧ (q.c=(0)))) ∧ ((q.a=(1)) → (q.c=(0))) ∧ ((q.a=(2)) → (q.b≥(2))) ∧ ((q.a=(3)) → ((q.b=(4)) ∧ ((q.c=(0)) ∨ (q.c=(4))))) ∧ (((q.a≥(4)) ∧ (q.a≤(6))) → (((q.b=(0)) ∨ (q.b=(4))) ∧ ((q.c=(0)) ∨ (q.c=(4))))) ∧ ((q.c≥(1)) → (q.b≥(2))) ∧ ((q.observer=(1)) → (q.recordLive=(1))) ∧ ((q.observerGate=(1)) → (q.recordLive=(1))) ∧ ((q.recordLive=(0)) → ((q.complete=(1)) ∧ (q.a=(6)) ∧ ((q.b=(0)) ∨ (q.b=(4))) ∧ ((q.c=(0)) ∨ (q.c=(4))) ∧ (q.observerGate=(0)) ∧ (q.observer=(0)) ∧ (q.issuer=(0)))) ∧ ((q.issuer=(0)) → ((q.complete=(1)) ∧ (q.a=(6)) ∧ ((q.b=(0)) ∨ (q.b=(4))) ∧ ((q.c=(0)) ∨ (q.c=(4))))))
def initial : State := {a:=(0), b:=(0), c:=(0), complete:=(0), observerGate:=(1), observer:=(0), issuer:=(1), recordLive:=(1), generation:=(1)}
def saveAGuard (q : State) : Prop := (q.a=(0))
def saveANext (q : State) : State := {q with a:=(1)}
def installBGuard (q : State) : Prop := ((q.a=(1)) ∧ (q.b=(0)))
def installBNext (q : State) : State := {q with b:=(1)}
def beginRestoreGuard (q : State) : Prop := ((q.a=(1)) ∧ (q.b=(1)))
def beginRestoreNext (q : State) : State := {q with a:=(2), b:=(2)}
def reenterPublishCGuard (q : State) : Prop := (((q.a=(2)) ∧ (q.b=(2))) ∧ (q.c=(0)))
def reenterPublishCNext (q : State) : State := {q with c:=(1)}
def loseBGuard (q : State) : Prop := (q.b=(2))
def loseBNext (q : State) : State := {q with b:=(3)}
def ackBGuard (q : State) : Prop := ((q.b=(2)) ∨ (q.b=(3)))
def ackBNext (q : State) : State := {q with b:=(4)}
def beginCReleaseGuard (q : State) : Prop := (q.c=(1))
def beginCReleaseNext (q : State) : State := {q with c:=(2)}
def loseCGuard (q : State) : Prop := (q.c=(2))
def loseCNext (q : State) : State := {q with c:=(3)}
def ackCGuard (q : State) : Prop := ((q.c=(2)) ∨ (q.c=(3)))
def ackCNext (q : State) : State := {q with c:=(4)}
def commitRestoreGuard (q : State) : Prop := (((q.a=(2)) ∧ (q.b=(4))) ∧ ((q.c=(0)) ∨ (q.c=(4))))
def commitRestoreNext (q : State) : State := {q with a:=(3)}
def beginDiscardGuard (q : State) : Prop := ((q.a=(1)) ∧ (q.b=(0)))
def beginDiscardNext (q : State) : State := {q with a:=(4)}
def beginRestoredReleaseGuard (q : State) : Prop := (q.a=(3))
def beginRestoredReleaseNext (q : State) : State := {q with a:=(4)}
def loseAGuard (q : State) : Prop := (q.a=(4))
def loseANext (q : State) : State := {q with a:=(5)}
def ackAGuard (q : State) : Prop := ((q.a=(4)) ∨ (q.a=(5)))
def ackANext (q : State) : State := {q with a:=(6)}
def completeFirstGuard (q : State) : Prop := (((q.generation=(1)) ∧ (q.issuer=(1))) ∧ (q.complete=(0)))
def completeFirstNext (q : State) : State := {q with complete:=(1)}
def completeSecondGuard (q : State) : Prop := (((q.generation=(2)) ∧ (q.issuer=(1))) ∧ (q.complete=(0)))
def completeSecondNext (q : State) : State := {q with complete:=(1)}
def lookupRecordGuard (q : State) : Prop := (((q.observerGate=(1)) ∧ (q.recordLive=(1))) ∧ (q.observer=(0)))
def lookupRecordNext (q : State) : State := {q with observer:=(1)}
def returnRecordGuard (q : State) : Prop := (q.observer=(1))
def returnRecordNext (q : State) : State := {q with observer:=(0)}
def closeObserverGateGuard (q : State) : Prop := (q.observerGate=(1))
def closeObserverGateNext (q : State) : State := {q with observerGate:=(0)}
def closeIssuerGuard (q : State) : Prop := (((((q.complete=(1)) ∧ (q.a=(6))) ∧ ((q.b=(0)) ∨ (q.b=(4)))) ∧ ((q.c=(0)) ∨ (q.c=(4)))) ∧ (q.issuer=(1)))
def closeIssuerNext (q : State) : State := {q with issuer:=(0)}
def retireRecordGuard (q : State) : Prop := ((((((((q.complete=(1)) ∧ (q.a=(6))) ∧ ((q.b=(0)) ∨ (q.b=(4)))) ∧ ((q.c=(0)) ∨ (q.c=(4)))) ∧ (q.observerGate=(0))) ∧ (q.observer=(0))) ∧ (q.issuer=(0))) ∧ (q.recordLive=(1)))
def retireRecordNext (q : State) : State := {q with recordLive:=(0)}
def reuseSlotGuard (q : State) : Prop := ((q.recordLive=(0)) ∧ (q.generation=(1)))
def reuseSlotNext (q : State) : State := {q with a:=(0), b:=(0), c:=(0), complete:=(0), observerGate:=(1), issuer:=(1), recordLive:=(1), generation:=(2)}
def Step (q r : State) : Prop := (saveAGuard q ∧ r=saveANext q) ∨ (installBGuard q ∧ r=installBNext q) ∨ (beginRestoreGuard q ∧ r=beginRestoreNext q) ∨ (reenterPublishCGuard q ∧ r=reenterPublishCNext q) ∨ (loseBGuard q ∧ r=loseBNext q) ∨ (ackBGuard q ∧ r=ackBNext q) ∨ (beginCReleaseGuard q ∧ r=beginCReleaseNext q) ∨ (loseCGuard q ∧ r=loseCNext q) ∨ (ackCGuard q ∧ r=ackCNext q) ∨ (commitRestoreGuard q ∧ r=commitRestoreNext q) ∨ (beginDiscardGuard q ∧ r=beginDiscardNext q) ∨ (beginRestoredReleaseGuard q ∧ r=beginRestoredReleaseNext q) ∨ (loseAGuard q ∧ r=loseANext q) ∨ (ackAGuard q ∧ r=ackANext q) ∨ (completeFirstGuard q ∧ r=completeFirstNext q) ∨ (completeSecondGuard q ∧ r=completeSecondNext q) ∨ (lookupRecordGuard q ∧ r=lookupRecordNext q) ∨ (returnRecordGuard q ∧ r=returnRecordNext q) ∨ (closeObserverGateGuard q ∧ r=closeObserverGateNext q) ∨ (closeIssuerGuard q ∧ r=closeIssuerNext q) ∨ (retireRecordGuard q ∧ r=retireRecordNext q) ∨ (reuseSlotGuard q ∧ r=reuseSlotNext q) ∨ r=q
end SavedResultRetirementAst
