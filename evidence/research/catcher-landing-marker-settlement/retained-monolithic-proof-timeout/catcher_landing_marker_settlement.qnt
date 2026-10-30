module catcher_landing_marker_settlement {
// Two accepted native extents; root admission and NoAbandon leaf permit are premises.
// Phases 10 and 12 expose physical decrement before receipt commit.
type State={phase:int,prepared:int,escrow:int,issued:int,errorClass:int,caught:int,current:int,validated:int,receipt:int,reply:int,refI:int,refO:int,doneI:int,doneO:int,effectsI:int,effectsO:int,critical:int,root:int,descriptor:int,captured:int,reader:int,scanStage:int,slot:int,cache:int,borrow:int,version:int,shotActive:int,shotTicket:int,contextSlot:int,closed:int,rootRetired:int,grace:int,guard:int,unknown:int,leafPermit:int,validI:int,validO:int}
pure val initial:State={phase:0,prepared:0,escrow:0,issued:0,errorClass:0,caught:0,current:2,validated:0,receipt:0,reply:0,refI:1,refO:1,doneI:0,doneO:0,effectsI:0,effectsO:0,critical:0,root:1,descriptor:1,captured:1,reader:0,scanStage:0,slot:1,cache:0,borrow:0,version:0,shotActive:0,shotTicket:0,contextSlot:0,closed:0,rootRetired:0,grace:0,guard:1,unknown:0,leafPermit:1,validI:1,validO:1}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,
s.prepared>=0,
s.escrow>=0,
s.issued>=0,
s.errorClass>=0,
s.caught>=0,
s.current>=0,
s.validated>=0,
s.receipt>=0,
s.reply>=0,
s.refI>=0,
s.refO>=0,
s.doneI>=0,
s.doneO>=0,
s.effectsI>=0,
s.effectsO>=0,
s.critical>=0,
s.root>=0,
s.descriptor>=0,
s.captured>=0,
s.reader>=0,
s.scanStage>=0,
s.slot>=0,
s.cache>=0,
s.borrow>=0,
s.version>=0,
s.shotActive>=0,
s.shotTicket>=0,
s.contextSlot>=0,
s.closed>=0,
s.rootRetired>=0,
s.grace>=0,
s.guard>=0,
s.unknown>=0,
s.leafPermit>=0,
s.validI>=0,
s.validO>=0,
s.phase<=21,
s.prepared<=2,
s.escrow<=1,
s.issued<=1,
s.errorClass<=2,
s.caught<=2,
s.current<=2,
s.validated<=1,
s.receipt<=1,
s.reply<=1,
s.refI<=1,
s.refO<=1,
s.doneI<=1,
s.doneO<=1,
s.effectsI<=1,
s.effectsO<=1,
s.critical<=2,
s.root<=1,
s.descriptor<=1,
s.captured<=1,
s.reader<=1,
s.scanStage<=2,
s.slot<=2,
s.cache<=2,
s.borrow<=1,
s.version<=1,
s.shotActive<=1,
s.shotTicket<=2,
s.contextSlot<=2,
s.closed<=1,
s.rootRetired<=1,
s.grace<=1,
s.guard<=3,
s.unknown<=1,
s.leafPermit<=1,
s.validI<=1,
s.validO<=1,
s.phase!=20,
s.leafPermit==1,
s.slot>=1,
s.guard>=1,
(s.phase==0) implies (s.prepared==0 and s.escrow==0),
(s.phase==1 or s.phase==21) implies (s.prepared==1 and s.escrow==0),
(s.phase==2) implies (s.prepared==2 and s.escrow==0),
(s.escrow==0) implies (s.phase==0 or s.phase==1 or s.phase==2 or s.phase==21),
(s.escrow==0) implies (s.issued==0 and s.receipt==0 and s.validI==1 and s.validO==1 and s.guard==1 and s.root==1 and s.descriptor==1 and s.captured==1 and s.critical==0),
(s.borrow==1) implies (s.phase==8 or s.phase==9 or s.phase==10 or s.phase==11 or s.phase==12 or s.phase==14),
(s.phase>=16 and s.phase<=19) implies (s.closed==1),
(s.phase>=17 and s.phase<=19) implies (s.root==0 and s.rootRetired==1),
(s.phase>=18 and s.phase<=19) implies (s.grace==1),
(s.phase>=4 and s.phase<=19) implies (s.errorClass>=1),
(s.phase<=3 or s.phase==21) implies (s.errorClass==0),
(s.receipt==1) implies (s.errorClass==1),
(s.phase>=3 and s.phase<=19) implies (s.escrow==1 and s.prepared==2 and s.validI==0 and s.validO==0 and s.guard>=2),
(s.escrow==1) implies (s.phase>=3 and s.phase<=19),
(s.issued==1) implies (s.phase>=4 and s.phase<=19),
(s.phase>=4 and s.phase<=19) implies (s.issued==1),
(s.phase<=4 or s.phase==21) implies (s.caught==0 and s.current==2),
(s.phase==5) implies (s.caught==2 and s.current==2),
(s.phase==6) implies (s.caught==2 and s.current==1),
(s.phase==7) implies (s.caught==1 and s.current==1),
(s.phase>=8 and s.phase<=19) implies (s.caught==1 and s.current==0),
(s.validated==1) implies (s.phase>=8 and s.phase<=19 and s.caught==1 and s.current==0 and s.issued==1),
(s.receipt==1) implies (s.phase>=9 and s.phase<=19 and s.validated==1),
(s.phase>=9 and s.phase<=19) implies (s.receipt==1),
(s.phase<=8 or s.phase==21) implies (s.refI==1 and s.refO==1 and s.effectsI==0 and s.effectsO==0 and s.doneI==0 and s.doneO==0 and s.critical==0),
(s.phase==9) implies (s.refI==1 and s.refO==1 and s.effectsI==0 and s.effectsO==0 and s.doneI==0 and s.doneO==0 and s.critical<=1),
(s.phase==10) implies (s.refI==0 and s.effectsI==1 and s.doneI==0 and s.refO==1 and s.effectsO==0 and s.doneO==0 and s.critical==1),
(s.phase==11) implies (s.refI==0 and s.effectsI==1 and s.doneI==1 and s.refO==1 and s.effectsO==0 and s.doneO==0 and (s.critical==0 or s.critical==2)),
(s.phase==12) implies (s.refI==0 and s.effectsI==1 and s.doneI==1 and s.refO==0 and s.effectsO==1 and s.doneO==0 and s.critical==2),
(s.phase>=13 and s.phase<=19) implies (s.refI==0 and s.refO==0 and s.effectsI==1 and s.effectsO==1 and s.doneI==1 and s.doneO==1 and s.critical==0),
s.refI+s.effectsI==1,
s.refO+s.effectsO==1,
s.doneI<=s.effectsI,
s.doneO<=s.effectsO,
(s.doneI==1) implies (s.receipt==1),
(s.doneO==1) implies (s.doneI==1 and s.receipt==1),
(s.critical==1) implies ((s.phase==9 or s.phase==10) and s.borrow==1 and s.reader==0 and s.receipt==1 and s.reply==0),
(s.critical==2) implies ((s.phase==11 or s.phase==12) and s.borrow==1 and s.reader==0 and s.receipt==1 and s.reply==0),
(s.phase>=14 and s.phase<=19) implies (s.guard==3),
(s.guard==3) implies (s.phase>=14 and s.phase<=19),
(s.guard==2) implies (s.phase>=3 and s.phase<=13),
(s.reply==1) implies ((s.phase==3 or s.phase==9 or s.phase==11 or s.phase==13) and s.critical==0 and s.borrow==0),
(s.unknown==1) implies (s.phase==21),
(s.phase==21) implies (s.unknown==1),
(s.root==0) implies (s.phase>=17 and s.phase<=19 and s.rootRetired==1 and s.guard==3 and s.captured==0 and s.closed==1 and s.reader==0 and s.borrow==0),
(s.rootRetired==1) implies (s.root==0 and s.closed==1 and s.reader==0 and s.doneI==1 and s.doneO==1),
(s.closed==1) implies (s.phase>=16 and s.phase<=19 and s.borrow==0 and s.critical==0 and s.captured==0 and s.shotActive==0 and s.guard==3),
(s.descriptor==0) implies (s.phase==19 and s.rootRetired==1 and s.grace==1 and s.reader==0 and s.captured==0),
(s.grace==1) implies ((s.phase==18 or s.phase==19) and s.rootRetired==1 and s.reader==0),
(s.captured==0) implies (s.phase>=15 and s.phase<=19 and s.shotActive==0),
(s.phase>=15 and s.phase<=19) implies (s.captured==0),
(s.shotActive==1) implies (s.phase==14 and s.captured==1 and s.root==1 and s.descriptor==1 and s.guard==3 and s.contextSlot>0 and s.borrow==0 and s.shotTicket>=1),
(s.shotActive==0) implies (s.contextSlot==0),
(s.reader==1) implies (s.root==1 and s.descriptor==1 and s.borrow==0 and s.critical==0),
(s.borrow==1) implies (s.reader==0 and s.root==1 and s.descriptor==1 and s.cache==s.slot and s.closed==0 and s.reply==0),
(s.shotActive==1 and (s.reader==0 or s.scanStage==0 or s.scanStage==2)) implies (s.contextSlot==s.slot),
(s.scanStage==1) implies (s.reader==1 and s.shotActive==1 and s.slot==2 and s.contextSlot==1 and s.version==1),
(s.scanStage==2) implies (s.reader==1 and s.slot==2 and s.version==1),
(s.version==0) implies (s.slot==1),
(s.version==1) implies (s.slot==2),
(s.scanStage>0) implies (s.reader==1),
(s.phase<=16) implies (s.root==1 and s.descriptor==1),
(s.phase==21) implies (s.root==1 and s.descriptor==1)}
action prepareFirst=all{s.phase==0,s'={...s,phase:1,prepared:1}}
action prepareSecond=all{s.phase==1 and s.unknown==0,s'={...s,phase:2,prepared:2}}
action rollbackPartial=all{s.phase==1 and s.unknown==0,s'={...s,phase:0,prepared:0}}
action rollbackReady=all{s.phase==2,s'={...s,phase:0,prepared:0}}
action preparationUnknown=all{s.phase==1,s'={...s,phase:21,unknown:1}}
action auditPreparation=all{s.phase==21,s'={...s,phase:1,unknown:0}}
action publishEscrow=all{s.phase==2 and s.reader==0 and s.borrow==0,s'={...s,phase:3,escrow:1,guard:2,validI:0,validO:0}}
action escrowReplyLost=all{s.phase==3 and s.reply==0,s'={...s,reply:1}}
action queryEscrow=all{s.phase==3 and s.reply==1,s'={...s,reply:0}}
action issueTransfer=all{s.phase==3 and s.reply==0 and s.reader==0,s'={...s,phase:4,issued:1,errorClass:1}}
action issueOtherError=all{s.phase==3 and s.reply==0 and s.reader==0,s'={...s,phase:4,issued:1,errorClass:2}}
action catchInner=all{s.phase==4,s'={...s,phase:5,caught:2}}
action restoreInnerCatcher=all{s.phase==5,s'={...s,phase:6,current:1}}
action catchOuter=all{s.phase==6,s'={...s,phase:7,caught:1}}
action restoreOuterCatcher=all{s.phase==7,s'={...s,phase:8,current:0}}
action borrowFresh=all{(s.phase==8 or s.phase==9 or s.phase==11 or s.phase==14) and s.reply==0 and s.reader==0 and s.borrow==0 and s.critical==0 and s.root==1 and s.closed==0 and s.shotActive==0,s'={...s,borrow:1,cache:s.slot}}
action releaseBorrow=all{s.borrow==1 and s.critical==0 and s.shotActive==0,s'={...s,borrow:0}}
action validateLanding=all{s.phase==8 and s.errorClass==1 and s.caught==1 and s.current==0 and s.issued==1 and s.borrow==1 and s.cache==s.slot and s.reader==0,s'={...s,validated:1}}
action publishLanding=all{s.phase==8 and s.validated==1 and s.borrow==1 and s.cache==s.slot,s'={...s,phase:9,receipt:1,borrow:0}}
action landingReplyLost=all{s.phase==9 and s.reply==0 and s.critical==0 and s.borrow==0,s'={...s,reply:1}}
action queryLanding=all{s.phase==9 and s.reply==1,s'={...s,reply:0}}
action beginInnerRelease=all{s.phase==9 and s.receipt==1 and s.reply==0 and s.borrow==1 and s.reader==0 and s.critical==0 and s.leafPermit==1,s'={...s,critical:1}}
action decrementInner=all{s.phase==9 and s.critical==1 and s.refI==1 and s.doneI==0,s'={...s,phase:10,refI:0,effectsI:1}}
action commitInnerRelease=all{s.phase==10 and s.critical==1 and s.refI==0,s'={...s,phase:11,doneI:1,critical:0,borrow:0}}
action innerReplyLost=all{s.phase==11 and s.reply==0 and s.critical==0 and s.borrow==0,s'={...s,reply:1}}
action queryInnerRelease=all{s.phase==11 and s.reply==1,s'={...s,reply:0}}
action beginOuterRelease=all{s.phase==11 and s.doneI==1 and s.reply==0 and s.borrow==1 and s.reader==0 and s.critical==0 and s.leafPermit==1,s'={...s,critical:2}}
action decrementOuter=all{s.phase==11 and s.critical==2 and s.refO==1 and s.doneO==0,s'={...s,phase:12,refO:0,effectsO:1}}
action commitOuterRelease=all{s.phase==12 and s.critical==2 and s.refO==0,s'={...s,phase:13,doneO:1,critical:0,borrow:0}}
action outerReplyLost=all{s.phase==13 and s.reply==0,s'={...s,reply:1}}
action queryOuterRelease=all{s.phase==13 and s.reply==1,s'={...s,reply:0}}
action settleGuards=all{s.phase==13 and s.doneI==1 and s.doneO==1 and s.reply==0,s'={...s,phase:14,guard:3}}
action resumeCaptured=all{s.phase==14 and s.captured==1 and s.borrow==1 and s.cache==s.slot and s.reader==0 and s.shotActive==0 and s.shotTicket<2,s'={...s,shotActive:1,shotTicket:s.shotTicket+1,contextSlot:s.slot,borrow:0}}
action finishResumption=all{s.phase==14 and s.shotActive==1 and s.reader==0 and s.contextSlot==s.slot,s'={...s,shotActive:0,contextSlot:0}}
action dropCaptured=all{s.phase==14 and s.shotActive==0 and s.borrow==0,s'={...s,phase:15,captured:0}}
action startGc=all{s.root==1 and s.descriptor==1 and s.closed==0 and s.borrow==0 and s.critical==0 and s.reader==0,s'={...s,reader:1}}
action rewriteRootOnly=all{s.reader==1 and s.version==0 and s.shotActive==0,s'={...s,slot:2,version:1,scanStage:2}}
action rewriteRegistryFirst=all{s.reader==1 and s.version==0 and s.shotActive==1,s'={...s,slot:2,version:1,scanStage:1}}
action rewriteContextSlot=all{s.reader==1 and s.scanStage==1,s'={...s,contextSlot:2,scanStage:2}}
action finishGc=all{s.reader==1 and s.scanStage!=1 and (s.shotActive==0 or s.contextSlot==s.slot),s'={...s,reader:0,scanStage:0}}
action closeRootAdmission=all{s.phase==15 and s.borrow==0 and s.critical==0,s'={...s,phase:16,closed:1}}
action retireRoots=all{s.phase==16 and s.reader==0,s'={...s,phase:17,root:0,rootRetired:1}}
action ackDescriptorGrace=all{s.phase==17 and s.reader==0,s'={...s,phase:18,grace:1}}
action retireDescriptor=all{s.phase==18 and s.root==0 and s.captured==0 and s.reader==0 and s.grace==1,s'={...s,phase:19,descriptor:0}}
action step=any{prepareFirst,prepareSecond,rollbackPartial,rollbackReady,preparationUnknown,auditPreparation,publishEscrow,escrowReplyLost,queryEscrow,issueTransfer,issueOtherError,catchInner,restoreInnerCatcher,catchOuter,restoreOuterCatcher,borrowFresh,releaseBorrow,validateLanding,publishLanding,landingReplyLost,queryLanding,beginInnerRelease,decrementInner,commitInnerRelease,innerReplyLost,queryInnerRelease,beginOuterRelease,decrementOuter,commitOuterRelease,outerReplyLost,queryOuterRelease,settleGuards,resumeCaptured,finishResumption,dropCaptured,startGc,rewriteRootOnly,rewriteRegistryFirst,rewriteContextSlot,finishGc,closeRootAdmission,retireRoots,ackDescriptorGrace,retireDescriptor,all{s'=s}}
run wrongErrorRejectedTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueOtherError).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(all{assert(s.receipt==0 and s.errorClass==2),assert(safe),s'=s})
run normalTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run partialRollbackTest=init.then(prepareFirst).then(rollbackPartial).then(all{assert(s.prepared==0 and s.validI==1),assert(safe),s'=s})
run partialUnknownTest=init.then(prepareFirst).then(preparationUnknown).then(startGc).then(rewriteRootOnly).then(finishGc).then(all{assert(s.unknown==1 and s.root==1),assert(safe),s'=s})
run partialReconciledTest=init.then(prepareFirst).then(preparationUnknown).then(auditPreparation).then(rollbackPartial).then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run lostEscrowTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(escrowReplyLost).then(queryEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run lostLandingTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(landingReplyLost).then(queryLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run lostMarkerRepliesTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(innerReplyLost).then(queryInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(outerReplyLost).then(queryOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.effectsI==1 and s.effectsO==1),assert(safe),s'=s})
run innerGapTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(all{assert(s.phase==10 and s.doneI==0 and s.critical==1),assert(safe),s'=s})
run transitNotReceiptTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(all{assert(s.caught==2 and s.receipt==0),assert(safe),s'=s})
run gcBeforeLandingTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(startGc).then(rewriteRootOnly).then(finishGc).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.slot==2),assert(safe),s'=s})
run gcDuringResumptionTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(borrowFresh).then(resumeCaptured).then(startGc).then(rewriteRegistryFirst).then(rewriteContextSlot).then(finishGc).then(finishResumption).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run partialGcSlotTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(borrowFresh).then(resumeCaptured).then(startGc).then(rewriteRegistryFirst).then(all{assert(s.scanStage==1 and s.contextSlot==1 and s.slot==2),assert(safe),s'=s})
run twoResumptionsTest=init.then(prepareFirst).then(prepareSecond).then(publishEscrow).then(issueTransfer).then(catchInner).then(restoreInnerCatcher).then(catchOuter).then(restoreOuterCatcher).then(borrowFresh).then(validateLanding).then(publishLanding).then(borrowFresh).then(beginInnerRelease).then(decrementInner).then(commitInnerRelease).then(borrowFresh).then(beginOuterRelease).then(decrementOuter).then(commitOuterRelease).then(settleGuards).then(borrowFresh).then(resumeCaptured).then(finishResumption).then(borrowFresh).then(resumeCaptured).then(finishResumption).then(dropCaptured).then(closeRootAdmission).then(retireRoots).then(ackDescriptorGrace).then(retireDescriptor).then(all{assert(s.shotTicket==2 and s.effectsI==1),assert(safe),s'=s})
}
