module native_return_domains {
// Finite two-shot protocol. Root coverage and admitted owner are initial premises.
type State={phase:int,threadLive:int,stackLive:int,returnRight:int,guard:int,root:int,shot:int,ticket:int,retained:int,closed:int,grace:int}
pure val initial:State={phase:0,threadLive:1,stackLive:1,returnRight:1,guard:0,root:1,shot:0,ticket:0,retained:1,closed:0,grace:0}
var s:State
action init=s'=initial
val safe=any{all{s.phase==0,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==0,s.root==1,s.shot==0,s.ticket==0,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==1,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==1,s.root==1,s.shot==0,s.ticket==1,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==2,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==1,s.root==1,s.shot==0,s.ticket==1,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==3,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==0,s.root==1,s.shot==0,s.ticket==1,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==4,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==1,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==5,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==0,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==6,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==7,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==1,s.root==1,s.shot==2,s.ticket==3,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==8,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==1,s.root==1,s.shot==2,s.ticket==3,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==9,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==1,s.shot==2,s.ticket==3,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==10,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==1,s.shot==2,s.ticket==3,s.retained==0,s.closed==1,s.grace==0},
all{s.phase==11,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==1,s.shot==2,s.ticket==3,s.retained==0,s.closed==1,s.grace==1},
all{s.phase==12,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==0,s.shot==2,s.ticket==3,s.retained==0,s.closed==1,s.grace==1},
all{s.phase==13,s.threadLive==0,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==0,s.shot==2,s.ticket==3,s.retained==0,s.closed==1,s.grace==1},
all{s.phase==14,s.threadLive==1,s.stackLive==2,s.returnRight==2,s.guard==1,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==15,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==1,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==16,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==0,s.root==1,s.shot==0,s.ticket==1,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==17,s.threadLive==1,s.stackLive==0,s.returnRight==0,s.guard==1,s.root==1,s.shot==1,s.ticket==2,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==18,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==1,s.root==1,s.shot==2,s.ticket==3,s.retained==1,s.closed==0,s.grace==0},
all{s.phase==19,s.threadLive==1,s.stackLive==1,s.returnRight==1,s.guard==0,s.root==1,s.shot==2,s.ticket==3,s.retained==1,s.closed==0,s.grace==0}}
action enterGuard=all{s.phase==0,s'={...s,phase:1,threadLive:1,stackLive:1,returnRight:1,guard:1,root:1,shot:0,ticket:1,retained:1,closed:0,grace:0}}
action captureScheme=all{s.phase==1,s'={...s,phase:2,threadLive:1,stackLive:1,returnRight:1,guard:1,root:1,shot:0,ticket:1,retained:1,closed:0,grace:0}}
action leaveActivation=all{s.phase==2,s'={...s,phase:3,threadLive:1,stackLive:1,returnRight:1,guard:0,root:1,shot:0,ticket:1,retained:1,closed:0,grace:0}}
action resumeFirst=all{s.phase==3,s'={...s,phase:4,threadLive:1,stackLive:1,returnRight:1,guard:1,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action settleFirst=all{s.phase==4,s'={...s,phase:5,threadLive:1,stackLive:1,returnRight:1,guard:0,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action physicalReturn=all{s.phase==5,s'={...s,phase:6,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action resumeSecond=all{s.phase==6,s'={...s,phase:7,threadLive:1,stackLive:0,returnRight:0,guard:1,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action rejectStaleReturn=all{s.phase==7,s'={...s,phase:8,threadLive:1,stackLive:0,returnRight:0,guard:1,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action settleSecond=all{s.phase==8,s'={...s,phase:9,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action closeCapture=all{s.phase==9,s'={...s,phase:10,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:2,ticket:3,retained:0,closed:1,grace:0}}
action scanGrace=all{s.phase==10,s'={...s,phase:11,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:2,ticket:3,retained:0,closed:1,grace:1}}
action retireRoots=all{s.phase==11,s'={...s,phase:12,threadLive:1,stackLive:0,returnRight:0,guard:0,root:0,shot:2,ticket:3,retained:0,closed:1,grace:1}}
action detachThread=all{s.phase==12,s'={...s,phase:13,threadLive:0,stackLive:0,returnRight:0,guard:0,root:0,shot:2,ticket:3,retained:0,closed:1,grace:1}}
action unknownExit=all{s.phase==4,s'={...s,phase:14,threadLive:1,stackLive:2,returnRight:2,guard:1,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action rejectWrongOwner=all{s.phase==4,s'={...s,phase:15,threadLive:1,stackLive:1,returnRight:1,guard:1,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action settleRejectedOwner=all{s.phase==15,s'={...s,phase:5,threadLive:1,stackLive:1,returnRight:1,guard:0,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action earlyPhysicalReturn=all{s.phase==3,s'={...s,phase:16,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:0,ticket:1,retained:1,closed:0,grace:0}}
action resumeAfterReturn=all{s.phase==16,s'={...s,phase:17,threadLive:1,stackLive:0,returnRight:0,guard:1,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action settleAfterReturn=all{s.phase==17,s'={...s,phase:6,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:1,ticket:2,retained:1,closed:0,grace:0}}
action resumeAgainLive=all{s.phase==5,s'={...s,phase:18,threadLive:1,stackLive:1,returnRight:1,guard:1,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action settleAgainLive=all{s.phase==18,s'={...s,phase:19,threadLive:1,stackLive:1,returnRight:1,guard:0,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action returnAfterTwo=all{s.phase==19,s'={...s,phase:9,threadLive:1,stackLive:0,returnRight:0,guard:0,root:1,shot:2,ticket:3,retained:1,closed:0,grace:0}}
action step=any{enterGuard,captureScheme,leaveActivation,resumeFirst,settleFirst,physicalReturn,resumeSecond,rejectStaleReturn,settleSecond,closeCapture,scanGrace,retireRoots,detachThread,unknownExit,rejectWrongOwner,settleRejectedOwner,earlyPhysicalReturn,resumeAfterReturn,settleAfterReturn,resumeAgainLive,settleAgainLive,returnAfterTwo,all{s'=s}}
run twoShotsStaleTest=init.then(enterGuard).then(captureScheme).then(leaveActivation).then(resumeFirst).then(settleFirst).then(physicalReturn).then(resumeSecond).then(rejectStaleReturn).then(settleSecond).then(closeCapture).then(scanGrace).then(retireRoots).then(detachThread).then(all{assert(s.phase==13),assert(safe),s'=s})
run unknownCustodyTest=init.then(enterGuard).then(captureScheme).then(leaveActivation).then(resumeFirst).then(unknownExit).then(all{assert(s.phase==14),assert(safe),s'=s})
run wrongOwnerTest=init.then(enterGuard).then(captureScheme).then(leaveActivation).then(resumeFirst).then(rejectWrongOwner).then(settleRejectedOwner).then(all{assert(s.phase==5),assert(safe),s'=s})
run earlyReturnTest=init.then(enterGuard).then(captureScheme).then(leaveActivation).then(earlyPhysicalReturn).then(resumeAfterReturn).then(settleAfterReturn).then(all{assert(s.phase==6),assert(safe),s'=s})
run twoLiveShotsTest=init.then(enterGuard).then(captureScheme).then(leaveActivation).then(resumeFirst).then(settleFirst).then(resumeAgainLive).then(settleAgainLive).then(returnAfterTwo).then(closeCapture).then(scanGrace).then(retireRoots).then(all{assert(s.phase==12),assert(safe),s'=s})
}
