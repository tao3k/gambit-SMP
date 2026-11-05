import Std
namespace StorageIndexAst
set_option maxRecDepth 10000
structure State where
 opened : Int
 generation : Int
 revision : Int
 adjacent : Int
 payload : Int
 rejections : Int
 a : Int
 aSnapshot : Int
 aSnapshotGeneration : Int
 aGeneration : Int
 aLease : Int
 aBound : Int
 aRoot : Int
 aKnown : Int
 aReaders : Int
 aScan : Int
 b : Int
 bSnapshot : Int
 bSnapshotGeneration : Int
 bGeneration : Int
 bLease : Int
 bBound : Int
 bRoot : Int
 bKnown : Int
 bReaders : Int
 bScan : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.opened≥(0)) ∧ (q.opened≤(1)) ∧ ((q.a=(4)) → (q.aKnown=(1))) ∧ ((q.b=(4)) → (q.bKnown=(1))) ∧ (q.generation≥(1)) ∧ (q.generation≤(2)) ∧ (q.revision≥(0)) ∧ (q.adjacent≥(0)) ∧ (q.adjacent≤(1)) ∧ (q.payload≥(0)) ∧ (q.rejections≥(0)) ∧ (q.a≥(0)) ∧ (q.a≤(5)) ∧ (q.aSnapshot≥(-(1))) ∧ (q.aSnapshot≤q.revision) ∧ (q.aSnapshotGeneration≥(0)) ∧ (q.aSnapshotGeneration≤q.generation) ∧ (q.aGeneration≥(0)) ∧ (q.aGeneration≤q.generation) ∧ (q.aLease≥(0)) ∧ (q.aLease≤(1)) ∧ (q.aRoot≥(0)) ∧ (q.aRoot≤(1)) ∧ (q.aKnown≥(0)) ∧ (q.aKnown≤(1)) ∧ (q.aReaders≥(0)) ∧ (q.aReaders≤(1)) ∧ (q.aScan≥(0)) ∧ (q.aScan≤(1)) ∧ (((q.a≥(1)) ∧ (q.a≤(4))) → (((q.aLease=(1)) ∧ (q.aGeneration=q.generation)) ∧ (q.aBound=q.payload))) ∧ ((q.a=(0)) → ((((q.aLease=(0)) ∧ (q.aRoot=(0))) ∧ (q.aReaders=(0))) ∧ (q.aScan=(0)))) ∧ ((q.a=(5)) → (((((q.aLease=(0)) ∧ (q.aKnown=(1))) ∧ (q.aReaders=(0))) ∧ (q.aScan=(0))) ∧ (q.aRoot=(0)))) ∧ (((q.a=(2)) ∨ (q.a=(3))) → (q.aRoot=(1))) ∧ (((q.aReaders=(1)) ∨ (q.aScan=(1))) → ((q.a=(2)) ∨ (q.a=(3)))) ∧ ((q.aKnown=(1)) → (q.a≥(2))) ∧ (q.b≥(0)) ∧ (q.b≤(5)) ∧ (q.bSnapshot≥(-(1))) ∧ (q.bSnapshot≤q.revision) ∧ (q.bSnapshotGeneration≥(0)) ∧ (q.bSnapshotGeneration≤q.generation) ∧ (q.bGeneration≥(0)) ∧ (q.bGeneration≤q.generation) ∧ (q.bLease≥(0)) ∧ (q.bLease≤(1)) ∧ (q.bRoot≥(0)) ∧ (q.bRoot≤(1)) ∧ (q.bKnown≥(0)) ∧ (q.bKnown≤(1)) ∧ (q.bReaders≥(0)) ∧ (q.bReaders≤(1)) ∧ (q.bScan≥(0)) ∧ (q.bScan≤(1)) ∧ (((q.b≥(1)) ∧ (q.b≤(4))) → (((q.bLease=(1)) ∧ (q.bGeneration=q.generation)) ∧ (q.bBound=q.payload))) ∧ ((q.b=(0)) → ((((q.bLease=(0)) ∧ (q.bRoot=(0))) ∧ (q.bReaders=(0))) ∧ (q.bScan=(0)))) ∧ ((q.b=(5)) → (((((q.bLease=(0)) ∧ (q.bKnown=(1))) ∧ (q.bReaders=(0))) ∧ (q.bScan=(0))) ∧ (q.bRoot=(0)))) ∧ (((q.b=(2)) ∨ (q.b=(3))) → (q.bRoot=(1))) ∧ (((q.bReaders=(1)) ∨ (q.bScan=(1))) → ((q.b=(2)) ∨ (q.b=(3)))) ∧ ((q.bKnown=(1)) → (q.b≥(2))) ∧ (((((q.a≥(1)) ∧ (q.a≤(4))) ∧ (q.b≥(1))) ∧ (q.b≤(4))) → (q.adjacent=(1))))
def initial : State := {opened:=(1), generation:=(1), revision:=(0), adjacent:=(0), payload:=(0), rejections:=(0), a:=(0), aSnapshot:=(-(1)), aSnapshotGeneration:=(0), aGeneration:=(0), aLease:=(0), aBound:=(0), aRoot:=(0), aKnown:=(0), aReaders:=(0), aScan:=(0), b:=(0), bSnapshot:=(-(1)), bSnapshotGeneration:=(0), bGeneration:=(0), bLease:=(0), bBound:=(0), bRoot:=(0), bKnown:=(0), bReaders:=(0), bScan:=(0)}
def chooseAdjacentGuard (q : State) : Prop := (q.revision=(0)) ∧ (q.a=(0)) ∧ (q.b=(0))
def chooseAdjacentNext (q : State) : State := {q with adjacent:=(1)}
def observeAGuard (q : State) : Prop := (q.a=(0))
def observeANext (q : State) : State := {q with aSnapshot:=q.revision, aSnapshotGeneration:=q.generation}
def reserveAGuard (q : State) : Prop := (q.opened=(1)) ∧ (q.a=(0)) ∧ (q.aSnapshot=q.revision) ∧ (q.aSnapshotGeneration=q.generation) ∧ (((q.b=(0)) ∨ (q.b=(5))) ∨ (q.adjacent=(1)))
def reserveANext (q : State) : State := {q with a:=(1), aGeneration:=q.generation, aLease:=(1), aBound:=q.payload, revision:=(q.revision+(1))}
def prepareAGuard (q : State) : Prop := (q.a=(1))
def prepareANext (q : State) : State := {q with aRoot:=(1)}
def publishAGuard (q : State) : Prop := (q.a=(1)) ∧ (q.aRoot=(1))
def publishANext (q : State) : State := {q with a:=(2)}
def queryAGuard (q : State) : Prop := (q.a≥(2)) ∧ (q.a≤(5))
def queryANext (q : State) : State := {q with aKnown:=(1)}
def borrowAGuard (q : State) : Prop := (q.a=(2)) ∧ (q.aReaders=(0))
def borrowANext (q : State) : State := {q with aReaders:=(1)}
def returnAGuard (q : State) : Prop := (q.aReaders=(1))
def returnANext (q : State) : State := {q with aReaders:=(0)}
def scanAGuard (q : State) : Prop := (q.a=(2)) ∧ (q.aScan=(0))
def scanANext (q : State) : State := {q with aScan:=(1)}
def finishScanAGuard (q : State) : Prop := (q.aScan=(1))
def finishScanANext (q : State) : State := {q with aScan:=(0)}
def revokeAGuard (q : State) : Prop := (q.a=(2))
def revokeANext (q : State) : State := {q with a:=(3)}
def drainAGuard (q : State) : Prop := (q.a=(3)) ∧ (q.aKnown=(1)) ∧ (q.aReaders=(0)) ∧ (q.aScan=(0))
def drainANext (q : State) : State := {q with a:=(4)}
def abortAGuard (q : State) : Prop := (q.a=(1))
def abortANext (q : State) : State := {q with a:=(4), aKnown:=(1)}
def settleAGuard (q : State) : Prop := (q.a=(4)) ∧ (q.aKnown=(1)) ∧ (q.aGeneration=q.generation) ∧ (q.aReaders=(0)) ∧ (q.aScan=(0))
def settleANext (q : State) : State := {q with a:=(5), aLease:=(0), aRoot:=(0), revision:=(q.revision+(1))}
def rejectOldAGuard (q : State) : Prop := (q.aGeneration>(0)) ∧ (q.aGeneration≠q.generation)
def rejectOldANext (q : State) : State := {q with rejections:=(q.rejections+(1))}
def observeBGuard (q : State) : Prop := (q.b=(0))
def observeBNext (q : State) : State := {q with bSnapshot:=q.revision, bSnapshotGeneration:=q.generation}
def reserveBGuard (q : State) : Prop := (q.opened=(1)) ∧ (q.b=(0)) ∧ (q.bSnapshot=q.revision) ∧ (q.bSnapshotGeneration=q.generation) ∧ (((q.a=(0)) ∨ (q.a=(5))) ∨ (q.adjacent=(1)))
def reserveBNext (q : State) : State := {q with b:=(1), bGeneration:=q.generation, bLease:=(1), bBound:=q.payload, revision:=(q.revision+(1))}
def prepareBGuard (q : State) : Prop := (q.b=(1))
def prepareBNext (q : State) : State := {q with bRoot:=(1)}
def publishBGuard (q : State) : Prop := (q.b=(1)) ∧ (q.bRoot=(1))
def publishBNext (q : State) : State := {q with b:=(2)}
def queryBGuard (q : State) : Prop := (q.b≥(2)) ∧ (q.b≤(5))
def queryBNext (q : State) : State := {q with bKnown:=(1)}
def borrowBGuard (q : State) : Prop := (q.b=(2)) ∧ (q.bReaders=(0))
def borrowBNext (q : State) : State := {q with bReaders:=(1)}
def returnBGuard (q : State) : Prop := (q.bReaders=(1))
def returnBNext (q : State) : State := {q with bReaders:=(0)}
def scanBGuard (q : State) : Prop := (q.b=(2)) ∧ (q.bScan=(0))
def scanBNext (q : State) : State := {q with bScan:=(1)}
def finishScanBGuard (q : State) : Prop := (q.bScan=(1))
def finishScanBNext (q : State) : State := {q with bScan:=(0)}
def revokeBGuard (q : State) : Prop := (q.b=(2))
def revokeBNext (q : State) : State := {q with b:=(3)}
def drainBGuard (q : State) : Prop := (q.b=(3)) ∧ (q.bKnown=(1)) ∧ (q.bReaders=(0)) ∧ (q.bScan=(0))
def drainBNext (q : State) : State := {q with b:=(4)}
def abortBGuard (q : State) : Prop := (q.b=(1))
def abortBNext (q : State) : State := {q with b:=(4), bKnown:=(1)}
def settleBGuard (q : State) : Prop := (q.b=(4)) ∧ (q.bKnown=(1)) ∧ (q.bGeneration=q.generation) ∧ (q.bReaders=(0)) ∧ (q.bScan=(0))
def settleBNext (q : State) : State := {q with b:=(5), bLease:=(0), bRoot:=(0), revision:=(q.revision+(1))}
def rejectOldBGuard (q : State) : Prop := (q.bGeneration>(0)) ∧ (q.bGeneration≠q.generation)
def rejectOldBNext (q : State) : State := {q with rejections:=(q.rejections+(1))}
def sourceWriteGuard (q : State) : Prop := (q.opened=(1)) ∧ (q.aLease=(0)) ∧ (q.bLease=(0))
def sourceWriteNext (q : State) : State := {q with payload:=(q.payload+(1))}
def closeIndexGuard (q : State) : Prop := (q.opened=(1))
def closeIndexNext (q : State) : State := {q with opened:=(0)}
def reuseGuard (q : State) : Prop := (q.opened=(0)) ∧ (q.generation<(2)) ∧ ((q.a=(0)) ∨ (q.a=(5))) ∧ ((q.b=(0)) ∨ (q.b=(5))) ∧ (q.aLease=(0)) ∧ (q.bLease=(0))
def reuseNext (q : State) : State := {q with generation:=q.generation, revision:=(q.revision+(1)), opened:=(1)}
def Step (q r : State) : Prop := (chooseAdjacentGuard q ∧ r=chooseAdjacentNext q) ∨ (observeAGuard q ∧ r=observeANext q) ∨ (reserveAGuard q ∧ r=reserveANext q) ∨ (prepareAGuard q ∧ r=prepareANext q) ∨ (publishAGuard q ∧ r=publishANext q) ∨ (queryAGuard q ∧ r=queryANext q) ∨ (borrowAGuard q ∧ r=borrowANext q) ∨ (returnAGuard q ∧ r=returnANext q) ∨ (scanAGuard q ∧ r=scanANext q) ∨ (finishScanAGuard q ∧ r=finishScanANext q) ∨ (revokeAGuard q ∧ r=revokeANext q) ∨ (drainAGuard q ∧ r=drainANext q) ∨ (abortAGuard q ∧ r=abortANext q) ∨ (settleAGuard q ∧ r=settleANext q) ∨ (rejectOldAGuard q ∧ r=rejectOldANext q) ∨ (observeBGuard q ∧ r=observeBNext q) ∨ (reserveBGuard q ∧ r=reserveBNext q) ∨ (prepareBGuard q ∧ r=prepareBNext q) ∨ (publishBGuard q ∧ r=publishBNext q) ∨ (queryBGuard q ∧ r=queryBNext q) ∨ (borrowBGuard q ∧ r=borrowBNext q) ∨ (returnBGuard q ∧ r=returnBNext q) ∨ (scanBGuard q ∧ r=scanBNext q) ∨ (finishScanBGuard q ∧ r=finishScanBNext q) ∨ (revokeBGuard q ∧ r=revokeBNext q) ∨ (drainBGuard q ∧ r=drainBNext q) ∨ (abortBGuard q ∧ r=abortBNext q) ∨ (settleBGuard q ∧ r=settleBNext q) ∨ (rejectOldBGuard q ∧ r=rejectOldBNext q) ∨ (sourceWriteGuard q ∧ r=sourceWriteNext q) ∨ (closeIndexGuard q ∧ r=closeIndexNext q) ∨ (reuseGuard q ∧ r=reuseNext q) ∨ r=q
end StorageIndexAst
