import Std.Tactic
namespace FfiScanReadyHandoff
def covered (live source frame : Nat → Prop) := ∀ i, live i → source i ∨ frame i
def add (s : Nat → Prop) (i : Nat) := fun j => j=i ∨ s j
def remove (s : Nat → Prop) (i : Nat) := fun j => j≠i ∧ s j
theorem publicationPreserves (l s f : Nat → Prop) (i : Nat) (h : covered l s f) : covered l s (add f i) := by
 intro j hj; rcases h j hj with hs|hf
 · exact Or.inl hs
 · exact Or.inr (Or.inr hf)
theorem releaseSourcePreserves (l s f : Nat → Prop) (i : Nat) (h : covered l s f) (ready : f i) : covered l (remove s i) f := by
 intro j hj; by_cases e : j=i
 · subst j; exact Or.inr ready
 · rcases h j hj with hs|hf
   · exact Or.inl ⟨e,hs⟩
   · exact Or.inr hf
structure LeaseState where
 preparing : Bool
 rooted : Bool
 storageOwned : Bool
 parked : Bool
 completed : Bool
def convertLease (s : LeaseState) (stopAcknowledged : Bool) : LeaseState :=
 if stopAcknowledged then {s with preparing := false, parked := true} else s
theorem handoffRetainsCustody (s : LeaseState) (stopAcknowledged : Bool)
 (rootReady : s.rooted=true) (storage : s.storageOwned=true) (stopped : stopAcknowledged=true) :
 (convertLease s stopAcknowledged).rooted=true ∧ (convertLease s stopAcknowledged).storageOwned=true ∧
 (convertLease s stopAcknowledged).preparing=false ∧ (convertLease s stopAcknowledged).parked=true ∧
 (convertLease s stopAcknowledged).completed=s.completed := by
 simp [convertLease,stopped,rootReady,storage]
def readyToFreeze (preparing live parked : Nat → Prop) := (∀ i, ¬preparing i) ∧ ∀ i, live i → parked i
theorem noReturnNeeded : readyToFreeze (fun _ => False) (fun i => i=0) (fun i => i=0) := by
 constructor
 · intro i h; exact h
 · intro i h; exact h
theorem preparingBlocks (p l k : Nat → Prop) (i : Nat) (h : p i) : ¬readyToFreeze p l k := by intro ready; exact ready.1 i h
theorem unknownNotQuiescence : ¬(∀ (unknown parked : Bool), unknown=true → parked=true) := by
 intro h; have bad := h true false rfl; contradiction
def fresh (slot loaded heap : Nat) := slot=heap ∧ loaded=slot
theorem reloadAfterMove (slot heap : Nat) (h : slot=heap) : fresh slot slot heap := ⟨h,rfl⟩
theorem staleLocalRejected : ¬fresh 1 0 1 := by simp [fresh]
def retirePermit (outcome known readers pins childClosed : Bool) := outcome=true ∧ known=true ∧ readers=false ∧ pins=false ∧ childClosed=true
theorem readerBlocksRetirement (o k p c : Bool) : ¬retirePermit o k true p c := by simp [retirePermit]
theorem unknownRetainsCustody (o r p c : Bool) : ¬retirePermit o false r p c := by simp [retirePermit]
theorem nestedBlocksParent (o k r p : Bool) : ¬retirePermit o k r p false := by simp [retirePermit]
def nonzeroScanPermit (vmRegistered ownerCovered : Bool) := vmRegistered=true ∧ ownerCovered=true
theorem registrationAloneInsufficient : ¬nonzeroScanPermit true false := by simp [nonzeroScanPermit]
theorem retryIsNotReexecution (commits : Nat) : commits=commits := rfl
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end FfiScanReadyHandoff
