import Std
namespace Gambit.ServiceShutdown
structure Cursor where
 stage : Nat
 claimed : Bool
 unknown : Bool
 error : Bool
 logicalReadClosed : Bool
 readDone : Bool
 writeDone : Bool
 childrenSettled : Bool

def complete (c : Cursor) : Prop := c.stage=8 ∧ c.unknown=false ∧ c.childrenSettled=true

def canReadDone (c : Cursor) : Prop := c.stage=3 ∧ c.unknown=false ∧ c.error=false

def advanceRead (c : Cursor) : Cursor := {c with stage:=4, readDone:=true}

def canDetach (c : Cursor) : Prop := c.claimed=true ∧ c.stage=0

theorem readErrorRefusesAdvance (c : Cursor) (h : c.error=true) : ¬canReadDone c := by
 intro p
 have no:=p.2.2
 rw [h] at no
 contradiction

theorem unknownReadRefusesAdvance (c : Cursor) (h : c.unknown=true) : ¬canReadDone c := by
 intro p
 have no:=p.2.1
 rw [h] at no
 contradiction

theorem knownReadRetainsPhysicalWitness (c : Cursor) (_h : canReadDone c) : (advanceRead c).stage=4 ∧ (advanceRead c).readDone=true := ⟨rfl,rfl⟩

theorem detachedIntentCannotRestart (c : Cursor) (h : c.stage=1) : ¬canDetach c := by
 intro p
 have zero:=p.2
 omega

theorem logicalClosedDoesNotProveReadDone : ∃ c : Cursor, c.logicalReadClosed=true ∧ c.readDone=false :=
 ⟨⟨3,true,false,true,true,false,false,false⟩,rfl,rfl⟩

structure Service (Member : Type) where
 admitting : Bool
 writers : Nat
 rawWriter : Bool
 anchor : Bool
 producer : Bool
 cursor : Member → Cursor

def drained {Member : Type} (s : Service Member) : Prop := s.admitting=false ∧ s.writers=0 ∧ s.rawWriter=false ∧ s.producer=false ∧ ∀ m, complete (s.cursor m)

def canStop {Member : Type} (s : Service Member) : Prop := drained s ∧ s.anchor=false

theorem liveWriterBlocksDrain {Member : Type} (s : Service Member) (h : s.writers≠0) : ¬drained s := fun p=>h p.2.1

theorem rawWriterBlocksDrain {Member : Type} (s : Service Member) (h : s.rawWriter=true) : ¬drained s := by
 intro p
 have no:=p.2.2.1
 rw [h] at no
 contradiction

theorem stopRequiresEveryMember {Member : Type} (s : Service Member) (h : canStop s) : ∀ m, complete (s.cursor m) := h.1.2.2.2.2

theorem oneUnknownRefusesStop {Member : Type} (s : Service Member) (m : Member) (h : (s.cursor m).unknown=true) : ¬canStop s := by
 intro p
 have no:=(stopRequiresEveryMember s p m).2.1
 rw [h] at no
 contradiction

theorem retainedAnchorRefusesStop {Member : Type} (s : Service Member) (h : s.anchor=true) : ¬canStop s := by
 intro p
 have no:=p.2
 rw [h] at no
 contradiction

structure ForeignClaim where
 escrowReady : Bool
 pointerLive : Bool
 releaseFunctionLive : Bool

def clearBeforeCall (x : ForeignClaim) : ForeignClaim := {x with pointerLive:=false,releaseFunctionLive:=false}

theorem clearBeforeCallKeepsEscrow (x : ForeignClaim) (h : x.escrowReady=true) : (clearBeforeCall x).escrowReady=true ∧ (clearBeforeCall x).pointerLive=false ∧ (clearBeforeCall x).releaseFunctionLive=false := ⟨h,rfl,rfl⟩

def finishRelease (c : Cursor) : Cursor := {c with stage:=8,unknown:=false}

theorem knownReleaseErrorStillFinished (c : Cursor) (children : c.childrenSettled=true) : complete (finishRelease {c with error:=true}) := ⟨rfl,rfl,children⟩
theorem normalErrorReturnDoesNotProveCompletion : ∃ c : Cursor, c.error=true ∧ ¬complete c := by
 refine ⟨⟨3,true,false,true,true,false,false,false⟩,rfl,?_⟩
 simp [complete]

structure ReleaseOutcome where
 observed : Bool
 qualified : Bool
 ownLeaseDone : Bool
 containerFreed : Bool
 childrenKnown : Bool
 error : Bool

def receipt (o : ReleaseOutcome) : Prop := o.observed=true ∧ o.qualified=true ∧ o.ownLeaseDone=true ∧ o.childrenKnown=true

theorem zeroStatusDoesNotImplyNativeFree : ∃ o : ReleaseOutcome, receipt o ∧ o.error=false ∧ o.containerFreed=false := ⟨⟨true,true,true,false,true,false⟩,⟨rfl,rfl,rfl,rfl⟩,rfl,rfl⟩

theorem nonzeroCanSettleWithWitnesses : ∃ o : ReleaseOutcome, receipt o ∧ o.error=true := ⟨⟨true,true,true,true,true,true⟩,⟨rfl,rfl,rfl,rfl⟩,rfl⟩

theorem ownFreeDoesNotSettleDescendants : ∃ o : ReleaseOutcome, o.containerFreed=true ∧ ¬receipt o := by
 refine ⟨⟨true,true,true,true,false,true⟩,rfl,?_⟩
 simp [receipt]

theorem unknownOutcomeRefusesReceipt (o : ReleaseOutcome) (h : o.observed=false) : ¬receipt o := by
 intro p
 have known:=p.1
 rw [h] at known
 contradiction

theorem unqualifiedSuccessRefusesReceipt (o : ReleaseOutcome) (h : o.qualified=false) : ¬receipt o := by
 intro p
 have certified:=p.2.1
 rw [h] at certified
 contradiction

theorem descendantDebtBlocksComplete (c : Cursor) (h : c.childrenSettled=false) : ¬complete c := by
 intro p
 have done:=p.2.2
 rw [h] at done
 contradiction
-- Source closure and identity resolution remain refinement premises.
structure ChildCertificate where
 attempt : Nat
 member : Nat
 generation : Nat
 provider : Nat
 issuer : Nat
 closed : Bool
 observed : Bool
 required : List Nat
 settled : List Nat
 transferred : List Nat

def certified (a m : Nat) (expected : List Nat) (r : ChildCertificate) : Prop :=
 r.attempt=a ∧ r.member=m ∧ r.generation=a ∧ r.provider=100+m ∧ r.issuer=200+m ∧
 r.closed=true ∧ r.observed=true ∧ r.required=expected ∧
 (∀ k, k ∈ expected ↔ k ∈ r.settled) ∧ r.transferred=[]

theorem certificateCoversEveryResource (a m : Nat) (expected : List Nat) (r : ChildCertificate)
 (h : certified a m expected r) : ∀ k, k ∈ expected → k ∈ r.settled := by
 intro k hk
 exact (h.2.2.2.2.2.2.2.2.1 k).mp hk

theorem certificateRejectsExtraResource (a m : Nat) (expected : List Nat) (r : ChildCertificate)
 (h : certified a m expected r) : ∀ k, k ∈ r.settled → k ∈ expected := by
 intro k hk
 exact (h.2.2.2.2.2.2.2.2.1 k).mpr hk

theorem certificateRejectsStaleGeneration (a m : Nat) (expected : List Nat) (r : ChildCertificate)
 (bad : r.generation ≠ a) : ¬certified a m expected r := fun h => bad h.2.2.1

theorem certificateRequiresClosedProducer (a m : Nat) (expected : List Nat) (r : ChildCertificate)
 (h : certified a m expected r) : r.closed=true := h.2.2.2.2.2.1

theorem certificateRejectsTransferredVmDebt (a m : Nat) (expected : List Nat) (r : ChildCertificate)
 (bad : r.transferred ≠ []) : ¬certified a m expected r := fun h => bad h.2.2.2.2.2.2.2.2.2

def acceptChildren (c : Cursor) : Cursor := {c with childrenSettled:=true}
theorem acceptedChildrenCompletesKnownOwnRelease (c : Cursor) (stage : c.stage=8)
 (known : c.unknown=false) : complete (acceptChildren c) := ⟨stage,known,rfl⟩
theorem repeatedChildReceiptIdempotent (c : Cursor) : acceptChildren (acceptChildren c)=acceptChildren c := rfl
end Gambit.ServiceShutdown
