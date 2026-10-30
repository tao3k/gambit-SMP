import SnapshotObserverRefinement
namespace PinRosterDetachment
structure PinFlat where
 «open» : Bool
 registered : Bool
 generation : Int
 view : Int
 captured : Bool
 pin : Bool
 access : Bool
 scanner : Bool
 closing : Bool
 requested : Bool
 stopped : Bool
 joined : Bool
 custodian : Bool
 unknown : Bool
 retired : Bool
 deriving DecidableEq
def qRegisterGuard (q : PinFlat) : Prop := q.«open»=true ∧ ¬q.registered=true ∧ ¬q.closing=true ∧ ¬q.retired=true
def qRegisterNext (q : PinFlat) := {q with registered:=true}
def qPinGuard (q : PinFlat) : Prop := q.registered=true ∧ q.captured=true ∧ q.view=q.generation ∧ ¬q.closing=true ∧ ¬q.retired=true ∧ ¬q.stopped=true
def qPinNext (q : PinFlat) := {q with pin:=true}
def qWithdrawGuard (q : PinFlat) : Prop := q.registered=true ∧ q.closing=true ∧ ¬q.pin=true ∧ ¬q.access=true ∧ ¬q.scanner=true ∧ q.stopped=true ∧ q.joined=true ∧ ¬q.unknown=true
def qWithdrawNext (q : PinFlat) := {q with registered:=false}
theorem staleTagNoGrant (q : PinFlat) (h : q.view≠q.generation) : ¬qPinGuard q := by simp [qPinGuard,h]
theorem accessBlocksWithdraw (q : PinFlat) (h : q.access=true) : ¬qWithdrawGuard q := by simp [qWithdrawGuard,h]
theorem scannerBlocksWithdraw (q : PinFlat) (h : q.scanner=true) : ¬qWithdrawGuard q := by simp [qWithdrawGuard,h]
theorem unknownBlocksWithdraw (q : PinFlat) (h : q.unknown=true) : ¬qWithdrawGuard q := by simp [qWithdrawGuard,h]
theorem closedBlocksRegister (q : PinFlat) (h : q.closing=true) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
def staleRelease (q : PinFlat) := q
theorem staleReleasePreserves (q : PinFlat) : staleRelease q=q := rfl
theorem generationAdvanceDistinct (g : Int) : g+1≠g := by omega
-- Mathematical layout bounds only; no effective Darwin word-width attestation.
theorem generation32 : (2:Nat)^(32-26)-1=63 := by decide
theorem generation64 : (2:Nat)^(64-26)-1=274877906943 := by decide
structure Certificate where
 semantic : Bool
 foreign : Bool
 resident : Bool
 dataOnly : Bool
 pending : Bool
 unknown : Bool
 epoch : Int
 current : Int
 deriving DecidableEq
def qualified (c : Certificate) : Prop := c.semantic=true ∧ c.foreign=true ∧ c.resident=true ∧ c.dataOnly=true ∧ c.pending=false ∧ c.unknown=false ∧ c.epoch=c.current
theorem missingSemanticRejects (c : Certificate) (h : c.semantic=false) : ¬qualified c := by simp [qualified,h]
theorem unknownRejects (c : Certificate) (h : c.unknown=true) : ¬qualified c := by simp [qualified,h]
theorem epochMismatchRejects (c : Certificate) (h : c.epoch≠c.current) : ¬qualified c := by simp [qualified,h]
-- Reuse the independently compiled finite-domain direction; extraction remains trusted.
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := SnapshotObserverRefinement.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := SnapshotObserverRefinement.environmentExactDomain rows valid k d
end PinRosterDetachment
