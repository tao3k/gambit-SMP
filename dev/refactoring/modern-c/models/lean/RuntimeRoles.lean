import Std

namespace Gambit.RuntimeRoles

-- These are universal contract laws over root origins and receipts.
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

-- Root coverage is a data-refinement obligation, not a temporal protocol.
-- Cell denotes a logical root location (including its owner/family/slot), not
-- the heap object stored there. Two cells may refer to the same continuation.
-- No theorem below grants unique object copying or asserts that C supplies
-- these premises. In particular, scanning only the leader RC chain cannot
-- establish completeCensus for a nonzero-origin RC payload cell.
section RootTaskCoverage
variable {Cell Origin Task : Type}

def CompleteCensus (actual : Cell → Prop) (represented : Origin → Cell → Prop) : Prop :=
  ∀ c, actual c → ∃ o, represented o c

def TaskCoverage (represented : Origin → Cell → Prop)
    (taskOrigin : Task → Origin) (admitted : Task → Prop) : Prop :=
  ∀ o c, represented o c → ∃ t, admitted t ∧ taskOrigin t = o

def AdapterFaithful (represented : Origin → Cell → Prop)
    (taskOrigin : Task → Origin) (visited : Task → Cell → Prop) : Prop :=
  ∀ t c, visited t c ↔ represented (taskOrigin t) c

theorem completeRootVisit
    (actual : Cell → Prop) (represented : Origin → Cell → Prop)
    (taskOrigin : Task → Origin) (admitted : Task → Prop)
    (visited : Task → Cell → Prop)
    (census : CompleteCensus actual represented)
    (tasks : TaskCoverage represented taskOrigin admitted)
    (adapter : AdapterFaithful represented taskOrigin visited) :
    ∀ c, actual c → ∃ t, admitted t ∧ visited t c := by
  intro c hc
  obtain ⟨o, ho⟩ := census c hc
  obtain ⟨t, ht, he⟩ := tasks o c ho
  exact ⟨t, ht, (adapter t c).mpr (by simpa [he] using ho)⟩

-- A faithful task visits exactly its explicit root-cell domain; it must not
-- replace the source with the worker's bank. Disjointness is required only
-- for root locations, never for reachable heap-object identity.
theorem distinctOriginsNoDuplicateCell
    (represented : Origin → Cell → Prop) (taskOrigin : Task → Origin)
    (visited : Task → Cell → Prop)
    (adapter : AdapterFaithful represented taskOrigin visited)
    (partition : ∀ a b c, represented a c → represented b c → a = b)
    (a b : Task) (different : taskOrigin a ≠ taskOrigin b) :
    ∀ c, ¬ (visited a c ∧ visited b c) := by
  intro c h
  exact different (partition _ _ c ((adapter a c).mp h.1) ((adapter b c).mp h.2))

-- Physical GC relocation changes root addresses. The C refinement must supply
-- a faithful cell-to-current-address map and scanned-address witness; an old
-- saved pointer is not a proof of either premise.
theorem currentAddressCovered {Address : Type}
    (actual : Cell → Prop) (visited : Task → Cell → Prop)
    (currentAddress : Cell → Address) (scannedAddress : Task → Address → Prop)
    (covered : ∀ c, actual c → ∃ t, visited t c)
    (decode : ∀ t c, visited t c → scannedAddress t (currentAddress c)) :
    ∀ c, actual c → ∃ t, scannedAddress t (currentAddress c) := by
  intro c hc
  obtain ⟨t, ht⟩ := covered c hc
  exact ⟨t, decode t c ht⟩
end RootTaskCoverage

end Gambit.RuntimeRoles
