import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem validateInvariant (q : State) (h : Safe q) (g : validateGuard q) : Invariant (validateNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem prepareInvariant (q : State) (h : Safe q) (g : prepareGuard q) : Invariant (prepareNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem sendPublicationInvariant (q : State) (h : Safe q) (g : sendPublicationGuard q) : Invariant (sendPublicationNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem publicationUnknownInvariant (q : State) (h : Safe q) (g : publicationUnknownGuard q) : Invariant (publicationUnknownNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
