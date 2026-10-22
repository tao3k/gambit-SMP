namespace GambitSMP.StillCompletionLifetime
structure Ledger where
 liability : Nat
 credited : Nat
 consumed : Bool
 known : Bool
 allowed : Bool
def total (s : Ledger) := s.liability+s.credited
inductive SettleStep : Ledger → Ledger → Prop
 | apply (s : Ledger) (w : Nat) (hw : w ≤ s.liability) (fresh : s.consumed=false)
     (known : s.known=true) (allowed : s.allowed=true) :
     SettleStep s {s with liability:=s.liability-w,credited:=s.credited+w,consumed:=true}
 | replay (s : Ledger) : SettleStep s s
theorem settlePreserves {a b : Ledger} (h : SettleStep a b) : total a=total b := by
 cases h <;> simp [total] <;> omega
inductive SettleTrace : Ledger → Ledger → Prop
 | nil (s : Ledger) : SettleTrace s s
 | cons {a b c : Ledger} : SettleStep a b → SettleTrace b c → SettleTrace a c
theorem tracePreserves {a b : Ledger} (h : SettleTrace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (settlePreserves h).trans ih
theorem consumedCannotCredit (a b : Ledger) (used : a.consumed=true) (h : SettleStep a b) : b=a := by
 cases h with
 | apply w hw fresh known allowed => simp [used] at fresh
 | replay => rfl
structure Exit where
 ready : Bool
 gateHeld : Bool
 poisoned : Bool
 resultProtected : Bool
 bindingRestored : Bool
def canRestore (s : Exit) := s.ready=true ∧ s.gateHeld=false ∧ s.poisoned=false ∧ s.resultProtected=true ∧ s.bindingRestored=true
theorem rawGapCannotRestore (s : Exit) (h : s.ready=false) : ¬ canRestore s := by simp [canRestore,h]
theorem heldGateCannotRestore (s : Exit) (h : s.gateHeld=true) : ¬ canRestore s := by simp [canRestore,h]
theorem poisonCannotRestore (s : Exit) (h : s.poisoned=true) : ¬ canRestore s := by simp [canRestore,h]
theorem unrootedCannotRestore (s : Exit) (h : s.resultProtected=false) : ¬ canRestore s := by simp [canRestore,h]
structure RawState where
 ready : Bool
 effect : Bool
def visible (s : RawState) : Bool := if s.ready then s.effect else false
theorem unpublishedAmbiguity : ∃ a b : RawState, visible a=visible b ∧ a.effect≠b.effect := by
 exact ⟨⟨false,false⟩,⟨false,true⟩,rfl,by decide⟩
theorem noObservationOnlyDecoder : ¬ ∃ f : Bool → Bool, ∀ s : RawState, f (visible s)=s.effect := by
 rintro ⟨f,h⟩
 have a:=h ⟨false,false⟩
 have b:=h ⟨false,true⟩
 simp [visible] at a b
 rw [a] at b
 contradiction
structure Record where
 sequence : Nat
 floor : Nat
 pins : Nat
 producerClosed : Bool
 settled : Bool
 acknowledged : Bool
def reusable (r : Record) := r.sequence≤r.floor ∧ r.pins=0 ∧ r.producerClosed=true ∧ r.settled=true ∧ r.acknowledged=true
theorem pinBlocksReuse (r : Record) (h : 0<r.pins) : ¬ reusable r := by
 intro good
 have hz:=good.2.1
 omega
theorem prefixHoleBlocksReuse (r : Record) (h : r.floor<r.sequence) : ¬ reusable r := by
 intro good
 have hf:=good.1
 omega
theorem producerMustClose (r : Record) (h : r.producerClosed=false) : ¬ reusable r := by simp [reusable,h]
def lookupAllowed (sequence floor : Nat) := floor<sequence
theorem retiredLookupRejected (sequence floor : Nat) (h : sequence≤floor) : ¬ lookupAllowed sequence floor := by simp [lookupAllowed] <;> omega
inductive FloorTrace : Nat → Nat → Prop
 | nil (f : Nat) : FloorTrace f f
 | cons {a b c : Nat} : a≤b → FloorTrace b c → FloorTrace a c
theorem floorNeverRegresses {a b : Nat} (h : FloorTrace a b) : a≤b := by
 induction h with
 | nil => exact Nat.le_refl _
 | cons h _ ih => exact Nat.le_trans h ih
theorem generationMismatchRejected (present request : Nat) (h : present≠request) : ¬ present=request := h
theorem boundedWindowMetadata (records issuers window recordBytes floorBytes : Nat)
 (h : records≤issuers*window) : records*recordBytes+issuers*floorBytes≤(issuers*window)*recordBytes+issuers*floorBytes := by
 exact Nat.add_le_add_right (Nat.mul_le_mul_right recordBytes h) _
end GambitSMP.StillCompletionLifetime
