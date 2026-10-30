import Std
namespace DispatchJointAst
set_option maxRecDepth 10000
structure State where
 nativeOpen : Int
 storage : Int
 control : Int
 root : Int
 scope : Int
 others : Int
 selected : Int
 phase : Int
 pending : Int
 committed : Int
 known : Int
 refused : Int
 unknown : Int
 borrow : Int
 created : Int
 released : Int
 lease : Int
 rootAuth : Int
 nativeAuth : Int
 finished : Int
 delivered : Int
 dataReads : Int
 gcOpen : Int
 frozen : Int
 scanning : Int
 scanned : Int
 gcEpoch : Int
 viewRoot : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.nativeOpen≥(0)) ∧ (q.nativeOpen≤(1)) ∧ (q.storage≥(0)) ∧ (q.storage≤(1)) ∧ (q.control≥(0)) ∧ (q.control≤(1)) ∧ (q.root≥(0)) ∧ (q.root≤(1)) ∧ (q.scope≥(0)) ∧ (q.scope≤(1)) ∧ (q.others≥(0)) ∧ (q.selected≥(0)) ∧ (q.selected≤(1)) ∧ (q.phase≥(0)) ∧ (q.phase≤(4)) ∧ (q.pending≥(0)) ∧ (q.pending≤(1)) ∧ (q.committed≥(0)) ∧ (q.committed≤(1)) ∧ (q.known≥(0)) ∧ (q.known≤(1)) ∧ (q.refused≥(0)) ∧ (q.refused≤(1)) ∧ (q.unknown≥(0)) ∧ (q.unknown≤(1)) ∧ (q.borrow≥(0)) ∧ (q.borrow≤(1)) ∧ (q.created≥(0)) ∧ (q.created≤(1)) ∧ (q.released≥(0)) ∧ (q.released≤(1)) ∧ (q.lease≥(0)) ∧ (q.lease≤(1)) ∧ (q.rootAuth≥(0)) ∧ (q.rootAuth≤(1)) ∧ (q.nativeAuth≥(0)) ∧ (q.nativeAuth≤(1)) ∧ (q.finished≥(0)) ∧ (q.finished≤(1)) ∧ (q.delivered≥(0)) ∧ (q.delivered≤(1)) ∧ (q.dataReads≥(0)) ∧ (q.dataReads≤(1)) ∧ (q.gcOpen≥(0)) ∧ (q.gcOpen≤(1)) ∧ (q.frozen≥(0)) ∧ (q.frozen≤(1)) ∧ (q.scanning≥(0)) ∧ (q.scanning≤(1)) ∧ (q.scanned≥(0)) ∧ (q.scanned≤(1)) ∧ (q.gcEpoch≥(0)) ∧ (q.viewRoot≥(0)) ∧ (q.viewRoot≤(1)) ∧ ((q.phase≤(1)) → (((((((((((((q.pending=(0)) ∧ (q.committed=(0))) ∧ (q.known=(0))) ∧ (q.refused=(0))) ∧ (q.unknown=(0))) ∧ (q.borrow=(0))) ∧ (q.created=(0))) ∧ (q.released=(0))) ∧ (q.lease=(0))) ∧ (q.rootAuth=(0))) ∧ (q.finished=(0))) ∧ (q.delivered=(0))) ∧ (q.dataReads=(0)))) ∧ ((q.phase=(0)) → (((q.scope=(0)) ∧ (q.nativeAuth=(0))) ∧ (q.selected=(0)))) ∧ (q.gcEpoch≥(1)) ∧ ((q.borrow+q.released)=q.created) ∧ (((q.scope=(1)) ∨ (q.others≥(1))) → (((q.control=(1)) ∧ (q.storage=(1))) ∧ (q.root=(1)))) ∧ ((q.nativeOpen=(1)) → (((q.root=(1)) ∧ (q.storage=(1))) ∧ (q.control=(1)))) ∧ ((q.root=(1)) → ((q.storage=(1)) ∧ (q.control=(1)))) ∧ ((q.storage=(1)) → (q.control=(1))) ∧ ((q.nativeAuth=(1)) → (q.scope=(1))) ∧ ((q.scope=(1)) → (q.nativeAuth=(1))) ∧ ((q.pending=(1)) → ((((q.scope=(1)) ∧ (q.known=(0))) ∧ ((q.phase=(2)) ∨ (q.phase=(3)))) ∧ (q.root=(1)))) ∧ ((q.unknown=(1)) → ((q.pending=(1)) ∧ (q.known=(0)))) ∧ ((q.lease=(1)) → ((((q.phase=(2)) ∧ (q.rootAuth=(1))) ∧ (q.pending=(1))) ∧ (q.frozen=(0)))) ∧ ((q.phase=(2)) → (((((q.lease=(1)) ∧ (q.committed=(0))) ∧ (q.borrow=(0))) ∧ (q.refused=(0))) ∧ (q.scope=(1)))) ∧ ((q.phase=(3)) → ((((((q.committed=(1)) ∧ (q.borrow=(1))) ∧ (q.scope=(1))) ∧ (q.rootAuth=(1))) ∧ (q.lease=(0))) ∧ (q.refused=(0)))) ∧ ((q.borrow=(1)) → (((((((q.root=(1)) ∧ (q.storage=(1))) ∧ (q.control=(1))) ∧ (q.committed=(1))) ∧ (q.scope=(1))) ∧ (q.rootAuth=(1))) ∧ (q.phase=(3)))) ∧ ((q.rootAuth=(1)) → (((q.root=(1)) ∧ (q.scope=(1))) ∧ ((q.phase=(2)) ∨ (q.phase=(3))))) ∧ ((q.refused=(1)) → ((((((q.phase=(4)) ∧ (q.committed=(0))) ∧ (q.known=(1))) ∧ (q.pending=(0))) ∧ (q.borrow=(0))) ∧ (q.dataReads=(0)))) ∧ ((q.phase=(4)) → (((((q.known=(1)) ∧ (q.pending=(0))) ∧ (q.borrow=(0))) ∧ (q.rootAuth=(0))) ∧ (q.lease=(0)))) ∧ ((q.dataReads=(1)) → ((q.known=(1)) ∧ (q.committed=(1)))) ∧ ((q.released=(1)) → (((q.phase=(4)) ∧ (q.finished=(1))) ∧ (q.committed=(1)))) ∧ ((q.delivered=(1)) → ((((q.phase=(4)) ∧ (q.known=(1))) ∧ (q.pending=(0))) ∧ (q.borrow=(0)))) ∧ ((q.frozen=(1)) → (((q.gcOpen=(0)) ∧ (q.lease=(0))) ∧ (q.root=q.viewRoot))) ∧ ((q.scanning=(1)) → ((q.frozen=(1)) ∧ (q.scanned=(0)))) ∧ ((q.scanned=(1)) → ((q.frozen=(1)) ∧ (q.scanning=(0)))) ∧ ((q.storage=(0)) → (((((((q.root=(0)) ∧ (q.nativeOpen=(0))) ∧ (q.scope=(0))) ∧ (q.others=(0))) ∧ (q.borrow=(0))) ∧ (q.pending=(0))) ∧ (q.lease=(0)))) ∧ ((q.control=(0)) → ((((((q.storage=(0)) ∧ (q.root=(0))) ∧ (q.nativeOpen=(0))) ∧ (q.scope=(0))) ∧ (q.others=(0))) ∧ (q.pending=(0)))))
def initial : State := {nativeOpen:=(1), storage:=(1), control:=(1), root:=(1), scope:=(0), others:=(0), selected:=(0), phase:=(0), pending:=(0), committed:=(0), known:=(0), refused:=(0), unknown:=(0), borrow:=(0), created:=(0), released:=(0), lease:=(0), rootAuth:=(0), nativeAuth:=(0), finished:=(0), delivered:=(0), dataReads:=(0), gcOpen:=(1), frozen:=(0), scanning:=(0), scanned:=(0), gcEpoch:=(1), viewRoot:=(0)}
def enterNativeGuard (q : State) : Prop := ((((q.nativeOpen=(1)) ∧ (q.control=(1))) ∧ (q.scope=(0))) ∧ (q.phase=(0)))
def enterNativeNext (q : State) : State := {q with scope:=(1), nativeAuth:=(1), phase:=(1)}
def enterOtherGuard (q : State) : Prop := ((q.nativeOpen=(1)) ∧ (q.control=(1)))
def enterOtherNext (q : State) : State := {q with others:=(q.others+(1))}
def leaveOtherGuard (q : State) : Prop := (q.others≥(1))
def leaveOtherNext (q : State) : State := {q with others:=(q.others-(1))}
def selectHandleGuard (q : State) : Prop := (((((q.scope=(1)) ∧ (q.phase=(1))) ∧ (q.nativeOpen=(1))) ∧ (q.storage=(1))) ∧ (q.selected=(0)))
def selectHandleNext (q : State) : State := {q with selected:=(1)}
def deleteCommandGuard (q : State) : Prop := (q.nativeOpen=(1))
def deleteCommandNext (q : State) : State := {q with nativeOpen:=(0)}
def reserveRootGuard (q : State) : Prop := ((((((((q.phase=(1)) ∧ (q.scope=(1))) ∧ (q.selected=(1))) ∧ (q.nativeOpen=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.root=(1))) ∧ (q.lease=(0)))
def reserveRootNext (q : State) : State := {q with phase:=(2), lease:=(1), pending:=(1), rootAuth:=(1)}
def rejectBeforeReserveGuard (q : State) : Prop := ((((q.phase=(1)) ∧ (q.scope=(1))) ∧ (q.selected=(1))) ∧ ((q.nativeOpen=(0)) ∨ (q.gcOpen=(0))))
def rejectBeforeReserveNext (q : State) : State := {q with phase:=(4), known:=(1), refused:=(1)}
def commitJointGuard (q : State) : Prop := ((((((q.phase=(2)) ∧ (q.lease=(1))) ∧ (q.rootAuth=(1))) ∧ (q.nativeOpen=(1))) ∧ (q.root=(1))) ∧ (q.storage=(1)))
def commitJointNext (q : State) : State := {q with phase:=(3), committed:=(1), borrow:=(1), created:=(1), lease:=(0)}
def rejectReservedDeleteGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.lease=(1))) ∧ (q.nativeOpen=(0)))
def rejectReservedDeleteNext (q : State) : State := {q with phase:=(4), known:=(1), refused:=(1), pending:=(0), lease:=(0), rootAuth:=(0), unknown:=(0)}
def abortPreparationGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.lease=(1))) ∧ (q.committed=(0)))
def abortPreparationNext (q : State) : State := {q with phase:=(4), known:=(1), refused:=(1), pending:=(0), lease:=(0), rootAuth:=(0), unknown:=(0)}
def loseReplyGuard (q : State) : Prop := (((q.pending=(1)) ∧ (q.known=(0))) ∧ ((q.phase=(2)) ∨ (q.phase=(3))))
def loseReplyNext (q : State) : State := {q with unknown:=(1)}
def resolveReservedAbortGuard (q : State) : Prop := ((((q.phase=(2)) ∧ (q.unknown=(1))) ∧ (q.lease=(1))) ∧ (q.committed=(0)))
def resolveReservedAbortNext (q : State) : State := {q with phase:=(4), known:=(1), refused:=(1), pending:=(0), lease:=(0), rootAuth:=(0), unknown:=(0)}
def ackCommitGuard (q : State) : Prop := ((((q.phase=(3)) ∧ (q.committed=(1))) ∧ (q.pending=(1))) ∧ (q.borrow=(1)))
def ackCommitNext (q : State) : State := {q with known:=(1), pending:=(0), unknown:=(0)}
def readSelectedGuard (q : State) : Prop := (((((((q.phase=(3)) ∧ (q.known=(1))) ∧ (q.borrow=(1))) ∧ (q.rootAuth=(1))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.dataReads=(0)))
def readSelectedNext (q : State) : State := {q with dataReads:=(1)}
def finishUseGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.known=(1))) ∧ (q.borrow=(1)))
def finishUseNext (q : State) : State := {q with finished:=(1)}
def retireBorrowGuard (q : State) : Prop := ((((q.phase=(3)) ∧ (q.finished=(1))) ∧ (q.known=(1))) ∧ (q.borrow=(1)))
def retireBorrowNext (q : State) : State := {q with borrow:=(0), released:=(1), rootAuth:=(0), phase:=(4)}
def deliverOutcomeGuard (q : State) : Prop := True
def deliverOutcomeNext (q : State) : State := {q with delivered:=(1)}
def leaveScopeGuard (q : State) : Prop := ((((((q.phase=(4)) ∧ (q.delivered=(1))) ∧ (q.pending=(0))) ∧ (q.borrow=(0))) ∧ (q.lease=(0))) ∧ (q.scope=(1)))
def leaveScopeNext (q : State) : State := {q with scope:=(0), nativeAuth:=(0)}
def leaveEmptyScopeGuard (q : State) : Prop := ((((q.phase=(1)) ∧ (q.selected=(0))) ∧ (q.pending=(0))) ∧ (q.scope=(1)))
def leaveEmptyScopeNext (q : State) : State := {q with scope:=(0), nativeAuth:=(0), phase:=(0)}
def removeRootGuard (q : State) : Prop := (((((((((q.nativeOpen=(0)) ∧ (q.scope=(0))) ∧ (q.others=(0))) ∧ (q.borrow=(0))) ∧ (q.lease=(0))) ∧ (q.pending=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.root=(1)))
def removeRootNext (q : State) : State := {q with root:=(0)}
def freeStorageGuard (q : State) : Prop := ((((((((((q.nativeOpen=(0)) ∧ (q.root=(0))) ∧ (q.scope=(0))) ∧ (q.others=(0))) ∧ (q.borrow=(0))) ∧ (q.pending=(0))) ∧ (q.lease=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.storage=(1)))
def freeStorageNext (q : State) : State := {q with storage:=(0)}
def freeControlGuard (q : State) : Prop := ((((((((q.storage=(0)) ∧ (q.scope=(0))) ∧ (q.others=(0))) ∧ (q.pending=(0))) ∧ (q.nativeAuth=(0))) ∧ (q.gcOpen=(1))) ∧ (q.frozen=(0))) ∧ (q.control=(1)))
def freeControlNext (q : State) : State := {q with control:=(0)}
def closeGcGuard (q : State) : Prop := (q.gcOpen=(1))
def closeGcNext (q : State) : State := {q with gcOpen:=(0)}
def freezeRootsGuard (q : State) : Prop := (((q.gcOpen=(0)) ∧ (q.lease=(0))) ∧ (q.frozen=(0)))
def freezeRootsNext (q : State) : State := {q with frozen:=(1), viewRoot:=q.root}
def beginScanGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(0)))
def beginScanNext (q : State) : State := {q with scanning:=(1)}
def endScanGuard (q : State) : Prop := (q.scanning=(1))
def endScanNext (q : State) : State := {q with scanning:=(0), scanned:=(1)}
def resumeGcGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(1)))
def resumeGcNext (q : State) : State := {q with frozen:=(0), gcOpen:=(1), scanned:=(0), gcEpoch:=(q.gcEpoch+(1))}
def Step (q r : State) : Prop := (enterNativeGuard q ∧ r=enterNativeNext q) ∨ (enterOtherGuard q ∧ r=enterOtherNext q) ∨ (leaveOtherGuard q ∧ r=leaveOtherNext q) ∨ (selectHandleGuard q ∧ r=selectHandleNext q) ∨ (deleteCommandGuard q ∧ r=deleteCommandNext q) ∨ (reserveRootGuard q ∧ r=reserveRootNext q) ∨ (rejectBeforeReserveGuard q ∧ r=rejectBeforeReserveNext q) ∨ (commitJointGuard q ∧ r=commitJointNext q) ∨ (rejectReservedDeleteGuard q ∧ r=rejectReservedDeleteNext q) ∨ (abortPreparationGuard q ∧ r=abortPreparationNext q) ∨ (loseReplyGuard q ∧ r=loseReplyNext q) ∨ (resolveReservedAbortGuard q ∧ r=resolveReservedAbortNext q) ∨ (ackCommitGuard q ∧ r=ackCommitNext q) ∨ (readSelectedGuard q ∧ r=readSelectedNext q) ∨ (finishUseGuard q ∧ r=finishUseNext q) ∨ (retireBorrowGuard q ∧ r=retireBorrowNext q) ∨ (deliverOutcomeGuard q ∧ r=deliverOutcomeNext q) ∨ (leaveScopeGuard q ∧ r=leaveScopeNext q) ∨ (leaveEmptyScopeGuard q ∧ r=leaveEmptyScopeNext q) ∨ (removeRootGuard q ∧ r=removeRootNext q) ∨ (freeStorageGuard q ∧ r=freeStorageNext q) ∨ (freeControlGuard q ∧ r=freeControlNext q) ∨ (closeGcGuard q ∧ r=closeGcNext q) ∨ (freezeRootsGuard q ∧ r=freezeRootsNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (resumeGcGuard q ∧ r=resumeGcNext q) ∨ r=q
end DispatchJointAst
