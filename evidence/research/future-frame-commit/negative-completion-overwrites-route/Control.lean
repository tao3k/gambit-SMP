import ControlWordAst
open ControlWordAst
def witness : State := {initial with n_decision:=1,n_claims:=1,n_done:=0,n_resultRoot:=0,n_sourceRoot:=1,n_destRoot:=0,n_childRoot:=1,n_copyReady:=0,n_copyRev:=0,n_viewRev:=0,n_viewGen:=0,n_viewLease:=0,n_patchReady:=0,n_patchRev:=0,n_patchGen:=0,n_patchLease:=0,n_gate:=0,n_admitted:=1,n_generation:=1,n_grantGen:=0,n_lease:=0,n_revision:=0,n_sourceHeap:=0,n_localGrants:=0,n_remoteGrants:=0,n_copyOps:=0,n_validations:=0,n_probes:=0,p_phase:=1,p_eligible:=1,p_claims:=1,p_probes:=0,p_childRuns:=1,p_childDone:=0,p_sourceRoot:=1,p_copyRoot:=0,p_ready:=0,p_queueRoot:=0,p_restoreRoot:=0,p_contextRoot:=0,p_resultRoot:=0,p_placeholder:=0,p_materialized:=0,p_split:=0,p_parentOwner:=0,p_prefixRuns:=0,p_parentRuns:=0,p_captured:=0,p_captureRoot:=0,p_exited:=0,p_descriptor:=1,p_gcOpen:=1,p_frozen:=0,p_scanning:=0,p_scanned:=0,p_epoch:=1,p_vSource:=0,p_vCopy:=0,p_vQueue:=0,p_vRestore:=0,p_vContext:=0,p_vResult:=0,p_vCapture:=0,p_resultPublished:=0,publication:=0,active:=0,attempts:=0,word:=1,sExpected:=0,sMode:=0,cExpected:=1,cMode:=1,preparedResult:=1,commitRelease:=0,resultRelease:=0,aSeen:=0,aWord:=0,activationWord:=0,activeRelease:=0,carriedCommit:=0,workerSeen:=0,resultSeen:=0,casFailures:=0,wordWins:=1}
example : loadReserveGuard (initial) := by simp [loadReserveGuard,initial]
example : casReserveGuard (loadReserveNext (initial)) := by simp [casReserveGuard,initial,loadReserveNext]
example : prepareResultGuard (casReserveNext (loadReserveNext (initial))) := by simp [prepareResultGuard,initial,loadReserveNext,casReserveNext]
example : loadChildGuard (prepareResultNext (casReserveNext (loadReserveNext (initial)))) := by simp [loadChildGuard,initial,loadReserveNext,casReserveNext,prepareResultNext]
example : witness = loadChildNext (prepareResultNext (casReserveNext (loadReserveNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : casChildSplitGuard witness := by simp [casChildSplitGuard,witness,initial]
example : ¬ (Safe (casChildSplitNext witness)) := by simp [Safe,casChildSplitNext,witness,initial]
example : Safe (casChildSplitNext witness) := by simp [Safe,casChildSplitNext,witness,initial]
