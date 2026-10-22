namespace GambitSMP.RcFreezePublication

structure State where
  initialized : Bool
  published : Bool
  closed : Bool
  knownWriters : Bool
  writers : Nat
  rawBorrows : Nat
  storageLeases : Nat
  generation : Nat
  receiptGeneration : Nat
  deriving DecidableEq

def CanIssue (s : State) : Prop :=
  s.initialized = true ∧ s.published = true ∧ s.closed = true ∧
  s.knownWriters = true ∧ s.writers = 0 ∧ s.rawBorrows = 0

def issue (s : State) : State := { s with receiptGeneration := s.generation }

theorem issueRequiresFinalValues (s : State) (h : CanIssue s) :
    s.writers = 0 ∧ s.rawBorrows = 0 ∧ s.knownWriters = true :=
  ⟨h.2.2.2.2.1, h.2.2.2.2.2, h.2.2.2.1⟩

theorem issueBindsGeneration (s : State) : (issue s).receiptGeneration = s.generation := rfl

theorem storageLeaseDoesNotBlockFreeze (s : State) (h : CanIssue s) (n : Nat) :
    CanIssue { s with storageLeases := n } := h

theorem publicationPrecedesReceipt (s : State) (h : CanIssue s) :
    s.initialized = true ∧ s.published = true := ⟨h.1, h.2.1⟩

-- The collector owns relocation; mutator permission is intentionally not required.
def CollectorMayRelocate (s : State) : Prop := CanIssue s ∧ s.receiptGeneration = s.generation

theorem collectorCanUpdateFrozenRoots (s : State) (h : CanIssue s) :
    CollectorMayRelocate (issue s) := by
  exact ⟨h, rfl⟩

-- Protocol rule: the collector cannot await a task which needs its own pin released.
-- Natural ranks rule out all finite wait cycles only if EVERY real wait edge refines this relation.
inductive WaitEdge : Nat → Nat → Prop where
  | ordered {a b} : a < b → WaitEdge a b

inductive WaitPath : Nat → Nat → Prop where
  | edge {a b} : WaitEdge a b → WaitPath a b
  | snoc {a b c} : WaitPath a b → WaitEdge b c → WaitPath a c

theorem waitPathIncreases {a b : Nat} (p : WaitPath a b) : a < b := by
  induction p with
  | edge h => cases h with | ordered lt => exact lt
  | snoc _ e ih => cases e with | ordered lt => exact Nat.lt_trans ih lt

theorem noRankedWaitCycle {a : Nat} (p : WaitPath a a) : False :=
  Nat.lt_irrefl a (waitPathIncreases p)

#print axioms issueRequiresFinalValues
#print axioms issueBindsGeneration
#print axioms storageLeaseDoesNotBlockFreeze
#print axioms publicationPrecedesReceipt
#print axioms collectorCanUpdateFrozenRoots
#print axioms waitPathIncreases
#print axioms noRankedWaitCycle
end GambitSMP.RcFreezePublication
namespace GambitSMP.GenerationalRootAdmission

inductive Reach {Obj : Type} (root : Obj → Prop) (edge : Obj → Obj → Prop) : Obj → Prop where
  | root {x} : root x → Reach root edge x
  | next {x y} : Reach root edge x → edge x y → Reach root edge y

-- Arbitrary graph and arbitrary young-path length. Every entry into young space
-- is a direct root or an old-to-young boundary; no assumption that old objects are immutable.
theorem youngReachabilityCovered {Obj : Type}
    (root young marked : Obj → Prop) (edge : Obj → Obj → Prop)
    (rootCoverage : ∀ x, root x → young x → marked x)
    (boundaryCoverage : ∀ x y, ¬ young x → edge x y → young y → marked y)
    (youngClosure : ∀ x y, young x → marked x → edge x y → young y → marked y) :
    ∀ y, Reach root edge y → young y → marked y := by
  intro y reach
  induction reach with
  | root r => exact rootCoverage _ r
  | @next x y _ e ih =>
    intro hy
    by_cases hx : young x
    · exact youngClosure x y hx (ih hx) e hy
    · exact boundaryCoverage x y hx e hy

-- Source slots matter: finding the target elsewhere does not relocate an omitted slot.
theorem rememberedSlotsSelected {Slot : Type} (oldYoung dirty selected : Slot → Prop)
    (barrier : ∀ p, oldYoung p → dirty p)
    (snapshot : ∀ p, dirty p → selected p) :
    ∀ p, oldYoung p → selected p := by
  intro p hp
  exact snapshot p (barrier p hp)

theorem fallbackCoversOldSlots {Slot : Type} (old oldYoung selected : Slot → Prop)
    (belongs : ∀ p, oldYoung p → old p)
    (fallback : ∀ p, old p → selected p) :
    ∀ p, oldYoung p → selected p := by
  intro p hp
  exact fallback p (belongs p hp)

-- Nonmoving mature objects can avoid whole-graph minor scans only under these premises.
-- This does not justify skipping explicit roots, weak processing or a major cycle.
theorem minorSurvivorsRetained {Obj : Type}
    (root young marked promoted : Obj → Prop) (edge : Obj → Obj → Prop)
    (rootCoverage : ∀ x, root x → young x → marked x)
    (boundaryCoverage : ∀ x y, ¬ young x → edge x y → young y → marked y)
    (youngClosure : ∀ x y, young x → marked x → edge x y → young y → marked y)
    (evacuate : ∀ x, marked x → promoted x) :
    ∀ x, Reach root edge x → young x → promoted x := by
  intro x reach hx
  exact evacuate x (youngReachabilityCovered root young marked edge rootCoverage boundaryCoverage youngClosure x reach hx)

-- A completed dirty card can be cleared only while writers are excluded and all
-- young references are promoted/rewritten, or the residual card remains dirty.
theorem residualYoungMustRemainRecorded {Slot : Type}
    (residual dirtyAfter : Slot → Prop)
    (rearm : ∀ p, residual p → dirtyAfter p) :
    ∀ p, ¬ dirtyAfter p → ¬ residual p := by
  intro p clean remains
  exact clean (rearm p remains)

#print axioms youngReachabilityCovered
#print axioms rememberedSlotsSelected
#print axioms fallbackCoversOldSlots
#print axioms minorSurvivorsRetained
#print axioms residualYoungMustRemainRecorded
end GambitSMP.GenerationalRootAdmission
#check GambitSMP.RcFreezePublication.issueRequiresFinalValues
#check GambitSMP.RcFreezePublication.issueBindsGeneration
#check GambitSMP.RcFreezePublication.storageLeaseDoesNotBlockFreeze
#check GambitSMP.RcFreezePublication.publicationPrecedesReceipt
#check GambitSMP.RcFreezePublication.collectorCanUpdateFrozenRoots
#check GambitSMP.RcFreezePublication.waitPathIncreases
#check GambitSMP.RcFreezePublication.noRankedWaitCycle
#check GambitSMP.GenerationalRootAdmission.youngReachabilityCovered
#check GambitSMP.GenerationalRootAdmission.rememberedSlotsSelected
#check GambitSMP.GenerationalRootAdmission.fallbackCoversOldSlots
#check GambitSMP.GenerationalRootAdmission.minorSurvivorsRetained
#check GambitSMP.GenerationalRootAdmission.residualYoungMustRemainRecorded
