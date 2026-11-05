module nested_domain_root_retirement {
// Bounded product: two accepted domains, one admitted source, one GC reader, two resumptions.
type State={source:int,target:int,ack:int,pubReply:int,outerGuard:int,innerGuard:int,outerRight:int,innerRight:int,unwind:int,landed:int,captured:int,gcReader:int,descriptor:int,rootClosed:int,rootGrace:int,rootRetired:int,codeClosed:int,codeGrace:int,detached:int,outcome:int,shotGuard:int,shotTicket:int}
pure val initial:State={source:1,target:0,ack:0,pubReply:0,outerGuard:0,innerGuard:0,outerRight:0,innerRight:0,unwind:0,landed:0,captured:0,gcReader:0,descriptor:1,rootClosed:0,rootGrace:0,rootRetired:0,codeClosed:0,codeGrace:0,detached:0,outcome:0,shotGuard:0,shotTicket:0}
var s:State
action init=s'=initial
val safe=all{s.source>=0,
s.target>=0,
s.ack>=0,
s.pubReply>=0,
s.outerGuard>=0,
s.innerGuard>=0,
s.outerRight>=0,
s.innerRight>=0,
s.unwind>=0,
s.landed>=0,
s.captured>=0,
s.gcReader>=0,
s.descriptor>=0,
s.rootClosed>=0,
s.rootGrace>=0,
s.rootRetired>=0,
s.codeClosed>=0,
s.codeGrace>=0,
s.detached>=0,
s.outcome>=0,
s.shotGuard>=0,
s.shotTicket>=0,
s.source<=1,
s.target<=1,
s.ack<=1,
s.pubReply<=1,
s.outerGuard<=3,
s.innerGuard<=3,
s.outerRight<=1,
s.innerRight<=1,
s.unwind<=3,
s.landed<=1,
s.captured<=1,
s.gcReader<=1,
s.descriptor<=1,
s.rootClosed<=1,
s.rootGrace<=1,
s.rootRetired<=1,
s.codeClosed<=1,
s.codeGrace<=1,
s.detached<=1,
s.outcome<=1,
s.shotGuard<=1,
s.shotTicket<=2,
(s.source==1 or s.target==1 or s.rootRetired==1),
(s.pubReply==1) implies (s.source==1 and s.ack==0 and s.outerGuard==0),
(s.ack==1) implies (s.target==1 or s.rootRetired==1),
(s.outerGuard>0) implies (s.ack==1 and s.source==0),
(s.innerGuard>0) implies (s.outerGuard>0),
(s.outerGuard==1 or s.outerGuard==2 or s.innerGuard==1 or s.innerGuard==2 or s.shotGuard==1) implies (s.target==1 and s.descriptor==1 and s.rootRetired==0),
(s.outerRight==1) implies (s.outerGuard==1 and s.unwind==0 and s.landed==0),
(s.innerRight==1) implies (s.innerGuard==1 and s.outerRight==1),
(s.outerGuard==1) implies (s.outerRight==1 and s.unwind==0),
(s.innerGuard==1) implies (s.innerRight==1 and s.outerGuard==1),
(s.outerGuard==2 or s.innerGuard==2) implies (s.unwind>=1),
(s.unwind>=1) implies (s.outerRight==0 and s.innerRight==0 and s.outerGuard>=2 and s.innerGuard>=2),
(s.unwind==1 or s.unwind==2) implies (s.outerGuard==2 and s.innerGuard==2 and s.landed==0 and s.captured==1),
(s.landed==1) implies (s.unwind==3 and s.outcome==0),
(s.unwind==3) implies (s.landed==1),
(s.innerGuard==3) implies (s.landed==1),
(s.outerGuard==3) implies (s.innerGuard==3),
(s.outcome==1) implies (s.unwind==2 and s.landed==0 and s.outerGuard==2 and s.innerGuard==2),
(s.captured==1) implies (s.target==1 and s.descriptor==1 and s.rootClosed==0),
(s.gcReader==1) implies (s.target==1 and s.descriptor==1 and s.rootGrace==0 and s.codeGrace==0),
(s.rootClosed==1) implies (s.source==0 and s.ack==1 and s.landed==1 and s.outerGuard==3 and s.innerGuard==3 and s.captured==0 and s.shotGuard==0),
(s.rootGrace==1) implies (s.rootClosed==1 and s.gcReader==0),
(s.codeClosed==1) implies (s.rootClosed==1),
(s.codeGrace==1) implies (s.codeClosed==1 and s.gcReader==0),
(s.rootRetired==1) implies (s.target==0 and s.source==0 and s.rootClosed==1 and s.rootGrace==1 and s.gcReader==0),
(s.descriptor==0) implies (s.rootRetired==1 and s.codeClosed==1 and s.codeGrace==1 and s.gcReader==0),
(s.detached==1) implies (s.descriptor==0 and s.rootRetired==1 and s.landed==1),
(s.shotGuard==1) implies (s.landed==1 and s.outerGuard==3 and s.innerGuard==3 and s.captured==1 and s.shotTicket>=1),
(s.shotTicket>0) implies (s.landed==1 and s.outerGuard==3 and s.innerGuard==3)}
action publishRoots=all{s.source==1 and s.target==0 and s.pubReply==0,s'={...s,target:1}}
action publicationReplyLost=all{s.source==1 and s.target==0 and s.pubReply==0,s'={...s,target:1,pubReply:1}}
action publicationAbsentUnknown=all{s.source==1 and s.target==0 and s.pubReply==0,s'={...s,pubReply:1}}
action resolvePublication=all{s.pubReply==1,s'={...s,pubReply:0}}
action acknowledgeRoots=all{s.target==1 and s.pubReply==0 and s.ack==0,s'={...s,ack:1}}
action releaseSource=all{s.source==1 and s.target==1 and s.ack==1 and s.pubReply==0,s'={...s,source:0}}
action enterOuter=all{s.outerGuard==0 and s.source==0 and s.target==1 and s.ack==1 and s.rootClosed==0 and s.codeClosed==0,s'={...s,outerGuard:1,outerRight:1}}
action enterInner=all{s.outerGuard==1 and s.outerRight==1 and s.innerGuard==0 and s.rootClosed==0 and s.codeClosed==0,s'={...s,innerGuard:1,innerRight:1}}
action captureInner=all{s.innerGuard==1 and s.captured==0,s'={...s,captured:1}}
action startGcReader=all{s.target==1 and s.descriptor==1 and s.rootClosed==0 and s.codeClosed==0 and s.gcReader==0,s'={...s,gcReader:1}}
action finishGcReader=all{s.gcReader==1,s'={...s,gcReader:0}}
action escrowOuterUnwind=all{s.outerGuard==1 and s.innerGuard==1 and s.captured==1 and s.unwind==0,s'={...s,outerGuard:2,innerGuard:2,outerRight:0,innerRight:0,unwind:1}}
action issueOuterUnwind=all{s.unwind==1,s'={...s,unwind:2}}
action landingObserved=all{s.unwind==2 and s.outcome==0,s'={...s,unwind:3,landed:1}}
action landingReplyLost=all{s.unwind==2 and s.outcome==0,s'={...s,outcome:1}}
action reconcileLanding=all{s.unwind==2 and s.outcome==1,s'={...s,unwind:3,landed:1,outcome:0}}
action settleInnerGuard=all{s.unwind==3 and s.innerGuard==2,s'={...s,innerGuard:3}}
action settleOuterGuard=all{s.unwind==3 and s.innerGuard==3 and s.outerGuard==2,s'={...s,outerGuard:3}}
action resumeCaptured=all{s.captured==1 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0 and s.shotTicket<2 and s.rootClosed==0 and s.codeClosed==0,s'={...s,shotGuard:1,shotTicket:s.shotTicket+1}}
action rejectInnerReturn=all{s.shotGuard==1 and s.innerRight==0,s'={...s}}
action finishResumption=all{s.shotGuard==1,s'={...s,shotGuard:0}}
action closeCapturedHolders=all{s.captured==1 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0,s'={...s,captured:0}}
action closeRootAdmission=all{s.captured==0 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0 and s.rootClosed==0,s'={...s,rootClosed:1}}
action closeCodeAdmission=all{s.rootClosed==1 and s.codeClosed==0,s'={...s,codeClosed:1}}
action ackRootGrace=all{s.rootClosed==1 and s.gcReader==0 and s.rootGrace==0,s'={...s,rootGrace:1}}
action retireRootSlots=all{s.rootClosed==1 and s.rootGrace==1 and s.gcReader==0 and s.target==1,s'={...s,target:0,rootRetired:1}}
action ackCodeGrace=all{s.codeClosed==1 and s.gcReader==0 and s.codeGrace==0,s'={...s,codeGrace:1}}
action retireDescriptor=all{s.rootRetired==1 and s.codeClosed==1 and s.codeGrace==1 and s.gcReader==0 and s.descriptor==1,s'={...s,descriptor:0}}
action detachNativeOwner=all{s.rootRetired==1 and s.descriptor==0 and s.gcReader==0 and s.detached==0,s'={...s,detached:1}}
action step=any{publishRoots,publicationReplyLost,publicationAbsentUnknown,resolvePublication,acknowledgeRoots,releaseSource,enterOuter,enterInner,captureInner,startGcReader,finishGcReader,escrowOuterUnwind,issueOuterUnwind,landingObserved,landingReplyLost,reconcileLanding,settleInnerGuard,settleOuterGuard,resumeCaptured,rejectInnerReturn,finishResumption,closeCapturedHolders,closeRootAdmission,closeCodeAdmission,ackRootGrace,retireRootSlots,ackCodeGrace,retireDescriptor,detachNativeOwner,all{s'=s}}
run normalRetirementTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.detached==1),assert(safe),s'=s})
run gcOverUnwindTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(startGcReader).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(finishGcReader).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.descriptor==0),assert(safe),s'=s})
run unknownLandingTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingReplyLost).then(startGcReader).then(all{assert(s.outcome==1 and s.innerGuard==2 and s.descriptor==1),assert(safe),s'=s})
run unknownReconciledTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingReplyLost).then(reconcileLanding).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.detached==1),assert(safe),s'=s})
run twoRestorationsTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(resumeCaptured).then(rejectInnerReturn).then(finishResumption).then(resumeCaptured).then(rejectInnerReturn).then(finishResumption).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.shotTicket==2 and s.innerRight==0),assert(safe),s'=s})
run publicationUnknownGcTest=init.then(publicationReplyLost).then(startGcReader).then(resolvePublication).then(acknowledgeRoots).then(releaseSource).then(finishGcReader).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.detached==1),assert(safe),s'=s})
run publicationAbsentRetryTest=init.then(publicationAbsentUnknown).then(resolvePublication).then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackRootGrace).then(retireRootSlots).then(ackCodeGrace).then(retireDescriptor).then(detachNativeOwner).then(all{assert(s.detached==1),assert(safe),s'=s})
run capturedKeepsDescriptorTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(startGcReader).then(finishGcReader).then(all{assert(s.captured==1 and s.descriptor==1 and s.target==1),assert(safe),s'=s})
run codeGraceBeforeRootRetireTest=init.then(publishRoots).then(acknowledgeRoots).then(releaseSource).then(enterOuter).then(enterInner).then(captureInner).then(escrowOuterUnwind).then(issueOuterUnwind).then(landingObserved).then(settleInnerGuard).then(settleOuterGuard).then(closeCapturedHolders).then(closeRootAdmission).then(closeCodeAdmission).then(ackCodeGrace).then(ackRootGrace).then(retireRootSlots).then(retireDescriptor).then(all{assert(s.descriptor==0),assert(safe),s'=s})
}
