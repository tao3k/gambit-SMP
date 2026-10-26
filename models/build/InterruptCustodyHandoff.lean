import Std.Tactic
namespace InterruptCustodyHandoff
-- Logical custody sets. Signal multiplicity is not represented by event identities.
structure Ledger where
 accepted : Nat → Prop
 producer : Nat → Prop
 pending : Nat → Prop
 active : Nat → Prop
 done : Nat → Prop
def covered (s : Ledger) := ∀ i, s.accepted i → s.producer i ∨ s.pending i ∨ s.active i ∨ s.done i
def accept (s : Ledger) (i : Nat) : Ledger :=
 ⟨fun j=>j=i ∨ s.accepted j,fun j=>j=i ∨ s.producer j,s.pending,s.active,s.done⟩
def publish (s : Ledger) (i : Nat) : Ledger :=
 ⟨s.accepted,fun j=>s.producer j ∧ j≠i,fun j=>j=i ∨ s.pending j,s.active,s.done⟩
def claim (s : Ledger) (batch : Nat → Prop) : Ledger :=
 ⟨s.accepted,s.producer,fun j=>s.pending j ∧ ¬batch j,fun j=>batch j ∨ s.active j,s.done⟩
def finish (s : Ledger) (batch : Nat → Prop) : Ledger :=
 ⟨s.accepted,s.producer,s.pending,fun j=>s.active j ∧ ¬batch j,fun j=>batch j ∨ s.done j⟩
theorem acceptCovered (s : Ledger) (i : Nat) (h : covered s) : covered (accept s i) := by
 intro j hj
 rcases hj with e | old
 · exact Or.inl (Or.inl e)
 · rcases h j old with p | q | a | d
   · exact Or.inl (Or.inr p)
   · exact Or.inr (Or.inl q)
   · exact Or.inr (Or.inr (Or.inl a))
   · exact Or.inr (Or.inr (Or.inr d))
theorem publishPreserves (s : Ledger) (i : Nat) (h : covered s) : covered (publish s i) := by
 intro j hj
 rcases h j hj with p | q | a | d
 · by_cases e : j=i
   · exact Or.inr (Or.inl (Or.inl e))
   · exact Or.inl ⟨p,e⟩
 · exact Or.inr (Or.inl (Or.inr q))
 · exact Or.inr (Or.inr (Or.inl a))
 · exact Or.inr (Or.inr (Or.inr d))
theorem claimPreserves (s : Ledger) (b : Nat → Prop) (h : covered s) : covered (claim s b) := by
 classical
 intro j hj
 rcases h j hj with p | q | a | d
 · exact Or.inl p
 · by_cases e : b j
   · exact Or.inr (Or.inr (Or.inl (Or.inl e)))
   · exact Or.inr (Or.inl ⟨q,e⟩)
 · exact Or.inr (Or.inr (Or.inl (Or.inr a)))
 · exact Or.inr (Or.inr (Or.inr d))
theorem finishPreserves (s : Ledger) (b : Nat → Prop) (h : covered s) : covered (finish s b) := by
 classical
 intro j hj
 rcases h j hj with p | q | a | d
 · exact Or.inl p
 · exact Or.inr (Or.inl q)
 · by_cases e : b j
   · exact Or.inr (Or.inr (Or.inr (Or.inl e)))
   · exact Or.inr (Or.inr (Or.inl ⟨a,e⟩))
 · exact Or.inr (Or.inr (Or.inr (Or.inr d)))
inductive Step : Ledger → Ledger → Prop where
 | enter (s i) : Step s (accept s i)
 | publish (s i) : Step s (publish s i)
 | claim (s b) : Step s (claim s b)
 | finish (s b) : Step s (finish s b)
 | close (s) : Step s s
theorem stepPreserves (s t : Ledger) (h : covered s) (e : Step s t) : covered t := by
 cases e with
 | enter i => exact acceptCovered s i h
 | publish i => exact publishPreserves s i h
 | claim b => exact claimPreserves s b h
 | finish b => exact finishPreserves s b h
 | close => exact h
inductive History : Ledger → Ledger → Prop where
 | nil (s) : History s s
 | cons {s t u} : Step s t → History t u → History s u
theorem historyPreserves {s t : Ledger} (h : covered s) (trace : History s t) : covered t := by
 induction trace with
 | nil => exact h
 | cons first rest ih => exact ih (stepPreserves _ _ h first)
-- Coverage alone does not exclude forged work. These premises are separate.
theorem claimNoInventedWork (s : Ledger) (b : Nat → Prop)
 (subset : ∀ i, b i → s.pending i) (i : Nat) (h : (claim s b).active i) :
 s.pending i ∨ s.active i := by
 rcases h with added | old
 · exact Or.inl (subset i added)
 · exact Or.inr old
theorem finishNoInventedWork (s : Ledger) (b : Nat → Prop)
 (subset : ∀ i, b i → s.active i) (i : Nat) (h : (finish s b).done i) :
 s.active i ∨ s.done i := by
 rcases h with added | old
 · exact Or.inl (subset i added)
 · exact Or.inr old
theorem claimDoesNotAccept (s : Ledger) (b : Nat → Prop) : (claim s b).accepted=s.accepted := rfl
def canSeal (closed : Bool) (producers : Nat) := closed=true ∧ producers=0
theorem sealNeedsProducerDrain (closed : Bool) (p : Nat) (h : canSeal closed p) : p=0 := h.2
def canRetire (closed sealed : Bool) (producers consumers pending writers : Nat) :=
 closed=true ∧ sealed=true ∧ producers=0 ∧ consumers=0 ∧ pending=0 ∧ writers=0
theorem retirementRequiresClosure (c s : Bool) (p a q w : Nat) (h : canRetire c s p a q w) :
 p=0 ∧ a=0 ∧ q=0 ∧ w=0 := h.2.2
theorem acceptedPinBlocksRetirement (c s : Bool) (p a q w : Nat) (pin : 0<p) : ¬canRetire c s p a q w := by
 intro h; have z:=h.2.2.1; omega
theorem reservedClaimBlocksRetirement (c s : Bool) (p a q w : Nat) (pin : 0<a) : ¬canRetire c s p a q w := by
 intro h; have z:=h.2.2.2.1; omega
structure Root where
 identity : Nat
 address : Nat
 registered : Bool
def validRoot (r : Root) (epoch : Nat) := r.registered=true ∧ r.address=r.identity+epoch
def capture (id epoch : Nat) : Root := ⟨id,id+epoch,true⟩
def relocate (r : Root) (newEpoch : Nat) : Root :=
 ⟨r.identity,if r.registered then r.identity+newEpoch else r.address,r.registered⟩
theorem captureRoots (id epoch : Nat) : validRoot (capture id epoch) epoch := by simp [validRoot,capture]
theorem relocationPreserves (r : Root) (old next : Nat) (h : validRoot r old) : validRoot (relocate r next) next := by
 simp_all [validRoot,relocate]
theorem rootedReplacementStable (r : Root) (oldVector newVector : Nat) :
 (fun (_ : Nat) => r.identity) oldVector = (fun (_ : Nat) => r.identity) newVector := rfl
def canCollect (unrooted : Nat) (allParked : Bool) := unrooted=0 ∧ allParked=true
theorem temporaryBlocksGc (n : Nat) (b : Bool) (h : 0<n) : ¬canCollect n b := by
 intro a; have z:=a.1; omega
theorem registeredRequired (r : Root) (e : Nat) (h : validRoot r e) : r.registered=true := h.1
theorem rawTemporaryCounterexample : ¬validRoot (relocate ⟨1,1,false⟩ 10) 10 := by
 simp [validRoot,relocate]
theorem afterMoveMustReload (id old next : Nat) (h : old≠next) : id+old≠id+next := by omega
def parentCanComplete (parent : Nat) (writerParent : Option Nat) := writerParent ≠ some parent
theorem derivedSetterBlocksCompletion (parent : Nat) : ¬parentCanComplete parent (some parent) := by
 simp [parentCanComplete]
theorem unrelatedParentCanComplete (parent other : Nat) (h : other ≠ parent) : parentCanComplete parent (some other) := by
 simp_all [parentCanComplete]
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added)
 (gain : added<saved) : newWork<oldWork := by omega
end InterruptCustodyHandoff
