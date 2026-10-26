import FrameActivationAst
open FrameActivationAst
def witness : State := {initial with n_decision:=1,n_claims:=1,n_done:=0,n_resultRoot:=0,n_sourceRoot:=1,n_destRoot:=1,n_childRoot:=1,n_copyReady:=1,n_copyRev:=0,n_viewRev:=0,n_viewGen:=1,n_viewLease:=1,n_patchReady:=1,n_patchRev:=0,n_patchGen:=1,n_patchLease:=1,n_gate:=1,n_admitted:=1,n_generation:=1,n_grantGen:=1,n_lease:=1,n_revision:=0,n_sourceHeap:=0,n_localGrants:=0,n_remoteGrants:=0,n_copyOps:=1,n_validations:=1,n_probes:=0,p_phase:=2,p_eligible:=1,p_claims:=1,p_probes:=0,p_childRuns:=1,p_childDone:=0,p_sourceRoot:=1,p_copyRoot:=1,p_ready:=1,p_queueRoot:=0,p_restoreRoot:=0,p_contextRoot:=0,p_resultRoot:=0,p_placeholder:=1,p_materialized:=1,p_split:=0,p_parentOwner:=0,p_prefixRuns:=0,p_parentRuns:=0,p_captured:=0,p_captureRoot:=0,p_exited:=0,p_descriptor:=1,p_gcOpen:=1,p_frozen:=0,p_scanning:=0,p_scanned:=0,p_epoch:=1,p_vSource:=0,p_vCopy:=0,p_vQueue:=0,p_vRestore:=0,p_vContext:=0,p_vResult:=0,p_vCapture:=0,p_resultPublished:=0,publication:=1,active:=0,attempts:=0}
example : reserveGuard (initial) := by simp [reserveGuard,initial]
example : allocateGuard (reserveNext (initial)) := by simp [allocateGuard,initial,reserveNext]
example : enterGuard (allocateNext (reserveNext (initial))) := by simp [enterGuard,initial,reserveNext,allocateNext]
example : resolveGuard (enterNext (allocateNext (reserveNext (initial)))) := by simp [resolveGuard,initial,reserveNext,allocateNext,enterNext]
example : initializeGuard (resolveNext (enterNext (allocateNext (reserveNext (initial))))) := by simp [initializeGuard,initial,reserveNext,allocateNext,enterNext,resolveNext]
example : validateGuard (initializeNext (resolveNext (enterNext (allocateNext (reserveNext (initial)))))) := by simp [validateGuard,initial,reserveNext,allocateNext,enterNext,resolveNext,initializeNext]
example : prepareGuard (validateNext (initializeNext (resolveNext (enterNext (allocateNext (reserveNext (initial))))))) := by simp [prepareGuard,initial,reserveNext,allocateNext,enterNext,resolveNext,initializeNext,validateNext]
example : sendPublicationGuard (prepareNext (validateNext (initializeNext (resolveNext (enterNext (allocateNext (reserveNext (initial)))))))) := by simp [sendPublicationGuard,initial,reserveNext,allocateNext,enterNext,resolveNext,initializeNext,validateNext,prepareNext]
example : witness = sendPublicationNext (prepareNext (validateNext (initializeNext (resolveNext (enterNext (allocateNext (reserveNext (initial)))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
