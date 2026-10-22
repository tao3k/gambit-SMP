namespace GambitSMP.StillLedgerSnapshot
structure Inventory where
  published : Nat
  privateHeld : Nat
  retiredHeld : Nat
  unbackedGrant : Nat
def obligation (i : Inventory) : Nat := i.published+i.privateHeld+i.retiredHeld+i.unbackedGrant
def physical (i : Inventory) : Nat := i.published+i.privateHeld+i.retiredHeld
def attach (i : Inventory) (w : Nat) : Inventory := {i with privateHeld := i.privateHeld+w, unbackedGrant := i.unbackedGrant-w}
def publish (i : Inventory) (w : Nat) : Inventory := {i with published := i.published+w, privateHeld := i.privateHeld-w}
def retire (i : Inventory) (w : Nat) : Inventory := {i with published := i.published-w, retiredHeld := i.retiredHeld+w}
theorem physicalBound (i : Inventory) : physical i ≤ obligation i := by simp [physical,obligation] <;> omega
theorem attachConserves (i : Inventory) (w : Nat) (h : w ≤ i.unbackedGrant) : obligation (attach i w) = obligation i := by simp [obligation,attach] <;> omega
theorem publishConserves (i : Inventory) (w : Nat) (h : w ≤ i.privateHeld) : obligation (publish i w) = obligation i := by simp [obligation,publish] <;> omega
theorem retireConserves (i : Inventory) (w : Nat) (h : w ≤ i.published) : obligation (retire i w) = obligation i := by simp [obligation,retire] <;> omega
theorem retireIsNotFree (i : Inventory) (w : Nat) (h : w ≤ i.published) : physical (retire i w) = physical i := by simp [physical,retire] <;> omega
structure LegacyView where
  lastLive : Nat
  deferred : Nat
  vmCharge : Nat
  physicalWords : Nat
def counters (v : LegacyView) := (v.lastLive,v.deferred,v.vmCharge)
theorem countersNotInjective : ∃ a b : LegacyView, counters a = counters b ∧ a.physicalWords ≠ b.physicalWords := by
  exact ⟨⟨2,0,4,2⟩,⟨2,0,4,4⟩,rfl,by decide⟩
theorem noCounterOnlyDecoder : ¬ ∃ f : (Nat × Nat × Nat) → Nat, ∀ v : LegacyView, f (counters v) = v.physicalWords := by
  rintro ⟨f,h⟩
  have a := h ⟨2,0,4,2⟩
  have b := h ⟨2,0,4,4⟩
  simp [counters] at a b
  omega
structure Snapshot where
  captured : Nat
  current : Nat
  mutationActive : Bool
def admissible (s : Snapshot) : Prop := s.captured=s.current ∧ s.mutationActive=false
theorem staleRejected (s : Snapshot) (h : s.captured ≠ s.current) : ¬ admissible s := by simp [admissible,h]
theorem mutationRejected (s : Snapshot) (h : s.mutationActive=true) : ¬ admissible s := by simp [admissible,h]
theorem ownerOnlyChange (s : Snapshot) (h : admissible s) : admissible s := h
theorem revisionAdvanceInvalidates (s : Snapshot) (h : s.captured=s.current) : ¬ admissible {s with current := s.current+1} := by simp [admissible] <;> omega
structure Refund where
  heldGrant : Nat
  credited : Nat
def settled (r : Refund) : Nat := r.heldGrant+r.credited
inductive RefundStep : Refund → Refund → Prop
  | credit (r : Refund) (w : Nat) (h : w ≤ r.heldGrant) : RefundStep r ⟨r.heldGrant-w,r.credited+w⟩
  | stay (r : Refund) : RefundStep r r
theorem refundStepConserves {a b : Refund} (s : RefundStep a b) : settled a=settled b := by
  cases s <;> simp [settled] <;> omega
inductive RefundTrace : Refund → Refund → Prop
  | refl (r : Refund) : RefundTrace r r
  | next {a b c : Refund} : RefundStep a b → RefundTrace b c → RefundTrace a c
theorem refundTraceConserves {a b : Refund} (t : RefundTrace a b) : settled a=settled b := by
  induction t with
  | refl => rfl
  | next s _ ih => exact (refundStepConserves s).trans ih
theorem emptyGrantCannotCredit (r : Refund) (h : r.heldGrant=0) (w : Nat) (p : 0<w) : ¬ w≤r.heldGrant := by omega
theorem nativeExtentIncludesPadding (words ws modulus extra : Nat) : words*ws ≤ extra+(words+modulus)*ws := by
  rw [Nat.add_mul] <;> omega
theorem logicalRetirementPeak (physical metadata : Nat) : physical ≤ physical+metadata := Nat.le_add_right _ _
end GambitSMP.StillLedgerSnapshot

#check GambitSMP.StillLedgerSnapshot.physicalBound
#print axioms GambitSMP.StillLedgerSnapshot.physicalBound
#check GambitSMP.StillLedgerSnapshot.attachConserves
#print axioms GambitSMP.StillLedgerSnapshot.attachConserves
#check GambitSMP.StillLedgerSnapshot.publishConserves
#print axioms GambitSMP.StillLedgerSnapshot.publishConserves
#check GambitSMP.StillLedgerSnapshot.retireConserves
#print axioms GambitSMP.StillLedgerSnapshot.retireConserves
#check GambitSMP.StillLedgerSnapshot.retireIsNotFree
#print axioms GambitSMP.StillLedgerSnapshot.retireIsNotFree
#check GambitSMP.StillLedgerSnapshot.countersNotInjective
#print axioms GambitSMP.StillLedgerSnapshot.countersNotInjective
#check GambitSMP.StillLedgerSnapshot.noCounterOnlyDecoder
#print axioms GambitSMP.StillLedgerSnapshot.noCounterOnlyDecoder
#check GambitSMP.StillLedgerSnapshot.staleRejected
#print axioms GambitSMP.StillLedgerSnapshot.staleRejected
#check GambitSMP.StillLedgerSnapshot.mutationRejected
#print axioms GambitSMP.StillLedgerSnapshot.mutationRejected
#check GambitSMP.StillLedgerSnapshot.ownerOnlyChange
#print axioms GambitSMP.StillLedgerSnapshot.ownerOnlyChange
#check GambitSMP.StillLedgerSnapshot.revisionAdvanceInvalidates
#print axioms GambitSMP.StillLedgerSnapshot.revisionAdvanceInvalidates
#check GambitSMP.StillLedgerSnapshot.refundStepConserves
#print axioms GambitSMP.StillLedgerSnapshot.refundStepConserves
#check GambitSMP.StillLedgerSnapshot.refundTraceConserves
#print axioms GambitSMP.StillLedgerSnapshot.refundTraceConserves
#check GambitSMP.StillLedgerSnapshot.emptyGrantCannotCredit
#print axioms GambitSMP.StillLedgerSnapshot.emptyGrantCannotCredit
#check GambitSMP.StillLedgerSnapshot.nativeExtentIncludesPadding
#print axioms GambitSMP.StillLedgerSnapshot.nativeExtentIncludesPadding
#check GambitSMP.StillLedgerSnapshot.logicalRetirementPeak
#print axioms GambitSMP.StillLedgerSnapshot.logicalRetirementPeak
