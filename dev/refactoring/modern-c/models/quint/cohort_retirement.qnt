module cohort_retirement {
// One departing worker and one exported reader; all-roles native coverage is a premise.
type State={admission:int,lookup:int,worker:int,external:int,fault:int,closed:int,drained:int,joined:int,unknown:int,retired:int}
pure val initial:State={admission:1,lookup:0,worker:1,external:0,fault:0,closed:0,drained:0,joined:0,unknown:0,retired:0}
var s:State
action init=s'=initial
val safe=all{s.admission>=0,s.lookup>=0,s.worker>=0,s.external>=0,s.fault>=0,s.closed>=0,s.drained>=0,s.joined>=0,s.unknown>=0,s.retired>=0,s.admission<=1,s.lookup<=1,s.worker<=1,s.external<=1,s.fault<=1,s.closed<=1,s.drained<=1,s.joined<=1,s.unknown<=1,s.retired<=1,s.admission+s.closed==1,s.lookup==1 implies s.retired==0,s.external==1 implies s.retired==0,s.fault==1 implies all{s.worker==1,s.drained==0,s.joined==0,s.retired==0},s.drained==1 implies all{s.closed==1,s.lookup==0,s.fault==0},s.worker==0 implies all{s.closed==1,s.drained==1,s.fault==0},s.joined==1 implies all{s.closed==1,s.worker==0,s.drained==1,s.unknown==0},s.retired==1 implies all{s.closed==1,s.drained==1,s.joined==1,s.lookup==0,s.external==0,s.fault==0,s.worker==0,s.unknown==0}}
action enterLookup=all{s.admission==1 and s.lookup==0,s'={...s,lookup:1}}
action exitLookup=all{s.lookup==1,s'={...s,lookup:0}}
action acquireExternal=all{s.admission==1 and s.external==0,s'={...s,external:1}}
action returnExternal=all{s.external==1,s'={...s,external:0}}
action closeRoster=all{s.admission==1,s'={...s,admission:0,closed:1}}
action escapeScanner=all{s.worker==1 and s.fault==0 and s.drained==0,s'={...s,fault:1}}
action collectiveDrain=all{s.closed==1 and s.lookup==0 and s.fault==0 and s.worker==1 and s.drained==0,s'={...s,drained:1}}
action exitWorker=all{s.closed==1 and s.drained==1 and s.worker==1 and s.fault==0,s'={...s,worker:0}}
action joinUnknown=all{s.closed==1 and s.joined==0 and s.unknown==0,s'={...s,unknown:1}}
action joinKnown=all{s.closed==1 and s.worker==0 and s.fault==0 and s.joined==0,s'={...s,joined:1,unknown:0}}
action retireDomain=all{s.closed==1 and s.drained==1 and s.joined==1 and s.lookup==0 and s.external==0 and s.fault==0 and s.unknown==0 and s.retired==0,s'={...s,retired:1}}
action step=any{enterLookup,exitLookup,acquireExternal,returnExternal,closeRoster,escapeScanner,collectiveDrain,exitWorker,joinUnknown,joinKnown,retireDomain,all{s'=s}}
run normalTest=init.then(enterLookup).then(closeRoster).then(exitLookup).then(collectiveDrain).then(exitWorker).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
run externalTest=init.then(acquireExternal).then(closeRoster).then(collectiveDrain).then(exitWorker).then(joinKnown).then(returnExternal).then(retireDomain).then(all{assert(safe),s'=s})
run joinUncertainTest=init.then(closeRoster).then(collectiveDrain).then(joinUnknown).then(all{assert(safe),s'=s})
run faultTest=init.then(enterLookup).then(escapeScanner).then(closeRoster).then(exitLookup).then(all{assert(safe),s'=s})
run reconcileJoinTest=init.then(closeRoster).then(collectiveDrain).then(exitWorker).then(joinUnknown).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
}
