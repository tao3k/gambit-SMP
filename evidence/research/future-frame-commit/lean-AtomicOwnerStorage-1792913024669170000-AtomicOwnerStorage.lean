import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem allocateInvariant (q : State) (h : Safe q) (g : allocateGuard q) : Invariant (allocateNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem enterInvariant (q : State) (h : Safe q) (g : enterGuard q) : Invariant (enterNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem resolveInvariant (q : State) (h : Safe q) (g : resolveGuard q) : Invariant (resolveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem initializeInvariant (q : State) (h : Safe q) (g : initializeGuard q) : Invariant (initializeNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
