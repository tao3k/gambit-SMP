import Std

namespace Gambit.RuntimeRoles

-- These are universal contract laws over root origins and receipts receipts.
-- They assume stable VM storage and a real collective publication edge.
def Covered (frozen scanned : Nat → Bool) : Prop :=
  ∀ i, scanned i = true → frozen i = true

def add (slots : Nat → Bool) (i : Nat) : Nat → Bool :=
  fun j => if j = i then true else slots j

theorem emptyCovered (frozen : Nat → Bool) : Covered frozen (fun _ => false) := by
  intro i h
  cases h

theorem freezePreserves (frozen scanned : Nat → Bool) (i : Nat)
    (h : Covered frozen scanned) : Covered (add frozen i) scanned := by
  intro j hs
  by_cases hj : j = i
  · simp [add, hj]
  · simp [add, hj, h j hs]

theorem scanPreserves (frozen scanned : Nat → Bool) (i : Nat)
    (h : Covered frozen scanned) (hi : frozen i = true) :
    Covered frozen (add scanned i) := by
  intro j hs
  by_cases hj : j = i
  · simpa [hj] using hi
  · have hx : scanned j = true := by simpa [add, hj] using hs
    exact h j hx

def Origins (origin : Nat → Nat) (scanned : Nat → Bool) (r : Nat) : Prop :=
  ∃ i, scanned i = true ∧ origin i = r

theorem scanAddsOrigin (origin : Nat → Nat) (scanned : Nat → Bool) (i r : Nat) :
    Origins origin (add scanned i) r ↔ Origins origin scanned r ∨ origin i = r := by
  constructor
  · rintro ⟨j, hj, hr⟩
    by_cases hji : j = i
    · exact Or.inr (by simpa [hji] using hr)
    · exact Or.inl ⟨j, by simpa [add, hji] using hj, hr⟩
  · intro h
    rcases h with ⟨j, hj, hr⟩ | hi
    · exact ⟨j, by by_cases hji : j = i <;> simp [add, hji, hj], hr⟩
    · exact ⟨i, by simp [add], hi⟩

def Delivered (consumed : Nat → Bool) (receipts : Nat → Bool) (outcome : Bool) : Prop :=
  ∀ i, consumed i = true → receipts i = outcome

theorem consumePreserves (consumed receipts : Nat → Bool) (outcome : Bool) (i : Nat)
    (h : Delivered consumed receipts outcome) :
    Delivered (add consumed i) (fun j => if j = i then outcome else receipts j) outcome := by
  intro j hc
  by_cases hj : j = i
  · simp [hj]
  · simp only [if_neg hj]
    exact h j (by simpa [add, hj] using hc)

theorem finalAckImpliesConsumed (prepared consumed : Nat → Bool)
    (h : ∀ i, prepared i = true → consumed i = true)
    (allPrepared : ∀ i, prepared i = true) : ∀ i, consumed i = true := by
  intro i
  exact h i (allPrepared i)

end Gambit.RuntimeRoles
