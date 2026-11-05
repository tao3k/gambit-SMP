import Std
namespace PutObjsCustodyAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 mode : Int
 empty : Int
 walk : Int
 last : Int
 local : Int
 uncredited : Int
 exposed : Int
 delta : Int
 split : Int
 lock : Int
 sharedTail : Int
 lastFixed : Int
 receipt : Int
 escaped : Int
 held : Int
 gate : Int
 readers : Int
 generation : Int
 stamp : Int
 accepted : Int
 finalized : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(15)) ∧ (q.mode≥(0)) ∧ (q.mode≤(1)) ∧ (q.empty≥(0)) ∧ (q.empty≤(1)) ∧ (q.walk≥(0)) ∧ (q.walk≤(401)) ∧ (q.last≥(0)) ∧ (q.last≤(401)) ∧ (q.local≥(0)) ∧ (q.local≤(1201)) ∧ (q.uncredited≥(0)) ∧ (q.uncredited≤(800)) ∧ (q.exposed≥(0)) ∧ (q.exposed≤(800)) ∧ (q.delta≥(0)) ∧ (q.delta≤(800)) ∧ (q.split≥(0)) ∧ (q.split≤(1)) ∧ (q.lock≥(0)) ∧ (q.lock≤(2)) ∧ (q.sharedTail≥(0)) ∧ (q.sharedTail≤(1)) ∧ (q.lastFixed≥(0)) ∧ (q.lastFixed≤(1)) ∧ (q.receipt≥(0)) ∧ (q.receipt≤(1)) ∧ (q.escaped≥(0)) ∧ (q.escaped≤(1)) ∧ (q.held≥(0)) ∧ (q.held≤(1)) ∧ (q.gate≥(0)) ∧ (q.gate≤(1)) ∧ (q.readers≥(0)) ∧ (q.readers≤(1)) ∧ (q.generation≥(0)) ∧ (q.generation≤(2)) ∧ (q.stamp≥(0)) ∧ (q.stamp≤(1)) ∧ (q.accepted≥(0)) ∧ (q.accepted≤(1)) ∧ (q.finalized≥(0)) ∧ (q.finalized≤(1)) ∧ (q.generation≥(1)) ∧ (q.stamp=(1)) ∧ (((q.local+q.uncredited)+q.delta)=(1201)) ∧ ((q.phase=(0)) → ((q.local=(1201)) ∧ (q.uncredited=(0)) ∧ (q.walk=(0)) ∧ (q.last=(0)))) ∧ ((q.phase≥(1)) → ((q.local=(401)) ∧ (q.mode=(1)))) ∧ ((q.phase≤(1)) → ((q.walk=(0)) ∧ (q.last=(0)))) ∧ ((q.phase=(2)) → ((q.last=q.walk) ∧ (q.walk<(401)))) ∧ ((q.phase=(3)) → ((q.last=(q.walk+(1))) ∧ (q.walk<(401)))) ∧ ((q.phase=(4)) → ((q.last=q.walk) ∧ (q.walk≥(1)))) ∧ ((q.phase≥(5)) → ((q.walk=(401)) ∧ (q.last=(401)))) ∧ ((q.phase≤(4)) → (q.split=(0))) ∧ ((q.phase≥(5)) → (q.split=(1))) ∧ ((q.phase≤(5)) → (q.lock=(0))) ∧ (((q.phase≥(6)) ∧ (q.phase≤(10))) → (q.lock≥(1))) ∧ ((q.phase≥(12)) → (q.lock=(0))) ∧ ((q.lock=(2)) → ((q.escaped=(1)) ∧ ((q.phase=(6)) ∨ (q.phase=(11))))) ∧ ((q.phase≤(7)) → (q.exposed=(0))) ∧ ((q.phase≥(8)) → (q.exposed=(800))) ∧ ((q.phase≤(8)) → (q.sharedTail=(0))) ∧ ((q.phase≥(9)) → (q.sharedTail=(1))) ∧ ((q.phase≤(9)) → (q.delta=(0))) ∧ ((q.phase≥(10)) → (q.delta=(800))) ∧ ((q.phase≤(11)) → (q.lastFixed=(0))) ∧ ((q.phase≥(12)) → (q.lastFixed=(1))) ∧ ((q.phase≤(12)) → (q.receipt=(0))) ∧ ((q.phase≥(13)) → (q.receipt=(1))) ∧ ((q.phase≤(13)) → ((q.gate=(1)) ∧ (q.readers=(1)))) ∧ ((q.phase≥(14)) → (q.gate=(0))) ∧ ((q.phase≤(14)) → ((q.generation=(1)) ∧ (q.held=(1)))) ∧ ((q.phase=(15)) → ((q.generation=(2)) ∧ (q.held=(0)) ∧ (q.readers=(0)) ∧ (q.accepted=(0)) ∧ (q.finalized=(1)))) ∧ ((q.accepted=(1)) → ((q.receipt=(1)) ∧ (q.generation=q.stamp))) ∧ ((q.finalized=(1)) → ((q.phase≥(14)) ∧ (q.readers=(0)))))
def initial : State := {phase:=(0), mode:=(0), empty:=(0), walk:=(0), last:=(0), local:=(1201), uncredited:=(0), exposed:=(0), delta:=(0), split:=(0), lock:=(0), sharedTail:=(0), lastFixed:=(0), receipt:=(0), escaped:=(0), held:=(1), gate:=(1), readers:=(1), generation:=(1), stamp:=(1), accepted:=(0), finalized:=(0)}
def chooseEmptyGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.mode=(0)))
def chooseEmptyNext (q : State) : State := {q with mode:=(1), empty:=(1)}
def chooseNonemptyGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.mode=(0)))
def chooseNonemptyNext (q : State) : State := {q with mode:=(1), empty:=(0)}
def trimLocalGuard (q : State) : Prop := (((q.phase=(0)) ∧ (q.mode=(1))) ∧ (q.escaped=(0)))
def trimLocalNext (q : State) : State := {q with phase:=(1), local:=(401), uncredited:=(800)}
def loadLocalHeadGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.escaped=(0)))
def loadLocalHeadNext (q : State) : State := {q with phase:=(2)}
def assignLastGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.walk<(401))) ∧ (q.escaped=(0)))
def assignLastNext (q : State) : State := {q with phase:=(3), last:=(q.walk+(1))}
def advanceCursorGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.escaped=(0)))
def advanceCursorNext (q : State) : State := {q with phase:=(4), walk:=(q.walk+(1))}
def loopAgainGuard (q : State) : Prop := (((q.phase=(4)) ∧ (q.walk<(401))) ∧ (q.escaped=(0)))
def loopAgainNext (q : State) : State := {q with phase:=(2)}
def cutLocalGuard (q : State) : Prop := (((q.phase=(4)) ∧ (q.walk=(401))) ∧ (q.escaped=(0)))
def cutLocalNext (q : State) : State := {q with phase:=(5), split:=(1)}
def lockKnownGuard (q : State) : Prop := ((q.phase=(5)) ∧ (q.escaped=(0)))
def lockKnownNext (q : State) : State := {q with phase:=(6), lock:=(1)}
def lockUnknownGuard (q : State) : Prop := ((q.phase=(5)) ∧ (q.escaped=(0)))
def lockUnknownNext (q : State) : State := {q with phase:=(6), lock:=(2), escaped:=(1)}
def linkOldTailGuard (q : State) : Prop := (((q.phase=(6)) ∧ (q.lock=(1))) ∧ (q.escaped=(0)))
def linkOldTailNext (q : State) : State := {q with phase:=(7)}
def publishSharedHeadGuard (q : State) : Prop := (((q.phase=(7)) ∧ (q.lock=(1))) ∧ (q.escaped=(0)))
def publishSharedHeadNext (q : State) : State := {q with phase:=(8), exposed:=(800)}
def updateEmptySharedTailGuard (q : State) : Prop := (((q.phase=(8)) ∧ (q.empty=(1))) ∧ (q.escaped=(0)))
def updateEmptySharedTailNext (q : State) : State := {q with phase:=(9), sharedTail:=(1)}
def keepSharedTailGuard (q : State) : Prop := (((q.phase=(8)) ∧ (q.empty=(0))) ∧ (q.escaped=(0)))
def keepSharedTailNext (q : State) : State := {q with phase:=(9), sharedTail:=(1)}
def addSharedCountGuard (q : State) : Prop := ((q.phase=(9)) ∧ (q.escaped=(0)))
def addSharedCountNext (q : State) : State := {q with phase:=(10), delta:=(800), uncredited:=(0)}
def unlockKnownGuard (q : State) : Prop := (((q.phase=(10)) ∧ (q.lock=(1))) ∧ (q.escaped=(0)))
def unlockKnownNext (q : State) : State := {q with phase:=(11), lock:=(0)}
def unlockUnknownGuard (q : State) : Prop := (((q.phase=(10)) ∧ (q.lock=(1))) ∧ (q.escaped=(0)))
def unlockUnknownNext (q : State) : State := {q with phase:=(11), lock:=(2), escaped:=(1)}
def fixLocalLastGuard (q : State) : Prop := (((q.phase=(11)) ∧ (q.lock=(0))) ∧ (q.escaped=(0)))
def fixLocalLastNext (q : State) : State := {q with phase:=(12), lastFixed:=(1)}
def publishReceiptGuard (q : State) : Prop := ((((q.phase=(12)) ∧ (q.lock=(0))) ∧ (q.lastFixed=(1))) ∧ (q.escaped=(0)))
def publishReceiptNext (q : State) : State := {q with phase:=(13), receipt:=(1)}
def escapeGuard (q : State) : Prop := (((q.phase≤(12)) ∧ (q.mode=(1))) ∧ (q.escaped=(0)))
def escapeNext (q : State) : State := {q with escaped:=(1)}
def loseReceiptAckGuard (q : State) : Prop := (((q.phase=(13)) ∧ (q.receipt=(1))) ∧ (q.escaped=(0)))
def loseReceiptAckNext (q : State) : State := {q with escaped:=(1)}
def acceptReceiptGuard (q : State) : Prop := (((((q.receipt=(1)) ∧ (q.stamp=q.generation)) ∧ (q.held=(1))) ∧ (q.gate=(1))) ∧ (q.accepted=(0)))
def acceptReceiptNext (q : State) : State := {q with accepted:=(1)}
def closeAdmissionGuard (q : State) : Prop := ((q.phase=(13)) ∧ (q.receipt=(1)))
def closeAdmissionNext (q : State) : State := {q with phase:=(14), gate:=(0)}
def readersDetachedGuard (q : State) : Prop := ((q.phase=(14)) ∧ (q.readers=(1)))
def readersDetachedNext (q : State) : State := {q with readers:=(0)}
def attestFinalizationGuard (q : State) : Prop := (((q.phase=(14)) ∧ (q.readers=(0))) ∧ (q.finalized=(0)))
def attestFinalizationNext (q : State) : State := {q with finalized:=(1)}
def reuseAddressGuard (q : State) : Prop := (((((q.phase=(14)) ∧ (q.readers=(0))) ∧ (q.finalized=(1))) ∧ (q.lock=(0))) ∧ (q.held=(1)))
def reuseAddressNext (q : State) : State := {q with phase:=(15), generation:=(2), held:=(0), accepted:=(0)}
def Step (q r : State) : Prop := (chooseEmptyGuard q ∧ r=chooseEmptyNext q) ∨ (chooseNonemptyGuard q ∧ r=chooseNonemptyNext q) ∨ (trimLocalGuard q ∧ r=trimLocalNext q) ∨ (loadLocalHeadGuard q ∧ r=loadLocalHeadNext q) ∨ (assignLastGuard q ∧ r=assignLastNext q) ∨ (advanceCursorGuard q ∧ r=advanceCursorNext q) ∨ (loopAgainGuard q ∧ r=loopAgainNext q) ∨ (cutLocalGuard q ∧ r=cutLocalNext q) ∨ (lockKnownGuard q ∧ r=lockKnownNext q) ∨ (lockUnknownGuard q ∧ r=lockUnknownNext q) ∨ (linkOldTailGuard q ∧ r=linkOldTailNext q) ∨ (publishSharedHeadGuard q ∧ r=publishSharedHeadNext q) ∨ (updateEmptySharedTailGuard q ∧ r=updateEmptySharedTailNext q) ∨ (keepSharedTailGuard q ∧ r=keepSharedTailNext q) ∨ (addSharedCountGuard q ∧ r=addSharedCountNext q) ∨ (unlockKnownGuard q ∧ r=unlockKnownNext q) ∨ (unlockUnknownGuard q ∧ r=unlockUnknownNext q) ∨ (fixLocalLastGuard q ∧ r=fixLocalLastNext q) ∨ (publishReceiptGuard q ∧ r=publishReceiptNext q) ∨ (escapeGuard q ∧ r=escapeNext q) ∨ (loseReceiptAckGuard q ∧ r=loseReceiptAckNext q) ∨ (acceptReceiptGuard q ∧ r=acceptReceiptNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (readersDetachedGuard q ∧ r=readersDetachedNext q) ∨ (attestFinalizationGuard q ∧ r=attestFinalizationNext q) ∨ (reuseAddressGuard q ∧ r=reuseAddressNext q) ∨ r=q
end PutObjsCustodyAst
