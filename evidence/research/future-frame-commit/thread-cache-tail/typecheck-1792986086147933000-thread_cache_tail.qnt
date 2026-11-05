module thread_cache_tail {
// Existing nonnull interp cache, correct owner and valid cache representation are premises.
// Fast-tail attestation is native evidence, not inferred from mask=1.
type State={phase:int,count:int,initialCount:int,shared:int,counted:int,headPublished:int,qualified:int,receipt:int,owner:int,mask:int,supervisor:int,free:int,parentSlot:int,childSlot:int,extra:int,childPhase:int}
pure val initial:State={phase:0,count:0,initialCount:0,shared:0,counted:0,headPublished:0,qualified:0,receipt:0,owner:1,mask:1,supervisor:0,free:1,parentSlot:1,childSlot:0,extra:0,childPhase:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,s.count>=0,s.initialCount>=0,s.shared>=0,s.counted>=0,s.headPublished>=0,s.qualified>=0,s.receipt>=0,s.owner>=0,s.mask>=0,s.supervisor>=0,s.free>=0,s.parentSlot>=0,s.childSlot>=0,s.extra>=0,s.childPhase>=0,s.phase<=13,s.count<=1201,s.initialCount<=1200,s.shared<=800,s.counted<=1,s.headPublished<=1,s.qualified<=1,s.receipt<=1,s.owner<=1,s.mask<=3,s.supervisor<=1,s.free<=2,s.parentSlot<=1,s.childSlot<=1,s.extra<=1,s.childPhase<=4,s.mask>=1,s.free+s.parentSlot+s.childSlot+s.extra==2,s.count+s.shared==s.initialCount+s.counted,s.phase==0 implies all{s.count==0,s.initialCount==0,s.counted==0,s.headPublished==0,s.receipt==0},s.phase>=1 and s.phase<=3 implies all{s.counted==0,s.headPublished==0,s.receipt==0},s.phase==11 implies all{s.counted==0,s.headPublished==0,s.qualified==1,s.receipt==0},s.phase==12 implies all{s.counted==0,s.headPublished==1,s.qualified==1,s.receipt==0},s.phase==13 implies all{s.counted==1,s.headPublished==1,s.qualified==1,s.receipt==0,s.count<=1200},(s.phase==4 or s.phase==5) implies all{s.counted==1,s.headPublished==1,s.receipt==0},s.receipt==1 implies all{s.phase>=6,s.phase<=9,s.counted==1,s.headPublished==1,s.count<=1200},s.phase>=6 and s.phase<=9 implies s.receipt==1,s.phase==5 implies s.shared==800,s.phase!=5 and s.phase!=6 and s.phase!=7 and s.phase!=8 and s.phase!=9 and s.phase!=10 implies s.shared==0,s.phase!=9 implies s.parentSlot==1,s.phase==9 implies all{s.parentSlot==0,s.mask==3,s.supervisor==0},s.phase!=8 and s.phase!=9 implies s.mask==1,s.phase==8 implies all{s.mask==2,s.supervisor==1,s.parentSlot==1},s.supervisor==1 implies (s.phase==7 or s.phase==8),(s.childPhase==1 or s.childPhase==2 or s.childPhase==3) implies all{s.childSlot==1,s.phase==0,s.mask==1},(s.childPhase==0 or s.childPhase==4) implies s.childSlot==0,(s.phase==2 or s.phase==11 or s.phase==12) implies all{s.count>=1,s.count<1200}}
action enterChild=all{s.phase==0 and s.childPhase==0 and s.free>0,s'={...s,free:s.free-1,childSlot:1,childPhase:1}}
action childCleanupKnown=all{s.childPhase==1,s'={...s,childPhase:2}}
action beginChildRestore=all{s.childPhase==2,s'={...s,childPhase:3}}
action knownChildRestore=all{s.childPhase==3,s'={...s,childPhase:4,childSlot:0,free:s.free+1}}
action claimExtra=all{s.phase==0 and s.extra==0 and s.free>0,s'={...s,extra:1,free:s.free-1}}
action returnExtra=all{s.extra==1,s'={...s,extra:0,free:s.free+1}}
action denyOwner=all{s.phase==0,s'={...s,owner:0}}
action sampleEmpty=all{s.phase==0 and (s.childPhase==0 or s.childPhase==4),s'={...s,phase:1,count:0,initialCount:0}}
action sampleLow=all{s.phase==0 and (s.childPhase==0 or s.childPhase==4),s'={...s,phase:1,count:1,initialCount:1}}
action sampleNear=all{s.phase==0 and (s.childPhase==0 or s.childPhase==4),s'={...s,phase:1,count:1199,initialCount:1199}}
action sampleHigh=all{s.phase==0 and (s.childPhase==0 or s.childPhase==4),s'={...s,phase:1,count:1200,initialCount:1200}}
action selectFast=all{s.phase==1 and s.owner==1 and s.count>=1 and s.count<1200,s'={...s,phase:2}}
action selectHelper=all{s.phase==1 and s.owner==1 and (s.count==0 or s.count>=1200),s'={...s,phase:3}}
action attestFastTail=all{s.phase==2 and s.mask==1 and s.owner==1 and s.qualified==0,s'={...s,qualified:1}}
action writeFastLink=all{s.phase==2 and s.qualified==1 and s.mask==1,s'={...s,phase:11}}
action publishFastHead=all{s.phase==11 and s.mask==1,s'={...s,phase:12,headPublished:1}}
action incrementFastCount=all{s.phase==12 and s.mask==1,s'={...s,phase:13,count:s.count+1,counted:1}}
action publishFastReceipt=all{s.phase==13 and s.mask==1,s'={...s,phase:6,receipt:1}}
action helperPush=all{s.phase==3,s'={...s,phase:4,count:s.count+1,counted:1,headPublished:1}}
action helperFlush800=all{s.phase==4 and s.count>1200,s'={...s,phase:5,count:s.count-800,shared:800}}
action helperKnownReturn=all{(s.phase==4 and s.count<=1200) or s.phase==5,s'={...s,phase:6,receipt:1}}
action unknownHelper=all{(s.phase==3 or s.phase==4 or s.phase==5),s'={...s,phase:10}}
action handoffParent=all{s.phase==6 and s.receipt==1 and s.mask==1 and (s.childPhase==0 or s.childPhase==4) and s.childSlot==0,s'={...s,phase:7,supervisor:1}}
action beginParentRestore=all{s.phase==7 and s.supervisor==1 and s.mask==1,s'={...s,phase:8,mask:2}}
action knownParentRestore=all{s.phase==8 and s.supervisor==1 and s.mask==2,s'={...s,phase:9,mask:3,supervisor:0,parentSlot:0,free:s.free+1}}
action step=any{enterChild,childCleanupKnown,beginChildRestore,knownChildRestore,claimExtra,returnExtra,denyOwner,sampleEmpty,sampleLow,sampleNear,sampleHigh,selectFast,selectHelper,attestFastTail,writeFastLink,publishFastHead,incrementFastCount,publishFastReceipt,helperPush,helperFlush800,helperKnownReturn,unknownHelper,handoffParent,beginParentRestore,knownParentRestore,all{s'=s}}
run fast1199Test=init.then(sampleNear).then(selectFast).then(attestFastTail).then(writeFastLink).then(publishFastHead).then(incrementFastCount).then(publishFastReceipt).then(handoffParent).then(beginParentRestore).then(knownParentRestore).then(all{assert(safe),s'=s})
run emptyHelperTest=init.then(sampleEmpty).then(selectHelper).then(helperPush).then(helperKnownReturn).then(handoffParent).then(beginParentRestore).then(knownParentRestore).then(all{assert(safe),s'=s})
run highHelperTest=init.then(sampleHigh).then(selectHelper).then(helperPush).then(helperFlush800).then(helperKnownReturn).then(handoffParent).then(beginParentRestore).then(knownParentRestore).then(all{assert(safe),s'=s})
run unknownFlushTest=init.then(sampleHigh).then(selectHelper).then(helperPush).then(helperFlush800).then(unknownHelper).then(all{assert(safe),s'=s})
run childRestorePendingTest=init.then(enterChild).then(childCleanupKnown).then(beginChildRestore).then(all{assert(safe),s'=s})
run nestedKnownTest=init.then(enterChild).then(childCleanupKnown).then(beginChildRestore).then(knownChildRestore).then(sampleNear).then(selectFast).then(attestFastTail).then(writeFastLink).then(publishFastHead).then(incrementFastCount).then(publishFastReceipt).then(handoffParent).then(beginParentRestore).then(knownParentRestore).then(all{assert(safe),s'=s})
run extraDebtTest=init.then(claimExtra).then(sampleNear).then(selectFast).then(attestFastTail).then(writeFastLink).then(publishFastHead).then(incrementFastCount).then(publishFastReceipt).then(handoffParent).then(beginParentRestore).then(all{assert(safe),s'=s})
}
