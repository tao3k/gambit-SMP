import WorkAccounting

namespace GambitSMP.RuntimeEntryContracts

-- Abstract word intervals: no machine overflow, alignment or psection model.
abbrev Reservation := Nat × Nat

def Disjoint (a b : Reservation) : Prop :=
  a.1 + a.2 ≤ b.1 ∨ b.1 + b.2 ≤ a.1

def reservations (cursor : Nat) : List Nat → List Reservation
  | [] => []
  | size :: rest => (cursor, size) :: reservations (cursor + size) rest

theorem reservationLowerBound (sizes : List Nat) (cursor : Nat) :
    ∀ r ∈ reservations cursor sizes, cursor ≤ r.1 := by
  induction sizes generalizing cursor with
  | nil => simp [reservations]
  | cons size rest ih =>
    intro r hr
    simp only [reservations, List.mem_cons] at hr
    rcases hr with rfl | hr
    · exact Nat.le_refl _
    · have h := ih (cursor + size) r hr
      omega

-- The source must refine this single-cursor history; this is not that proof.
theorem sequentialReservationsDisjoint (sizes : List Nat) (cursor : Nat) :
    (reservations cursor sizes).Pairwise Disjoint := by
  induction sizes generalizing cursor with
  | nil => simp [reservations]
  | cons size rest ih =>
    simp only [reservations, List.pairwise_cons]
    constructor
    · intro r hr
      exact Or.inl (reservationLowerBound rest (cursor + size) r hr)
    · exact ih (cursor + size)

theorem staleCursorOverlap : ¬ Disjoint (0, 2) (0, 1) := by
  unfold Disjoint
  decide

-- The same processor can have nested entries by the same execution owner.
-- Different owners must not execute on that processor simultaneously.
structure Entry where
  owner : Nat
  processor : Nat
  lease : Bool
  deriving DecidableEq

def Compatible (a b : Entry) : Prop :=
  a.processor ≠ b.processor ∨ a.owner = b.owner

theorem ownedProcessorEntriesCompatible (ownerOf : Nat → Nat)
    (a b : Entry) (ha : ownerOf a.processor = a.owner)
    (hb : ownerOf b.processor = b.owner) : Compatible a b := by
  by_cases same : a.processor = b.processor
  · right
    rw [same] at ha
    exact ha.symm.trans hb
  · exact Or.inl same

theorem leasesDoNotGiveExecutionOwnership :
    let a : Entry := ⟨0, 0, true⟩
    let b : Entry := ⟨1, 0, true⟩
    a.lease = true ∧ b.lease = true ∧ ¬ Compatible a b := by
  dsimp [Compatible]
  decide

theorem distinctProcessorsPermitIndependentOwners (a b : Entry)
    (different : a.processor ≠ b.processor) : Compatible a b :=
  Or.inl different

-- Local address stability and published data do not preserve mutated links.
-- This finite lookup projection is not an unbounded hash-table theorem.
def reachesB (node : Nat) (nextA : Option Nat) : Bool :=
  if node = 1 then true else if node = 0 then nextA == some 1 else false

theorem retainedHeadDoesNotPreserveLookup :
    reachesB 0 (some 1) = true ∧ reachesB 0 none = false := by
  decide

theorem lookupWithStableTopology (node : Nat) (before after : Option Nat)
    (unchanged : after = before) : reachesB node after = reachesB node before := by
  rw [unchanged]

-- A failed private operation cannot rewind an arena past another reservation.
-- Abstract intervals only: not a proof of allocator cleanup in C.
theorem rewindAcrossLaterReservationUnsafe (base size laterSize : Nat)
    (laterNonempty : 0 < laterSize) :
    ¬ Disjoint (base + size, laterSize) (base, size + laterSize) := by
  unfold Disjoint
  omega

-- Planning capacity is insufficient; this premise must hold at protected copy.
theorem revalidatedCopyIndexBound (count capacity index : Nat)
    (fit : count ≤ capacity) (inCapture : index < count) : index < capacity := by
  omega

-- A published root must be reloaded after the moving-GC epoch changes.
-- This does not prove source root-slot ownership, service, or moving GC.
theorem staleLocalAfterMove (before after cached : Nat)
    (moved : before ≠ after) (stale : cached = before) : cached ≠ after := by
  simpa [stale] using moved

-- A traced frame chain retains the relocated suspended suffix. The source
-- must actually enumerate these roots; a C-local backup is not such a chain.
theorem nestedTracedSuffix (relocate : Nat → Nat) (inner : Nat)
    (outer : List Nat) :
    ((inner :: outer).map relocate).tail = outer.map relocate := by
  rfl

-- A prospective metadata->service->registry->metadata cycle cannot be fixed
-- merely by assigning ranks. This does not assert that source has every edge.
theorem serviceCycleCannotHaveStrictRanks (metadata service registry : Nat)
    (toService : metadata < service) (toRegistry : service < registry)
    (toMetadata : registry < metadata) : False := by
  omega

-- Distinct publication predicates: VM slot coverage says nothing by itself
-- about a later-initialized global record. Not a C memory-order theorem.
theorem slotReadinessDoesNotGiveRecordReadiness :
    ∃ readiness : Bool × Bool, readiness.1 = true ∧ readiness.2 = false := by
  exact ⟨(true, false), rfl, rfl⟩

-- New proposed registry->metadata and metadata->registry cannot coexist.
-- Actual callback effects must supply the source edges; no native lock proof.
theorem registryMetadataOrderExcludesReverse (registry metadata : Nat)
    (ordered : registry < metadata) (reverse : metadata < registry) : False := by
  omega

-- Alignment may leave a gap but must not move the reservation backwards.
-- This does not model machine overflow, psections or OS allocation failure.
theorem alignedSuccessorDisjoint (base size aligned nextSize : Nat)
    (after : base + size ≤ aligned) : Disjoint (base, size) (aligned, nextSize) := by
  exact Or.inl after

-- A binding/index correspondence is the missing bridge between separately
-- ready records and VM roots. All participants use the matched rebuilt
-- protocol; actual publication/constructor transitions must establish it.
theorem bindingCoverageComposes {Slot : Type} (bindings globals roots : Slot → Prop)
    (registered : ∀ x, bindings x → globals x)
    (rooted : ∀ x, globals x → roots x) : ∀ x, bindings x → roots x := by
  intro x visible
  exact rooted x (registered x visible)

-- Root coverage for committed globals alone permits an unrelated visible
-- binding. This is not a theorem about C atomic instructions or real GC.
theorem localCoverageWithoutBindingBridge :
    ∃ globals roots bindings : Nat → Prop,
      (∀ x, globals x → roots x) ∧ bindings 1 ∧ ¬ roots 1 := by
  refine ⟨(fun x => x = 0), (fun x => x = 0), (fun x => x = 1), ?_⟩
  exact ⟨(fun _ h => h), rfl, by decide⟩

-- Revalidate the derived predicate, not merely the address/root or capacity.
-- The caller must establish either topology stability or actual recomputation.
theorem checkedBucketAfterWait (hash before after cached : Nat)
    (positive : 0 < after)
    (checked : (before = after ∧ cached = hash % before) ∨ cached = hash % after) :
    cached = hash % after ∧ cached < after := by
  have current : cached = hash % after := by
    rcases checked with ⟨same, old⟩ | fresh
    · simpa [same] using old
    · exact fresh
  exact ⟨current, current ▸ Nat.mod_lt hash positive⟩

-- Capacity checks alone admit a stale but in-bounds bucket after a resize.
theorem inBoundsBucketMayMiss :
    (1 : Nat) < 4 ∧ (3 : Nat) % 2 = 1 ∧ (3 : Nat) % 4 ≠ 1 := by
  decide

-- Re-entry uses the suffix of the captured membership, not a fresh table.
-- Root retention and generated-frame liveness are separate source premises.
theorem replayedSuffixMembership {A : Type} (snapshot : List A) (index : Nat)
    (x : A) (present : x ∈ snapshot.drop index) : x ∈ snapshot := by
  exact List.mem_of_mem_drop present

-- Exactly-once delivery within one traversal cannot forbid explicit re-entry.
-- No theorem here asserts arbitrary FFI continuation resumption is supported.
theorem explicitReplayMayRepeat (effects shots : Nat)
    (nonempty : 0 < effects) (repeated : 1 < shots) : effects < shots * effects := by
  calc
    effects = 1 * effects := by simp
    _ < shots * effects := Nat.mul_lt_mul_of_pos_right repeated nonempty

-- The source must re-read this canonical binding while owning the transaction.
-- A preliminary miss, stable capacity or independent reservation is not enough.
theorem canonicalRecheckAgrees {Identity : Type} (existing : Option Identity)
    (winner firstPrepared secondPrepared : Identity) (bound : existing = some winner) :
    existing.getD firstPrepared = winner ∧ existing.getD secondPrepared = winner := by
  simp [bound]

-- A successful structural rehash changes layout, not the registered identities.
-- Permutation, lifetime and visibility are source premises, not derived here.
theorem rehashMembershipPreserved {Identity : Type} (before after : List Identity)
    (layout : before.Perm after) (identity : Identity) :
    identity ∈ before ↔ identity ∈ after := by
  exact layout.mem_iff

-- Shared binding identity is not shared mutable VM payload. This functional
-- frame rule is conditional on the actual compiled accessor selecting owner.
theorem vmCellWriteFrame {VM Value : Type} [DecidableEq VM]
    (cells : VM → Value) (owner : VM) (value : Value) :
    let updated := fun vm => if vm = owner then value else cells vm
    updated owner = value ∧ ∀ other, other ≠ owner → updated other = cells other := by
  dsimp
  constructor
  · simp
  · intro other different
    simp [different]

-- A root/continuation/reader's interpretation dependency must remain live.
-- Actual map completeness, producer identity and consumer enumeration are
-- source premises; native-frame count alone cannot instantiate them.
theorem descriptorRetirementExcludesConsumers {Consumer Descriptor : Type}
    (live : Consumer → Prop) (requires : Consumer → Descriptor → Prop)
    (available : Descriptor → Prop)
    (coverage : ∀ c d, live c → requires c d → available d)
    (retired : Descriptor) (reclaimed : ¬ available retired) :
    ∀ c, live c → ¬ requires c retired := by
  intro c active dependency
  exact reclaimed (coverage c retired active dependency)

-- Reuse the existing coverage composition for actual live-slot relocation.
-- The compiler must establish completeness at this RA; the scanner must
-- establish the relocation relation. Producer identity supplies neither.
theorem generatedMapRelocation {Slot Value : Type}
    (live mapped : Slot → Prop) (before after : Slot → Value)
    (relocate : Value → Value)
    (complete : ∀ slot, live slot → mapped slot)
    (scanned : ∀ slot, mapped slot → after slot = relocate (before slot)) :
    ∀ slot, live slot → after slot = relocate (before slot) :=
  bindingCoverageComposes live mapped
    (fun slot => after slot = relocate (before slot)) complete scanned

-- Preserve the established per-entry accounting theorem, not a new unwinder.
theorem ownedNestedExitAccounting
    (a1 a2 r1 r2 : Nat) (e1 e2 d1 d2 : Int)
    (first : GambitSMP.WorkAccounting.EntryBalanced a1 r1 e1 d1)
    (second : GambitSMP.WorkAccounting.EntryBalanced a2 r2 e2 d2) :
    a1 + a2 = r1 + r2 ∧ e1 = d1 ∧ e2 = d2 :=
  GambitSMP.WorkAccounting.balancedNestedExitsCompose
    a1 a2 r1 r2 e1 e2 d1 d2 first second

#print axioms sequentialReservationsDisjoint
#print axioms staleCursorOverlap
#print axioms ownedProcessorEntriesCompatible
#print axioms leasesDoNotGiveExecutionOwnership
#print axioms distinctProcessorsPermitIndependentOwners
#print axioms retainedHeadDoesNotPreserveLookup
#print axioms lookupWithStableTopology
#print axioms ownedNestedExitAccounting
#print axioms rewindAcrossLaterReservationUnsafe
#print axioms revalidatedCopyIndexBound
#print axioms staleLocalAfterMove
#print axioms nestedTracedSuffix
#print axioms serviceCycleCannotHaveStrictRanks
#print axioms slotReadinessDoesNotGiveRecordReadiness
#print axioms registryMetadataOrderExcludesReverse
#print axioms alignedSuccessorDisjoint
#print axioms bindingCoverageComposes
#print axioms localCoverageWithoutBindingBridge
#print axioms checkedBucketAfterWait
#print axioms inBoundsBucketMayMiss
#print axioms replayedSuffixMembership
#print axioms explicitReplayMayRepeat
#print axioms canonicalRecheckAgrees
#print axioms rehashMembershipPreserved
#print axioms vmCellWriteFrame
#print axioms descriptorRetirementExcludesConsumers
#print axioms generatedMapRelocation

end GambitSMP.RuntimeEntryContracts
