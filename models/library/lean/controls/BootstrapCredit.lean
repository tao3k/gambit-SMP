import ResearchFunnel
open ResearchFunnel

-- Must fail: a bootstrap receipt cannot close the stress gate.
example : Accepted (append emptyState bootstrapReceipt) 1 := by
  simp [Accepted, Supports, append, emptyState, bootstrapReceipt]
