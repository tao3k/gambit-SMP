import Std
namespace PutObjsMoveGraphAst
set_option maxRecDepth 10000
structure State where
 p : Int
 c : Int
 knowledge : Int
 mutex : Int
 walk : Int
 cursor : Int
 sharedHead : Int
 sharedCount : Int
 destHead : Int
 destTail : Int
 destCount : Int
 tailNext : Int
 localTail : Int
 pops : Int
 popPtr : Int
 nMove : Int
 tailReturned : Int
 tailReused : Int
 receipt : Int
 held : Int
 gate : Int
 readers : Int
 ready : Int
 generation : Int
 stamp : Int
 opaque : Int
 oldRead : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.p≥(0)) ∧ (q.p≤(5))) ∧ ((q.c≥(0)) ∧ (q.c≤(13))) ∧ ((q.knowledge≥(0)) ∧ (q.knowledge≤(2))) ∧ ((q.mutex≥(0)) ∧ (q.mutex≤(2))) ∧ ((q.walk≥(0)) ∧ (q.walk≤(799))) ∧ ((q.cursor≥(0)) ∧ (q.cursor≤(1201))) ∧ ((q.sharedHead≥(0)) ∧ (q.sharedHead≤(1202))) ∧ ((q.sharedCount≥(0)) ∧ (q.sharedCount≤(801))) ∧ ((q.destHead≥(0)) ∧ (q.destHead≤(1201))) ∧ ((q.destTail≥(0)) ∧ (q.destTail≤(1201))) ∧ ((q.destCount≥(0)) ∧ (q.destCount≤(800))) ∧ ((q.tailNext≥(0)) ∧ (q.tailNext≤(1202))) ∧ ((q.localTail≥(0)) ∧ (q.localTail≤(1201))) ∧ ((q.pops≥(0)) ∧ (q.pops≤(800))) ∧ ((q.popPtr≥(0)) ∧ (q.popPtr≤(1201))) ∧ ((q.nMove≥(0)) ∧ (q.nMove≤(800))) ∧ ((q.tailReturned≥(0)) ∧ (q.tailReturned≤(1))) ∧ ((q.tailReused≥(0)) ∧ (q.tailReused≤(1))) ∧ ((q.receipt≥(0)) ∧ (q.receipt≤(1))) ∧ ((q.held≥(0)) ∧ (q.held≤(1))) ∧ ((q.gate≥(0)) ∧ (q.gate≤(1))) ∧ ((q.readers≥(0)) ∧ (q.readers≤(1))) ∧ ((q.ready≥(0)) ∧ (q.ready≤(1))) ∧ ((q.generation≥(0)) ∧ (q.generation≤(2))) ∧ ((q.stamp≥(0)) ∧ (q.stamp≤(1))) ∧ ((q.opaque≥(0)) ∧ (q.opaque≤(1))) ∧ ((q.oldRead≥(0)) ∧ (q.oldRead≤(1))) ∧ (q.generation≥(1)) ∧ (q.stamp=(1)) ∧ (q.cursor=((402)+q.walk)) ∧ ((q.c≤(4)) → (q.walk=(0))) ∧ ((q.c≥(6)) → (q.walk=(799))) ∧ ((q.c≤(4)) → (q.sharedCount=(801))) ∧ ((q.c≥(5)) → (q.sharedCount=(1))) ∧ ((q.c≤(5)) → (q.sharedHead=(402))) ∧ ((q.c≥(6)) → (q.sharedHead=(1202))) ∧ ((q.c≤(6)) → (q.destTail=(0))) ∧ ((q.c≥(7)) → (q.destTail=(1201))) ∧ ((q.c≤(7)) → (q.tailNext=(1202))) ∧ ((q.c≥(8)) → (q.tailNext=(0))) ∧ ((q.c≤(3)) → (q.destCount=(0))) ∧ (((q.c≥(4)) ∧ (q.c≤(9))) → (q.destCount=(800))) ∧ (((q.c≥(10)) ∧ (q.c≤(12))) → ((q.destCount+q.pops)=(800))) ∧ ((q.c=(13)) → ((q.destCount+q.pops)=(799))) ∧ ((q.c≤(9)) → (q.pops=(0))) ∧ ((q.c≥(11)) → (q.pops<(800))) ∧ ((q.c≥(11)) → (q.popPtr=((402)+q.pops))) ∧ ((q.c≤(8)) → (q.destHead=(0))) ∧ ((q.c=(9)) → (q.destHead=(402))) ∧ (((q.c=(10)) ∧ (q.pops<(800))) → (q.destHead=((402)+q.pops))) ∧ (((q.c=(10)) ∧ (q.pops=(800))) → (q.destHead=(0))) ∧ ((q.c=(11)) → (q.destHead=((402)+q.pops))) ∧ ((((q.c=(12)) ∨ (q.c=(13))) ∧ (q.pops=(799))) → (q.destHead=(0))) ∧ ((((q.c=(12)) ∨ (q.c=(13))) ∧ (q.pops<(799))) → (q.destHead=((403)+q.pops))) ∧ (((q.c≥(1)) ∧ (q.c≤(9))) → (q.mutex=(2))) ∧ ((q.c≥(10)) → (q.mutex=(0))) ∧ (((q.c=(0)) ∧ (q.knowledge=(0))) → (q.mutex=(1))) ∧ (((q.c=(0)) ∧ (q.knowledge=(1))) → (q.mutex=(0))) ∧ ((q.p=(0)) → ((q.knowledge=(0)) ∧ (q.opaque=(0)) ∧ (q.localTail=(1201)) ∧ (q.receipt=(0)) ∧ (q.c=(0)))) ∧ ((q.p≥(1)) → ((q.knowledge≥(1)) ∧ (q.opaque=(1)))) ∧ ((q.knowledge=(2)) → ((q.p=(1)) ∧ (q.localTail=(1201)) ∧ (q.held=(1)) ∧ (q.receipt=(0)) ∧ (q.gate=(1)) ∧ (q.readers=(1)) ∧ (q.ready=(0)) ∧ (q.generation=(1)))) ∧ ((q.p=(1)) → (q.localTail=(1201))) ∧ ((q.p≥(2)) → ((q.localTail=(401)) ∧ (q.knowledge=(1)))) ∧ ((q.p≤(2)) → (q.receipt=(0))) ∧ ((q.p≥(3)) → (q.receipt=(1))) ∧ ((q.p≤(3)) → ((q.gate=(1)) ∧ (q.readers=(1)))) ∧ ((q.p≥(4)) → (q.gate=(0))) ∧ ((q.p≤(4)) → ((q.held=(1)) ∧ (q.generation=(1)))) ∧ ((q.p=(5)) → ((q.held=(0)) ∧ (q.generation=(2)) ∧ (q.readers=(0)) ∧ (q.ready=(1)))) ∧ ((q.ready=(1)) → ((q.p≥(4)) ∧ (q.c≥(10)) ∧ (q.readers=(0)))) ∧ ((q.tailReturned=(1)) → (q.pops=(800))) ∧ ((q.pops=(800)) → (q.tailReturned=(1))) ∧ ((q.tailReused=(1)) → (q.tailReturned=(1))))
def initial : State := {p:=(0), c:=(0), knowledge:=(0), mutex:=(1), walk:=(0), cursor:=(402), sharedHead:=(402), sharedCount:=(801), destHead:=(0), destTail:=(0), destCount:=(0), tailNext:=(1202), localTail:=(1201), pops:=(0), popPtr:=(0), nMove:=(0), tailReturned:=(0), tailReused:=(0), receipt:=(0), held:=(1), gate:=(1), readers:=(1), ready:=(0), generation:=(1), stamp:=(1), opaque:=(0), oldRead:=(0)}
def knownProducerUnlockGuard (q : State) : Prop := (q.p=(0))
def knownProducerUnlockNext (q : State) : State := {q with p:=(1), knowledge:=(1), mutex:=(0), opaque:=(1)}
def unknownReleasedGuard (q : State) : Prop := (q.p=(0))
def unknownReleasedNext (q : State) : State := {q with p:=(1), knowledge:=(2), mutex:=(0), opaque:=(1)}
def unknownStillHeldGuard (q : State) : Prop := (q.p=(0))
def unknownStillHeldNext (q : State) : State := {q with p:=(1), knowledge:=(2), mutex:=(1), opaque:=(1)}
def fixProducerLastGuard (q : State) : Prop := ((q.p=(1)) ∧ (q.knowledge=(1)))
def fixProducerLastNext (q : State) : State := {q with p:=(2), localTail:=(401)}
def publishReceiptGuard (q : State) : Prop := ((q.p=(2)) ∧ (q.knowledge=(1)))
def publishReceiptNext (q : State) : State := {q with p:=(3), receipt:=(1)}
def closeSourceAdmissionGuard (q : State) : Prop := (q.p=(3))
def closeSourceAdmissionNext (q : State) : State := {q with p:=(4), gate:=(0)}
def sourceReadersDetachedGuard (q : State) : Prop := ((q.p=(4)) ∧ (q.readers=(1)))
def sourceReadersDetachedNext (q : State) : State := {q with readers:=(0)}
def attestSourceFinalizedGuard (q : State) : Prop := ((((q.p=(4)) ∧ (q.readers=(0))) ∧ (q.c≥(10))) ∧ (q.ready=(0)))
def attestSourceFinalizedNext (q : State) : State := {q with ready:=(1)}
def reuseSourceCacheGuard (q : State) : Prop := ((((q.p=(4)) ∧ (q.readers=(0))) ∧ (q.ready=(1))) ∧ (q.held=(1)))
def reuseSourceCacheNext (q : State) : State := {q with p:=(5), held:=(0), generation:=(2)}
def borrowOldTailGuard (q : State) : Prop := ((((q.p=(0)) ∧ (q.knowledge=(0))) ∧ (q.mutex=(1))) ∧ (q.oldRead=(0)))
def borrowOldTailNext (q : State) : State := {q with oldRead:=(1)}
def acquireConsumerGuard (q : State) : Prop := ((q.c=(0)) ∧ (q.mutex=(0)))
def acquireConsumerNext (q : State) : State := {q with c:=(1), mutex:=(2)}
def selectMove800Guard (q : State) : Prop := (q.c=(1))
def selectMove800Next (q : State) : State := {q with c:=(2), nMove:=(800)}
def loadMoveHeadGuard (q : State) : Prop := (q.c=(2))
def loadMoveHeadNext (q : State) : State := {q with c:=(3), cursor:=(402)}
def creditDestinationGuard (q : State) : Prop := (q.c=(3))
def creditDestinationNext (q : State) : State := {q with c:=(4), destCount:=(800)}
def debitSharedGuard (q : State) : Prop := (q.c=(4))
def debitSharedNext (q : State) : State := {q with c:=(5), sharedCount:=(1)}
def walkMovedNextGuard (q : State) : Prop := ((q.c=(5)) ∧ (q.walk<(799)))
def walkMovedNextNext (q : State) : State := {q with walk:=(q.walk+(1)), cursor:=(q.cursor+(1))}
def detachSharedHeadGuard (q : State) : Prop := ((q.c=(5)) ∧ (q.walk=(799)))
def detachSharedHeadNext (q : State) : State := {q with c:=(6), sharedHead:=q.tailNext}
def assignDestinationTailGuard (q : State) : Prop := (q.c=(6))
def assignDestinationTailNext (q : State) : State := {q with c:=(7), destTail:=q.cursor}
def cutMovedTailGuard (q : State) : Prop := (q.c=(7))
def cutMovedTailNext (q : State) : State := {q with c:=(8), tailNext:=q.destHead}
def publishDestinationHeadGuard (q : State) : Prop := (q.c=(8))
def publishDestinationHeadNext (q : State) : State := {q with c:=(9), destHead:=(402)}
def releaseConsumerGuard (q : State) : Prop := (q.c=(9))
def releaseConsumerNext (q : State) : State := {q with c:=(10), mutex:=(0)}
def loadPopHeadGuard (q : State) : Prop := ((q.c=(10)) ∧ (q.destCount>(0)))
def loadPopHeadNext (q : State) : State := {q with c:=(11), popPtr:=q.destHead}
def advanceInteriorHeadGuard (q : State) : Prop := ((q.c=(11)) ∧ (q.popPtr<(1201)))
def advanceInteriorHeadNext (q : State) : State := {q with c:=(12), destHead:=(q.popPtr+(1))}
def advanceLastHeadGuard (q : State) : Prop := ((q.c=(11)) ∧ (q.popPtr=(1201)))
def advanceLastHeadNext (q : State) : State := {q with c:=(12), destHead:=(0)}
def decrementDestinationGuard (q : State) : Prop := (q.c=(12))
def decrementDestinationNext (q : State) : State := {q with c:=(13), destCount:=(q.destCount-(1))}
def returnInteriorGuard (q : State) : Prop := ((q.c=(13)) ∧ (q.popPtr<(1201)))
def returnInteriorNext (q : State) : State := {q with c:=(10), pops:=(q.pops+(1))}
def returnTailGuard (q : State) : Prop := ((q.c=(13)) ∧ (q.popPtr=(1201)))
def returnTailNext (q : State) : State := {q with c:=(10), pops:=(q.pops+(1)), tailReturned:=(1)}
def initializeTailPayloadGuard (q : State) : Prop := ((q.tailReturned=(1)) ∧ (q.tailReused=(0)))
def initializeTailPayloadNext (q : State) : State := {q with tailReused:=(1)}
def Step (q r : State) : Prop := (knownProducerUnlockGuard q ∧ r=knownProducerUnlockNext q) ∨ (unknownReleasedGuard q ∧ r=unknownReleasedNext q) ∨ (unknownStillHeldGuard q ∧ r=unknownStillHeldNext q) ∨ (fixProducerLastGuard q ∧ r=fixProducerLastNext q) ∨ (publishReceiptGuard q ∧ r=publishReceiptNext q) ∨ (closeSourceAdmissionGuard q ∧ r=closeSourceAdmissionNext q) ∨ (sourceReadersDetachedGuard q ∧ r=sourceReadersDetachedNext q) ∨ (attestSourceFinalizedGuard q ∧ r=attestSourceFinalizedNext q) ∨ (reuseSourceCacheGuard q ∧ r=reuseSourceCacheNext q) ∨ (borrowOldTailGuard q ∧ r=borrowOldTailNext q) ∨ (acquireConsumerGuard q ∧ r=acquireConsumerNext q) ∨ (selectMove800Guard q ∧ r=selectMove800Next q) ∨ (loadMoveHeadGuard q ∧ r=loadMoveHeadNext q) ∨ (creditDestinationGuard q ∧ r=creditDestinationNext q) ∨ (debitSharedGuard q ∧ r=debitSharedNext q) ∨ (walkMovedNextGuard q ∧ r=walkMovedNextNext q) ∨ (detachSharedHeadGuard q ∧ r=detachSharedHeadNext q) ∨ (assignDestinationTailGuard q ∧ r=assignDestinationTailNext q) ∨ (cutMovedTailGuard q ∧ r=cutMovedTailNext q) ∨ (publishDestinationHeadGuard q ∧ r=publishDestinationHeadNext q) ∨ (releaseConsumerGuard q ∧ r=releaseConsumerNext q) ∨ (loadPopHeadGuard q ∧ r=loadPopHeadNext q) ∨ (advanceInteriorHeadGuard q ∧ r=advanceInteriorHeadNext q) ∨ (advanceLastHeadGuard q ∧ r=advanceLastHeadNext q) ∨ (decrementDestinationGuard q ∧ r=decrementDestinationNext q) ∨ (returnInteriorGuard q ∧ r=returnInteriorNext q) ∨ (returnTailGuard q ∧ r=returnTailNext q) ∨ (initializeTailPayloadGuard q ∧ r=initializeTailPayloadNext q) ∨ r=q
end PutObjsMoveGraphAst
