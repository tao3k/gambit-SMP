import Std
namespace CallbackProducerAst
set_option maxRecDepth 10000
structure State where
 gate : Int
 producer : Int
 ticket : Int
 phase : Int
 done : Int
 receipt : Int
 resultPhase : Int
 resultReceipt : Int
 origin : Int
 retired : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.gate≥(0)) ∧ (q.producer≥(0)) ∧ (q.ticket≥(0)) ∧ (q.phase≥(0)) ∧ (q.done≥(0)) ∧ (q.receipt≥(0)) ∧ (q.resultPhase≥(0)) ∧ (q.resultReceipt≥(0)) ∧ (q.origin≥(0)) ∧ (q.retired≥(0)) ∧ (q.gate≤(1)) ∧ (q.producer≤(1)) ∧ (q.ticket≤(2)) ∧ (q.phase≤(5)) ∧ (q.done≤(2)) ∧ (q.receipt≤(1)) ∧ (q.resultPhase≤(4)) ∧ (q.resultReceipt≤(1)) ∧ (q.origin≤(1)) ∧ (q.retired≤(1)) ∧ (q.done≤q.ticket) ∧ ((q.ticket-q.done)≤(1)) ∧ ((q.phase=(0)) → ((q.ticket=(0)) ∧ (q.done=(0)) ∧ (q.receipt=(0)))) ∧ (((q.phase≥(1)) ∧ (q.phase≤(4))) → ((q.producer=(1)) ∧ (q.ticket≥(1)) ∧ (q.ticket=(q.done+(1))))) ∧ ((q.phase=(5)) → ((q.done=q.ticket) ∧ (q.ticket≥(1)) ∧ (q.receipt=(1)))) ∧ ((q.receipt=(1)) → (((q.phase=(3)) ∨ (q.phase=(4))) ∨ (q.phase=(5)))) ∧ ((q.producer=(0)) → (((q.phase=(0)) ∨ (q.phase=(5))) ∧ (q.done=q.ticket))) ∧ ((q.resultPhase=(0)) → ((q.origin=(0)) ∧ (q.resultReceipt=(0)))) ∧ (((q.resultPhase≥(1)) ∧ (q.resultPhase≤(3))) → (q.origin=(1))) ∧ ((q.resultPhase=(1)) → (q.resultReceipt=(0))) ∧ ((q.resultReceipt=(1)) → (q.resultPhase≥(2))) ∧ ((q.resultPhase=(4)) → ((q.origin=(0)) ∧ (q.resultReceipt=(1)))) ∧ ((q.retired=(1)) → ((q.gate=(0)) ∧ (q.producer=(0)) ∧ (q.done=q.ticket) ∧ ((q.phase=(0)) ∨ (q.phase=(5))) ∧ ((q.resultPhase=(0)) ∨ (q.resultPhase=(4))) ∧ (q.origin=(0)))) ∧ ((q.producer=(1)) → (q.retired=(0))))
def initial : State := {gate:=(1), producer:=(1), ticket:=(0), phase:=(0), done:=(0), receipt:=(0), resultPhase:=(0), resultReceipt:=(0), origin:=(0), retired:=(0)}
def closeRootsGuard (q : State) : Prop := (q.gate=(1))
def closeRootsNext (q : State) : State := {q with gate:=(0)}
def dispatchChildGuard (q : State) : Prop := ((((q.producer=(1)) ∧ ((q.phase=(0)) ∨ (q.phase=(5)))) ∧ (q.done=q.ticket)) ∧ (q.ticket<(2)))
def dispatchChildNext (q : State) : State := {q with ticket:=(q.ticket+(1)), phase:=(1), receipt:=(0)}
def landingFirstGuard (q : State) : Prop := ((q.ticket=(1)) ∧ (q.phase=(1)))
def landingFirstNext (q : State) : State := {q with phase:=(2)}
def landingSecondGuard (q : State) : Prop := ((q.ticket=(2)) ∧ (q.phase=(1)))
def landingSecondNext (q : State) : State := {q with phase:=(2)}
def beginCleanupGuard (q : State) : Prop := (q.phase=(2))
def beginCleanupNext (q : State) : State := {q with phase:=(3)}
def loseCleanupGuard (q : State) : Prop := (q.phase=(3))
def loseCleanupNext (q : State) : State := {q with phase:=(4)}
def cleanupReceiptFirstGuard (q : State) : Prop := (((q.ticket=(1)) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.receipt=(0)))
def cleanupReceiptFirstNext (q : State) : State := {q with receipt:=(1)}
def cleanupReceiptSecondGuard (q : State) : Prop := (((q.ticket=(2)) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.receipt=(0)))
def cleanupReceiptSecondNext (q : State) : State := {q with receipt:=(1)}
def settleFirstGuard (q : State) : Prop := ((((q.ticket=(1)) ∧ (q.done=(0))) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.receipt=(1)))
def settleFirstNext (q : State) : State := {q with done:=(1), phase:=(5)}
def settleSecondGuard (q : State) : Prop := ((((q.ticket=(2)) ∧ (q.done=(1))) ∧ ((q.phase=(3)) ∨ (q.phase=(4)))) ∧ (q.receipt=(1)))
def settleSecondNext (q : State) : State := {q with done:=(2), phase:=(5)}
def sealProducerGuard (q : State) : Prop := (((q.producer=(1)) ∧ ((q.phase=(0)) ∨ (q.phase=(5)))) ∧ (q.done=q.ticket))
def sealProducerNext (q : State) : State := {q with producer:=(0)}
def publishResultGuard (q : State) : Prop := (((q.producer=(1)) ∧ (q.phase=(2))) ∧ (q.resultPhase=(0)))
def publishResultNext (q : State) : State := {q with resultPhase:=(1), origin:=(1)}
def beginResultReleaseGuard (q : State) : Prop := (q.resultPhase=(1))
def beginResultReleaseNext (q : State) : State := {q with resultPhase:=(2)}
def loseResultReleaseGuard (q : State) : Prop := (q.resultPhase=(2))
def loseResultReleaseNext (q : State) : State := {q with resultPhase:=(3)}
def resultReleaseReceiptGuard (q : State) : Prop := (((q.resultPhase=(2)) ∨ (q.resultPhase=(3))) ∧ (q.resultReceipt=(0)))
def resultReleaseReceiptNext (q : State) : State := {q with resultReceipt:=(1)}
def settleResultReleaseGuard (q : State) : Prop := (((q.resultPhase=(2)) ∨ (q.resultPhase=(3))) ∧ (q.resultReceipt=(1)))
def settleResultReleaseNext (q : State) : State := {q with resultPhase:=(4), origin:=(0)}
def retireDomainGuard (q : State) : Prop := (((((((q.gate=(0)) ∧ (q.producer=(0))) ∧ (q.done=q.ticket)) ∧ ((q.phase=(0)) ∨ (q.phase=(5)))) ∧ ((q.resultPhase=(0)) ∨ (q.resultPhase=(4)))) ∧ (q.origin=(0))) ∧ (q.retired=(0)))
def retireDomainNext (q : State) : State := {q with retired:=(1)}
def Step (q r : State) : Prop := (closeRootsGuard q ∧ r=closeRootsNext q) ∨ (dispatchChildGuard q ∧ r=dispatchChildNext q) ∨ (landingFirstGuard q ∧ r=landingFirstNext q) ∨ (landingSecondGuard q ∧ r=landingSecondNext q) ∨ (beginCleanupGuard q ∧ r=beginCleanupNext q) ∨ (loseCleanupGuard q ∧ r=loseCleanupNext q) ∨ (cleanupReceiptFirstGuard q ∧ r=cleanupReceiptFirstNext q) ∨ (cleanupReceiptSecondGuard q ∧ r=cleanupReceiptSecondNext q) ∨ (settleFirstGuard q ∧ r=settleFirstNext q) ∨ (settleSecondGuard q ∧ r=settleSecondNext q) ∨ (sealProducerGuard q ∧ r=sealProducerNext q) ∨ (publishResultGuard q ∧ r=publishResultNext q) ∨ (beginResultReleaseGuard q ∧ r=beginResultReleaseNext q) ∨ (loseResultReleaseGuard q ∧ r=loseResultReleaseNext q) ∨ (resultReleaseReceiptGuard q ∧ r=resultReleaseReceiptNext q) ∨ (settleResultReleaseGuard q ∧ r=settleResultReleaseNext q) ∨ (retireDomainGuard q ∧ r=retireDomainNext q) ∨ r=q
end CallbackProducerAst
