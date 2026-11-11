import Std
namespace NrInflightHandoffAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 tokenApplied : Int
 nodeApplied : Int
 tokenReceipt : Int
 nodeReceipt : Int
 escrow : Int
 queue : Int
 lock : Int
 gate : Int
 pin : Int
 anchor : Int
 validated : Int
 live : Int
 generation : Int
 senders : Int
 rawClosed : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.stage≥(0)) ∧ (q.tokenApplied≥(0)) ∧ (q.nodeApplied≥(0)) ∧ (q.tokenReceipt≥(0)) ∧ (q.nodeReceipt≥(0)) ∧ (q.escrow≥(0)) ∧ (q.queue≥(0)) ∧ (q.lock≥(0)) ∧ (q.gate≥(0)) ∧ (q.pin≥(0)) ∧ (q.anchor≥(0)) ∧ (q.validated≥(0)) ∧ (q.live≥(0)) ∧ (q.generation≥(0)) ∧ (q.senders≥(0)) ∧ (q.rawClosed≥(0)) ∧ (q.stage≤(9)) ∧ (q.tokenApplied≤(1)) ∧ (q.nodeApplied≤(1)) ∧ (q.tokenReceipt≤(1)) ∧ (q.nodeReceipt≤(1)) ∧ (q.escrow≤(1)) ∧ (q.queue≤(1)) ∧ (q.lock≤(3)) ∧ (q.gate≤(1)) ∧ (q.pin≤(1)) ∧ (q.anchor≤(1)) ∧ (q.validated≤(1)) ∧ (q.live≤(1)) ∧ (q.generation≤(2)) ∧ (q.senders≤(1)) ∧ (q.rawClosed≤(1)) ∧ (q.generation≥(1)) ∧ ((q.stage=(0)) → ((q.escrow=(0)) ∧ (q.queue=(1)) ∧ (q.tokenApplied=(0)) ∧ (q.nodeApplied=(0)) ∧ (q.tokenReceipt=(0)) ∧ (q.nodeReceipt=(0)))) ∧ ((q.stage=(1)) → ((q.escrow=(1)) ∧ (q.queue=(1)))) ∧ ((q.stage≥(2)) → (q.queue=(0))) ∧ (((q.stage≥(1)) ∧ (q.stage≤(8))) → (q.escrow=(1))) ∧ ((q.stage≤(2)) → ((q.tokenApplied=(0)) ∧ (q.nodeApplied=(0)) ∧ (q.tokenReceipt=(0)) ∧ (q.nodeReceipt=(0)))) ∧ ((q.stage≤(5)) → ((q.nodeApplied=(0)) ∧ (q.nodeReceipt=(0)))) ∧ ((q.tokenReceipt=(1)) → (q.tokenApplied=(1))) ∧ ((q.nodeReceipt=(1)) → (q.nodeApplied=(1))) ∧ ((q.stage≥(5)) → ((q.tokenApplied=(1)) ∧ (q.tokenReceipt=(1)))) ∧ ((q.stage≥(8)) → ((q.nodeApplied=(1)) ∧ (q.nodeReceipt=(1)))) ∧ ((q.pin=(1)) → ((q.anchor=(1)) ∧ (q.live=(1)))) ∧ ((q.validated=(1)) → ((q.lock=(1)) ∧ (q.anchor=(1)) ∧ (q.gate=(1)) ∧ (q.live=(1)) ∧ (q.pin=(0)))) ∧ ((q.lock=(1)) → (q.anchor=(1))) ∧ ((q.lock=(3)) → ((q.anchor=(0)) ∧ (q.pin=(0)) ∧ (q.validated=(0)))) ∧ ((q.gate=(1)) → (q.live=(1))) ∧ ((q.senders=(0)) → ((q.stage=(9)) ∧ (q.escrow=(0)))) ∧ ((q.rawClosed=(1)) → ((q.gate=(0)) ∧ (q.senders=(0)))) ∧ ((q.live=(0)) → ((q.gate=(0)) ∧ (q.pin=(0)) ∧ (q.validated=(0)) ∧ (q.stage=(9)) ∧ (q.escrow=(0)) ∧ (q.senders=(0)) ∧ (q.rawClosed=(1)))))
def initial : State := {stage:=(0), tokenApplied:=(0), nodeApplied:=(0), tokenReceipt:=(0), nodeReceipt:=(0), escrow:=(0), queue:=(1), lock:=(0), gate:=(1), pin:=(0), anchor:=(0), validated:=(0), live:=(1), generation:=(1), senders:=(1), rawClosed:=(0)}
def prepareEscrowGuard (q : State) : Prop := ((q.stage=(0)) ∧ (q.escrow=(0)))
def prepareEscrowNext (q : State) : State := {q with stage:=(1), escrow:=(1)}
def popNodeGuard (q : State) : Prop := (((q.stage=(1)) ∧ (q.escrow=(1))) ∧ (q.queue=(1)))
def popNodeNext (q : State) : State := {q with stage:=(2), queue:=(0)}
def beginTokenGuard (q : State) : Prop := (q.stage=(2))
def beginTokenNext (q : State) : State := {q with stage:=(3)}
def applyTokenEffectGuard (q : State) : Prop := (((q.stage=(3)) ∨ (q.stage=(4))) ∧ (q.tokenApplied=(0)))
def applyTokenEffectNext (q : State) : State := {q with tokenApplied:=(1)}
def loseTokenReturnGuard (q : State) : Prop := (q.stage=(3))
def loseTokenReturnNext (q : State) : State := {q with stage:=(4)}
def receiveTokenReceiptGuard (q : State) : Prop := ((((q.stage=(3)) ∨ (q.stage=(4))) ∧ (q.tokenApplied=(1))) ∧ (q.tokenReceipt=(0)))
def receiveTokenReceiptNext (q : State) : State := {q with tokenReceipt:=(1)}
def confirmTokenGuard (q : State) : Prop := (((q.stage=(3)) ∨ (q.stage=(4))) ∧ (q.tokenReceipt=(1)))
def confirmTokenNext (q : State) : State := {q with stage:=(5)}
def beginNodeReleaseGuard (q : State) : Prop := (q.stage=(5))
def beginNodeReleaseNext (q : State) : State := {q with stage:=(6)}
def applyNodeEffectGuard (q : State) : Prop := (((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.nodeApplied=(0)))
def applyNodeEffectNext (q : State) : State := {q with nodeApplied:=(1)}
def loseNodeReturnGuard (q : State) : Prop := (q.stage=(6))
def loseNodeReturnNext (q : State) : State := {q with stage:=(7)}
def receiveNodeReceiptGuard (q : State) : Prop := ((((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.nodeApplied=(1))) ∧ (q.nodeReceipt=(0)))
def receiveNodeReceiptNext (q : State) : State := {q with nodeReceipt:=(1)}
def confirmNodeGuard (q : State) : Prop := (((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.nodeReceipt=(1)))
def confirmNodeNext (q : State) : State := {q with stage:=(8)}
def publishDoneGuard (q : State) : Prop := (((q.stage=(8)) ∧ (q.tokenReceipt=(1))) ∧ (q.nodeReceipt=(1)))
def publishDoneNext (q : State) : State := {q with stage:=(9)}
def releaseEscrowGuard (q : State) : Prop := ((q.stage=(9)) ∧ (q.escrow=(1)))
def releaseEscrowNext (q : State) : State := {q with escrow:=(0)}
def beginLookupGuard (q : State) : Prop := (((q.lock=(0)) ∧ (q.anchor=(0))) ∧ (q.pin=(0)))
def beginLookupNext (q : State) : State := {q with lock:=(1), anchor:=(1)}
def validateFirstGuard (q : State) : Prop := ((((((q.lock=(1)) ∧ (q.generation=(1))) ∧ (q.gate=(1))) ∧ (q.live=(1))) ∧ (q.validated=(0))) ∧ (q.pin=(0)))
def validateFirstNext (q : State) : State := {q with validated:=(1)}
def validateSecondGuard (q : State) : Prop := ((((((q.lock=(1)) ∧ (q.generation=(2))) ∧ (q.gate=(1))) ∧ (q.live=(1))) ∧ (q.validated=(0))) ∧ (q.pin=(0)))
def validateSecondNext (q : State) : State := {q with validated:=(1)}
def installPinGuard (q : State) : Prop := (((((q.lock=(1)) ∧ (q.validated=(1))) ∧ (q.gate=(1))) ∧ (q.live=(1))) ∧ (q.pin=(0)))
def installPinNext (q : State) : State := {q with pin:=(1), validated:=(0)}
def unlockLookupGuard (q : State) : Prop := (((q.lock=(1)) ∧ (q.pin=(1))) ∧ (q.validated=(0)))
def unlockLookupNext (q : State) : State := {q with lock:=(0)}
def releasePinGuard (q : State) : Prop := (((q.lock=(0)) ∧ (q.pin=(1))) ∧ (q.anchor=(1)))
def releasePinNext (q : State) : State := {q with pin:=(0), anchor:=(0)}
def rejectClosedLookupGuard (q : State) : Prop := ((((q.lock=(1)) ∧ (q.validated=(0))) ∧ (q.pin=(0))) ∧ ((q.gate=(0)) ∨ (q.live=(0))))
def rejectClosedLookupNext (q : State) : State := {q with lock:=(0), anchor:=(0)}
def rejectOldFirstGuard (q : State) : Prop := ((((q.lock=(1)) ∧ (q.generation=(2))) ∧ (q.validated=(0))) ∧ (q.pin=(0)))
def rejectOldFirstNext (q : State) : State := {q with lock:=(0), anchor:=(0)}
def acquireCloseGuard (q : State) : Prop := (q.lock=(0))
def acquireCloseNext (q : State) : State := {q with lock:=(2)}
def closeGateGuard (q : State) : Prop := ((q.lock=(2)) ∧ (q.gate=(1)))
def closeGateNext (q : State) : State := {q with gate:=(0)}
def closeSendersGuard (q : State) : Prop := (((q.stage=(9)) ∧ (q.escrow=(0))) ∧ (q.senders=(1)))
def closeSendersNext (q : State) : State := {q with senders:=(0)}
def closeRawRoutesGuard (q : State) : Prop := (((q.gate=(0)) ∧ (q.senders=(0))) ∧ (q.rawClosed=(0)))
def closeRawRoutesNext (q : State) : State := {q with rawClosed:=(1)}
def retireRecordGuard (q : State) : Prop := ((((((((q.lock=(2)) ∧ (q.gate=(0))) ∧ (q.pin=(0))) ∧ (q.live=(1))) ∧ (q.stage=(9))) ∧ (q.escrow=(0))) ∧ (q.senders=(0))) ∧ (q.rawClosed=(1)))
def retireRecordNext (q : State) : State := {q with live:=(0)}
def unlockCloseGuard (q : State) : Prop := (q.lock=(2))
def unlockCloseNext (q : State) : State := {q with lock:=(0)}
def acquireReuseGuard (q : State) : Prop := ((((q.lock=(0)) ∧ (q.live=(0))) ∧ (q.anchor=(0))) ∧ (q.generation=(1)))
def acquireReuseNext (q : State) : State := {q with lock:=(3)}
def commitReuseGuard (q : State) : Prop := (((q.lock=(3)) ∧ (q.generation=(1))) ∧ (q.live=(0)))
def commitReuseNext (q : State) : State := {q with stage:=(0), tokenApplied:=(0), nodeApplied:=(0), tokenReceipt:=(0), nodeReceipt:=(0), escrow:=(0), queue:=(1), gate:=(1), validated:=(0), live:=(1), generation:=(2), senders:=(1), rawClosed:=(0)}
def unlockReuseGuard (q : State) : Prop := (((q.lock=(3)) ∧ (q.generation=(2))) ∧ (q.live=(1)))
def unlockReuseNext (q : State) : State := {q with lock:=(0)}
def Step (q r : State) : Prop := (prepareEscrowGuard q ∧ r=prepareEscrowNext q) ∨ (popNodeGuard q ∧ r=popNodeNext q) ∨ (beginTokenGuard q ∧ r=beginTokenNext q) ∨ (applyTokenEffectGuard q ∧ r=applyTokenEffectNext q) ∨ (loseTokenReturnGuard q ∧ r=loseTokenReturnNext q) ∨ (receiveTokenReceiptGuard q ∧ r=receiveTokenReceiptNext q) ∨ (confirmTokenGuard q ∧ r=confirmTokenNext q) ∨ (beginNodeReleaseGuard q ∧ r=beginNodeReleaseNext q) ∨ (applyNodeEffectGuard q ∧ r=applyNodeEffectNext q) ∨ (loseNodeReturnGuard q ∧ r=loseNodeReturnNext q) ∨ (receiveNodeReceiptGuard q ∧ r=receiveNodeReceiptNext q) ∨ (confirmNodeGuard q ∧ r=confirmNodeNext q) ∨ (publishDoneGuard q ∧ r=publishDoneNext q) ∨ (releaseEscrowGuard q ∧ r=releaseEscrowNext q) ∨ (beginLookupGuard q ∧ r=beginLookupNext q) ∨ (validateFirstGuard q ∧ r=validateFirstNext q) ∨ (validateSecondGuard q ∧ r=validateSecondNext q) ∨ (installPinGuard q ∧ r=installPinNext q) ∨ (unlockLookupGuard q ∧ r=unlockLookupNext q) ∨ (releasePinGuard q ∧ r=releasePinNext q) ∨ (rejectClosedLookupGuard q ∧ r=rejectClosedLookupNext q) ∨ (rejectOldFirstGuard q ∧ r=rejectOldFirstNext q) ∨ (acquireCloseGuard q ∧ r=acquireCloseNext q) ∨ (closeGateGuard q ∧ r=closeGateNext q) ∨ (closeSendersGuard q ∧ r=closeSendersNext q) ∨ (closeRawRoutesGuard q ∧ r=closeRawRoutesNext q) ∨ (retireRecordGuard q ∧ r=retireRecordNext q) ∨ (unlockCloseGuard q ∧ r=unlockCloseNext q) ∨ (acquireReuseGuard q ∧ r=acquireReuseNext q) ∨ (commitReuseGuard q ∧ r=commitReuseNext q) ∨ (unlockReuseGuard q ∧ r=unlockReuseNext q) ∨ r=q
end NrInflightHandoffAst
