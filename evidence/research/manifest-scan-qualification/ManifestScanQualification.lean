import PendingStartComposition
namespace ManifestScanQualification
structure PinFlat where
 frozen : Bool
 captured : Bool
 root0 : Bool
 root1 : Bool
 root2 : Bool
 active0 : Bool
 active1 : Bool
 c0 : Int
 c1 : Int
 c2 : Int
 debt : Int
 ingressClosed : Bool
 drained : Bool
 joinedB : Bool
 rejectedB : Bool
 abortB : Bool
 quarantinedB : Bool
 retiredB : Bool
 deriving DecidableEq
def qScanGuard (q : PinFlat) : Prop := q.frozen=true ∧ q.captured=true ∧ q.active0=true ∧ q.c0=0
def qScanNext (q : PinFlat) := {q with c0:=1,debt:=q.debt+1}
def qDrainGuard (q : PinFlat) : Prop := q.frozen=true ∧ q.ingressClosed=true ∧ q.c0=1 ∧ q.c1=1 ∧ q.c2=1 ∧ q.debt=0 ∧ ¬q.active0=true ∧ ¬q.active1=true
def qDrainNext (q : PinFlat) := {q with drained:=true}
def qRetireGuard (q : PinFlat) : Prop := ¬q.captured=true ∧ ¬q.frozen=true ∧ (q.joinedB=true ∨ q.rejectedB=true) ∧ ¬q.quarantinedB=true
def qRetireNext (q : PinFlat) := {q with retiredB:=true}
theorem noFrozenRejectsScan (q : PinFlat) (h : q.frozen=false) : ¬qScanGuard q := by simp [qScanGuard,h]
theorem debtBlocksDrain (q : PinFlat) (h : q.debt≠0) : ¬qDrainGuard q := by simp [qDrainGuard,h]
theorem missingSlotBlocksDrain (q : PinFlat) (h : q.c2≠1) : ¬qDrainGuard q := by simp [qDrainGuard,h]
theorem capturedBlocksRetire (q : PinFlat) (h : q.captured=true) : ¬qRetireGuard q := by simp [qRetireGuard,h]
theorem quarantineBlocksRetire (q : PinFlat) (h : q.quarantinedB=true) : ¬qRetireGuard q := by simp [qRetireGuard,h]
theorem noStopBlocksRetire (q : PinFlat) (j : q.joinedB=false) (r : q.rejectedB=false) : ¬qRetireGuard q := by simp [qRetireGuard,j,r]
def assigned (i w workers : Nat) : Prop := w=i%workers ∧ w<workers
theorem partitionTotal (i workers : Nat) (positive : 0<workers) : ∃ w, assigned i w workers := by
 exact ⟨i%workers,rfl,Nat.mod_lt i positive⟩
theorem partitionUnique (i w v workers : Nat) (a : assigned i w workers) (b : assigned i v workers) : w=v := a.1.trans b.1.symm
-- Canonical index-to-slot identity is an independent input assumption.
theorem canonicalUnique (slot : Nat → Nat) (injective : Function.Injective slot)
 (i j : Nat) (same : slot i=slot j) : i=j := injective same
-- Terminal root conditions are stronger than root-visit count alone.
theorem drainNoActiveWorker (q : PinFlat) (h : qDrainGuard q) : q.active0=false ∧ q.active1=false := by
 rcases h with ⟨_,_,_,_,_,_,a,b⟩
 cases x:q.active0 <;> cases y:q.active1 <;> simp_all
theorem oldViewBeforeFree (last drain free : Nat) (a : last<drain) (b : drain<free) : last<free := by omega
-- Stronger ready cohort implies the old adoption guard; readiness issuance itself is external.
def readyCohort (q : PendingStartComposition.PinFlat) : Prop :=
 q.phase=0 ∧ q.pendingA=true ∧ ¬q.contextA=true ∧ q.launchA=true ∧ q.startA=true ∧ q.readyA=true ∧ q.memberA=true ∧ q.ackA=true
theorem readyImpliesAdoption (q : PendingStartComposition.PinFlat) (h : readyCohort q) : PendingStartComposition.qAdoptGuard q := h
theorem readyAdoptionKeepsRoot (q : PendingStartComposition.PinFlat) (h : readyCohort q) :
 PendingStartComposition.rootProjection (PendingStartComposition.qAdoptNext q)=PendingStartComposition.rootProjection q := PendingStartComposition.adoptionRootStutters q h
theorem isolatedRollbackLocal (q : PendingStartComposition.PinFlat) :
 (PendingStartComposition.qRollbackNext q).launchA=q.launchA := rfl
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := PendingStartComposition.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := PendingStartComposition.environmentExactDomain rows valid k d
end ManifestScanQualification
