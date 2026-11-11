import Std
namespace TclBorrowAst
set_option maxRecDepth 10000
structure State where
 generation : Int
 tokenGeneration : Int
 storage : Int
 closed : Int
 scope : Int
 borrower : Int
 borrowCreated : Int
 borrowReleased : Int
 selected : Int
 current : Int
 oldRoot : Int
 newRoot : Int
 dest : Int
 destVersion : Int
 pending : Int
 acknowledged : Int
 replyLost : Int
 writer : Int
 gcClosed : Int
 frozen : Int
 scanning : Int
 scanned : Int
 epoch : Int
 viewOld : Int
 viewNew : Int
 viewDest : Int
 prepared : Int
 refused : Int
 otherOld : Int
 otherNew : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.generation≥(0)) ∧ (q.generation≤(2)) ∧ (q.tokenGeneration≥(0)) ∧ (q.tokenGeneration≤(2)) ∧ (q.storage≥(0)) ∧ (q.storage≤(1)) ∧ (q.closed≥(0)) ∧ (q.closed≤(1)) ∧ (q.scope≥(0)) ∧ (q.scope≤(1)) ∧ (q.borrower≥(0)) ∧ (q.borrower≤(1)) ∧ (q.borrowCreated≥(0)) ∧ (q.borrowCreated≤(1)) ∧ (q.borrowReleased≥(0)) ∧ (q.borrowReleased≤(1)) ∧ (q.selected≥(0)) ∧ (q.selected≤(2)) ∧ (q.current≥(0)) ∧ (q.current≤(2)) ∧ (q.oldRoot≥(0)) ∧ (q.oldRoot≤(1)) ∧ (q.newRoot≥(0)) ∧ (q.newRoot≤(1)) ∧ (q.dest≥(0)) ∧ (q.dest≤(1)) ∧ (q.destVersion≥(0)) ∧ (q.destVersion≤(2)) ∧ (q.pending≥(0)) ∧ (q.pending≤(1)) ∧ (q.acknowledged≥(0)) ∧ (q.acknowledged≤(1)) ∧ (q.replyLost≥(0)) ∧ (q.replyLost≤(1)) ∧ (q.writer≥(0)) ∧ (q.writer≤(1)) ∧ (q.gcClosed≥(0)) ∧ (q.gcClosed≤(1)) ∧ (q.frozen≥(0)) ∧ (q.frozen≤(1)) ∧ (q.scanning≥(0)) ∧ (q.scanning≤(1)) ∧ (q.scanned≥(0)) ∧ (q.scanned≤(1)) ∧ (q.epoch≥(0)) ∧ (q.viewOld≥(0)) ∧ (q.viewOld≤(1)) ∧ (q.viewNew≥(0)) ∧ (q.viewNew≤(1)) ∧ (q.viewDest≥(0)) ∧ (q.viewDest≤(1)) ∧ (q.prepared≥(0)) ∧ (q.prepared≤(1)) ∧ (q.refused≥(0)) ∧ (q.refused≤(1)) ∧ (q.otherOld≥(0)) ∧ (q.otherNew≥(0)) ∧ (q.generation≥(1)) ∧ (q.tokenGeneration≥(1)) ∧ (q.current≥(1)) ∧ (q.epoch≥(1)) ∧ ((q.borrower+q.borrowReleased)=q.borrowCreated) ∧ ((q.borrower=(1)) → ((((q.storage=(1)) ∧ (q.scope=(1))) ∧ (q.selected≥(1))) ∧ (q.selected≤q.current))) ∧ (((q.borrower=(1)) ∧ (q.selected=(1))) → (q.oldRoot=(1))) ∧ (((q.borrower=(1)) ∧ (q.selected=(2))) → (q.newRoot=(1))) ∧ ((q.otherOld≥(1)) → ((q.storage=(1)) ∧ (q.oldRoot=(1)))) ∧ ((q.otherNew≥(1)) → (((q.storage=(1)) ∧ (q.newRoot=(1))) ∧ (q.current=(2)))) ∧ ((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.current=(1))) → (q.oldRoot=(1))) ∧ ((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.current=(2))) → (q.newRoot=(1))) ∧ ((q.prepared=(1)) → (((q.storage=(1)) ∧ (q.current=(1))) ∧ (q.newRoot=(1)))) ∧ ((q.pending=(1)) → ((((q.borrower=(1)) ∧ (q.dest=(1))) ∧ (q.destVersion=q.selected)) ∧ (q.acknowledged=(0)))) ∧ ((q.acknowledged=(1)) → ((q.borrowReleased=(1)) ∧ (q.borrower=(0)))) ∧ ((q.scope=(1)) → ((q.storage=(1)) ∧ (q.tokenGeneration=q.generation))) ∧ ((q.storage=(0)) → ((((((((q.closed=(1)) ∧ (q.scope=(0))) ∧ (q.borrower=(0))) ∧ (q.otherOld=(0))) ∧ (q.otherNew=(0))) ∧ (q.oldRoot=(0))) ∧ (q.newRoot=(0))) ∧ (q.prepared=(0)))) ∧ ((q.writer=(1)) → ((q.frozen=(0)) ∧ (q.scanning=(0)))) ∧ ((q.frozen=(1)) → (((((q.gcClosed=(1)) ∧ (q.writer=(0))) ∧ (q.oldRoot=q.viewOld)) ∧ (q.newRoot=q.viewNew)) ∧ (q.dest=q.viewDest))) ∧ ((q.scanning=(1)) → ((q.frozen=(1)) ∧ (q.scanned=(0)))) ∧ ((q.scanned=(1)) → ((q.frozen=(1)) ∧ (q.scanning=(0)))))
def initial : State := {generation:=(1), tokenGeneration:=(1), storage:=(1), closed:=(0), scope:=(0), borrower:=(0), borrowCreated:=(0), borrowReleased:=(0), selected:=(0), current:=(1), oldRoot:=(1), newRoot:=(0), dest:=(0), destVersion:=(0), pending:=(0), acknowledged:=(0), replyLost:=(0), writer:=(0), gcClosed:=(0), frozen:=(0), scanning:=(0), scanned:=(0), epoch:=(1), viewOld:=(0), viewNew:=(0), viewDest:=(0), prepared:=(0), refused:=(0), otherOld:=(0), otherNew:=(0)}
def selectDispatchGuard (q : State) : Prop := ((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.scope=(0))) ∧ (q.tokenGeneration=q.generation))
def selectDispatchNext (q : State) : State := {q with scope:=(1)}
def acquireBorrowGuard (q : State) : Prop := (((((((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.scope=(1))) ∧ (q.tokenGeneration=q.generation)) ∧ (q.borrowCreated=(0))) ∧ (q.refused=(0))) ∧ (q.writer=(0))) ∧ (q.gcClosed=(0))) ∧ (q.frozen=(0)))
def acquireBorrowNext (q : State) : State := {q with borrower:=(1), borrowCreated:=(1), selected:=q.current}
def refuseLateDispatchGuard (q : State) : Prop := ((((q.storage=(1)) ∧ (q.scope=(1))) ∧ (q.closed=(1))) ∧ (q.borrower=(0)))
def refuseLateDispatchNext (q : State) : State := {q with refused:=(1)}
def refuseGcClosedGuard (q : State) : Prop := ((((q.storage=(1)) ∧ (q.scope=(1))) ∧ (q.borrower=(0))) ∧ (q.gcClosed=(1)))
def refuseGcClosedNext (q : State) : State := {q with refused:=(1)}
def otherBorrowOldGuard (q : State) : Prop := ((((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.current=(1))) ∧ (q.gcClosed=(0))) ∧ (q.writer=(0))) ∧ (q.frozen=(0)))
def otherBorrowOldNext (q : State) : State := {q with otherOld:=(q.otherOld+(1))}
def otherBorrowNewGuard (q : State) : Prop := ((((((q.storage=(1)) ∧ (q.closed=(0))) ∧ (q.current=(2))) ∧ (q.gcClosed=(0))) ∧ (q.writer=(0))) ∧ (q.frozen=(0)))
def otherBorrowNewNext (q : State) : State := {q with otherNew:=(q.otherNew+(1))}
def releaseOtherOldGuard (q : State) : Prop := (q.otherOld≥(1))
def releaseOtherOldNext (q : State) : State := {q with otherOld:=(q.otherOld-(1))}
def releaseOtherNewGuard (q : State) : Prop := (q.otherNew≥(1))
def releaseOtherNewNext (q : State) : State := {q with otherNew:=(q.otherNew-(1))}
def acquireWriterGuard (q : State) : Prop := (((q.writer=(0)) ∧ (q.gcClosed=(0))) ∧ (q.frozen=(0)))
def acquireWriterNext (q : State) : State := {q with writer:=(1)}
def prepareSetterGuard (q : State) : Prop := ((((((q.writer=(1)) ∧ (q.storage=(1))) ∧ (q.closed=(0))) ∧ (q.current=(1))) ∧ (q.prepared=(0))) ∧ (q.newRoot=(0)))
def prepareSetterNext (q : State) : State := {q with prepared:=(1), newRoot:=(1)}
def commitSetterGuard (q : State) : Prop := (((((q.writer=(1)) ∧ (q.storage=(1))) ∧ (q.closed=(0))) ∧ (q.current=(1))) ∧ (q.prepared=(1)))
def commitSetterNext (q : State) : State := {q with current:=(2), prepared:=(0)}
def abortSetterGuard (q : State) : Prop := (((q.writer=(1)) ∧ (q.current=(1))) ∧ (q.prepared=(1)))
def abortSetterNext (q : State) : State := {q with prepared:=(0), newRoot:=(0)}
def releaseWriterGuard (q : State) : Prop := (q.writer=(1))
def releaseWriterNext (q : State) : State := {q with writer:=(0)}
def revokeGuard (q : State) : Prop := ((q.storage=(1)) ∧ (q.closed=(0)))
def revokeNext (q : State) : State := {q with closed:=(1)}
def publishDestinationGuard (q : State) : Prop := ((((((q.storage=(1)) ∧ (q.borrower=(1))) ∧ (q.writer=(1))) ∧ (q.dest=(0))) ∧ (q.pending=(0))) ∧ (q.acknowledged=(0)))
def publishDestinationNext (q : State) : State := {q with dest:=(1), destVersion:=q.selected, pending:=(1)}
def loseReplyGuard (q : State) : Prop := ((q.pending=(1)) ∧ (q.borrower=(1)))
def loseReplyNext (q : State) : State := {q with replyLost:=(1)}
def acknowledgeTransferGuard (q : State) : Prop := (((((q.pending=(1)) ∧ (q.dest=(1))) ∧ (q.borrower=(1))) ∧ (q.tokenGeneration=q.generation)) ∧ (q.destVersion=q.selected))
def acknowledgeTransferNext (q : State) : State := {q with pending:=(0), borrower:=(0), borrowReleased:=(1), acknowledged:=(1), replyLost:=(0)}
def dropOldVersionGuard (q : State) : Prop := (((((q.storage=(1)) ∧ (q.current=(2))) ∧ (q.writer=(1))) ∧ (q.otherOld=(0))) ∧ ((q.borrower=(0)) ∨ (q.selected≠(1))))
def dropOldVersionNext (q : State) : State := {q with oldRoot:=(0)}
def dropRevokedRootsGuard (q : State) : Prop := ((((((q.storage=(1)) ∧ (q.closed=(1))) ∧ (q.writer=(1))) ∧ (q.borrower=(0))) ∧ (q.otherOld=(0))) ∧ (q.otherNew=(0)))
def dropRevokedRootsNext (q : State) : State := {q with oldRoot:=(0), newRoot:=(0), prepared:=(0)}
def leaveDispatchGuard (q : State) : Prop := ((q.scope=(1)) ∧ (q.borrower=(0)))
def leaveDispatchNext (q : State) : State := {q with scope:=(0)}
def freeSourceGuard (q : State) : Prop := ((((((((((q.storage=(1)) ∧ (q.closed=(1))) ∧ (q.writer=(1))) ∧ (q.scope=(0))) ∧ (q.borrower=(0))) ∧ (q.otherOld=(0))) ∧ (q.otherNew=(0))) ∧ (q.oldRoot=(0))) ∧ (q.newRoot=(0))) ∧ (q.prepared=(0)))
def freeSourceNext (q : State) : State := {q with storage:=(0)}
def dropDestinationGuard (q : State) : Prop := (((((q.dest=(1)) ∧ (q.pending=(0))) ∧ (q.borrower=(0))) ∧ (q.acknowledged=(1))) ∧ (q.writer=(1)))
def dropDestinationNext (q : State) : State := {q with dest:=(0), destVersion:=(0)}
def reuseStorageGuard (q : State) : Prop := ((((((q.storage=(0)) ∧ (q.generation=(1))) ∧ (q.dest=(0))) ∧ (q.writer=(0))) ∧ (q.gcClosed=(0))) ∧ (q.frozen=(0)))
def reuseStorageNext (q : State) : State := {q with generation:=(2), storage:=(1), closed:=(0), current:=(1), oldRoot:=(1), newRoot:=(0), borrowCreated:=(0), borrowReleased:=(0), selected:=(0), acknowledged:=(0), refused:=(0), replyLost:=(0)}
def selectNewTokenGuard (q : State) : Prop := ((((q.storage=(1)) ∧ (q.generation=(2))) ∧ (q.scope=(0))) ∧ (q.borrowCreated=(0)))
def selectNewTokenNext (q : State) : State := {q with tokenGeneration:=(2)}
def closeGcGateGuard (q : State) : Prop := (q.gcClosed=(0))
def closeGcGateNext (q : State) : State := {q with gcClosed:=(1)}
def freezeRootsGuard (q : State) : Prop := True
def freezeRootsNext (q : State) : State := {q with frozen:=(1), viewOld:=q.oldRoot, viewNew:=q.newRoot, viewDest:=q.dest}
def beginScanGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(0)))
def beginScanNext (q : State) : State := {q with scanning:=(1)}
def endScanGuard (q : State) : Prop := (q.scanning=(1))
def endScanNext (q : State) : State := {q with scanning:=(0), scanned:=(1)}
def resumeRootsGuard (q : State) : Prop := ((((q.frozen=(1)) ∧ (q.scanning=(0))) ∧ (q.scanned=(1))) ∧ (q.writer=(0)))
def resumeRootsNext (q : State) : State := {q with frozen:=(0), gcClosed:=(0), scanned:=(0), epoch:=(q.epoch+(1))}
def Step (q r : State) : Prop := (selectDispatchGuard q ∧ r=selectDispatchNext q) ∨ (acquireBorrowGuard q ∧ r=acquireBorrowNext q) ∨ (refuseLateDispatchGuard q ∧ r=refuseLateDispatchNext q) ∨ (refuseGcClosedGuard q ∧ r=refuseGcClosedNext q) ∨ (otherBorrowOldGuard q ∧ r=otherBorrowOldNext q) ∨ (otherBorrowNewGuard q ∧ r=otherBorrowNewNext q) ∨ (releaseOtherOldGuard q ∧ r=releaseOtherOldNext q) ∨ (releaseOtherNewGuard q ∧ r=releaseOtherNewNext q) ∨ (acquireWriterGuard q ∧ r=acquireWriterNext q) ∨ (prepareSetterGuard q ∧ r=prepareSetterNext q) ∨ (commitSetterGuard q ∧ r=commitSetterNext q) ∨ (abortSetterGuard q ∧ r=abortSetterNext q) ∨ (releaseWriterGuard q ∧ r=releaseWriterNext q) ∨ (revokeGuard q ∧ r=revokeNext q) ∨ (publishDestinationGuard q ∧ r=publishDestinationNext q) ∨ (loseReplyGuard q ∧ r=loseReplyNext q) ∨ (acknowledgeTransferGuard q ∧ r=acknowledgeTransferNext q) ∨ (dropOldVersionGuard q ∧ r=dropOldVersionNext q) ∨ (dropRevokedRootsGuard q ∧ r=dropRevokedRootsNext q) ∨ (leaveDispatchGuard q ∧ r=leaveDispatchNext q) ∨ (freeSourceGuard q ∧ r=freeSourceNext q) ∨ (dropDestinationGuard q ∧ r=dropDestinationNext q) ∨ (reuseStorageGuard q ∧ r=reuseStorageNext q) ∨ (selectNewTokenGuard q ∧ r=selectNewTokenNext q) ∨ (closeGcGateGuard q ∧ r=closeGcGateNext q) ∨ (freezeRootsGuard q ∧ r=freezeRootsNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (resumeRootsGuard q ∧ r=resumeRootsNext q) ∨ r=q
end TclBorrowAst
