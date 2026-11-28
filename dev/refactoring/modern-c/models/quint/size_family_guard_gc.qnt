module size_family_guard_gc {
// One stable current attempt; old receipts survive logical reissue. No native ABI claim.
// completeBoxed abstracts initialization plus adoption; NoAbandon/source refinement remains open.
// lease=1 root update, lease=2 physical drop through receipt publication.
type State={phase:int,direction:int,created:int,hold:int,effects:int,carrier:int,lang:int,captured:int,guard:int,lease:int,closed:int,frozen:int,gc:int,scanners:int,scanned:int,exited:int,outcome:int,receiptId:int,reply:int,attempt:int,epoch:int,leaseEpoch:int,viewGuard:int,viewCarrier:int,viewAttempt:int,viewLang:int}
pure val initial:State={phase:0,direction:0,created:0,hold:0,effects:0,carrier:0,lang:0,captured:0,guard:0,lease:0,closed:0,frozen:0,gc:0,scanners:0,scanned:0,exited:0,outcome:0,receiptId:0,reply:0,attempt:0,epoch:1,leaseEpoch:0,viewGuard:0,viewCarrier:0,viewAttempt:0,viewLang:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,
s.phase<=9,
s.direction>=0,
s.direction<=1,
s.created>=0,
s.created<=1,
s.hold>=0,
s.hold<=1,
s.effects>=0,
s.effects<=1,
s.carrier>=0,
s.carrier<=1,
s.lang>=0,
s.lang<=1,
s.captured>=0,
s.captured<=1,
s.guard>=0,
s.guard<=1,
s.lease>=0,
s.lease<=2,
s.closed>=0,
s.closed<=1,
s.frozen>=0,
s.frozen<=1,
s.gc>=0,
s.gc<=1,
s.scanners>=0,
s.scanners<=1,
s.scanned>=0,
s.scanned<=1,
s.exited>=0,
s.exited<=1,
s.outcome>=0,
s.outcome<=2,
s.reply>=0,
s.reply<=1,
s.viewGuard>=0,
s.viewGuard<=1,
s.viewCarrier>=0,
s.viewCarrier<=1,
s.viewLang>=0,
s.viewLang<=1,
s.viewAttempt>=0,
s.viewAttempt<=s.attempt,
(s.frozen==1) implies (s.guard==s.viewGuard and s.carrier==s.viewCarrier and s.attempt==s.viewAttempt and s.lang==s.viewLang),
s.attempt>=0,
s.epoch>=1,
s.receiptId>=0,
s.receiptId<=s.attempt,
s.leaseEpoch>=0,
s.leaseEpoch<=s.epoch,
s.hold+s.effects==s.created,
s.captured<=s.lang,
(s.phase<=2) implies (s.created==0 and s.hold==0 and s.effects==0 and s.carrier==0 and s.lang==0 and s.captured==0),
(s.phase<=5) implies (s.effects==0),
(s.phase>=6) implies (s.hold==0 and s.effects==s.created),
(s.phase>=7) implies (s.receiptId==s.attempt),
(s.phase<=7) implies (s.reply==0),
(s.reply==1) implies ((s.phase==8 or s.phase==9) and s.receiptId==s.attempt),
(s.phase==0) implies (s.guard==0 and s.attempt==0),
(s.phase>=1) implies (s.attempt>=1),
(s.phase>=1 and s.phase<=8) implies (s.guard==1),
(s.phase>=3 and s.phase<=8) implies (s.carrier==1),
(s.phase==9) implies (s.guard==0 and s.carrier==0),
(s.phase<=3) implies (s.exited==0 and s.outcome==0),
(s.phase>=4) implies (s.exited==1 and s.outcome>=1),
(s.lease==1) implies (s.phase==3 or s.phase==8 or s.phase==9),
(s.lease==2) implies (s.phase==5 or s.phase==6 or s.phase==7),
(s.phase==5 or s.phase==6 or s.phase==7) implies (s.lease==2),
(s.lease>=1) implies (s.frozen==0 and s.gc==0 and s.leaseEpoch==s.epoch),
(s.frozen==1) implies (s.closed==1 and s.lease==0),
(s.gc==1) implies (s.frozen==1 and s.scanners==1),
(s.scanners==1) implies (s.gc==1),
(s.scanned==1) implies (s.frozen==1 and s.gc==0 and s.scanners==0),
(s.direction==1 and s.created==1 and s.outcome==1 and s.phase>=4 and s.phase<=7) implies (s.lang==1)}
action reserveSfun=all{s.phase==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:1,direction:0,guard:1,attempt:1}}
action reserveCfun=all{s.phase==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:1,direction:1,guard:1,attempt:1}}
action beginConversion=all{s.phase==1 and s.closed==0 and s.frozen==0 and s.gc==0 and s.lease==0,s'={...s,phase:2}}
action completeBoxed=all{s.phase==2 and s.closed==0 and s.frozen==0 and s.gc==0 and s.lease==0,s'={...s,phase:3,created:1,hold:1,carrier:1}}
action completeImmediate=all{s.phase==2 and s.closed==0 and s.frozen==0 and s.gc==0 and s.lease==0,s'={...s,phase:3,carrier:1}}
action abortBeforeConversion=all{(s.phase==1 or s.phase==2) and s.closed==0 and s.frozen==0 and s.gc==0 and s.lease==0,s'={...s,phase:4,carrier:1,exited:1,outcome:2}}
action acquireRootUpdate=all{(s.phase==3 or s.phase==8 or s.phase==9) and s.closed==0 and s.frozen==0 and s.gc==0 and s.lease==0,s'={...s,lease:1,leaseEpoch:s.epoch}}
action publishLanguage=all{s.phase==3 and s.lease==1 and s.frozen==0 and s.gc==0,s'={...s,lang:1}}
action releaseRootUpdate=all{s.lease==1 and s.frozen==0 and s.gc==0,s'={...s,lease:0}}
action captureArgument=all{s.phase==3 and s.direction==0 and s.lang==1 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,captured:1}}
action finishNative=all{s.phase==3 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0 and (s.direction==0 or s.lang==1 or s.created==0),s'={...s,phase:4,exited:1,outcome:1}}
action escapeNative=all{s.phase==3 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:4,exited:1,outcome:2}}
action claimDrop=all{s.phase==4 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:5,lease:2,leaseEpoch:s.epoch}}
action fuseCfunHandoff=all{s.phase==3 and s.direction==1 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:5,lang:1,exited:1,outcome:1,lease:2,leaseEpoch:s.epoch}}
action physicalDrop=all{s.phase==5 and s.lease==2 and s.leaseEpoch==s.epoch and s.frozen==0 and s.gc==0,s'={...s,phase:6,hold:0,effects:s.created}}
action recordDrop=all{s.phase==6 and s.lease==2 and s.leaseEpoch==s.epoch and s.frozen==0 and s.gc==0,s'={...s,phase:7,receiptId:s.attempt}}
action releaseDrop=all{s.phase==7 and s.lease==2 and s.receiptId==s.attempt and s.frozen==0 and s.gc==0,s'={...s,phase:8,lease:0,reply:1}}
action loseReply=all{(s.phase==8 or s.phase==9) and s.reply==1,s'={...s,reply:0}}
action queryReceipt=all{(s.phase==8 or s.phase==9) and s.receiptId==s.attempt,s'={...s,reply:1}}
action dropCapture=all{(s.phase==8 or s.phase==9) and s.closed==0 and s.lease==0 and s.frozen==0 and s.gc==0,s'={...s,captured:0}}
action clearLanguage=all{(s.phase==8 or s.phase==9) and s.captured==0 and s.lease==1 and s.frozen==0 and s.gc==0,s'={...s,lang:0}}
action retireGuard=all{s.phase==8 and s.lease==1 and s.frozen==0 and s.gc==0 and s.scanners==0,s'={...s,phase:9,guard:0,carrier:0}}
action reissueSfun=all{s.phase==9 and s.lang==0 and s.captured==0 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:1,direction:0,created:0,hold:0,effects:0,carrier:0,guard:1,exited:0,outcome:0,reply:0,attempt:s.attempt+1}}
action reissueCfun=all{s.phase==9 and s.lang==0 and s.captured==0 and s.lease==0 and s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,phase:1,direction:1,created:0,hold:0,effects:0,carrier:0,guard:1,exited:0,outcome:0,reply:0,attempt:s.attempt+1}}
action closeGate=all{s.closed==0 and s.frozen==0 and s.gc==0,s'={...s,closed:1}}
action freezeOwner=all{s.closed==1 and s.frozen==0 and s.lease==0 and s.gc==0 and s.scanned==0,s'={...s,frozen:1,viewGuard:s.guard,viewCarrier:s.carrier,viewAttempt:s.attempt,viewLang:s.lang}}
action beginScan=all{s.frozen==1 and s.gc==0 and s.scanned==0,s'={...s,gc:1,scanners:1}}
action endScan=all{s.gc==1 and s.scanners==1,s'={...s,gc:0,scanners:0,scanned:1}}
action resumeOwner=all{s.frozen==1 and s.gc==0 and s.scanners==0 and s.scanned==1 and s.lease==0,s'={...s,closed:0,frozen:0,scanned:0,epoch:s.epoch+1}}
action step=any{reserveSfun,reserveCfun,beginConversion,completeBoxed,completeImmediate,abortBeforeConversion,acquireRootUpdate,publishLanguage,releaseRootUpdate,captureArgument,finishNative,escapeNative,claimDrop,fuseCfunHandoff,physicalDrop,recordDrop,releaseDrop,loseReply,queryReceipt,dropCapture,clearLanguage,retireGuard,reissueSfun,reissueCfun,closeGate,freezeOwner,beginScan,endScan,resumeOwner,all{s'=s}}
run sfunNormalTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(acquireRootUpdate).then(publishLanguage).then(releaseRootUpdate).then(captureArgument).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run cfunNormalTest=init.then(reserveCfun).then(beginConversion).then(completeBoxed).then(acquireRootUpdate).then(publishLanguage).then(releaseRootUpdate).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run cfunFusedTest=init.then(reserveCfun).then(beginConversion).then(completeBoxed).then(fuseCfunHandoff).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run cfunAbortTest=init.then(reserveCfun).then(beginConversion).then(completeBoxed).then(escapeNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run preConversionAbortTest=init.then(reserveSfun).then(abortBeforeConversion).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run immediateTest=init.then(reserveCfun).then(beginConversion).then(completeImmediate).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run gcWhileConvertingTest=init.then(reserveSfun).then(beginConversion).then(closeGate).then(freezeOwner).then(beginScan).then(endScan).then(resumeOwner).then(completeBoxed).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run gcWhileHeldTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(closeGate).then(freezeOwner).then(beginScan).then(endScan).then(resumeOwner).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run closeDuringDropTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(finishNative).then(claimDrop).then(closeGate).then(physicalDrop).then(recordDrop).then(releaseDrop).then(freezeOwner).then(beginScan).then(endScan).then(resumeOwner).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run closeDuringTransferTest=init.then(reserveCfun).then(beginConversion).then(completeBoxed).then(acquireRootUpdate).then(closeGate).then(publishLanguage).then(releaseRootUpdate).then(freezeOwner).then(beginScan).then(endScan).then(resumeOwner).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run lostReplyTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(loseReply).then(queryReceipt).then(queryReceipt).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run captureRetireTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(acquireRootUpdate).then(publishLanguage).then(releaseRootUpdate).then(captureArgument).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(acquireRootUpdate).then(retireGuard).then(releaseRootUpdate).then(closeGate).then(freezeOwner).then(beginScan).then(endScan).then(resumeOwner).then(dropCapture).then(acquireRootUpdate).then(clearLanguage).then(releaseRootUpdate).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
run newAttemptTest=init.then(reserveSfun).then(beginConversion).then(completeBoxed).then(finishNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(acquireRootUpdate).then(retireGuard).then(releaseRootUpdate).then(reissueCfun).then(beginConversion).then(completeBoxed).then(escapeNative).then(claimDrop).then(physicalDrop).then(recordDrop).then(releaseDrop).then(loseReply).then(queryReceipt).then(all{assert(safe and s.hold==0 and s.effects==s.created and s.phase>=8),s'=s})
}
