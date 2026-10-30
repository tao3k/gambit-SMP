module registry_atomic_commit {
 import atomic_commit_parameters.* from "./atomic_commit_parameters"
 type Bundle={gen:int,regs:List[int],ledger:int->int,digests:int->int}
 pure val empty:Bundle={gen:0,regs:List(),ledger:Map(0->-1,1->-1,2->-1,3->-1),digests:Map(0->-1,1->-1,2->-1,3->-1)}
 pure def valid(b:Bundle):bool=b.gen==b.regs.length() and b.gen==0.to(3).filter(e=>b.ledger.get(e)>=0).size()
 pure def add(b:Bundle,e:int,h:int):Bundle={gen:b.gen+1,regs:List(e).concat(b.regs),ledger:b.ledger.set(e,b.gen+1),digests:b.digests.set(e,h)}
 type State={cur:Bundle,cand:Bundle,phase:int,req:int,payload:int,base:int,fence:int,ticket:int,
  ack:int,retry:bool,active:int,childReturned:bool,saved:bool,roots:bool,unknown:bool,rejected:bool,parsed:bool,workspace:int,commitFence:int,commitTicket:int,commitBase:int,commitPriorGen:int}
 pure val initial:State={cur:empty,cand:empty,phase:0,req:-1,payload:7,base:0,fence:0,ticket:0,ack:-1,
  retry:false,active:0,childReturned:false,saved:false,roots:false,unknown:false,rejected:false,parsed:false,workspace:0,commitFence:0,commitTicket:0,commitBase:0,commitPriorGen:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,workspace:WorkspaceCount-1}
 def freshId=if(s.active==1) 1 else if(s.active==2) 3 else if(s.childReturned) 2 else 0
 action prepareEvent=all {s.phase==0,not(s.unknown),s.cur.ledger.get(freshId)<0,
  s'={...s,phase:1,req:freshId,payload:7,base:s.cur.gen,ticket:s.fence,ack:-1,retry:false,roots:true,cand:s.cur}}
 action prepareRetry(e)=all {s.phase==0,s.cur.ledger.get(e)>=0,
  s'={...s,phase:1,req:e,payload:7,base:0,ticket:0,ack:-1,retry:true,roots:true,cand:s.cur}}
 action lookupExisting=all {s.phase==1,s.cur.ledger.get(s.req)>=0,s.cur.digests.get(s.req)==s.payload,
  s'={...s,phase:4,ack:s.cur.ledger.get(s.req)}}
 action buildRegistry=all {s.phase==1,s.cur.ledger.get(s.req)<0,s.ticket==s.fence,s.base==s.cur.gen,
  s'={...s,phase:2,cand:{...s.cur,gen:s.cur.gen+1,regs:List(s.req).concat(s.cur.regs)}}}
 action buildIndex=all {s.phase==2,s'={...s,phase:3,cand:{...s.cand,ledger:s.cand.ledger.set(s.req,s.cand.gen),digests:s.cand.digests.set(s.req,s.payload)}}}
 action publishBundle=all {s.phase==3,s.ticket==s.fence,s.base==s.cur.gen,s.cur.ledger.get(s.req)<0,valid(s.cand),
  s'={...s,phase:4,cur:s.cand,ack:s.cand.ledger.get(s.req),commitFence:s.fence,commitTicket:s.ticket,commitBase:s.base,commitPriorGen:s.cur.gen}}
 action loseAck=all {s.phase==4,s'={...s,unknown:true}}
 action retryLookup=all {s.phase==4,s.unknown,s.cur.ledger.get(s.req)>=0,s.cur.digests.get(s.req)==s.payload,
  s'={...s,ack:s.cur.ledger.get(s.req)}}
 action finishDelivery=all {s.phase==4,s.ack==s.cur.ledger.get(s.req),s'={...s,phase:0,unknown:false,roots:s.saved,cand:s.cur}}
 action abortCandidate=all {s.phase>=1,s.phase<=3,s'={...s,phase:0,cand:s.cur,ack:-1,roots:s.saved}}
 action enterChild=all {s.phase==0,s.active==0,not(s.childReturned),s.cur.ledger.get(0)>=0,
  s'={...s,active:1}}
 action leaveChild=all {s.phase==0,s.active==1,s.cur.ledger.get(1)>=0,s'={...s,active:0,childReturned:true}}
 action saveBefore=all {s.phase==0,s.cur.ledger.get(0)<0,s'={...s,saved:true,roots:true}}
 action resumeBefore=all {s.phase==0,s.saved,s.cur.ledger.get(0)>=0,s'={...s,active:2}}
 action retireSaved=all {s.saved,s'={...s,saved:false,roots:s.phase!=0}}
 action parseNext=all {s.phase==0,s.active==0,s.childReturned,s.cur.ledger.get(2)>=0,s'={...s,parsed:true}}
 action rotateFence=all {s.phase!=4,s'={...s,fence:s.fence+1}}
 def safe=valid(s.cur) and s.commitFence==s.commitTicket and s.commitBase==s.commitPriorGen and (s.phase!=0 or s.saved or s.unknown implies s.roots) and
  (s.ack>=0 implies s.ack==s.cur.ledger.get(s.req) and s.cur.digests.get(s.req)==s.payload) and
  (s.phase!=0 and not(s.retry) implies s.req==freshId) and
  (s.childReturned implies s.cur.ledger.get(1)>=0) and
  (s.parsed implies s.cur.ledger.get(2)>=0 and s.childReturned)
 action step={nondet e=0.to(3).oneOf();any {prepareEvent,prepareRetry(e),lookupExisting,buildRegistry,buildIndex,publishBundle,
  loseAck,retryLookup,finishDelivery,abortCandidate,enterChild,leaveChild,saveBefore,resumeBefore,retireSaved,parseNext,rotateFence,s'=s}}
 action publishRootOnly=s'={...s,cur:s.cand}
 action publishIndexOnly=s'={...s,cur:{...s.cur,ledger:s.cand.ledger,digests:s.cand.digests}}
 action mismatchPayload=s'={...s,payload:8}
 action forceLookup=s'={...s,phase:4,ack:s.cur.ledger.get(s.req)}
 action ackCurrent=s'={...s,ack:s.cur.gen}
 action nestedAlias=s'={...s,req:0}
 action resumedAlias=s'={...s,req:0}
 action dropRoots=s'={...s,roots:false}
 action leaveTooSoon=s'={...s,active:0,childReturned:true}
 action forcePublish=s'={...s,phase:4,cur:s.cand,ack:s.cand.gen,commitFence:s.fence,commitTicket:s.ticket,commitBase:s.base,commitPriorGen:s.cur.gen}
 action baseChanged=s'={...s,cur:add(s.cur,1,7)}
 def guardValid=s.phase!=3 or s.ticket==s.fence and s.base==s.cur.gen
 action checkFence=s'={...s,rejected:s.ticket!=s.fence}
 action checkBase=s'={...s,rejected:s.base!=s.cur.gen}
 run completeBundleTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).expect(safe and s.cur.gen==1)
 run lostAckTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(loseAck).then(retryLookup).then(finishDelivery).expect(safe and s.cur.gen==1)
 run privatePrefixAbortTest=init.then(prepareEvent).then(buildRegistry).then(abortCandidate).expect(safe and s.cur.gen==0)
 run privateFullAbortTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(abortCandidate).expect(safe and s.cur.gen==0)
 run nestedOrderTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(enterChild).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(leaveChild).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(parseNext).expect(safe and s.cur.regs==List(2,1,0))
 run oldReceiptFirstTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(enterChild).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(prepareRetry(0)).then(lookupExisting).expect(safe and s.ack==1 and s.cur.gen==2)
 run stalePermitLookupTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(rotateFence).then(prepareRetry(0)).then(lookupExisting).expect(safe and s.ack==1 and s.ticket!=s.fence)
 run semanticResumeTest=init.then(saveBefore).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(resumeBefore).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).expect(safe and s.req==3 and s.cur.gen==2)
 run fenceRejectionTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(rotateFence).then(checkFence).then(abortCandidate).expect(safe and s.rejected and s.cur.gen==0)
 run baseRejectionTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(baseChanged).then(checkBase).then(abortCandidate).expect(safe and s.rejected and s.cur.gen==1)
 run otherWorkspaceTest=initOther.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).expect(safe and s.workspace==1)
 run staleFenceControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(rotateFence).then(forcePublish).expect(not(safe))
 run staleBaseControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(baseChanged).then(forcePublish).expect(not(safe))
 run rootOnlyControlTest=init.then(prepareEvent).then(buildRegistry).then(publishRootOnly).expect(not(safe))
 run indexOnlyControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishIndexOnly).expect(not(safe))
 run payloadCollisionControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(prepareRetry(0)).then(mismatchPayload).then(forceLookup).expect(not(safe))
 run newerAckControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(enterChild).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(prepareRetry(0)).then(lookupExisting).then(ackCurrent).expect(not(safe))
 run childAliasControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(enterChild).then(prepareEvent).then(nestedAlias).expect(not(safe))
 run resumeAliasControlTest=init.then(saveBefore).then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(resumeBefore).then(prepareEvent).then(resumedAlias).expect(not(safe))
 run unknownRootControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(loseAck).then(dropRoots).expect(not(safe))
 run prematureChildReturnControlTest=init.then(prepareEvent).then(buildRegistry).then(buildIndex).then(publishBundle).then(finishDelivery).then(enterChild).then(leaveTooSoon).expect(not(safe))
}
