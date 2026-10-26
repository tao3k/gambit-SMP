import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem grantLocalInvariant (q : State) (h : Safe q) (g : grantLocalGuard q) : Invariant (grantLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem leaveInvariant (q : State) (h : Safe q) (g : leaveGuard q) : Invariant (leaveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem gcEnterInvariant (q : State) (h : Safe q) (g : gcEnterGuard q) : Invariant (gcEnterNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem gcFreezeInvariant (q : State) (h : Safe q) (g : gcFreezeGuard q) : Invariant (gcFreezeNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
