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
