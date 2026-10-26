import CleanupIngress
open CleanupIngressAst
def witness : State := loseBoundaryNext (requestCloseNext (initial))
example : requestCloseGuard (initial) := by simp [requestCloseGuard,initial]
example : loseBoundaryGuard (requestCloseNext (initial)) := by simp [loseBoundaryGuard,initial,requestCloseNext]
example : Safe witness := by simp [Safe,witness,initial,requestCloseNext,loseBoundaryNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (finishOuterGuard witness) := by simp [Safe,witness,initial,requestCloseNext,loseBoundaryNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : finishOuterGuard witness := by simp [Safe,witness,initial,requestCloseNext,loseBoundaryNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
