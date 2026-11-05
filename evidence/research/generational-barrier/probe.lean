import Std.Tactic

namespace GambitSMP.GenerationalBarrier

structure StoreState (Slot Card : Type) where
  youngEdge : Slot → Bool
  dirty : Card → Prop
  gcCount : Nat

def Covered {Slot Card : Type} (card : Slot → Card) (s : StoreState Slot Card) : Prop :=
  ∀ p, s.youngEdge p = true → s.dirty (card p)

def record {Slot Card : Type} (card : Slot → Card) (s : StoreState Slot Card) (p : Slot) : StoreState Slot Card :=
  { s with dirty := fun c => c = card p ∨ s.dirty c }

def commit {Slot Card : Type} [DecidableEq Slot] (s : StoreState Slot Card) (p : Slot) : StoreState Slot Card :=
  { s with youngEdge := fun q => if q = p then true else s.youngEdge q }

theorem recordPreservesCoverage {Slot Card : Type} (card : Slot → Card)
    (s : StoreState Slot Card) (p : Slot) (h : Covered card s) :
    Covered card (record card s p) := by
  intro q hq
  exact Or.inr (h q hq)

theorem commitPreservesCoverage {Slot Card : Type} [DecidableEq Slot]
    (card : Slot → Card) (s : StoreState Slot Card) (p : Slot)
    (h : Covered card s) (marked : s.dirty (card p)) : Covered card (commit s p) := by
  intro q hq
  by_cases eq : q = p
  · simpa [commit, eq] using marked
  · exact h q (by simpa [commit, eq] using hq)

theorem recordDoesNotCollect {Slot Card : Type} (card : Slot → Card)
    (s : StoreState Slot Card) (p : Slot) : (record card s p).gcCount = s.gcCount := rfl

theorem commitDoesNotCollect {Slot Card : Type} [DecidableEq Slot]
    (s : StoreState Slot Card) (p : Slot) : (commit s p).gcCount = s.gcCount := rfl

structure LogState (Card : Type) where
  dirty : Card → Prop
  hints : Card → Prop
  overflow : Bool

def LogComplete {Card : Type} (s : LogState Card) : Prop :=
  ∀ c, s.dirty c → s.hints c ∨ s.overflow = true

def mark {Card : Type} (s : LogState Card) (c : Card) (room : Bool) : LogState Card :=
  { dirty := fun q => q = c ∨ s.dirty q
    hints := fun q => (room = true ∧ q = c) ∨ s.hints q
    overflow := s.overflow || !room }

def Selected {Card : Type} (s : LogState Card) (c : Card) : Prop :=
  (s.overflow = true ∧ s.dirty c) ∨ (s.overflow = false ∧ s.hints c)

theorem markPreservesLogCompleteness {Card : Type} (s : LogState Card)
    (c : Card) (room : Bool) (h : LogComplete s) : LogComplete (mark s c room) := by
  intro q hq
  rcases hq with eq | old
  · cases room with
    | false => exact Or.inr (by simp [mark])
    | true => exact Or.inl (Or.inl ⟨rfl, eq⟩)
  · rcases h q old with hint | over
    · exact Or.inl (Or.inr hint)
    · exact Or.inr (by simp [mark, over])

theorem selectedCoversDirty {Card : Type} (s : LogState Card) (h : LogComplete s) :
    ∀ c, s.dirty c → Selected s c := by
  intro c dirty
  cases ho : s.overflow with
  | true => exact Or.inl ⟨ho, dirty⟩
  | false =>
    rcases h c dirty with hint | over
    · exact Or.inr ⟨ho, hint⟩
    · simp [ho] at over

theorem sourceSlotsCovered {Slot Card : Type} (card : Slot → Card)
    (s : LogState Card) (oldYoung : Slot → Prop)
    (writers : ∀ p, oldYoung p → s.dirty (card p)) (complete : LogComplete s) :
    ∀ p, oldYoung p → Selected s (card p) := by
  intro p hp
  exact selectedCoversDirty s complete (card p) (writers p hp)

def seedEpoch {Card : Type} (residual : Card → Prop) (fits : Bool) : LogState Card :=
  { dirty := residual, hints := fun c => fits = true ∧ residual c, overflow := !fits }

theorem nextEpochSeedComplete {Card : Type} (residual : Card → Prop) (fits : Bool) :
    LogComplete (seedEpoch residual fits) := by
  intro c hc
  cases fits with
  | false => exact Or.inr rfl
  | true => exact Or.inl ⟨rfl, hc⟩

-- Arbitrary object population; readiness, payload scan and slot rewriting are distinct.
def Finish {Obj Slot : Type} (published ready scanned : Obj → Prop)
    (required rewritten : Slot → Prop) : Prop :=
  (∀ o, published o → ready o ∧ scanned o) ∧ (∀ p, required p → rewritten p)

theorem noFinishWithCopyDebt {Obj Slot : Type}
    (published ready scanned : Obj → Prop) (required rewritten : Slot → Prop)
    (o : Obj) (pub : published o) (debt : ¬ ready o ∨ ¬ scanned o) :
    ¬ Finish published ready scanned required rewritten := by
  intro done
  rcases debt with init | scan
  · exact init (done.1 o pub).1
  · exact scan (done.1 o pub).2

theorem noRollbackAfterForward {Obj : Type} (published : Obj → Prop)
    (o : Obj) (pub : published o) : ¬ (∀ x, ¬ published x) := by
  intro none
  exact none o pub

theorem claimPreservesBudget (free used total cost : Nat)
    (conserved : free + used = total) (reserved : cost ≤ free) :
    (free - cost) + (used + cost) = total := by omega

theorem reclaimRequiresRewrite {Obj Slot : Type}
    (published ready scanned : Obj → Prop) (required rewritten : Slot → Prop)
    (done : Finish published ready scanned required rewritten)
    (p : Slot) (needed : required p) : rewritten p := done.2 p needed

-- Eliminating a generational barrier requires a proof of the actual old-to-young
-- predicate, not an assumption that every constructor or continuation is young.
theorem validatedElision {Slot : Type} (oldSource youngValue : Slot → Prop)
    (p : Slot) (known : ¬ oldSource p ∨ ¬ youngValue p) :
    ¬ (oldSource p ∧ youngValue p) := by
  intro edge
  rcases known with source | value
  · exact source edge.1
  · exact value edge.2

-- Work-unit bound only: one candidate major is bounded by one baseline mature
-- pass; all extra barrier/coordination/promotion work is charged in overhead.
theorem amplificationWorkPositive (k mature overhead : Nat) (atLeastOne : 1 ≤ k)
    (positive : overhead < (k - 1) * mature) : mature + overhead < k * mature := by
  have split : k * mature = mature + (k - 1) * mature := by
    calc
      k * mature = ((k - 1) + 1) * mature := by rw [Nat.sub_add_cancel atLeastOne]
      _ = mature + (k - 1) * mature := by simp [Nat.add_mul, Nat.add_comm]
  omega

#print axioms recordPreservesCoverage
#print axioms commitPreservesCoverage
#print axioms recordDoesNotCollect
#print axioms commitDoesNotCollect
#print axioms markPreservesLogCompleteness
#print axioms selectedCoversDirty
#print axioms sourceSlotsCovered
#print axioms nextEpochSeedComplete
#print axioms noFinishWithCopyDebt
#print axioms noRollbackAfterForward
#print axioms claimPreservesBudget
#print axioms reclaimRequiresRewrite
#print axioms validatedElision
#print axioms amplificationWorkPositive
end GambitSMP.GenerationalBarrier
#check GambitSMP.GenerationalBarrier.recordPreservesCoverage
#check GambitSMP.GenerationalBarrier.commitPreservesCoverage
#check GambitSMP.GenerationalBarrier.recordDoesNotCollect
#check GambitSMP.GenerationalBarrier.commitDoesNotCollect
#check GambitSMP.GenerationalBarrier.markPreservesLogCompleteness
#check GambitSMP.GenerationalBarrier.selectedCoversDirty
#check GambitSMP.GenerationalBarrier.sourceSlotsCovered
#check GambitSMP.GenerationalBarrier.nextEpochSeedComplete
#check GambitSMP.GenerationalBarrier.noFinishWithCopyDebt
#check GambitSMP.GenerationalBarrier.noRollbackAfterForward
#check GambitSMP.GenerationalBarrier.claimPreservesBudget
#check GambitSMP.GenerationalBarrier.reclaimRequiresRewrite
#check GambitSMP.GenerationalBarrier.validatedElision
#check GambitSMP.GenerationalBarrier.amplificationWorkPositive
