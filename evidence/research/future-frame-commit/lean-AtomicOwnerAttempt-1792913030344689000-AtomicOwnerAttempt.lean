import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem gcLeaveInvariant (q : State) (h : Safe q) (g : gcLeaveGuard q) : Invariant (gcLeaveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem closeDomainInvariant (q : State) (h : Safe q) (g : closeDomainGuard q) : Invariant (closeDomainNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem resetDomainInvariant (q : State) (h : Safe q) (g : resetDomainGuard q) : Invariant (resetDomainNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem prepareResultInvariant (q : State) (h : Safe q) (g : prepareResultGuard q) : Invariant (prepareResultNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
