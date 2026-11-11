import Std
namespace SlotIssuanceAst
set_option maxRecDepth 10000
structure State where
 storage : Int
 generation : Int
 request : Int
 lo : Int
 hi : Int
 key : Int
 keyGeneration : Int
 savedGeneration : Int
 fresh : Int
 freshLo : Int
 freshHi : Int
 reg : Int
 mode : Int
 lease : Int
 boundGeneration : Int
 boundPayload : Int
 payload : Int
 copy : Int
 known : Int
 borrow : Int
 lookup : Int
 scan : Int
 gc : Int
 sourceBorrow : Int
 backing : Int
 rejected : Int
 queries : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.key≥(0)) ∧ (q.key≤(1)) ∧ (q.fresh≥(0)) ∧ (q.fresh≤(1)) ∧ (q.lease≥(0)) ∧ (q.lease≤(1)) ∧ (q.copy≥(0)) ∧ (q.copy≤(1)) ∧ (q.known≥(0)) ∧ (q.known≤(1)) ∧ (q.borrow≥(0)) ∧ (q.borrow≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.sourceBorrow≥(0)) ∧ (q.sourceBorrow≤(1)) ∧ (q.backing≥(0)) ∧ (q.backing≤(1)) ∧ (q.storage≥(1)) ∧ (q.storage≤(3)) ∧ (q.generation≥(1)) ∧ (q.generation≤(2)) ∧ (q.request≥(0)) ∧ (q.request≤(4)) ∧ (q.reg≥(0)) ∧ (q.reg≤(4)) ∧ (q.mode≥(0)) ∧ (q.mode≤(2)) ∧ (q.lookup≥(0)) ∧ (q.lookup≤(2)) ∧ (q.scan≥(0)) ∧ (q.scan≤(2)) ∧ (q.keyGeneration≥(0)) ∧ (q.keyGeneration≤(2)) ∧ (q.savedGeneration≥(0)) ∧ (q.savedGeneration≤(2)) ∧ (q.boundGeneration≥(0)) ∧ (q.boundGeneration≤(2)) ∧ (q.lo≥(0)) ∧ (q.hi≥q.lo) ∧ (q.freshLo≥(0)) ∧ (q.freshHi≥q.freshLo) ∧ (q.payload≥(0)) ∧ (q.boundPayload≥(0)) ∧ (q.boundPayload≤q.payload) ∧ (q.rejected≥(0)) ∧ (q.queries≥(0)) ∧ ((q.request=(1)) → ((q.lo=(2)) ∧ (q.hi=(4)))) ∧ ((q.request=(2)) → ((q.lo=(8)) ∧ (q.hi=(12)))) ∧ ((q.request=(3)) → ((q.lo=(6)) ∧ (q.hi=(10)))) ∧ ((q.request=(4)) → ((q.lo=(0)) ∧ (q.hi=(8)))) ∧ ((q.fresh=(1)) → ((q.freshLo≥(8)) ∨ (q.freshHi≤(0)))) ∧ ((q.key=(1)) → (q.keyGeneration≥(1))) ∧ ((q.savedGeneration>(0)) → (q.savedGeneration≤q.generation)) ∧ (q.keyGeneration≤q.generation) ∧ ((q.lease=(1)) → ((((q.storage=(1)) ∨ (q.storage=(2))) ∧ (q.boundGeneration=q.generation)) ∧ (q.boundPayload=q.payload))) ∧ (((q.mode=(1)) ∧ (((q.reg=(1)) ∨ (q.reg=(2))) ∨ (q.reg=(3)))) → (q.lease=(1))) ∧ (((q.mode=(2)) ∧ ((q.reg=(2)) ∨ (q.reg=(3)))) → (q.copy=(1))) ∧ ((((q.reg=(1)) ∨ (q.reg=(2))) ∨ (q.reg=(3))) → ((q.mode=(1)) ∨ (q.mode=(2)))) ∧ ((q.reg=(0)) → ((((q.mode=(0)) ∧ (q.lease=(0))) ∧ (q.copy=(0))) ∧ (q.known=(0)))) ∧ ((q.known=(1)) → (((q.reg=(2)) ∨ (q.reg=(3))) ∨ (q.reg=(4)))) ∧ ((((q.borrow=(1)) ∨ (q.lookup>(0))) ∨ (q.scan>(0))) → ((q.reg=(2)) ∨ (q.reg=(3)))) ∧ ((q.sourceBorrow=(1)) → ((q.storage=(1)) ∨ (q.storage=(2)))) ∧ ((q.storage=(3)) → ((q.lease=(0)) ∧ (q.sourceBorrow=(0)))) ∧ ((q.scan>(0)) → (q.gc=(1))) ∧ ((q.gc=(1)) → (q.scan>(0))) ∧ ((((q.mode=(2)) ∧ ((q.reg=(2)) ∨ (q.reg=(3)))) ∧ (q.known=(0))) → (q.lease=(1))))
def initial : State := {storage:=(1), generation:=(1), request:=(0), lo:=(0), hi:=(0), key:=(0), keyGeneration:=(0), savedGeneration:=(0), fresh:=(0), freshLo:=(0), freshHi:=(0), reg:=(0), mode:=(0), lease:=(0), boundGeneration:=(0), boundPayload:=(0), payload:=(0), copy:=(0), known:=(0), borrow:=(0), lookup:=(0), scan:=(0), gc:=(0), sourceBorrow:=(0), backing:=(0), rejected:=(0), queries:=(0)}
def probeSubviewGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(0))
def probeSubviewNext (q : State) : State := {q with request:=(1), lo:=(2), hi:=(4)}
def probeAdjacentGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(0))
def probeAdjacentNext (q : State) : State := {q with request:=(2), lo:=(8), hi:=(12)}
def probeOverlapGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(0))
def probeOverlapNext (q : State) : State := {q with request:=(3), lo:=(6), hi:=(10)}
def probeUnownedExactGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(0))
def probeUnownedExactNext (q : State) : State := {q with request:=(4), lo:=(0), hi:=(8)}
def issueSubviewGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(1)) ∧ (q.lo≥(0)) ∧ (q.hi≤(8))
def issueSubviewNext (q : State) : State := {q with request:=(0), key:=(1), keyGeneration:=q.generation}
def issueFreshGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(2)) ∧ (q.fresh=(0)) ∧ ((q.lo≥(8)) ∨ (q.hi≤(0)))
def issueFreshNext (q : State) : State := {q with request:=(0), fresh:=(1), freshLo:=q.lo, freshHi:=q.hi}
def rejectOverlapGuard (q : State) : Prop := (q.request=(3))
def rejectOverlapNext (q : State) : State := {q with request:=(0), rejected:=(q.rejected+(1))}
def rejectUnownedExactGuard (q : State) : Prop := (q.request=(4))
def rejectUnownedExactNext (q : State) : State := {q with request:=(0), rejected:=(q.rejected+(1))}
def saveKeyGuard (q : State) : Prop := (q.key=(1)) ∧ (q.savedGeneration=(0))
def saveKeyNext (q : State) : State := {q with savedGeneration:=q.keyGeneration}
def prepareAliasGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.key=(1)) ∧ (q.keyGeneration=q.generation) ∧ (q.reg=(0)) ∧ (q.gc=(0))
def prepareAliasNext (q : State) : State := {q with reg:=(1), mode:=(1), lease:=(1), boundGeneration:=q.generation, boundPayload:=q.payload}
def prepareCopyGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.key=(1)) ∧ (q.keyGeneration=q.generation) ∧ (q.reg=(0)) ∧ (q.gc=(0))
def prepareCopyNext (q : State) : State := {q with reg:=(1), mode:=(2), lease:=(1), boundGeneration:=q.generation, boundPayload:=q.payload}
def materializeCopyGuard (q : State) : Prop := (q.reg=(1)) ∧ (q.mode=(2)) ∧ (q.lease=(1)) ∧ (q.gc=(0))
def materializeCopyNext (q : State) : State := {q with copy:=(1)}
def publishAliasGuard (q : State) : Prop := (q.reg=(1)) ∧ (q.mode=(1)) ∧ (q.lease=(1)) ∧ (q.gc=(0))
def publishAliasNext (q : State) : State := {q with reg:=(2)}
def publishCopyGuard (q : State) : Prop := (q.reg=(1)) ∧ (q.mode=(2)) ∧ (q.copy=(1)) ∧ (q.lease=(1)) ∧ (q.gc=(0))
def publishCopyNext (q : State) : State := {q with reg:=(2)}
def queryCommitGuard (q : State) : Prop := ((q.reg=(2)) ∨ (q.reg=(3)))
def queryCommitNext (q : State) : State := {q with known:=(1), queries:=(q.queries+(1))}
def releaseCopyLeaseGuard (q : State) : Prop := (q.mode=(2)) ∧ ((q.reg=(2)) ∨ (q.reg=(3))) ∧ (q.copy=(1)) ∧ True ∧ (q.gc=(0))
def releaseCopyLeaseNext (q : State) : State := {q with lease:=(0)}
def beginLookupGuard (q : State) : Prop := (q.reg=(2)) ∧ (q.lookup=(0)) ∧ (q.borrow=(0))
def beginLookupNext (q : State) : State := {q with lookup:=(1)}
def acceptBorrowGuard (q : State) : Prop := (q.reg=(2)) ∧ (q.lookup=(1)) ∧ (q.borrow=(0))
def acceptBorrowNext (q : State) : State := {q with lookup:=(0), borrow:=(1)}
def lookupUnknownGuard (q : State) : Prop := (q.lookup=(1))
def lookupUnknownNext (q : State) : State := {q with lookup:=(2)}
def resolveLookupGuard (q : State) : Prop := (q.lookup=(2))
def resolveLookupNext (q : State) : State := {q with lookup:=(1)}
def rejectLookupGuard (q : State) : Prop := (q.lookup=(1)) ∧ (q.reg=(3))
def rejectLookupNext (q : State) : State := {q with lookup:=(0)}
def returnBorrowGuard (q : State) : Prop := (q.borrow=(1))
def returnBorrowNext (q : State) : State := {q with borrow:=(0)}
def closeRegistryGuard (q : State) : Prop := (q.reg=(2))
def closeRegistryNext (q : State) : State := {q with reg:=(3)}
def beginScanGuard (q : State) : Prop := ((q.reg=(2)) ∨ (q.reg=(3))) ∧ (q.gc=(0))
def beginScanNext (q : State) : State := {q with scan:=(1), gc:=(1)}
def finishScanGuard (q : State) : Prop := (q.scan=(1))
def finishScanNext (q : State) : State := {q with scan:=(0), gc:=(0)}
def scanUnknownGuard (q : State) : Prop := (q.scan=(1))
def scanUnknownNext (q : State) : State := {q with scan:=(2)}
def resolveScanGuard (q : State) : Prop := (q.scan=(2))
def resolveScanNext (q : State) : State := {q with scan:=(0), gc:=(0)}
def retireRegistryGuard (q : State) : Prop := (q.reg=(3)) ∧ (q.known=(1)) ∧ ((q.mode=(1)) ∨ (q.lease=(0))) ∧ (q.lookup=(0)) ∧ (q.borrow=(0)) ∧ (q.scan=(0)) ∧ (q.gc=(0))
def retireRegistryNext (q : State) : State := {q with reg:=(4)}
def releaseRetiredAliasLeaseGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.reg=(4)) ∧ (q.lookup=(0)) ∧ (q.borrow=(0)) ∧ (q.scan=(0)) ∧ (q.gc=(0))
def releaseRetiredAliasLeaseNext (q : State) : State := {q with lease:=(0)}
def abortCandidateGuard (q : State) : Prop := (q.reg=(1)) ∧ (q.gc=(0))
def abortCandidateNext (q : State) : State := {q with reg:=(4), lease:=(0)}
def sourceWriteGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.lease=(0)) ∧ (q.gc=(0))
def sourceWriteNext (q : State) : State := {q with payload:=(q.payload+(1))}
def sourceBorrowBeginGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.sourceBorrow=(0))
def sourceBorrowBeginNext (q : State) : State := {q with sourceBorrow:=(1)}
def sourceBorrowReturnGuard (q : State) : Prop := (q.sourceBorrow=(1))
def sourceBorrowReturnNext (q : State) : State := {q with sourceBorrow:=(0)}
def closeStorageGuard (q : State) : Prop := (q.storage=(1)) ∧ (q.request=(0))
def closeStorageNext (q : State) : State := {q with storage:=(2)}
def settleBackingGuard (q : State) : Prop := (q.storage=(2)) ∧ (q.gc=(0))
def settleBackingNext (q : State) : State := {q with backing:=(1)}
def reclaimStorageGuard (q : State) : Prop := (q.storage=(2)) ∧ (q.lease=(0)) ∧ (q.sourceBorrow=(0)) ∧ (q.backing=(1)) ∧ (q.gc=(0))
def reclaimStorageNext (q : State) : State := {q with storage:=(3)}
def reuseStorageGuard (q : State) : Prop := (q.storage=(3)) ∧ (q.generation<(2)) ∧ (q.lease=(0)) ∧ (q.sourceBorrow=(0)) ∧ (q.gc=(0))
def reuseStorageNext (q : State) : State := {q with storage:=(1), generation:=(q.generation+(1)), payload:=(q.payload+(1)), backing:=(0)}
def rejectStaleKeyGuard (q : State) : Prop := (q.savedGeneration>(0)) ∧ (q.savedGeneration≠q.generation)
def rejectStaleKeyNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def Step (q r : State) : Prop := (probeSubviewGuard q ∧ r=probeSubviewNext q) ∨ (probeAdjacentGuard q ∧ r=probeAdjacentNext q) ∨ (probeOverlapGuard q ∧ r=probeOverlapNext q) ∨ (probeUnownedExactGuard q ∧ r=probeUnownedExactNext q) ∨ (issueSubviewGuard q ∧ r=issueSubviewNext q) ∨ (issueFreshGuard q ∧ r=issueFreshNext q) ∨ (rejectOverlapGuard q ∧ r=rejectOverlapNext q) ∨ (rejectUnownedExactGuard q ∧ r=rejectUnownedExactNext q) ∨ (saveKeyGuard q ∧ r=saveKeyNext q) ∨ (prepareAliasGuard q ∧ r=prepareAliasNext q) ∨ (prepareCopyGuard q ∧ r=prepareCopyNext q) ∨ (materializeCopyGuard q ∧ r=materializeCopyNext q) ∨ (publishAliasGuard q ∧ r=publishAliasNext q) ∨ (publishCopyGuard q ∧ r=publishCopyNext q) ∨ (queryCommitGuard q ∧ r=queryCommitNext q) ∨ (releaseCopyLeaseGuard q ∧ r=releaseCopyLeaseNext q) ∨ (beginLookupGuard q ∧ r=beginLookupNext q) ∨ (acceptBorrowGuard q ∧ r=acceptBorrowNext q) ∨ (lookupUnknownGuard q ∧ r=lookupUnknownNext q) ∨ (resolveLookupGuard q ∧ r=resolveLookupNext q) ∨ (rejectLookupGuard q ∧ r=rejectLookupNext q) ∨ (returnBorrowGuard q ∧ r=returnBorrowNext q) ∨ (closeRegistryGuard q ∧ r=closeRegistryNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (finishScanGuard q ∧ r=finishScanNext q) ∨ (scanUnknownGuard q ∧ r=scanUnknownNext q) ∨ (resolveScanGuard q ∧ r=resolveScanNext q) ∨ (retireRegistryGuard q ∧ r=retireRegistryNext q) ∨ (releaseRetiredAliasLeaseGuard q ∧ r=releaseRetiredAliasLeaseNext q) ∨ (abortCandidateGuard q ∧ r=abortCandidateNext q) ∨ (sourceWriteGuard q ∧ r=sourceWriteNext q) ∨ (sourceBorrowBeginGuard q ∧ r=sourceBorrowBeginNext q) ∨ (sourceBorrowReturnGuard q ∧ r=sourceBorrowReturnNext q) ∨ (closeStorageGuard q ∧ r=closeStorageNext q) ∨ (settleBackingGuard q ∧ r=settleBackingNext q) ∨ (reclaimStorageGuard q ∧ r=reclaimStorageNext q) ∨ (reuseStorageGuard q ∧ r=reuseStorageNext q) ∨ (rejectStaleKeyGuard q ∧ r=rejectStaleKeyNext q) ∨ r=q
end SlotIssuanceAst
