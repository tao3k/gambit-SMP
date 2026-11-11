import CleanupIngress
open CleanupIngressAst
def witness : State := finishOuterNext (requestCloseNext (initial))
example : requestCloseGuard (initial) := by simp [requestCloseGuard,initial]
example : finishOuterGuard (requestCloseNext (initial)) := by simp [finishOuterGuard,initial,requestCloseNext]
example : Safe witness := by simp [Safe,witness,initial,requestCloseNext,finishOuterNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (finishOuterGuard witness) := by simp [Safe,witness,initial,requestCloseNext,finishOuterNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : finishOuterGuard witness := by simp [Safe,witness,initial,requestCloseNext,finishOuterNext,reserveChildGuard,enterChildGuard,returnChildGuard,cancelPermitGuard,requestCloseGuard,loseBoundaryGuard,recoverLandingGuard,exportResultGuard,releaseResultGuard,finishOuterGuard,drainCollectiveGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
