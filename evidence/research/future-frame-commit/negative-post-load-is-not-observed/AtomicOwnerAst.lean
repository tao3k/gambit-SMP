import Std
namespace AtomicOwnerAst
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
 commitValue : Int
 childValue : Int
 childCover : Int
 activeEvidence : Int
 activeIssuer : Int
 activeProofGen : Int
 claimedEvidence : Int
 claimedOwner : Int
 claimProofGen : Int
 activeFloor : Int
 claimFloor : Int
 a0Floor : Int
 a1Floor : Int
 w0Floor : Int
 w1Floor : Int
 w0ActiveFloor : Int
 w1ActiveFloor : Int
 sPending : Int
 sOutExpected : Int
 sOutObserved : Int
 sSnapshot : Int
 sOutSuccess : Int
 sNativeExpected : Int
 sLegacyExpected : Int
 sDeliveredObserved : Int
 sDeliveredValid : Int
 sCall : Int
 sDeliveredCall : Int
 cPending : Int
 cOutExpected : Int
 cOutObserved : Int
 cSnapshot : Int
 cOutSuccess : Int
 cNativeExpected : Int
 cLegacyExpected : Int
 cDeliveredObserved : Int
 cDeliveredValid : Int
 cCall : Int
 cDeliveredCall : Int
 a0View : Int
 a0Rf : Int
 a0Value : Int
 a0CapGen : Int
 a0Gen : Int
 a1View : Int
 a1Rf : Int
 a1Value : Int
 a1CapGen : Int
 a1Gen : Int
 w0View : Int
 w0Rf : Int
 w0Value : Int
 w0CapGen : Int
 w0Gen : Int
 w1View : Int
 w1Rf : Int
 w1Value : Int
 w1CapGen : Int
 w1Gen : Int
 r0View : Int
 r0Rf : Int
 r0Value : Int
 r1View : Int
 r1Rf : Int
 r1Value : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((((q.n_decision≥(0)) ∧ (q.n_decision≤(3)) ∧ (q.n_claims≥(0)) ∧ (q.n_claims≤(1)) ∧ (q.n_done≥(0)) ∧ (q.n_done≤(1)) ∧ (q.n_resultRoot≥(0)) ∧ (q.n_resultRoot≤(1)) ∧ (q.n_sourceRoot≥(0)) ∧ (q.n_sourceRoot≤(1)) ∧ (q.n_destRoot≥(0)) ∧ (q.n_destRoot≤(1)) ∧ (q.n_childRoot≥(0)) ∧ (q.n_childRoot≤(1)) ∧ (q.n_copyReady≥(0)) ∧ (q.n_copyReady≤(1)) ∧ (q.n_copyRev≥(0)) ∧ (q.n_viewRev≥(0)) ∧ (q.n_viewGen≥(0)) ∧ (q.n_viewLease≥(0)) ∧ (q.n_patchReady≥(0)) ∧ (q.n_patchReady≤(1)) ∧ (q.n_patchRev≥(0)) ∧ (q.n_patchGen≥(0)) ∧ (q.n_patchLease≥(0)) ∧ (q.n_gate≥(0)) ∧ (q.n_gate≤(2)) ∧ (q.n_admitted≥(0)) ∧ (q.n_admitted≤(1)) ∧ (q.n_generation≥(0)) ∧ (q.n_grantGen≥(0)) ∧ (q.n_lease≥(0)) ∧ (q.n_revision≥(0)) ∧ (q.n_sourceHeap≥(0)) ∧ (q.n_sourceHeap≤(1)) ∧ (q.n_localGrants≥(0)) ∧ (q.n_localGrants≤(1)) ∧ (q.n_remoteGrants≥(0)) ∧ (q.n_remoteGrants≤(1)) ∧ (q.n_copyOps≥(0)) ∧ (q.n_validations≥(0)) ∧ (q.n_probes≥(0)) ∧ (q.n_copyOps≤(1)) ∧ ((q.n_copyOps=(1)) → ((q.n_copyReady=(1)) ∨ (q.n_decision=(3)))) ∧ (q.n_generation≥(1)) ∧ (q.n_viewRev≤q.n_revision) ∧ (q.n_copyRev≤q.n_revision) ∧ (q.n_patchRev≤q.n_revision) ∧ (q.n_viewGen≤q.n_generation) ∧ (q.n_patchGen≤q.n_generation) ∧ (q.n_grantGen≤q.n_generation) ∧ (q.n_viewLease≤q.n_lease) ∧ (q.n_patchLease≤q.n_lease) ∧ (q.n_childRoot=(1)) ∧ ((q.n_sourceRoot+q.n_destRoot)≥(1)) ∧ ((q.n_localGrants+q.n_remoteGrants)≤(1)) ∧ ((q.n_done=(1)) → (q.n_resultRoot=(1))) ∧ ((q.n_resultRoot=(1)) → (q.n_done=(1))) ∧ ((q.n_decision=(0)) → ((((((q.n_claims=(0)) ∧ (q.n_sourceRoot=(1))) ∧ (q.n_destRoot=(0))) ∧ (q.n_copyReady=(0))) ∧ (q.n_localGrants=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_decision=(1)) → ((((q.n_claims=(1)) ∧ (q.n_sourceRoot=(1))) ∧ (q.n_localGrants=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_decision=(2)) → (((((q.n_claims=(1)) ∧ (q.n_sourceRoot=(0))) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyReady=(1))) ∧ (q.n_localGrants=(0)))) ∧ ((q.n_decision=(3)) → ((((q.n_sourceRoot=(1)) ∧ (q.n_destRoot=(0))) ∧ (q.n_copyReady=(0))) ∧ (q.n_remoteGrants=(0)))) ∧ ((q.n_copyReady=(1)) → (((q.n_destRoot=(1)) ∧ ((q.n_decision=(1)) ∨ (q.n_decision=(2)))) ∧ (q.n_copyRev=q.n_revision))) ∧ ((q.n_destRoot=(1)) → ((q.n_claims=(1)) ∧ ((q.n_decision=(1)) ∨ (q.n_decision=(2))))) ∧ ((q.n_localGrants=(1)) → (((q.n_decision=(3)) ∧ (q.n_done=(1))) ∧ (q.n_resultRoot=(1)))) ∧ ((q.n_remoteGrants=(1)) → (((q.n_decision=(2)) ∧ (q.n_done=(1))) ∧ (q.n_resultRoot=(1)))) ∧ ((q.n_gate≥(1)) → (q.n_grantGen=q.n_generation)) ∧ ((q.n_gate=(1)) → (q.n_lease≥(1))) ∧ ((q.n_patchReady=(1)) → ((q.n_copyReady=(1)) ∧ (q.n_destRoot=(1)))) ∧ ((q.n_copyOps=(0)) → ((q.n_copyReady=(0)) ∧ (q.n_patchReady=(0))))) ∧ ((q.p_phase≥(0)) ∧ (q.p_phase≤(9)) ∧ (q.p_eligible≥(0)) ∧ (q.p_eligible≤(1)) ∧ (q.p_claims≥(0)) ∧ (q.p_claims≤(1)) ∧ (q.p_probes≥(0)) ∧ (q.p_childRuns≥(0)) ∧ (q.p_childRuns≤(1)) ∧ (q.p_childDone≥(0)) ∧ (q.p_childDone≤(1)) ∧ (q.p_sourceRoot≥(0)) ∧ (q.p_sourceRoot≤(1)) ∧ (q.p_copyRoot≥(0)) ∧ (q.p_copyRoot≤(1)) ∧ (q.p_ready≥(0)) ∧ (q.p_ready≤(1)) ∧ (q.p_queueRoot≥(0)) ∧ (q.p_queueRoot≤(1)) ∧ (q.p_restoreRoot≥(0)) ∧ (q.p_restoreRoot≤(1)) ∧ (q.p_contextRoot≥(0)) ∧ (q.p_contextRoot≤(1)) ∧ (q.p_resultRoot≥(0)) ∧ (q.p_resultRoot≤(1)) ∧ (q.p_placeholder≥(0)) ∧ (q.p_placeholder≤(1)) ∧ (q.p_materialized≥(0)) ∧ (q.p_materialized≤(1)) ∧ (q.p_split≥(0)) ∧ (q.p_split≤(1)) ∧ (q.p_parentOwner≥(0)) ∧ (q.p_parentOwner≤(3)) ∧ (q.p_prefixRuns≥(0)) ∧ (q.p_prefixRuns≤(1)) ∧ (q.p_parentRuns≥(0)) ∧ (q.p_captured≥(0)) ∧ (q.p_captured≤(1)) ∧ (q.p_captureRoot≥(0)) ∧ (q.p_captureRoot≤(1)) ∧ (q.p_exited≥(0)) ∧ (q.p_exited≤(1)) ∧ (q.p_descriptor≥(0)) ∧ (q.p_descriptor≤(1)) ∧ (q.p_gcOpen≥(0)) ∧ (q.p_gcOpen≤(1)) ∧ (q.p_frozen≥(0)) ∧ (q.p_frozen≤(1)) ∧ (q.p_scanning≥(0)) ∧ (q.p_scanning≤(1)) ∧ (q.p_scanned≥(0)) ∧ (q.p_scanned≤(1)) ∧ (q.p_epoch≥(0)) ∧ (q.p_vSource≥(0)) ∧ (q.p_vSource≤(1)) ∧ (q.p_vCopy≥(0)) ∧ (q.p_vCopy≤(1)) ∧ (q.p_vQueue≥(0)) ∧ (q.p_vQueue≤(1)) ∧ (q.p_vRestore≥(0)) ∧ (q.p_vRestore≤(1)) ∧ (q.p_vContext≥(0)) ∧ (q.p_vContext≤(1)) ∧ (q.p_vResult≥(0)) ∧ (q.p_vResult≤(1)) ∧ (q.p_vCapture≥(0)) ∧ (q.p_vCapture≤(1)) ∧ (q.p_resultPublished≥(0)) ∧ (q.p_resultPublished≤(1)) ∧ (q.p_epoch≥(1)) ∧ (q.p_childRuns=(1)) ∧ (((q.p_phase≤(3)) ∨ (q.p_phase=(6))) → (q.p_sourceRoot=(1))) ∧ (((q.p_phase≥(1)) ∧ (q.p_phase≤(5))) → ((q.p_claims=(1)) ∧ (q.p_eligible=(1)))) ∧ ((q.p_phase=(0)) → ((((((q.p_split=(0)) ∧ (q.p_ready=(0))) ∧ (q.p_copyRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_parentOwner=(0))) ∧ (q.p_placeholder=(0)))) ∧ ((q.p_phase=(1)) → (((q.p_ready=(0)) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(2)) → ((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(3)) → ((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(0)))) ∧ ((q.p_phase=(4)) → (((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(1)))) ∧ ((q.p_phase=(5)) → ((((((q.p_copyRoot=(1)) ∧ (q.p_ready=(1))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_restoreRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(2)))) ∧ ((q.p_phase=(6)) → ((((q.p_childDone=(1)) ∧ (q.p_resultRoot=(1))) ∧ (q.p_split=(0))) ∧ (q.p_parentOwner=(0)))) ∧ ((q.p_phase=(7)) → (((((((q.p_contextRoot=(1)) ∧ (q.p_copyRoot=(0))) ∧ (q.p_restoreRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_split=(1))) ∧ (q.p_parentOwner=(3))) ∧ (q.p_ready=(1)))) ∧ ((q.p_phase<(8)) → (q.p_descriptor=(1))) ∧ ((q.p_phase≥(8)) → ((((((((((q.p_sourceRoot=(0)) ∧ (q.p_copyRoot=(0))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_restoreRoot=(0))) ∧ (q.p_contextRoot=(0))) ∧ (q.p_resultRoot=(0))) ∧ (q.p_captureRoot=(0))) ∧ (q.p_captured=(0))) ∧ (q.p_placeholder=(0))) ∧ (q.p_exited=(1)))) ∧ ((q.p_queueRoot=(1)) → ((q.p_phase=(3)) ∨ (q.p_phase=(4)))) ∧ ((q.p_copyRoot=(1)) → ((((q.p_placeholder=(1)) ∧ (q.p_materialized=(1))) ∧ (q.p_phase≥(1))) ∧ (q.p_phase≤(5)))) ∧ ((q.p_restoreRoot=(1)) → (q.p_phase=(5))) ∧ ((q.p_contextRoot=(1)) → (q.p_phase=(7))) ∧ ((q.p_ready=(1)) → (((q.p_phase≥(2)) ∧ (q.p_phase≤(7))) ∧ (q.p_phase≠(6)))) ∧ ((q.p_split=(1)) → (((q.p_phase≥(4)) ∧ (q.p_claims=(1))) ∧ (q.p_materialized=(1)))) ∧ ((q.p_parentOwner≥(1)) → (q.p_split=(1))) ∧ (((q.p_childDone=(1)) ∧ (q.p_phase<(8))) → (q.p_resultRoot=(1))) ∧ ((q.p_resultPublished=(1)) → ((q.p_childDone=(1)) ∧ (q.p_split=(1)))) ∧ ((q.p_parentRuns≥(1)) → (((q.p_phase≥(6)) ∧ (q.p_childDone=(1))) ∧ (q.p_prefixRuns=(1)))) ∧ (((q.p_parentRuns≥(1)) ∧ (q.p_split=(1))) → (q.p_resultPublished=(1))) ∧ ((q.p_captured=(1)) → ((((q.p_captureRoot=(1)) ∧ (q.p_parentRuns≥(1))) ∧ ((q.p_phase=(6)) ∨ (q.p_phase=(7)))) ∧ (q.p_exited=(0)))) ∧ ((q.p_captureRoot=(1)) → (q.p_captured=(1))) ∧ ((q.p_phase<(6)) → ((((q.p_parentRuns=(0)) ∧ (q.p_prefixRuns=(0))) ∧ (q.p_captured=(0))) ∧ (q.p_exited=(0)))) ∧ ((q.p_exited=(1)) → ((q.p_parentRuns≥(1)) ∧ (q.p_captured=(0)))) ∧ ((q.p_materialized=(1)) → (q.p_claims=(1))) ∧ ((q.p_frozen=(1)) → ((((((((q.p_gcOpen=(0)) ∧ (q.p_sourceRoot=q.p_vSource)) ∧ (q.p_copyRoot=q.p_vCopy)) ∧ (q.p_queueRoot=q.p_vQueue)) ∧ (q.p_restoreRoot=q.p_vRestore)) ∧ (q.p_contextRoot=q.p_vContext)) ∧ (q.p_resultRoot=q.p_vResult)) ∧ (q.p_captureRoot=q.p_vCapture))) ∧ ((q.p_scanning=(1)) → ((q.p_frozen=(1)) ∧ (q.p_scanned=(0)))) ∧ ((q.p_scanned=(1)) → ((q.p_frozen=(1)) ∧ (q.p_scanning=(0))))) ∧ ((q.n_done=q.p_childDone) ∧ (q.n_resultRoot=q.p_resultRoot) ∧ (q.n_claims=q.p_claims) ∧ (q.n_sourceRoot=q.p_sourceRoot) ∧ (q.n_destRoot=(q.p_copyRoot+q.p_contextRoot)) ∧ (q.n_copyReady=q.p_ready) ∧ (((q.n_decision=(2)) → (q.p_split=(1))) ∧ ((q.p_split=(1)) → (q.n_decision=(2)))) ∧ ((q.n_decision=(0)) → ((q.p_phase=(0)) ∨ (q.p_phase=(6)))) ∧ ((q.n_decision=(1)) → ((q.p_phase≥(1)) ∧ (q.p_phase≤(3)))) ∧ ((q.n_decision=(3)) → ((q.p_phase=(0)) ∨ (q.p_phase=(6)))) ∧ (q.p_phase≤(7)) ∧ (q.p_parentRuns=(q.n_localGrants+q.n_remoteGrants)) ∧ (((q.n_gate=(2)) → (q.p_gcOpen=(0))) ∧ ((q.p_gcOpen=(0)) → (q.n_gate=(2)))) ∧ (q.publication≥(0)) ∧ (q.publication≤(3)) ∧ (q.active≥(0)) ∧ (q.active≤(1)) ∧ (q.attempts≥(0)) ∧ ((q.publication=(1)) → (((q.n_decision=(1)) ∧ (q.p_phase=(2))) ∧ (q.n_destRoot=(1)))) ∧ (((q.publication=(2)) → ((((q.p_phase=(3)) ∨ (q.p_phase=(4))) ∨ (q.p_phase=(5))) ∨ (q.p_phase=(7)))) ∧ (((((q.p_phase=(3)) ∨ (q.p_phase=(4))) ∨ (q.p_phase=(5))) ∨ (q.p_phase=(7))) → (q.publication=(2)))) ∧ ((q.n_decision=(2)) → (q.publication=(2))) ∧ ((q.active=(1)) → (q.n_decision=(2))) ∧ (((q.p_phase=(5)) ∨ (q.p_phase=(7))) → (q.active=(1))) ∧ (q.p_captured=(0)) ∧ (q.p_exited=(0)))) ∧ ((q.wordWins≥(0)) ∧ (q.wordWins≤(3)) ∧ ((q.n_decision≤(1)) → (q.wordWins=(q.n_claims+q.n_done))) ∧ ((q.n_decision≥(2)) → (q.wordWins=((q.n_claims+q.n_done)+(1)))) ∧ (q.word=(q.n_decision+((4)*q.n_done))) ∧ (q.word≥(0)) ∧ (q.word≤(7)) ∧ (q.sExpected≥(0)) ∧ (q.sExpected≤(7)) ∧ (q.sMode≥(0)) ∧ (q.sMode≤(3)) ∧ (q.cExpected≥(0)) ∧ (q.cExpected≤(7)) ∧ (q.cMode≥(0)) ∧ (q.cMode≤(2)) ∧ (q.preparedResult≥(0)) ∧ (q.preparedResult≤(1)) ∧ (q.commitRelease≥(0)) ∧ (q.commitRelease≤(1)) ∧ (q.resultRelease=q.n_done) ∧ (q.aSeen≥(0)) ∧ (q.aSeen≤(1)) ∧ (q.aWord≥(0)) ∧ (q.aWord≤(7)) ∧ (q.activationWord≥(0)) ∧ (q.activationWord≤(2)) ∧ (q.activeRelease=q.active) ∧ (q.carriedCommit=q.activeRelease) ∧ (q.workerSeen≥(0)) ∧ (q.workerSeen≤(1)) ∧ (q.resultSeen≥(0)) ∧ (q.resultSeen≤(1)) ∧ (q.casFailures≥(0)) ∧ ((q.commitRelease=(1)) → (q.n_decision=(2))) ∧ ((q.n_decision=(2)) → (q.commitRelease=(1))) ∧ ((q.aSeen=(1)) → ((q.commitRelease=(1)) ∧ ((q.aWord=(2)) ∨ (q.aWord=(6))))) ∧ ((q.active=(1)) → ((q.aSeen=(1)) ∧ (q.activationWord≥(1)))) ∧ ((q.activationWord≥(1)) → (q.active=(1))) ∧ ((q.activationWord=(1)) → (q.p_phase=(4))) ∧ ((q.activationWord=(2)) → ((q.p_phase=(5)) ∨ (q.p_phase=(7)))) ∧ (((q.p_phase=(5)) ∨ (q.p_phase=(7))) → (q.activationWord=(2))) ∧ ((q.workerSeen=(1)) → ((q.activeRelease=(1)) ∧ (q.carriedCommit=(1)))) ∧ ((q.activationWord=(2)) → (q.workerSeen=(1))) ∧ ((q.resultSeen=(1)) → (q.resultRelease=(1))) ∧ ((q.n_remoteGrants=(1)) → ((q.resultSeen=(1)) ∧ (q.workerSeen=(1)))))) ∧ (((q.commitValue≥(0)) ∧ (q.commitValue≤(7)) ∧ (q.childValue≥(0)) ∧ (q.childValue≤(7)) ∧ (q.childCover≥(0)) ∧ (q.childCover≤(1)) ∧ ((q.commitRelease=(0)) → (q.commitValue=(0))) ∧ ((q.commitRelease=(1)) → ((q.commitValue=(2)) ∨ (q.commitValue=(6)))) ∧ ((q.resultRelease=(0)) → ((q.childValue=(0)) ∧ (q.childCover=(0)))) ∧ ((q.resultRelease=(1)) → (q.childValue≥(4))) ∧ ((q.childValue=(6)) → ((q.childCover=(1)) ∧ (q.commitRelease=(1)))) ∧ ((q.childCover=(1)) → ((q.childValue=(6)) ∧ (q.commitRelease=(1)))) ∧ ((q.commitValue=(6)) → (q.resultRelease=(1))) ∧ (((q.childValue=(5)) ∧ (q.commitRelease=(1))) → (q.commitValue=(6))) ∧ ((q.childValue=(6)) → (q.commitValue=(2))) ∧ (((q.childValue=(4)) ∨ (q.childValue=(7))) → (q.commitRelease=(0))) ∧ ((q.childValue=(4)) → ((q.n_decision=(0)) ∨ (q.n_decision=(3)))) ∧ ((q.childValue=(7)) → (q.n_decision=(3))) ∧ (q.commitValue≤q.word) ∧ (q.childValue≤q.word)) ∧ ((q.activeEvidence=q.active) ∧ (q.claimedEvidence≥(0)) ∧ (q.claimedEvidence≤(1)) ∧ (q.activeIssuer≥(0)) ∧ (q.activeIssuer≤(3)) ∧ (q.activeProofGen≥(0)) ∧ (q.claimedOwner≥(0)) ∧ (q.claimedOwner≤(5)) ∧ (q.claimProofGen≥(0)) ∧ ((q.active=(0)) → ((q.activeIssuer=(0)) ∧ (q.activeProofGen=(0)))) ∧ ((q.active=(1)) → (((q.activeIssuer=(2)) ∨ (q.activeIssuer=(3))) ∧ (q.activeProofGen≥(1)))) ∧ ((q.activeIssuer=(2)) → (q.activeProofGen≤q.a0Gen)) ∧ ((q.activeIssuer=(3)) → (q.activeProofGen≤q.a1Gen)) ∧ ((q.activationWord=(2)) → (((q.claimedEvidence=(1)) ∧ ((q.claimedOwner=(4)) ∨ (q.claimedOwner=(5)))) ∧ (q.claimProofGen≥(1)))) ∧ ((q.activationWord≤(1)) → (((q.claimedEvidence=(0)) ∧ (q.claimedOwner=(0))) ∧ (q.claimProofGen=(0)))) ∧ ((q.claimedOwner=(4)) → (q.claimProofGen=q.w0Gen)) ∧ ((q.claimedOwner=(5)) → (q.claimProofGen=q.w1Gen)) ∧ ((q.n_remoteGrants=(1)) → (((q.claimedOwner=(4)) ∧ (q.r0View=(1))) ∨ ((q.claimedOwner=(5)) ∧ (q.r1View=(1))))) ∧ (q.activeFloor≥(0)) ∧ (q.activeFloor≤(7)) ∧ (q.claimFloor≥(0)) ∧ (q.claimFloor≤(7)) ∧ ((q.active=(0)) → (q.activeFloor=(0))) ∧ ((q.active=(1)) → (((q.activeFloor=(2)) ∨ (q.activeFloor=(6))) ∧ (q.activeFloor≥q.commitValue))) ∧ ((q.activationWord≤(1)) → (q.claimFloor=(0))) ∧ ((q.activationWord=(2)) → (((q.claimFloor=(2)) ∨ (q.claimFloor=(6))) ∧ (q.claimFloor≥q.activeFloor)))) ∧ ((q.sPending≥(0)) ∧ (q.sPending≤(1)) ∧ (q.sOutSuccess≥(0)) ∧ (q.sOutSuccess≤(1)) ∧ (q.sDeliveredValid≥(0)) ∧ (q.sDeliveredValid≤(1)) ∧ (q.sOutExpected≥(0)) ∧ (q.sOutExpected≤(7)) ∧ (q.sOutObserved≥(0)) ∧ (q.sOutObserved≤(7)) ∧ (q.sSnapshot≥(0)) ∧ (q.sSnapshot≤(7)) ∧ (q.sNativeExpected≥(0)) ∧ (q.sNativeExpected≤(7)) ∧ (q.sLegacyExpected≥(0)) ∧ (q.sLegacyExpected≤(7)) ∧ (q.sDeliveredObserved≥(0)) ∧ (q.sDeliveredObserved≤(7)) ∧ (q.sOutObserved=q.sSnapshot) ∧ (q.sNativeExpected=q.sOutObserved) ∧ (q.sLegacyExpected=q.sOutExpected) ∧ ((q.sOutSuccess=(1)) → (q.sOutObserved=q.sOutExpected)) ∧ (q.sCall≥(0)) ∧ (q.sDeliveredCall≥(0)) ∧ (q.sDeliveredCall≤q.sCall) ∧ ((q.sPending=(1)) → ((q.sCall≥(1)) ∧ (q.sDeliveredValid=(0)))) ∧ ((q.sDeliveredValid=(1)) → (((q.sDeliveredObserved=q.sOutObserved) ∧ (q.sDeliveredCall=q.sCall)) ∧ (q.sPending=(0))))) ∧ ((q.cPending≥(0)) ∧ (q.cPending≤(1)) ∧ (q.cOutSuccess≥(0)) ∧ (q.cOutSuccess≤(1)) ∧ (q.cDeliveredValid≥(0)) ∧ (q.cDeliveredValid≤(1)) ∧ (q.cOutExpected≥(0)) ∧ (q.cOutExpected≤(7)) ∧ (q.cOutObserved≥(0)) ∧ (q.cOutObserved≤(7)) ∧ (q.cSnapshot≥(0)) ∧ (q.cSnapshot≤(7)) ∧ (q.cNativeExpected≥(0)) ∧ (q.cNativeExpected≤(7)) ∧ (q.cLegacyExpected≥(0)) ∧ (q.cLegacyExpected≤(7)) ∧ (q.cDeliveredObserved≥(0)) ∧ (q.cDeliveredObserved≤(7)) ∧ (q.cOutObserved=q.cSnapshot) ∧ (q.cNativeExpected=q.cOutObserved) ∧ (q.cLegacyExpected=q.cOutExpected) ∧ ((q.cOutSuccess=(1)) → (q.cOutObserved=q.cOutExpected)) ∧ (q.cCall≥(0)) ∧ (q.cDeliveredCall≥(0)) ∧ (q.cDeliveredCall≤q.cCall) ∧ ((q.cPending=(1)) → ((q.cCall≥(1)) ∧ (q.cDeliveredValid=(0)))) ∧ ((q.cDeliveredValid=(1)) → (((q.cDeliveredObserved=q.cOutObserved) ∧ (q.cDeliveredCall=q.cCall)) ∧ (q.cPending=(0))))) ∧ ((q.a0Gen≥(1)) ∧ (q.a0View≥(0)) ∧ (q.a0View≤(1)) ∧ (q.a0CapGen≥(0)) ∧ (q.a0CapGen≤q.a0Gen) ∧ (q.a0Rf≥(0)) ∧ (q.a0Rf≤(4)) ∧ (q.a0Value≥(0)) ∧ (q.a0Value≤(7)) ∧ ((q.a0View=(1)) → (q.a0CapGen=q.a0Gen)) ∧ ((q.a0View=(1)) → (((q.commitRelease=(1)) ∧ ((q.a0Value=(2)) ∨ (q.a0Value=(6)))) ∧ ((q.a0Rf=(1)) ∨ (q.a0Rf=(2))))) ∧ (((q.a0View=(1)) ∧ (q.a0Rf=(1))) → (q.a0Value=q.commitValue)) ∧ (((q.a0View=(1)) ∧ (q.a0Rf=(2))) → ((q.a0Value=q.childValue) ∧ (q.childCover=(1)))) ∧ (q.a0Floor≥(0)) ∧ (q.a0Floor≤(7)) ∧ ((q.a0View=(1)) → (q.a0Value=q.a0Floor))) ∧ ((q.a1Gen≥(1)) ∧ (q.a1View≥(0)) ∧ (q.a1View≤(1)) ∧ (q.a1CapGen≥(0)) ∧ (q.a1CapGen≤q.a1Gen) ∧ (q.a1Rf≥(0)) ∧ (q.a1Rf≤(4)) ∧ (q.a1Value≥(0)) ∧ (q.a1Value≤(7)) ∧ ((q.a1View=(1)) → (q.a1CapGen=q.a1Gen)) ∧ ((q.a1View=(1)) → (((q.commitRelease=(1)) ∧ ((q.a1Value=(2)) ∨ (q.a1Value=(6)))) ∧ ((q.a1Rf=(1)) ∨ (q.a1Rf=(2))))) ∧ (((q.a1View=(1)) ∧ (q.a1Rf=(1))) → (q.a1Value=q.commitValue)) ∧ (((q.a1View=(1)) ∧ (q.a1Rf=(2))) → ((q.a1Value=q.childValue) ∧ (q.childCover=(1)))) ∧ (q.a1Floor≥(0)) ∧ (q.a1Floor≤(7)) ∧ ((q.a1View=(1)) → (q.a1Value=q.a1Floor))) ∧ ((q.w0Gen≥(1)) ∧ (q.w0View≥(0)) ∧ (q.w0View≤(1)) ∧ (q.w0CapGen≥(0)) ∧ (q.w0CapGen≤q.w0Gen) ∧ (q.w0Rf≥(0)) ∧ (q.w0Rf≤(4)) ∧ (q.w0Value≥(0)) ∧ (q.w0Value≤(7)) ∧ ((q.w0View=(1)) → (q.w0CapGen=q.w0Gen)) ∧ ((q.w0View=(1)) → ((q.activeEvidence=(1)) ∧ (((q.w0Rf=(3)) ∧ (q.w0Value=(1))) ∨ (((q.w0Rf=(4)) ∧ (q.w0Value=(2))) ∧ (q.claimedEvidence=(1)))))) ∧ (q.w0Floor≥(0)) ∧ (q.w0Floor≤(7)) ∧ (q.w0ActiveFloor≥(0)) ∧ (q.w0ActiveFloor≤(2)) ∧ ((q.w0View=(1)) → ((q.w0Floor≥q.activeFloor) ∧ (q.w0ActiveFloor≥q.w0Value))) ∧ (((q.w0Floor=(0)) ∨ (q.w0Floor=(2))) ∨ (q.w0Floor=(6)))) ∧ ((q.w1Gen≥(1)) ∧ (q.w1View≥(0)) ∧ (q.w1View≤(1)) ∧ (q.w1CapGen≥(0)) ∧ (q.w1CapGen≤q.w1Gen) ∧ (q.w1Rf≥(0)) ∧ (q.w1Rf≤(4)) ∧ (q.w1Value≥(0)) ∧ (q.w1Value≤(7)) ∧ ((q.w1View=(1)) → (q.w1CapGen=q.w1Gen)) ∧ ((q.w1View=(1)) → ((q.activeEvidence=(1)) ∧ (((q.w1Rf=(3)) ∧ (q.w1Value=(1))) ∨ (((q.w1Rf=(4)) ∧ (q.w1Value=(2))) ∧ (q.claimedEvidence=(1)))))) ∧ (q.w1Floor≥(0)) ∧ (q.w1Floor≤(7)) ∧ (q.w1ActiveFloor≥(0)) ∧ (q.w1ActiveFloor≤(2)) ∧ ((q.w1View=(1)) → ((q.w1Floor≥q.activeFloor) ∧ (q.w1ActiveFloor≥q.w1Value))) ∧ (((q.w1Floor=(0)) ∨ (q.w1Floor=(2))) ∨ (q.w1Floor=(6)))) ∧ ((q.r0View≥(0)) ∧ (q.r0View≤(1)) ∧ (q.r0Rf≥(0)) ∧ (q.r0Rf≤(2)) ∧ (q.r0Value≥(0)) ∧ (q.r0Value≤(7)) ∧ ((q.r0View=(1)) → (((q.resultRelease=(1)) ∧ (q.r0Value≥(4))) ∧ ((q.r0Rf=(1)) ∨ (q.r0Rf=(2))))) ∧ (((q.r0View=(1)) ∧ (q.r0Rf=(1))) → (q.r0Value=q.commitValue)) ∧ (((q.r0View=(1)) ∧ (q.r0Rf=(2))) → (q.r0Value=q.childValue))) ∧ ((q.r1View≥(0)) ∧ (q.r1View≤(1)) ∧ (q.r1Rf≥(0)) ∧ (q.r1Rf≤(2)) ∧ (q.r1Value≥(0)) ∧ (q.r1Value≤(7)) ∧ ((q.r1View=(1)) → (((q.resultRelease=(1)) ∧ (q.r1Value≥(4))) ∧ ((q.r1Rf=(1)) ∨ (q.r1Rf=(2))))) ∧ (((q.r1View=(1)) ∧ (q.r1Rf=(1))) → (q.r1Value=q.commitValue)) ∧ (((q.r1View=(1)) ∧ (q.r1Rf=(2))) → (q.r1Value=q.childValue)))))
def initial : State := {n_decision:=(0), n_claims:=(0), n_done:=(0), n_resultRoot:=(0), n_sourceRoot:=(1), n_destRoot:=(0), n_childRoot:=(1), n_copyReady:=(0), n_copyRev:=(0), n_viewRev:=(0), n_viewGen:=(0), n_viewLease:=(0), n_patchReady:=(0), n_patchRev:=(0), n_patchGen:=(0), n_patchLease:=(0), n_gate:=(0), n_admitted:=(1), n_generation:=(1), n_grantGen:=(0), n_lease:=(0), n_revision:=(0), n_sourceHeap:=(0), n_localGrants:=(0), n_remoteGrants:=(0), n_copyOps:=(0), n_validations:=(0), n_probes:=(0), p_phase:=(0), p_eligible:=(1), p_claims:=(0), p_probes:=(0), p_childRuns:=(1), p_childDone:=(0), p_sourceRoot:=(1), p_copyRoot:=(0), p_ready:=(0), p_queueRoot:=(0), p_restoreRoot:=(0), p_contextRoot:=(0), p_resultRoot:=(0), p_placeholder:=(0), p_materialized:=(0), p_split:=(0), p_parentOwner:=(0), p_prefixRuns:=(0), p_parentRuns:=(0), p_captured:=(0), p_captureRoot:=(0), p_exited:=(0), p_descriptor:=(1), p_gcOpen:=(1), p_frozen:=(0), p_scanning:=(0), p_scanned:=(0), p_epoch:=(1), p_vSource:=(0), p_vCopy:=(0), p_vQueue:=(0), p_vRestore:=(0), p_vContext:=(0), p_vResult:=(0), p_vCapture:=(0), p_resultPublished:=(0), publication:=(0), active:=(0), attempts:=(0), word:=(0), sExpected:=(0), sMode:=(0), cExpected:=(0), cMode:=(0), preparedResult:=(0), commitRelease:=(0), resultRelease:=(0), aSeen:=(0), aWord:=(0), activationWord:=(0), activeRelease:=(0), carriedCommit:=(0), workerSeen:=(0), resultSeen:=(0), casFailures:=(0), wordWins:=(0), commitValue:=(0), childValue:=(0), childCover:=(0), activeEvidence:=(0), activeIssuer:=(0), activeProofGen:=(0), claimedEvidence:=(0), claimedOwner:=(0), claimProofGen:=(0), activeFloor:=(0), claimFloor:=(0), a0Floor:=(0), a1Floor:=(0), w0Floor:=(0), w1Floor:=(0), w0ActiveFloor:=(0), w1ActiveFloor:=(0), sPending:=(0), sOutExpected:=(0), sOutObserved:=(0), sSnapshot:=(0), sOutSuccess:=(0), sNativeExpected:=(0), sLegacyExpected:=(0), sDeliveredObserved:=(0), sDeliveredValid:=(0), sCall:=(0), sDeliveredCall:=(0), cPending:=(0), cOutExpected:=(0), cOutObserved:=(0), cSnapshot:=(0), cOutSuccess:=(0), cNativeExpected:=(0), cLegacyExpected:=(0), cDeliveredObserved:=(0), cDeliveredValid:=(0), cCall:=(0), cDeliveredCall:=(0), a0View:=(0), a0Rf:=(0), a0Value:=(0), a0CapGen:=(0), a0Gen:=(1), a1View:=(0), a1Rf:=(0), a1Value:=(0), a1CapGen:=(0), a1Gen:=(1), w0View:=(0), w0Rf:=(0), w0Value:=(0), w0CapGen:=(0), w0Gen:=(1), w1View:=(0), w1Rf:=(0), w1Value:=(0), w1CapGen:=(0), w1Gen:=(1), r0View:=(0), r0Rf:=(0), r0Value:=(0), r1View:=(0), r1Rf:=(0), r1Value:=(0)}
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
def loadReserveGuard (q : State) : Prop := ((True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(0))) ∧ (q.n_done=(0)))) ∧ (q.sPending=(0)))
def loadReserveNext (q : State) : State := {q with sExpected:=q.word, sMode:=(1)}
def loadCommitGuard (q : State) : Prop := ((True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(1))) ∧ (q.publication=(2)))) ∧ (q.sPending=(0)))
def loadCommitNext (q : State) : State := {q with sExpected:=q.word, sMode:=(2)}
def loadAbortGuard (q : State) : Prop := ((True ∧ (((q.sMode=(0)) ∧ (q.n_decision=(1))) ∧ ((q.publication=(0)) ∨ (q.publication=(3))))) ∧ (q.sPending=(0)))
def loadAbortNext (q : State) : State := {q with sExpected:=q.word, sMode:=(3)}
def casReserveGuard (q : State) : Prop := ((((((q.n_decision=(0)) ∧ (q.n_done=(0))) ∧ (q.n_admitted=(1))) ∧ ((((((q.p_phase=(0)) ∧ (q.p_eligible=(1))) ∧ (q.p_claims=(0))) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.sMode=(1)) ∧ (q.sExpected=(0))) ∧ (q.sExpected=q.word))) ∧ (q.sPending=(0)))
def casReserveNext (q : State) : State := {q with n_decision:=(1), n_claims:=(q.n_claims+(1)), p_phase:=(1), p_claims:=(q.p_claims+(1)), word:=(q.sExpected+(1)), sMode:=(0), wordWins:=(q.wordWins+(1)), sPending:=(1), sOutExpected:=q.sExpected, sOutObserved:=q.word, sSnapshot:=q.word, sOutSuccess:=(1), sNativeExpected:=q.sExpected, sLegacyExpected:=q.sExpected, sDeliveredValid:=(0), sCall:=(q.sCall+(1))}
def casCommitGuard (q : State) : Prop := (((((((((((((((((q.n_decision=(1)) ∧ (q.n_copyReady=(1))) ∧ (q.n_destRoot=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_patchReady=(1))) ∧ (q.n_patchRev=q.n_revision)) ∧ (q.n_patchGen=q.n_generation)) ∧ (q.n_patchLease=q.n_lease)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ ((((((q.p_phase=(3)) ∧ (q.p_ready=(1))) ∧ (q.p_copyRoot=(1))) ∧ (q.p_queueRoot=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ ((q.publication=(2)) ∧ (q.active=(0)))) ∧ ((q.sMode=(2)) ∧ (q.sExpected=q.word))) ∧ (q.sPending=(0)))
def casCommitNext (q : State) : State := {q with n_decision:=(2), n_sourceRoot:=(0), p_phase:=(4), p_sourceRoot:=(0), p_split:=(1), p_parentOwner:=(1), word:=(q.sExpected+(1)), sMode:=(0), commitRelease:=(1), wordWins:=(q.wordWins+(1)), sPending:=(1), sOutExpected:=q.sExpected, sOutObserved:=q.word, sSnapshot:=q.word, sOutSuccess:=(1), sNativeExpected:=q.sExpected, sLegacyExpected:=q.sExpected, sDeliveredValid:=(0), sCall:=(q.sCall+(1)), commitValue:=(q.sExpected+(1))}
def casAbortGuard (q : State) : Prop := ((((((((((q.n_decision=(1)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ (((((q.p_phase=(1)) ∨ (q.p_phase=(2))) ∧ (q.p_queueRoot=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ ((q.publication=(0)) ∨ (q.publication=(3)))) ∧ ((q.sMode=(3)) ∧ (q.sExpected=q.word))) ∧ (q.sPending=(0)))
def casAbortNext (q : State) : State := {q with n_decision:=(3), n_destRoot:=(0), n_copyReady:=(0), n_copyRev:=(0), n_patchReady:=(0), p_phase:=(0), p_copyRoot:=(0), p_placeholder:=(0), p_ready:=(0), word:=(q.sExpected+(2)), sMode:=(0), wordWins:=(q.wordWins+(1)), sPending:=(1), sOutExpected:=q.sExpected, sOutObserved:=q.word, sSnapshot:=q.word, sOutSuccess:=(1), sNativeExpected:=q.sExpected, sLegacyExpected:=q.sExpected, sDeliveredValid:=(0), sCall:=(q.sCall+(1))}
def loadChildGuard (q : State) : Prop := ((True ∧ (((q.cMode=(0)) ∧ (q.n_done=(0))) ∧ (q.preparedResult=(1)))) ∧ (q.cPending=(0)))
def loadChildNext (q : State) : State := {q with cExpected:=q.word, cMode:=(1)}
def loadLocalGuard (q : State) : Prop := ((True ∧ (((q.cMode=(0)) ∧ (q.n_decision=(0))) ∧ (q.n_done=(1)))) ∧ (q.cPending=(0)))
def loadLocalNext (q : State) : State := {q with cExpected:=q.word, cMode:=(2)}
def casChildLocalGuard (q : State) : Prop := (((((q.n_done=(0)) ∧ (q.n_gate≠(2))) ∧ ((((q.p_phase=(0)) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.cMode=(1)) ∧ (q.cExpected=q.word)) ∧ (q.preparedResult=(1)))) ∧ (q.cPending=(0)))
def casChildLocalNext (q : State) : State := {q with n_done:=(1), n_resultRoot:=(1), p_phase:=(6), p_childDone:=(1), p_resultRoot:=(1), word:=(q.cExpected+(4)), cMode:=(0), resultRelease:=(1), wordWins:=(q.wordWins+(1)), cPending:=(1), cOutExpected:=q.cExpected, cOutObserved:=q.word, cSnapshot:=q.word, cOutSuccess:=(1), cNativeExpected:=q.cExpected, cLegacyExpected:=q.cExpected, cDeliveredValid:=(0), cCall:=(q.cCall+(1)), childValue:=(q.cExpected+(4)), childCover:=q.commitRelease}
def casChildSplitGuard (q : State) : Prop := (((((q.n_done=(0)) ∧ (q.n_gate≠(2))) ∧ ((((((q.p_phase≥(1)) ∧ (q.p_phase≤(5))) ∨ (q.p_phase=(7))) ∧ (q.p_childDone=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (((q.cMode=(1)) ∧ (q.cExpected=q.word)) ∧ (q.preparedResult=(1)))) ∧ (q.cPending=(0)))
def casChildSplitNext (q : State) : State := {q with n_done:=(1), n_resultRoot:=(1), p_childDone:=(1), p_resultRoot:=(1), word:=(q.cExpected+(4)), cMode:=(0), resultRelease:=(1), wordWins:=(q.wordWins+(1)), cPending:=(1), cOutExpected:=q.cExpected, cOutObserved:=q.word, cSnapshot:=q.word, cOutSuccess:=(1), cNativeExpected:=q.cExpected, cLegacyExpected:=q.cExpected, cDeliveredValid:=(0), cCall:=(q.cCall+(1)), childValue:=(q.cExpected+(4)), childCover:=q.commitRelease}
def casCloseLocalGuard (q : State) : Prop := (((((q.n_decision=(0)) ∧ (q.n_done=(1))) ∧ (q.n_gate=(0))) ∧ ((q.cMode=(2)) ∧ (q.cExpected=q.word))) ∧ (q.cPending=(0)))
def casCloseLocalNext (q : State) : State := {q with n_decision:=(3), word:=(q.cExpected+(3)), cMode:=(0), wordWins:=(q.wordWins+(1)), cPending:=(1), cOutExpected:=q.cExpected, cOutObserved:=q.word, cSnapshot:=q.word, cOutSuccess:=(1), cNativeExpected:=q.cExpected, cLegacyExpected:=q.cExpected, cDeliveredValid:=(0), cCall:=(q.cCall+(1))}
def retirePreparedResultGuard (q : State) : Prop := (True ∧ ((((q.n_done=(1)) ∧ (q.n_resultRoot=(1))) ∧ (q.n_gate≠(2))) ∧ (q.p_gcOpen=(1))))
def retirePreparedResultNext (q : State) : State := {q with preparedResult:=(0)}
def splitNativeFailureGuard (q : State) : Prop := ((True ∧ (q.sMode≥(1))) ∧ (q.sPending=(0)))
def splitNativeFailureNext (q : State) : State := {q with sExpected:=q.word, sMode:=(0), casFailures:=(q.casFailures+(1)), sPending:=(1), sOutExpected:=q.sExpected, sOutObserved:=q.word, sSnapshot:=q.word, sOutSuccess:=(0), sNativeExpected:=q.word, sLegacyExpected:=q.sExpected, sDeliveredValid:=(0), sCall:=(q.sCall+(1))}
def splitLegacyFailureGuard (q : State) : Prop := ((True ∧ (q.sMode≥(1))) ∧ ((q.sPending=(0)) ∧ (q.sExpected≠q.word)))
def splitLegacyFailureNext (q : State) : State := {q with sExpected:=q.word, sMode:=(0), casFailures:=(q.casFailures+(1)), sPending:=(1), sOutExpected:=q.sExpected, sOutObserved:=q.word, sSnapshot:=q.word, sOutSuccess:=(0), sNativeExpected:=q.word, sLegacyExpected:=q.sExpected, sDeliveredValid:=(0), sCall:=(q.sCall+(1))}
def deliverSplitterGuard (q : State) : Prop := (True ∧ (q.sPending=(1)))
def deliverSplitterNext (q : State) : State := {q with sPending:=(0), sDeliveredObserved:=q.word, sDeliveredValid:=(1), sDeliveredCall:=q.sCall}
def childNativeFailureGuard (q : State) : Prop := ((True ∧ (q.cMode≥(1))) ∧ (q.cPending=(0)))
def childNativeFailureNext (q : State) : State := {q with cExpected:=q.word, cMode:=(0), casFailures:=(q.casFailures+(1)), cPending:=(1), cOutExpected:=q.cExpected, cOutObserved:=q.word, cSnapshot:=q.word, cOutSuccess:=(0), cNativeExpected:=q.word, cLegacyExpected:=q.cExpected, cDeliveredValid:=(0), cCall:=(q.cCall+(1))}
def childLegacyFailureGuard (q : State) : Prop := ((True ∧ (q.cMode≥(1))) ∧ ((q.cPending=(0)) ∧ (q.cExpected≠q.word)))
def childLegacyFailureNext (q : State) : State := {q with cExpected:=q.word, cMode:=(0), casFailures:=(q.casFailures+(1)), cPending:=(1), cOutExpected:=q.cExpected, cOutObserved:=q.word, cSnapshot:=q.word, cOutSuccess:=(0), cNativeExpected:=q.word, cLegacyExpected:=q.cExpected, cDeliveredValid:=(0), cCall:=(q.cCall+(1))}
def deliverChildGuard (q : State) : Prop := (True ∧ (q.cPending=(1)))
def deliverChildNext (q : State) : State := {q with cPending:=(0), cDeliveredObserved:=q.cOutObserved, cDeliveredValid:=(1), cDeliveredCall:=q.cCall}
def acquireCommitA0Guard (q : State) : Prop := ((True ∧ ((q.n_decision=(2)) ∧ (q.commitRelease=(1)))) ∧ ((q.commitValue≥(2)) ∧ (q.commitValue≥q.a0Floor)))
def acquireCommitA0Next (q : State) : State := {q with aSeen:=(1), aWord:=q.word, a0View:=(1), a0Rf:=(1), a0Value:=q.commitValue, a0CapGen:=q.a0Gen, a0Floor:=q.commitValue}
def acquireChildA0Guard (q : State) : Prop := ((True ∧ ((q.n_decision=(2)) ∧ (q.commitRelease=(1)))) ∧ (((q.childValue=(6)) ∧ (q.childCover=(1))) ∧ (q.childValue≥q.a0Floor)))
def acquireChildA0Next (q : State) : State := {q with aSeen:=(1), aWord:=q.word, a0View:=(1), a0Rf:=(2), a0Value:=q.childValue, a0CapGen:=q.a0Gen, a0Floor:=q.childValue}
def activateA0Guard (q : State) : Prop := ((((((q.n_decision=(2)) ∧ (q.p_phase=(4))) ∧ (q.active=(0))) ∧ (q.n_gate=(0))) ∧ ((q.aSeen=(1)) ∧ (q.activationWord=(0)))) ∧ ((q.a0View=(1)) ∧ (q.a0CapGen=q.a0Gen)))
def activateA0Next (q : State) : State := {q with active:=(1), activationWord:=(1), activeRelease:=(1), carriedCommit:=(1), activeEvidence:=q.a0View, activeIssuer:=(2), activeProofGen:=q.a0CapGen, activeFloor:=q.a0Value}
def acquireActiveW0Guard (q : State) : Prop := ((True ∧ (((q.activationWord≥(1)) ∧ (q.activeRelease=(1))) ∧ (q.carriedCommit=(1)))) ∧ (((q.activeEvidence=(1)) ∧ (q.activeFloor≥q.w0Floor)) ∧ (q.w0ActiveFloor≤(1))))
def acquireActiveW0Next (q : State) : State := {q with workerSeen:=(1), w0View:=(1), w0Rf:=(3), w0Value:=(1), w0CapGen:=q.w0Gen, w0Floor:=q.activeFloor, w0ActiveFloor:=(1)}
def failedClaimAcquireW0Guard (q : State) : Prop := ((True ∧ (((q.activationWord≥(1)) ∧ (q.activeRelease=(1))) ∧ (q.carriedCommit=(1)))) ∧ ((((q.activationWord=(2)) ∧ (q.claimedEvidence=(1))) ∧ (q.activeEvidence=(1))) ∧ (q.claimFloor≥q.w0Floor)))
def failedClaimAcquireW0Next (q : State) : State := {q with workerSeen:=(1), w0View:=(1), w0Rf:=(4), w0Value:=(2), w0CapGen:=q.w0Gen, w0Floor:=q.claimFloor, w0ActiveFloor:=(2)}
def claimW0Guard (q : State) : Prop := ((((((((q.p_phase=(4)) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ ((q.active=(1)) ∧ (q.n_gate=(0)))) ∧ ((q.workerSeen=(1)) ∧ (q.activationWord=(1)))) ∧ ((q.w0View=(1)) ∧ (q.w0CapGen=q.w0Gen)))
def claimW0Next (q : State) : State := {q with p_phase:=(5), p_queueRoot:=(0), p_restoreRoot:=(1), p_parentOwner:=(2), activationWord:=(2), claimedEvidence:=q.w0View, claimedOwner:=(4), claimProofGen:=q.w0CapGen, claimFloor:=q.w0Floor, w0ActiveFloor:=(2)}
def resultChildW0Guard (q : State) : Prop := ((True ∧ ((q.n_done=(1)) ∧ (q.resultRelease=(1)))) ∧ (((q.claimedOwner=(4)) ∧ (q.childValue=(6))) ∧ (q.childValue≥q.w0Floor)))
def resultChildW0Next (q : State) : State := {q with resultSeen:=(1), r0View:=(1), r0Rf:=(2), r0Value:=q.childValue, w0Floor:=q.childValue}
def resultCommitW0Guard (q : State) : Prop := ((True ∧ ((q.n_done=(1)) ∧ (q.resultRelease=(1)))) ∧ (((q.claimedOwner=(4)) ∧ (q.commitValue=(6))) ∧ (q.commitValue≥q.w0Floor)))
def resultCommitW0Next (q : State) : State := {q with resultSeen:=(1), r0View:=(1), r0Rf:=(1), r0Value:=q.commitValue, w0Floor:=q.commitValue}
def grantW0Guard (q : State) : Prop := ((((((((((((((q.n_decision=(2)) ∧ (q.n_done=(1))) ∧ (q.n_remoteGrants=(0))) ∧ (q.n_copyReady=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ ((((((q.p_phase=(7)) ∧ (q.p_prefixRuns=(1))) ∧ (q.p_resultPublished=(1))) ∧ (q.p_parentRuns=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (q.active=(1))) ∧ ((q.resultSeen=(1)) ∧ (q.workerSeen=(1)))) ∧ ((((q.claimedOwner=(4)) ∧ (q.r0View=(1))) ∧ (q.w0View=(1))) ∧ (q.w0CapGen=q.w0Gen)))
def grantW0Next (q : State) : State := {q with n_remoteGrants:=(q.n_remoteGrants+(1)), p_parentRuns:=(1)}
def renewA0Guard (q : State) : Prop := True
def renewA0Next (q : State) : State := {q with a0View:=(0), a0Rf:=(0), a0Value:=(0), a0CapGen:=(0), a0Gen:=(q.a0Gen+(1))}
def renewW0Guard (q : State) : Prop := (True ∧ (q.claimedOwner≠(4)))
def renewW0Next (q : State) : State := {q with w0View:=(0), w0Rf:=(0), w0Value:=(0), w0CapGen:=(0), w0Gen:=(q.w0Gen+(1)), r0View:=(0), r0Rf:=(0), r0Value:=(0)}
def acquireCommitA1Guard (q : State) : Prop := ((True ∧ ((q.n_decision=(2)) ∧ (q.commitRelease=(1)))) ∧ ((q.commitValue≥(2)) ∧ (q.commitValue≥q.a1Floor)))
def acquireCommitA1Next (q : State) : State := {q with aSeen:=(1), aWord:=q.word, a1View:=(1), a1Rf:=(1), a1Value:=q.commitValue, a1CapGen:=q.a1Gen, a1Floor:=q.commitValue}
def acquireChildA1Guard (q : State) : Prop := ((True ∧ ((q.n_decision=(2)) ∧ (q.commitRelease=(1)))) ∧ (((q.childValue=(6)) ∧ (q.childCover=(1))) ∧ (q.childValue≥q.a1Floor)))
def acquireChildA1Next (q : State) : State := {q with aSeen:=(1), aWord:=q.word, a1View:=(1), a1Rf:=(2), a1Value:=q.childValue, a1CapGen:=q.a1Gen, a1Floor:=q.childValue}
def activateA1Guard (q : State) : Prop := ((((((q.n_decision=(2)) ∧ (q.p_phase=(4))) ∧ (q.active=(0))) ∧ (q.n_gate=(0))) ∧ ((q.aSeen=(1)) ∧ (q.activationWord=(0)))) ∧ ((q.a1View=(1)) ∧ (q.a1CapGen=q.a1Gen)))
def activateA1Next (q : State) : State := {q with active:=(1), activationWord:=(1), activeRelease:=(1), carriedCommit:=(1), activeEvidence:=q.a1View, activeIssuer:=(3), activeProofGen:=q.a1CapGen, activeFloor:=q.a1Value}
def acquireActiveW1Guard (q : State) : Prop := ((True ∧ (((q.activationWord≥(1)) ∧ (q.activeRelease=(1))) ∧ (q.carriedCommit=(1)))) ∧ (((q.activeEvidence=(1)) ∧ (q.activeFloor≥q.w1Floor)) ∧ (q.w1ActiveFloor≤(1))))
def acquireActiveW1Next (q : State) : State := {q with workerSeen:=(1), w1View:=(1), w1Rf:=(3), w1Value:=(1), w1CapGen:=q.w1Gen, w1Floor:=q.activeFloor, w1ActiveFloor:=(1)}
def failedClaimAcquireW1Guard (q : State) : Prop := ((True ∧ (((q.activationWord≥(1)) ∧ (q.activeRelease=(1))) ∧ (q.carriedCommit=(1)))) ∧ ((((q.activationWord=(2)) ∧ (q.claimedEvidence=(1))) ∧ (q.activeEvidence=(1))) ∧ (q.claimFloor≥q.w1Floor)))
def failedClaimAcquireW1Next (q : State) : State := {q with workerSeen:=(1), w1View:=(1), w1Rf:=(4), w1Value:=(2), w1CapGen:=q.w1Gen, w1Floor:=q.claimFloor, w1ActiveFloor:=(2)}
def claimW1Guard (q : State) : Prop := ((((((((q.p_phase=(4)) ∧ (q.p_queueRoot=(1))) ∧ (q.p_split=(1))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0))) ∧ ((q.active=(1)) ∧ (q.n_gate=(0)))) ∧ ((q.workerSeen=(1)) ∧ (q.activationWord=(1)))) ∧ ((q.w1View=(1)) ∧ (q.w1CapGen=q.w1Gen)))
def claimW1Next (q : State) : State := {q with p_phase:=(5), p_queueRoot:=(0), p_restoreRoot:=(1), p_parentOwner:=(2), activationWord:=(2), claimedEvidence:=q.w1View, claimedOwner:=(5), claimProofGen:=q.w1CapGen, claimFloor:=q.w1Floor, w1ActiveFloor:=(2)}
def resultChildW1Guard (q : State) : Prop := ((True ∧ ((q.n_done=(1)) ∧ (q.resultRelease=(1)))) ∧ (((q.claimedOwner=(5)) ∧ (q.childValue=(6))) ∧ (q.childValue≥q.w1Floor)))
def resultChildW1Next (q : State) : State := {q with resultSeen:=(1), r1View:=(1), r1Rf:=(2), r1Value:=q.childValue, w1Floor:=q.childValue}
def resultCommitW1Guard (q : State) : Prop := ((True ∧ ((q.n_done=(1)) ∧ (q.resultRelease=(1)))) ∧ (((q.claimedOwner=(5)) ∧ (q.commitValue=(6))) ∧ (q.commitValue≥q.w1Floor)))
def resultCommitW1Next (q : State) : State := {q with resultSeen:=(1), r1View:=(1), r1Rf:=(1), r1Value:=q.commitValue, w1Floor:=q.commitValue}
def grantW1Guard (q : State) : Prop := ((((((((((((((q.n_decision=(2)) ∧ (q.n_done=(1))) ∧ (q.n_remoteGrants=(0))) ∧ (q.n_copyReady=(1))) ∧ (q.n_copyRev=q.n_revision)) ∧ (q.n_gate=(1))) ∧ (q.n_grantGen=q.n_generation)) ∧ (q.n_viewGen=q.n_generation)) ∧ (q.n_viewLease=q.n_lease)) ∧ (q.n_viewRev=q.n_revision)) ∧ ((((((q.p_phase=(7)) ∧ (q.p_prefixRuns=(1))) ∧ (q.p_resultPublished=(1))) ∧ (q.p_parentRuns=(0))) ∧ (q.p_gcOpen=(1))) ∧ (q.p_frozen=(0)))) ∧ (q.active=(1))) ∧ ((q.resultSeen=(1)) ∧ (q.workerSeen=(1)))) ∧ ((((q.claimedOwner=(5)) ∧ (q.r1View=(1))) ∧ (q.w1View=(1))) ∧ (q.w1CapGen=q.w1Gen)))
def grantW1Next (q : State) : State := {q with n_remoteGrants:=(q.n_remoteGrants+(1)), p_parentRuns:=(1)}
def renewA1Guard (q : State) : Prop := True
def renewA1Next (q : State) : State := {q with a1View:=(0), a1Rf:=(0), a1Value:=(0), a1CapGen:=(0), a1Gen:=(q.a1Gen+(1))}
def renewW1Guard (q : State) : Prop := (True ∧ (q.claimedOwner≠(5)))
def renewW1Next (q : State) : State := {q with w1View:=(0), w1Rf:=(0), w1Value:=(0), w1CapGen:=(0), w1Gen:=(q.w1Gen+(1)), r1View:=(0), r1Rf:=(0), r1Value:=(0)}
def Step (q r : State) : Prop := (allocateGuard q ∧ r=allocateNext q) ∨ (enterGuard q ∧ r=enterNext q) ∨ (resolveGuard q ∧ r=resolveNext q) ∨ (initializeGuard q ∧ r=initializeNext q) ∨ (validateGuard q ∧ r=validateNext q) ∨ (prepareGuard q ∧ r=prepareNext q) ∨ (sendPublicationGuard q ∧ r=sendPublicationNext q) ∨ (publicationUnknownGuard q ∧ r=publicationUnknownNext q) ∨ (acceptPublicationGuard q ∧ r=acceptPublicationNext q) ∨ (rejectPublicationGuard q ∧ r=rejectPublicationNext q) ∨ (activationFailedGuard q ∧ r=activationFailedNext q) ∨ (wakeFailedGuard q ∧ r=wakeFailedNext q) ∨ (restoreGuard q ∧ r=restoreNext q) ∨ (finishAbortedGuard q ∧ r=finishAbortedNext q) ∨ (publishResultGuard q ∧ r=publishResultNext q) ∨ (runPrefixGuard q ∧ r=runPrefixNext q) ∨ (grantLocalGuard q ∧ r=grantLocalNext q) ∨ (leaveGuard q ∧ r=leaveNext q) ∨ (gcEnterGuard q ∧ r=gcEnterNext q) ∨ (gcFreezeGuard q ∧ r=gcFreezeNext q) ∨ (gcBeginGuard q ∧ r=gcBeginNext q) ∨ (forwardNoCopyGuard q ∧ r=forwardNoCopyNext q) ∨ (forwardWithCopyGuard q ∧ r=forwardWithCopyNext q) ∨ (gcEndGuard q ∧ r=gcEndNext q) ∨ (gcLeaveGuard q ∧ r=gcLeaveNext q) ∨ (closeDomainGuard q ∧ r=closeDomainNext q) ∨ (resetDomainGuard q ∧ r=resetDomainNext q) ∨ (prepareResultGuard q ∧ r=prepareResultNext q) ∨ (loadReserveGuard q ∧ r=loadReserveNext q) ∨ (loadCommitGuard q ∧ r=loadCommitNext q) ∨ (loadAbortGuard q ∧ r=loadAbortNext q) ∨ (casReserveGuard q ∧ r=casReserveNext q) ∨ (casCommitGuard q ∧ r=casCommitNext q) ∨ (casAbortGuard q ∧ r=casAbortNext q) ∨ (loadChildGuard q ∧ r=loadChildNext q) ∨ (loadLocalGuard q ∧ r=loadLocalNext q) ∨ (casChildLocalGuard q ∧ r=casChildLocalNext q) ∨ (casChildSplitGuard q ∧ r=casChildSplitNext q) ∨ (casCloseLocalGuard q ∧ r=casCloseLocalNext q) ∨ (retirePreparedResultGuard q ∧ r=retirePreparedResultNext q) ∨ (splitNativeFailureGuard q ∧ r=splitNativeFailureNext q) ∨ (splitLegacyFailureGuard q ∧ r=splitLegacyFailureNext q) ∨ (deliverSplitterGuard q ∧ r=deliverSplitterNext q) ∨ (childNativeFailureGuard q ∧ r=childNativeFailureNext q) ∨ (childLegacyFailureGuard q ∧ r=childLegacyFailureNext q) ∨ (deliverChildGuard q ∧ r=deliverChildNext q) ∨ (acquireCommitA0Guard q ∧ r=acquireCommitA0Next q) ∨ (acquireChildA0Guard q ∧ r=acquireChildA0Next q) ∨ (activateA0Guard q ∧ r=activateA0Next q) ∨ (acquireActiveW0Guard q ∧ r=acquireActiveW0Next q) ∨ (failedClaimAcquireW0Guard q ∧ r=failedClaimAcquireW0Next q) ∨ (claimW0Guard q ∧ r=claimW0Next q) ∨ (resultChildW0Guard q ∧ r=resultChildW0Next q) ∨ (resultCommitW0Guard q ∧ r=resultCommitW0Next q) ∨ (grantW0Guard q ∧ r=grantW0Next q) ∨ (renewA0Guard q ∧ r=renewA0Next q) ∨ (renewW0Guard q ∧ r=renewW0Next q) ∨ (acquireCommitA1Guard q ∧ r=acquireCommitA1Next q) ∨ (acquireChildA1Guard q ∧ r=acquireChildA1Next q) ∨ (activateA1Guard q ∧ r=activateA1Next q) ∨ (acquireActiveW1Guard q ∧ r=acquireActiveW1Next q) ∨ (failedClaimAcquireW1Guard q ∧ r=failedClaimAcquireW1Next q) ∨ (claimW1Guard q ∧ r=claimW1Next q) ∨ (resultChildW1Guard q ∧ r=resultChildW1Next q) ∨ (resultCommitW1Guard q ∧ r=resultCommitW1Next q) ∨ (grantW1Guard q ∧ r=grantW1Next q) ∨ (renewA1Guard q ∧ r=renewA1Next q) ∨ (renewW1Guard q ∧ r=renewW1Next q) ∨ r=q
end AtomicOwnerAst
