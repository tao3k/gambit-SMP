module future_control_word {
// Research CAS interleavings and conditional reads-from witnesses; not a C23 axiomatic memory model.
type State={n_decision:int,n_claims:int,n_done:int,n_resultRoot:int,n_sourceRoot:int,n_destRoot:int,n_childRoot:int,n_copyReady:int,n_copyRev:int,n_viewRev:int,n_viewGen:int,n_viewLease:int,n_patchReady:int,n_patchRev:int,n_patchGen:int,n_patchLease:int,n_gate:int,n_admitted:int,n_generation:int,n_grantGen:int,n_lease:int,n_revision:int,n_sourceHeap:int,n_localGrants:int,n_remoteGrants:int,n_copyOps:int,n_validations:int,n_probes:int,p_phase:int,p_eligible:int,p_claims:int,p_probes:int,p_childRuns:int,p_childDone:int,p_sourceRoot:int,p_copyRoot:int,p_ready:int,p_queueRoot:int,p_restoreRoot:int,p_contextRoot:int,p_resultRoot:int,p_placeholder:int,p_materialized:int,p_split:int,p_parentOwner:int,p_prefixRuns:int,p_parentRuns:int,p_captured:int,p_captureRoot:int,p_exited:int,p_descriptor:int,p_gcOpen:int,p_frozen:int,p_scanning:int,p_scanned:int,p_epoch:int,p_vSource:int,p_vCopy:int,p_vQueue:int,p_vRestore:int,p_vContext:int,p_vResult:int,p_vCapture:int,p_resultPublished:int,publication:int,active:int,attempts:int,word:int,sExpected:int,sMode:int,cExpected:int,cMode:int,preparedResult:int,commitRelease:int,resultRelease:int,aSeen:int,aWord:int,activationWord:int,activeRelease:int,carriedCommit:int,workerSeen:int,resultSeen:int,casFailures:int,wordWins:int}
pure val initial:State={n_decision:0,n_claims:0,n_done:0,n_resultRoot:0,n_sourceRoot:1,n_destRoot:0,n_childRoot:1,n_copyReady:0,n_copyRev:0,n_viewRev:0,n_viewGen:0,n_viewLease:0,n_patchReady:0,n_patchRev:0,n_patchGen:0,n_patchLease:0,n_gate:0,n_admitted:1,n_generation:1,n_grantGen:0,n_lease:0,n_revision:0,n_sourceHeap:0,n_localGrants:0,n_remoteGrants:0,n_copyOps:0,n_validations:0,n_probes:0,p_phase:0,p_eligible:1,p_claims:0,p_probes:0,p_childRuns:1,p_childDone:0,p_sourceRoot:1,p_copyRoot:0,p_ready:0,p_queueRoot:0,p_restoreRoot:0,p_contextRoot:0,p_resultRoot:0,p_placeholder:0,p_materialized:0,p_split:0,p_parentOwner:0,p_prefixRuns:0,p_parentRuns:0,p_captured:0,p_captureRoot:0,p_exited:0,p_descriptor:1,p_gcOpen:1,p_frozen:0,p_scanning:0,p_scanned:0,p_epoch:1,p_vSource:0,p_vCopy:0,p_vQueue:0,p_vRestore:0,p_vContext:0,p_vResult:0,p_vCapture:0,p_resultPublished:0,publication:0,active:0,attempts:0,word:0,sExpected:0,sMode:0,cExpected:0,cMode:0,preparedResult:0,commitRelease:0,resultRelease:0,aSeen:0,aWord:0,activationWord:0,activeRelease:0,carriedCommit:0,workerSeen:0,resultSeen:0,casFailures:0,wordWins:0}
var s:State
action init=s'=initial
val safe=all{all{all{s.n_decision>=0,
s.n_decision<=3,
s.n_claims>=0,
s.n_claims<=1,
s.n_done>=0,
s.n_done<=1,
s.n_resultRoot>=0,
s.n_resultRoot<=1,
s.n_sourceRoot>=0,
s.n_sourceRoot<=1,
s.n_destRoot>=0,
s.n_destRoot<=1,
s.n_childRoot>=0,
s.n_childRoot<=1,
s.n_copyReady>=0,
s.n_copyReady<=1,
s.n_copyRev>=0,
s.n_viewRev>=0,
s.n_viewGen>=0,
s.n_viewLease>=0,
s.n_patchReady>=0,
s.n_patchReady<=1,
s.n_patchRev>=0,
s.n_patchGen>=0,
s.n_patchLease>=0,
s.n_gate>=0,
s.n_gate<=2,
s.n_admitted>=0,
s.n_admitted<=1,
s.n_generation>=0,
s.n_grantGen>=0,
s.n_lease>=0,
s.n_revision>=0,
s.n_sourceHeap>=0,
s.n_sourceHeap<=1,
s.n_localGrants>=0,
s.n_localGrants<=1,
s.n_remoteGrants>=0,
s.n_remoteGrants<=1,
s.n_copyOps>=0,
s.n_validations>=0,
s.n_probes>=0,
s.n_copyOps<=1,
(s.n_copyOps==1) implies (s.n_copyReady==1 or s.n_decision==3),
s.n_generation>=1,
s.n_viewRev<=s.n_revision,
s.n_copyRev<=s.n_revision,
s.n_patchRev<=s.n_revision,
s.n_viewGen<=s.n_generation,
s.n_patchGen<=s.n_generation,
s.n_grantGen<=s.n_generation,
s.n_viewLease<=s.n_lease,
s.n_patchLease<=s.n_lease,
s.n_childRoot==1,
s.n_sourceRoot+s.n_destRoot>=1,
s.n_localGrants+s.n_remoteGrants<=1,
(s.n_done==1) implies (s.n_resultRoot==1),
(s.n_resultRoot==1) implies (s.n_done==1),
(s.n_decision==0) implies (s.n_claims==0 and s.n_sourceRoot==1 and s.n_destRoot==0 and s.n_copyReady==0 and s.n_localGrants==0 and s.n_remoteGrants==0),
(s.n_decision==1) implies (s.n_claims==1 and s.n_sourceRoot==1 and s.n_localGrants==0 and s.n_remoteGrants==0),
(s.n_decision==2) implies (s.n_claims==1 and s.n_sourceRoot==0 and s.n_destRoot==1 and s.n_copyReady==1 and s.n_localGrants==0),
(s.n_decision==3) implies (s.n_sourceRoot==1 and s.n_destRoot==0 and s.n_copyReady==0 and s.n_remoteGrants==0),
(s.n_copyReady==1) implies (s.n_destRoot==1 and (s.n_decision==1 or s.n_decision==2) and s.n_copyRev==s.n_revision),
(s.n_destRoot==1) implies (s.n_claims==1 and (s.n_decision==1 or s.n_decision==2)),
(s.n_localGrants==1) implies (s.n_decision==3 and s.n_done==1 and s.n_resultRoot==1),
(s.n_remoteGrants==1) implies (s.n_decision==2 and s.n_done==1 and s.n_resultRoot==1),
(s.n_gate>=1) implies (s.n_grantGen==s.n_generation),
(s.n_gate==1) implies (s.n_lease>=1),
(s.n_patchReady==1) implies (s.n_copyReady==1 and s.n_destRoot==1),
(s.n_copyOps==0) implies (s.n_copyReady==0 and s.n_patchReady==0)},
all{s.p_phase>=0,
s.p_phase<=9,
s.p_eligible>=0,
s.p_eligible<=1,
s.p_claims>=0,
s.p_claims<=1,
s.p_probes>=0,
s.p_childRuns>=0,
s.p_childRuns<=1,
s.p_childDone>=0,
s.p_childDone<=1,
s.p_sourceRoot>=0,
s.p_sourceRoot<=1,
s.p_copyRoot>=0,
s.p_copyRoot<=1,
s.p_ready>=0,
s.p_ready<=1,
s.p_queueRoot>=0,
s.p_queueRoot<=1,
s.p_restoreRoot>=0,
s.p_restoreRoot<=1,
s.p_contextRoot>=0,
s.p_contextRoot<=1,
s.p_resultRoot>=0,
s.p_resultRoot<=1,
s.p_placeholder>=0,
s.p_placeholder<=1,
s.p_materialized>=0,
s.p_materialized<=1,
s.p_split>=0,
s.p_split<=1,
s.p_parentOwner>=0,
s.p_parentOwner<=3,
s.p_prefixRuns>=0,
s.p_prefixRuns<=1,
s.p_parentRuns>=0,
s.p_captured>=0,
s.p_captured<=1,
s.p_captureRoot>=0,
s.p_captureRoot<=1,
s.p_exited>=0,
s.p_exited<=1,
s.p_descriptor>=0,
s.p_descriptor<=1,
s.p_gcOpen>=0,
s.p_gcOpen<=1,
s.p_frozen>=0,
s.p_frozen<=1,
s.p_scanning>=0,
s.p_scanning<=1,
s.p_scanned>=0,
s.p_scanned<=1,
s.p_epoch>=0,
s.p_vSource>=0,
s.p_vSource<=1,
s.p_vCopy>=0,
s.p_vCopy<=1,
s.p_vQueue>=0,
s.p_vQueue<=1,
s.p_vRestore>=0,
s.p_vRestore<=1,
s.p_vContext>=0,
s.p_vContext<=1,
s.p_vResult>=0,
s.p_vResult<=1,
s.p_vCapture>=0,
s.p_vCapture<=1,
s.p_resultPublished>=0,
s.p_resultPublished<=1,
s.p_epoch>=1,
s.p_childRuns==1,
(s.p_phase<=3 or s.p_phase==6) implies (s.p_sourceRoot==1),
(s.p_phase>=1 and s.p_phase<=5) implies (s.p_claims==1 and s.p_eligible==1),
(s.p_phase==0) implies (s.p_split==0 and s.p_ready==0 and s.p_copyRoot==0 and s.p_queueRoot==0 and s.p_parentOwner==0 and s.p_placeholder==0),
(s.p_phase==1) implies (s.p_ready==0 and s.p_queueRoot==0 and s.p_split==0),
(s.p_phase==2) implies (s.p_copyRoot==1 and s.p_ready==1 and s.p_queueRoot==0 and s.p_split==0),
(s.p_phase==3) implies (s.p_copyRoot==1 and s.p_ready==1 and s.p_queueRoot==1 and s.p_split==0),
(s.p_phase==4) implies (s.p_copyRoot==1 and s.p_ready==1 and s.p_queueRoot==1 and s.p_split==1 and s.p_parentOwner==1),
(s.p_phase==5) implies (s.p_copyRoot==1 and s.p_ready==1 and s.p_queueRoot==0 and s.p_restoreRoot==1 and s.p_split==1 and s.p_parentOwner==2),
(s.p_phase==6) implies (s.p_childDone==1 and s.p_resultRoot==1 and s.p_split==0 and s.p_parentOwner==0),
(s.p_phase==7) implies (s.p_contextRoot==1 and s.p_copyRoot==0 and s.p_restoreRoot==0 and s.p_queueRoot==0 and s.p_split==1 and s.p_parentOwner==3 and s.p_ready==1),
(s.p_phase<8) implies (s.p_descriptor==1),
(s.p_phase>=8) implies (s.p_sourceRoot==0 and s.p_copyRoot==0 and s.p_queueRoot==0 and s.p_restoreRoot==0 and s.p_contextRoot==0 and s.p_resultRoot==0 and s.p_captureRoot==0 and s.p_captured==0 and s.p_placeholder==0 and s.p_exited==1),
(s.p_queueRoot==1) implies (s.p_phase==3 or s.p_phase==4),
(s.p_copyRoot==1) implies (s.p_placeholder==1 and s.p_materialized==1 and s.p_phase>=1 and s.p_phase<=5),
(s.p_restoreRoot==1) implies (s.p_phase==5),
(s.p_contextRoot==1) implies (s.p_phase==7),
(s.p_ready==1) implies (s.p_phase>=2 and s.p_phase<=7 and s.p_phase!=6),
(s.p_split==1) implies (s.p_phase>=4 and s.p_claims==1 and s.p_materialized==1),
(s.p_parentOwner>=1) implies (s.p_split==1),
(s.p_childDone==1 and s.p_phase<8) implies (s.p_resultRoot==1),
(s.p_resultPublished==1) implies (s.p_childDone==1 and s.p_split==1),
(s.p_parentRuns>=1) implies (s.p_phase>=6 and s.p_childDone==1 and s.p_prefixRuns==1),
(s.p_parentRuns>=1 and s.p_split==1) implies (s.p_resultPublished==1),
(s.p_captured==1) implies (s.p_captureRoot==1 and s.p_parentRuns>=1 and (s.p_phase==6 or s.p_phase==7) and s.p_exited==0),
(s.p_captureRoot==1) implies (s.p_captured==1),
(s.p_phase<6) implies (s.p_parentRuns==0 and s.p_prefixRuns==0 and s.p_captured==0 and s.p_exited==0),
(s.p_exited==1) implies (s.p_parentRuns>=1 and s.p_captured==0),
(s.p_materialized==1) implies (s.p_claims==1),
(s.p_frozen==1) implies (s.p_gcOpen==0 and s.p_sourceRoot==s.p_vSource and s.p_copyRoot==s.p_vCopy and s.p_queueRoot==s.p_vQueue and s.p_restoreRoot==s.p_vRestore and s.p_contextRoot==s.p_vContext and s.p_resultRoot==s.p_vResult and s.p_captureRoot==s.p_vCapture),
(s.p_scanning==1) implies (s.p_frozen==1 and s.p_scanned==0),
(s.p_scanned==1) implies (s.p_frozen==1 and s.p_scanning==0)},
all{s.n_done==s.p_childDone,
s.n_resultRoot==s.p_resultRoot,
s.n_claims==s.p_claims,
s.n_sourceRoot==s.p_sourceRoot,
s.n_destRoot==s.p_copyRoot+s.p_contextRoot,
s.n_copyReady==s.p_ready,
((s.n_decision==2) implies (s.p_split==1)) and ((s.p_split==1) implies (s.n_decision==2)),
(s.n_decision==0) implies (s.p_phase==0 or s.p_phase==6),
(s.n_decision==1) implies (s.p_phase>=1 and s.p_phase<=3),
(s.n_decision==3) implies (s.p_phase==0 or s.p_phase==6),
s.p_phase<=7,
s.p_parentRuns==s.n_localGrants+s.n_remoteGrants,
((s.n_gate==2) implies (s.p_gcOpen==0)) and ((s.p_gcOpen==0) implies (s.n_gate==2)),
s.publication>=0,
s.publication<=3,
s.active>=0,
s.active<=1,
s.attempts>=0,
(s.publication==1) implies (s.n_decision==1 and s.p_phase==2 and s.n_destRoot==1),
((s.publication==2) implies (s.p_phase==3 or s.p_phase==4 or s.p_phase==5 or s.p_phase==7)) and ((s.p_phase==3 or s.p_phase==4 or s.p_phase==5 or s.p_phase==7) implies (s.publication==2)),
(s.n_decision==2) implies (s.publication==2),
(s.active==1) implies (s.n_decision==2),
(s.p_phase==5 or s.p_phase==7) implies (s.active==1),
s.p_captured==0,
s.p_exited==0}},all{s.wordWins>=0,
s.wordWins<=3,
(s.n_decision<=1) implies (s.wordWins==s.n_claims+s.n_done),
(s.n_decision>=2) implies (s.wordWins==s.n_claims+s.n_done+1),
s.word==s.n_decision+4*s.n_done,
s.word>=0,
s.word<=7,
s.sExpected>=0,
s.sExpected<=7,
s.sMode>=0,
s.sMode<=3,
s.cExpected>=0,
s.cExpected<=7,
s.cMode>=0,
s.cMode<=2,
s.preparedResult>=0,
s.preparedResult<=1,
s.commitRelease>=0,
s.commitRelease<=1,
s.resultRelease==s.n_done,
s.aSeen>=0,
s.aSeen<=1,
s.aWord>=0,
s.aWord<=7,
s.activationWord>=0,
s.activationWord<=2,
s.activeRelease==s.active,
s.carriedCommit==s.activeRelease,
s.workerSeen>=0,
s.workerSeen<=1,
s.resultSeen>=0,
s.resultSeen<=1,
s.casFailures>=0,
(s.commitRelease==1) implies (s.n_decision==2),
(s.n_decision==2) implies (s.commitRelease==1),
(s.aSeen==1) implies (s.commitRelease==1 and (s.aWord==2 or s.aWord==6)),
(s.active==1) implies (s.aSeen==1 and s.activationWord>=1),
(s.activationWord>=1) implies (s.active==1),
(s.activationWord==1) implies (s.p_phase==4),
(s.activationWord==2) implies (s.p_phase==5 or s.p_phase==7),
(s.p_phase==5 or s.p_phase==7) implies (s.activationWord==2),
(s.workerSeen==1) implies (s.activeRelease==1 and s.carriedCommit==1),
(s.activationWord==2) implies (s.workerSeen==1),
(s.resultSeen==1) implies (s.resultRelease==1),
(s.n_remoteGrants==1) implies (s.resultSeen==1 and s.workerSeen==1)}}
action allocate=all{(s.n_decision==1 and s.n_destRoot==0 and s.n_gate==0 and s.n_admitted==1) and (s.p_phase==1 and s.p_copyRoot==0 and s.p_gcOpen==1 and s.p_frozen==0),s'={...s,n_destRoot:1,p_copyRoot:1,p_placeholder:1,p_materialized:1}}
action enter=all{(s.n_gate==0 and s.n_admitted==1 and s.n_decision>=1),s'={...s,n_gate:1,n_lease:s.n_lease+1,n_grantGen:s.n_generation}}
action resolve=all{(s.n_gate==1 and s.n_grantGen==s.n_generation),s'={...s,n_viewRev:s.n_revision,n_viewGen:s.n_generation,n_viewLease:s.n_lease}}
action initialize=all{(s.n_decision==1 and s.n_destRoot==1 and s.n_copyReady==0 and s.n_sourceRoot==1 and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision) and (s.p_phase==1 and s.p_copyRoot==1 and s.p_sourceRoot==1 and s.p_gcOpen==1 and s.p_frozen==0),s'={...s,n_copyReady:1,n_copyRev:s.n_revision,n_copyOps:s.n_copyOps+1,n_patchReady:0,p_phase:2,p_ready:1}}
action validate=all{(s.n_decision==1 and s.n_destRoot==1 and s.n_copyReady==1 and s.n_copyRev==s.n_revision and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision),s'={...s,n_validations:s.n_validations+1,n_patchReady:0}}
action prepare=all{(s.n_decision==1 and s.n_destRoot==1 and s.n_copyReady==1 and s.n_copyRev==s.n_revision and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision),s'={...s,n_patchReady:1,n_patchRev:s.n_revision,n_patchGen:s.n_generation,n_patchLease:s.n_lease}}
action sendPublication=all{(s.n_decision==1 and s.p_phase==2 and (s.publication==0 or s.publication==3)),s'={...s,publication:1}}
action publicationUnknown=all{(s.publication==1),s'={...s,attempts:s.attempts+1}}
action acceptPublication=all{(s.p_phase==2 and s.p_ready==1 and s.p_copyRoot==1 and s.p_gcOpen==1 and s.p_frozen==0) and (s.publication==1),s'={...s,p_phase:3,p_queueRoot:1,publication:2}}
action rejectPublication=all{(s.publication==1 and s.p_phase==2),s'={...s,publication:3}}
action activationFailed=all{(s.n_decision==2 and s.p_phase==4 and s.active==0),s'={...s,attempts:s.attempts+1}}
action wakeFailed=all{(s.active==1),s'={...s,attempts:s.attempts+1}}
action restore=all{(s.p_phase==5 and s.p_copyRoot==1 and s.p_restoreRoot==1 and s.p_ready==1 and s.p_gcOpen==1 and s.p_frozen==0) and (s.n_gate==0),s'={...s,p_phase:7,p_contextRoot:1,p_copyRoot:0,p_restoreRoot:0,p_parentOwner:3}}
action finishAborted=all{(s.p_phase==0 and s.p_childDone==1 and s.p_gcOpen==1 and s.p_frozen==0) and (s.n_decision==3),s'={...s,p_phase:6}}
action publishResult=all{(s.p_split==1 and s.p_childDone==1 and s.p_resultRoot==1 and s.p_resultPublished==0 and s.p_phase<8 and s.p_gcOpen==1 and s.p_frozen==0),s'={...s,p_resultPublished:1}}
action runPrefix=all{(s.p_phase==7 and s.p_parentOwner==3 and s.p_prefixRuns==0 and s.p_gcOpen==1 and s.p_frozen==0) and (s.active==1),s'={...s,p_prefixRuns:1}}
action grantLocal=all{(s.n_decision==3 and s.n_done==1 and s.n_localGrants==0 and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision) and (s.p_phase==6 and s.p_childDone==1 and s.p_parentRuns==0 and s.p_gcOpen==1 and s.p_frozen==0),s'={...s,n_localGrants:s.n_localGrants+1,p_prefixRuns:1,p_parentRuns:1}}
action leave=all{(s.n_gate==1),s'={...s,n_gate:0}}
action gcEnter=all{(s.n_gate==0 and s.n_admitted==1) and (s.p_gcOpen==1),s'={...s,n_gate:2,n_grantGen:s.n_generation,p_gcOpen:0}}
action gcFreeze=all{(s.p_gcOpen==0 and s.p_frozen==0),s'={...s,p_frozen:1,p_vSource:s.p_sourceRoot,p_vCopy:s.p_copyRoot,p_vQueue:s.p_queueRoot,p_vRestore:s.p_restoreRoot,p_vContext:s.p_contextRoot,p_vResult:s.p_resultRoot,p_vCapture:s.p_captureRoot}}
action gcBegin=all{(s.p_frozen==1 and s.p_scanning==0 and s.p_scanned==0),s'={...s,p_scanning:1}}
action forwardNoCopy=all{(s.n_gate==2 and s.n_copyReady==0) and (s.p_scanning==1),s'={...s,n_revision:s.n_revision+1,n_sourceHeap:1}}
action forwardWithCopy=all{(s.n_gate==2 and s.n_copyReady==1 and s.n_destRoot==1) and (s.p_scanning==1),s'={...s,n_revision:s.n_revision+1,n_copyRev:s.n_revision+1,n_sourceHeap:1}}
action gcEnd=all{(s.p_scanning==1),s'={...s,p_scanning:0,p_scanned:1}}
action gcLeave=all{(s.n_gate==2) and (s.p_frozen==1 and s.p_scanning==0 and s.p_scanned==1),s'={...s,n_gate:0,p_frozen:0,p_gcOpen:1,p_scanned:0,p_epoch:s.p_epoch+1}}
action closeDomain=all{(s.n_admitted==1),s'={...s,n_admitted:0}}
action resetDomain=all{(s.n_admitted==0 and s.n_gate==0),s'={...s,n_generation:s.n_generation+1,n_admitted:1}}
action prepareResult=all{(true) and (s.preparedResult==0 and s.n_done==0 and s.n_gate!=2 and s.p_gcOpen==1),s'={...s,preparedResult:1}}
action loadReserve=all{(true) and (s.sMode==0 and s.n_decision==0 and s.n_done==0),s'={...s,sExpected:s.word,sMode:1}}
action loadCommit=all{(true) and (s.sMode==0 and s.n_decision==1 and s.publication==2),s'={...s,sExpected:s.word,sMode:2}}
action loadAbort=all{(true) and (s.sMode==0 and s.n_decision==1 and (s.publication==0 or s.publication==3)),s'={...s,sExpected:s.word,sMode:3}}
action splitFailure=all{(true) and (s.sMode>=1),s'={...s,sExpected:s.word,sMode:0,casFailures:s.casFailures+1}}
action casReserve=all{((s.n_decision==0 and s.n_done==0 and s.n_admitted==1) and (s.p_phase==0 and s.p_eligible==1 and s.p_claims==0 and s.p_childDone==0 and s.p_gcOpen==1 and s.p_frozen==0)) and (s.sMode==1 and s.sExpected==0 and s.sExpected==s.word),s'={...s,n_decision:1,n_claims:s.n_claims+1,p_phase:1,p_claims:s.p_claims+1,word:s.sExpected+1,sMode:0,wordWins:s.wordWins+1}}
action casCommit=all{((s.n_decision==1 and s.n_copyReady==1 and s.n_destRoot==1 and s.n_copyRev==s.n_revision and s.n_patchReady==1 and s.n_patchRev==s.n_revision and s.n_patchGen==s.n_generation and s.n_patchLease==s.n_lease and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision) and (s.p_phase==3 and s.p_ready==1 and s.p_copyRoot==1 and s.p_queueRoot==1 and s.p_gcOpen==1 and s.p_frozen==0) and (s.publication==2 and s.active==0)) and (s.sMode==2 and s.sExpected==s.word),s'={...s,n_decision:2,n_sourceRoot:0,p_phase:4,p_sourceRoot:0,p_split:1,p_parentOwner:1,word:s.sExpected+1,sMode:0,commitRelease:1,wordWins:s.wordWins+1}}
action casAbort=all{((s.n_decision==1 and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision) and ((s.p_phase==1 or s.p_phase==2) and s.p_queueRoot==0 and s.p_gcOpen==1 and s.p_frozen==0) and (s.publication==0 or s.publication==3)) and (s.sMode==3 and s.sExpected==s.word),s'={...s,n_decision:3,n_destRoot:0,n_copyReady:0,n_copyRev:0,n_patchReady:0,p_phase:0,p_copyRoot:0,p_placeholder:0,p_ready:0,word:s.sExpected+2,sMode:0,wordWins:s.wordWins+1}}
action loadChild=all{(true) and (s.cMode==0 and s.n_done==0 and s.preparedResult==1),s'={...s,cExpected:s.word,cMode:1}}
action loadLocal=all{(true) and (s.cMode==0 and s.n_decision==0 and s.n_done==1),s'={...s,cExpected:s.word,cMode:2}}
action childFailure=all{(true) and (s.cMode>=1),s'={...s,cExpected:s.word,cMode:0,casFailures:s.casFailures+1}}
action casChildLocal=all{((s.n_done==0 and s.n_gate!=2) and (s.p_phase==0 and s.p_childDone==0 and s.p_gcOpen==1 and s.p_frozen==0)) and (s.cMode==1 and s.cExpected==s.word and s.preparedResult==1),s'={...s,n_done:1,n_resultRoot:1,p_phase:6,p_childDone:1,p_resultRoot:1,word:s.cExpected+4,cMode:0,resultRelease:1,wordWins:s.wordWins+1}}
action casChildSplit=all{((s.n_done==0 and s.n_gate!=2) and (((s.p_phase>=1 and s.p_phase<=5) or s.p_phase==7) and s.p_childDone==0 and s.p_gcOpen==1 and s.p_frozen==0)) and (s.cMode==1 and s.cExpected==s.word and s.preparedResult==1),s'={...s,n_done:1,n_resultRoot:1,p_childDone:1,p_resultRoot:1,word:s.cExpected+4,cMode:0,resultRelease:1,wordWins:s.wordWins+1}}
action casCloseLocal=all{((s.n_decision==0 and s.n_done==1 and s.n_gate==0)) and (s.cMode==2 and s.cExpected==s.word),s'={...s,n_decision:3,word:s.cExpected+3,cMode:0,wordWins:s.wordWins+1}}
action retirePreparedResult=all{(true) and (s.n_done==1 and s.n_resultRoot==1 and s.n_gate!=2 and s.p_gcOpen==1),s'={...s,preparedResult:0}}
action acquireCommit=all{(true) and (s.n_decision==2 and s.commitRelease==1),s'={...s,aSeen:1,aWord:s.word}}
action casActivate=all{((s.n_decision==2 and s.p_phase==4 and s.active==0 and s.n_gate==0)) and (s.aSeen==1 and s.activationWord==0),s'={...s,active:1,activationWord:1,activeRelease:1,carriedCommit:1}}
action acquireActive=all{(true) and (s.activationWord>=1 and s.activeRelease==1 and s.carriedCommit==1),s'={...s,workerSeen:1}}
action casDequeue=all{((s.p_phase==4 and s.p_queueRoot==1 and s.p_split==1 and s.p_gcOpen==1 and s.p_frozen==0) and (s.active==1 and s.n_gate==0)) and (s.workerSeen==1 and s.activationWord==1),s'={...s,p_phase:5,p_queueRoot:0,p_restoreRoot:1,p_parentOwner:2,activationWord:2}}
action acquireResult=all{(true) and (s.n_done==1 and s.resultRelease==1),s'={...s,resultSeen:1}}
action grantRemote=all{((s.n_decision==2 and s.n_done==1 and s.n_remoteGrants==0 and s.n_copyReady==1 and s.n_copyRev==s.n_revision and s.n_gate==1 and s.n_grantGen==s.n_generation and s.n_viewGen==s.n_generation and s.n_viewLease==s.n_lease and s.n_viewRev==s.n_revision) and (s.p_phase==7 and s.p_prefixRuns==1 and s.p_resultPublished==1 and s.p_parentRuns==0 and s.p_gcOpen==1 and s.p_frozen==0) and (s.active==1)) and (s.resultSeen==1 and s.workerSeen==1),s'={...s,n_remoteGrants:s.n_remoteGrants+1,p_parentRuns:1}}
action step=any{allocate,enter,resolve,initialize,validate,prepare,sendPublication,publicationUnknown,acceptPublication,rejectPublication,activationFailed,wakeFailed,restore,finishAborted,publishResult,runPrefix,grantLocal,leave,gcEnter,gcFreeze,gcBegin,forwardNoCopy,forwardWithCopy,gcEnd,gcLeave,closeDomain,resetDomain,prepareResult,loadReserve,loadCommit,loadAbort,splitFailure,casReserve,casCommit,casAbort,loadChild,loadLocal,childFailure,casChildLocal,casChildSplit,casCloseLocal,retirePreparedResult,acquireCommit,casActivate,acquireActive,casDequeue,acquireResult,grantRemote,all{s'=s}}
run normalTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(casCommit).then(leave).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(prepareResult).then(loadChild).then(casChildSplit).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run childWinsReservationTest=init.then(loadReserve).then(prepareResult).then(loadChild).then(casChildLocal).then(splitFailure).then(loadLocal).then(casCloseLocal).then(enter).then(resolve).then(grantLocal).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run reservationWinsChildTest=init.then(prepareResult).then(loadChild).then(loadReserve).then(casReserve).then(childFailure).then(loadChild).then(casChildSplit).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(casCommit).then(leave).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run childWinsCommitTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(prepareResult).then(loadChild).then(casChildSplit).then(splitFailure).then(loadCommit).then(casCommit).then(leave).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run commitWinsChildTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(prepareResult).then(loadChild).then(loadCommit).then(casCommit).then(leave).then(childFailure).then(loadChild).then(casChildSplit).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run acquireAfterRmwTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(casCommit).then(leave).then(prepareResult).then(loadChild).then(casChildSplit).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run doneAfterAcquireTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(casCommit).then(leave).then(acquireCommit).then(prepareResult).then(loadChild).then(casChildSplit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run weakSpuriousTest=init.then(loadReserve).then(splitFailure).then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(splitFailure).then(loadCommit).then(casCommit).then(leave).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(prepareResult).then(loadChild).then(casChildSplit).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run rejectAbortTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(rejectPublication).then(prepareResult).then(loadChild).then(casChildSplit).then(loadAbort).then(casAbort).then(leave).then(finishAborted).then(enter).then(resolve).then(grantLocal).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
run gcInvalidatesPreparedPatchTest=init.then(loadReserve).then(casReserve).then(allocate).then(enter).then(resolve).then(initialize).then(validate).then(prepare).then(sendPublication).then(acceptPublication).then(loadCommit).then(leave).then(gcEnter).then(gcFreeze).then(gcBegin).then(forwardWithCopy).then(gcEnd).then(gcLeave).then(enter).then(resolve).then(validate).then(prepare).then(casCommit).then(leave).then(acquireCommit).then(casActivate).then(acquireActive).then(casDequeue).then(restore).then(runPrefix).then(prepareResult).then(loadChild).then(casChildSplit).then(publishResult).then(acquireResult).then(enter).then(resolve).then(grantRemote).then(leave).then(all{assert(safe and s.n_localGrants+s.n_remoteGrants==1),s'=s})
}
