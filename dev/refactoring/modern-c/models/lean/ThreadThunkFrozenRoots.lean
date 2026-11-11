import IngressCarrierTransfer
namespace ThreadThunkFrozenRoots
structure PinFlat where
 phase : Int
 round : Int
 epoch : Int
 source : Bool
 staged : Bool
 target : Bool
 future : Bool
 receipt : Bool
 unknown : Bool
 sourceView : Bool
 targetView : Bool
 scanBorrow : Bool
 done : Bool
 sourceStamp : Int
 targetStamp : Int
 deriving DecidableEq
def qRegisterGuard (q : PinFlat) : Prop := q.phase=0 ∧ q.source=true ∧ q.staged=true ∧ ¬q.target=true
def qRegisterNext (q : PinFlat) := {q with target:=true,future:=true,receipt:=true,targetStamp:=q.sourceStamp}
def qRestoreGuard (q : PinFlat) : Prop := q.phase=2 ∧ ¬q.scanBorrow=true
def qRestoreNext (q : PinFlat) := {q with phase:=0,sourceView:=false,targetView:=false}
def qReleaseGuard (q : PinFlat) : Prop := q.phase=0 ∧ q.source=true ∧ q.target=true ∧ q.future=true ∧ q.receipt=true ∧ ¬q.unknown=true ∧ q.targetStamp=q.epoch
def qReleaseNext (q : PinFlat) := {q with source:=false}
def covered (q : PinFlat) : Prop := q.source=true ∨ q.target=true
theorem unstagedRejectsActivation (q : PinFlat) (h : q.staged=false) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem frozenBlocksActivation (q : PinFlat) (h : q.phase≠0) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem frozenBlocksRelease (q : PinFlat) (h : q.phase≠0) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem scannerBlocksRestore (q : PinFlat) (h : q.scanBorrow=true) : ¬qRestoreGuard q := by simp [qRestoreGuard,h]
theorem noFutureRejectsRelease (q : PinFlat) (h : q.future=false) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem unknownRejectsRelease (q : PinFlat) (h : q.unknown=true) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem noReceiptRejectsRelease (q : PinFlat) (h : q.receipt=false) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem releasePreservesCoverage (q : PinFlat) (h : qReleaseGuard q) : covered (qReleaseNext q) := by
 rcases h with ⟨_,_,v,_,_,_,_⟩
 simp [covered,qReleaseNext,v]
theorem restorePreservesRoot (q : PinFlat) : (qRestoreNext q).target=q.target := rfl
theorem activeRegistrationCoversFuture (q : PinFlat) : (qRegisterNext q).future=true := rfl
-- A real C11/collector ordering embedding must supply these event-order premises.
theorem lastWorkerBeforeSourceRelease (worker restore release : Nat)
 (a : worker<restore) (b : restore<release) : worker<release := by omega
theorem frozenArrivalCannotBeIncluded (freeze arrival : Nat) (late : freeze<arrival) (included : arrival<freeze) : False := by omega
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := IngressCarrierTransfer.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := IngressCarrierTransfer.environmentExactDomain rows valid k d
end ThreadThunkFrozenRoots
