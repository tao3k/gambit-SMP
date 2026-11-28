namespace PersistentCensus
structure Descriptor where
  identity : Nat
  phase : Nat
  deriving DecidableEq
 def live (d : Descriptor) : Bool := d.phase == 2 || d.phase == 3
 def enumerate (ds : List Descriptor) : List Descriptor := ds.filter live
 theorem complete (ds : List Descriptor) (d : Descriptor) (h : d ∈ ds) (l : live d = true) : d ∈ enumerate ds := by
  simp [enumerate, h, l]
 theorem sound (ds : List Descriptor) (d : Descriptor) (h : d ∈ enumerate ds) : d ∈ ds ∧ live d = true := by
  simpa [enumerate] using h
 theorem closingIncluded (ds : List Descriptor) (d : Descriptor) (h : d ∈ ds) (c : d.phase = 3) : d ∈ enumerate ds := by
  apply complete ds d h
  simp [live, c]
 def revoke (d : Descriptor) : Descriptor := {d with phase := if d.phase = 2 then 3 else d.phase}
 theorem revokeLive (d : Descriptor) : live (revoke d) = live d := by
  by_cases h : d.phase = 2
  · simp [live, revoke, h]
  · simp [live, revoke, h]
 def ids (ds : List Descriptor) : List Nat := (enumerate ds).map Descriptor.identity
 theorem revokePreservesIds (ds : List Descriptor) : ids (ds.map revoke) = ids ds := by
  induction ds with
  | nil => rfl
  | cons d ds ih =>
    simp only [List.map_cons, ids, enumerate, List.filter_cons]
    rw [revokeLive]
    split <;> simp_all [ids, enumerate, revoke]
end PersistentCensus
