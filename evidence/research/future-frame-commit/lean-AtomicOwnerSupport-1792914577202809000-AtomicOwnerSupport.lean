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
theorem loadReserveInvariant (q : State) (h : Safe q) (g : loadReserveGuard q) : Invariant (loadReserveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadCommitInvariant (q : State) (h : Safe q) (g : loadCommitGuard q) : Invariant (loadCommitNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadAbortInvariant (q : State) (h : Safe q) (g : loadAbortGuard q) : Invariant (loadAbortNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadChildInvariant (q : State) (h : Safe q) (g : loadChildGuard q) : Invariant (loadChildNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadLocalInvariant (q : State) (h : Safe q) (g : loadLocalGuard q) : Invariant (loadLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem retirePreparedResultInvariant (q : State) (h : Safe q) (g : retirePreparedResultGuard q) : Invariant (retirePreparedResultNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
