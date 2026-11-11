import Std
namespace RuntimeTlsReadyAst
set_option maxRecDepth 10000
structure State where
 g : Int
 locks : Int
 tables : Int
 genericKey : Int
 allocKey : Int
 initOwner : Int
 bootPin : Int
 cache : Int
 tls : Int
 fast : Int
 owner : Int
 usePin : Int
 finalizer : Int
 late : Int
 roster : Int
 observed : Int
 epoch : Int
 reentrySeen : Int
 rawSeen : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.g≥(0)) ∧ (q.g≤(4))) ∧ ((q.locks≥(0)) ∧ (q.locks≤(1))) ∧ ((q.tables≥(0)) ∧ (q.tables≤(1))) ∧ ((q.genericKey≥(0)) ∧ (q.genericKey≤(1))) ∧ ((q.allocKey≥(0)) ∧ (q.allocKey≤(2))) ∧ ((q.initOwner≥(0)) ∧ (q.initOwner≤(1))) ∧ ((q.bootPin≥(0)) ∧ (q.bootPin≤(1))) ∧ ((q.cache≥(0)) ∧ (q.cache≤(4))) ∧ ((q.tls≥(0)) ∧ (q.tls≤(2))) ∧ ((q.fast≥(0)) ∧ (q.fast≤(1))) ∧ ((q.owner≥(0)) ∧ (q.owner≤(1))) ∧ ((q.usePin≥(0)) ∧ (q.usePin≤(1))) ∧ ((q.finalizer≥(0)) ∧ (q.finalizer≤(1))) ∧ ((q.late≥(0)) ∧ (q.late≤(1))) ∧ ((q.roster≥(0)) ∧ (q.roster≤(1))) ∧ ((q.observed≥(0)) ∧ (q.observed≤(1))) ∧ ((q.epoch≥(0)) ∧ (q.epoch≤(2))) ∧ ((q.reentrySeen≥(0)) ∧ (q.reentrySeen≤(1))) ∧ ((q.rawSeen≥(0)) ∧ (q.rawSeen≤(1))) ∧ (q.epoch≥(1)) ∧ ((q.g=(0)) → ((q.locks=(0)) ∧ (q.tables=(0)) ∧ (q.genericKey=(0)) ∧ (q.allocKey=(0)) ∧ (q.initOwner=(0)) ∧ (q.cache=(0)) ∧ (q.observed=(0)))) ∧ ((q.g=(1)) → ((q.initOwner=(1)) ∧ (q.cache=(0)) ∧ (q.observed=(0)) ∧ (q.roster=(0)))) ∧ ((q.g=(2)) → ((q.locks=(1)) ∧ (q.tables=(1)) ∧ (q.genericKey=(1)) ∧ (q.allocKey=(1)) ∧ (q.initOwner=(0)) ∧ (q.roster=(0)))) ∧ ((q.g≥(2)) → (q.initOwner=(0))) ∧ ((q.g=(4)) → ((q.cache=(4)) ∧ (q.locks=(0)) ∧ (q.tables=(0)) ∧ (q.allocKey=(0)) ∧ (q.genericKey=(0)) ∧ (q.roster=(1)) ∧ (q.epoch=(2)))) ∧ ((q.g≠(4)) → (q.epoch=(1))) ∧ ((q.tables=(1)) → (q.locks=(1))) ∧ ((q.bootPin=(1)) → ((q.g=(1)) ∧ (q.locks=(1)))) ∧ ((q.cache=(0)) → ((q.tls=(0)) ∧ (q.fast=(0)) ∧ (q.owner=(0)) ∧ (q.usePin=(0)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)) ∧ (q.rawSeen=(0)))) ∧ ((q.cache≥(1)) → ((q.g≥(2)) ∧ (q.observed=(1)))) ∧ (((q.cache≥(1)) ∧ (q.cache≤(3))) → (q.owner=(1))) ∧ ((q.cache=(1)) → ((q.g=(2)) ∧ (q.fast=(0)) ∧ (q.usePin=(0)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)))) ∧ ((q.cache=(2)) → (((q.g=(2)) ∨ (q.g=(3))) ∧ (q.tls=(1)))) ∧ ((q.cache=(3)) → ((q.g=(3)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)))) ∧ ((q.cache=(4)) → ((q.g≥(3)) ∧ (q.tls=(0)) ∧ (q.fast=(0)) ∧ (q.owner=(0)) ∧ (q.usePin=(0)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)))) ∧ ((q.tls=(2)) → (((q.cache=(1)) ∨ (q.cache=(3))) ∧ (q.owner=(1)))) ∧ ((q.usePin=(1)) → (((q.cache=(2)) ∨ (q.cache=(3))) ∧ (q.owner=(1)) ∧ (q.tls=(1)))) ∧ ((q.finalizer=(1)) → ((q.cache=(2)) ∧ (q.owner=(1)))) ∧ ((q.late=(1)) → ((q.g=(3)) ∧ (q.cache=(2)) ∧ (q.finalizer=(1)))) ∧ ((q.roster=(1)) → ((q.g≥(3)) ∧ (q.cache=(4)) ∧ (q.owner=(0)) ∧ (q.usePin=(0)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)))) ∧ ((q.allocKey=(2)) → ((q.g=(1)) ∨ (q.g=(3)))) ∧ ((q.g≤(1)) → ((q.roster=(0)) ∧ (q.finalizer=(0)) ∧ (q.late=(0)))) ∧ ((q.observed=(1)) → (q.g≥(2))))
def initial : State := {g:=(0), locks:=(0), tables:=(0), genericKey:=(0), allocKey:=(0), initOwner:=(0), bootPin:=(0), cache:=(0), tls:=(0), fast:=(0), owner:=(0), usePin:=(0), finalizer:=(0), late:=(0), roster:=(0), observed:=(0), epoch:=(1), reentrySeen:=(0), rawSeen:=(0)}
def reserveRuntimeGuard (q : State) : Prop := (q.g=(0))
def reserveRuntimeNext (q : State) : State := {q with g:=(1), initOwner:=(1)}
def initializeLocksGuard (q : State) : Prop := ((q.g=(1)) ∧ (q.locks=(0)))
def initializeLocksNext (q : State) : State := {q with locks:=(1)}
def initializeTablesGuard (q : State) : Prop := (((q.g=(1)) ∧ (q.locks=(1))) ∧ (q.tables=(0)))
def initializeTablesNext (q : State) : State := {q with tables:=(1)}
def createGenericKeyGuard (q : State) : Prop := ((q.g=(1)) ∧ (q.genericKey=(0)))
def createGenericKeyNext (q : State) : State := {q with genericKey:=(1)}
def createAllocKeyKnownGuard (q : State) : Prop := ((q.g=(1)) ∧ (q.allocKey=(0)))
def createAllocKeyKnownNext (q : State) : State := {q with allocKey:=(1)}
def createAllocKeyUnknownGuard (q : State) : Prop := ((q.g=(1)) ∧ (q.allocKey=(0)))
def createAllocKeyUnknownNext (q : State) : State := {q with allocKey:=(2)}
def bootstrapBorrowGuard (q : State) : Prop := (((q.g=(1)) ∧ (q.locks=(1))) ∧ (q.bootPin=(0)))
def bootstrapBorrowNext (q : State) : State := {q with bootPin:=(1)}
def bootstrapReturnGuard (q : State) : Prop := (q.bootPin=(1))
def bootstrapReturnNext (q : State) : State := {q with bootPin:=(0)}
def initializationReentryGuard (q : State) : Prop := ((q.g=(1)) ∧ (q.reentrySeen=(0)))
def initializationReentryNext (q : State) : State := {q with reentrySeen:=(1)}
def publishRuntimeGuard (q : State) : Prop := ((((((q.g=(1)) ∧ (q.locks=(1))) ∧ (q.tables=(1))) ∧ (q.genericKey=(1))) ∧ (q.allocKey=(1))) ∧ (q.bootPin=(0)))
def publishRuntimeNext (q : State) : State := {q with g:=(2), initOwner:=(0)}
def observeRuntimeGuard (q : State) : Prop := ((q.g=(2)) ∧ (q.observed=(0)))
def observeRuntimeNext (q : State) : State := {q with observed:=(1)}
def beginCacheInstallGuard (q : State) : Prop := (((q.g=(2)) ∧ (q.observed=(1))) ∧ (q.cache=(0)))
def beginCacheInstallNext (q : State) : State := {q with cache:=(1), owner:=(1)}
def rawSetterReturnedGuard (q : State) : Prop := (((q.cache=(1)) ∧ (q.tls=(0))) ∧ (q.rawSeen=(0)))
def rawSetterReturnedNext (q : State) : State := {q with rawSeen:=(1)}
def recordKnownInstallGuard (q : State) : Prop := ((q.cache=(1)) ∧ (q.tls=(0)))
def recordKnownInstallNext (q : State) : State := {q with tls:=(1)}
def installUnknownGuard (q : State) : Prop := ((q.cache=(1)) ∧ (q.tls=(0)))
def installUnknownNext (q : State) : State := {q with tls:=(2)}
def publishCacheGuard (q : State) : Prop := (((q.g=(2)) ∧ (q.cache=(1))) ∧ (q.tls=(1)))
def publishCacheNext (q : State) : State := {q with cache:=(2)}
def publishFastGuard (q : State) : Prop := (((q.g=(2)) ∧ (q.cache=(2))) ∧ (q.fast=(0)))
def publishFastNext (q : State) : State := {q with fast:=(1)}
def acquireNormalGuard (q : State) : Prop := ((((q.g=(2)) ∧ (q.cache=(2))) ∧ (q.observed=(1))) ∧ (q.usePin=(0)))
def acquireNormalNext (q : State) : State := {q with usePin:=(1)}
def releaseNormalGuard (q : State) : Prop := (q.usePin=(1))
def releaseNormalNext (q : State) : State := {q with usePin:=(0)}
def admitFinalizerGuard (q : State) : Prop := (((q.g=(2)) ∧ (q.cache=(2))) ∧ (q.finalizer=(0)))
def admitFinalizerNext (q : State) : State := {q with finalizer:=(1)}
def beginGlobalCloseGuard (q : State) : Prop := (q.g=(2))
def beginGlobalCloseNext (q : State) : State := {q with g:=(3)}
def deriveLateTsdWorkGuard (q : State) : Prop := ((((q.g=(3)) ∧ (q.cache=(2))) ∧ (q.finalizer=(1))) ∧ (q.late=(0)))
def deriveLateTsdWorkNext (q : State) : State := {q with late:=(1)}
def drainLateTsdWorkGuard (q : State) : Prop := (((q.g=(3)) ∧ (q.finalizer=(1))) ∧ (q.late=(1)))
def drainLateTsdWorkNext (q : State) : State := {q with late:=(0)}
def finishFinalizerGuard (q : State) : Prop := (((q.g=(3)) ∧ (q.finalizer=(1))) ∧ (q.late=(0)))
def finishFinalizerNext (q : State) : State := {q with finalizer:=(0)}
def closeCacheGuard (q : State) : Prop := ((((q.g=(3)) ∧ (q.cache=(2))) ∧ (q.finalizer=(0))) ∧ (q.late=(0)))
def closeCacheNext (q : State) : State := {q with cache:=(3)}
def clearFastKnownGuard (q : State) : Prop := (((q.cache=(3)) ∧ (q.usePin=(0))) ∧ (q.fast=(1)))
def clearFastKnownNext (q : State) : State := {q with fast:=(0)}
def clearTlsKnownGuard (q : State) : Prop := (((q.cache=(3)) ∧ (q.usePin=(0))) ∧ (q.tls=(1)))
def clearTlsKnownNext (q : State) : State := {q with tls:=(0)}
def clearTlsUnknownGuard (q : State) : Prop := (((q.cache=(3)) ∧ (q.usePin=(0))) ∧ (q.tls=(1)))
def clearTlsUnknownNext (q : State) : State := {q with tls:=(2)}
def freeCacheKnownGuard (q : State) : Prop := (((((q.cache=(3)) ∧ (q.tls=(0))) ∧ (q.fast=(0))) ∧ (q.usePin=(0))) ∧ (q.owner=(1)))
def freeCacheKnownNext (q : State) : State := {q with cache:=(4), owner:=(0)}
def attestRosterClosedGuard (q : State) : Prop := (((((((q.g=(3)) ∧ (q.cache=(4))) ∧ (q.owner=(0))) ∧ (q.usePin=(0))) ∧ (q.finalizer=(0))) ∧ (q.late=(0))) ∧ (q.roster=(0)))
def attestRosterClosedNext (q : State) : State := {q with roster:=(1)}
def deleteGenericKeyGuard (q : State) : Prop := (((q.g=(3)) ∧ (q.roster=(1))) ∧ (q.genericKey=(1)))
def deleteGenericKeyNext (q : State) : State := {q with genericKey:=(0)}
def deleteAllocKeyKnownGuard (q : State) : Prop := (((q.g=(3)) ∧ (q.roster=(1))) ∧ (q.allocKey=(1)))
def deleteAllocKeyKnownNext (q : State) : State := {q with allocKey:=(0)}
def deleteAllocKeyUnknownGuard (q : State) : Prop := (((q.g=(3)) ∧ (q.roster=(1))) ∧ (q.allocKey=(1)))
def deleteAllocKeyUnknownNext (q : State) : State := {q with allocKey:=(2)}
def freeGlobalLocksGuard (q : State) : Prop := ((((((q.g=(3)) ∧ (q.roster=(1))) ∧ (q.genericKey=(0))) ∧ (q.allocKey=(0))) ∧ (q.cache=(4))) ∧ (q.bootPin=(0)))
def freeGlobalLocksNext (q : State) : State := {q with locks:=(0), tables:=(0)}
def retireRuntimeGuard (q : State) : Prop := (((((((q.g=(3)) ∧ (q.roster=(1))) ∧ (q.genericKey=(0))) ∧ (q.allocKey=(0))) ∧ (q.cache=(4))) ∧ (q.locks=(0))) ∧ (q.tables=(0)))
def retireRuntimeNext (q : State) : State := {q with g:=(4), epoch:=(2)}
def Step (q r : State) : Prop := (reserveRuntimeGuard q ∧ r=reserveRuntimeNext q) ∨ (initializeLocksGuard q ∧ r=initializeLocksNext q) ∨ (initializeTablesGuard q ∧ r=initializeTablesNext q) ∨ (createGenericKeyGuard q ∧ r=createGenericKeyNext q) ∨ (createAllocKeyKnownGuard q ∧ r=createAllocKeyKnownNext q) ∨ (createAllocKeyUnknownGuard q ∧ r=createAllocKeyUnknownNext q) ∨ (bootstrapBorrowGuard q ∧ r=bootstrapBorrowNext q) ∨ (bootstrapReturnGuard q ∧ r=bootstrapReturnNext q) ∨ (initializationReentryGuard q ∧ r=initializationReentryNext q) ∨ (publishRuntimeGuard q ∧ r=publishRuntimeNext q) ∨ (observeRuntimeGuard q ∧ r=observeRuntimeNext q) ∨ (beginCacheInstallGuard q ∧ r=beginCacheInstallNext q) ∨ (rawSetterReturnedGuard q ∧ r=rawSetterReturnedNext q) ∨ (recordKnownInstallGuard q ∧ r=recordKnownInstallNext q) ∨ (installUnknownGuard q ∧ r=installUnknownNext q) ∨ (publishCacheGuard q ∧ r=publishCacheNext q) ∨ (publishFastGuard q ∧ r=publishFastNext q) ∨ (acquireNormalGuard q ∧ r=acquireNormalNext q) ∨ (releaseNormalGuard q ∧ r=releaseNormalNext q) ∨ (admitFinalizerGuard q ∧ r=admitFinalizerNext q) ∨ (beginGlobalCloseGuard q ∧ r=beginGlobalCloseNext q) ∨ (deriveLateTsdWorkGuard q ∧ r=deriveLateTsdWorkNext q) ∨ (drainLateTsdWorkGuard q ∧ r=drainLateTsdWorkNext q) ∨ (finishFinalizerGuard q ∧ r=finishFinalizerNext q) ∨ (closeCacheGuard q ∧ r=closeCacheNext q) ∨ (clearFastKnownGuard q ∧ r=clearFastKnownNext q) ∨ (clearTlsKnownGuard q ∧ r=clearTlsKnownNext q) ∨ (clearTlsUnknownGuard q ∧ r=clearTlsUnknownNext q) ∨ (freeCacheKnownGuard q ∧ r=freeCacheKnownNext q) ∨ (attestRosterClosedGuard q ∧ r=attestRosterClosedNext q) ∨ (deleteGenericKeyGuard q ∧ r=deleteGenericKeyNext q) ∨ (deleteAllocKeyKnownGuard q ∧ r=deleteAllocKeyKnownNext q) ∨ (deleteAllocKeyUnknownGuard q ∧ r=deleteAllocKeyUnknownNext q) ∨ (freeGlobalLocksGuard q ∧ r=freeGlobalLocksNext q) ∨ (retireRuntimeGuard q ∧ r=retireRuntimeNext q) ∨ r=q
end RuntimeTlsReadyAst
