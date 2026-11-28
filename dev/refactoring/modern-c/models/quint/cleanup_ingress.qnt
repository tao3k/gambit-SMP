module cleanup_ingress {
// One admitted parent, one preauthorized child, one result-release debt.
// Requesting close never decrements the requester; exact native landing is a premise.
type State={gate:int,outer:int,child:int,permit:int,closed:int,guard:int,roots:int,settled:int,resultDebt:int,unknown:int,collective:int,joined:int,retired:int}
pure val initial:State={gate:1,outer:1,child:0,permit:0,closed:0,guard:1,roots:1,settled:0,resultDebt:0,unknown:0,collective:0,joined:0,retired:0}
var s:State
action init=s'=initial
val safe=all{s.gate>=0,s.outer>=0,s.child>=0,s.permit>=0,s.closed>=0,s.guard>=0,s.roots>=0,s.settled>=0,s.resultDebt>=0,s.unknown>=0,s.collective>=0,s.joined>=0,s.retired>=0,s.gate<=1,s.outer<=1,s.child<=1,s.permit<=1,s.closed<=1,s.guard<=1,s.roots<=1,s.settled<=1,s.resultDebt<=1,s.unknown<=2,s.collective<=1,s.joined<=1,s.retired<=1,s.gate+s.closed==1,s.outer+s.settled==1,s.guard==s.outer,s.roots==s.outer,s.child==1 implies s.outer==1,s.permit==1 implies s.outer==1,s.child+s.permit<=1,s.unknown==1 implies s.outer==1,s.unknown==2 implies all{s.collective==1,s.joined==0},s.collective==1 implies all{s.closed==1,s.outer==0,s.child==0,s.permit==0,s.guard==0,s.roots==0,s.settled==1},s.joined==1 implies all{s.collective==1,s.unknown==0},s.retired==1 implies all{s.closed==1,s.outer==0,s.child==0,s.permit==0,s.guard==0,s.roots==0,s.settled==1,s.resultDebt==0,s.unknown==0,s.collective==1,s.joined==1},s.resultDebt==1 implies s.retired==0}
action reserveChild=all{s.gate==1 and s.outer==1 and s.permit==0 and s.child==0 and s.unknown==0,s'={...s,permit:1}}
action enterChild=all{s.permit==1 and s.outer==1 and s.child==0 and s.unknown==0,s'={...s,permit:0,child:1}}
action returnChild=all{s.child==1 and s.unknown==0,s'={...s,child:0}}
action cancelPermit=all{s.permit==1 and s.unknown==0,s'={...s,permit:0}}
action requestClose=all{s.closed==0,s'={...s,gate:0,closed:1}}
action loseBoundary=all{s.outer==1 and s.unknown==0,s'={...s,unknown:1}}
action recoverLanding=all{s.unknown==1 and s.outer==1,s'={...s,unknown:0}}
action exportResult=all{s.outer==1 and s.unknown==0 and s.resultDebt==0,s'={...s,resultDebt:1}}
action releaseResult=all{s.resultDebt==1,s'={...s,resultDebt:0}}
action finishOuter=all{s.outer==1 and s.child==0 and s.permit==0 and s.unknown==0 and s.settled==0,s'={...s,outer:0,guard:0,roots:0,settled:1}}
action drainCollective=all{s.closed==1 and s.outer==0 and s.child==0 and s.permit==0 and s.unknown==0 and s.collective==0,s'={...s,collective:1}}
action joinUnknown=all{s.collective==1 and s.joined==0 and s.unknown==0,s'={...s,unknown:2}}
action joinKnown=all{s.collective==1 and s.joined==0 and (s.unknown==0 or s.unknown==2),s'={...s,joined:1,unknown:0}}
action retireDomain=all{s.closed==1 and s.outer==0 and s.child==0 and s.permit==0 and s.guard==0 and s.roots==0 and s.settled==1 and s.resultDebt==0 and s.unknown==0 and s.collective==1 and s.joined==1 and s.retired==0,s'={...s,retired:1}}
action step=any{reserveChild,enterChild,returnChild,cancelPermit,requestClose,loseBoundary,recoverLanding,exportResult,releaseResult,finishOuter,drainCollective,joinUnknown,joinKnown,retireDomain,all{s'=s}}
run nestedRequestTest=init.then(reserveChild).then(enterChild).then(requestClose).then(returnChild).then(finishOuter).then(drainCollective).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
run lateAuthorizedChildTest=init.then(reserveChild).then(requestClose).then(enterChild).then(returnChild).then(finishOuter).then(drainCollective).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
run resultAfterReturnTest=init.then(exportResult).then(requestClose).then(finishOuter).then(drainCollective).then(joinKnown).then(releaseResult).then(retireDomain).then(all{assert(safe),s'=s})
run unwindLandingTest=init.then(reserveChild).then(enterChild).then(requestClose).then(loseBoundary).then(recoverLanding).then(returnChild).then(finishOuter).then(drainCollective).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
run unknownJoinTest=init.then(requestClose).then(finishOuter).then(drainCollective).then(joinUnknown).then(joinKnown).then(retireDomain).then(all{assert(safe),s'=s})
run unknownBoundaryTest=init.then(requestClose).then(loseBoundary).then(all{assert(safe),s'=s})
}
