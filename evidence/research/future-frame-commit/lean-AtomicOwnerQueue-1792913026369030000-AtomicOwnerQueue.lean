import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem acceptPublicationInvariant (q : State) (h : Safe q) (g : acceptPublicationGuard q) : Invariant (acceptPublicationNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem rejectPublicationInvariant (q : State) (h : Safe q) (g : rejectPublicationGuard q) : Invariant (rejectPublicationNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem activationFailedInvariant (q : State) (h : Safe q) (g : activationFailedGuard q) : Invariant (activationFailedNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem wakeFailedInvariant (q : State) (h : Safe q) (g : wakeFailedGuard q) : Invariant (wakeFailedNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
