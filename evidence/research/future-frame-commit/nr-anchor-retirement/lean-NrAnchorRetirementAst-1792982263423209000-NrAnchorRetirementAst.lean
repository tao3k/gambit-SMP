import Std
namespace NrAnchorRetirementAst
set_option maxRecDepth 10000
structure State where
 token : Int
 queue : Int
 node : Int
 done : Int
 eeLive : Int
 senders : Int
 anchorPin : Int
 recordPin : Int
 recordGate : Int
 recordLive : Int
 generation : Int
 rawClosed : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.token≥(0)) ∧ (q.queue≥(0)) ∧ (q.node≥(0)) ∧ (q.done≥(0)) ∧ (q.eeLive≥(0)) ∧ (q.senders≥(0)) ∧ (q.anchorPin≥(0)) ∧ (q.recordPin≥(0)) ∧ (q.recordGate≥(0)) ∧ (q.recordLive≥(0)) ∧ (q.generation≥(0)) ∧ (q.rawClosed≥(0)) ∧ (q.token≤(6)) ∧ (q.queue≤(1)) ∧ (q.node≤(1)) ∧ (q.done≤(1)) ∧ (q.eeLive≤(1)) ∧ (q.senders≤(1)) ∧ (q.anchorPin≤(1)) ∧ (q.recordPin≤(1)) ∧ (q.recordGate≤(1)) ∧ (q.recordLive≤(1)) ∧ (q.generation≤(2)) ∧ (q.rawClosed≤(1)) ∧ (q.generation≥(1)) ∧ ((q.token=(0)) → ((q.node=(0)) ∧ (q.queue=(0)))) ∧ ((q.token=(1)) → ((q.node=(0)) ∧ (q.queue=(0)) ∧ (q.done=(0)) ∧ (q.eeLive=(1)))) ∧ ((q.token=(2)) → ((q.node=(1)) ∧ (q.queue=(1)) ∧ (q.done=(0)) ∧ (q.eeLive=(1)))) ∧ ((((q.token=(3)) ∨ (q.token=(4))) ∨ (q.token=(6))) → ((q.node=(1)) ∧ (q.queue=(0)) ∧ (q.done=(0)) ∧ (q.eeLive=(1)))) ∧ ((q.token=(5)) → ((q.node=(0)) ∧ (q.queue=(0)) ∧ (q.done=(1)))) ∧ ((q.queue=(1)) → (q.token=(2))) ∧ ((q.done=(1)) → (((q.token=(0)) ∨ (q.token=(5))) ∧ (q.node=(0)) ∧ (q.queue=(0)))) ∧ ((q.eeLive=(0)) → (q.done=(1))) ∧ ((q.recordPin=(1)) → ((q.anchorPin=(1)) ∧ (q.recordLive=(1)))) ∧ ((q.recordGate=(1)) → (q.recordLive=(1))) ∧ ((q.senders=(0)) → (q.done=(1))) ∧ ((q.rawClosed=(1)) → ((q.recordGate=(0)) ∧ (q.senders=(0)))) ∧ ((q.recordLive=(0)) → ((q.recordGate=(0)) ∧ (q.recordPin=(0)) ∧ (q.senders=(0)) ∧ (q.rawClosed=(1)) ∧ (q.done=(1)) ∧ (q.node=(0)) ∧ (q.queue=(0)))))
def initial : State := {token:=(0), queue:=(0), node:=(0), done:=(0), eeLive:=(1), senders:=(1), anchorPin:=(0), recordPin:=(0), recordGate:=(1), recordLive:=(1), generation:=(1), rawClosed:=(0)}
def produceErrorTokenGuard (q : State) : Prop := ((q.token=(0)) ∧ (q.done=(0)))
def produceErrorTokenNext (q : State) : State := {q with token:=(1)}
def completeNoTokenGuard (q : State) : Prop := ((q.token=(0)) ∧ (q.done=(0)))
def completeNoTokenNext (q : State) : State := {q with done:=(1)}
def enqueueTokenGuard (q : State) : Prop := (q.token=(1))
def enqueueTokenNext (q : State) : State := {q with token:=(2), queue:=(1), node:=(1)}
def claimPrivateTokenGuard (q : State) : Prop := (q.token=(1))
def claimPrivateTokenNext (q : State) : State := {q with token:=(3), node:=(1)}
def popCallbackGuard (q : State) : Prop := ((q.token=(2)) ∧ (q.queue=(1)))
def popCallbackNext (q : State) : State := {q with token:=(3), queue:=(0)}
def knownTokenConsumptionGuard (q : State) : Prop := (q.token=(3))
def knownTokenConsumptionNext (q : State) : State := {q with token:=(4)}
def unknownCallbackExitGuard (q : State) : Prop := (q.token=(3))
def unknownCallbackExitNext (q : State) : State := {q with token:=(6)}
def reconcileKnownConsumptionGuard (q : State) : Prop := (q.token=(6))
def reconcileKnownConsumptionNext (q : State) : State := {q with token:=(4)}
def finishLandingGuard (q : State) : Prop := ((q.token=(4)) ∧ (q.node=(1)))
def finishLandingNext (q : State) : State := {q with token:=(5), node:=(0), done:=(1)}
def exitOwnerEnvGuard (q : State) : Prop := (((((q.eeLive=(1)) ∧ (q.done=(1))) ∧ ((q.token=(0)) ∨ (q.token=(5)))) ∧ (q.node=(0))) ∧ (q.queue=(0)))
def exitOwnerEnvNext (q : State) : State := {q with eeLive:=(0)}
def acquireAnchorGuard (q : State) : Prop := (q.anchorPin=(0))
def acquireAnchorNext (q : State) : State := {q with anchorPin:=(1)}
def lookupFirstRecordGuard (q : State) : Prop := (((((q.anchorPin=(1)) ∧ (q.recordGate=(1))) ∧ (q.recordLive=(1))) ∧ (q.recordPin=(0))) ∧ (q.generation=(1)))
def lookupFirstRecordNext (q : State) : State := {q with recordPin:=(1)}
def lookupSecondRecordGuard (q : State) : Prop := (((((q.anchorPin=(1)) ∧ (q.recordGate=(1))) ∧ (q.recordLive=(1))) ∧ (q.recordPin=(0))) ∧ (q.generation=(2)))
def lookupSecondRecordNext (q : State) : State := {q with recordPin:=(1)}
def releaseRecordGuard (q : State) : Prop := (q.recordPin=(1))
def releaseRecordNext (q : State) : State := {q with recordPin:=(0)}
def releaseAnchorGuard (q : State) : Prop := ((q.anchorPin=(1)) ∧ (q.recordPin=(0)))
def releaseAnchorNext (q : State) : State := {q with anchorPin:=(0)}
def closeRecordGateGuard (q : State) : Prop := (q.recordGate=(1))
def closeRecordGateNext (q : State) : State := {q with recordGate:=(0)}
def closeSendersGuard (q : State) : Prop := (((q.done=(1)) ∧ ((q.token=(0)) ∨ (q.token=(5)))) ∧ (q.senders=(1)))
def closeSendersNext (q : State) : State := {q with senders:=(0)}
def closeRawRoutesGuard (q : State) : Prop := (((q.recordGate=(0)) ∧ (q.senders=(0))) ∧ (q.rawClosed=(0)))
def closeRawRoutesNext (q : State) : State := {q with rawClosed:=(1)}
def retireRecordGuard (q : State) : Prop := (((((((((q.recordLive=(1)) ∧ (q.recordGate=(0))) ∧ (q.recordPin=(0))) ∧ (q.senders=(0))) ∧ (q.rawClosed=(1))) ∧ (q.done=(1))) ∧ (q.node=(0))) ∧ (q.queue=(0))) ∧ ((q.token=(0)) ∨ (q.token=(5))))
def retireRecordNext (q : State) : State := {q with recordLive:=(0)}
def reuseSlotGuard (q : State) : Prop := (((q.recordLive=(0)) ∧ (q.anchorPin=(0))) ∧ (q.generation=(1)))
def reuseSlotNext (q : State) : State := {q with token:=(0), queue:=(0), node:=(0), done:=(0), eeLive:=(1), senders:=(1), recordGate:=(1), recordLive:=(1), generation:=(2), rawClosed:=(0)}
def acceptFirstAckGuard (q : State) : Prop := ((((q.anchorPin=(1)) ∧ (q.generation=(1))) ∧ (q.recordLive=(1))) ∧ (q.senders=(1)))
def acceptFirstAckNext (q : State) : State := {q with }
def rejectFirstAfterReuseGuard (q : State) : Prop := ((q.anchorPin=(1)) ∧ (q.generation=(2)))
def rejectFirstAfterReuseNext (q : State) : State := {q with }
def Step (q r : State) : Prop := (produceErrorTokenGuard q ∧ r=produceErrorTokenNext q) ∨ (completeNoTokenGuard q ∧ r=completeNoTokenNext q) ∨ (enqueueTokenGuard q ∧ r=enqueueTokenNext q) ∨ (claimPrivateTokenGuard q ∧ r=claimPrivateTokenNext q) ∨ (popCallbackGuard q ∧ r=popCallbackNext q) ∨ (knownTokenConsumptionGuard q ∧ r=knownTokenConsumptionNext q) ∨ (unknownCallbackExitGuard q ∧ r=unknownCallbackExitNext q) ∨ (reconcileKnownConsumptionGuard q ∧ r=reconcileKnownConsumptionNext q) ∨ (finishLandingGuard q ∧ r=finishLandingNext q) ∨ (exitOwnerEnvGuard q ∧ r=exitOwnerEnvNext q) ∨ (acquireAnchorGuard q ∧ r=acquireAnchorNext q) ∨ (lookupFirstRecordGuard q ∧ r=lookupFirstRecordNext q) ∨ (lookupSecondRecordGuard q ∧ r=lookupSecondRecordNext q) ∨ (releaseRecordGuard q ∧ r=releaseRecordNext q) ∨ (releaseAnchorGuard q ∧ r=releaseAnchorNext q) ∨ (closeRecordGateGuard q ∧ r=closeRecordGateNext q) ∨ (closeSendersGuard q ∧ r=closeSendersNext q) ∨ (closeRawRoutesGuard q ∧ r=closeRawRoutesNext q) ∨ (retireRecordGuard q ∧ r=retireRecordNext q) ∨ (reuseSlotGuard q ∧ r=reuseSlotNext q) ∨ (acceptFirstAckGuard q ∧ r=acceptFirstAckNext q) ∨ (rejectFirstAfterReuseGuard q ∧ r=rejectFirstAfterReuseNext q) ∨ r=q
end NrAnchorRetirementAst
