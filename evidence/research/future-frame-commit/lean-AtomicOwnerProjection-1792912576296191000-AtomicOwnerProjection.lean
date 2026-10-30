import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem allocateProjects (q : State) (g : allocateGuard q) : ControlWordAst.Step (parent q) (parent (allocateNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inl (?_)
 constructor
 · simp only [allocateGuard] at g
   dsimp only [parent,ControlWordAst.allocateGuard]
   omega
 · rfl
theorem enterProjects (q : State) (g : enterGuard q) : ControlWordAst.Step (parent q) (parent (enterNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inl (?_))
 constructor
 · simp only [enterGuard] at g
   dsimp only [parent,ControlWordAst.enterGuard]
   omega
 · rfl
theorem resolveProjects (q : State) (g : resolveGuard q) : ControlWordAst.Step (parent q) (parent (resolveNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inl (?_)))
 constructor
 · simp only [resolveGuard] at g
   dsimp only [parent,ControlWordAst.resolveGuard]
   omega
 · rfl
theorem initializeProjects (q : State) (g : initializeGuard q) : ControlWordAst.Step (parent q) (parent (initializeNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inl (?_))))
 constructor
 · simp only [initializeGuard] at g
   dsimp only [parent,ControlWordAst.initializeGuard]
   omega
 · rfl
theorem validateProjects (q : State) (g : validateGuard q) : ControlWordAst.Step (parent q) (parent (validateNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))
 constructor
 · simp only [validateGuard] at g
   dsimp only [parent,ControlWordAst.validateGuard]
   omega
 · rfl
theorem prepareProjects (q : State) (g : prepareGuard q) : ControlWordAst.Step (parent q) (parent (prepareNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))
 constructor
 · simp only [prepareGuard] at g
   dsimp only [parent,ControlWordAst.prepareGuard]
   omega
 · rfl
theorem sendPublicationProjects (q : State) (g : sendPublicationGuard q) : ControlWordAst.Step (parent q) (parent (sendPublicationNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))
 constructor
 · simp only [sendPublicationGuard] at g
   dsimp only [parent,ControlWordAst.sendPublicationGuard]
   omega
 · rfl
theorem publicationUnknownProjects (q : State) (g : publicationUnknownGuard q) : ControlWordAst.Step (parent q) (parent (publicationUnknownNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))
 constructor
 · simp only [publicationUnknownGuard] at g
   dsimp only [parent,ControlWordAst.publicationUnknownGuard]
   omega
 · rfl
theorem acceptPublicationProjects (q : State) (g : acceptPublicationGuard q) : ControlWordAst.Step (parent q) (parent (acceptPublicationNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))
 constructor
 · simp only [acceptPublicationGuard] at g
   dsimp only [parent,ControlWordAst.acceptPublicationGuard]
   omega
 · rfl
theorem rejectPublicationProjects (q : State) (g : rejectPublicationGuard q) : ControlWordAst.Step (parent q) (parent (rejectPublicationNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))
 constructor
 · simp only [rejectPublicationGuard] at g
   dsimp only [parent,ControlWordAst.rejectPublicationGuard]
   omega
 · rfl
theorem activationFailedProjects (q : State) (g : activationFailedGuard q) : ControlWordAst.Step (parent q) (parent (activationFailedNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))
 constructor
 · simp only [activationFailedGuard] at g
   dsimp only [parent,ControlWordAst.activationFailedGuard]
   omega
 · rfl
theorem wakeFailedProjects (q : State) (g : wakeFailedGuard q) : ControlWordAst.Step (parent q) (parent (wakeFailedNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))
 constructor
 · simp only [wakeFailedGuard] at g
   dsimp only [parent,ControlWordAst.wakeFailedGuard]
   omega
 · rfl
theorem restoreProjects (q : State) (g : restoreGuard q) : ControlWordAst.Step (parent q) (parent (restoreNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))
 constructor
 · simp only [restoreGuard] at g
   dsimp only [parent,ControlWordAst.restoreGuard]
   omega
 · rfl
theorem finishAbortedProjects (q : State) (g : finishAbortedGuard q) : ControlWordAst.Step (parent q) (parent (finishAbortedNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))
 constructor
 · simp only [finishAbortedGuard] at g
   dsimp only [parent,ControlWordAst.finishAbortedGuard]
   omega
 · rfl
theorem publishResultProjects (q : State) (g : publishResultGuard q) : ControlWordAst.Step (parent q) (parent (publishResultNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))
 constructor
 · simp only [publishResultGuard] at g
   dsimp only [parent,ControlWordAst.publishResultGuard]
   omega
 · rfl
theorem runPrefixProjects (q : State) (g : runPrefixGuard q) : ControlWordAst.Step (parent q) (parent (runPrefixNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))
 constructor
 · simp only [runPrefixGuard] at g
   dsimp only [parent,ControlWordAst.runPrefixGuard]
   omega
 · rfl
theorem grantLocalProjects (q : State) (g : grantLocalGuard q) : ControlWordAst.Step (parent q) (parent (grantLocalNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))
 constructor
 · simp only [grantLocalGuard] at g
   dsimp only [parent,ControlWordAst.grantLocalGuard]
   omega
 · rfl
theorem leaveProjects (q : State) (g : leaveGuard q) : ControlWordAst.Step (parent q) (parent (leaveNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))
 constructor
 · simp only [leaveGuard] at g
   dsimp only [parent,ControlWordAst.leaveGuard]
   omega
 · rfl
theorem gcEnterProjects (q : State) (g : gcEnterGuard q) : ControlWordAst.Step (parent q) (parent (gcEnterNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))
 constructor
 · simp only [gcEnterGuard] at g
   dsimp only [parent,ControlWordAst.gcEnterGuard]
   omega
 · rfl
theorem gcFreezeProjects (q : State) (g : gcFreezeGuard q) : ControlWordAst.Step (parent q) (parent (gcFreezeNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))
 constructor
 · simp only [gcFreezeGuard] at g
   dsimp only [parent,ControlWordAst.gcFreezeGuard]
   omega
 · rfl
theorem gcBeginProjects (q : State) (g : gcBeginGuard q) : ControlWordAst.Step (parent q) (parent (gcBeginNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))
 constructor
 · simp only [gcBeginGuard] at g
   dsimp only [parent,ControlWordAst.gcBeginGuard]
   omega
 · rfl
theorem forwardNoCopyProjects (q : State) (g : forwardNoCopyGuard q) : ControlWordAst.Step (parent q) (parent (forwardNoCopyNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))
 constructor
 · simp only [forwardNoCopyGuard] at g
   dsimp only [parent,ControlWordAst.forwardNoCopyGuard]
   omega
 · rfl
theorem forwardWithCopyProjects (q : State) (g : forwardWithCopyGuard q) : ControlWordAst.Step (parent q) (parent (forwardWithCopyNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))
 constructor
 · simp only [forwardWithCopyGuard] at g
   dsimp only [parent,ControlWordAst.forwardWithCopyGuard]
   omega
 · rfl
theorem gcEndProjects (q : State) (g : gcEndGuard q) : ControlWordAst.Step (parent q) (parent (gcEndNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))
 constructor
 · simp only [gcEndGuard] at g
   dsimp only [parent,ControlWordAst.gcEndGuard]
   omega
 · rfl
theorem gcLeaveProjects (q : State) (g : gcLeaveGuard q) : ControlWordAst.Step (parent q) (parent (gcLeaveNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))
 constructor
 · simp only [gcLeaveGuard] at g
   dsimp only [parent,ControlWordAst.gcLeaveGuard]
   omega
 · rfl
theorem closeDomainProjects (q : State) (g : closeDomainGuard q) : ControlWordAst.Step (parent q) (parent (closeDomainNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))
 constructor
 · simp only [closeDomainGuard] at g
   dsimp only [parent,ControlWordAst.closeDomainGuard]
   omega
 · rfl
theorem resetDomainProjects (q : State) (g : resetDomainGuard q) : ControlWordAst.Step (parent q) (parent (resetDomainNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))
 constructor
 · simp only [resetDomainGuard] at g
   dsimp only [parent,ControlWordAst.resetDomainGuard]
   omega
 · rfl
theorem prepareResultProjects (q : State) (g : prepareResultGuard q) : ControlWordAst.Step (parent q) (parent (prepareResultNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))
 constructor
 · simp only [prepareResultGuard] at g
   dsimp only [parent,ControlWordAst.prepareResultGuard]
   omega
 · rfl
theorem loadReserveProjects (q : State) (g : loadReserveGuard q) : ControlWordAst.Step (parent q) (parent (loadReserveNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))
 constructor
 · simp only [loadReserveGuard] at g
   dsimp only [parent,ControlWordAst.loadReserveGuard]
   omega
 · rfl
theorem loadCommitProjects (q : State) (g : loadCommitGuard q) : ControlWordAst.Step (parent q) (parent (loadCommitNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))
 constructor
 · simp only [loadCommitGuard] at g
   dsimp only [parent,ControlWordAst.loadCommitGuard]
   omega
 · rfl
theorem loadAbortProjects (q : State) (g : loadAbortGuard q) : ControlWordAst.Step (parent q) (parent (loadAbortNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))
 constructor
 · simp only [loadAbortGuard] at g
   dsimp only [parent,ControlWordAst.loadAbortGuard]
   omega
 · rfl
theorem casReserveProjects (q : State) (g : casReserveGuard q) : ControlWordAst.Step (parent q) (parent (casReserveNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))
 constructor
 · simp only [casReserveGuard] at g
   dsimp only [parent,ControlWordAst.casReserveGuard]
   omega
 · rfl
theorem casCommitProjects (q : State) (g : casCommitGuard q) : ControlWordAst.Step (parent q) (parent (casCommitNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))
 constructor
 · simp only [casCommitGuard] at g
   dsimp only [parent,ControlWordAst.casCommitGuard]
   omega
 · rfl
theorem casAbortProjects (q : State) (g : casAbortGuard q) : ControlWordAst.Step (parent q) (parent (casAbortNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))
 constructor
 · simp only [casAbortGuard] at g
   dsimp only [parent,ControlWordAst.casAbortGuard]
   omega
 · rfl
theorem loadChildProjects (q : State) (g : loadChildGuard q) : ControlWordAst.Step (parent q) (parent (loadChildNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [loadChildGuard] at g
   dsimp only [parent,ControlWordAst.loadChildGuard]
   omega
 · rfl
theorem loadLocalProjects (q : State) (g : loadLocalGuard q) : ControlWordAst.Step (parent q) (parent (loadLocalNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [loadLocalGuard] at g
   dsimp only [parent,ControlWordAst.loadLocalGuard]
   omega
 · rfl
theorem casChildLocalProjects (q : State) (g : casChildLocalGuard q) : ControlWordAst.Step (parent q) (parent (casChildLocalNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [casChildLocalGuard] at g
   dsimp only [parent,ControlWordAst.casChildLocalGuard]
   omega
 · rfl
theorem casChildSplitProjects (q : State) (g : casChildSplitGuard q) : ControlWordAst.Step (parent q) (parent (casChildSplitNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [casChildSplitGuard] at g
   dsimp only [parent,ControlWordAst.casChildSplitGuard]
   omega
 · rfl
theorem casCloseLocalProjects (q : State) (g : casCloseLocalGuard q) : ControlWordAst.Step (parent q) (parent (casCloseLocalNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [casCloseLocalGuard] at g
   dsimp only [parent,ControlWordAst.casCloseLocalGuard]
   omega
 · rfl
theorem retirePreparedResultProjects (q : State) (g : retirePreparedResultGuard q) : ControlWordAst.Step (parent q) (parent (retirePreparedResultNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [retirePreparedResultGuard] at g
   dsimp only [parent,ControlWordAst.retirePreparedResultGuard]
   omega
 · rfl
theorem splitNativeFailureProjects (q : State) (g : splitNativeFailureGuard q) : ControlWordAst.Step (parent q) (parent (splitNativeFailureNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))
 constructor
 · simp only [splitNativeFailureGuard] at g
   dsimp only [parent,ControlWordAst.splitFailureGuard]
   omega
 · rfl
theorem splitLegacyFailureProjects (q : State) (g : splitLegacyFailureGuard q) : ControlWordAst.Step (parent q) (parent (splitLegacyFailureNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))
 constructor
 · simp only [splitLegacyFailureGuard] at g
   dsimp only [parent,ControlWordAst.splitFailureGuard]
   omega
 · rfl
theorem deliverSplitterProjects (q : State) (g : deliverSplitterGuard q) : ControlWordAst.Step (parent q) (parent (deliverSplitterNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
theorem childNativeFailureProjects (q : State) (g : childNativeFailureGuard q) : ControlWordAst.Step (parent q) (parent (childNativeFailureNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [childNativeFailureGuard] at g
   dsimp only [parent,ControlWordAst.childFailureGuard]
   omega
 · rfl
theorem childLegacyFailureProjects (q : State) (g : childLegacyFailureGuard q) : ControlWordAst.Step (parent q) (parent (childLegacyFailureNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [childLegacyFailureGuard] at g
   dsimp only [parent,ControlWordAst.childFailureGuard]
   omega
 · rfl
theorem deliverChildProjects (q : State) (g : deliverChildGuard q) : ControlWordAst.Step (parent q) (parent (deliverChildNext q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
theorem acquireCommitA0Projects (q : State) (g : acquireCommitA0Guard q) : ControlWordAst.Step (parent q) (parent (acquireCommitA0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireCommitA0Guard] at g
   dsimp only [parent,ControlWordAst.acquireCommitGuard]
   omega
 · rfl
theorem acquireChildA0Projects (q : State) (g : acquireChildA0Guard q) : ControlWordAst.Step (parent q) (parent (acquireChildA0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireChildA0Guard] at g
   dsimp only [parent,ControlWordAst.acquireCommitGuard]
   omega
 · rfl
theorem activateA0Projects (q : State) (g : activateA0Guard q) : ControlWordAst.Step (parent q) (parent (activateA0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [activateA0Guard] at g
   dsimp only [parent,ControlWordAst.casActivateGuard]
   omega
 · rfl
theorem acquireActiveW0Projects (q : State) (g : acquireActiveW0Guard q) : ControlWordAst.Step (parent q) (parent (acquireActiveW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireActiveW0Guard] at g
   dsimp only [parent,ControlWordAst.acquireActiveGuard]
   omega
 · rfl
theorem failedClaimAcquireW0Projects (q : State) (g : failedClaimAcquireW0Guard q) : ControlWordAst.Step (parent q) (parent (failedClaimAcquireW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [failedClaimAcquireW0Guard] at g
   dsimp only [parent,ControlWordAst.acquireActiveGuard]
   omega
 · rfl
theorem claimW0Projects (q : State) (g : claimW0Guard q) : ControlWordAst.Step (parent q) (parent (claimW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [claimW0Guard] at g
   dsimp only [parent,ControlWordAst.casDequeueGuard]
   omega
 · rfl
theorem resultChildW0Projects (q : State) (g : resultChildW0Guard q) : ControlWordAst.Step (parent q) (parent (resultChildW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [resultChildW0Guard] at g
   dsimp only [parent,ControlWordAst.acquireResultGuard]
   omega
 · rfl
theorem resultCommitW0Projects (q : State) (g : resultCommitW0Guard q) : ControlWordAst.Step (parent q) (parent (resultCommitW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [resultCommitW0Guard] at g
   dsimp only [parent,ControlWordAst.acquireResultGuard]
   omega
 · rfl
theorem grantW0Projects (q : State) (g : grantW0Guard q) : ControlWordAst.Step (parent q) (parent (grantW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [grantW0Guard] at g
   dsimp only [parent,ControlWordAst.grantRemoteGuard]
   omega
 · rfl
theorem renewA0Projects (q : State) (g : renewA0Guard q) : ControlWordAst.Step (parent q) (parent (renewA0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
theorem renewW0Projects (q : State) (g : renewW0Guard q) : ControlWordAst.Step (parent q) (parent (renewW0Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
theorem acquireCommitA1Projects (q : State) (g : acquireCommitA1Guard q) : ControlWordAst.Step (parent q) (parent (acquireCommitA1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireCommitA1Guard] at g
   dsimp only [parent,ControlWordAst.acquireCommitGuard]
   omega
 · rfl
theorem acquireChildA1Projects (q : State) (g : acquireChildA1Guard q) : ControlWordAst.Step (parent q) (parent (acquireChildA1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireChildA1Guard] at g
   dsimp only [parent,ControlWordAst.acquireCommitGuard]
   omega
 · rfl
theorem activateA1Projects (q : State) (g : activateA1Guard q) : ControlWordAst.Step (parent q) (parent (activateA1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [activateA1Guard] at g
   dsimp only [parent,ControlWordAst.casActivateGuard]
   omega
 · rfl
theorem acquireActiveW1Projects (q : State) (g : acquireActiveW1Guard q) : ControlWordAst.Step (parent q) (parent (acquireActiveW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [acquireActiveW1Guard] at g
   dsimp only [parent,ControlWordAst.acquireActiveGuard]
   omega
 · rfl
theorem failedClaimAcquireW1Projects (q : State) (g : failedClaimAcquireW1Guard q) : ControlWordAst.Step (parent q) (parent (failedClaimAcquireW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [failedClaimAcquireW1Guard] at g
   dsimp only [parent,ControlWordAst.acquireActiveGuard]
   omega
 · rfl
theorem claimW1Projects (q : State) (g : claimW1Guard q) : ControlWordAst.Step (parent q) (parent (claimW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [claimW1Guard] at g
   dsimp only [parent,ControlWordAst.casDequeueGuard]
   omega
 · rfl
theorem resultChildW1Projects (q : State) (g : resultChildW1Guard q) : ControlWordAst.Step (parent q) (parent (resultChildW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [resultChildW1Guard] at g
   dsimp only [parent,ControlWordAst.acquireResultGuard]
   omega
 · rfl
theorem resultCommitW1Projects (q : State) (g : resultCommitW1Guard q) : ControlWordAst.Step (parent q) (parent (resultCommitW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [resultCommitW1Guard] at g
   dsimp only [parent,ControlWordAst.acquireResultGuard]
   omega
 · rfl
theorem grantW1Projects (q : State) (g : grantW1Guard q) : ControlWordAst.Step (parent q) (parent (grantW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [grantW1Guard] at g
   dsimp only [parent,ControlWordAst.grantRemoteGuard]
   omega
 · rfl
theorem renewA1Projects (q : State) (g : renewA1Guard q) : ControlWordAst.Step (parent q) (parent (renewA1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
theorem renewW1Projects (q : State) (g : renewW1Guard q) : ControlWordAst.Step (parent q) (parent (renewW1Next q)) := by
 unfold ControlWordAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))))))))))))))
 rfl
end AtomicOwner
