import Std
namespace CacheReadyPublicationAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 owned : Int
 busy : Int
 owner : Int
 tls : Int
 fast : Int
 listed : Int
 ready : Int
 ack : Int
 builder : Int
 readerPin : Int
 diagPin : Int
 diagState : Int
 snapshot : Int
 statsOK : Int
 formatted : Int
 rollbackUnknown : Int
 pendingSeen : Int
 cleanupOK : Int
 generation : Int
 snapshotGen : Int
 allocations : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.stage≥(0)) ∧ (q.stage≤(10))) ∧ ((q.owned≥(0)) ∧ (q.owned≤(1))) ∧ ((q.busy≥(0)) ∧ (q.busy≤(1))) ∧ ((q.owner≥(0)) ∧ (q.owner≤(1))) ∧ ((q.tls≥(0)) ∧ (q.tls≤(2))) ∧ ((q.fast≥(0)) ∧ (q.fast≤(1))) ∧ ((q.listed≥(0)) ∧ (q.listed≤(1))) ∧ ((q.ready≥(0)) ∧ (q.ready≤(1))) ∧ ((q.ack≥(0)) ∧ (q.ack≤(3))) ∧ ((q.builder≥(0)) ∧ (q.builder≤(1))) ∧ ((q.readerPin≥(0)) ∧ (q.readerPin≤(1))) ∧ ((q.diagPin≥(0)) ∧ (q.diagPin≤(1))) ∧ ((q.diagState≥(0)) ∧ (q.diagState≤(5))) ∧ ((q.snapshot≥(0)) ∧ (q.snapshot≤(1))) ∧ ((q.statsOK≥(0)) ∧ (q.statsOK≤(1))) ∧ ((q.formatted≥(0)) ∧ (q.formatted≤(1))) ∧ ((q.rollbackUnknown≥(0)) ∧ (q.rollbackUnknown≤(1))) ∧ ((q.pendingSeen≥(0)) ∧ (q.pendingSeen≤(1))) ∧ ((q.cleanupOK≥(0)) ∧ (q.cleanupOK≤(1))) ∧ ((q.generation≥(0)) ∧ (q.generation≤(2))) ∧ ((q.snapshotGen≥(0)) ∧ (q.snapshotGen≤(1))) ∧ ((q.allocations≥(0)) ∧ (q.allocations≤(1))) ∧ (q.generation≥(1)) ∧ ((q.stage=(0)) → ((q.owned=(0)) ∧ (q.busy=(0)) ∧ (q.owner=(0)) ∧ (q.tls=(0)) ∧ (q.listed=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(0)) ∧ (q.allocations=(0)))) ∧ (((q.stage≥(1)) ∧ (q.stage≤(7))) → (q.busy=(1))) ∧ ((q.stage=(9)) → (q.busy=(1))) ∧ ((q.stage=(1)) → ((q.owned=(0)) ∧ (q.owner=(0)) ∧ (q.tls=(0)) ∧ (q.listed=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(0)) ∧ (q.allocations=(0)))) ∧ (((q.stage≥(2)) ∧ (q.stage≤(7))) → ((q.owned=(1)) ∧ (q.allocations=(1)))) ∧ ((q.stage=(2)) → ((q.owner=(0)) ∧ (q.tls=(0)) ∧ (q.listed=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(0)))) ∧ (((q.stage≥(3)) ∧ (q.stage≤(7))) → (q.owner=(1))) ∧ ((q.stage=(3)) → ((q.tls≠(1)) ∧ (q.listed=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(0)))) ∧ ((q.stage=(4)) → ((q.tls=(1)) ∧ (q.listed=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(0)))) ∧ ((q.stage=(5)) → ((q.tls=(1)) ∧ (q.listed=(1)) ∧ (q.ready=(0)) ∧ ((q.ack=(0)) ∨ (q.ack=(2))))) ∧ ((q.stage=(6)) → ((q.ready=(1)) ∧ (q.owned=(1)) ∧ (q.owner=(1)) ∧ (q.tls=(1)) ∧ (q.listed=(1)) ∧ ((q.ack=(1)) ∨ (q.ack=(2))))) ∧ ((q.ready=(1)) → (q.stage=(6))) ∧ ((q.stage=(7)) → ((q.ready=(0)) ∧ ((q.ack=(1)) ∨ (q.ack=(2))))) ∧ ((q.stage=(8)) → ((q.owned=(0)) ∧ (q.busy=(0)) ∧ (q.ready=(0)) ∧ (q.ack=(1)) ∧ (q.builder=(0)) ∧ (q.readerPin=(0)) ∧ (q.diagPin=(0)) ∧ (q.tls=(0)) ∧ (q.fast=(0)) ∧ (q.listed=(0)) ∧ (q.cleanupOK=(1)) ∧ (q.generation=(2)))) ∧ ((q.stage=(9)) → ((q.ready=(0)) ∧ (q.ack=(3)) ∧ (q.builder=(1)) ∧ (q.readerPin=(0)) ∧ (q.diagPin=(0)) ∧ (q.diagState=(0)) ∧ (q.fast=(0)))) ∧ ((q.stage=(10)) → ((q.owned=(0)) ∧ (q.busy=(0)) ∧ (q.ready=(0)) ∧ (q.builder=(0)) ∧ (q.readerPin=(0)) ∧ (q.diagPin=(0)) ∧ (q.tls=(0)) ∧ (q.fast=(0)) ∧ (q.listed=(0)) ∧ (q.ack=(3)))) ∧ ((q.stage≠(8)) → (q.generation=(1))) ∧ ((q.stage≤(5)) → ((q.builder=(1)) ∧ (q.readerPin=(0)) ∧ (q.diagPin=(0)) ∧ (q.diagState=(0)) ∧ (q.fast=(0)) ∧ (q.cleanupOK=(0)))) ∧ ((q.ack=(2)) → ((q.builder=(1)) ∧ (((q.stage=(5)) ∨ (q.stage=(6))) ∨ (q.stage=(7))))) ∧ ((q.tls=(2)) → ((q.stage=(3)) ∧ (q.owned=(1)) ∧ (q.builder=(1)) ∧ (q.ready=(0)))) ∧ ((q.readerPin=(1)) → (((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.owned=(1)) ∧ (q.tls=(1)))) ∧ ((q.diagPin=(1)) → (((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.owned=(1)) ∧ (q.tls=(1)) ∧ (q.diagState≥(1)) ∧ (q.diagState≤(3)))) ∧ (((q.diagState≥(1)) ∧ (q.diagState≤(3))) → (q.diagPin=(1))) ∧ ((q.diagState=(0)) → ((q.diagPin=(0)) ∧ (q.snapshot=(0)) ∧ (q.snapshotGen=(0)) ∧ (q.formatted=(0)))) ∧ (((q.diagState=(1)) ∨ (q.diagState=(2))) → ((q.snapshot=(0)) ∧ (q.snapshotGen=(0)) ∧ (q.formatted=(0)))) ∧ ((q.diagState≥(3)) → ((q.snapshot=(1)) ∧ (q.snapshotGen=(1)))) ∧ ((q.diagState≥(4)) → (q.diagPin=(0))) ∧ ((q.diagState=(5)) → (q.formatted=(1))) ∧ ((q.formatted=(1)) → ((q.diagState=(5)) ∧ (q.diagPin=(0)))) ∧ ((q.snapshot=(1)) → (q.diagState≥(3))) ∧ ((q.cleanupOK=(1)) → (((q.stage=(7)) ∨ (q.stage=(8))) ∧ (q.builder=(0)) ∧ (q.ack=(1)) ∧ (q.readerPin=(0)) ∧ (q.diagPin=(0)) ∧ (q.tls=(0)) ∧ (q.fast=(0)) ∧ (q.listed=(0)))) ∧ ((q.rollbackUnknown=(1)) → ((q.stage=(9)) ∧ (q.ready=(0)) ∧ (q.builder=(1)) ∧ (q.listed=(0)) ∧ (q.tls=(0)) ∧ (q.fast=(0)))) ∧ ((q.stage≤(5)) → (q.statsOK=(0))) ∧ (((q.stage=(9)) ∨ (q.stage=(10))) → (q.statsOK=(0))))
def initial : State := {stage:=(0), owned:=(0), busy:=(0), owner:=(0), tls:=(0), fast:=(0), listed:=(0), ready:=(0), ack:=(0), builder:=(1), readerPin:=(0), diagPin:=(0), diagState:=(0), snapshot:=(0), statsOK:=(0), formatted:=(0), rollbackUnknown:=(0), pendingSeen:=(0), cleanupOK:=(0), generation:=(1), snapshotGen:=(0), allocations:=(0)}
def reserveConstructionGuard (q : State) : Prop := (q.stage=(0))
def reserveConstructionNext (q : State) : State := {q with stage:=(1), busy:=(1)}
def allocateCandidateGuard (q : State) : Prop := ((q.stage=(1)) ∧ (q.allocations=(0)))
def allocateCandidateNext (q : State) : State := {q with stage:=(2), owned:=(1), allocations:=(1)}
def allocationRejectedGuard (q : State) : Prop := ((q.stage=(1)) ∧ (q.allocations=(0)))
def allocationRejectedNext (q : State) : State := {q with stage:=(9), ack:=(3)}
def initializeOwnerGuard (q : State) : Prop := (q.stage=(2))
def initializeOwnerNext (q : State) : State := {q with stage:=(3), owner:=(1)}
def installTlsKnownGuard (q : State) : Prop := ((q.stage=(3)) ∧ (q.tls=(0)))
def installTlsKnownNext (q : State) : State := {q with stage:=(4), tls:=(1)}
def installTlsUnknownGuard (q : State) : Prop := ((q.stage=(3)) ∧ (q.tls=(0)))
def installTlsUnknownNext (q : State) : State := {q with tls:=(2)}
def stageRegistryEntryGuard (q : State) : Prop := (q.stage=(4))
def stageRegistryEntryNext (q : State) : State := {q with stage:=(5), listed:=(1)}
def publishKnownGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.ack=(0)))
def publishKnownNext (q : State) : State := {q with stage:=(6), ready:=(1), ack:=(1)}
def publishUnknownCommittedGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.ack=(0)))
def publishUnknownCommittedNext (q : State) : State := {q with stage:=(6), ready:=(1), ack:=(2)}
def publishUnknownAbsentGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.ack=(0)))
def publishUnknownAbsentNext (q : State) : State := {q with ack:=(2)}
def rejectPublicationGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.ack=(0)))
def rejectPublicationNext (q : State) : State := {q with stage:=(9), ack:=(3)}
def reconcileCommittedGuard (q : State) : Prop := (((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.ack=(2)))
def reconcileCommittedNext (q : State) : State := {q with ack:=(1)}
def reconcileAbsentGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.ack=(2)))
def reconcileAbsentNext (q : State) : State := {q with stage:=(9), ack:=(3)}
def finishBuilderGuard (q : State) : Prop := ((((q.stage=(6)) ∨ (q.stage=(7))) ∧ (q.ack=(1))) ∧ (q.builder=(1)))
def finishBuilderNext (q : State) : State := {q with builder:=(0)}
def publishFastHandleGuard (q : State) : Prop := (((q.stage=(6)) ∧ (q.ready=(1))) ∧ (q.fast=(0)))
def publishFastHandleNext (q : State) : State := {q with fast:=(1)}
def constructionReentryGuard (q : State) : Prop := (((((q.stage≥(1)) ∧ (q.stage≤(5))) ∧ (q.busy=(1))) ∧ (q.ready=(0))) ∧ (q.pendingSeen=(0)))
def constructionReentryNext (q : State) : State := {q with pendingSeen:=(1)}
def closingReentryGuard (q : State) : Prop := (((q.stage=(7)) ∧ (q.ready=(0))) ∧ (q.pendingSeen=(0)))
def closingReentryNext (q : State) : State := {q with pendingSeen:=(1)}
def acquireReaderGuard (q : State) : Prop := (((q.stage=(6)) ∧ (q.ready=(1))) ∧ (q.readerPin=(0)))
def acquireReaderNext (q : State) : State := {q with readerPin:=(1)}
def releaseReaderGuard (q : State) : Prop := (q.readerPin=(1))
def releaseReaderNext (q : State) : State := {q with readerPin:=(0)}
def qualifyStatsGuard (q : State) : Prop := ((q.stage=(6)) ∧ (q.statsOK=(0)))
def qualifyStatsNext (q : State) : State := {q with statsOK:=(1)}
def beginDiagnosticGuard (q : State) : Prop := ((((q.stage=(6)) ∧ (q.ready=(1))) ∧ (q.statsOK=(1))) ∧ (q.diagState=(0)))
def beginDiagnosticNext (q : State) : State := {q with diagState:=(1), diagPin:=(1)}
def requestOwnerSnapshotGuard (q : State) : Prop := (q.diagState=(1))
def requestOwnerSnapshotNext (q : State) : State := {q with diagState:=(2)}
def ownerSnapshotAckGuard (q : State) : Prop := ((q.diagState=(2)) ∧ (q.statsOK=(1)))
def ownerSnapshotAckNext (q : State) : State := {q with diagState:=(3), snapshot:=(1), snapshotGen:=(1)}
def releaseDiagnosticPinGuard (q : State) : Prop := ((q.diagState=(3)) ∧ (q.snapshot=(1)))
def releaseDiagnosticPinNext (q : State) : State := {q with diagState:=(4), diagPin:=(0)}
def formatSnapshotGuard (q : State) : Prop := (((q.diagState=(4)) ∧ (q.snapshot=(1))) ∧ (q.formatted=(0)))
def formatSnapshotNext (q : State) : State := {q with diagState:=(5), formatted:=(1)}
def closeReadyGuard (q : State) : Prop := (q.stage=(6))
def closeReadyNext (q : State) : State := {q with stage:=(7), ready:=(0)}
def unlinkEntryGuard (q : State) : Prop := (((q.stage=(7)) ∨ (q.stage=(9))) ∧ (q.listed=(1)))
def unlinkEntryNext (q : State) : State := {q with listed:=(0)}
def clearTlsKnownGuard (q : State) : Prop := (((((q.stage=(7)) ∨ (q.stage=(9))) ∧ (q.tls=(1))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0)))
def clearTlsKnownNext (q : State) : State := {q with tls:=(0)}
def clearFastKnownGuard (q : State) : Prop := ((((q.stage=(7)) ∧ (q.fast=(1))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0)))
def clearFastKnownNext (q : State) : State := {q with fast:=(0)}
def attestNativeCleanupGuard (q : State) : Prop := ((((((((((q.stage=(7)) ∧ (q.builder=(0))) ∧ (q.ack=(1))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0))) ∧ (q.tls=(0))) ∧ (q.fast=(0))) ∧ (q.listed=(0))) ∧ (q.rollbackUnknown=(0))) ∧ (q.cleanupOK=(0)))
def attestNativeCleanupNext (q : State) : State := {q with cleanupOK:=(1)}
def retireKnownGuard (q : State) : Prop := ((((((((((q.stage=(7)) ∧ (q.builder=(0))) ∧ (q.ack=(1))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0))) ∧ (q.tls=(0))) ∧ (q.fast=(0))) ∧ (q.listed=(0))) ∧ (q.rollbackUnknown=(0))) ∧ (q.cleanupOK=(1)))
def retireKnownNext (q : State) : State := {q with stage:=(8), owned:=(0), busy:=(0), generation:=(2)}
def rollbackUnknownGuard (q : State) : Prop := ((((((((q.stage=(9)) ∧ (q.ack=(3))) ∧ (q.listed=(0))) ∧ (q.tls=(0))) ∧ (q.fast=(0))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0))) ∧ (q.rollbackUnknown=(0)))
def rollbackUnknownNext (q : State) : State := {q with rollbackUnknown:=(1)}
def rollbackKnownGuard (q : State) : Prop := ((((((((q.stage=(9)) ∧ (q.ack=(3))) ∧ (q.listed=(0))) ∧ (q.tls=(0))) ∧ (q.fast=(0))) ∧ (q.readerPin=(0))) ∧ (q.diagPin=(0))) ∧ (q.rollbackUnknown=(0)))
def rollbackKnownNext (q : State) : State := {q with stage:=(10), owned:=(0), busy:=(0), builder:=(0)}
def Step (q r : State) : Prop := (reserveConstructionGuard q ∧ r=reserveConstructionNext q) ∨ (allocateCandidateGuard q ∧ r=allocateCandidateNext q) ∨ (allocationRejectedGuard q ∧ r=allocationRejectedNext q) ∨ (initializeOwnerGuard q ∧ r=initializeOwnerNext q) ∨ (installTlsKnownGuard q ∧ r=installTlsKnownNext q) ∨ (installTlsUnknownGuard q ∧ r=installTlsUnknownNext q) ∨ (stageRegistryEntryGuard q ∧ r=stageRegistryEntryNext q) ∨ (publishKnownGuard q ∧ r=publishKnownNext q) ∨ (publishUnknownCommittedGuard q ∧ r=publishUnknownCommittedNext q) ∨ (publishUnknownAbsentGuard q ∧ r=publishUnknownAbsentNext q) ∨ (rejectPublicationGuard q ∧ r=rejectPublicationNext q) ∨ (reconcileCommittedGuard q ∧ r=reconcileCommittedNext q) ∨ (reconcileAbsentGuard q ∧ r=reconcileAbsentNext q) ∨ (finishBuilderGuard q ∧ r=finishBuilderNext q) ∨ (publishFastHandleGuard q ∧ r=publishFastHandleNext q) ∨ (constructionReentryGuard q ∧ r=constructionReentryNext q) ∨ (closingReentryGuard q ∧ r=closingReentryNext q) ∨ (acquireReaderGuard q ∧ r=acquireReaderNext q) ∨ (releaseReaderGuard q ∧ r=releaseReaderNext q) ∨ (qualifyStatsGuard q ∧ r=qualifyStatsNext q) ∨ (beginDiagnosticGuard q ∧ r=beginDiagnosticNext q) ∨ (requestOwnerSnapshotGuard q ∧ r=requestOwnerSnapshotNext q) ∨ (ownerSnapshotAckGuard q ∧ r=ownerSnapshotAckNext q) ∨ (releaseDiagnosticPinGuard q ∧ r=releaseDiagnosticPinNext q) ∨ (formatSnapshotGuard q ∧ r=formatSnapshotNext q) ∨ (closeReadyGuard q ∧ r=closeReadyNext q) ∨ (unlinkEntryGuard q ∧ r=unlinkEntryNext q) ∨ (clearTlsKnownGuard q ∧ r=clearTlsKnownNext q) ∨ (clearFastKnownGuard q ∧ r=clearFastKnownNext q) ∨ (attestNativeCleanupGuard q ∧ r=attestNativeCleanupNext q) ∨ (retireKnownGuard q ∧ r=retireKnownNext q) ∨ (rollbackUnknownGuard q ∧ r=rollbackUnknownNext q) ∨ (rollbackKnownGuard q ∧ r=rollbackKnownNext q) ∨ r=q
end CacheReadyPublicationAst
