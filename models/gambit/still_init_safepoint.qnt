module still_init_safepoint {
  // Two root activations and one initializer. Values11/99 are identity tags,
  // not native addresses. Unknown storage charged by an abstract block8.
  type State={phase:int,owned:bool,prefix:int,complete:bool,published:bool,
    req:int,ack:int,executing:bool,participating:bool,irq:bool,delivered:bool,
    outerRoot:bool,innerRoot:bool,outerValue:int,depth:int,
    unknown:bool,held:int,pin:bool,aborted:bool}
  var s:State
  action init=s'={phase:0,owned:false,prefix:0,complete:false,published:false,
    req:0,ack:0,executing:false,participating:false,irq:false,delivered:false,
    outerRoot:true,innerRoot:false,outerValue:11,depth:0,
    unknown:false,held:0,pin:true,aborted:false}
  val safe=s.prefix>=0 and s.prefix<=3 and s.ack<=s.req and
    (not(s.participating) or (s.outerRoot and (not(s.owned) or (s.complete and s.published)))) and
    (not(s.executing) or (s.participating and s.ack==s.req and s.outerRoot and
      (not(s.owned) or (s.complete and s.published)) and not(s.unknown))) and
    (not(s.owned) or s.outerRoot) and (s.published implies s.complete) and
    (s.depth==0 or (s.innerRoot and s.outerRoot)) and s.outerValue==11 and
    (not(s.delivered) or (not(s.owned) or (s.complete and s.published))) and
    (not(s.unknown) or (s.held==8 and s.pin and not(s.executing))) and
    (not(s.aborted) or (not(s.owned) and s.held==0))
  action request=all{s.req<2,not(s.executing),s'={...s,req:s.req+1}}
  action requestInterrupt=s'={...s,irq:true}
  action own=all{s.phase==0,not(s.participating),s.depth==0,
    s'={...s,phase:1,owned:true,held:8,delivered:false}}
  action initializeOne=all{s.phase==1,s.prefix<3,not(s.participating),
    s'={...s,prefix:s.prefix+1,complete:s.prefix+1==3}}
  action publish=all{s.phase==1,s.complete,not(s.unknown),not(s.participating),
    s'={...s,phase:2,published:true}}
  action acknowledge=all{s.req>s.ack,s.outerRoot,not(s.unknown),
    not(s.owned) or (s.complete and s.published),s'={...s,ack:s.req,participating:true}}
  action executeGc=all{s.req>0,s.ack==s.req,s.outerRoot,s.participating,
    not(s.owned) or (s.complete and s.published),not(s.unknown),s'={...s,executing:true}}
  action finishGc=all{s.executing,s'={...s,executing:false,participating:false}}
  action deliver=all{s.irq,not(s.participating),not(s.unknown),not(s.owned) or (s.complete and s.published),
    s'={...s,delivered:true,irq:false}}
  action callbackEnter=all{s.depth==0,not(s.participating),not(s.unknown),
    not(s.owned) or (s.complete and s.published),s'={...s,depth:1,innerRoot:true}}
  action callbackExit=all{s.depth==1,not(s.participating),s'={...s,depth:0,innerRoot:false}}
  action unknownResult=all{s.phase==0,not(s.participating),
    s'={...s,phase:3,unknown:true,held:8,pin:true}}
  action resolveSameOperation=all{s.phase==3,s.unknown,not(s.participating),
    s'={...s,phase:1,unknown:false,owned:true,delivered:false}}
  action privateAbortBeforeLink=all{s.phase==0,not(s.owned),not(s.unknown),not(s.participating),
    s'={...s,phase:4,aborted:true}}
  action stutter=s'=s
  action step=any{request,requestInterrupt,own,initializeOne,publish,acknowledge,
    executeGc,finishGc,deliver,callbackEnter,callbackExit,unknownResult,
    resolveSameOperation,privateAbortBeforeLink,stutter}
  action finishInit=initializeOne.then(initializeOne).then(initializeOne).then(publish)
  run requestBeforeAllocateTest=init.then(request).then(acknowledge).then(executeGc).then(finishGc).then(own).then(finishInit).expect(safe)
  run requestDuringInitTest=init.then(own).then(initializeOne).then(request).then(initializeOne).expect(safe and s.ack==0)
  run completeThenAckTest=init.then(own).then(request).then(finishInit).then(acknowledge).then(executeGc).expect(safe)
  run interruptDeferredTest=init.then(own).then(requestInterrupt).then(initializeOne).expect(safe and s.irq and not(s.delivered))
  run interruptAfterInitTest=init.then(own).then(requestInterrupt).then(finishInit).then(deliver).expect(safe and s.delivered)
  run nestedPreallocationRootsTest=init.then(callbackEnter).then(request).then(acknowledge).then(executeGc).then(finishGc).then(callbackExit).expect(safe and s.outerRoot and s.outerValue==11)
  run nestedAfterInitializationTest=init.then(own).then(finishInit).then(callbackEnter).then(callbackExit).expect(safe and s.outerRoot)
  run unknownFullCustodyTest=init.then(unknownResult).then(request).expect(safe and s.held==8 and s.pin)
  run sameOperationResolveTest=init.then(unknownResult).then(resolveSameOperation).then(finishInit).expect(safe and s.published)
  run beforeLinkAbortTest=init.then(privateAbortBeforeLink).expect(safe and s.aborted)
  run newRequestAfterAckTest=init.then(request).then(acknowledge).then(request).expect(safe and s.ack<s.req)
  run uninitializedParticipationControlTest=init.then(own).then(request).then(s'={...s,ack:s.req,executing:true}).expect(not(safe))
  run mutatorAfterAckControlTest=init.then(request).then(acknowledge).then(s'={...s,phase:1,owned:true,held:8}).expect(not(safe))
  run lostOuterRootControlTest=init.then(own).then(s'={...s,outerRoot:false}).expect(not(safe))
  run sharedScratchClobberControlTest=init.then(callbackEnter).then(s'={...s,outerValue:99}).expect(not(safe))
  run innerExitClearsParentControlTest=init.then(callbackEnter).then(callbackExit).then(s'={...s,outerRoot:false,owned:true}).expect(not(safe))
  run staleAckControlTest=init.then(request).then(acknowledge).then(request).then(s'={...s,executing:true}).expect(not(safe))
  run earlyCallbackControlTest=init.then(own).then(s'={...s,delivered:true}).expect(not(safe))
  run unknownRefundControlTest=init.then(unknownResult).then(s'={...s,held:0,pin:false}).expect(not(safe))
  run abortLinkedUninitializedControlTest=init.then(own).then(s'={...s,aborted:true,held:0}).expect(not(safe))
  run filledButUnrootedControlTest=init.then(own).then(initializeOne).then(initializeOne).then(initializeOne).then(request).then(s'={...s,ack:s.req,participating:true,executing:true}).expect(not(safe))
}
