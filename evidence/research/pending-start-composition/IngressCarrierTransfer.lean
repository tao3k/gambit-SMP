import FfiScopeRootAdmission
namespace IngressCarrierTransfer
structure PinFlat where
 sourceProtected : Bool
 sourceReleased : Bool
 gcCut : Bool
 targetRegistered : Bool
 targetVisible : Bool
 receipt : Bool
 unknown : Bool
 failed : Bool
 done : Bool
 epoch : Int
 sourceStamp : Int
 targetStamp : Int
 localStamp : Int
 deriving DecidableEq
def qRegisterGuard (q : PinFlat) : Prop := q.gcCut=true ∧ q.sourceProtected=true ∧ ¬q.targetVisible=true ∧ q.localStamp=q.epoch
def qRegisterNext (q : PinFlat) := {q with targetRegistered:=true,targetStamp:=q.localStamp}
def qPublishGuard (q : PinFlat) : Prop := q.gcCut=true ∧ q.targetRegistered=true ∧ q.targetStamp=q.epoch ∧ ¬q.targetVisible=true
def qPublishNext (q : PinFlat) := {q with targetVisible:=true,receipt:=true}
def qReleaseGuard (q : PinFlat) : Prop := q.gcCut=true ∧ q.sourceProtected=true ∧ q.targetVisible=true ∧ q.receipt=true ∧ ¬q.unknown=true ∧ q.targetStamp=q.epoch
def qReleaseNext (q : PinFlat) := {q with sourceProtected:=false,sourceReleased:=true}
def covered (q : PinFlat) : Prop := q.sourceProtected=true ∨ q.targetVisible=true
theorem staleLocalRejects (q : PinFlat) (h : q.localStamp≠q.epoch) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem noCutRejectsPublish (q : PinFlat) (h : q.gcCut=false) : ¬qPublishGuard q := by simp [qPublishGuard,h]
theorem unknownBlocksRelease (q : PinFlat) (h : q.unknown=true) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem invisibleBlocksRelease (q : PinFlat) (h : q.targetVisible=false) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem noReceiptBlocksRelease (q : PinFlat) (h : q.receipt=false) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem releasePreservesCoverage (q : PinFlat) (h : qReleaseGuard q) : covered (qReleaseNext q) := by
 rcases h with ⟨_,_,v,_,_,_⟩
 simp [covered,qReleaseNext,v]
theorem registerPreservesSource (q : PinFlat) : (qRegisterNext q).sourceProtected=q.sourceProtected := rfl
theorem publishEstablishesCoverage (q : PinFlat) : covered (qPublishNext q) := by simp [covered,qPublishNext]
-- A supplied ordering embedding is a premise; this does not define the C11 model.
theorem publicationPrecedesSourceRelease (write publish observe release : Nat)
 (a : write<publish) (b : publish<observe) (c : observe<release) : write<release := by omega
theorem lastScanPrecedesFree (scan drain free : Nat) (a : scan<drain) (b : drain<free) : scan<free := by omega
theorem overlapNeedsNoGap (sourceEnd targetStart : Nat) (overlap : targetStart≤sourceEnd)
 (gap : sourceEnd<targetStart) : False := by omega
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := FfiScopeRootAdmission.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := FfiScopeRootAdmission.environmentExactDomain rows valid k d
end IngressCarrierTransfer
