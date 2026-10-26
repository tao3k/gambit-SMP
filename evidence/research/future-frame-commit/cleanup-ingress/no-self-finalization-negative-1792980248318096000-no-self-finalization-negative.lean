import CleanupIngress
open CleanupIngressAst
def witness : State := requestCloseNext (enterChildNext (reserveChildNext (initial)))
example : reserveChildGuard (initial) := by simp [reserveChildGuard,initial]
example : enterChildGuard (reserveChildNext (initial)) := by simp [enterChildGuard,initial,reserveChildNext]
example : requestCloseGuard (enterChildNext (reserveChildNext (initial))) := by simp [requestCloseGuard,initial,reserveChildNext,enterChildNext]
example : Safe witness := by simp [Safe,witness,initial,reserveChildNext,enterChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (finishOuterGuard witness) := by simp [Safe,witness,initial,reserveChildNext,enterChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : finishOuterGuard witness := by simp [Safe,witness,initial,reserveChildNext,enterChildNext,requestCloseNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
