module nr_anchor_retirement {
// Owner Env is the snapshot callback environment, not every coroutine Env.
// Process-lifetime typed-ID anchor remains live; raw-route closure is a native premise.
type State={token:int,queue:int,node:int,done:int,eeLive:int,senders:int,anchorPin:int,recordPin:int,recordGate:int,recordLive:int,generation:int,rawClosed:int}
pure val initial:State={token:0,queue:0,node:0,done:0,eeLive:1,senders:1,anchorPin:0,recordPin:0,recordGate:1,recordLive:1,generation:1,rawClosed:0}
var s:State
action init=s'=initial
val safe=all{s.token>=0,s.queue>=0,s.node>=0,s.done>=0,s.eeLive>=0,s.senders>=0,s.anchorPin>=0,s.recordPin>=0,s.recordGate>=0,s.recordLive>=0,s.generation>=0,s.rawClosed>=0,s.token<=6,s.queue<=1,s.node<=1,s.done<=1,s.eeLive<=1,s.senders<=1,s.anchorPin<=1,s.recordPin<=1,s.recordGate<=1,s.recordLive<=1,s.generation<=2,s.rawClosed<=1,s.generation>=1,s.token==0 implies all{s.node==0,s.queue==0},s.token==1 implies all{s.node==0,s.queue==0,s.done==0,s.eeLive==1},s.token==2 implies all{s.node==1,s.queue==1,s.done==0,s.eeLive==1},(s.token==3 or s.token==4 or s.token==6) implies all{s.node==1,s.queue==0,s.done==0,s.eeLive==1},s.token==5 implies all{s.node==0,s.queue==0,s.done==1},s.queue==1 implies s.token==2,s.done==1 implies all{(s.token==0 or s.token==5),s.node==0,s.queue==0},s.eeLive==0 implies s.done==1,s.recordPin==1 implies all{s.anchorPin==1,s.recordLive==1},s.recordGate==1 implies s.recordLive==1,s.senders==0 implies s.done==1,s.rawClosed==1 implies all{s.recordGate==0,s.senders==0},s.recordLive==0 implies all{s.recordGate==0,s.recordPin==0,s.senders==0,s.rawClosed==1,s.done==1,s.node==0,s.queue==0}}
action produceErrorToken=all{s.token==0 and s.done==0,s'={...s,token:1}}
action completeNoToken=all{s.token==0 and s.done==0,s'={...s,done:1}}
action enqueueToken=all{s.token==1,s'={...s,token:2,queue:1,node:1}}
action claimPrivateToken=all{s.token==1,s'={...s,token:3,node:1}}
action popCallback=all{s.token==2 and s.queue==1,s'={...s,token:3,queue:0}}
action knownTokenConsumption=all{s.token==3,s'={...s,token:4}}
action unknownCallbackExit=all{s.token==3,s'={...s,token:6}}
action reconcileKnownConsumption=all{s.token==6,s'={...s,token:4}}
action finishLanding=all{s.token==4 and s.node==1,s'={...s,token:5,node:0,done:1}}
action exitOwnerEnv=all{s.eeLive==1 and s.done==1 and (s.token==0 or s.token==5) and s.node==0 and s.queue==0,s'={...s,eeLive:0}}
action acquireAnchor=all{s.anchorPin==0,s'={...s,anchorPin:1}}
action lookupFirstRecord=all{s.anchorPin==1 and s.recordGate==1 and s.recordLive==1 and s.recordPin==0 and s.generation==1,s'={...s,recordPin:1}}
action lookupSecondRecord=all{s.anchorPin==1 and s.recordGate==1 and s.recordLive==1 and s.recordPin==0 and s.generation==2,s'={...s,recordPin:1}}
action releaseRecord=all{s.recordPin==1,s'={...s,recordPin:0}}
action releaseAnchor=all{s.anchorPin==1 and s.recordPin==0,s'={...s,anchorPin:0}}
action closeRecordGate=all{s.recordGate==1,s'={...s,recordGate:0}}
action closeSenders=all{s.done==1 and (s.token==0 or s.token==5) and s.senders==1,s'={...s,senders:0}}
action closeRawRoutes=all{s.recordGate==0 and s.senders==0 and s.rawClosed==0,s'={...s,rawClosed:1}}
action retireRecord=all{s.recordLive==1 and s.recordGate==0 and s.recordPin==0 and s.senders==0 and s.rawClosed==1 and s.done==1 and s.node==0 and s.queue==0 and (s.token==0 or s.token==5),s'={...s,recordLive:0}}
action reuseSlot=all{s.recordLive==0 and s.anchorPin==0 and s.generation==1,s'={...s,token:0,queue:0,node:0,done:0,eeLive:1,senders:1,recordGate:1,recordLive:1,generation:2,rawClosed:0}}
action acceptFirstAck=all{s.anchorPin==1 and s.generation==1 and s.recordLive==1 and s.senders==1,s'=s}
action rejectFirstAfterReuse=all{s.anchorPin==1 and s.generation==2,s'=s}
action step=any{produceErrorToken,completeNoToken,enqueueToken,claimPrivateToken,popCallback,knownTokenConsumption,unknownCallbackExit,reconcileKnownConsumption,finishLanding,exitOwnerEnv,acquireAnchor,lookupFirstRecord,lookupSecondRecord,releaseRecord,releaseAnchor,closeRecordGate,closeSenders,closeRawRoutes,retireRecord,reuseSlot,acceptFirstAck,rejectFirstAfterReuse,all{s'=s}}
run parsePrivateTest=init.then(produceErrorToken).then(claimPrivateToken).then(knownTokenConsumption).then(finishLanding).then(closeRecordGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(all{assert(safe),s'=s})
run parseSuccessTest=init.then(completeNoToken).then(closeRecordGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(all{assert(safe),s'=s})
run nrNormalTest=init.then(produceErrorToken).then(enqueueToken).then(popCallback).then(knownTokenConsumption).then(finishLanding).then(exitOwnerEnv).then(closeRecordGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(all{assert(safe),s'=s})
run unknownPoppedTest=init.then(produceErrorToken).then(enqueueToken).then(popCallback).then(unknownCallbackExit).then(closeRecordGate).then(all{assert(safe),s'=s})
run oldReaderTest=init.then(produceErrorToken).then(enqueueToken).then(popCallback).then(knownTokenConsumption).then(finishLanding).then(acquireAnchor).then(lookupFirstRecord).then(closeRecordGate).then(closeSenders).then(closeRawRoutes).then(releaseRecord).then(releaseAnchor).then(retireRecord).then(all{assert(safe),s'=s})
run lateAckTest=init.then(produceErrorToken).then(enqueueToken).then(popCallback).then(knownTokenConsumption).then(finishLanding).then(closeRecordGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(acquireAnchor).then(releaseAnchor).then(reuseSlot).then(acquireAnchor).then(rejectFirstAfterReuse).then(releaseAnchor).then(all{assert(safe),s'=s})
}
