module sfun_admission_refusal {
// managed=0 is the isolated legacy recurrence fragment, not an observed native path.
// sourcePin initially denotes an already-qualified source carrier; its issuer is unresolved.
type State={phase:int,managed:int,domainOpen:int,pool:int,sourcePin:int,sourceDrops:int,root:int,guard:int,guardCreates:int,guardDrops:int,marker:int,markerCreates:int,markerDrops:int,allocs:int,bodyEntries:int,handlerEntries:int,legacyRetries:int,origin:int,code:int,refused:int,preRefused:int,refusalStamp:int,final:int,landing:int}
pure val initial:State={phase:0,managed:1,domainOpen:1,pool:1,sourcePin:1,sourceDrops:0,root:0,guard:0,guardCreates:0,guardDrops:0,marker:0,markerCreates:0,markerDrops:0,allocs:0,bodyEntries:0,handlerEntries:0,legacyRetries:0,origin:0,code:0,refused:0,preRefused:0,refusalStamp:0,final:0,landing:0}
pure val initialLegacy:State={...initial,managed:0}
var s:State
action init=s'=initial
action legacyInit=s'=initialLegacy
val safe=all{s.phase>=0,
s.phase<=8,
s.managed>=0,
s.managed<=1,
s.domainOpen>=0,
s.domainOpen<=1,
s.pool>=0,
s.pool<=1,
s.sourcePin>=0,
s.sourcePin<=1,
s.sourceDrops>=0,
s.sourceDrops<=1,
s.root>=0,
s.root<=1,
s.guard>=0,
s.guard<=1,
s.guardCreates>=0,
s.guardCreates<=1,
s.guardDrops>=0,
s.guardDrops<=1,
s.marker>=0,
s.marker<=1,
s.markerCreates>=0,
s.markerCreates<=1,
s.markerDrops>=0,
s.markerDrops<=1,
s.allocs>=0,
s.allocs<=1,
s.bodyEntries>=0,
s.bodyEntries<=1,
s.handlerEntries>=0,
s.legacyRetries>=0,
s.origin>=0,
s.origin<=5,
s.code>=0,
s.code<=3,
s.refused>=0,
s.refused<=1,
s.preRefused>=0,
s.preRefused<=1,
s.refusalStamp>=0,
s.final>=0,
s.final<=1,
s.landing>=0,
s.landing<=1,
s.sourcePin+s.sourceDrops==1,
s.guard+s.guardDrops==s.guardCreates,
s.marker+s.markerDrops==s.markerCreates,
s.refusalStamp<=s.handlerEntries,
(s.managed==1) implies (s.legacyRetries==0),
(s.managed==1 and s.phase<=6) implies (s.sourcePin+s.root>=1),
(s.managed==1 and s.guard==1) implies (s.root==1),
(s.managed==1 and s.marker==1) implies (s.guard==1 and s.root==1),
(s.managed==1 and s.phase==0) implies (s.guard==0 and s.marker==0 and s.root==0 and s.sourcePin==1 and s.guardCreates==0 and s.markerCreates==0),
(s.managed==1 and s.phase==1) implies (s.guard==1 and s.root==1 and s.marker==0 and s.sourcePin==1),
(s.managed==1 and s.phase==2) implies (s.guard==1 and s.root==1 and s.marker==0 and s.sourcePin==0),
(s.managed==1 and (s.phase==3 or s.phase==4 or s.phase==5)) implies (s.guard==1 and s.root==1 and s.marker==1 and s.sourcePin==0),
(s.managed==1 and s.phase==5) implies (s.origin==2 and s.refused==0),
(s.managed==1 and s.phase==6) implies (s.guard==1 and s.root==1),
(s.managed==1 and s.phase>=7) implies (s.guard==0 and s.root==0 and s.marker==0),
(s.managed==1 and s.refused==1) implies (s.handlerEntries==s.refusalStamp and s.origin==1 and s.phase>=6),
(s.managed==1 and s.preRefused==1) implies (s.guardCreates==0 and s.markerCreates==0 and s.allocs==0 and s.bodyEntries==0 and s.handlerEntries==0),
(s.managed==1 and s.final==1) implies (s.phase==8 and s.guard==0 and s.marker==0 and s.root==0 and s.sourcePin==0),
(s.managed==1 and s.phase<=7) implies (s.final==0)}
action refuseBeforeEntry=all{s.managed==1 and s.phase==0 and s.domainOpen==0,s'={...s,phase:7,origin:1,code:1,refused:1,preRefused:1,refusalStamp:s.handlerEntries}}
action exhaustPool=all{s.managed==1 and s.phase==0 and s.pool==1,s'={...s,pool:0}}
action refuseNoRecord=all{s.managed==1 and s.phase==0 and s.domainOpen==1 and s.pool==0,s'={...s,phase:7,origin:3,code:2}}
action reserveGuard=all{s.managed==1 and s.phase==0 and s.domainOpen==1 and s.pool==1,s'={...s,phase:1,guard:1,guardCreates:1,root:1}}
action ackHandoff=all{s.managed==1 and s.phase==1 and s.guard==1 and s.root==1,s'={...s,phase:2,sourcePin:0,sourceDrops:1}}
action cancelBeforeAck=all{s.managed==1 and s.phase==1 and s.guard==1 and s.root==1,s'={...s,phase:6,origin:4,code:3,landing:1}}
action allocateMarker=all{s.managed==1 and s.phase==2 and s.domainOpen==1 and s.guard==1 and s.root==1,s'={...s,phase:3,marker:1,markerCreates:1,allocs:1}}
action markerFailure=all{s.managed==1 and s.phase==2 and s.domainOpen==1,s'={...s,phase:6,origin:3,code:2}}
action beginBody=all{s.managed==1 and s.phase==3 and s.domainOpen==1,s'={...s,phase:4,bodyEntries:1}}
action conversionFailure=all{s.managed==1 and (s.phase==3 or s.phase==4) and s.domainOpen==1,s'={...s,phase:5,origin:2,code:2}}
action opaqueConversionFailure=all{s.managed==1 and (s.phase==3 or s.phase==4) and s.domainOpen==1,s'={...s,phase:5,origin:2,code:1}}
action finishSuccess=all{s.managed==1 and s.phase==4 and s.domainOpen==1,s'={...s,phase:6,origin:5,code:0}}
action callRefused=all{s.managed==1 and s.phase==3 and s.domainOpen==0,s'={...s,phase:6,origin:1,code:1,refused:1,refusalStamp:s.handlerEntries}}
action handlerRefused=all{s.managed==1 and s.phase==5 and s.domainOpen==0,s'={...s,phase:6,origin:1,code:1,refused:1,refusalStamp:s.handlerEntries}}
action recoverGood=all{s.managed==1 and s.phase==5 and s.origin==2 and s.domainOpen==1 and s.refused==0,s'={...s,phase:6,origin:5,code:0,handlerEntries:s.handlerEntries+1}}
action recoverBad=all{s.managed==1 and s.phase==5 and s.origin==2 and s.domainOpen==1 and s.refused==0,s'={...s,phase:5,code:1,handlerEntries:s.handlerEntries+1}}
action outerThrow=all{s.managed==1 and (s.phase==2 or s.phase==3 or s.phase==4 or s.phase==5),s'={...s,phase:6,origin:4,code:3,landing:1}}
action releaseMarker=all{s.managed==1 and s.phase==6 and s.marker==1 and s.guard==1 and s.domainOpen==1,s'={...s,marker:0,markerDrops:s.markerDrops+1}}
action closeGuard=all{s.managed==1 and s.phase==6 and s.marker==0 and s.guard==1 and s.domainOpen==1,s'={...s,phase:7,guard:0,guardDrops:s.guardDrops+1,root:0}}
action dropRefusedSource=all{s.managed==1 and s.phase==7 and s.sourcePin==1,s'={...s,sourcePin:0,sourceDrops:1}}
action deliver=all{s.managed==1 and s.phase==7 and s.sourcePin==0 and s.marker==0 and s.guard==0 and s.root==0,s'={...s,phase:8,final:1}}
action closeDomain=all{s.domainOpen==1,s'={...s,domainOpen:0}}
action resumeDomain=all{s.domainOpen==0,s'={...s,domainOpen:1}}
action legacyMarkerSuccess=all{s.managed==0 and s.phase==0 and s.domainOpen==0,s'={...s,phase:3,marker:1,markerCreates:1,allocs:1}}
action legacyRejectCall=all{s.managed==0 and s.phase==3 and s.domainOpen==0,s'={...s,phase:5,origin:1,code:1,refused:1}}
action legacyErrorRetry=all{s.managed==0 and s.phase==5 and s.domainOpen==0 and s.code==1,s'={...s,legacyRetries:s.legacyRetries+1}}
action legacyMarkerFailure=all{s.managed==0 and s.phase==0 and s.domainOpen==0,s'={...s,phase:6,origin:3,code:2}}
action step=any{refuseBeforeEntry,exhaustPool,refuseNoRecord,reserveGuard,ackHandoff,cancelBeforeAck,allocateMarker,markerFailure,beginBody,conversionFailure,opaqueConversionFailure,finishSuccess,callRefused,handlerRefused,recoverGood,recoverBad,outerThrow,releaseMarker,closeGuard,dropRefusedSource,deliver,closeDomain,resumeDomain,legacyMarkerSuccess,legacyRejectCall,legacyErrorRetry,legacyMarkerFailure,all{s'=s}}
run preRefusalTest=init.then(closeDomain).then(refuseBeforeEntry).then(dropRefusedSource).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run poolFailureTest=init.then(exhaustPool).then(refuseNoRecord).then(dropRefusedSource).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run normalTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(beginBody).then(finishSuccess).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run markerFailureTest=init.then(reserveGuard).then(ackHandoff).then(markerFailure).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run conversionRecoveryTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(conversionFailure).then(recoverGood).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run opaqueUnknownRecoveryTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(opaqueConversionFailure).then(recoverBad).then(recoverGood).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run lateCallRefusalTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(closeDomain).then(callRefused).then(resumeDomain).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run handlerRefusalTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(conversionFailure).then(recoverBad).then(closeDomain).then(handlerRefused).then(resumeDomain).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run outerThrowTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(outerThrow).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run unknownHandoffTest=init.then(reserveGuard).then(closeDomain).then(resumeDomain).then(ackHandoff).then(markerFailure).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run cancelBeforeAckTest=init.then(reserveGuard).then(cancelBeforeAck).then(closeGuard).then(dropRefusedSource).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run inputFailureBeforeBodyTest=init.then(reserveGuard).then(ackHandoff).then(allocateMarker).then(conversionFailure).then(recoverGood).then(releaseMarker).then(closeGuard).then(deliver).then(all{assert(safe and s.final==1 and s.marker==0 and s.guard==0 and s.sourcePin==0),s'=s})
run legacyPersistentRefusalTest=legacyInit.then(closeDomain).then(legacyMarkerSuccess).then(legacyRejectCall).then(legacyErrorRetry).then(legacyErrorRetry).then(legacyErrorRetry).then(all{assert(s.phase==5 and s.code==1 and s.domainOpen==0 and s.legacyRetries==3 and s.marker==1 and s.final==0),s'=s})
run legacyMarkerFailureTest=legacyInit.then(closeDomain).then(legacyMarkerFailure).then(all{assert(s.phase==6 and s.origin==3 and s.marker==0 and s.legacyRetries==0),s'=s})
}
