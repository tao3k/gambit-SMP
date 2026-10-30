import ResearchFunnel
open ResearchFunnel

def oldNative : Receipt := ⟨.nativeGate, 1, 0, 0, 0, 0, true, true⟩

-- Must fail even though source and product identities return to zero.
example : Supports (advance (advance emptyState 1 1) 0 0) oldNative 1 := by
  simp [Supports, advance, emptyState, oldNative]
