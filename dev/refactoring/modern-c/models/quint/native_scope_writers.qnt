module native_scope_writers {
// Closed writer set, stable registration and root coverage are premises, not native facts.
type State={phase:int,generation:int,thread:int,cap:int,nested:int,gate:int,pending:int,unknown:int,pins:int,roots:int,descriptors:int,custodian:int,closedWorld:int,pub:int,view:int,rf:int,observed:int,floor0:int,floor1:int,handoffRelease:int,targetAcquired:int,returnRight:int,recorded:int,callGen:int,responseGen:int,rejected:int}
pure val initial:State={phase:0,generation:1,thread:0,cap:0,nested:0,gate:0,pending:0,unknown:0,pins:1,roots:1,descriptors:1,custodian:1,closedWorld:1,pub:0,view:0,rf:0,observed:0,floor0:0,floor1:0,handoffRelease:0,targetAcquired:0,returnRight:1,recorded:0,callGen:0,responseGen:0,rejected:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,s.phase<=3,s.generation>=1,s.generation<=2,s.thread>=0,s.thread<=1,s.cap>=0,s.cap<=s.generation,s.callGen>=0,s.callGen<=s.generation,s.custodian>=0,s.custodian<=3,s.responseGen>=0,s.responseGen<=s.generation,s.nested>=0,s.nested<=1,s.gate>=0,s.gate<=1,s.pending>=0,s.pending<=1,s.unknown>=0,s.unknown<=1,s.pins>=0,s.pins<=1,s.roots>=0,s.roots<=1,s.descriptors>=0,s.descriptors<=1,s.closedWorld>=0,s.closedWorld<=1,s.pub>=0,s.pub<=1,s.view>=0,s.view<=1,s.rf>=0,s.rf<=1,s.observed>=0,s.observed<=1,s.floor0>=0,s.floor0<=1,s.floor1>=0,s.floor1<=1,s.handoffRelease>=0,s.handoffRelease<=1,s.targetAcquired>=0,s.targetAcquired<=1,s.returnRight>=0,s.returnRight<=1,s.recorded>=0,s.recorded<=1,s.rejected>=0,s.rejected<=1,s.unknown<=s.pending,s.phase!=3 implies all{s.pins==1,s.roots==1,s.descriptors==1,s.custodian>=1},s.unknown==1 implies all{s.phase==1,s.custodian==2,s.cap==0,s.view==0},s.pending==1 implies s.phase==1,s.nested==1 implies s.phase==1,s.view==1 implies all{s.phase==1,s.cap==s.generation,s.pub==1,s.rf==1,s.observed==1,s.closedWorld==1,s.unknown==0},s.phase==2 implies all{s.generation==2,s.pending==0,s.nested==0,s.cap==0,s.returnRight==0,s.handoffRelease==1},s.thread==1 implies all{s.generation==2,s.targetAcquired==1,s.returnRight==0},s.phase==3 implies all{s.gate==1,s.pending==0,s.nested==0,s.pins==0,s.roots==0,s.descriptors==0,s.cap==0,s.custodian==0,s.view==0},s.closedWorld==0 implies all{s.phase==1,s.gate==1,s.pending==0,s.nested==0,s.view==0,s.cap==0}}
action issue=all{s.phase==0 and s.closedWorld==1 and s.roots==1 and s.pins==1,s'={...s,phase:1,cap:s.generation}}
action beginWrite=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.gate==0 and s.pending==0 and s.nested==0,s'={...s,pending:1,callGen:s.generation,recorded:0,view:0,rf:0,observed:0}}
action publishRelease=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.pending==1 and s.pub==0,s'={...s,pub:1}}
action recordOutcome=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.pending==1 and s.recorded==0,s'={...s,recorded:1,responseGen:s.callGen}}
action deliverOutcome=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.pending==1 and s.recorded==1 and s.nested==0 and s.callGen==s.generation and s.responseGen==s.callGen,s'={...s,pending:0}}
action loseResponse=all{s.phase==1 and s.pending==1 and s.unknown==0,s'={...s,unknown:1,custodian:2,cap:0,view:0,rf:0,observed:0}}
action recoverRecorded=all{s.phase==1 and s.unknown==1 and s.recorded==1 and s.nested==0 and s.callGen==s.generation and s.responseGen==s.callGen,s'={...s,unknown:0,pending:0,custodian:1,cap:s.generation}}
action enterNested=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.gate==0 and s.nested==0,s'={...s,nested:1,view:0,rf:0,observed:0}}
action leaveNested=all{s.phase==1 and s.nested==1,s'={...s,nested:0}}
action catcherSubtree=all{s.phase==1 and s.nested==1 and s.unknown==1,s'={...s,nested:0}}
action acquire0=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.thread==0 and s.pub==1 and s.pending==0 and s.nested==0,s'={...s,view:1,cap:s.generation,rf:1,observed:1,floor0:1}}
action acquire1=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.thread==1 and s.pub==1 and s.pending==0 and s.nested==0,s'={...s,view:1,cap:s.generation,rf:1,observed:1,floor1:1}}
action closeAdmission=all{s.phase==1 and s.gate==0,s'={...s,gate:1}}
action renewSameThread=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.pending==0 and s.nested==0,s'={...s,view:0,rf:0,observed:0}}
action prepareMigration=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.thread==0 and s.generation==1 and s.pending==0 and s.nested==0 and s.gate==0,s'={...s,phase:2,generation:2,cap:0,view:0,rf:0,observed:0,returnRight:0,handoffRelease:1}}
action targetAcquire=all{s.phase==2 and s.handoffRelease==1 and s.targetAcquired==0,s'={...s,thread:1,targetAcquired:1}}
action issueTarget=all{s.phase==2 and s.targetAcquired==1 and s.thread==1,s'={...s,phase:1,cap:s.generation,custodian:3}}
action rejectStaleDelivery=all{s.phase==1 and s.thread==1 and s.responseGen==1 and s.generation==2 and s.rejected==0,s'={...s,rejected:1}}
action rawInterference=all{s.phase==1 and s.unknown==0 and s.closedWorld==1 and s.pending==0 and s.nested==0,s'={...s,closedWorld:0,gate:1,cap:0,view:0,rf:0,observed:0}}
action retire=all{s.phase==1 and s.gate==1 and s.pending==0 and s.nested==0 and s.closedWorld==1,s'={...s,phase:3,pins:0,roots:0,descriptors:0,cap:0,view:0,rf:0,observed:0,custodian:0,returnRight:0}}
action step=any{issue,beginWrite,publishRelease,recordOutcome,deliverOutcome,loseResponse,recoverRecorded,enterNested,leaveNested,catcherSubtree,acquire0,acquire1,closeAdmission,renewSameThread,prepareMigration,targetAcquire,issueTarget,rejectStaleDelivery,rawInterference,retire,all{s'=s}}
run nestedUnknownTest=init.then(issue).then(beginWrite).then(publishRelease).then(recordOutcome).then(enterNested).then(loseResponse).then(catcherSubtree).then(closeAdmission).then(recoverRecorded).then(retire).then(all{assert(s.phase==3),assert(safe),s'=s})
run unknownBeforeRecordTest=init.then(issue).then(beginWrite).then(loseResponse).then(closeAdmission).then(all{assert(s.unknown==1 and s.pins==1 and s.pending==1),assert(safe),s'=s})
run migrationTest=init.then(issue).then(beginWrite).then(publishRelease).then(recordOutcome).then(deliverOutcome).then(acquire0).then(prepareMigration).then(targetAcquire).then(issueTarget).then(rejectStaleDelivery).then(acquire1).then(all{assert(s.floor0==1 and s.floor1==1 and s.returnRight==0),assert(safe),s'=s})
run rawRejectionTest=init.then(issue).then(rawInterference).then(all{assert(s.closedWorld==0 and s.pins==1),assert(safe),s'=s})
run renewKeepsHistoryTest=init.then(issue).then(beginWrite).then(publishRelease).then(recordOutcome).then(deliverOutcome).then(acquire0).then(renewSameThread).then(enterNested).then(leaveNested).then(all{assert(s.floor0==1 and s.view==0),assert(safe),s'=s})
}
