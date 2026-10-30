import Std
namespace Gambit.RoundCapacity
theorem disjointGrantCoversRequest (lo first past hi requested : Nat)
    (left : lo ≤ first) (right : past ≤ hi) (size : first + requested ≤ past) :
    lo ≤ first ∧ first + requested ≤ hi := by omega
theorem cancelDoesNotRefundSectionWaste (reserved cancelled committed active waste : Nat)
    (h : reserved = cancelled + committed + active) :
    reserved + waste = (cancelled + active) + committed + waste := by omega
theorem aggregateWordsDoNotImplyContiguousGrant :
    ∃ left right request : Nat,
      request ≤ left + right ∧ ¬(request ≤ left ∨ request ≤ right) := by
  exact ⟨3, 3, 4, by decide, by decide⟩
theorem allIntervalsBeforeFlip (flip plan : Bool)
    (gate : flip = true → plan = true) (h : flip = true) : plan = true := gate h
-- Layout validity is a premise; this does not derive it from C counters,
-- current source census, allocator callbacks, or an implemented planner.
end Gambit.RoundCapacity
namespace Gambit.RoundCapacity
theorem frameCopyFitsSourceExtent (fs extent : Nat)
    (physicalFrame : fs + 3 ≤ extent) : fs + 2 ≤ extent := by omega
theorem sectionPackingBound (used workers exhausted source gain : Nat)
    (positive : 0 < gain) (tails : used ≤ workers + exhausted)
    (charge : exhausted * gain ≤ source) : used ≤ workers + source / gain := by
  have h : exhausted ≤ source / gain := (Nat.le_div_iff_mul_le positive).2 charge
  omega
theorem selectedProfileGain :
    65536 - 16395 - 4 - ((65536 + 255 - 1) / 255) = 48879 := by decide
end Gambit.RoundCapacity

namespace Gambit.RoundCapacity
-- QNT owns request/worker schedules. These are only the integer implications
-- used by the physical-prefix certificate; C supplies the charging premises.
theorem classedCopyPrefix (used smallClosed workers large budget gain : Nat)
    (positive : 0 < gain)
    (frontiers : used ≤ smallClosed + workers + 2 * large)
    (charge : smallClosed * gain ≤ budget) :
    used ≤ workers + 2 * large + budget / gain := by
  exact sectionPackingBound used (workers + 2 * large) smallClosed budget gain
    positive (by omega) charge

theorem independentRestorePrefix (roots copy used pool : Nat)
    (sealed : roots + copy ≤ pool) (copyBound : used ≤ copy) :
    roots + used ≤ pool := by omega

theorem copyTipRetainsExecutionFudge (tip copyLimit physicalLimit fudge : Nat)
    (thresholdMarker : tip ≤ copyLimit + 1)
    (separated : copyLimit + fudge + 1 ≤ physicalLimit) :
    tip + fudge ≤ physicalLimit := by omega
end Gambit.RoundCapacity

namespace Gambit.RoundCapacity
-- This supplies only integer composition. Actual adjacent-bin pair charging
-- and the at-most-twice premise come from the C no-fit/refill protocol.
theorem adjacentCopyPrefix (used closed workers large budget capacity : Nat)
    (positive : 0 < capacity)
    (frontiers : used ≤ closed + workers + 2 * large)
    (pairCharge : closed * capacity ≤ 2 * budget) :
    used ≤ workers + 2 * large + 2 * budget / capacity := by
  exact sectionPackingBound used (workers + 2 * large) closed (2 * budget) capacity
    positive (by omega) pairCharge

theorem combineCopyCertificates (used base first second : Nat)
    (a : used ≤ base + first) (b : used ≤ base + second) :
    used ≤ base + min first second := by omega
end Gambit.RoundCapacity
