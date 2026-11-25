import Lean

namespace NumericHostSpan

-- Word arithmetic only. C must refine these values with checked integer
-- operations before constructing a pointer or writing a heap header.
theorem roundedPayload32 (bytes : Nat) : bytes ≤ ((bytes + 3) / 4) * 4 := by
  omega

theorem roundedPayload64 (bytes : Nat) : bytes ≤ ((bytes + 7) / 8) * 8 := by
  omega

-- The 32-bit word / 64-bit digit branch rounds (body + 1) down
-- to a two-word boundary. The aligned body advances by at most one word.
theorem alignedBody32 (body : Nat) :
    body ≤ ((body + 1) / 2) * 2 ∧ ((body + 1) / 2) * 2 ≤ body + 1 := by
  omega

theorem footprintInside (lo hp hi padding header payload reserve : Nat)
    (cursor : lo ≤ hp) (current : hp ≤ hi)
    (fit : reserve ≤ hi - hp) (extent : padding + header + payload ≤ reserve) :
    lo ≤ hp + padding ∧ hp + padding + header + payload ≤ hi := by
  omega

theorem shortByOneRejects (capacity demand : Nat) (short : capacity + 1 = demand) :
    ¬ demand ≤ capacity := by
  omega

-- A backing half is an upper envelope, not the heap allocation extent.
-- The existing half-end test may admit a write at the heap's exclusive end.
theorem halfRoomDoesNotImplyHeapRoom (hp heapEnd halfEnd : Nat)
    (cursor : hp = heapEnd) (shared : heapEnd < halfEnd) :
    1 ≤ halfEnd - hp ∧ ¬ 1 ≤ heapEnd - hp := by
  omega

end NumericHostSpan
