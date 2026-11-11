import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem gcBeginInvariant (q : State) (h : Safe q) (g : gcBeginGuard q) : Invariant (gcBeginNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem forwardNoCopyInvariant (q : State) (h : Safe q) (g : forwardNoCopyGuard q) : Invariant (forwardNoCopyNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem forwardWithCopyInvariant (q : State) (h : Safe q) (g : forwardWithCopyGuard q) : Invariant (forwardWithCopyNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem gcEndInvariant (q : State) (h : Safe q) (g : gcEndGuard q) : Invariant (gcEndNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
