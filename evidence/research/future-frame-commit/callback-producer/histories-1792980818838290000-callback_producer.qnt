module callback_producer {
// Two sequential child identities under one admitted eval/event-pump producer.
// Two is a bounded witness, not an arbitrary-script callback limit.
type State={gate:int,producer:int,ticket:int,phase:int,done:int,receipt:int,resultPhase:int,resultReceipt:int,origin:int,retired:int}
pure val initial:State={gate:1,producer:1,ticket:0,phase:0,done:0,receipt:0,resultPhase:0,resultReceipt:0,origin:0,retired:0}
var s:State
action init=s'=initial
val safe=all{s.gate>=0,s.producer>=0,s.ticket>=0,s.phase>=0,s.done>=0,s.receipt>=0,s.resultPhase>=0,s.resultReceipt>=0,s.origin>=0,s.retired>=0,s.gate<=1,s.producer<=1,s.ticket<=2,s.phase<=5,s.done<=2,s.receipt<=1,s.resultPhase<=4,s.resultReceipt<=1,s.origin<=1,s.retired<=1,s.done<=s.ticket,s.ticket-s.done<=1,s.phase==0 implies all{s.ticket==0,s.done==0,s.receipt==0},s.phase>=1 and s.phase<=4 implies all{s.producer==1,s.ticket>=1,s.ticket==s.done+1},s.phase==5 implies all{s.done==s.ticket,s.ticket>=1,s.receipt==1},s.receipt==1 implies (s.phase==3 or s.phase==4 or s.phase==5),s.producer==0 implies all{(s.phase==0 or s.phase==5),s.done==s.ticket},s.resultPhase==0 implies all{s.origin==0,s.resultReceipt==0},s.resultPhase>=1 and s.resultPhase<=3 implies s.origin==1,s.resultPhase==1 implies s.resultReceipt==0,s.resultReceipt==1 implies s.resultPhase>=2,s.resultPhase==4 implies all{s.origin==0,s.resultReceipt==1},s.retired==1 implies all{s.gate==0,s.producer==0,s.done==s.ticket,(s.phase==0 or s.phase==5),(s.resultPhase==0 or s.resultPhase==4),s.origin==0},s.producer==1 implies s.retired==0}
action closeRoots=all{s.gate==1,s'={...s,gate:0}}
action dispatchChild=all{s.producer==1 and (s.phase==0 or s.phase==5) and s.done==s.ticket and s.ticket<2,s'={...s,ticket:s.ticket+1,phase:1,receipt:0}}
action landingFirst=all{s.ticket==1 and s.phase==1,s'={...s,phase:2}}
action landingSecond=all{s.ticket==2 and s.phase==1,s'={...s,phase:2}}
action beginCleanup=all{s.phase==2,s'={...s,phase:3}}
action loseCleanup=all{s.phase==3,s'={...s,phase:4}}
action cleanupReceiptFirst=all{s.ticket==1 and (s.phase==3 or s.phase==4) and s.receipt==0,s'={...s,receipt:1}}
action cleanupReceiptSecond=all{s.ticket==2 and (s.phase==3 or s.phase==4) and s.receipt==0,s'={...s,receipt:1}}
action settleFirst=all{s.ticket==1 and s.done==0 and (s.phase==3 or s.phase==4) and s.receipt==1,s'={...s,done:1,phase:5}}
action settleSecond=all{s.ticket==2 and s.done==1 and (s.phase==3 or s.phase==4) and s.receipt==1,s'={...s,done:2,phase:5}}
action sealProducer=all{s.producer==1 and (s.phase==0 or s.phase==5) and s.done==s.ticket,s'={...s,producer:0}}
action publishResult=all{s.producer==1 and s.phase==2 and s.resultPhase==0,s'={...s,resultPhase:1,origin:1}}
action beginResultRelease=all{s.resultPhase==1,s'={...s,resultPhase:2}}
action loseResultRelease=all{s.resultPhase==2,s'={...s,resultPhase:3}}
action resultReleaseReceipt=all{(s.resultPhase==2 or s.resultPhase==3) and s.resultReceipt==0,s'={...s,resultReceipt:1}}
action settleResultRelease=all{(s.resultPhase==2 or s.resultPhase==3) and s.resultReceipt==1,s'={...s,resultPhase:4,origin:0}}
action retireDomain=all{s.gate==0 and s.producer==0 and s.done==s.ticket and (s.phase==0 or s.phase==5) and (s.resultPhase==0 or s.resultPhase==4) and s.origin==0 and s.retired==0,s'={...s,retired:1}}
action step=any{closeRoots,dispatchChild,landingFirst,landingSecond,beginCleanup,loseCleanup,cleanupReceiptFirst,cleanupReceiptSecond,settleFirst,settleSecond,sealProducer,publishResult,beginResultRelease,loseResultRelease,resultReleaseReceipt,settleResultRelease,retireDomain,all{s'=s}}
run twoAfterCloseTest=init.then(closeRoots).then(dispatchChild).then(landingFirst).then(beginCleanup).then(cleanupReceiptFirst).then(settleFirst).then(dispatchChild).then(landingSecond).then(beginCleanup).then(cleanupReceiptSecond).then(settleSecond).then(sealProducer).then(retireDomain).then(all{assert(safe),s'=s})
run noChildTest=init.then(closeRoots).then(sealProducer).then(retireDomain).then(all{assert(safe),s'=s})
run unknownCleanupTest=init.then(dispatchChild).then(landingFirst).then(beginCleanup).then(loseCleanup).then(closeRoots).then(all{assert(safe),s'=s})
run knownCleanupReceiptTest=init.then(dispatchChild).then(landingFirst).then(beginCleanup).then(loseCleanup).then(closeRoots).then(cleanupReceiptFirst).then(settleFirst).then(sealProducer).then(retireDomain).then(all{assert(safe),s'=s})
run resultUnknownTest=init.then(dispatchChild).then(landingFirst).then(publishResult).then(beginCleanup).then(cleanupReceiptFirst).then(settleFirst).then(sealProducer).then(closeRoots).then(beginResultRelease).then(loseResultRelease).then(all{assert(safe),s'=s})
run resultSettledTest=init.then(dispatchChild).then(landingFirst).then(publishResult).then(beginCleanup).then(cleanupReceiptFirst).then(settleFirst).then(sealProducer).then(closeRoots).then(beginResultRelease).then(resultReleaseReceipt).then(settleResultRelease).then(retireDomain).then(all{assert(safe),s'=s})
}
