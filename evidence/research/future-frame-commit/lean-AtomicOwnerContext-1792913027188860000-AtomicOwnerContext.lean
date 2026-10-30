import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem restoreInvariant (q : State) (h : Safe q) (g : restoreGuard q) : Invariant (restoreNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem finishAbortedInvariant (q : State) (h : Safe q) (g : finishAbortedGuard q) : Invariant (finishAbortedNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem publishResultInvariant (q : State) (h : Safe q) (g : publishResultGuard q) : Invariant (publishResultNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem runPrefixInvariant (q : State) (h : Safe q) (g : runPrefixGuard q) : Invariant (runPrefixNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
