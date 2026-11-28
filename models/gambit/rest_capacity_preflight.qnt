// One call after operand evaluation; four rest args, 14-word caller heap envelope.
// Arena offsets [0,64), stack request 12 is a conservative finite geometry example, NOT a proved caller FrameSpec.
module rest_capacity_preflight {
  type S={phase:int,route:int,view:bool,full:bool,epoch:int,arena:int,rootVersion:int,reload:int,
    ctx:bool,bound:bool,gate:bool,closing:bool,ticket:int,serial:int,te:int,ta:int,
    inputGen:int,planGen:int,tg:int,ce:int,ca:int,cs:int,observed:bool,
    se:int,sa:int,ss:int,saved:bool,hp:int,sp:int,hlo:int,hhi:int,slo:int,shi:int,
    need:int,sneed:int,used:int,pairs:int,packet:bool,held:bool,unknown:bool,
    evals:int,builds:int,body:int,replay:bool,escaped:bool}
  var s:S
  // ticket none0,pending1,unused2,active3,closed4. phase caller0,view1,request2,grant3,partial4,frame5,body6.
  action init=s'={phase:0,route:0,view:false,full:true,epoch:0,arena:0,rootVersion:0,reload:0,
    ctx:true,bound:true,gate:true,closing:false,ticket:0,serial:0,te:-1,ta:-1,
    inputGen:0,planGen:0,tg:-1,ce:-1,ca:-1,cs:-1,observed:false,
    se:-1,sa:-1,ss:-1,saved:false,hp:8,sp:64,hlo:0,hhi:0,slo:0,shi:0,
    need:14,sneed:12,used:0,pairs:0,packet:false,held:false,unknown:false,
    evals:1,builds:0,body:0,replay:false,escaped:false}
  action runningInit=init.then(all{s'={...s,route:2}})
  action directInit=init.then(all{s'={...s,route:1}})
  action prepareView=all{s.phase==0,s.full,s'={...s,phase:1,view:true}}
  action refreshPlan=all{s.phase==1,s.ticket!=1,s.ticket!=2,s.full,s'={...s,planGen:s.inputGen}}
  action request=all{s.phase==1,s.view,s.full,s.gate,not(s.closing),s.ctx,s.bound,s.reload==s.rootVersion,
    s.planGen==s.inputGen,s.serial<2,s'={...s,phase:2,ticket:1,serial:s.serial+1,observed:false,te:s.epoch,ta:s.arena}}
  action deny=all{s.phase==2,s.ticket==1,not(s.unknown),s'={...s,phase:1,ticket:0}}
  action grant=all{s.phase==2,s.ticket==1,not(s.unknown),not(s.closing),s.gate,
    s.hp+s.need<=s.sp-s.sneed,s.hp>=0,s.sp<=64,s.planGen==s.inputGen,
    s'={...s,phase:3,ticket:2,te:s.epoch,ta:s.arena,tg:s.inputGen,
      hlo:s.hp,hhi:s.hp+s.need,slo:s.sp-s.sneed,shi:s.sp,held:true}}
  action observe=all{s.ticket==2,s'={...s,ce:s.te,ca:s.ta,cs:s.serial,observed:true}}
  action loseResponse=all{s.ticket==2,s'={...s,observed:false}}
  action saveClient=all{s.observed,s.ticket==2,not(s.saved),s'={...s,se:s.ce,sa:s.ca,ss:s.cs,saved:true}}
  action lateOldReply=all{s.saved,s.full,s.ticket!=3,s'={...s,ce:s.se,ca:s.sa,cs:s.ss,observed:true}}
  action changeInput=all{s.phase==1 or s.phase==3,s.full,s.inputGen==0,s'={...s,inputGen:1}}
  val fresh=s.te==s.epoch and s.ta==s.arena and s.tg==s.inputGen and s.ce==s.te and s.ca==s.ta and s.cs==s.serial
  val physical=s.hlo>=0 and s.hhi-s.hlo>=s.need and s.shi-s.slo>=s.sneed and s.shi<=64 and s.hhi<=s.slo
  action enter=all{s.phase==3,s.ticket==2,s.observed,fresh,physical,s.hp==s.hlo,s.sp==s.shi,
    s.gate,not(s.closing),s.ctx,s.bound,s.reload==s.rootVersion,
    s'={...s,phase:4,ticket:3,full:false,builds:s.builds+1}}
  action cons=all{s.phase==4,s.ticket==3,s.pairs<4,s.used+3<=s.need,
    s'={...s,pairs:s.pairs+1,used:s.used+3,hp:s.hp+3}}
  action pack=all{s.phase==4,s.ticket==3,s.pairs==4,not(s.packet),s.used+2<=s.need,
    s'={...s,packet:true,used:s.used+2,hp:s.hp+2}}
  action makeFrame=all{s.phase==4,s.packet,s'={...s,phase:5,full:true}}
  action closeLease=all{s.phase==5,s.ticket==3,s'={...s,ticket:4,held:false}}
  action closeRound=all{s.phase<6,not(s.closing),s'={...s,gate:false,closing:true}}
  // Cancellation and enter share one canonical arbitration; only UNUSED can cancel.
  action cancelUnused=all{s.ticket==2,s.full,s'={...s,ticket:4,held:false,phase:1}}
  action cancelPending=all{s.ticket==1,s.closing,not(s.unknown),s'={...s,ticket:0,phase:1}}
  action nativeUnknown=all{s.ticket==1,s'={...s,unknown:true}}
  // External known-failure evidence is a premise; no timeout action clears unknown.
  action reconcileDeny=all{s.ticket==1,s.unknown,s'={...s,unknown:false,ticket:0,phase:1}}
  action collect=all{s.epoch==0,s.closing,s.full,s.view,not(s.held),s.ticket!=1,s.ticket!=3,not(s.unknown),
    s'={...s,epoch:1,arena:1,rootVersion:1,hp:8,sp:64,ctx:false,bound:false}}
  action reassignLayout=all{s.epoch==0,s.arena==0,s.closing,s.phase==1,not(s.held),s.ticket!=1,not(s.unknown),
    s'={...s,arena:1,hp:8,sp:64,ctx:false,bound:false}}
  action prepareContext=all{s.closing,s.full,not(s.held),s.ticket!=1,s'={...s,ctx:true}}
  action bindOwner=all{s.ctx,s.full,s'={...s,bound:true}}
  action reloadRoots=all{s.ctx,s.bound,s.full,s'={...s,reload:s.rootVersion}}
  action reopen=all{s.closing,s.ctx,s.bound,s.reload==s.rootVersion,s.full,not(s.unknown),
    s'={...s,gate:true,closing:false}}
  action resumeBody=all{s.phase==5,s.ticket==4,s.full,s.gate,s.ctx,s.bound,s.reload==s.rootVersion,
    s'={...s,phase:6,body:1}}
  action query=s'=s
  action idle=s'=s
  val admitted=all{
    s.evals==1,s.builds<=1,s.body<=1,not(s.replay),not(s.escaped),
    s.phase!=0 or s.full,s.phase==0 or s.view,
    s.ticket!=1 or (s.full and s.view and s.te==s.epoch and s.ta==s.arena),
    s.ticket!=2 or (s.full and s.held and physical and s.te==s.epoch and s.ta==s.arena and s.hp==s.hlo and s.sp==s.shi),
    s.ticket!=3 or (fresh and physical and s.held and s.hp==s.hlo+s.used and s.used<=s.need),
    s.full or (s.phase==4 and s.ticket==3),
    s.phase!=4 or (s.ticket==3 and s.used==3*s.pairs+(if(s.packet) 2 else 0)),
    s.body==0 or (s.full and s.packet and s.builds==1 and s.ctx and s.bound and s.reload==s.rootVersion),
    s.ticket!=4 or not(s.held)}
  action step=any{prepareView,refreshPlan,request,deny,grant,observe,loseResponse,saveClient,lateOldReply,
    changeInput,enter,cons,pack,makeFrame,closeLease,closeRound,cancelUnused,cancelPending,nativeUnknown,
    reconcileDeny,collect,reassignLayout,prepareContext,bindOwner,reloadRoots,reopen,resumeBody,query,idle}
  action viewReady=init.then(prepareView)
  action pending=viewReady.then(request)
  action leased=pending.then(grant).then(observe)
  action canceled=leased.then(saveClient).then(closeRound).then(cancelUnused)
  action reset=canceled.then(collect).then(prepareContext).then(bindOwner).then(reloadRoots).then(reopen)
  action reissued=reset.then(request).then(grant).then(observe)
  action partial=leased.then(enter)
  action completed=partial.then(cons).then(cons).then(cons).then(cons).then(pack).then(makeFrame).then(closeLease)
  action badEnter=s'={...s,phase:4,ticket:3,full:false,held:true,builds:s.builds+1}
  action badCollect=s'={...s,epoch:1,arena:1,rootVersion:1,hp:8,sp:64,ctx:false,bound:false}
  action badDrop=s'={...s,view:false}
  action badReevaluate=s'={...s,evals:s.evals+1}
  action badConsumeAgain=s'={...s,builds:s.builds+1}
  action badHole=s'={...s,hp:s.hhi}
  action badOverlap=s'={...s,hhi:s.slo+1}
  action badShort=s'={...s,hhi:s.hlo+13}
  action badRefund=s'={...s,ticket:4,held:false}
  action badCursor=s'={...s,hp:s.hp+1}
  action badOwner=s'={...s,escaped:true}
  action badResume=s'={...s,phase:6,body:1}
  action badForgetUnknown=s'={...s,unknown:false,ticket:0,phase:1,replay:true}
  run failedPreflightKeepsFullRootsTest=pending.then(deny).then(all{assert(s.full and s.view and s.hp==8 and s.evals==1 and admitted),s'=s})
  run failureThenGcRetryTest=pending.then(deny).then(closeRound).then(collect).then(prepareContext).then(bindOwner).then(reloadRoots).then(reopen).then(request).then(grant).then(observe).then(enter).then(all{assert(admitted),s'=s})
  run unusedTicketCanceledBeforeGcTest=canceled.then(collect).then(all{assert(not(s.held) and s.full and admitted),s'=s})
  run reissueSameCallTest=reissued.then(enter).then(all{assert(s.serial==2 and s.evals==1 and s.builds==1 and admitted),s'=s})
  run grantDoesNotAdvanceHpTest=leased.then(all{assert(s.hp==8 and s.hhi==22 and admitted),s'=s})
  run cursorMovesOnlyInitializedWordsTest=partial.then(cons).then(all{assert(s.hp==11 and s.used==3 and admitted),s'=s})
  run alreadyStartedDrainsBeforeGcTest=partial.then(closeRound).then(cons).then(cons).then(cons).then(cons).then(pack).then(makeFrame).then(closeLease).then(collect).then(all{assert(admitted),s'=s})
  run completedPacketNeedsNoNewRepairTicketTest=completed.then(closeRound).then(collect).then(prepareContext).then(bindOwner).then(reloadRoots).then(reopen).then(resumeBody).then(all{assert(s.serial==1 and s.builds==1 and admitted),s'=s})
  run nativeIngressProfileTest=runningInit.then(prepareView).then(request).then(deny).then(all{assert(s.route==2 and s.full and admitted),s'=s})
  run directCallerProfileTest=directInit.then(prepareView).then(request).then(grant).then(observe).then(enter).then(all{assert(s.route==1 and admitted),s'=s})
  run missingAckRetainsCanonicalLeaseTest=pending.then(grant).then(loseResponse).then(query).then(all{assert(s.ticket==2 and s.held and s.full and admitted),s'=s})
  run closeWinsAgainstLateAckTest=pending.then(grant).then(closeRound).then(cancelUnused).then(query).then(all{assert(s.ticket==4 and s.full and admitted),s'=s})
  run inputMutationForcesCancelAndReplanTest=leased.then(changeInput).then(cancelUnused).then(refreshPlan).then(request).then(grant).then(observe).then(enter).then(all{assert(s.tg==1 and admitted),s'=s})
  run unknownAllocatorResultRetainsRootsTest=pending.then(nativeUnknown).then(closeRound).then(query).then(all{assert(s.full and s.view and s.unknown and s.ticket==1 and admitted),s'=s})
  run knownDenyAfterUnknownTest=pending.then(nativeUnknown).then(closeRound).then(reconcileDeny).then(collect).then(all{assert(admitted),s'=s})
  run sameEpochLayoutReissueTest=canceled.then(reassignLayout).then(prepareContext).then(bindOwner).then(reloadRoots).then(reopen).then(request).then(grant).then(observe).then(enter).then(all{assert(s.epoch==0 and s.ta==1 and admitted),s'=s})
  run partialFrameGcCounterexampleTest=partial.then(cons).then(closeRound).then(badCollect).then(all{assert(not(admitted)),s'=s})
  run unusedGrantCannotSurviveGcCounterexampleTest=leased.then(closeRound).then(badCollect).then(all{assert(not(admitted)),s'=s})
  run staleEpochClientCounterexampleTest=reissued.then(lateOldReply).then(badEnter).then(all{assert(not(admitted)),s'=s})
  run staleLayoutSameEpochCounterexampleTest=canceled.then(reassignLayout).then(prepareContext).then(bindOwner).then(reloadRoots).then(reopen).then(request).then(grant).then(observe).then(lateOldReply).then(badEnter).then(all{assert(not(admitted)),s'=s})
  run addressReuseDoesNotAuthorizeOldSerialCounterexampleTest=reissued.then(lateOldReply).then(badEnter).then(all{assert(s.hlo==8 and not(admitted)),s'=s})
  run inputVersionMismatchCounterexampleTest=leased.then(changeInput).then(badEnter).then(all{assert(not(admitted)),s'=s})
  run logicalFreeCannotProveDisjointCounterexampleTest=leased.then(badOverlap).then(all{assert(not(admitted)),s'=s})
  run shortHeapIntervalCounterexampleTest=leased.then(badShort).then(all{assert(not(admitted)),s'=s})
  run reserveMustNotPublishHoleCounterexampleTest=partial.then(badHole).then(all{assert(not(admitted)),s'=s})
  run interveningAllocationCounterexampleTest=partial.then(badCursor).then(all{assert(not(admitted)),s'=s})
  run missingInputRootsCounterexampleTest=pending.then(deny).then(badDrop).then(all{assert(not(admitted)),s'=s})
  run retryMustNotReevaluateArgumentsCounterexampleTest=reset.then(badReevaluate).then(all{assert(not(admitted)),s'=s})
  run consumedTicketNoSecondConstructionCounterexampleTest=completed.then(badConsumeAgain).then(all{assert(not(admitted)),s'=s})
  run cancelCannotEraseActiveWriterCounterexampleTest=partial.then(badRefund).then(all{assert(not(admitted)),s'=s})
  run wrongOwnerCannotConsumeCounterexampleTest=leased.then(badOwner).then(all{assert(not(admitted)),s'=s})
  run unknownIsNotTimeoutDenyCounterexampleTest=pending.then(nativeUnknown).then(badForgetUnknown).then(all{assert(not(admitted)),s'=s})
  run gcNotificationCannotResumeCounterexampleTest=completed.then(closeRound).then(collect).then(badResume).then(all{assert(not(admitted)),s'=s})
  action negativeInit=partial.then(cons).then(closeRound)
  action negativeStep=badCollect
}
