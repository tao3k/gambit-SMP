module size_family_hold_balance {
// One stable conversion attempt; direction 0 SFUN input, 1 CFUN result.
// critical models a non-abandonable, GC-excluded physical effect/record window.
type State={phase:int,direction:int,x:int,created:int,hold:int,effects:int,root:int,captured:int,gc:int,reply:int,settled:int,critical:int,exited:int}
pure val initial:State={phase:0,direction:0,x:0,created:0,hold:0,effects:0,root:0,captured:0,gc:0,reply:0,settled:0,critical:0,exited:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,
s.phase<=6,
s.direction>=0,
s.direction<=1,
s.created>=0,
s.created<=1,
s.hold>=0,
s.hold<=1,
s.effects>=0,
s.effects<=1,
s.root>=0,
s.root<=1,
s.captured>=0,
s.captured<=1,
s.gc>=0,
s.gc<=1,
s.reply>=0,
s.reply<=1,
s.settled>=0,
s.settled<=1,
s.critical>=0,
s.critical<=1,
s.exited>=0,
s.exited<=1,
s.hold+s.effects==s.created,
s.captured<=s.root,
(s.phase<=1) implies (s.created==0 and s.effects==0 and s.root==0 and s.captured==0),
(s.phase<=4) implies (s.effects==0 and s.settled==0),
(s.phase>=5) implies (s.hold==0 and s.effects==s.created),
(s.phase==6) implies (s.settled==1 and s.critical==0),
(s.phase!=6) implies (s.settled==0 and s.reply==0),
(s.critical==1) implies ((s.phase==4 or s.phase==5) and s.gc==0),
(s.phase==4 or s.phase==5) implies (s.critical==1),
(s.phase>=3) implies (s.exited==1),
(s.phase<=2) implies (s.exited==0),
(s.direction==1 and s.created==1 and s.phase>=3 and s.phase<=5) implies (s.root==1)}
action selectSizeMax=all{s.phase==0,s'={...s,phase:1,x:18446744073709551615,direction:0}}
action selectSignedMin=all{s.phase==0,s'={...s,phase:1,x:-9223372036854775808,direction:0}}
action selectSignedMax=all{s.phase==0,s'={...s,phase:1,x:9223372036854775807,direction:1}}
action selectAboveFix=all{s.phase==0,s'={...s,phase:1,x:1152921504606846976,direction:1}}
action selectAtFix=all{s.phase==0,s'={...s,phase:1,x:1152921504606846975,direction:0}}
action selectMinFix=all{s.phase==0,s'={...s,phase:1,x:-1152921504606846976,direction:0}}
action selectBelowFix=all{s.phase==0,s'={...s,phase:1,x:-1152921504606846977,direction:1}}
action convertBoxed=all{s.phase==1 and (s.x < -1152921504606846976 or s.x > 1152921504606846975),s'={...s,phase:2,created:1,hold:1}}
action convertImmediate=all{s.phase==1 and s.x >= -1152921504606846976 and s.x <= 1152921504606846975,s'={...s,phase:2}}
action conversionFailure=all{s.phase==1,s'={...s,phase:2}}
action publishRoot=all{s.phase==2 and s.root==0 and s.gc==0,s'={...s,root:1}}
action captureArgument=all{s.phase==2 and s.direction==0 and s.root==1 and s.captured==0 and s.gc==0,s'={...s,captured:1}}
action finishNative=all{s.phase==2 and s.gc==0 and (s.direction==0 or s.root==1 or s.created==0),s'={...s,phase:3,exited:1}}
action enterDrop=all{s.phase==3 and s.gc==0 and (s.direction==0 or s.root==1 or s.created==0),s'={...s,phase:4,critical:1}}
action physicalDrop=all{s.phase==4 and s.critical==1 and s.gc==0,s'={...s,phase:5,hold:0,effects:s.created}}
action commitDrop=all{s.phase==5 and s.critical==1 and s.gc==0,s'={...s,phase:6,critical:0,settled:1,reply:1}}
action loseReply=all{s.phase==6 and s.reply==1,s'={...s,reply:0}}
action recoverReply=all{s.phase==6 and s.reply==0,s'={...s,reply:1}}
action dropCapture=all{s.phase==6 and s.captured==1 and s.gc==0,s'={...s,captured:0}}
action dropRoot=all{s.phase==6 and s.root==1 and s.captured==0 and s.gc==0,s'={...s,root:0}}
action beginGc=all{s.phase>=2 and s.gc==0 and s.critical==0,s'={...s,gc:1}}
action finishGc=all{s.gc==1,s'={...s,gc:0}}
action step=any{selectSizeMax,selectSignedMin,selectSignedMax,selectAboveFix,selectAtFix,selectMinFix,selectBelowFix,convertBoxed,convertImmediate,conversionFailure,publishRoot,captureArgument,finishNative,enterDrop,physicalDrop,commitDrop,loseReply,recoverReply,dropCapture,dropRoot,beginGc,finishGc,all{s'=s}}
run sfunBoxTest=init.then(selectSizeMax).then(convertBoxed).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run cfunRootTest=init.then(selectAboveFix).then(convertBoxed).then(publishRoot).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run captureTest=init.then(selectSignedMin).then(convertBoxed).then(publishRoot).then(captureArgument).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(beginGc).then(finishGc).then(dropCapture).then(dropRoot).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run immediateTest=init.then(selectAtFix).then(convertImmediate).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run failureTest=init.then(selectSignedMax).then(conversionFailure).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run lostReplyTest=init.then(selectBelowFix).then(convertBoxed).then(publishRoot).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(loseReply).then(recoverReply).then(loseReply).then(recoverReply).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run minFixTest=init.then(selectMinFix).then(convertImmediate).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
run gcBeforeDropTest=init.then(selectAboveFix).then(convertBoxed).then(beginGc).then(finishGc).then(publishRoot).then(finishNative).then(enterDrop).then(physicalDrop).then(commitDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.settled==1),s'=s})
}
