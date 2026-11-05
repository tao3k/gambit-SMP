import Std
namespace SourceOwnerAst
set_option maxRecDepth 10000
structure State where
 persistent : Int
 registry : Int
 owner : Int
 root : Int
 writer : Int
 writerRoot : Int
 payload : Int
 writeId : Int
 seenWrite : Int
 lastDone : Int
 round : Int
 gc : Int
 manifest : Int
 storage : Int
 pin0 : Int
 pin1 : Int
 used0 : Int
 used1 : Int
 view0 : Int
 view1 : Int
 target0 : Int
 target1 : Int
 targetView0 : Int
 targetView1 : Int
 guard0 : Int
 guard1 : Int
 ack0 : Int
 ack1 : Int
 queries : Int
 rejects : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.registry≥(0)) ∧ (q.registry≤(1)) ∧ (q.owner≥(0)) ∧ (q.owner≤(4)) ∧ (q.root≥(0)) ∧ (q.root≤(1)) ∧ (q.writer≥(0)) ∧ (q.writer≤(2)) ∧ (q.writerRoot≥(0)) ∧ (q.writerRoot≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.manifest≥(0)) ∧ (q.manifest≤(1)) ∧ (q.storage≥(0)) ∧ (q.storage≤(1)) ∧ (q.pin0≥(0)) ∧ (q.pin0≤(1)) ∧ (q.pin1≥(0)) ∧ (q.pin1≤(1)) ∧ (q.used0≥(0)) ∧ (q.used0≤(1)) ∧ (q.used1≥(0)) ∧ (q.used1≤(1)) ∧ (q.target0≥(0)) ∧ (q.target0≤(1)) ∧ (q.target1≥(0)) ∧ (q.target1≤(1)) ∧ (q.guard0≥(0)) ∧ (q.guard0≤(4)) ∧ (q.guard1≥(0)) ∧ (q.guard1≤(4)) ∧ (q.payload≥(0)) ∧ (q.writeId≥(0)) ∧ (q.seenWrite≥(0)) ∧ (q.lastDone≥(0)) ∧ (q.round≥(0)) ∧ (q.view0≥(0)) ∧ (q.view1≥(0)) ∧ (q.targetView0≥(0)) ∧ (q.targetView1≥(0)) ∧ (q.queries≥(0)) ∧ (q.rejects≥(0)) ∧ (q.ack0≥(-(1))) ∧ (q.ack0≤q.round) ∧ ((q.pin0=(1)) → ((((((q.owner=(2)) ∨ (q.owner=(3))) ∧ (q.root=(1))) ∧ (q.writer=(0))) ∧ (q.used0=(1))) ∧ (q.view0=q.payload))) ∧ ((q.target0=(1)) → ((q.used0=(1)) ∧ (q.targetView0≤q.payload))) ∧ ((((q.guard0=(1)) ∨ (q.guard0=(2))) ∨ (q.guard0=(3))) → (q.target0=(1))) ∧ (((q.guard0=(1)) ∨ (q.guard0=(3))) → (q.pin0=(1))) ∧ ((q.guard0>(0)) → (q.used0=(1))) ∧ (q.ack1≥(-(1))) ∧ (q.ack1≤q.round) ∧ ((q.pin1=(1)) → ((((((q.owner=(2)) ∨ (q.owner=(3))) ∧ (q.root=(1))) ∧ (q.writer=(0))) ∧ (q.used1=(1))) ∧ (q.view1=q.payload))) ∧ ((q.target1=(1)) → ((q.used1=(1)) ∧ (q.targetView1≤q.payload))) ∧ ((((q.guard1=(1)) ∨ (q.guard1=(2))) ∨ (q.guard1=(3))) → (q.target1=(1))) ∧ (((q.guard1=(1)) ∨ (q.guard1=(3))) → (q.pin1=(1))) ∧ ((q.guard1>(0)) → (q.used1=(1))) ∧ (((q.owner=(2)) ∨ (q.owner=(3))) → (q.root=(1))) ∧ ((q.owner=(0)) → ((q.root=(0)) ∧ (q.writer=(0)))) ∧ ((q.owner=(4)) → ((((q.root=(0)) ∧ (q.writer=(0))) ∧ (q.pin0=(0))) ∧ (q.pin1=(0)))) ∧ ((q.writer>(0)) → ((((((q.owner=(2)) ∨ (q.owner=(3))) ∧ (q.pin0=(0))) ∧ (q.pin1=(0))) ∧ (q.writerRoot=(1))) ∧ (q.writeId>q.lastDone))) ∧ ((q.writer=(0)) → (q.writerRoot=(0))) ∧ ((q.storage=(1)) → (((((q.owner=(3)) ∨ (q.owner=(4))) ∧ (q.writer=(0))) ∧ (q.pin0=(0))) ∧ (q.pin1=(0)))) ∧ ((q.manifest=(1)) → ((q.registry=(0)) ∧ (q.owner≥(3)))) ∧ (q.lastDone≤q.writeId) ∧ (q.persistent≥(0)) ∧ (q.persistent≤(1)))
def initial : State := {persistent:=(0), registry:=(1), owner:=(0), root:=(0), writer:=(0), writerRoot:=(0), payload:=(0), writeId:=(0), seenWrite:=(0), lastDone:=(0), round:=(0), gc:=(0), manifest:=(0), storage:=(0), pin0:=(0), pin1:=(0), used0:=(0), used1:=(0), view0:=(0), view1:=(0), target0:=(0), target1:=(0), targetView0:=(0), targetView1:=(0), guard0:=(0), guard1:=(0), ack0:=(-(1)), ack1:=(-(1)), queries:=(0), rejects:=(0)}
def reserveOwnerGuard (q : State) : Prop := (q.owner=(0)) ∧ (q.registry=(1))
def reserveOwnerNext (q : State) : State := {q with owner:=(1)}
def prepareRootGuard (q : State) : Prop := (q.owner=(1)) ∧ (q.gc=(0))
def prepareRootNext (q : State) : State := {q with root:=(1)}
def publishOwnerGuard (q : State) : Prop := (q.owner=(1)) ∧ (q.root=(1)) ∧ (q.registry=(1)) ∧ (q.gc=(0))
def publishOwnerNext (q : State) : State := {q with owner:=(2)}
def abortPrivateGuard (q : State) : Prop := (q.owner=(1)) ∧ (q.gc=(0))
def abortPrivateNext (q : State) : State := {q with owner:=(4), root:=(0)}
def closeRegistryGuard (q : State) : Prop := (q.registry=(1))
def closeRegistryNext (q : State) : State := {q with registry:=(0)}
def closeOwnerGuard (q : State) : Prop := (q.owner=(2))
def closeOwnerNext (q : State) : State := {q with owner:=(3)}
def sealRosterGuard (q : State) : Prop := (q.registry=(0)) ∧ ((q.owner=(3)) ∨ (q.owner=(4)))
def sealRosterNext (q : State) : State := {q with manifest:=(1)}
def rejectLateGuard (q : State) : Prop := ((q.owner=(3)) ∨ (q.owner=(4)))
def rejectLateNext (q : State) : State := {q with rejects:=(q.rejects+(1))}
def beginWriteGuard (q : State) : Prop := (q.owner=(2)) ∧ (q.writer=(0)) ∧ (q.pin0=(0)) ∧ (q.pin1=(0)) ∧ (q.gc=(0)) ∧ (q.storage=(0))
def beginWriteNext (q : State) : State := {q with writer:=(1), writerRoot:=(1), writeId:=(q.writeId+(1))}
def unknownWriteGuard (q : State) : Prop := (q.writer=(1))
def unknownWriteNext (q : State) : State := {q with writer:=(2)}
def presentCurrentWriteGuard (q : State) : Prop := (q.writeId>(0))
def presentCurrentWriteNext (q : State) : State := {q with seenWrite:=q.writeId}
def presentOldWriteGuard (q : State) : Prop := (q.writeId>(0))
def presentOldWriteNext (q : State) : State := {q with seenWrite:=(q.writeId-(1))}
def commitWriteGuard (q : State) : Prop := ((q.writer=(1)) ∨ (q.writer=(2))) ∧ (q.seenWrite=q.writeId) ∧ (q.gc=(0))
def commitWriteNext (q : State) : State := {q with writer:=(0), writerRoot:=(0), payload:=(q.payload+(1)), lastDone:=q.writeId}
def abortWriteGuard (q : State) : Prop := ((q.writer=(1)) ∨ (q.writer=(2))) ∧ (q.seenWrite=q.writeId) ∧ (q.gc=(0))
def abortWriteNext (q : State) : State := {q with writer:=(0), writerRoot:=(0), lastDone:=q.writeId}
def queryWriteGuard (q : State) : Prop := (q.writeId>(0))
def queryWriteNext (q : State) : State := {q with queries:=(q.queries+(1))}
def pin0Guard (q : State) : Prop := (q.owner=(2)) ∧ (q.writer=(0)) ∧ (q.used0=(0))
def pin0Next (q : State) : State := {q with pin0:=(1), used0:=(1), view0:=q.payload}
def enrollTarget0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.target0=(0)) ∧ (q.gc=(0))
def enrollTarget0Next (q : State) : State := {q with target0:=(1), targetView0:=q.view0}
def ackRound0Guard (q : State) : Prop := (q.target0=(1)) ∧ (q.gc=(0))
def ackRound0Next (q : State) : State := {q with ack0:=q.round}
def reserveGuard0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.target0=(1)) ∧ (q.guard0=(0)) ∧ ((q.ack0=q.round) ∨ (q.persistent=(1))) ∧ (q.gc=(0))
def reserveGuard0Next (q : State) : State := {q with guard0:=(1)}
def commitGuard0Guard (q : State) : Prop := (q.guard0=(1))
def commitGuard0Next (q : State) : State := {q with guard0:=(2)}
def unknownGuard0Guard (q : State) : Prop := (q.guard0=(1))
def unknownGuard0Next (q : State) : State := {q with guard0:=(3)}
def resolveGuard0Guard (q : State) : Prop := (q.guard0=(3))
def resolveGuard0Next (q : State) : State := {q with guard0:=(2)}
def returnPin0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.guard0=(2)) ∧ (q.target0=(1)) ∧ ((q.ack0=q.round) ∨ (q.persistent=(1))) ∧ (q.gc=(0))
def returnPin0Next (q : State) : State := {q with pin0:=(0)}
def finishGuard0Guard (q : State) : Prop := (q.guard0=(2)) ∧ (q.pin0=(0))
def finishGuard0Next (q : State) : State := {q with guard0:=(4)}
def retireTarget0Guard (q : State) : Prop := (q.guard0=(4)) ∧ (q.gc=(0))
def retireTarget0Next (q : State) : State := {q with target0:=(0)}
def pin1Guard (q : State) : Prop := (q.owner=(2)) ∧ (q.writer=(0)) ∧ (q.used1=(0)) ∧ (q.guard0=(2))
def pin1Next (q : State) : State := {q with pin1:=(1), used1:=(1), view1:=q.payload}
def enrollTarget1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.target1=(0)) ∧ (q.gc=(0))
def enrollTarget1Next (q : State) : State := {q with target1:=(1), targetView1:=q.view1}
def ackRound1Guard (q : State) : Prop := (q.target1=(1)) ∧ (q.gc=(0))
def ackRound1Next (q : State) : State := {q with ack1:=q.round}
def reserveGuard1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.target1=(1)) ∧ (q.guard1=(0)) ∧ ((q.ack1=q.round) ∨ (q.persistent=(1))) ∧ (q.gc=(0))
def reserveGuard1Next (q : State) : State := {q with guard1:=(1)}
def commitGuard1Guard (q : State) : Prop := (q.guard1=(1))
def commitGuard1Next (q : State) : State := {q with guard1:=(2)}
def unknownGuard1Guard (q : State) : Prop := (q.guard1=(1))
def unknownGuard1Next (q : State) : State := {q with guard1:=(3)}
def resolveGuard1Guard (q : State) : Prop := (q.guard1=(3))
def resolveGuard1Next (q : State) : State := {q with guard1:=(2)}
def returnPin1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.guard1=(2)) ∧ (q.target1=(1)) ∧ ((q.ack1=q.round) ∨ (q.persistent=(1))) ∧ (q.gc=(0))
def returnPin1Next (q : State) : State := {q with pin1:=(0)}
def finishGuard1Guard (q : State) : Prop := (q.guard1=(2)) ∧ (q.pin1=(0))
def finishGuard1Next (q : State) : State := {q with guard1:=(4)}
def retireTarget1Guard (q : State) : Prop := (q.guard1=(4)) ∧ (q.gc=(0))
def retireTarget1Next (q : State) : State := {q with target1:=(0)}
def qualifyPersistentCoverageGuard (q : State) : Prop := (q.owner=(2)) ∧ (q.target0=(1)) ∧ (q.gc=(0))
def qualifyPersistentCoverageNext (q : State) : State := {q with persistent:=(1)}
def freezeGcGuard (q : State) : Prop := (q.gc=(0)) ∧ ((((q.root=(1)) ∨ (q.writerRoot=(1))) ∨ (q.target0=(1))) ∨ (q.target1=(1)))
def freezeGcNext (q : State) : State := {q with gc:=(1), round:=(q.round+(1))}
def finishGcGuard (q : State) : Prop := (q.gc=(1))
def finishGcNext (q : State) : State := {q with gc:=(0)}
def storageReceiptGuard (q : State) : Prop := (q.owner=(3)) ∧ (q.writer=(0)) ∧ (q.pin0=(0)) ∧ (q.pin1=(0)) ∧ (q.gc=(0))
def storageReceiptNext (q : State) : State := {q with storage:=(1)}
def bulkCleanupGuard (q : State) : Prop := (q.owner=(3)) ∧ (q.registry=(0)) ∧ (q.manifest=(1)) ∧ (q.storage=(1)) ∧ (q.writer=(0)) ∧ (q.pin0=(0)) ∧ (q.pin1=(0)) ∧ (q.gc=(0))
def bulkCleanupNext (q : State) : State := {q with owner:=(4), root:=(0)}
def Step (q r : State) : Prop := (reserveOwnerGuard q ∧ r=reserveOwnerNext q) ∨ (prepareRootGuard q ∧ r=prepareRootNext q) ∨ (publishOwnerGuard q ∧ r=publishOwnerNext q) ∨ (abortPrivateGuard q ∧ r=abortPrivateNext q) ∨ (closeRegistryGuard q ∧ r=closeRegistryNext q) ∨ (closeOwnerGuard q ∧ r=closeOwnerNext q) ∨ (sealRosterGuard q ∧ r=sealRosterNext q) ∨ (rejectLateGuard q ∧ r=rejectLateNext q) ∨ (beginWriteGuard q ∧ r=beginWriteNext q) ∨ (unknownWriteGuard q ∧ r=unknownWriteNext q) ∨ (presentCurrentWriteGuard q ∧ r=presentCurrentWriteNext q) ∨ (presentOldWriteGuard q ∧ r=presentOldWriteNext q) ∨ (commitWriteGuard q ∧ r=commitWriteNext q) ∨ (abortWriteGuard q ∧ r=abortWriteNext q) ∨ (queryWriteGuard q ∧ r=queryWriteNext q) ∨ (pin0Guard q ∧ r=pin0Next q) ∨ (enrollTarget0Guard q ∧ r=enrollTarget0Next q) ∨ (ackRound0Guard q ∧ r=ackRound0Next q) ∨ (reserveGuard0Guard q ∧ r=reserveGuard0Next q) ∨ (commitGuard0Guard q ∧ r=commitGuard0Next q) ∨ (unknownGuard0Guard q ∧ r=unknownGuard0Next q) ∨ (resolveGuard0Guard q ∧ r=resolveGuard0Next q) ∨ (returnPin0Guard q ∧ r=returnPin0Next q) ∨ (finishGuard0Guard q ∧ r=finishGuard0Next q) ∨ (retireTarget0Guard q ∧ r=retireTarget0Next q) ∨ (pin1Guard q ∧ r=pin1Next q) ∨ (enrollTarget1Guard q ∧ r=enrollTarget1Next q) ∨ (ackRound1Guard q ∧ r=ackRound1Next q) ∨ (reserveGuard1Guard q ∧ r=reserveGuard1Next q) ∨ (commitGuard1Guard q ∧ r=commitGuard1Next q) ∨ (unknownGuard1Guard q ∧ r=unknownGuard1Next q) ∨ (resolveGuard1Guard q ∧ r=resolveGuard1Next q) ∨ (returnPin1Guard q ∧ r=returnPin1Next q) ∨ (finishGuard1Guard q ∧ r=finishGuard1Next q) ∨ (retireTarget1Guard q ∧ r=retireTarget1Next q) ∨ (qualifyPersistentCoverageGuard q ∧ r=qualifyPersistentCoverageNext q) ∨ (freezeGcGuard q ∧ r=freezeGcNext q) ∨ (finishGcGuard q ∧ r=finishGcNext q) ∨ (storageReceiptGuard q ∧ r=storageReceiptNext q) ∨ (bulkCleanupGuard q ∧ r=bulkCleanupNext q) ∨ r=q
end SourceOwnerAst
