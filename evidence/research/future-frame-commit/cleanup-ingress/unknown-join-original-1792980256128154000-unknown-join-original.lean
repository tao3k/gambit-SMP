import CleanupIngress
open CleanupIngressAst
def witness : State := joinUnknownNext (drainCollectiveNext (finishOuterNext (requestCloseNext (initial))))
example : requestCloseGuard (initial) := by simp [requestCloseGuard,initial]
example : finishOuterGuard (requestCloseNext (initial)) := by simp [finishOuterGuard,initial,requestCloseNext]
example : drainCollectiveGuard (finishOuterNext (requestCloseNext (initial))) := by simp [drainCollectiveGuard,initial,requestCloseNext,finishOuterNext]
example : joinUnknownGuard (drainCollectiveNext (finishOuterNext (requestCloseNext (initial)))) := by simp [joinUnknownGuard,initial,requestCloseNext,finishOuterNext,drainCollectiveNext]
example : Safe witness := by simp [Safe,witness,initial,requestCloseNext,finishOuterNext,drainCollectiveNext,joinUnknownNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,requestCloseNext,finishOuterNext,drainCollectiveNext,joinUnknownNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
