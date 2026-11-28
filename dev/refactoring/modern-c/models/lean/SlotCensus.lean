import Std
namespace SlotCensus
structure SlotKey where
 vm : Nat
 storage : Nat
 generation : Nat
 offset : Nat
 deriving DecidableEq
structure Descriptor where
 identity : Nat
 key : SlotKey
 phase : Nat
 deriving DecidableEq
def live (d : Descriptor) : Bool := d.phase == 2 || d.phase == 3
def unique {α : Type} [DecidableEq α] : List α → List α
 | [] => []
 | a::as => if a ∈ unique as then unique as else a :: unique as
theorem memUnique {α : Type} [DecidableEq α] (xs : List α) (a : α) : a ∈ unique xs ↔ a ∈ xs := by
 induction xs generalizing a with
 | nil => simp [unique]
 | cons x xs ih =>
   by_cases h : x ∈ unique xs
   · simp only [unique, if_pos h]
     have hx := (ih x).mp h
     simp_all
   · simp only [unique, if_neg h, List.mem_cons]
     rw [ih a]
theorem uniqueNodup {α : Type} [DecidableEq α] (xs : List α) : (unique xs).Nodup := by
 induction xs with
 | nil => simp [unique]
 | cons x xs ih =>
   by_cases h : x ∈ unique xs <;> simp [unique, h, ih]
theorem uniqueLength {α : Type} [DecidableEq α] (xs : List α) : (unique xs).length ≤ xs.length := by
 induction xs with
 | nil => simp [unique]
 | cons x xs ih =>
   by_cases h : x ∈ unique xs <;> simp only [unique, h, ite_true, ite_false, List.length_cons] <;> omega
def census (ds : List Descriptor) : List SlotKey := unique ((ds.filter live).map Descriptor.key)
theorem allRegisteredSlots (ds : List Descriptor) (d : Descriptor) (member : d ∈ ds) (l : live d = true) : d.key ∈ census ds := by
 apply (memUnique _ _).mpr
 exact List.mem_map.mpr ⟨d, List.mem_filter.mpr ⟨member,l⟩, rfl⟩
theorem censusNoDuplicate (ds : List Descriptor) : (census ds).Nodup := uniqueNodup _
theorem boundedByEntries (ds : List Descriptor) : (census ds).length ≤ ds.length := by
 have h := uniqueLength ((ds.filter live).map Descriptor.key)
 have h2 := List.length_filter_le live ds
 simp only [List.length_map] at h
 exact Nat.le_trans h h2
theorem twoKeysBothRepresented (ds : List Descriptor) (a b : Descriptor)
 (ha : a ∈ ds) (hb : b ∈ ds) (la : live a = true) (lb : live b = true) :
 a.key ∈ census ds ∧ b.key ∈ census ds := ⟨allRegisteredSlots ds a ha la,allRegisteredSlots ds b hb lb⟩
-- Native key/address adequacy is a premise, never inferred from equal values.
theorem addressAliasIffKey (address : SlotKey → Nat) (adequate : Function.Injective address) (a b : SlotKey) : address a = address b ↔ a = b := by
 constructor
 · intro h; exact adequate h
 · intro h; exact congrArg address h
end SlotCensus
