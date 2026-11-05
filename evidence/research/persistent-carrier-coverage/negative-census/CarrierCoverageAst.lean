import Std
namespace CarrierCoverageAst
set_option maxRecDepth 10000
structure State where
 d0 : Int
 d1 : Int
 mem0 : Int
 mem1 : Int
 initialized1 : Int
 known1 : Int
 sourcePin : Int
 use1 : Int
 observe1 : Int
 managed : Int
 rawUnknown : Int
 backing1 : Int
 payload0 : Int
 payload1 : Int
 round : Int
 gc : Int
 snap0 : Int
 snap1 : Int
 read0 : Int
 read1 : Int
 done0 : Int
 done1 : Int
 updated0 : Int
 updated1 : Int
 processors : Int
 queries : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.d0≥(0)) ∧ (q.d0≤(4)) ∧ (q.d1≥(0)) ∧ (q.d1≤(4)) ∧ (q.mem0≥(0)) ∧ (q.mem0≤(1)) ∧ (q.mem1≥(0)) ∧ (q.mem1≤(1)) ∧ (q.initialized1≥(0)) ∧ (q.initialized1≤(1)) ∧ (q.known1≥(0)) ∧ (q.known1≤(1)) ∧ (q.sourcePin≥(0)) ∧ (q.sourcePin≤(1)) ∧ (q.use1≥(0)) ∧ (q.use1≤(1)) ∧ (q.observe1≥(0)) ∧ (q.observe1≤(1)) ∧ (q.managed≥(0)) ∧ (q.managed≤(1)) ∧ (q.rawUnknown≥(0)) ∧ (q.rawUnknown≤(1)) ∧ (q.backing1≥(0)) ∧ (q.backing1≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.snap0≥(0)) ∧ (q.snap0≤(1)) ∧ (q.snap1≥(0)) ∧ (q.snap1≤(1)) ∧ (q.read0≥(0)) ∧ (q.read0≤(2)) ∧ (q.read1≥(0)) ∧ (q.read1≤(2)) ∧ (q.done0≥(0)) ∧ (q.done0≤(1)) ∧ (q.done1≥(0)) ∧ (q.done1≤(1)) ∧ (q.payload0≥(0)) ∧ (q.payload1≥(0)) ∧ (q.round≥(0)) ∧ (q.queries≥(0)) ∧ ((q.processors=(1)) ∨ (q.processors=(2))) ∧ (q.updated0≥(-(1))) ∧ (q.updated1≥(-(1))) ∧ (q.updated0≤q.round) ∧ (q.updated1≤q.round) ∧ ((((q.d0=(1)) ∨ (q.d0=(2))) ∨ (q.d0=(3))) → (q.mem0=(1))) ∧ ((q.d0=(4)) → (q.mem0=(0))) ∧ (((q.gc=(1)) ∧ ((q.d0=(2)) ∨ (q.d0=(3)))) → (q.snap0=(1))) ∧ (((q.gc=(1)) ∧ (q.snap0=(1))) → (((q.d0=(2)) ∨ (q.d0=(3))) ∧ (q.mem0=(1)))) ∧ ((q.read0>(0)) → (((q.gc=(1)) ∧ (q.snap0=(1))) ∧ (q.done0=(0)))) ∧ ((((q.gc=(1)) ∧ (q.snap0=(1))) ∧ (q.done0=(1))) → (q.updated0=q.round)) ∧ ((((q.d1=(1)) ∨ (q.d1=(2))) ∨ (q.d1=(3))) → (q.mem1=(1))) ∧ ((q.d1=(4)) → (q.mem1=(0))) ∧ (((q.gc=(1)) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))) → (q.snap1=(1))) ∧ (((q.gc=(1)) ∧ (q.snap1=(1))) → (((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.mem1=(1)))) ∧ ((q.read1>(0)) → (((q.gc=(1)) ∧ (q.snap1=(1))) ∧ (q.done1=(0)))) ∧ ((((q.gc=(1)) ∧ (q.snap1=(1))) ∧ (q.done1=(1))) → (q.updated1=q.round)) ∧ ((q.use1=(1)) → (((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.mem1=(1)))) ∧ ((q.observe1=(1)) → (((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.mem1=(1)))) ∧ ((q.sourcePin=(1)) → ((q.mem0=(1)) ∧ ((q.d0=(2)) ∨ (q.d0=(3))))) ∧ ((q.d1=(0)) → ((((q.mem1=(0)) ∧ (q.initialized1=(0))) ∧ (q.known1=(0))) ∧ (q.sourcePin=(0)))) ∧ (((q.d1=(2)) ∨ (q.d1=(3))) → (q.initialized1=(1))) ∧ ((q.d1=(1)) → (q.sourcePin=(1))) ∧ ((q.known1=(1)) → (((q.d1=(2)) ∨ (q.d1=(3))) ∨ (q.d1=(4)))) ∧ (q.payload1≤q.payload0) ∧ ((q.gc=(0)) → ((((q.read0=(0)) ∧ (q.read1=(0))) ∧ (q.snap0=(0))) ∧ (q.snap1=(0)))) ∧ ((q.rawUnknown=(1)) → (q.managed=(0))))
def initial : State := {d0:=(2), d1:=(0), mem0:=(1), mem1:=(0), initialized1:=(0), known1:=(0), sourcePin:=(0), use1:=(0), observe1:=(0), managed:=(0), rawUnknown:=(0), backing1:=(0), payload0:=(0), payload1:=(0), round:=(0), gc:=(0), snap0:=(0), snap1:=(0), read0:=(0), read1:=(0), done0:=(0), done1:=(0), updated0:=(-(1)), updated1:=(-(1)), processors:=(2), queries:=(0)}
def admitManagedWritersGuard (q : State) : Prop := (q.managed=(0)) ∧ (q.rawUnknown=(0)) ∧ (q.d0=(2))
def admitManagedWritersNext (q : State) : State := {q with managed:=(1)}
def reserveCarrierGuard (q : State) : Prop := (q.d1=(0)) ∧ (q.d0=(2)) ∧ (q.managed=(1)) ∧ (q.rawUnknown=(0)) ∧ (q.gc=(0))
def reserveCarrierNext (q : State) : State := {q with d1:=(1), mem1:=(1), sourcePin:=(1)}
def initializeCarrierGuard (q : State) : Prop := (q.d1=(1)) ∧ (q.sourcePin=(1)) ∧ (q.gc=(0))
def initializeCarrierNext (q : State) : State := {q with initialized1:=(1), payload1:=q.payload0}
def publishCarrierGuard (q : State) : Prop := (q.d1=(1)) ∧ (q.initialized1=(1)) ∧ (q.gc=(0))
def publishCarrierNext (q : State) : State := {q with d1:=(2)}
def queryPublicationGuard (q : State) : Prop := ((q.d1=(2)) ∨ (q.d1=(3)))
def queryPublicationNext (q : State) : State := {q with known1:=(1), queries:=(q.queries+(1))}
def returnSourcePinGuard (q : State) : Prop := (q.sourcePin=(1)) ∧ (q.known1=(1)) ∧ ((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.rawUnknown=(0)) ∧ (q.gc=(0))
def returnSourcePinNext (q : State) : State := {q with sourcePin:=(0)}
def borrowPayloadGuard (q : State) : Prop := (q.d1=(2)) ∧ (q.known1=(1)) ∧ (q.managed=(1)) ∧ (q.rawUnknown=(0))
def borrowPayloadNext (q : State) : State := {q with use1:=(1)}
def returnPayloadGuard (q : State) : Prop := (q.use1=(1))
def returnPayloadNext (q : State) : State := {q with use1:=(0)}
def observeReceiptGuard (q : State) : Prop := (q.d1=(2)) ∧ (q.known1=(1)) ∧ (q.rawUnknown=(0))
def observeReceiptNext (q : State) : State := {q with observe1:=(1)}
def releaseObserverGuard (q : State) : Prop := (q.observe1=(1))
def releaseObserverNext (q : State) : State := {q with observe1:=(0)}
def revokeCarrierGuard (q : State) : Prop := (q.d1=(2))
def revokeCarrierNext (q : State) : State := {q with d1:=(3)}
def closeSourceGuard (q : State) : Prop := (q.d0=(2))
def closeSourceNext (q : State) : State := {q with d0:=(3)}
def managedSetterGuard (q : State) : Prop := (q.d0=(2)) ∧ (q.managed=(1)) ∧ (q.rawUnknown=(0)) ∧ (q.sourcePin=(0)) ∧ (q.gc=(0))
def managedSetterNext (q : State) : State := {q with payload0:=(q.payload0+(1))}
def recordRawInterferenceGuard (q : State) : Prop := ((q.d0=(2)) ∨ (q.d0=(3)))
def recordRawInterferenceNext (q : State) : State := {q with rawUnknown:=(1), managed:=(0)}
def storageHandoffGuard (q : State) : Prop := ((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.known1=(1)) ∧ (q.gc=(0))
def storageHandoffNext (q : State) : State := {q with backing1:=(1)}
def cleanupSourceGuard (q : State) : Prop := (q.d0=(3)) ∧ (q.sourcePin=(0)) ∧ (q.known1=(1)) ∧ ((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.backing1=(1)) ∧ (q.rawUnknown=(0)) ∧ (q.gc=(0))
def cleanupSourceNext (q : State) : State := {q with d0:=(4), mem0:=(0)}
def retireCarrierGuard (q : State) : Prop := (q.d1=(3)) ∧ (q.use1=(0)) ∧ (q.observe1=(0)) ∧ (q.sourcePin=(0)) ∧ (q.known1=(1)) ∧ (q.rawUnknown=(0)) ∧ (q.gc=(0))
def retireCarrierNext (q : State) : State := {q with d1:=(4), mem1:=(0)}
def shrinkProcessorsGuard (q : State) : Prop := (q.processors=(2)) ∧ (q.gc=(0))
def shrinkProcessorsNext (q : State) : State := {q with processors:=(1)}
def freezeBothGuard (q : State) : Prop := (q.gc=(0)) ∧ ((q.d1≠(1)) ∨ (q.initialized1=(0))) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freezeBothNext (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), snap0:=(1), snap1:=(1), done0:=(0), done1:=(0)}
def freezeSourceGuard (q : State) : Prop := (q.gc=(0)) ∧ ((q.d1≠(1)) ∨ (q.initialized1=(0))) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1≠(2)) ∧ (q.d1≠(3)))
def freezeSourceNext (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), snap0:=(1), snap1:=(0), done0:=(0), done1:=(1)}
def freezeCarrierGuard (q : State) : Prop := (q.gc=(0)) ∧ ((q.d1≠(1)) ∨ (q.initialized1=(0))) ∧ ((q.d0≠(2)) ∧ (q.d0≠(3))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freezeCarrierNext (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), snap0:=(0), snap1:=(0), done0:=(1), done1:=(0)}
def freezeNeitherGuard (q : State) : Prop := (q.gc=(0)) ∧ ((q.d1≠(1)) ∨ (q.initialized1=(0))) ∧ ((q.d0≠(2)) ∧ (q.d0≠(3))) ∧ ((q.d1≠(2)) ∧ (q.d1≠(3)))
def freezeNeitherNext (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), snap0:=(0), snap1:=(0), done0:=(1), done1:=(1)}
def claim0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.snap0=(1)) ∧ (q.done0=(0)) ∧ (q.read0=(0))
def claim0Next (q : State) : State := {q with read0:=(1)}
def scanDone0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read0=(1))
def scanDone0Next (q : State) : State := {q with read0:=(0), done0:=(1), updated0:=q.round}
def scanUnknown0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read0=(1))
def scanUnknown0Next (q : State) : State := {q with read0:=(2)}
def resolveScan0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read0=(2))
def resolveScan0Next (q : State) : State := {q with read0:=(0), done0:=(1), updated0:=q.round}
def claim1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.snap1=(1)) ∧ (q.done1=(0)) ∧ (q.read1=(0))
def claim1Next (q : State) : State := {q with read1:=(1)}
def scanDone1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read1=(1))
def scanDone1Next (q : State) : State := {q with read1:=(0), done1:=(1), updated1:=q.round}
def scanUnknown1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read1=(1))
def scanUnknown1Next (q : State) : State := {q with read1:=(2)}
def resolveScan1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.read1=(2))
def resolveScan1Next (q : State) : State := {q with read1:=(0), done1:=(1), updated1:=q.round}
def finishRoundGuard (q : State) : Prop := (q.gc=(1)) ∧ (q.done0=(1)) ∧ (q.done1=(1)) ∧ (q.read0=(0)) ∧ (q.read1=(0))
def finishRoundNext (q : State) : State := {q with gc:=(0), snap0:=(0), snap1:=(0)}
def Step (q r : State) : Prop := (admitManagedWritersGuard q ∧ r=admitManagedWritersNext q) ∨ (reserveCarrierGuard q ∧ r=reserveCarrierNext q) ∨ (initializeCarrierGuard q ∧ r=initializeCarrierNext q) ∨ (publishCarrierGuard q ∧ r=publishCarrierNext q) ∨ (queryPublicationGuard q ∧ r=queryPublicationNext q) ∨ (returnSourcePinGuard q ∧ r=returnSourcePinNext q) ∨ (borrowPayloadGuard q ∧ r=borrowPayloadNext q) ∨ (returnPayloadGuard q ∧ r=returnPayloadNext q) ∨ (observeReceiptGuard q ∧ r=observeReceiptNext q) ∨ (releaseObserverGuard q ∧ r=releaseObserverNext q) ∨ (revokeCarrierGuard q ∧ r=revokeCarrierNext q) ∨ (closeSourceGuard q ∧ r=closeSourceNext q) ∨ (managedSetterGuard q ∧ r=managedSetterNext q) ∨ (recordRawInterferenceGuard q ∧ r=recordRawInterferenceNext q) ∨ (storageHandoffGuard q ∧ r=storageHandoffNext q) ∨ (cleanupSourceGuard q ∧ r=cleanupSourceNext q) ∨ (retireCarrierGuard q ∧ r=retireCarrierNext q) ∨ (shrinkProcessorsGuard q ∧ r=shrinkProcessorsNext q) ∨ (freezeBothGuard q ∧ r=freezeBothNext q) ∨ (freezeSourceGuard q ∧ r=freezeSourceNext q) ∨ (freezeCarrierGuard q ∧ r=freezeCarrierNext q) ∨ (freezeNeitherGuard q ∧ r=freezeNeitherNext q) ∨ (claim0Guard q ∧ r=claim0Next q) ∨ (scanDone0Guard q ∧ r=scanDone0Next q) ∨ (scanUnknown0Guard q ∧ r=scanUnknown0Next q) ∨ (resolveScan0Guard q ∧ r=resolveScan0Next q) ∨ (claim1Guard q ∧ r=claim1Next q) ∨ (scanDone1Guard q ∧ r=scanDone1Next q) ∨ (scanUnknown1Guard q ∧ r=scanUnknown1Next q) ∨ (resolveScan1Guard q ∧ r=resolveScan1Next q) ∨ (finishRoundGuard q ∧ r=finishRoundNext q) ∨ r=q
end CarrierCoverageAst
