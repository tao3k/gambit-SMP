import Std
namespace Gambit.VMResizeTransaction
def Covered (capacity assigned pending resume : Nat) : Prop :=
  assigned + 2 * pending + resume ≤ capacity
theorem grantFloor (assigned pending resume : Nat) :
    Covered (assigned+2*pending+resume) assigned pending resume := by
  exact Nat.le_refl _
theorem consumePair (capacity assigned pending resume : Nat)
    (h : Covered capacity assigned (pending+1) resume) :
    Covered capacity (assigned+2) pending resume := by
  unfold Covered at *; omega
def Complete (required actual : Nat → Prop) : Prop := ∀ i, required i → actual i
theorem publishRequiresEveryCreate (required initialized created : Nat → Prop)
    (_ : Complete required initialized) (h : Complete required created) :
    ∀ i, required i → created i := h
theorem publishRequiresEveryInitialization (required initialized created : Nat → Prop)
    (h : Complete required initialized) (_ : Complete required created) :
    ∀ i, required i → initialized i := h
theorem noNewMemberWithoutCreate (old added created : Nat → Prop)
    (h : Complete added created) (i : Nat)
    (member : old i ∨ added i) (fresh : ¬old i) : created i := by
  cases member with
  | inl hOld => exact False.elim (fresh hOld)
  | inr hNew => exact h i hNew
def RefundAllowed (unknown : Bool) (created joined : Nat → Prop) : Prop :=
  unknown = false ∧ Complete created joined
theorem refundRequiresQuiescence (unknown : Bool) (created joined : Nat → Prop)
    (h : RefundAllowed unknown created joined) : Complete created joined := h.2
theorem unknownPreventsRefund (created joined : Nat → Prop) :
    ¬RefundAllowed true created joined := by
  intro h; cases h.1
theorem parkedRootsCoverEntry (required initialized rooted : Nat → Prop)
    (h : Complete initialized rooted) (c : Complete required initialized) :
    Complete required rooted := by
  intro i hi; exact h i (c i hi)
theorem oldSixSectionsInsufficient : ¬Covered 6 2 10 0 := by
  unfold Covered; omega
def ResumeReady (capacity assigned overflow fudge : Nat) : Prop :=
  assigned*131072 + overflow + 4*fudge ≤ capacity*131072
theorem freeHeadroomCoversBudget (capacity assigned reserve overflow fudge : Nat)
    (regions : assigned+reserve ≤ capacity)
    (rounding : overflow+4*fudge ≤ reserve*131072) :
    ResumeReady capacity assigned overflow fudge := by
  unfold ResumeReady; omega
theorem stackSubdivisionCoversFudge (free fudge : Nat) (h : 4*fudge ≤ free) :
    fudge ≤ (free/2)/2 := by omega
theorem chargingAllCapacityLosesBudget (assigned overflow fudge : Nat)
    (positive : 0 < overflow) : ¬ ResumeReady assigned assigned overflow fudge := by
  unfold ResumeReady; omega
-- Actual C barriers, physical list/allocator correspondence, raw native writer
-- exclusion, still transfer and owner-stop receipts are refinement premises.
end Gambit.VMResizeTransaction
