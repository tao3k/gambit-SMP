module putobjs_custody {
// Selected n=1200 high-water return, valid 1201-node chain and original native owner.
type State={phase:int,mode:int,empty:int,walk:int,last:int,localCount:int,uncredited:int,exposed:int,delta:int,split:int,lock:int,sharedTail:int,lastFixed:int,receipt:int,escaped:int,held:int,gate:int,readers:int,generation:int,stamp:int,accepted:int,finalized:int}
pure val initial:State={phase:0,mode:0,empty:0,walk:0,last:0,localCount:1201,uncredited:0,exposed:0,delta:0,split:0,lock:0,sharedTail:0,lastFixed:0,receipt:0,escaped:0,held:1,gate:1,readers:1,generation:1,stamp:1,accepted:0,finalized:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,s.phase<=15,s.mode>=0,s.mode<=2,s.empty>=0,s.empty<=1,s.walk>=0,s.walk<=401,s.last>=0,s.last<=401,s.localCount>=0,s.localCount<=1201,s.uncredited>=0,s.uncredited<=800,s.exposed>=0,s.exposed<=800,s.delta>=0,s.delta<=800,s.split>=0,s.split<=1,s.lock>=0,s.lock<=2,s.sharedTail>=0,s.sharedTail<=1,s.lastFixed>=0,s.lastFixed<=1,s.receipt>=0,s.receipt<=1,s.escaped>=0,s.escaped<=1,s.held>=0,s.held<=1,s.gate>=0,s.gate<=1,s.readers>=0,s.readers<=1,s.generation>=0,s.generation<=2,s.stamp>=0,s.stamp<=1,s.accepted>=0,s.accepted<=1,s.finalized>=0,s.finalized<=1,s.generation>=1,s.stamp==1,s.localCount+s.uncredited+s.delta==1201,s.phase==0 implies all{s.localCount==1201,s.uncredited==0,s.walk==0,s.last==0},s.phase>=1 implies all{s.localCount==401,s.mode>=1},s.phase<=1 implies all{s.walk==0,s.last==0},s.phase==2 implies all{s.last==s.walk,s.walk<401},s.phase==3 implies all{s.last==s.walk+1,s.walk<401},s.phase==4 implies all{s.last==s.walk,s.walk>=1},s.phase>=5 implies all{s.walk==401,s.last==401},s.phase<=4 implies s.split==0,s.phase>=5 implies s.split==1,s.phase<=5 implies s.lock==0,s.phase>=6 and s.phase<=10 implies s.lock>=1,s.phase>=12 implies s.lock==0,s.lock==2 implies all{s.escaped==1,(s.phase==6 or s.phase==11)},s.phase<=7 implies s.exposed==0,s.phase>=8 implies s.exposed==800,s.phase<=8 implies s.sharedTail==0,s.phase>=9 implies s.sharedTail==1,s.phase<=9 implies s.delta==0,s.phase>=10 implies s.delta==800,s.phase<=11 implies s.lastFixed==0,s.phase>=12 implies s.lastFixed==1,s.phase<=12 implies s.receipt==0,s.phase>=13 implies s.receipt==1,s.phase<=13 implies all{s.gate==1,s.readers==1},s.phase>=14 implies s.gate==0,s.phase<=14 implies all{s.generation==1,s.held==1},s.phase==15 implies all{s.generation==2,s.held==0,s.readers==0,s.accepted==0,s.finalized==1},s.accepted==1 implies all{s.receipt==1,s.generation==s.stamp},s.finalized==1 implies all{s.phase>=14,s.readers==0}}
action admitOwner=all{s.phase==0 and s.mode==0,s'={...s,mode:1}}
action chooseEmpty=all{s.phase==8 and s.mode==1 and s.escaped==0,s'={...s,mode:2,empty:1}}
action chooseNonempty=all{s.phase==8 and s.mode==1 and s.escaped==0,s'={...s,mode:2,empty:0}}
action trimLocal=all{s.phase==0 and s.mode==1 and s.escaped==0,s'={...s,phase:1,localCount:401,uncredited:800}}
action loadLocalHead=all{s.phase==1 and s.escaped==0,s'={...s,phase:2}}
action assignLast=all{s.phase==2 and s.walk<401 and s.escaped==0,s'={...s,phase:3,last:s.walk+1}}
action advanceCursor=all{s.phase==3 and s.escaped==0,s'={...s,phase:4,walk:s.walk+1}}
action loopAgain=all{s.phase==4 and s.walk<401 and s.escaped==0,s'={...s,phase:2}}
action cutLocal=all{s.phase==4 and s.walk==401 and s.escaped==0,s'={...s,phase:5,split:1}}
action lockKnown=all{s.phase==5 and s.escaped==0,s'={...s,phase:6,lock:1}}
action lockUnknown=all{s.phase==5 and s.escaped==0,s'={...s,phase:6,lock:2,escaped:1}}
action linkOldTail=all{s.phase==6 and s.lock==1 and s.escaped==0,s'={...s,phase:7}}
action publishSharedHead=all{s.phase==7 and s.lock==1 and s.escaped==0,s'={...s,phase:8,exposed:800}}
action updateEmptySharedTail=all{s.phase==8 and s.mode==2 and s.empty==1 and s.escaped==0,s'={...s,phase:9,sharedTail:1}}
action keepSharedTail=all{s.phase==8 and s.mode==2 and s.empty==0 and s.escaped==0,s'={...s,phase:9,sharedTail:1}}
action addSharedCount=all{s.phase==9 and s.escaped==0,s'={...s,phase:10,delta:800,uncredited:0}}
action unlockKnown=all{s.phase==10 and s.lock==1 and s.escaped==0,s'={...s,phase:11,lock:0}}
action unlockUnknown=all{s.phase==10 and s.lock==1 and s.escaped==0,s'={...s,phase:11,lock:2,escaped:1}}
action fixLocalLast=all{s.phase==11 and s.lock==0 and s.escaped==0,s'={...s,phase:12,lastFixed:1}}
action publishReceipt=all{s.phase==12 and s.lock==0 and s.lastFixed==1 and s.escaped==0,s'={...s,phase:13,receipt:1}}
action escape=all{s.phase<=12 and s.mode==1 and s.escaped==0,s'={...s,escaped:1}}
action loseReceiptAck=all{s.phase==13 and s.receipt==1 and s.escaped==0,s'={...s,escaped:1}}
action acceptReceipt=all{s.receipt==1 and s.stamp==s.generation and s.held==1 and s.gate==1 and s.accepted==0,s'={...s,accepted:1}}
action closeAdmission=all{s.phase==13 and s.receipt==1,s'={...s,phase:14,gate:0}}
action readersDetached=all{s.phase==14 and s.readers==1,s'={...s,readers:0}}
action attestFinalization=all{s.phase==14 and s.readers==0 and s.finalized==0,s'={...s,finalized:1}}
action reuseAddress=all{s.phase==14 and s.readers==0 and s.finalized==1 and s.lock==0 and s.held==1,s'={...s,phase:15,generation:2,held:0,accepted:0}}
action step=any{admitOwner,chooseEmpty,chooseNonempty,trimLocal,loadLocalHead,assignLast,advanceCursor,loopAgain,cutLocal,lockKnown,lockUnknown,linkOldTail,publishSharedHead,updateEmptySharedTail,keepSharedTail,addSharedCount,unlockKnown,unlockUnknown,fixLocalLast,publishReceipt,escape,loseReceiptAck,acceptReceipt,closeAdmission,readersDetached,attestFinalization,reuseAddress,all{s'=s}}
run normalEmptyTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseEmpty).then(updateEmptySharedTail).then(addSharedCount).then(unlockKnown).then(fixLocalLast).then(publishReceipt).then(acceptReceipt).then(all{assert(safe),s'=s})
run normalNonemptyTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseNonempty).then(keepSharedTail).then(addSharedCount).then(unlockKnown).then(fixLocalLast).then(publishReceipt).then(all{assert(safe),s'=s})
run lockUnknownTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockUnknown).then(all{assert(safe),s'=s})
run unlockUnknownTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseEmpty).then(updateEmptySharedTail).then(addSharedCount).then(unlockUnknown).then(all{assert(safe),s'=s})
run staleReceiptTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseEmpty).then(updateEmptySharedTail).then(addSharedCount).then(unlockKnown).then(fixLocalLast).then(publishReceipt).then(closeAdmission).then(readersDetached).then(attestFinalization).then(reuseAddress).then(all{assert(safe),s'=s})
run lostAckTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)).then(cutLocal).then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseEmpty).then(updateEmptySharedTail).then(addSharedCount).then(unlockKnown).then(fixLocalLast).then(publishReceipt).then(loseReceiptAck).then(acceptReceipt).then(all{assert(safe),s'=s})
run partialWalkTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(assignLast).then(advanceCursor).then(escape).then(all{assert(safe),s'=s})
}
