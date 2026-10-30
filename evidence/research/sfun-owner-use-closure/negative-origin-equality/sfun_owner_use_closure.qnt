module sfun_owner_use_closure {
// One successfully rooted marker owner, up to four invocations and two Scheme shots.
// NoAbandon, complete native-return mediation and exact source lowering remain premises.
type State={stage:int,owner:int,epoch:int,terminal:int,active:int,gate:int,valid:int,ref:int,effects:int,done:int,closeOwner:int,closeEpoch:int,completed:int,origin:int,captured:int,shots:int,borrowers:int,escrow:int,exitAck:int,root:int,code:int,gc:int,critical:int,reply:int,oldOwner:int,oldEpoch:int}
pure val initial:State={stage:0,owner:1,epoch:0,terminal:0,active:0,gate:1,valid:1,ref:1,effects:0,done:0,closeOwner:0,closeEpoch:0,completed:0,origin:0,captured:0,shots:0,borrowers:0,escrow:0,exitAck:0,root:1,code:1,gc:0,critical:0,reply:0,oldOwner:0,oldEpoch:0}
var s:State
action init=s'=initial
val safe=all{s.stage>=0,
s.owner>=0,
s.epoch>=0,
s.terminal>=0,
s.active>=0,
s.gate>=0,
s.valid>=0,
s.ref>=0,
s.effects>=0,
s.done>=0,
s.closeOwner>=0,
s.closeEpoch>=0,
s.completed>=0,
s.origin>=0,
s.captured>=0,
s.shots>=0,
s.borrowers>=0,
s.escrow>=0,
s.exitAck>=0,
s.root>=0,
s.code>=0,
s.gc>=0,
s.critical>=0,
s.reply>=0,
s.oldOwner>=0,
s.oldEpoch>=0,
s.stage<=10,
s.owner<=2,
s.epoch<=4,
s.terminal<=1,
s.active<=1,
s.gate<=1,
s.valid<=1,
s.ref<=1,
s.effects<=1,
s.done<=1,
s.closeOwner<=2,
s.closeEpoch<=4,
s.completed<=4,
s.origin<=4,
s.captured<=1,
s.shots<=2,
s.borrowers<=1,
s.escrow<=1,
s.exitAck<=1,
s.root<=1,
s.code<=1,
s.gc<=1,
s.critical<=1,
s.reply<=1,
s.oldOwner<=1,
s.oldEpoch<=4,
s.owner>=1,
(s.terminal==1) implies (s.stage>=4 and s.completed==s.epoch and s.epoch>0),
(s.stage<=3) implies (s.terminal==0),
(s.closeOwner>0 and s.escrow==0) implies (s.terminal==1),
(s.closeOwner>0 and s.escrow==1) implies (s.exitAck==1),
s.ref+s.effects==1,
s.done<=s.effects,
s.completed<=s.epoch,
(s.active==1) implies (s.stage==1 and s.epoch>0 and s.completed<s.epoch),
(s.stage==1) implies (s.active==1 and s.gate==1 and s.valid==1),
(s.stage!=1) implies (s.active==0),
(s.stage==0) implies (s.epoch==0 and s.completed==0),
(s.stage==2 or s.stage==4) implies (s.epoch>0 and s.completed==s.epoch),
(s.stage==3) implies (s.completed==s.epoch),
(s.stage<=3) implies (s.gate==1),
(s.gate==1) implies (s.stage<=4 and s.valid==1),
(s.stage==4) implies (s.borrowers==0),
(s.stage>=5 and s.stage<=9) implies (s.gate==0 and s.valid==0 and s.active==0 and s.borrowers==0 and s.closeOwner==s.owner and s.closeEpoch==s.epoch),
(s.stage<=4 or s.stage==10) implies (s.closeOwner==0 and s.closeEpoch==0 and s.ref==1 and s.effects==0 and s.done==0 and s.critical==0 and s.valid==1),
(s.stage==5) implies (s.ref==1 and s.effects==0 and s.done==0),
(s.stage==6) implies (s.ref==0 and s.effects==1 and s.done==0 and s.critical==1),
(s.stage>=7 and s.stage<=9) implies (s.ref==0 and s.effects==1 and s.done==1 and s.critical==0),
(s.done==1) implies (s.stage>=7 and s.stage<=9 and s.closeOwner==s.owner and s.closeEpoch==s.epoch),
(s.effects==1) implies (s.stage>=6 and s.stage<=9),
(s.closeOwner>0) implies (s.stage>=5 and s.stage<=9 and s.gate==0 and s.active==0 and s.borrowers==0),
(s.critical==1) implies ((s.stage==5 or s.stage==6) and s.gc==0 and s.borrowers==0 and s.reply==0 and s.root==1 and s.code==1),
(s.gc==1) implies (s.root==1 and s.code==1 and s.critical==0),
(s.captured==1) implies (s.origin>0 and s.origin<=s.epoch and s.root==1 and s.code==1),
(s.captured==0) implies (s.origin==0),
(s.borrowers==1) implies (s.stage==1 or s.stage==2 or s.stage==10),
(s.stage==10) implies (s.escrow==1 and s.gate==0 and s.active==0),
(s.exitAck==1) implies (s.escrow==1 and s.gate==0 and s.borrowers==0 and s.stage>=5),
(s.escrow==0) implies (s.exitAck==0),
(s.stage<=4) implies (s.escrow==0 and s.exitAck==0),
(s.root==0) implies ((s.stage==8 or s.stage==9) and s.captured==0 and s.done==1 and s.gc==0 and s.gate==0 and s.borrowers==0),
(s.code==0) implies (s.stage==9 and s.root==0 and s.captured==0 and s.done==1 and s.gc==0),
(s.stage<=7 or s.stage==10) implies (s.root==1 and s.code==1),
(s.stage==8) implies (s.root==0 and s.code==1),
(s.stage==9) implies (s.root==0 and s.code==0),
(s.stage>=8 and s.stage<=9) implies (s.captured==0 and s.gc==0),
(s.reply==1) implies ((s.stage==5 or s.stage==7) and s.critical==0),
(s.owner==1) implies (s.oldOwner==0 and s.oldEpoch==0),
(s.owner==2) implies (s.oldOwner==1),
s.oldOwner<s.owner}
action bodyCall=all{s.stage==0 and s.gc==0,s'={...s,stage:1,active:1,epoch:1}}
action inputConversionFails=all{s.stage==0 and s.gc==0,s'={...s,stage:3}}
action captureCurrent=all{s.stage==1 and s.captured==0 and s.gc==0,s'={...s,captured:1,origin:s.epoch}}
action callReturns=all{s.stage==1 and s.borrowers==0 and s.gc==0,s'={...s,stage:2,active:0,completed:s.epoch}}
action resultConversionFails=all{s.stage==2 and s.borrowers==0 and s.gc==0,s'={...s,stage:3}}
action retryHandler=all{s.stage==3 and s.epoch<4 and s.gc==0 and s.borrowers==0,s'={...s,stage:1,active:1,epoch:s.epoch+1}}
action resultConversionSucceeds=all{s.stage==2 and s.borrowers==0 and s.gc==0,s'={...s,stage:4,terminal:1}}
action closeAdmission=all{s.stage==4 and s.gate==1 and s.gc==0,s'={...s,gate:0}}
action signLocalClosure=all{s.stage==4 and s.gate==0 and s.terminal==1 and s.gc==0,s'={...s,stage:5,valid:0,closeOwner:s.owner,closeEpoch:s.epoch}}
action enterNested=all{(s.stage==1 or s.stage==2) and s.borrowers==0 and s.gc==0,s'={...s,borrowers:1}}
action leaveNested=all{(s.stage==1 or s.stage==2) and s.borrowers==1 and s.gc==0,s'={...s,borrowers:0}}
action outwardUnknown=all{s.stage<=4 and s.stage>=1 and s.gc==0,s'={...s,stage:10,active:0,gate:0,escrow:1}}
action drainDescendant=all{s.stage==10 and s.borrowers==1 and s.gc==0,s'={...s,borrowers:0}}
action ackNativeExit=all{s.stage==10 and s.borrowers==0 and s.gc==0,s'={...s,exitAck:1}}
action signEscapedClosure=all{s.stage==10 and s.exitAck==1 and s.gc==0,s'={...s,stage:5,valid:0,closeOwner:s.owner,closeEpoch:s.epoch}}
action beginRelease=all{s.stage==5 and s.critical==0 and s.gc==0 and s.reply==0 and s.closeOwner==s.owner and s.closeEpoch==s.epoch,s'={...s,critical:1}}
action physicalDrop=all{s.stage==5 and s.critical==1,s'={...s,stage:6,ref:0,effects:1}}
action commitDrop=all{s.stage==6 and s.critical==1,s'={...s,stage:7,done:1,critical:0}}
action loseClosureReply=all{(s.stage==5 or s.stage==7) and s.reply==0 and s.critical==0,s'={...s,reply:1}}
action queryClosure=all{(s.stage==5 or s.stage==7) and s.reply==1,s'={...s,reply:0}}
action observeOldInvocation=all{s.stage==1 and s.completed>0 and s.completed<s.epoch and s.gc==0,s'={...s,completed:s.completed}}
action observeOldOwner=all{s.owner==2 and s.oldOwner==1 and s.gate==1 and s.gc==0,s'={...s,oldOwner:s.oldOwner}}
action resumeOldReturn=all{s.origin==s.epoch and s.stage==1 and s.captured==1 and s.shots<2 and s.borrowers==0 and s.gc==0,s'={...s,stage:2,active:0,completed:s.epoch,shots:s.shots+1}}
action resumeExpiredPrefix=all{s.stage==7 and s.captured==1 and s.shots<2 and s.gc==0,s'={...s,shots:s.shots+1}}
action rejectExpiredReturn=all{s.stage==7 and s.captured==1 and s.gc==0,s'={...s,shots:s.shots}}
action dropCaptured=all{s.stage==7 and s.captured==1 and s.gc==0,s'={...s,captured:0,origin:0}}
action beginGc=all{s.root==1 and s.code==1 and s.critical==0 and s.gc==0,s'={...s,gc:1}}
action endGc=all{s.gc==1,s'={...s,gc:0}}
action retireRoots=all{s.stage==7 and s.captured==0 and s.gc==0 and s.reply==0,s'={...s,stage:8,root:0}}
action retireCode=all{s.stage==8,s'={...s,stage:9,code:0}}
action newOwner=all{s.stage==9 and s.owner==1,s'={...s,stage:0,owner:2,epoch:0,terminal:0,active:0,gate:1,valid:1,ref:1,effects:0,done:0,closeOwner:0,closeEpoch:0,completed:0,origin:0,captured:0,shots:0,borrowers:0,escrow:0,exitAck:0,root:1,code:1,gc:0,critical:0,reply:0,oldOwner:s.closeOwner,oldEpoch:s.closeEpoch}}
action step=any{bodyCall,inputConversionFails,captureCurrent,callReturns,resultConversionFails,retryHandler,resultConversionSucceeds,closeAdmission,signLocalClosure,enterNested,leaveNested,outwardUnknown,drainDescendant,ackNativeExit,signEscapedClosure,beginRelease,physicalDrop,commitDrop,loseClosureReply,queryClosure,observeOldInvocation,observeOldOwner,resumeOldReturn,resumeExpiredPrefix,rejectExpiredReturn,dropCaptured,beginGc,endGc,retireRoots,retireCode,newOwner,all{s'=s}}
run normalTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(retireRoots).then(retireCode).then(all{assert(s.stage==9 and s.effects==1),assert(safe),s'=s})
run oldInvocationTest=init.then(bodyCall).then(callReturns).then(resultConversionFails).then(retryHandler).then(observeOldInvocation).then(all{assert(s.active==1 and s.valid==1 and s.ref==1 and s.closeOwner==0 and s.completed<s.epoch),assert(safe),s'=s})
run twoOldResumptionsTest=init.then(bodyCall).then(callReturns).then(resultConversionFails).then(retryHandler).then(captureCurrent).then(callReturns).then(resultConversionFails).then(retryHandler).then(resumeOldReturn).then(resultConversionFails).then(retryHandler).then(resumeOldReturn).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(all{assert(s.origin==2 and s.epoch==4 and s.completed==4 and s.shots==2 and s.ref==0 and s.captured==1),assert(safe),s'=s})
run inputFailureTest=init.then(inputConversionFails).then(retryHandler).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(all{assert(s.done==1 and s.epoch==1),assert(safe),s'=s})
run unknownEscapeTest=init.then(bodyCall).then(captureCurrent).then(enterNested).then(outwardUnknown).then(all{assert(s.stage==10 and s.exitAck==0 and s.borrowers==1 and s.ref==1 and s.closeOwner==0 and s.root==1),assert(safe),s'=s})
run drainedEscapeTest=init.then(bodyCall).then(enterNested).then(outwardUnknown).then(drainDescendant).then(ackNativeExit).then(signEscapedClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(retireRoots).then(retireCode).then(all{assert(s.stage==9 and s.escrow==1),assert(safe),s'=s})
run escapeBeforeCallTest=init.then(inputConversionFails).then(outwardUnknown).then(ackNativeExit).then(signEscapedClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(all{assert(s.epoch==0 and s.done==1),assert(safe),s'=s})
run lostReplyTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(loseClosureReply).then(queryClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(loseClosureReply).then(queryClosure).then(all{assert(s.ref==0 and s.effects==1 and s.done==1),assert(safe),s'=s})
run physicalGapTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(all{assert(s.ref==0 and s.effects==1 and s.done==0 and s.critical==1 and s.root==1),assert(safe),s'=s})
run gcDuringRetryTest=init.then(bodyCall).then(callReturns).then(resultConversionFails).then(retryHandler).then(beginGc).then(endGc).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(all{assert(s.epoch==2 and s.done==1),assert(safe),s'=s})
run gcCaptureLeaseTest=init.then(bodyCall).then(captureCurrent).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(beginGc).then(endGc).then(all{assert(s.valid==0 and s.captured==1 and s.root==1 and s.code==1),assert(safe),s'=s})
run expiredTwoShotsTest=init.then(bodyCall).then(captureCurrent).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(resumeExpiredPrefix).then(rejectExpiredReturn).then(resumeExpiredPrefix).then(rejectExpiredReturn).then(all{assert(s.shots==2 and s.active==0 and s.effects==1 and s.code==1),assert(safe),s'=s})
run staleOwnerGenerationTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(retireRoots).then(retireCode).then(newOwner).then(bodyCall).then(observeOldOwner).then(all{assert(s.owner==2 and s.oldOwner==1 and s.oldEpoch==s.epoch and s.active==1 and s.effects==0),assert(safe),s'=s})
run nestedConversionTest=init.then(bodyCall).then(callReturns).then(enterNested).then(all{assert(s.stage==2 and s.borrowers==1 and s.closeOwner==0 and s.valid==1),assert(safe),s'=s})
run captureRetirementTest=init.then(bodyCall).then(captureCurrent).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(dropCaptured).then(retireRoots).then(retireCode).then(all{assert(s.stage==9 and s.captured==0),assert(safe),s'=s})
run gcBeforeOwnerClosureTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(beginGc).then(endGc).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(all{assert(s.done==1),assert(safe),s'=s})
run witnessPerInvocationKillTest=init.then(bodyCall).then(all{assert(s.stage==1 and s.owner==1 and s.epoch==1 and s.terminal==0 and s.active==1 and s.gate==1 and s.valid==1 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==0 and s.closeEpoch==0 and s.completed==0 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessOldReceiptDropsCurrentTest=init.then(bodyCall).then(callReturns).then(resultConversionFails).then(retryHandler).then(all{assert(s.stage==1 and s.owner==1 and s.epoch==2 and s.terminal==0 and s.active==1 and s.gate==1 and s.valid==1 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==0 and s.closeEpoch==0 and s.completed==1 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessEscapeWithoutNativeAckTest=init.then(bodyCall).then(outwardUnknown).then(all{assert(s.stage==10 and s.owner==1 and s.epoch==1 and s.terminal==0 and s.active==0 and s.gate==0 and s.valid==1 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==0 and s.closeEpoch==0 and s.completed==0 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==1 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessConversionCompletesWithBorrowTest=init.then(bodyCall).then(callReturns).then(enterNested).then(all{assert(s.stage==2 and s.owner==1 and s.epoch==1 and s.terminal==0 and s.active==0 and s.gate==1 and s.valid==1 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==0 and s.closeEpoch==0 and s.completed==1 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==1 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessAbandonAfterEffectTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(all{assert(s.stage==5 and s.owner==1 and s.epoch==1 and s.terminal==1 and s.active==0 and s.gate==0 and s.valid==0 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==1 and s.closeEpoch==1 and s.completed==1 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==1 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessReplyReplaysReferenceDropTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(loseClosureReply).then(all{assert(s.stage==7 and s.owner==1 and s.epoch==1 and s.terminal==1 and s.active==0 and s.gate==0 and s.valid==0 and s.ref==0 and s.effects==1 and s.done==1 and s.closeOwner==1 and s.closeEpoch==1 and s.completed==1 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==1 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
run witnessEpochOnlyOwnerAbaTest=init.then(bodyCall).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(commitDrop).then(retireRoots).then(retireCode).then(newOwner).then(bodyCall).then(all{assert(s.stage==1 and s.owner==2 and s.epoch==1 and s.terminal==0 and s.active==1 and s.gate==1 and s.valid==1 and s.ref==1 and s.effects==0 and s.done==0 and s.closeOwner==0 and s.closeEpoch==0 and s.completed==0 and s.origin==0 and s.captured==0 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==0 and s.reply==0 and s.oldOwner==1 and s.oldEpoch==1),assert(safe),s'=s})
run witnessSettlementUnloadsCapturedCodeTest=init.then(bodyCall).then(captureCurrent).then(callReturns).then(resultConversionSucceeds).then(closeAdmission).then(signLocalClosure).then(beginRelease).then(physicalDrop).then(all{assert(s.stage==6 and s.owner==1 and s.epoch==1 and s.terminal==1 and s.active==0 and s.gate==0 and s.valid==0 and s.ref==0 and s.effects==1 and s.done==0 and s.closeOwner==1 and s.closeEpoch==1 and s.completed==1 and s.origin==1 and s.captured==1 and s.shots==0 and s.borrowers==0 and s.escrow==0 and s.exitAck==0 and s.root==1 and s.code==1 and s.gc==0 and s.critical==1 and s.reply==0 and s.oldOwner==0 and s.oldEpoch==0),assert(safe),s'=s})
}
