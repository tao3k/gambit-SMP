import WorkAccounting

namespace GambitSMP.SavedStackArenaLifetime

def BackingReady (alive sameEpoch descriptorLive : Bool) : Prop :=
  alive = true ∧ sameEpoch = true ∧ descriptorLive = true

-- Retiring an executor need not retire its VM-owned frame storage.
theorem retiredSlotCanRetainRawFrame :
    ∃ retired slotCleaned rawNeeded : Bool,
      retired = true ∧ slotCleaned = true ∧ rawNeeded = true ∧
      BackingReady true true true := by
  exact ⟨true, true, true, rfl, rfl, rfl, rfl, rfl, rfl⟩

def CanRecycle {Borrower : Type} (needsOldFrame : Borrower → Prop) : Prop :=
  ∀ borrower, ¬ needsOldFrame borrower

-- A break link or escaped alias is a consumer even after thread.cont clears.
theorem movedReferenceStillBlocksReuse {Borrower : Type}
    (needsOldFrame : Borrower → Prop) (borrower : Borrower)
    (needed : needsOldFrame borrower) : ¬ CanRecycle needsOldFrame := by
  intro allGone
  exact allGone borrower needed

theorem allRawBorrowsRequireBacking {Borrower : Type}
    (needsOldFrame : Borrower → Prop) (alive sameEpoch descriptorLive : Bool)
    (backing : BackingReady alive sameEpoch descriptorLive) :
    ∀ borrower, needsOldFrame borrower → BackingReady alive sameEpoch descriptorLive := by
  intro _ _
  exact backing

-- Existing same-generation contract, not a new pointer-identity mechanism.
theorem reusedAddressDoesNotRestoreEpoch (old current : Nat)
    (same : WorkAccounting.SameGeneration old current) :
    ¬ WorkAccounting.SameGeneration old (current + 1) :=
  WorkAccounting.reuseRevokesOldIdentity old current same

-- This quantifies over the supplied complete borrower census. It does not
-- discover an unregistered alias or prove the collector enumerates it.
theorem perBorrowerDischargeAllowsReuse {Borrower : Type}
    (needed copied consumed : Borrower → Prop)
    (closed : ∀ borrower, needed borrower → copied borrower ∨ consumed borrower) :
    CanRecycle (fun borrower => needed borrower ∧ ¬ copied borrower ∧ ¬ consumed borrower) := by
  intro borrower pending
  rcases closed borrower pending.1 with moved | read
  · exact pending.2.1 moved
  · exact pending.2.2 read

#print axioms retiredSlotCanRetainRawFrame
#print axioms movedReferenceStillBlocksReuse
#print axioms allRawBorrowsRequireBacking
#print axioms reusedAddressDoesNotRestoreEpoch
#print axioms perBorrowerDischargeAllowsReuse

end GambitSMP.SavedStackArenaLifetime
