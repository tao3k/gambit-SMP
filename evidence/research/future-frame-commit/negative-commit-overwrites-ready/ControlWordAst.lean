import Std
namespace ControlWordAst
set_option maxRecDepth 10000
structure State where
 n_decision : Int
 n_claims : Int
 n_done : Int
 n_resultRoot : Int
 n_sourceRoot : Int
 n_destRoot : Int
 n_childRoot : Int
 n_copyReady : Int
 n_copyRev : Int
 n_viewRev : Int
 n_viewGen : Int
 n_viewLease : Int
 n_patchReady : Int
 n_patchRev : Int
 n_patchGen : Int
 n_patchLease : Int
 n_gate : Int
 n_admitted : Int
 n_generation : Int
 n_grantGen : Int
 n_lease : Int
 n_revision : Int
 n_sourceHeap : Int
 n_localGrants : Int
 n_remoteGrants : Int
 n_copyOps : Int
 n_validations : Int
 n_probes : Int
 p_phase : Int
 p_eligible : Int
 p_claims : Int
 p_probes : Int
 p_childRuns : Int
 p_childDone : Int
 p_sourceRoot : Int
 p_copyRoot : Int
 p_ready : Int
 p_queueRoot : Int
 p_restoreRoot : Int
 p_contextRoot : Int
 p_resultRoot : Int
 p_placeholder : Int
 p_materialized : Int
 p_split : Int
 p_parentOwner : Int
 p_prefixRuns : Int
 p_parentRuns : Int
 p_captured : Int
 p_captureRoot : Int
 p_exited : Int
 p_descriptor : Int
 p_gcOpen : Int
 p_frozen : Int
 p_scanning : Int
 p_scanned : Int
 p_epoch : Int
 p_vSource : Int
 p_vCopy : Int
 p_vQueue : Int
 p_vRestore : Int
 p_vContext : Int
 p_vResult : Int
 p_vCapture : Int
 p_resultPublished : Int
 publication : Int
 active : Int
 attempts : Int
 word : Int
 sExpected : Int
 sMode : Int
 cExpected : Int
 cMode : Int
 preparedResult : Int
 commitRelease : Int
 resultRelease : Int
 aSeen : Int
 aWord : Int
 activationWord : Int
 activeRelease : Int
 carriedCommit : Int
 workerSeen : Int
 resultSeen : Int
 casFailures : Int
 wordWins : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((((q.n_decision≥(0)) ∧ (q.n_decision≤(3)) ∧ (q.n_claims≥(0)) ∧ (q.n_claims≤(1)) ∧ (q.n_done≥(0)) ∧ (q.n_done≤(1)) ∧ (q.n_resultRoot≥(0)) ∧ (q.n_resultRoot≤(1)) ∧ (q.n_sourceRoot≥(0)) ∧ (q.n_sourceRoot≤(1)) ∧ (q.n_destRoot≥(0)) ∧ (q.n_destRoot≤(1)) ∧ (q.n_childRoot≥(0)) ∧ (q.n_childRoot≤(1)) ∧ (q.n_copyReady≥(0)) ∧ (q.n_copyReady≤(1)) ∧ (q.n_copyRev≥(0)) ∧ (q.n_viewRev≥(0)) ∧ (q.n_viewGen≥(0)) ∧ (q.n_viewLease≥(0)) ∧ (q.n_patchReady≥(0)) ∧ (q.n_patchReady≤(1)) ∧ (q.n_patchRev≥(0)) ∧ (q.n_patchGen≥(0)) ∧ (q.n_patchLease≥(0)) ∧ (q.n_gate≥(0)) ∧ (q.n_gate≤(2)) ∧ (q.n_admitted≥(0)) ∧ (q.n_admitted≤(1)) ∧ (q.n_generation≥(0)) ∧ (q.n_grantGen≥(0)) ∧ (q.n_lease≥(0)) ∧ (q.n_revision≥(0)) ∧ (q.n_sourceHeap≥(0)) ∧ (q.n_sourceHeap≤(1)) ∧ (q.n_localGrants≥(0)) ∧ (q.n_localGrants≤(1)) ∧ (q.n_remoteGrants≥(0)) ∧ (q.n_remoteGrants≤(1)) ∧ (q.n_copyOps≥(0)) ∧ (q.n_validations≥(0)) ∧ (q.n_probes≥(0)) ∧ (q.n_copyOps≤(1)) ∧ ((q.n_copyOps=(1)) → ((q.n_copyReady=(1)) ∨ (q.n_decision=(3)))) ∧ (q.n_generation≥(1)) ∧ (q.n_viewRev≤q.n_revision) ∧ (q.n_copyRev≤q.n_revision) ∧ (q.n_patchRev≤q.n_revision) ∧ (q.n_viewGen≤q.n_generation) ∧ (q.n_patchGen≤q.n_generation) ∧ (q.n_grantGen≤q.n_generation) ∧ (q.n_viewLease≤q.n_lease) ∧ (q.n_patchLease≤q.n_lease) ∧ (q.n_childRoot=(1)) ∧ ((q.n_sourceRoot+q.n_destRoot)≥(1)) ∧ ((q.n_localGrants+q.n_remoteGrants)≤(1)) ∧ ((q.n_done=(1)) → (q.n_resultRoot=(1))) ∧ ((q.n_resultRoot=(1)) → (q.n_done=(1))) ∧ ((q.n_decision=(0)) → ((((((q.n_claims=(0)) ∧ (q.n_sourceRoot=(1))) ∧ (q.n_destRoot=(0))) ∧ (q.n_copyReady=(0))) ∧ (q.n_localGrants=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_decision=(1)) → ((((q.n_claims=(1)) ∧ (q.n_sourceRoot=(1))) ∧ (q.n_localGrants=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_decision=(2)) → (((((q.n_claims=(1)) ∧ (q.n_sourceRoot=(0))) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyReady=(1))) ∧ (q.n_localGrants=(0)))) ∧ ((q.n_decision=(3)) → ((((q.n_sourceRoot=(1)) ∧ (q.n_destRoot=(0))) ∧ (q.n_copyReady=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_copyReady=(1)) → (((q.n_destRoot=(1)) ∧ ((q.n_decision=(1)) ∨ (q.n_decision=(2)))) ∧ (q.n_copyRev=q.n_revision))) ∧ ((q.n_destRoot=(1)) → ((q.n_claims=(1)) ∧ ((q.n_decision=(1)) ∨ (q.n_decision=(2))))) ∧ ((q.n_localGrants=(1)) → (((q.n_decision=(3)) ∧ (q.n_done=(1))) ∧ (q.n_resultRoot=(1)))) ∧ ((q.n_remoteGrants=(1)) → (((q.n_decision=(2)) ∧ (q.n_done=(1))) ∧ (q.n_resultRoot=(1)))) ∧ ((q.n_gate≥(1)) → (q.n_grantGen=q.n_generation)) ∧ ((q.n_gate=(1)) → (q.n_lease≥(1))) ∧ ((q.n_patchReady=(1)) → ((q.n_copyReady=(1)) ∧ (q.n_destRoot=(1)))) ∧ ((q.n_copyOps=(0)) → ((q.n_copyReady=(0)) ∧ (q.n_patchReady=(0))))) ∧ ((q.p_phase≥(0)) ∧ (q.p_phase≤(9)) ∧ (q.p_eligible≥(0)) ∧ (q.p_eligible≤(1)) ∧ (q.p_claims≥(0)) ∧ (q.p_claims≤(1)) ∧ (q.p_probes≥(0)) ∧ (q.p_childRuns≥(0)) ∧ (q.p_childRuns≤(1)) ∧ (q.p_childDone≥(0)) ∧ (q.p_childDone≤(1)) ∧ (q.p_sourceRoot≥(0)) ∧ (q.p_sourceRoot≤(1)) ∧ (q.p_copyRoot≥(0)) ∧ (q.p_copyRoot≤(1)) ∧ (q.p_ready≥(0)) ∧ (q.p_ready≤(1)) ∧ (q.p_queueRoot≥(0)) ∧ (q.p_queueRoot≤(1)) ∧ (q.p_restoreRoot≥(0)) ∧ (q.p_restoreRoot≤(1)) ∧ (q.p_contextRoot≥(0)) ∧ (q.p_contextRoot≤(1)) ∧ (q.p_resultRoot≥(0)) ∧ (q.p_resultRoot≤(1)) ∧ (q.p_placeholder≥(0)) ∧ (q.p_placeholder≤(1)) ∧ (q.p_materialized≥(0)) ∧ (q.p_materialized≤(1)) ∧ (q.p_split≥(0)) ∧ (q.p_split≤(1)) ∧ (q.p_parentOwner≥(0)) ∧ (q.p_parentOwner≤(3)) ∧ (q.p_prefixRuns≥(0)) ∧ (q.p_prefixRuns≤(1)) ∧ (q.p_parentRuns≥(0)) ∧ (q.p_captured≥(0)) ∧ (q.p_captured≤(1)) ∧ (q.p_captureRoot≥(0)) ∧ (q.p_captureRoot≤(1)) ∧ (q.p_exited≥(0)) ∧ (q.p_exited≤(1)) ∧ (q.p_descriptor≥(0)) ∧ (q.p_descriptor≤(1)) ∧ (q.p_gcOpen≥(0)) ∧ (q.p_gcOpen≤(1)) ∧ (q.p_frozen≥(0)) ∧ (q.p_frozen≤(1)) ∧ (q.p_scanning≥(0)) ∧ (q.p_scanning≤(1)) ∧ (q.p_scanned≥(0)) ∧ (q.p_scanned≤(1)) ∧ (q.p_epoch≥(0)) ∧ (q.p_vSource≥(0)) ∧ (q.p_vSource≤(1)) ∧ (q.p_vCopy≥(0)) ∧ (q.p_vCopy≤(1)) ∧ (q.p_vQueue≥(0)) ∧ (q.p_vQueue≤(1)) ∧ (q.p_vRestore≥(0)) ∧ (q.p_vRestore≤(1)) ∧ (q.p_vContext≥(0)) ∧ (q.p_vContext≤(1)) ∧ (q.p_vResult≥(0)) ∧ (q.p_vResult≤(1)) ∧ (q.p_vCapture≥(0)) ∧ (q.p_vCapture≤(1)) ∧ (q.p_resultPublished≥(0)) ∧ (q.p_resultPublished≤(1)) ∧ (q.p_epoch≥(1)) ∧ (q.p_childRuns=(1)) ∧ (((q.p_phase≤(3)) ∨ (q.p_phase=(6))) → (q.p_sourceRoot=(1))) ∧ (((q.p_phase≥(1)) ∧ (q.p_phase≤(5))) → ((q.p_claims=(1)) ∧ (q.p_eligible=(1)))) ∧ ((q.p_phase=(0)) → ((((((q.p_split=(0)) ∧ (q.p_ready=(0))) ∧ (q.p_copyRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_parentOwner=(0))) ∧ (q.p_placeholder=(0)))) ∧ ((q.p_phase=(1)) → (((q.p_ready=(0)) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(2)) → ((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(3)) → ((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(4)) → (((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(1)))) ∧ ((q.p_phase=(5)) → ((((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_restoreRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(2)))) ∧ ((q.p_phase=(6)) → ((((q.p_childDone=(1)) ∧ (q.p_resultRoot=(1))) ∧ (q.p_split=(0))) ∧ (q.p_parentOwner=(0)))) ∧ ((q.p_phase=(7)) → (((((((q.p_contextRoot=(1)) ∧ (q.p_copyRoot=(0))) ∧ (q.p_restoreRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(3))) ∧ (q.p_ready=(1)))) ∧ ((q.p_phase<(8)) → (q.p_descriptor=(1))) ∧ ((q.p_phase≥(8)) → ((((((((((q.p_sourceRoot=(0)) ∧ (q.p_copyRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_restoreRoot=(0))) ∧ (q.p_contextRoot=(0))) ∧ (q.p_resultRoot=(0))) ∧ (q.p_captureRoot=(0))) ∧ (q.p_captured=(0))) ∧ (q.p_placeholder=(0))) ∧ (q.p_exited=(1)))) ∧ ((q.p_queueRoot=(1)) → ((q.p_phase=(3)) ∨ (q.p_phase=(4)))) ∧ ((q.p_copyRoot=(1)) → ((((q.p_placeholder=(1)) ∧ (q.p_materialized=(1))) ∧ (q.p_phase≥(1))) ∧ (q.p_phase≤(5)))) ∧ ((q.p_restoreRoot=(1)) → (q.p_phase=(5))) ∧ ((q.p_contextRoot=(1)) → (q.p_phase=(7))) ∧ ((q.p_ready=(1)) → (((q.p_phase≥(2)) ∧ (q.p_phase≤(7))) ∧ (q.p_phase≠(6)))) ∧ ((q.p_split=(1)) → (((q.p_phase≥(4)) ∧ (q.p_claims=(1))) ∧ (q.p_materialized=(1)))) ∧ ((q.p_parentOwner≥(1)) → (q.p_split=(1))) ∧ (((q.p_childDone=(1)) ∧ (q.p_phase<(8))) → (q.p_resultRoot=(1))) ∧ ((q.p_resultPublished=(1)) → ((q.p_childDone=(1)) ∧ (q.p_split=(1)))) ∧ ((q.p_parentRuns≥(1)) → (((q.p_phase≥(6)) ∧ (q.p_childDone=(1))) ∧ (q.p_prefixRuns=(1)))) ∧ (((q.p_parentRuns≥(1)) ∧ (q.p_split=(1))) → (q.p_resultPublished=(1))) ∧ ((q.p_captured=(1)) → ((((q.p_captureRoot=(1)) ∧ (q.p_parentRuns≥(1))) ∧ ((q.p_phase=(6)) ∨ (q.p_phase=(7)))) ∧ (q.p_exited=(0)))) ∧ ((q.p_captureRoot=(1)) → (q.p_captured=(1))) ∧ ((q.p_phase<(6)) → ((((q.p_parentRuns=(0)) ∧ (q.p_prefixRuns=(0))) ∧ (q.p_captured=(0))) ∧ (q.p_exited=(0)))) ∧ ((q.p_exited=(1)) → ((q.p_parentRuns≥(1)) ∧ (q.p_captured=(0)))) ∧ ((q.p_materialized=(1)) → (q.p_claims=(1))) ∧ ((q.p_frozen=(1)) → ((((((((q.p_gcOpen=(0)) ∧ (q.p_sourceRoot=q.p_vSource)) ∧ (q.p_copyRoot=q.p_vCopy)) ∧ (q.p_queueRoot=q.p_vQueue)) ∧ (q.p_restoreRoot=q.p_vRestore)) ∧ (q.p_contextRoot=q.p_vContext)) ∧ (q.p_resultRoot=q.p_vResult)) ∧ (q.p_captureRoot=q.p_vCapture))) ∧ ((q.p_scanning=(1)) → ((q.p_frozen=(1)) ∧ (q.p_scanned=(0)))) ∧ ((q.p_scanned=(1)) → ((q.p_frozen=(1)) ∧ (q.p_scanning=(0))))) ∧ ((q.n_done=q.p_childDone) ∧ (q.n_resultRoot=q.p_resultRoot) ∧ (q.n_claims=q.p_claims) ∧ (q.n_sourceRoot=q.p_sourceRoot) ∧ (q.n_destRoot=(q.p_copyRoot+q.p_contextRoot)) ∧ (q.n_copyReady=q.p_ready) ∧ (((q.n_decision=(2)) → (q.p_split=(1))) ∧ ((q.p_split=(1)) → (q.n_decision=(2)))) ∧ ((q.n_decision=(0)) → ((q.p_phase=(0)) ∨ (q.p_phase=(6)))) ∧ ((q.n_decision=(1)) → ((q.p_phase≥(1)) ∧ (q.p_phase≤(3)))) ∧ ((q.n_decision=(3)) → ((q.p_phase=(0)) ∨ (q.p_phase=(6)))) ∧ (q.p_phase≤(7)) ∧ (q.p_parentRuns=(q.n_localGrants+q.n_remoteGrants)) ∧ (((q.n_gate=(2)) → (q.p_gcOpen=(0))) ∧ ((q.p_gcOpen=(0)) → (q.n_gate=(2)))) ∧ (q.publication≥(0)) ∧ (q.publication≤(3)) ∧ (q.active≥(0)) ∧ (q.active≤(1)) ∧ (q.attempts≥(0)) ∧ ((q.publication=(1)) → (((q.n_decision=(1)) ∧ (q.p_phase=(2))) ∧ (q.n_destRoot=(1)))) ∧ (((q.publication=(2)) → ((((q.p_phase=(3)) ∨ (q.p_phase=(4))) ∨ (q.p_phase=(5))) ∨ (q.p_phase=(7)))) ∧ (((((q.p_phase=(3)) ∨ (q.p_phase=(4))) ∨ (q.p_phase=(5))) ∨ (q.p_phase=(7))) → (q.publication=(2)))) ∧ ((q.n_decision=(2)) → (q.publication=(2))) ∧ ((q.active=(1)) → (q.n_decision=(2))) ∧ (((q.p_phase=(5)) ∨ (q.p_phase=(7))) → (q.active=(1))) ∧ (q.p_captured=(0)) ∧ (q.p_exited=(0)))) ∧ ((q.wordWins≥(0)) ∧ (q.wordWins≤(3)) ∧ ((q.n_decision≤(1)) → (q.wordWins=(q.n_claims+q.n_done))) ∧ ((q.n_decision≥(2)) → (q.wordWins=((q.n_claims+q.n_done)+(1)))) ∧ (q.word=(q.n_decision+((4)*q.n_done))) ∧ (q.word≥(0)) ∧ (q.word≤(7)) ∧ (q.sExpected≥(0)) ∧ (q.sExpected≤(7)) ∧ (q.sMode≥(0)) ∧ (q.sMode≤(3)) ∧ (q.cExpected≥(0)) ∧ (q.cExpected≤(7)) ∧ (q.cMode≥(0)) ∧ (q.cMode≤(2)) ∧ (q.preparedResult≥(0)) ∧ (q.preparedResult≤(1)) ∧ (q.commitRelease≥(0)) ∧ (q.commitRelease≤(1)) ∧ (q.resultRelease=q.n_done) ∧ (q.aSeen≥(0)) ∧ (q.aSeen≤(1)) ∧ (q.aWord≥(0)) ∧ (q.aWord≤(7)) ∧ (q.activationWord≥(0)) ∧ (q.activationWord≤(2)) ∧ (q.activeRelease=q.active) ∧ (q.carriedCommit=q.activeRelease) ∧ (q.workerSeen≥(0)) ∧ (q.workerSeen≤(1)) ∧ (q.resultSeen≥(0)) ∧ (q.resultSeen≤(1)) ∧ (q.casFailures≥(0)) ∧ ((q.commitRelease=(1)) → (q.n_decision=(2))) ∧ ((q.n_decision=(2)) → (q.commitRelease=(1))) ∧ ((q.aSeen=(1)) → ((q.commitRelease=(1)) ∧ ((q.aWord=(2)) ∨ (q.aWord=(6))))) ∧ ((q.active=(1)) → ((q.aSeen=(1)) ∧ (q.activationWord≥(1)))) ∧ ((q.activationWord≥(1)) → (q.active=(1))) ∧ ((q.activationWord=(1)) → (q.p_phase=(4))) ∧ ((q.activationWord=(2)) → ((q.p_phase=(5)) ∨ (q.p_phase=(7)))) ∧ (((q.p_phase=(5)) ∨ (q.p_phase=(7))) → (q.activationWord=(2))) ∧ ((q.workerSeen=(1)) → ((q.activeRelease=(1)) ∧ (q.carriedCommit=(1)))) ∧ ((q.activationWord=(2)) → (q.workerSeen=(1))) ∧ ((q.resultSeen=(1)) → (q.resultRelease=(1))) ∧ ((q.n_remoteGrants=(1)) → ((q.resultSeen=(1)) ∧ (q.workerSeen=(1))))))
def initial : State := {n_decision:=(0), n_claims:=(0), n_done:=(0), n_resultRoot:=(0), n_sourceRoot:=(1), n_destRoot:=(0), n_childRoot:=(1), n_copyReady:=(0), n_copyRev:=(0), n_viewRev:=(0), n_viewGen:=(0), n_viewLease:=(0), n_patchReady:=(0), n_patchRev:=(0), n_patchGen:=(0), n_patchLease:=(0), n_gate:=(0), n_admitted:=(1), n_generation:=(1), n_grantGen:=(0), n_lease:=(0), n_revision:=(0), n_sourceHeap:=(0), n_localGrants:=(0), n_remoteGrants:=(0), n_copyOps:=(0), n_validations:=(0), n_probes:=(0), p_phase:=(0), p_eligible:=(1), p_claims:=(0), p_probes:=(0), p_childRuns:=(1), p_childDone:=(0), p_sourceRoot:=(1), p_copyRoot:=(0), p_ready:=(0), p_queueRoot:=(0), p_restoreRoot:=(0), p_contextRoot:=(0), p_resultRoot:=(0), p_placeholder:=(0), p_materialized:=(0), p_split:=(0), p_parentOwner:=(0), p_prefixRuns:=(0), p_parentRuns:=(0), p_captured:=(0), p_captureRoot:=(0), p_exited:=(0), p_descriptor:=(1), p_gcOpen:=(1), p_frozen:=(0), p_scanning:=(0), p_scanned:=(0), p_epoch:=(1), p_vSource:=(0), p_vCopy:=(0), p_vQueue:=(0), p_vRestore:=(0), p_vContext:=(0), p_vResult:=(0), p_vCapture:=(0), p_resultPublished:=(0), publication:=(0), active:=(0), attempts:=(0), word:=(0), sExpected:=(0), sMode:=(0), cExpected:=(0), cMode:=(0), preparedResult:=(0), commitRelease:=(0), resultRelease:=(0), aSeen:=(0), aWord:=(0), activationWord:=(0), activeRelease:=(0), carriedCommit:=(0), workerSeen:=(0), resultSeen:=(0), casFailures:=(0), wordWins:=(0)}
def allocateGuard (q : State) : Prop := (((((q.n_decision=(1)) ∧ (q.n_destRoot=(0))) ∧ (q.n_gate=(0))) ∧ (q.n_admitted=(1))) ∧ ((((q.p_phase=(1)) ∧ (q.p_copyRoot=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))))
def allocateNext (q : State) : State := {q with n_destRoot:=(1), p_copyRoot:=(1), p_placeholder:=(1), p_materialized:=(1)}
def enterGuard (q : State) : Prop := (((q.n_gate=(0)) ∧ (q.n_admitted=(1))) ∧ (q.n_decision≥(1)))
def enterNext (q : State) : State := {q with n_gate:=(1), n_lease:=(q.n_lease+(1)), n_grantGen:=q.n_generation}
def resolveGuard (q : State) : Prop := ((q.n_gate=(1)) ∧ (q.n_grantGen=q.n_generation))
def resolveNext (q : State) : State := {q with n_viewRev:=q.n_revision, n_viewGen:=q.n_generation, n_viewLease:=q.n_lease}
def initializeGuard (q : State) : Prop := ((((((((((q.n_decision=(1)) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyReady=(0))) ∧ (q.n_sourceRoot=(1))) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ (((((q.p_phase=(1)) ∧ (q.p_copyRoot=(1))) ∧ (q.p_sourceRoot=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))))
def initializeNext (q : State) : State := {q with n_copyReady:=(1), n_copyRev:=q.n_revision, n_copyOps:=(q.n_copyOps+(1)), n_patchReady:=(0), p_phase:=(2), p_ready:=(1)}
def validateGuard (q : State) : Prop := (((((((((q.n_decision=(1)) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyReady=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision))
def validateNext (q : State) : State := {q with n_validations:=(q.n_validations+(1)), n_patchReady:=(0)}
def prepareGuard (q : State) : Prop := (((((((((q.n_decision=(1)) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyReady=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision))
def prepareNext (q : State) : State := {q with n_patchReady:=(1), n_patchRev:=q.n_revision, n_patchGen:=q.n_generation, n_patchLease:=q.n_lease}
def sendPublicationGuard (q : State) : Prop := (((q.n_decision=(1)) ∧ (q.p_phase=(2))) ∧ ((q.publication=(0)) ∨ (q.publication=(3))))
def sendPublicationNext (q : State) : State := {q with publication:=(1)}
def publicationUnknownGuard (q : State) : Prop := (q.publication=(1))
def publicationUnknownNext (q : State) : State := {q with attempts:=(q.attempts+(1))}
def acceptPublicationGuard (q : State) : Prop := ((((((q.p_phase=(2)) ∧ (q.p_ready=(1))) ∧ (q.p_copyRoot=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ (q.publication=(1)))
def acceptPublicationNext (q : State) : State := {q with p_phase:=(3), p_queueRoot:=(1), publication:=(2)}
def rejectPublicationGuard (q : State) : Prop := ((q.publication=(1)) ∧ (q.p_phase=(2)))
def rejectPublicationNext (q : State) : State := {q with publication:=(3)}
def activationFailedGuard (q : State) : Prop := (((q.n_decision=(2)) ∧ (q.p_phase=(4))) ∧ (q.active=(0)))
def activationFailedNext (q : State) : State := {q with attempts:=(q.attempts+(1))}
def wakeFailedGuard (q : State) : Prop := (q.active=(1))
def wakeFailedNext (q : State) : State := {q with attempts:=(q.attempts+(1))}
def restoreGuard (q : State) : Prop := (((((((q.p_phase=(5)) ∧ (q.p_copyRoot=(1))) ∧ (q.p_restoreRoot=(1))) ∧ (q.p_ready=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ (q.n_gate=(0)))
def restoreNext (q : State) : State := {q with p_phase:=(7), p_contextRoot:=(1), p_copyRoot:=(0), p_restoreRoot:=(0), p_parentOwner:=(3)}
def finishAbortedGuard (q : State) : Prop := (((((q.p_phase=(0)) ∧ (q.p_childDone=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ (q.n_decision=(3)))
def finishAbortedNext (q : State) : State := {q with p_phase:=(6)}
def publishResultGuard (q : State) : Prop := (((((((q.p_split=(1)) ∧ (q.p_childDone=(1))) ∧ (q.p_resultRoot=(1))) ∧ (q.p_resultPublished=(0))) ∧ (q.p_phase<(8))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))
def publishResultNext (q : State) : State := {q with p_resultPublished:=(1)}
def runPrefixGuard (q : State) : Prop := ((((((q.p_phase=(7)) ∧ (q.p_parentOwner=(3))) ∧ (q.p_prefixRuns=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ (q.active=(1)))
def runPrefixNext (q : State) : State := {q with p_prefixRuns:=(1)}
def grantLocalGuard (q : State) : Prop := (((((((((q.n_decision=(3)) ∧ (q.n_done=(1))) ∧ (q.n_localGrants=(0))) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ (((((q.p_phase=(6)) ∧ (q.p_childDone=(1))) ∧ (q.p_parentRuns=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))))
def grantLocalNext (q : State) : State := {q with n_localGrants:=(q.n_localGrants+(1)), p_prefixRuns:=(1), p_parentRuns:=(1)}
def leaveGuard (q : State) : Prop := (q.n_gate=(1))
def leaveNext (q : State) : State := {q with n_gate:=(0)}
def gcEnterGuard (q : State) : Prop := (((q.n_gate=(0)) ∧ (q.n_admitted=(1))) ∧ (q.p_gcOpen=(1)))
def gcEnterNext (q : State) : State := {q with n_gate:=(2), n_grantGen:=q.n_generation, p_gcOpen:=(0)}
def gcFreezeGuard (q : State) : Prop := ((q.p_gcOpen=(0)) ∧ (q.p_frozen=(0)))
def gcFreezeNext (q : State) : State := {q with p_frozen:=(1), p_vSource:=q.p_sourceRoot, p_vCopy:=q.p_copyRoot, p_vQueue:=q.p_queueRoot, p_vRestore:=q.p_restoreRoot, p_vContext:=q.p_contextRoot, p_vResult:=q.p_resultRoot, p_vCapture:=q.p_captureRoot}
def gcBeginGuard (q : State) : Prop := (((q.p_frozen=(1)) ∧ (q.p_scanning=(0))) ∧ (q.p_scanned=(0)))
def gcBeginNext (q : State) : State := {q with p_scanning:=(1)}
def forwardNoCopyGuard (q : State) : Prop := (((q.n_gate=(2)) ∧ (q.n_copyReady=(0))) ∧ (q.p_scanning=(1)))
def forwardNoCopyNext (q : State) : State := {q with n_revision:=(q.n_revision+(1)), n_sourceHeap:=(1)}
def forwardWithCopyGuard (q : State) : Prop := ((((q.n_gate=(2)) ∧ (q.n_copyReady=(1))) ∧ (q.n_destRoot=(1))) ∧ (q.p_scanning=(1)))
def forwardWithCopyNext (q : State) : State := {q with n_revision:=(q.n_revision+(1)), n_copyRev:=(q.n_revision+(1)), n_sourceHeap:=(1)}
def gcEndGuard (q : State) : Prop := (q.p_scanning=(1))
def gcEndNext (q : State) : State := {q with p_scanning:=(0), p_scanned:=(1)}
def gcLeaveGuard (q : State) : Prop := ((q.n_gate=(2)) ∧ (((q.p_frozen=(1)) ∧ (q.p_scanning=(0))) ∧ (q.p_scanned=(1))))
def gcLeaveNext (q : State) : State := {q with n_gate:=(0), p_frozen:=(0), p_gcOpen:=(1), p_scanned:=(0), p_epoch:=(q.p_epoch+(1))}
def closeDomainGuard (q : State) : Prop := (q.n_admitted=(1))
def closeDomainNext (q : State) : State := {q with n_admitted:=(0)}
def resetDomainGuard (q : State) : Prop := ((q.n_admitted=(0)) ∧ (q.n_gate=(0)))
def resetDomainNext (q : State) : State := {q with n_generation:=(q.n_generation+(1)), n_admitted:=(1)}
def prepareResultGuard (q : State) : Prop := (True ∧ ((((q.preparedResult=(0)) ∧ (q.n_done=(0))) ∧ (q.n_gate≠(2))) ∧ (q.p_gcOpen=(1))))
def prepareResultNext (q : State) : State := {q with preparedResult:=(1)}
def loadReserveGuard (q : State) : Prop := (True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(0))) ∧ (q.n_done=(0))))
def loadReserveNext (q : State) : State := {q with sExpected:=q.word, sMode:=(1)}
def loadCommitGuard (q : State) : Prop := (True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(1))) ∧ (q.publication=(2))))
def loadCommitNext (q : State) : State := {q with sExpected:=q.word, sMode:=(2)}
def loadAbortGuard (q : State) : Prop := (True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(1))) ∧ ((q.publication=(0)) ∨ (q.publication=(3)))))
def loadAbortNext (q : State) : State := {q with sExpected:=q.word, sMode:=(3)}
def splitFailureGuard (q : State) : Prop := (True ∧ (q.sMode≥(1)))
def splitFailureNext (q : State) : State := {q with sExpected:=q.word, sMode:=(0), casFailures:=(q.casFailures+(1))}
def casReserveGuard (q : State) : Prop := (((((q.n_decision=(0)) ∧ (q.n_done=(0))) ∧ (q.n_admitted=(1))) ∧ ((((((q.p_phase=(0)) ∧ (q.p_eligible=(1))) ∧ (q.p_claims=(0))) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.sMode=(1)) ∧ (q.sExpected=(0))) ∧ (q.sExpected=q.word)))
def casReserveNext (q : State) : State := {q with n_decision:=(1), n_claims:=(q.n_claims+(1)), p_phase:=(1), p_claims:=(q.p_claims+(1)), word:=(q.sExpected+(1)), sMode:=(0), wordWins:=(q.wordWins+(1))}
def casCommitGuard (q : State) : Prop := ((((((((((((((((q.n_decision=(1)) ∧ (q.n_copyReady=(1))) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_patchReady=(1))) ∧ (q.n_patchRev=q.n_revision)) ∧ (q.n_patchGen=q.n_generation)) ∧ (q.n_patchLease=q.n_lease)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ ((((((q.p_phase=(3)) ∧ (q.p_ready=(1))) ∧ (q.p_copyRoot=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ ((q.publication=(2)) ∧ (q.active=(0)))) ∧ ((q.sMode=(2)) ∧ (q.sExpected=q.word)))
def casCommitNext (q : State) : State := {q with n_decision:=(2), n_sourceRoot:=(0), p_phase:=(4), p_sourceRoot:=(0), p_split:=(1), p_parentOwner:=(1), word:=(2), sMode:=(0), commitRelease:=(1), wordWins:=(q.wordWins+(1))}
def casAbortGuard (q : State) : Prop := (((((((((q.n_decision=(1)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ (((((q.p_phase=(1)) ∨ (q.p_phase=(2))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ ((q.publication=(0)) ∨ (q.publication=(3)))) ∧ ((q.sMode=(3)) ∧ (q.sExpected=q.word)))
def casAbortNext (q : State) : State := {q with n_decision:=(3), n_destRoot:=(0), n_copyReady:=(0), n_copyRev:=(0), n_patchReady:=(0), p_phase:=(0), p_copyRoot:=(0), p_placeholder:=(0), p_ready:=(0), word:=(q.sExpected+(2)), sMode:=(0), wordWins:=(q.wordWins+(1))}
def loadChildGuard (q : State) : Prop := (True ∧ (((q.cMode=(0)) ∧ (q.n_done=(0))) ∧ (q.preparedResult=(1))))
def loadChildNext (q : State) : State := {q with cExpected:=q.word, cMode:=(1)}
def loadLocalGuard (q : State) : Prop := (True ∧ (((q.cMode=(0)) ∧ (q.n_decision=(0))) ∧ (q.n_done=(1))))
def loadLocalNext (q : State) : State := {q with cExpected:=q.word, cMode:=(2)}
def childFailureGuard (q : State) : Prop := (True ∧ (q.cMode≥(1)))
def childFailureNext (q : State) : State := {q with cExpected:=q.word, cMode:=(0), casFailures:=(q.casFailures+(1))}
def casChildLocalGuard (q : State) : Prop := ((((q.n_done=(0)) ∧ (q.n_gate≠(2))) ∧ ((((q.p_phase=(0)) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.cMode=(1)) ∧ (q.cExpected=q.word)) ∧ (q.preparedResult=(1))))
def casChildLocalNext (q : State) : State := {q with n_done:=(1), n_resultRoot:=(1), p_phase:=(6), p_childDone:=(1), p_resultRoot:=(1), word:=(q.cExpected+(4)), cMode:=(0), resultRelease:=(1), wordWins:=(q.wordWins+(1))}
def casChildSplitGuard (q : State) : Prop := ((((q.n_done=(0)) ∧ (q.n_gate≠(2))) ∧ ((((((q.p_phase≥(1)) ∧ (q.p_phase≤(5))) ∨ (q.p_phase=(7))) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.cMode=(1)) ∧ (q.cExpected=q.word)) ∧ (q.preparedResult=(1))))
def casChildSplitNext (q : State) : State := {q with n_done:=(1), n_resultRoot:=(1), p_childDone:=(1), p_resultRoot:=(1), word:=(q.cExpected+(4)), cMode:=(0), resultRelease:=(1), wordWins:=(q.wordWins+(1))}
def casCloseLocalGuard (q : State) : Prop := ((((q.n_decision=(0)) ∧ (q.n_done=(1))) ∧ (q.n_gate=(0))) ∧ ((q.cMode=(2)) ∧ (q.cExpected=q.word)))
def casCloseLocalNext (q : State) : State := {q with n_decision:=(3), word:=(q.cExpected+(3)), cMode:=(0), wordWins:=(q.wordWins+(1))}
def retirePreparedResultGuard (q : State) : Prop := (True ∧ ((((q.n_done=(1)) ∧ (q.n_resultRoot=(1))) ∧ (q.n_gate≠(2))) ∧ (q.p_gcOpen=(1))))
def retirePreparedResultNext (q : State) : State := {q with preparedResult:=(0)}
def acquireCommitGuard (q : State) : Prop := (True ∧ ((q.n_decision=(2)) ∧ (q.commitRelease=(1))))
def acquireCommitNext (q : State) : State := {q with aSeen:=(1), aWord:=q.word}
def casActivateGuard (q : State) : Prop := (((((q.n_decision=(2)) ∧ (q.p_phase=(4))) ∧ (q.active=(0))) ∧ (q.n_gate=(0))) ∧ ((q.aSeen=(1)) ∧ (q.activationWord=(0))))
def casActivateNext (q : State) : State := {q with active:=(1), activationWord:=(1), activeRelease:=(1), carriedCommit:=(1)}
def acquireActiveGuard (q : State) : Prop := (True ∧ (((q.activationWord≥(1)) ∧ (q.activeRelease=(1))) ∧ (q.carriedCommit=(1))))
def acquireActiveNext (q : State) : State := {q with workerSeen:=(1)}
def casDequeueGuard (q : State) : Prop := (((((((q.p_phase=(4)) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ ((q.active=(1)) ∧ (q.n_gate=(0)))) ∧ ((q.workerSeen=(1)) ∧ (q.activationWord=(1))))
def casDequeueNext (q : State) : State := {q with p_phase:=(5), p_queueRoot:=(0), p_restoreRoot:=(1), p_parentOwner:=(2), activationWord:=(2)}
def acquireResultGuard (q : State) : Prop := (True ∧ ((q.n_done=(1)) ∧ (q.resultRelease=(1))))
def acquireResultNext (q : State) : State := {q with resultSeen:=(1)}
def grantRemoteGuard (q : State) : Prop := (((((((((((((q.n_decision=(2)) ∧ (q.n_done=(1))) ∧ (q.n_remoteGrants=(0))) ∧ (q.n_copyReady=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ ((((((q.p_phase=(7)) ∧ (q.p_prefixRuns=(1))) ∧ (q.p_resultPublished=(1))) ∧ (q.p_parentRuns=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (q.active=(1))) ∧ ((q.resultSeen=(1)) ∧ (q.workerSeen=(1))))
def grantRemoteNext (q : State) : State := {q with n_remoteGrants:=(q.n_remoteGrants+(1)), p_parentRuns:=(1)}
def Step (q r : State) : Prop := (allocateGuard q ∧ r=allocateNext q) ∨ (enterGuard q ∧ r=enterNext q) ∨ (resolveGuard q ∧ r=resolveNext q) ∨ (initializeGuard q ∧ r=initializeNext q) ∨ (validateGuard q ∧ r=validateNext q) ∨ (prepareGuard q ∧ r=prepareNext q) ∨ (sendPublicationGuard q ∧ r=sendPublicationNext q) ∨ (publicationUnknownGuard q ∧ r=publicationUnknownNext q) ∨ (acceptPublicationGuard q ∧ r=acceptPublicationNext q) ∨ (rejectPublicationGuard q ∧ r=rejectPublicationNext q) ∨ (activationFailedGuard q ∧ r=activationFailedNext q) ∨ (wakeFailedGuard q ∧ r=wakeFailedNext q) ∨ (restoreGuard q ∧ r=restoreNext q) ∨ (finishAbortedGuard q ∧ r=finishAbortedNext q) ∨ (publishResultGuard q ∧ r=publishResultNext q) ∨ (runPrefixGuard q ∧ r=runPrefixNext q) ∨ (grantLocalGuard q ∧ r=grantLocalNext q) ∨ (leaveGuard q ∧ r=leaveNext q) ∨ (gcEnterGuard q ∧ r=gcEnterNext q) ∨ (gcFreezeGuard q ∧ r=gcFreezeNext q) ∨ (gcBeginGuard q ∧ r=gcBeginNext q) ∨ (forwardNoCopyGuard q ∧ r=forwardNoCopyNext q) ∨ (forwardWithCopyGuard q ∧ r=forwardWithCopyNext q) ∨ (gcEndGuard q ∧ r=gcEndNext q) ∨ (gcLeaveGuard q ∧ r=gcLeaveNext q) ∨ (closeDomainGuard q ∧ r=closeDomainNext q) ∨ (resetDomainGuard q ∧ r=resetDomainNext q) ∨ (prepareResultGuard q ∧ r=prepareResultNext q) ∨ (loadReserveGuard q ∧ r=loadReserveNext q) ∨ (loadCommitGuard q ∧ r=loadCommitNext q) ∨ (loadAbortGuard q ∧ r=loadAbortNext q) ∨ (splitFailureGuard q ∧ r=splitFailureNext q) ∨ (casReserveGuard q ∧ r=casReserveNext q) ∨ (casCommitGuard q ∧ r=casCommitNext q) ∨ (casAbortGuard q ∧ r=casAbortNext q) ∨ (loadChildGuard q ∧ r=loadChildNext q) ∨ (loadLocalGuard q ∧ r=loadLocalNext q) ∨ (childFailureGuard q ∧ r=childFailureNext q) ∨ (casChildLocalGuard q ∧ r=casChildLocalNext q) ∨ (casChildSplitGuard q ∧ r=casChildSplitNext q) ∨ (casCloseLocalGuard q ∧ r=casCloseLocalNext q) ∨ (retirePreparedResultGuard q ∧ r=retirePreparedResultNext q) ∨ (acquireCommitGuard q ∧ r=acquireCommitNext q) ∨ (casActivateGuard q ∧ r=casActivateNext q) ∨ (acquireActiveGuard q ∧ r=acquireActiveNext q) ∨ (casDequeueGuard q ∧ r=casDequeueNext q) ∨ (acquireResultGuard q ∧ r=acquireResultNext q) ∨ (grantRemoteGuard q ∧ r=grantRemoteNext q) ∨ r=q
end ControlWordAst
