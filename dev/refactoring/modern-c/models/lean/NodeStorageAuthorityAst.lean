import Std
namespace NodeStorageAuthorityAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 ownerReady : Int
 listVisible : Int
 layout : Int
 mapReady : Int
 coverage : Int
 aliasSeen : Int
 gate : Int
 metaLease : Int
 payloadLease : Int
 tailAuth : Int
 nodeRole : Int
 unknown : Int
 receipt : Int
 cacheLive : Int
 cacheGen : Int
 nodeAllocGen : Int
 queryGen : Int
 cleanupReady : Int
 opaqueSeen : Int
 currentSeen : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.stage≥(0)) ∧ (q.stage≤(10))) ∧ ((q.ownerReady≥(0)) ∧ (q.ownerReady≤(1))) ∧ ((q.listVisible≥(0)) ∧ (q.listVisible≤(1))) ∧ ((q.layout≥(0)) ∧ (q.layout≤(1))) ∧ ((q.mapReady≥(0)) ∧ (q.mapReady≤(1))) ∧ ((q.coverage≥(0)) ∧ (q.coverage≤(1))) ∧ ((q.aliasSeen≥(0)) ∧ (q.aliasSeen≤(1))) ∧ ((q.gate≥(0)) ∧ (q.gate≤(1))) ∧ ((q.metaLease≥(0)) ∧ (q.metaLease≤(1))) ∧ ((q.payloadLease≥(0)) ∧ (q.payloadLease≤(1))) ∧ ((q.tailAuth≥(0)) ∧ (q.tailAuth≤(1))) ∧ ((q.nodeRole≥(0)) ∧ (q.nodeRole≤(2))) ∧ ((q.unknown≥(0)) ∧ (q.unknown≤(1))) ∧ ((q.receipt≥(0)) ∧ (q.receipt≤(1))) ∧ ((q.cacheLive≥(0)) ∧ (q.cacheLive≤(1))) ∧ ((q.cacheGen≥(0)) ∧ (q.cacheGen≤(2))) ∧ ((q.nodeAllocGen≥(0)) ∧ (q.nodeAllocGen≤(1))) ∧ ((q.queryGen≥(0)) ∧ (q.queryGen≤(1))) ∧ ((q.cleanupReady≥(0)) ∧ (q.cleanupReady≤(1))) ∧ ((q.opaqueSeen≥(0)) ∧ (q.opaqueSeen≤(1))) ∧ ((q.currentSeen≥(0)) ∧ (q.currentSeen≤(1))) ∧ (q.nodeAllocGen=(1)) ∧ (q.queryGen=(1)) ∧ (q.cacheGen≥(1)) ∧ ((q.stage=(0)) → (q.listVisible=(0))) ∧ ((q.stage≥(1)) → (q.listVisible=(1))) ∧ ((q.stage≤(1)) → (q.ownerReady=(0))) ∧ ((q.stage≥(2)) → (q.ownerReady=(1))) ∧ ((q.stage≤(2)) → ((q.mapReady=(0)) ∧ (q.gate=(0)) ∧ (q.metaLease=(0)) ∧ (q.payloadLease=(0)) ∧ (q.coverage=(0)) ∧ (q.aliasSeen=(0)))) ∧ ((q.stage≥(3)) → ((q.mapReady=(1)) ∧ (q.layout=(1)) ∧ (q.ownerReady=(1)))) ∧ ((q.stage=(3)) → (q.coverage=(0))) ∧ ((q.stage=(4)) → ((q.coverage=(1)) ∧ (q.aliasSeen=(0)))) ∧ (((q.stage≥(5)) ∧ (q.stage≤(9))) → ((q.coverage=(1)) ∧ (q.aliasSeen=(0)))) ∧ ((q.stage≤(4)) → ((q.tailAuth=(1)) ∧ (q.nodeRole=(0)) ∧ (q.unknown=(0)) ∧ (q.receipt=(0)))) ∧ (((q.stage≥(5)) ∧ (q.stage≤(9))) → ((q.tailAuth=(0)) ∧ (q.nodeRole≥(1)))) ∧ ((q.stage=(10)) → ((q.aliasSeen=(1)) ∧ (q.coverage=(0)) ∧ (q.gate=(0)) ∧ (q.cacheLive=(1)) ∧ (q.receipt=(0)) ∧ (q.tailAuth=(1)) ∧ (q.nodeRole=(0)) ∧ (q.unknown=(0)) ∧ (q.payloadLease=(0)))) ∧ ((q.unknown=(1)) → ((q.stage=(5)) ∧ (q.receipt=(0)) ∧ (q.cacheLive=(1)) ∧ (q.cleanupReady=(0)) ∧ (q.cacheGen=(1)) ∧ (q.gate=(1)))) ∧ (((q.stage=(5)) ∨ (q.stage=(6))) → (q.receipt=(0))) ∧ (((q.stage≥(7)) ∧ (q.stage≤(9))) → (q.receipt=(1))) ∧ (((q.stage≥(3)) ∧ (q.stage≤(7))) → (q.gate=(1))) ∧ ((q.stage≥(8)) → (q.gate=(0))) ∧ ((q.stage=(9)) → ((q.cacheLive=(0)) ∧ (q.cacheGen=(2)) ∧ (q.metaLease=(0)) ∧ (q.payloadLease=(0)) ∧ (q.cleanupReady=(1)))) ∧ ((q.stage≠(9)) → ((q.cacheLive=(1)) ∧ (q.cacheGen=(1)))) ∧ ((q.cleanupReady=(1)) → (((q.stage=(8)) ∨ (q.stage=(9))) ∧ (q.metaLease=(0)) ∧ (q.payloadLease=(0)))) ∧ ((q.payloadLease=(1)) → ((q.stage=(4)) ∧ (q.tailAuth=(1)))))
def initial : State := {stage:=(0), ownerReady:=(0), listVisible:=(0), layout:=(0), mapReady:=(0), coverage:=(0), aliasSeen:=(0), gate:=(0), metaLease:=(0), payloadLease:=(0), tailAuth:=(1), nodeRole:=(0), unknown:=(0), receipt:=(0), cacheLive:=(1), cacheGen:=(1), nodeAllocGen:=(1), queryGen:=(1), cleanupReady:=(0), opaqueSeen:=(0), currentSeen:=(0)}
def publishRawListGuard (q : State) : Prop := (q.stage=(0))
def publishRawListNext (q : State) : State := {q with stage:=(1), listVisible:=(1)}
def initializeOwnerGuard (q : State) : Prop := (q.stage=(1))
def initializeOwnerNext (q : State) : State := {q with stage:=(2), ownerReady:=(1)}
def attestDisjointGuard (q : State) : Prop := ((q.stage=(2)) ∧ (q.layout=(0)))
def attestDisjointNext (q : State) : State := {q with layout:=(1)}
def bindNodeMapGuard (q : State) : Prop := (((q.stage=(2)) ∧ (q.ownerReady=(1))) ∧ (q.layout=(1)))
def bindNodeMapNext (q : State) : State := {q with stage:=(3), mapReady:=(1), gate:=(1)}
def sealReaderClosureGuard (q : State) : Prop := ((q.stage=(3)) ∧ (q.aliasSeen=(0)))
def sealReaderClosureNext (q : State) : State := {q with stage:=(4), coverage:=(1)}
def exposeAliasGuard (q : State) : Prop := ((q.stage=(3)) ∧ (q.aliasSeen=(0)))
def exposeAliasNext (q : State) : State := {q with aliasSeen:=(1)}
def revokeSealGuard (q : State) : Prop := ((q.stage=(4)) ∧ (q.payloadLease=(0)))
def revokeSealNext (q : State) : State := {q with stage:=(3), coverage:=(0), aliasSeen:=(1)}
def rejectAliasGuard (q : State) : Prop := (((q.stage=(3)) ∧ (q.aliasSeen=(1))) ∧ (q.payloadLease=(0)))
def rejectAliasNext (q : State) : State := {q with stage:=(10), gate:=(0)}
def acquireMetadataGuard (q : State) : Prop := (((q.mapReady=(1)) ∧ (q.gate=(1))) ∧ (q.metaLease=(0)))
def acquireMetadataNext (q : State) : State := {q with metaLease:=(1)}
def returnMetadataGuard (q : State) : Prop := (q.metaLease=(1))
def returnMetadataNext (q : State) : State := {q with metaLease:=(0)}
def acquirePayloadGuard (q : State) : Prop := ((((q.stage=(4)) ∧ (q.coverage=(1))) ∧ (q.tailAuth=(1))) ∧ (q.payloadLease=(0)))
def acquirePayloadNext (q : State) : State := {q with payloadLease:=(1)}
def returnPayloadGuard (q : State) : Prop := (q.payloadLease=(1))
def returnPayloadNext (q : State) : State := {q with payloadLease:=(0)}
def knownHandoffGuard (q : State) : Prop := (((q.stage=(4)) ∧ (q.coverage=(1))) ∧ (q.payloadLease=(0)))
def knownHandoffNext (q : State) : State := {q with stage:=(5), tailAuth:=(0), nodeRole:=(1)}
def unknownHandoffGuard (q : State) : Prop := (((q.stage=(4)) ∧ (q.coverage=(1))) ∧ (q.payloadLease=(0)))
def unknownHandoffNext (q : State) : State := {q with stage:=(5), tailAuth:=(0), nodeRole:=(1), unknown:=(1)}
def consumerAllocateGuard (q : State) : Prop := (((q.stage≥(5)) ∧ (q.stage≤(9))) ∧ (q.nodeRole=(1)))
def consumerAllocateNext (q : State) : State := {q with nodeRole:=(2)}
def fixSourceLastGuard (q : State) : Prop := ((q.stage=(5)) ∧ (q.unknown=(0)))
def fixSourceLastNext (q : State) : State := {q with stage:=(6)}
def publishCompletionGuard (q : State) : Prop := (q.stage=(6))
def publishCompletionNext (q : State) : State := {q with stage:=(7), receipt:=(1)}
def closeAdmissionGuard (q : State) : Prop := (q.stage=(7))
def closeAdmissionNext (q : State) : State := {q with stage:=(8), gate:=(0)}
def attestCleanupGuard (q : State) : Prop := ((((q.stage=(8)) ∧ (q.metaLease=(0))) ∧ (q.payloadLease=(0))) ∧ (q.cleanupReady=(0)))
def attestCleanupNext (q : State) : State := {q with cleanupReady:=(1)}
def retireCacheGuard (q : State) : Prop := ((((q.stage=(8)) ∧ (q.cleanupReady=(1))) ∧ (q.metaLease=(0))) ∧ (q.payloadLease=(0)))
def retireCacheNext (q : State) : State := {q with stage:=(9), cacheLive:=(0), cacheGen:=(2)}
def lookupOpaqueGuard (q : State) : Prop := ((q.mapReady=(1)) ∧ (q.opaqueSeen=(0)))
def lookupOpaqueNext (q : State) : State := {q with opaqueSeen:=(1)}
def probeCurrentCacheGuard (q : State) : Prop := ((((((((q.mapReady=(1)) ∧ (q.metaLease=(1))) ∧ (q.gate=(1))) ∧ (q.cacheLive=(1))) ∧ (q.cacheGen=q.queryGen)) ∧ (q.coverage=(1))) ∧ (q.aliasSeen=(0))) ∧ (q.currentSeen=(0)))
def probeCurrentCacheNext (q : State) : State := {q with currentSeen:=(1)}
def Step (q r : State) : Prop := (publishRawListGuard q ∧ r=publishRawListNext q) ∨ (initializeOwnerGuard q ∧ r=initializeOwnerNext q) ∨ (attestDisjointGuard q ∧ r=attestDisjointNext q) ∨ (bindNodeMapGuard q ∧ r=bindNodeMapNext q) ∨ (sealReaderClosureGuard q ∧ r=sealReaderClosureNext q) ∨ (exposeAliasGuard q ∧ r=exposeAliasNext q) ∨ (revokeSealGuard q ∧ r=revokeSealNext q) ∨ (rejectAliasGuard q ∧ r=rejectAliasNext q) ∨ (acquireMetadataGuard q ∧ r=acquireMetadataNext q) ∨ (returnMetadataGuard q ∧ r=returnMetadataNext q) ∨ (acquirePayloadGuard q ∧ r=acquirePayloadNext q) ∨ (returnPayloadGuard q ∧ r=returnPayloadNext q) ∨ (knownHandoffGuard q ∧ r=knownHandoffNext q) ∨ (unknownHandoffGuard q ∧ r=unknownHandoffNext q) ∨ (consumerAllocateGuard q ∧ r=consumerAllocateNext q) ∨ (fixSourceLastGuard q ∧ r=fixSourceLastNext q) ∨ (publishCompletionGuard q ∧ r=publishCompletionNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (attestCleanupGuard q ∧ r=attestCleanupNext q) ∨ (retireCacheGuard q ∧ r=retireCacheNext q) ∨ (lookupOpaqueGuard q ∧ r=lookupOpaqueNext q) ∨ (probeCurrentCacheGuard q ∧ r=probeCurrentCacheNext q) ∨ r=q
end NodeStorageAuthorityAst
