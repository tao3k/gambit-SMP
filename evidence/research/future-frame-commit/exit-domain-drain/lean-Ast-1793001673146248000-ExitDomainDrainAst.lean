import Std
namespace ExitDomainDrainAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 a : Int
 b : Int
 ack : Int
 parent : Int
 samePair : Int
 tailLive : Int
 tailDone : Int
 public : Int
 keyGate : Int
 lookupPin : Int
 data : Int
 slot : Int
 cache : Int
 joined : Int
 miss : Int
 deps : Int
 cacheDone : Int
 allOwners : Int
 key : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.phase≥(0)) ∧ (q.phase≤(6))) ∧ ((q.a≥(0)) ∧ (q.a≤(8))) ∧ ((q.b≥(0)) ∧ (q.b≤(8))) ∧ ((q.ack≥(0)) ∧ (q.ack≤(2))) ∧ ((q.parent≥(0)) ∧ (q.parent≤(2))) ∧ ((q.samePair≥(0)) ∧ (q.samePair≤(1))) ∧ ((q.tailLive≥(0)) ∧ (q.tailLive≤(1))) ∧ ((q.tailDone≥(0)) ∧ (q.tailDone≤(1))) ∧ ((q.public≥(0)) ∧ (q.public≤(1))) ∧ ((q.keyGate≥(0)) ∧ (q.keyGate≤(1))) ∧ ((q.lookupPin≥(0)) ∧ (q.lookupPin≤(1))) ∧ ((q.data≥(0)) ∧ (q.data≤(1))) ∧ ((q.slot≥(0)) ∧ (q.slot≤(1))) ∧ ((q.cache≥(0)) ∧ (q.cache≤(1))) ∧ ((q.joined≥(0)) ∧ (q.joined≤(1))) ∧ ((q.miss≥(0)) ∧ (q.miss≤(1))) ∧ ((q.deps≥(0)) ∧ (q.deps≤(1))) ∧ ((q.cacheDone≥(0)) ∧ (q.cacheDone≤(1))) ∧ ((q.allOwners≥(0)) ∧ (q.allOwners≤(1))) ∧ ((q.key≥(0)) ∧ (q.key≤(1))) ∧ ((q.phase=(0)) → ((q.public=(1)) ∧ (q.keyGate=(1)) ∧ (q.tailLive=(0)) ∧ (q.tailDone=(0)))) ∧ ((q.phase≥(1)) → (q.public=(0))) ∧ ((q.phase≤(1)) → ((q.keyGate=(1)) ∧ (q.slot=q.data) ∧ (q.deps=(0)))) ∧ ((q.phase≥(2)) → ((q.keyGate=(0)) ∧ ((q.a=(0)) ∨ (q.a=(5))) ∧ ((q.b=(0)) ∨ (q.b=(5))) ∧ (q.ack≠(2)) ∧ (q.tailLive=(0)) ∧ (q.tailDone=(1)))) ∧ ((q.phase≥(3)) → ((q.slot=(0)) ∧ (q.lookupPin=(0)) ∧ (q.deps=(1)))) ∧ ((q.phase≥(4)) → (q.data=(0))) ∧ ((q.phase≤(5)) → (q.key=(1))) ∧ ((q.phase=(6)) → ((q.key=(0)) ∧ (q.cacheDone=(1)) ∧ (q.allOwners=(1)) ∧ (q.cache=(0)))) ∧ ((q.lookupPin=(1)) → ((q.phase≤(2)) ∧ (q.key=(1)))) ∧ ((q.data=(1)) → (q.cache=(1))) ∧ ((((q.a≥(1)) ∧ (q.a≤(8))) ∧ (q.phase≤(1))) → (q.data=(1))) ∧ ((((q.b≥(1)) ∧ (q.b≤(8))) ∧ (q.phase≤(1))) → (q.data=(1))) ∧ ((q.b=(0)) → ((q.ack=(0)) ∧ (q.parent=(0)))) ∧ ((q.b=(1)) → ((q.ack≠(1)) ∧ (q.data=(1)))) ∧ ((q.b≥(2)) → ((q.parent≥(0)) ∧ ((q.ack=(1)) ∨ (q.ack=(2))))) ∧ (((q.a≥(3)) ∧ (q.a≤(4))) → (q.phase=(1))) ∧ (((q.b≥(3)) ∧ (q.b≤(4))) → (q.phase=(1))) ∧ ((((q.a=(6)) ∨ (q.a=(7))) ∨ (q.a=(8))) → (q.phase≤(1))) ∧ ((((q.b=(6)) ∨ (q.b=(7))) ∨ (q.b=(8))) → (q.phase≤(1))) ∧ ((q.tailLive=(1)) → ((q.phase=(1)) ∧ (q.tailDone=(0)))) ∧ ((q.tailDone=(1)) → (q.tailLive=(0))) ∧ ((q.cacheDone=(1)) → ((q.phase≥(5)) ∧ (q.data=(0)) ∧ (q.slot=(0)) ∧ (q.lookupPin=(0)) ∧ (q.cache=(0)))) ∧ ((q.allOwners=(1)) → ((q.phase≥(5)) ∧ (q.cacheDone=(1)))) ∧ ((q.phase≤(4)) → ((q.cacheDone=(0)) ∧ (q.allOwners=(0)))) ∧ ((q.cache=(0)) → (q.data=(0))))
def initial : State := {phase:=(0), a:=(0), b:=(0), ack:=(0), parent:=(0), samePair:=(0), tailLive:=(0), tailDone:=(0), public:=(1), keyGate:=(1), lookupPin:=(0), data:=(0), slot:=(0), cache:=(0), joined:=(0), miss:=(0), deps:=(0), cacheDone:=(0), allOwners:=(0), key:=(1)}
def seedRegistrationAGuard (q : State) : Prop := ((q.phase=(0)) ∧ (q.a=(0)))
def seedRegistrationANext (q : State) : State := {q with a:=(2), data:=(1), slot:=(1), cache:=(1)}
def chooseDuplicatePairGuard (q : State) : Prop := (((q.phase=(0)) ∧ (q.b=(0))) ∧ (q.samePair=(0)))
def chooseDuplicatePairNext (q : State) : State := {q with samePair:=(1)}
def reserveExternalBGuard (q : State) : Prop := (((q.phase=(0)) ∧ (q.a=(2))) ∧ (q.b=(0)))
def reserveExternalBNext (q : State) : State := {q with b:=(1), parent:=(0)}
def beginDrainGuard (q : State) : Prop := (q.phase=(0))
def beginDrainNext (q : State) : State := {q with phase:=(1), public:=(0)}
def reserveChildBGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.a=(3))) ∧ (q.b=(0)))
def reserveChildBNext (q : State) : State := {q with b:=(1), parent:=(1)}
def reserveTailBGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.tailLive=(1))) ∧ (q.b=(0)))
def reserveTailBNext (q : State) : State := {q with b:=(1), parent:=(2), data:=(1), slot:=(1), cache:=(1)}
def publishBKnownGuard (q : State) : Prop := ((q.b=(1)) ∧ (q.ack=(0)))
def publishBKnownNext (q : State) : State := {q with b:=(2), ack:=(1)}
def publishBUnknownGuard (q : State) : Prop := ((q.b=(1)) ∧ (q.ack=(0)))
def publishBUnknownNext (q : State) : State := {q with b:=(2), ack:=(2)}
def publicationAbsentUnknownGuard (q : State) : Prop := ((q.b=(1)) ∧ (q.ack=(0)))
def publicationAbsentUnknownNext (q : State) : State := {q with ack:=(2)}
def reconcileAcceptedBGuard (q : State) : Prop := ((q.b≥(2)) ∧ (q.ack=(2)))
def reconcileAcceptedBNext (q : State) : State := {q with ack:=(1)}
def reconcileAbsentAndRolledBackBGuard (q : State) : Prop := ((q.b=(1)) ∧ (q.ack=(2)))
def reconcileAbsentAndRolledBackBNext (q : State) : State := {q with b:=(0), ack:=(0), parent:=(0)}
def popAGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.a=(2))) ∧ (q.b≠(2)))
def popANext (q : State) : State := {q with a:=(3)}
def popBGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.b=(2)))
def popBNext (q : State) : State := {q with b:=(3)}
def returnAGuard (q : State) : Prop := (q.a=(3))
def returnANext (q : State) : State := {q with a:=(4)}
def returnBGuard (q : State) : Prop := (q.b=(3))
def returnBNext (q : State) : State := {q with b:=(4)}
def callbackUnknownAGuard (q : State) : Prop := (q.a=(3))
def callbackUnknownANext (q : State) : State := {q with a:=(8)}
def freeNodeAKnownGuard (q : State) : Prop := ((q.a=(4)) ∨ (q.a=(6)))
def freeNodeAKnownNext (q : State) : State := {q with a:=(5)}
def freeNodeBKnownGuard (q : State) : Prop := ((q.b=(4)) ∨ (q.b=(6)))
def freeNodeBKnownNext (q : State) : State := {q with b:=(5)}
def freeNodeAUnknownGuard (q : State) : Prop := ((q.a=(4)) ∨ (q.a=(6)))
def freeNodeAUnknownNext (q : State) : State := {q with a:=(7)}
def freeNodeBUnknownGuard (q : State) : Prop := ((q.b=(4)) ∨ (q.b=(6)))
def freeNodeBUnknownNext (q : State) : State := {q with b:=(7)}
def cancelNewestDuplicateBGuard (q : State) : Prop := ((q.b=(2)) ∧ (q.samePair=(1)))
def cancelNewestDuplicateBNext (q : State) : State := {q with b:=(6)}
def cancelQueuedAGuard (q : State) : Prop := ((q.a=(2)) ∧ (¬((q.b=(2)) ∧ (q.samePair=(1)))))
def cancelQueuedANext (q : State) : State := {q with a:=(6)}
def reentrantFinalizeJoinGuard (q : State) : Prop := (((q.phase=(1)) ∧ ((q.a=(3)) ∨ (q.b=(3)))) ∧ (q.joined=(0)))
def reentrantFinalizeJoinNext (q : State) : State := {q with joined:=(1)}
def beginSubsystemTailGuard (q : State) : Prop := ((((((q.phase=(1)) ∧ ((q.a=(0)) ∨ (q.a=(5)))) ∧ ((q.b=(0)) ∨ (q.b=(5)))) ∧ (q.ack≠(2))) ∧ (q.tailLive=(0))) ∧ (q.tailDone=(0)))
def beginSubsystemTailNext (q : State) : State := {q with tailLive:=(1)}
def finishSubsystemTailGuard (q : State) : Prop := ((((q.phase=(1)) ∧ (q.tailLive=(1))) ∧ (q.b≠(1))) ∧ (q.ack≠(2)))
def finishSubsystemTailNext (q : State) : State := {q with tailLive:=(0), tailDone:=(1)}
def closeProducersGuard (q : State) : Prop := ((((((q.phase=(1)) ∧ ((q.a=(0)) ∨ (q.a=(5)))) ∧ ((q.b=(0)) ∨ (q.b=(5)))) ∧ (q.ack≠(2))) ∧ (q.tailLive=(0))) ∧ (q.tailDone=(1)))
def closeProducersNext (q : State) : State := {q with phase:=(2), keyGate:=(0)}
def attestNoTsdDependenciesGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.deps=(0)))
def attestNoTsdDependenciesNext (q : State) : State := {q with deps:=(1)}
def acquireLookupGuard (q : State) : Prop := (((q.key=(1)) ∧ (q.keyGate=(1))) ∧ (q.lookupPin=(0)))
def acquireLookupNext (q : State) : State := {q with lookupPin:=(1)}
def lookupAbsentGuard (q : State) : Prop := (((q.lookupPin=(1)) ∧ (q.data=(0))) ∧ (q.miss=(0)))
def lookupAbsentNext (q : State) : State := {q with miss:=(1)}
def releaseLookupGuard (q : State) : Prop := (q.lookupPin=(1))
def releaseLookupNext (q : State) : State := {q with lookupPin:=(0)}
def detachTableSlotGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.lookupPin=(0))) ∧ (q.deps=(1)))
def detachTableSlotNext (q : State) : State := {q with phase:=(3), slot:=(0)}
def freeTsdDataGuard (q : State) : Prop := ((((q.phase=(3)) ∧ (q.slot=(0))) ∧ (q.lookupPin=(0))) ∧ (q.deps=(1)))
def freeTsdDataNext (q : State) : State := {q with phase:=(4), data:=(0)}
def issueDataDrainReceiptGuard (q : State) : Prop := (q.phase=(4))
def issueDataDrainReceiptNext (q : State) : State := {q with phase:=(5)}
def cancelAbsentFromReceiptGuard (q : State) : Prop := (((q.phase≥(3)) ∧ (q.slot=(0))) ∧ (q.miss=(0)))
def cancelAbsentFromReceiptNext (q : State) : State := {q with miss:=(1)}
def attestCacheAndOwnerRosterGuard (q : State) : Prop := ((q.phase=(5)) ∧ (q.lookupPin=(0)))
def attestCacheAndOwnerRosterNext (q : State) : State := {q with cacheDone:=(1), allOwners:=(1), cache:=(0)}
def deleteGenericKeyGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.cacheDone=(1))) ∧ (q.allOwners=(1))) ∧ (q.lookupPin=(0))) ∧ (q.key=(1)))
def deleteGenericKeyNext (q : State) : State := {q with phase:=(6), key:=(0)}
def Step (q r : State) : Prop := (seedRegistrationAGuard q ∧ r=seedRegistrationANext q) ∨ (chooseDuplicatePairGuard q ∧ r=chooseDuplicatePairNext q) ∨ (reserveExternalBGuard q ∧ r=reserveExternalBNext q) ∨ (beginDrainGuard q ∧ r=beginDrainNext q) ∨ (reserveChildBGuard q ∧ r=reserveChildBNext q) ∨ (reserveTailBGuard q ∧ r=reserveTailBNext q) ∨ (publishBKnownGuard q ∧ r=publishBKnownNext q) ∨ (publishBUnknownGuard q ∧ r=publishBUnknownNext q) ∨ (publicationAbsentUnknownGuard q ∧ r=publicationAbsentUnknownNext q) ∨ (reconcileAcceptedBGuard q ∧ r=reconcileAcceptedBNext q) ∨ (reconcileAbsentAndRolledBackBGuard q ∧ r=reconcileAbsentAndRolledBackBNext q) ∨ (popAGuard q ∧ r=popANext q) ∨ (popBGuard q ∧ r=popBNext q) ∨ (returnAGuard q ∧ r=returnANext q) ∨ (returnBGuard q ∧ r=returnBNext q) ∨ (callbackUnknownAGuard q ∧ r=callbackUnknownANext q) ∨ (freeNodeAKnownGuard q ∧ r=freeNodeAKnownNext q) ∨ (freeNodeBKnownGuard q ∧ r=freeNodeBKnownNext q) ∨ (freeNodeAUnknownGuard q ∧ r=freeNodeAUnknownNext q) ∨ (freeNodeBUnknownGuard q ∧ r=freeNodeBUnknownNext q) ∨ (cancelNewestDuplicateBGuard q ∧ r=cancelNewestDuplicateBNext q) ∨ (cancelQueuedAGuard q ∧ r=cancelQueuedANext q) ∨ (reentrantFinalizeJoinGuard q ∧ r=reentrantFinalizeJoinNext q) ∨ (beginSubsystemTailGuard q ∧ r=beginSubsystemTailNext q) ∨ (finishSubsystemTailGuard q ∧ r=finishSubsystemTailNext q) ∨ (closeProducersGuard q ∧ r=closeProducersNext q) ∨ (attestNoTsdDependenciesGuard q ∧ r=attestNoTsdDependenciesNext q) ∨ (acquireLookupGuard q ∧ r=acquireLookupNext q) ∨ (lookupAbsentGuard q ∧ r=lookupAbsentNext q) ∨ (releaseLookupGuard q ∧ r=releaseLookupNext q) ∨ (detachTableSlotGuard q ∧ r=detachTableSlotNext q) ∨ (freeTsdDataGuard q ∧ r=freeTsdDataNext q) ∨ (issueDataDrainReceiptGuard q ∧ r=issueDataDrainReceiptNext q) ∨ (cancelAbsentFromReceiptGuard q ∧ r=cancelAbsentFromReceiptNext q) ∨ (attestCacheAndOwnerRosterGuard q ∧ r=attestCacheAndOwnerRosterNext q) ∨ (deleteGenericKeyGuard q ∧ r=deleteGenericKeyNext q) ∨ r=q
end ExitDomainDrainAst
