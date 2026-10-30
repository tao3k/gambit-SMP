import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem allocateProjects (q : State) (g : allocateGuard q) : FrameActivationAst.Step (parent q) (parent (allocateNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inl (?_))
 constructor
 · simp only [allocateGuard] at g
   dsimp only [parent,FrameActivationAst.allocateGuard]
   omega
 · rfl
theorem enterProjects (q : State) (g : enterGuard q) : FrameActivationAst.Step (parent q) (parent (enterNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inl (?_)))
 constructor
 · simp only [enterGuard] at g
   dsimp only [parent,FrameActivationAst.enterGuard]
   omega
 · rfl
theorem resolveProjects (q : State) (g : resolveGuard q) : FrameActivationAst.Step (parent q) (parent (resolveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inl (?_))))
 constructor
 · simp only [resolveGuard] at g
   dsimp only [parent,FrameActivationAst.resolveGuard]
   omega
 · rfl
theorem initializeProjects (q : State) (g : initializeGuard q) : FrameActivationAst.Step (parent q) (parent (initializeNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))
 constructor
 · simp only [initializeGuard] at g
   dsimp only [parent,FrameActivationAst.initializeGuard]
   omega
 · rfl
theorem validateProjects (q : State) (g : validateGuard q) : FrameActivationAst.Step (parent q) (parent (validateNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))
 constructor
 · simp only [validateGuard] at g
   dsimp only [parent,FrameActivationAst.validateGuard]
   omega
 · rfl
theorem prepareProjects (q : State) (g : prepareGuard q) : FrameActivationAst.Step (parent q) (parent (prepareNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))
 constructor
 · simp only [prepareGuard] at g
   dsimp only [parent,FrameActivationAst.prepareGuard]
   omega
 · rfl
theorem sendPublicationProjects (q : State) (g : sendPublicationGuard q) : FrameActivationAst.Step (parent q) (parent (sendPublicationNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))
 constructor
 · simp only [sendPublicationGuard] at g
   dsimp only [parent,FrameActivationAst.sendPublicationGuard]
   omega
 · rfl
theorem publicationUnknownProjects (q : State) (g : publicationUnknownGuard q) : FrameActivationAst.Step (parent q) (parent (publicationUnknownNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))
 constructor
 · simp only [publicationUnknownGuard] at g
   dsimp only [parent,FrameActivationAst.publicationUnknownGuard]
   omega
 · rfl
theorem acceptPublicationProjects (q : State) (g : acceptPublicationGuard q) : FrameActivationAst.Step (parent q) (parent (acceptPublicationNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))
 constructor
 · simp only [acceptPublicationGuard] at g
   dsimp only [parent,FrameActivationAst.acceptPublicationGuard]
   omega
 · rfl
theorem rejectPublicationProjects (q : State) (g : rejectPublicationGuard q) : FrameActivationAst.Step (parent q) (parent (rejectPublicationNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))
 constructor
 · simp only [rejectPublicationGuard] at g
   dsimp only [parent,FrameActivationAst.rejectPublicationGuard]
   omega
 · rfl
theorem activationFailedProjects (q : State) (g : activationFailedGuard q) : FrameActivationAst.Step (parent q) (parent (activationFailedNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))
 constructor
 · simp only [activationFailedGuard] at g
   dsimp only [parent,FrameActivationAst.activationFailedGuard]
   omega
 · rfl
theorem wakeFailedProjects (q : State) (g : wakeFailedGuard q) : FrameActivationAst.Step (parent q) (parent (wakeFailedNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))
 constructor
 · simp only [wakeFailedGuard] at g
   dsimp only [parent,FrameActivationAst.wakeFailedGuard]
   omega
 · rfl
theorem restoreProjects (q : State) (g : restoreGuard q) : FrameActivationAst.Step (parent q) (parent (restoreNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))
 constructor
 · simp only [restoreGuard] at g
   dsimp only [parent,FrameActivationAst.restoreGuard]
   omega
 · rfl
theorem finishAbortedProjects (q : State) (g : finishAbortedGuard q) : FrameActivationAst.Step (parent q) (parent (finishAbortedNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))
 constructor
 · simp only [finishAbortedGuard] at g
   dsimp only [parent,FrameActivationAst.finishAbortedGuard]
   omega
 · rfl
theorem publishResultProjects (q : State) (g : publishResultGuard q) : FrameActivationAst.Step (parent q) (parent (publishResultNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))
 constructor
 · simp only [publishResultGuard] at g
   dsimp only [parent,FrameActivationAst.publishResultGuard]
   omega
 · rfl
theorem runPrefixProjects (q : State) (g : runPrefixGuard q) : FrameActivationAst.Step (parent q) (parent (runPrefixNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))
 constructor
 · simp only [runPrefixGuard] at g
   dsimp only [parent,FrameActivationAst.runPrefixGuard]
   omega
 · rfl
theorem grantLocalProjects (q : State) (g : grantLocalGuard q) : FrameActivationAst.Step (parent q) (parent (grantLocalNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))
 constructor
 · simp only [grantLocalGuard] at g
   dsimp only [parent,FrameActivationAst.grantLocalGuard]
   omega
 · rfl
theorem leaveProjects (q : State) (g : leaveGuard q) : FrameActivationAst.Step (parent q) (parent (leaveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))
 constructor
 · simp only [leaveGuard] at g
   dsimp only [parent,FrameActivationAst.leaveGuard]
   omega
 · rfl
theorem gcEnterProjects (q : State) (g : gcEnterGuard q) : FrameActivationAst.Step (parent q) (parent (gcEnterNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))
 constructor
 · simp only [gcEnterGuard] at g
   dsimp only [parent,FrameActivationAst.gcEnterGuard]
   omega
 · rfl
theorem gcFreezeProjects (q : State) (g : gcFreezeGuard q) : FrameActivationAst.Step (parent q) (parent (gcFreezeNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))
 constructor
 · simp only [gcFreezeGuard] at g
   dsimp only [parent,FrameActivationAst.gcFreezeGuard]
   omega
 · rfl
theorem gcBeginProjects (q : State) (g : gcBeginGuard q) : FrameActivationAst.Step (parent q) (parent (gcBeginNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))
 constructor
 · simp only [gcBeginGuard] at g
   dsimp only [parent,FrameActivationAst.gcBeginGuard]
   omega
 · rfl
theorem forwardNoCopyProjects (q : State) (g : forwardNoCopyGuard q) : FrameActivationAst.Step (parent q) (parent (forwardNoCopyNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))
 constructor
 · simp only [forwardNoCopyGuard] at g
   dsimp only [parent,FrameActivationAst.forwardNoCopyGuard]
   omega
 · rfl
theorem forwardWithCopyProjects (q : State) (g : forwardWithCopyGuard q) : FrameActivationAst.Step (parent q) (parent (forwardWithCopyNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))
 constructor
 · simp only [forwardWithCopyGuard] at g
   dsimp only [parent,FrameActivationAst.forwardWithCopyGuard]
   omega
 · rfl
theorem gcEndProjects (q : State) (g : gcEndGuard q) : FrameActivationAst.Step (parent q) (parent (gcEndNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))
 constructor
 · simp only [gcEndGuard] at g
   dsimp only [parent,FrameActivationAst.gcEndGuard]
   omega
 · rfl
theorem gcLeaveProjects (q : State) (g : gcLeaveGuard q) : FrameActivationAst.Step (parent q) (parent (gcLeaveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))
 constructor
 · simp only [gcLeaveGuard] at g
   dsimp only [parent,FrameActivationAst.gcLeaveGuard]
   omega
 · rfl
theorem closeDomainProjects (q : State) (g : closeDomainGuard q) : FrameActivationAst.Step (parent q) (parent (closeDomainNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))))))))))))))))
 constructor
 · simp only [closeDomainGuard] at g
   dsimp only [parent,FrameActivationAst.closeDomainGuard]
   omega
 · rfl
theorem resetDomainProjects (q : State) (g : resetDomainGuard q) : FrameActivationAst.Step (parent q) (parent (resetDomainNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))))))))))))
 constructor
 · simp only [resetDomainGuard] at g
   dsimp only [parent,FrameActivationAst.resetDomainGuard]
   omega
 · rfl
theorem prepareResultProjects (q : State) (g : prepareResultGuard q) : FrameActivationAst.Step (parent q) (parent (prepareResultNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem loadReserveProjects (q : State) (g : loadReserveGuard q) : FrameActivationAst.Step (parent q) (parent (loadReserveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem loadCommitProjects (q : State) (g : loadCommitGuard q) : FrameActivationAst.Step (parent q) (parent (loadCommitNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem loadAbortProjects (q : State) (g : loadAbortGuard q) : FrameActivationAst.Step (parent q) (parent (loadAbortNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem splitFailureProjects (q : State) (g : splitFailureGuard q) : FrameActivationAst.Step (parent q) (parent (splitFailureNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem casReserveProjects (q : State) (g : casReserveGuard q) : FrameActivationAst.Step (parent q) (parent (casReserveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inl (?_)
 constructor
 · simp only [casReserveGuard] at g
   dsimp only [parent,FrameActivationAst.reserveGuard]
   omega
 · rfl
theorem casCommitProjects (q : State) (g : casCommitGuard q) : FrameActivationAst.Step (parent q) (parent (casCommitNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))
 constructor
 · simp only [casCommitGuard] at g
   dsimp only [parent,FrameActivationAst.commitGuard]
   omega
 · rfl
theorem casAbortProjects (q : State) (g : casAbortGuard q) : FrameActivationAst.Step (parent q) (parent (casAbortNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))))
 constructor
 · simp only [casAbortGuard] at g
   dsimp only [parent,FrameActivationAst.abortGuard]
   omega
 · rfl
theorem loadChildProjects (q : State) (g : loadChildGuard q) : FrameActivationAst.Step (parent q) (parent (loadChildNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem loadLocalProjects (q : State) (g : loadLocalGuard q) : FrameActivationAst.Step (parent q) (parent (loadLocalNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem childFailureProjects (q : State) (g : childFailureGuard q) : FrameActivationAst.Step (parent q) (parent (childFailureNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem casChildLocalProjects (q : State) (g : casChildLocalGuard q) : FrameActivationAst.Step (parent q) (parent (casChildLocalNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))
 constructor
 · simp only [casChildLocalGuard] at g
   dsimp only [parent,FrameActivationAst.doneLocalGuard]
   omega
 · rfl
theorem casChildSplitProjects (q : State) (g : casChildSplitGuard q) : FrameActivationAst.Step (parent q) (parent (casChildSplitNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_)))))))))))))))))))
 constructor
 · simp only [casChildSplitGuard] at g
   dsimp only [parent,FrameActivationAst.doneSplitGuard]
   omega
 · rfl
theorem casCloseLocalProjects (q : State) (g : casCloseLocalGuard q) : FrameActivationAst.Step (parent q) (parent (casCloseLocalNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))
 constructor
 · simp only [casCloseLocalGuard] at g
   dsimp only [parent,FrameActivationAst.closeLocalGuard]
   omega
 · rfl
theorem retirePreparedResultProjects (q : State) (g : retirePreparedResultGuard q) : FrameActivationAst.Step (parent q) (parent (retirePreparedResultNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem acquireCommitProjects (q : State) (g : acquireCommitGuard q) : FrameActivationAst.Step (parent q) (parent (acquireCommitNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem casActivateProjects (q : State) (g : casActivateGuard q) : FrameActivationAst.Step (parent q) (parent (casActivateNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))
 constructor
 · simp only [casActivateGuard] at g
   dsimp only [parent,FrameActivationAst.activateGuard]
   omega
 · rfl
theorem acquireActiveProjects (q : State) (g : acquireActiveGuard q) : FrameActivationAst.Step (parent q) (parent (acquireActiveNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem casDequeueProjects (q : State) (g : casDequeueGuard q) : FrameActivationAst.Step (parent q) (parent (casDequeueNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))
 constructor
 · simp only [casDequeueGuard] at g
   dsimp only [parent,FrameActivationAst.dequeueGuard]
   omega
 · rfl
theorem acquireResultProjects (q : State) (g : acquireResultGuard q) : FrameActivationAst.Step (parent q) (parent (acquireResultNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?_))))))))))))))))))))))))))))))))))))
 rfl
theorem grantRemoteProjects (q : State) (g : grantRemoteGuard q) : FrameActivationAst.Step (parent q) (parent (grantRemoteNext q)) := by
 unfold FrameActivationAst.Step
 refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?_))))))))))))))))))))))))))
 constructor
 · simp only [grantRemoteGuard] at g
   dsimp only [parent,FrameActivationAst.grantRemoteGuard]
   omega
 · rfl
end ControlWord
