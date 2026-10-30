import ThreadThunkFrozenRoots
namespace PendingStartComposition
structure PinFlat where
 phase : Int
 round : Int
 sourceA : Bool
 sourceB : Bool
 pendingA : Bool
 pendingB : Bool
 contextA : Bool
 contextB : Bool
 ackA : Bool
 ackB : Bool
 launchA : Bool
 launchB : Bool
 startA : Bool
 readyA : Bool
 memberA : Bool
 failedB : Bool
 doneB : Bool
 unknownB : Bool
 scanLease : Bool
 viewSourceA : Bool
 viewSourceB : Bool
 viewPendingA : Bool
 viewPendingB : Bool
 viewContextA : Bool
 viewContextB : Bool
 deriving DecidableEq
def qRegisterGuard (q : PinFlat) : Prop := q.phase=0 ∧ q.sourceA=true ∧ ¬q.pendingA=true ∧ ¬q.contextA=true
def qRegisterNext (q : PinFlat) := {q with pendingA:=true,ackA:=true}
def qAdoptGuard (q : PinFlat) : Prop := q.phase=0 ∧ q.pendingA=true ∧ ¬q.contextA=true ∧ q.launchA=true ∧ q.startA=true ∧ q.readyA=true ∧ q.memberA=true ∧ q.ackA=true
def qAdoptNext (q : PinFlat) := {q with pendingA:=false,contextA:=true}
def qRollbackGuard (q : PinFlat) : Prop := q.phase=0 ∧ q.failedB=true ∧ q.doneB=true ∧ ¬q.launchB=true ∧ ¬q.unknownB=true ∧ ¬q.contextB=true
def qRollbackNext (q : PinFlat) := {q with pendingB:=false,ackB:=false}
def rootProjection (q : PinFlat) := (q.phase,q.sourceA,q.pendingA || q.contextA)
theorem frozenBlocksRegistration (q : PinFlat) (h : q.phase≠0) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem notReadyRejectsAdoption (q : PinFlat) (h : q.readyA=false) : ¬qAdoptGuard q := by simp [qAdoptGuard,h]
theorem frozenBlocksAdoption (q : PinFlat) (h : q.phase≠0) : ¬qAdoptGuard q := by simp [qAdoptGuard,h]
theorem liveChildRejectsRollback (q : PinFlat) (h : q.launchB=true) : ¬qRollbackGuard q := by simp [qRollbackGuard,h]
theorem unknownRejectsRollback (q : PinFlat) (h : q.unknownB=true) : ¬qRollbackGuard q := by simp [qRollbackGuard,h]
theorem unsettledRejectsRollback (q : PinFlat) (h : q.doneB=false) : ¬qRollbackGuard q := by simp [qRollbackGuard,h]
theorem rollbackLeavesA (q : PinFlat) : ((qRollbackNext q).pendingA,(qRollbackNext q).contextA,(qRollbackNext q).launchA)=(q.pendingA,q.contextA,q.launchA) := rfl
theorem adoptionRootStutters (q : PinFlat) (h : qAdoptGuard q) : rootProjection (qAdoptNext q)=rootProjection q := by
 rcases h with ⟨_,p,c,_,_,_,_,_⟩
 have cf : q.contextA=false := by cases z:q.contextA <;> simp_all
 simp [rootProjection,qAdoptNext,p,cf]
structure StartupFlat where
 parent : Bool
 registered : Bool
 future : Bool
 launched : Bool
 started : Bool
 syncDone : Bool
 entered : Bool
 unknown : Bool
 aborted : Bool
 rawUsed : Bool
 epoch : Int
 slot : Int
 localStamp : Int
 deriving DecidableEq
def startupProjection (q : PinFlat) : StartupFlat := ⟨q.sourceA,q.pendingA || q.contextA,q.pendingA || q.contextA,q.launchA,q.startA,q.readyA,q.contextA,false,false,false,0,0,0⟩
def qEnterGuard (q : StartupFlat) : Prop := q.registered=true ∧ q.future=true ∧ q.syncDone=true ∧ ¬q.unknown=true
def qEnterNext (q : StartupFlat) := {q with entered:=true}
theorem adoptionImpliesStartupGuard (q : PinFlat) (h : qAdoptGuard q) : qEnterGuard (startupProjection q) := by
 rcases h with ⟨_,p,_,_,_,ready,_,_⟩
 simp [qEnterGuard,startupProjection,p,ready]
theorem adoptionStartupCommutes (q : PinFlat) (h : qAdoptGuard q) : startupProjection (qAdoptNext q)=qEnterNext (startupProjection q) := by
 rcases h with ⟨_,p,c,_,_,_,_,_⟩
 have cf : q.contextA=false := by cases z:q.contextA <;> simp_all
 simp [startupProjection,qAdoptNext,qEnterNext,p,cf]
theorem oldScanBeforeAdoption (scan restore adopt : Nat) (a : scan<restore) (b : restore<adopt) : scan<adopt := by omega
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := ThreadThunkFrozenRoots.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := ThreadThunkFrozenRoots.environmentExactDomain rows valid k d
end PendingStartComposition
