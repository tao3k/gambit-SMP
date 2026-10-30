module nr_inflight_handoff {
// Applied effects are ghost facts, never runtime free receipts.
// lock=1 lookup, 2 close, 3 reuse; process-lifetime typed resolver is a premise.
type State={stage:int,tokenApplied:int,nodeApplied:int,tokenReceipt:int,nodeReceipt:int,escrow:int,queue:int,lock:int,gate:int,pin:int,anchor:int,validated:int,live:int,generation:int,senders:int,rawClosed:int}
pure val initial:State={stage:0,tokenApplied:0,nodeApplied:0,tokenReceipt:0,nodeReceipt:0,escrow:0,queue:1,lock:0,gate:1,pin:0,anchor:0,validated:0,live:1,generation:1,senders:1,rawClosed:0}
var s:State
action init=s'=initial
val safe=all{s.stage>=0,s.tokenApplied>=0,s.nodeApplied>=0,s.tokenReceipt>=0,s.nodeReceipt>=0,s.escrow>=0,s.queue>=0,s.lock>=0,s.gate>=0,s.pin>=0,s.anchor>=0,s.validated>=0,s.live>=0,s.generation>=0,s.senders>=0,s.rawClosed>=0,s.stage<=9,s.tokenApplied<=1,s.nodeApplied<=1,s.tokenReceipt<=1,s.nodeReceipt<=1,s.escrow<=1,s.queue<=1,s.lock<=3,s.gate<=1,s.pin<=1,s.anchor<=1,s.validated<=1,s.live<=1,s.generation<=2,s.senders<=1,s.rawClosed<=1,s.generation>=1,s.stage==0 implies all{s.escrow==0,s.queue==1,s.tokenApplied==0,s.nodeApplied==0,s.tokenReceipt==0,s.nodeReceipt==0},s.stage==1 implies all{s.escrow==1,s.queue==1},s.stage>=2 implies s.queue==0,s.stage>=1 and s.stage<=8 implies s.escrow==1,s.stage<=2 implies all{s.tokenApplied==0,s.nodeApplied==0,s.tokenReceipt==0,s.nodeReceipt==0},s.stage<=5 implies all{s.nodeApplied==0,s.nodeReceipt==0},s.tokenReceipt==1 implies s.tokenApplied==1,s.nodeReceipt==1 implies s.nodeApplied==1,s.stage>=5 implies all{s.tokenApplied==1,s.tokenReceipt==1},s.stage>=8 implies all{s.nodeApplied==1,s.nodeReceipt==1},s.pin==1 implies all{s.anchor==1,s.live==1},s.validated==1 implies all{s.lock==1,s.anchor==1,s.gate==1,s.live==1,s.pin==0},s.lock==1 implies s.anchor==1,s.lock==3 implies all{s.anchor==0,s.pin==0,s.validated==0},s.gate==1 implies s.live==1,s.senders==0 implies all{s.stage==9,s.escrow==0},s.rawClosed==1 implies all{s.gate==0,s.senders==0},s.live==0 implies all{s.gate==0,s.pin==0,s.validated==0,s.stage==9,s.escrow==0,s.senders==0,s.rawClosed==1}}
action prepareEscrow=all{s.stage==0 and s.escrow==0,s'={...s,stage:1,escrow:1}}
action popNode=all{s.stage==1 and s.escrow==1 and s.queue==1,s'={...s,stage:2,queue:0}}
action beginToken=all{s.stage==2,s'={...s,stage:3}}
action applyTokenEffect=all{(s.stage==3 or s.stage==4) and s.tokenApplied==0,s'={...s,tokenApplied:1}}
action loseTokenReturn=all{s.stage==3,s'={...s,stage:4}}
action receiveTokenReceipt=all{(s.stage==3 or s.stage==4) and s.tokenApplied==1 and s.tokenReceipt==0,s'={...s,tokenReceipt:1}}
action confirmToken=all{(s.stage==3 or s.stage==4) and s.tokenReceipt==1,s'={...s,stage:5}}
action beginNodeRelease=all{s.stage==5,s'={...s,stage:6}}
action applyNodeEffect=all{(s.stage==6 or s.stage==7) and s.nodeApplied==0,s'={...s,nodeApplied:1}}
action loseNodeReturn=all{s.stage==6,s'={...s,stage:7}}
action receiveNodeReceipt=all{(s.stage==6 or s.stage==7) and s.nodeApplied==1 and s.nodeReceipt==0,s'={...s,nodeReceipt:1}}
action confirmNode=all{(s.stage==6 or s.stage==7) and s.nodeReceipt==1,s'={...s,stage:8}}
action publishDone=all{s.stage==8 and s.tokenReceipt==1 and s.nodeReceipt==1,s'={...s,stage:9}}
action releaseEscrow=all{s.stage==9 and s.escrow==1,s'={...s,escrow:0}}
action beginLookup=all{s.lock==0 and s.anchor==0 and s.pin==0,s'={...s,lock:1,anchor:1}}
action validateFirst=all{s.lock==1 and s.generation==1 and s.gate==1 and s.live==1 and s.validated==0 and s.pin==0,s'={...s,validated:1}}
action validateSecond=all{s.lock==1 and s.generation==2 and s.gate==1 and s.live==1 and s.validated==0 and s.pin==0,s'={...s,validated:1}}
action installPin=all{s.lock==1 and s.validated==1 and s.gate==1 and s.live==1 and s.pin==0,s'={...s,pin:1,validated:0}}
action unlockLookup=all{s.lock==1 and s.pin==1 and s.validated==0,s'={...s,lock:0}}
action releasePin=all{s.lock==0 and s.pin==1 and s.anchor==1,s'={...s,pin:0,anchor:0}}
action rejectClosedLookup=all{s.lock==1 and s.validated==0 and s.pin==0 and (s.gate==0 or s.live==0),s'={...s,lock:0,anchor:0}}
action rejectOldFirst=all{s.lock==1 and s.generation==2 and s.validated==0 and s.pin==0,s'={...s,lock:0,anchor:0}}
action acquireClose=all{s.lock==0,s'={...s,lock:2}}
action closeGate=all{s.lock==2 and s.gate==1,s'={...s,gate:0}}
action closeSenders=all{s.stage==9 and s.escrow==0 and s.senders==1,s'={...s,senders:0}}
action closeRawRoutes=all{s.gate==0 and s.senders==0 and s.rawClosed==0,s'={...s,rawClosed:1}}
action retireRecord=all{s.lock==2 and s.gate==0 and s.pin==0 and s.live==1 and s.stage==9 and s.escrow==0 and s.senders==0 and s.rawClosed==1,s'={...s,live:0}}
action unlockClose=all{s.lock==2,s'={...s,lock:0}}
action acquireReuse=all{s.lock==0 and s.live==0 and s.anchor==0 and s.generation==1,s'={...s,lock:3}}
action commitReuse=all{s.lock==3 and s.generation==1 and s.live==0,s'={...s,stage:0,tokenApplied:0,nodeApplied:0,tokenReceipt:0,nodeReceipt:0,escrow:0,queue:1,gate:1,validated:0,live:1,generation:2,senders:1,rawClosed:0}}
action unlockReuse=all{s.lock==3 and s.generation==2 and s.live==1,s'={...s,lock:0}}
action step=any{prepareEscrow,popNode,beginToken,applyTokenEffect,loseTokenReturn,receiveTokenReceipt,confirmToken,beginNodeRelease,applyNodeEffect,loseNodeReturn,receiveNodeReceipt,confirmNode,publishDone,releaseEscrow,beginLookup,validateFirst,validateSecond,installPin,unlockLookup,releasePin,rejectClosedLookup,rejectOldFirst,acquireClose,closeGate,closeSenders,closeRawRoutes,retireRecord,unlockClose,acquireReuse,commitReuse,unlockReuse,all{s'=s}}
run normalTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(receiveTokenReceipt).then(confirmToken).then(beginNodeRelease).then(applyNodeEffect).then(receiveNodeReceipt).then(confirmNode).then(publishDone).then(releaseEscrow).then(acquireClose).then(closeGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(unlockClose).then(all{assert(safe),s'=s})
run tokenUnknownTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(loseTokenReturn).then(all{assert(safe),s'=s})
run nodeUnknownTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(receiveTokenReceipt).then(confirmToken).then(beginNodeRelease).then(applyNodeEffect).then(loseNodeReturn).then(all{assert(safe),s'=s})
run readerBeforeCloseTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(receiveTokenReceipt).then(confirmToken).then(beginNodeRelease).then(applyNodeEffect).then(receiveNodeReceipt).then(confirmNode).then(publishDone).then(releaseEscrow).then(beginLookup).then(validateFirst).then(installPin).then(unlockLookup).then(acquireClose).then(closeGate).then(unlockClose).then(releasePin).then(closeSenders).then(closeRawRoutes).then(acquireClose).then(retireRecord).then(unlockClose).then(all{assert(safe),s'=s})
run closeBeforeLookupTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(receiveTokenReceipt).then(confirmToken).then(beginNodeRelease).then(applyNodeEffect).then(receiveNodeReceipt).then(confirmNode).then(publishDone).then(releaseEscrow).then(acquireClose).then(closeGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(unlockClose).then(beginLookup).then(rejectClosedLookup).then(all{assert(safe),s'=s})
run generationReuseTest=init.then(prepareEscrow).then(popNode).then(beginToken).then(applyTokenEffect).then(receiveTokenReceipt).then(confirmToken).then(beginNodeRelease).then(applyNodeEffect).then(receiveNodeReceipt).then(confirmNode).then(publishDone).then(releaseEscrow).then(acquireClose).then(closeGate).then(closeSenders).then(closeRawRoutes).then(retireRecord).then(unlockClose).then(acquireReuse).then(commitReuse).then(unlockReuse).then(beginLookup).then(rejectOldFirst).then(all{assert(safe),s'=s})
}
