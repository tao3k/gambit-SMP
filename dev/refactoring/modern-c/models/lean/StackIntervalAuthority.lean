import FrameContract

namespace Gambit.FrameContract

-- The lower-bound fallback accepts the last case although the cursor is
-- beyond the owned interval. These are offsets, not C pointer expressions.
theorem stackFloorFallbackDoesNotAuthorizeSpill :
    stackRange 8 16 16 8 ∧ ¬ stackRange 8 16 16 9 ∧
      ¬ stackRange 16 24 17 9 ∧ 8 + 9 ≤ (17 : Nat) ∧ ¬ stackRange 8 16 17 9 := by
  simp [stackRange]

end Gambit.FrameContract
