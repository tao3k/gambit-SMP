import CleanupIngress
open CleanupIngressAst
def witness : State := joinKnownNext (drainCollectiveNext (finishOuterNext (requestCloseNext (exportResultNext (initial)))))
example : exportResultGuard (initial) := by simp [exportResultGuard,initial]
example : requestCloseGuard (exportResultNext (initial)) := by simp [requestCloseGuard,initial,exportResultNext]
example : finishOuterGuard (requestCloseNext (exportResultNext (initial))) := by simp [finishOuterGuard,initial,exportResultNext,requestCloseNext]
example : drainCollectiveGuard (finishOuterNext (requestCloseNext (exportResultNext (initial)))) := by simp [drainCollectiveGuard,initial,exportResultNext,requestCloseNext,finishOuterNext]
example : joinKnownGuard (drainCollectiveNext (finishOuterNext (requestCloseNext (exportResultNext (initial))))) := by simp [joinKnownGuard,initial,exportResultNext,requestCloseNext,finishOuterNext,drainCollectiveNext]
example : Safe witness := by simp [Safe,witness,initial,exportResultNext,requestCloseNext,finishOuterNext,drainCollectiveNext,joinKnownNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,exportResultNext,requestCloseNext,finishOuterNext,drainCollectiveNext,joinKnownNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
