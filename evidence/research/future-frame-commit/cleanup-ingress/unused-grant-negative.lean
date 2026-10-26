import CleanupIngress
open CleanupIngressAst
def witness : State := requestCloseNext (reserveChildNext (initial))
example : reserveChildGuard (initial) := by simp [reserveChildGuard,initial]
example : requestCloseGuard (reserveChildNext (initial)) := by simp [requestCloseGuard,initial,reserveChildNext]
example : Safe witness := by simp [Safe,witness,initial,reserveChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (finishOuterGuard witness) := by simp [Safe,witness,initial,reserveChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : finishOuterGuard witness := by simp [Safe,witness,initial,reserveChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
