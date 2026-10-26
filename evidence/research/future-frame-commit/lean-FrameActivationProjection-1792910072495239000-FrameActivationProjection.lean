import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem reserveProjects (q : State) (g : reserveGuard q) :
 FrameCommitAst.Step (native q) (native (reserveNext q)) ∧ LazySplitAst.Step (queue q) (queue (reserveNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inl (?h)
   constructor
   · simp only [reserveGuard] at g
     dsimp only [native,FrameCommitAst.reserveSplitGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inl (?h))
   constructor
   · simp only [reserveGuard] at g
     dsimp only [queue,LazySplitAst.claimSplitGuard]
     omega
   · rfl
theorem allocateProjects (q : State) (g : allocateGuard q) :
 FrameCommitAst.Step (native q) (native (allocateNext q)) ∧ LazySplitAst.Step (queue q) (queue (allocateNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inl (?h))))
   constructor
   · simp only [allocateGuard] at g
     dsimp only [native,FrameCommitAst.allocateRootedCopyGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inl (?h))))
   constructor
   · simp only [allocateGuard] at g
     dsimp only [queue,LazySplitAst.allocateCopyGuard]
     omega
   · rfl
theorem enterProjects (q : State) (g : enterGuard q) :
 FrameCommitAst.Step (native q) (native (enterNext q)) ∧ LazySplitAst.Step (queue q) (queue (enterNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))
   constructor
   · simp only [enterGuard] at g
     dsimp only [native,FrameCommitAst.enterRuntimeGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem resolveProjects (q : State) (g : resolveGuard q) :
 FrameCommitAst.Step (native q) (native (resolveNext q)) ∧ LazySplitAst.Step (queue q) (queue (resolveNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))
   constructor
   · simp only [resolveGuard] at g
     dsimp only [native,FrameCommitAst.resolveCanonicalGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem initializeProjects (q : State) (g : initializeGuard q) :
 FrameCommitAst.Step (native q) (native (initializeNext q)) ∧ LazySplitAst.Step (queue q) (queue (initializeNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))
   constructor
   · simp only [initializeGuard] at g
     dsimp only [native,FrameCommitAst.initializeCopyGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))
   constructor
   · simp only [initializeGuard] at g
     dsimp only [queue,LazySplitAst.initializeCopyGuard]
     omega
   · rfl
theorem validateProjects (q : State) (g : validateGuard q) :
 FrameCommitAst.Step (native q) (native (validateNext q)) ∧ LazySplitAst.Step (queue q) (queue (validateNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))
   constructor
   · simp only [validateGuard] at g
     dsimp only [native,FrameCommitAst.validateCopyGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem prepareProjects (q : State) (g : prepareGuard q) :
 FrameCommitAst.Step (native q) (native (prepareNext q)) ∧ LazySplitAst.Step (queue q) (queue (prepareNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))
   constructor
   · simp only [prepareGuard] at g
     dsimp only [native,FrameCommitAst.prepareReturnGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem sendPublicationProjects (q : State) (g : sendPublicationGuard q) :
 FrameCommitAst.Step (native q) (native (sendPublicationNext q)) ∧ LazySplitAst.Step (queue q) (queue (sendPublicationNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem publicationUnknownProjects (q : State) (g : publicationUnknownGuard q) :
 FrameCommitAst.Step (native q) (native (publicationUnknownNext q)) ∧ LazySplitAst.Step (queue q) (queue (publicationUnknownNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem acceptPublicationProjects (q : State) (g : acceptPublicationGuard q) :
 FrameCommitAst.Step (native q) (native (acceptPublicationNext q)) ∧ LazySplitAst.Step (queue q) (queue (acceptPublicationNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))
   constructor
   · simp only [acceptPublicationGuard] at g
     dsimp only [queue,LazySplitAst.publishReadyGuard]
     omega
   · rfl
theorem rejectPublicationProjects (q : State) (g : rejectPublicationGuard q) :
 FrameCommitAst.Step (native q) (native (rejectPublicationNext q)) ∧ LazySplitAst.Step (queue q) (queue (rejectPublicationNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem commitProjects (q : State) (g : commitGuard q) :
 FrameCommitAst.Step (native q) (native (commitNext q)) ∧ LazySplitAst.Step (queue q) (queue (commitNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))
   constructor
   · simp only [commitGuard] at g
     dsimp only [native,FrameCommitAst.commitSplitGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))
   constructor
   · simp only [commitGuard] at g
     dsimp only [queue,LazySplitAst.commitSplitGuard]
     omega
   · rfl
theorem activationFailedProjects (q : State) (g : activationFailedGuard q) :
 FrameCommitAst.Step (native q) (native (activationFailedNext q)) ∧ LazySplitAst.Step (queue q) (queue (activationFailedNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem activateProjects (q : State) (g : activateGuard q) :
 FrameCommitAst.Step (native q) (native (activateNext q)) ∧ LazySplitAst.Step (queue q) (queue (activateNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem wakeFailedProjects (q : State) (g : wakeFailedGuard q) :
 FrameCommitAst.Step (native q) (native (wakeFailedNext q)) ∧ LazySplitAst.Step (queue q) (queue (wakeFailedNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem dequeueProjects (q : State) (g : dequeueGuard q) :
 FrameCommitAst.Step (native q) (native (dequeueNext q)) ∧ LazySplitAst.Step (queue q) (queue (dequeueNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))
   constructor
   · simp only [dequeueGuard] at g
     dsimp only [queue,LazySplitAst.dequeueParentGuard]
     omega
   · rfl
theorem restoreProjects (q : State) (g : restoreGuard q) :
 FrameCommitAst.Step (native q) (native (restoreNext q)) ∧ LazySplitAst.Step (queue q) (queue (restoreNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))
   constructor
   · simp only [restoreGuard] at g
     dsimp only [queue,LazySplitAst.restoreParentGuard]
     omega
   · rfl
theorem doneLocalProjects (q : State) (g : doneLocalGuard q) :
 FrameCommitAst.Step (native q) (native (doneLocalNext q)) ∧ LazySplitAst.Step (queue q) (queue (doneLocalNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inl (?h))
   constructor
   · simp only [doneLocalGuard] at g
     dsimp only [native,FrameCommitAst.childDoneGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))
   constructor
   · simp only [doneLocalGuard] at g
     dsimp only [queue,LazySplitAst.localChildDoneGuard]
     omega
   · rfl
theorem doneSplitProjects (q : State) (g : doneSplitGuard q) :
 FrameCommitAst.Step (native q) (native (doneSplitNext q)) ∧ LazySplitAst.Step (queue q) (queue (doneSplitNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inl (?h))
   constructor
   · simp only [doneSplitGuard] at g
     dsimp only [native,FrameCommitAst.childDoneGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))
   constructor
   · simp only [doneSplitGuard] at g
     dsimp only [queue,LazySplitAst.childDoneInSplitGuard]
     omega
   · rfl
theorem closeLocalProjects (q : State) (g : closeLocalGuard q) :
 FrameCommitAst.Step (native q) (native (closeLocalNext q)) ∧ LazySplitAst.Step (queue q) (queue (closeLocalNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inl (?h)))
   constructor
   · simp only [closeLocalGuard] at g
     dsimp only [native,FrameCommitAst.closeLocalGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem abortProjects (q : State) (g : abortGuard q) :
 FrameCommitAst.Step (native q) (native (abortNext q)) ∧ LazySplitAst.Step (queue q) (queue (abortNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))
   constructor
   · simp only [abortGuard] at g
     dsimp only [native,FrameCommitAst.abortSplitGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))
   constructor
   · simp only [abortGuard] at g
     dsimp only [queue,LazySplitAst.abortPrivateGuard]
     omega
   · rfl
theorem finishAbortedProjects (q : State) (g : finishAbortedGuard q) :
 FrameCommitAst.Step (native q) (native (finishAbortedNext q)) ∧ LazySplitAst.Step (queue q) (queue (finishAbortedNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))
   constructor
   · simp only [finishAbortedGuard] at g
     dsimp only [queue,LazySplitAst.localAfterAbortDoneGuard]
     omega
   · rfl
theorem publishResultProjects (q : State) (g : publishResultGuard q) :
 FrameCommitAst.Step (native q) (native (publishResultNext q)) ∧ LazySplitAst.Step (queue q) (queue (publishResultNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))
   constructor
   · simp only [publishResultGuard] at g
     dsimp only [queue,LazySplitAst.publishResultGuard]
     omega
   · rfl
theorem runPrefixProjects (q : State) (g : runPrefixGuard q) :
 FrameCommitAst.Step (native q) (native (runPrefixNext q)) ∧ LazySplitAst.Step (queue q) (queue (runPrefixNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))
   constructor
   · simp only [runPrefixGuard] at g
     dsimp only [queue,LazySplitAst.runParentPrefixGuard]
     omega
   · rfl
theorem grantLocalProjects (q : State) (g : grantLocalGuard q) :
 FrameCommitAst.Step (native q) (native (grantLocalNext q)) ∧ LazySplitAst.Step (queue q) (queue (grantLocalNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))
   constructor
   · simp only [grantLocalGuard] at g
     dsimp only [native,FrameCommitAst.grantLocalGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))))
   constructor
   · simp only [grantLocalGuard] at g
     dsimp only [queue,LazySplitAst.runLocalParentGuard]
     omega
   · rfl
theorem grantRemoteProjects (q : State) (g : grantRemoteGuard q) :
 FrameCommitAst.Step (native q) (native (grantRemoteNext q)) ∧ LazySplitAst.Step (queue q) (queue (grantRemoteNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))
   constructor
   · simp only [grantRemoteGuard] at g
     dsimp only [native,FrameCommitAst.grantRemoteGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))
   constructor
   · simp only [grantRemoteGuard] at g
     dsimp only [queue,LazySplitAst.consumeSplitResultGuard]
     omega
   · rfl
theorem leaveProjects (q : State) (g : leaveGuard q) :
 FrameCommitAst.Step (native q) (native (leaveNext q)) ∧ LazySplitAst.Step (queue q) (queue (leaveNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))
   constructor
   · simp only [leaveGuard] at g
     dsimp only [native,FrameCommitAst.leaveRuntimeGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem gcEnterProjects (q : State) (g : gcEnterGuard q) :
 FrameCommitAst.Step (native q) (native (gcEnterNext q)) ∧ LazySplitAst.Step (queue q) (queue (gcEnterNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))
   constructor
   · simp only [gcEnterGuard] at g
     dsimp only [native,FrameCommitAst.enterGcGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))))))))))
   constructor
   · simp only [gcEnterGuard] at g
     dsimp only [queue,LazySplitAst.closeGcGuard]
     omega
   · rfl
theorem gcFreezeProjects (q : State) (g : gcFreezeGuard q) :
 FrameCommitAst.Step (native q) (native (gcFreezeNext q)) ∧ LazySplitAst.Step (queue q) (queue (gcFreezeNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))))))))))))
   constructor
   · simp only [gcFreezeGuard] at g
     dsimp only [queue,LazySplitAst.freezeRootsGuard]
     omega
   · rfl
theorem gcBeginProjects (q : State) (g : gcBeginGuard q) :
 FrameCommitAst.Step (native q) (native (gcBeginNext q)) ∧ LazySplitAst.Step (queue q) (queue (gcBeginNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))))))))))))
   constructor
   · simp only [gcBeginGuard] at g
     dsimp only [queue,LazySplitAst.beginScanGuard]
     omega
   · rfl
theorem forwardNoCopyProjects (q : State) (g : forwardNoCopyGuard q) :
 FrameCommitAst.Step (native q) (native (forwardNoCopyNext q)) ∧ LazySplitAst.Step (queue q) (queue (forwardNoCopyNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))
   constructor
   · simp only [forwardNoCopyGuard] at g
     dsimp only [native,FrameCommitAst.forwardNoCopyGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem forwardWithCopyProjects (q : State) (g : forwardWithCopyGuard q) :
 FrameCommitAst.Step (native q) (native (forwardWithCopyNext q)) ∧ LazySplitAst.Step (queue q) (queue (forwardWithCopyNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))))
   constructor
   · simp only [forwardWithCopyGuard] at g
     dsimp only [native,FrameCommitAst.forwardWithCopyGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem gcEndProjects (q : State) (g : gcEndGuard q) :
 FrameCommitAst.Step (native q) (native (gcEndNext q)) ∧ LazySplitAst.Step (queue q) (queue (gcEndNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h)))))))))))))))))))))
   rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))))))))))))))
   constructor
   · simp only [gcEndGuard] at g
     dsimp only [queue,LazySplitAst.endScanGuard]
     omega
   · rfl
theorem gcLeaveProjects (q : State) (g : gcLeaveGuard q) :
 FrameCommitAst.Step (native q) (native (gcLeaveNext q)) ∧ LazySplitAst.Step (queue q) (queue (gcLeaveNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))))
   constructor
   · simp only [gcLeaveGuard] at g
     dsimp only [native,FrameCommitAst.leaveGcGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))))))))))))))
   constructor
   · simp only [gcLeaveGuard] at g
     dsimp only [queue,LazySplitAst.resumeGcGuard]
     omega
   · rfl
theorem closeDomainProjects (q : State) (g : closeDomainGuard q) :
 FrameCommitAst.Step (native q) (native (closeDomainNext q)) ∧ LazySplitAst.Step (queue q) (queue (closeDomainNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h)))))))))))))))))))
   constructor
   · simp only [closeDomainGuard] at g
     dsimp only [native,FrameCommitAst.closeDomainGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
theorem resetDomainProjects (q : State) (g : resetDomainGuard q) :
 FrameCommitAst.Step (native q) (native (resetDomainNext q)) ∧ LazySplitAst.Step (queue q) (queue (resetDomainNext q)) := by
 constructor
 · unfold FrameCommitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (?h))))))))))))))))))))
   constructor
   · simp only [resetDomainGuard] at g
     dsimp only [native,FrameCommitAst.resetDomainGuard]
     omega
   · rfl
 · unfold LazySplitAst.Step
   refine Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (?h))))))))))))))))))))))))))))
   rfl
end FrameActivation
