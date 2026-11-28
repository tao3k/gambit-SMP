// Quint owns schedules and permit/root lifetimes only. Payload slot-map and
// value coherence under an authentic permit belong exclusively to Lean.
// View versions here are revocable ticket revisions, not a value proof.
// Hook takeover is modeled; arbitrary capture/reinstatement inside hooks and
// complete prompt composition semantics remain separate refinement obligations.
module continuation_segments {
  pure def parent(w:int):int=if(w==2)1 else 0
  pure def common(a:int,b:int):int=
    if(a==b)a else if(a.in(Set(1,2)) and b.in(Set(1,2)))1 else 0
  pure def exits(a:int,c:int):List[int]=
    if(a==c)[] else if(a==2 and c==1)[-2] else if(a==2)[-2,-1]
    else if(a==1)[-1] else if(a==3)[-3] else []
  pure def entries(b:int,c:int):List[int]=
    if(b==c)[] else if(b==2 and c==1)[2] else if(b==2)[1,2]
    else if(b==1)[1] else if(b==3)[3] else []
  pure def windOps(a:int,b:int):List[int]=exits(a,common(a,b)).concat(entries(b,common(a,b)))
  pure def afterOp(op:int):int=if(op<0)parent(-op) else op
  type S={captured:bool,materialized:bool,available:bool,imageVersion:int,viewVersion:int,
    loc:int,epoch:int,loaded:int,cache:int,imageRoot:int,denvRoot:int,windRoot:int,
    promptRoot:int,transferRoot:int,activeRoot:int,frozen:bool,borrow:bool,
    oldImage:bool,youngEdge:bool,dirty:bool,
    wind:int,startWind:int,targetWind:int,ops:List[int],cursor:int,hook:int,
    working:bool,transfer:int,hookToken:int,staleHook:bool,trace:List[int],shots:int,
    lastVersion:int,lastImageVersion:int,acceptedDeadOrigin:bool,
    nativeNeeded:bool,nativeLive:bool,prompt:bool,tagMatches:bool,
    delimited:bool,escapeOnly:bool,escaped:bool}
  var s:S
  pure val empty:S={captured:false,materialized:false,available:false,imageVersion:0,viewVersion:0,
    loc:1,epoch:0,loaded:0,cache:1,imageRoot:0,denvRoot:0,windRoot:1,
    promptRoot:0,transferRoot:0,activeRoot:1,frozen:false,borrow:false,
    oldImage:false,youngEdge:false,dirty:false,
    wind:2,startWind:2,targetWind:2,ops:[],cursor:0,hook:0,
    working:false,transfer:0,hookToken:0,staleHook:false,trace:[],shots:0,
    lastVersion:0,lastImageVersion:0,acceptedDeadOrigin:false,
    nativeNeeded:false,nativeLive:true,prompt:false,tagMatches:true,
    delimited:false,escapeOnly:false,escaped:false}
  val reloaded=s.loaded==s.epoch and s.cache==s.loc
  action init={s'=empty}
  action installPrompt=all{not(s.frozen),not(s.prompt),s'={...s,prompt:true,promptRoot:s.loc}}
  action mismatchTag=all{not(s.captured),s'={...s,tagMatches:false}}
  action chooseEscapeOnly=all{not(s.captured),s'={...s,escapeOnly:true}}
  action captureFull=all{not(s.captured),not(s.escaped),not(s.frozen),reloaded,
    s'={...s,captured:true,available:true,imageRoot:s.loc,denvRoot:s.loc}}
  action captureDelimited=all{not(s.captured),not(s.frozen),reloaded,
    s.prompt,s.tagMatches,not(s.escapeOnly),not(s.borrow),
    s'={...s,captured:true,available:true,delimited:true,imageRoot:s.loc,denvRoot:s.loc}}
  action escape=all{s.prompt,s.tagMatches,s.escapeOnly,not(s.captured),not(s.frozen),
    s'={...s,escaped:true}}
  // Publish the still-valid source root before any GC-capable materialization.
  action materialize=all{s.captured,not(s.frozen),not(s.materialized),reloaded,
    s.imageRoot==s.loc,s'={...s,materialized:true}}
  action invalidateView=all{s.captured,not(s.frozen),reloaded,s.imageVersion<3,
    s'={...s,imageVersion:s.imageVersion+1,youngEdge:s.oldImage,dirty:s.oldImage}}
  action beginResume(t:int):bool=all{s.captured,s.available,not(s.working),
    not(s.frozen),not(s.borrow),reloaded,t.in(Set(0,1,2,3)),s.transfer<5,s.shots<3,
    s'={...s,working:true,startWind:s.wind,targetWind:t,ops:windOps(s.wind,t),
      cursor:0,hook:0,transfer:s.transfer+1,
      viewVersion:s.imageVersion,transferRoot:s.loc}}
  action beginHook={val op=s.ops.nth(s.cursor);
    all{s.working,not(s.frozen),reloaded,s.hook==0,s.cursor<s.ops.length(),
      (if(op<0)s.wind== -op else s.wind==parent(op)),
      s'={...s,hook:op,hookToken:s.transfer,wind:parent(if(op<0)-op else op),trace:s.trace.append(op)}}}
  action returnHook(token:int):bool=all{s.working,s.hook!=0,not(s.frozen),reloaded,
    token==s.transfer,token==s.hookToken,
    s'={...s,wind:afterOp(s.hook),cursor:s.cursor+1,hook:0}}
  // Abandoning a hook may initiate another transfer. Scheme still owns the
  // hook continuation; this token only excludes an old native helper return.
  action hookTakeover(t:int):bool=all{s.working,s.hook!=0,not(s.frozen),reloaded,
    t.in(Set(0,1,2,3)),s.transfer<5,
    s'={...s,startWind:s.wind,targetWind:t,ops:windOps(s.wind,t),cursor:0,
      hook:0,transfer:s.transfer+1,viewVersion:s.imageVersion}}
  action reloadView=all{s.working,not(s.frozen),reloaded,
    s'={...s,viewVersion:s.imageVersion}}
  action commitResume=all{s.working,not(s.frozen),not(s.borrow),reloaded,
    s.hook==0,s.cursor==s.ops.length(),s.wind==s.targetWind,
    s.viewVersion==s.imageVersion,not(s.nativeNeeded) or s.nativeLive,
    s'={...s,working:false,transferRoot:0,shots:s.shots+1,
      lastVersion:s.viewVersion,lastImageVersion:s.imageVersion}}
  action refuseStaleTicket=all{s.working,s.viewVersion!=s.imageVersion,s'=s}
  action refuseDeadOrigin=all{s.working,s.nativeNeeded,not(s.nativeLive),s'=s}
  action needNative=all{not(s.working),s'={...s,nativeNeeded:true}}
  action closeNative=all{not(s.borrow),s'={...s,nativeLive:false}}
  action borrowNative=all{not(s.frozen),reloaded,not(s.borrow),s'={...s,borrow:true}}
  action releaseBorrow=all{s.borrow,s'={...s,borrow:false}}
  action freeze=all{not(s.frozen),not(s.borrow),s'={...s,frozen:true}}
  // Relocation stands for completed scanning of all named root domains.
  action relocate=all{s.frozen,s.loc<4,not(s.youngEdge) or s.dirty,
    s'={...s,loc:s.loc+1,epoch:s.epoch+1,activeRoot:s.loc+1,windRoot:s.loc+1,
      imageRoot:if(s.captured)s.loc+1 else 0,denvRoot:if(s.captured)s.loc+1 else 0,
      promptRoot:if(s.prompt)s.loc+1 else 0,transferRoot:if(s.working)s.loc+1 else 0,
      materialized:s.captured,oldImage:s.captured,youngEdge:false,dirty:false}}
  action thaw=all{s.frozen,s'={...s,frozen:false}}
  action reload=all{not(s.frozen),s'={...s,loaded:s.epoch,cache:s.loc}}
  val safe=all{
    s.captured implies all{s.available,s.imageRoot==s.loc,s.denvRoot==s.loc},
    s.prompt implies s.promptRoot==s.loc,
    s.activeRoot==s.loc,s.windRoot==s.loc,
    s.working implies all{s.transferRoot==s.loc,s.viewVersion<=s.imageVersion,
      s.ops==windOps(s.startWind,s.targetWind),s.cursor<=s.ops.length(),
      if(s.hook!=0) all{s.hook==s.ops.nth(s.cursor),s.hookToken==s.transfer,
        s.wind==parent(if(s.hook<0)-s.hook else s.hook)}
      else s.wind==(if(s.cursor==0)s.startWind else afterOp(s.ops.nth(s.cursor-1)))},
    not(s.staleHook),not(s.acceptedDeadOrigin),s.youngEdge implies s.dirty,
    s.borrow implies all{not(s.frozen),reloaded},
    s.lastVersion==s.lastImageVersion,
    s.escaped implies not(s.captured),s.delimited implies all{s.prompt,s.tagMatches,not(s.escapeOnly)}
  }
  action step=any{installPrompt,mismatchTag,chooseEscapeOnly,captureFull,captureDelimited,escape,
    materialize,invalidateView,beginResume(0),beginResume(1),beginResume(2),beginResume(3),
    beginHook,returnHook(s.hookToken),hookTakeover(0),hookTakeover(3),reloadView,commitResume,
    needNative,closeNative,borrowNative,releaseBorrow,freeze,relocate,thaw,reload,
    refuseStaleTicket,refuseDeadOrigin,s'=s}
  action check=all{safe,s'=s}
  action collect=freeze.then(relocate).then(thaw).then(reload)
  action switchToSibling=beginResume(3).then(beginHook).then(returnHook(1))
    .then(beginHook).then(returnHook(1)).then(beginHook).then(returnHook(1))
  run repeatedImageTest=init.then(captureFull).then(beginResume(2)).then(commitResume)
    .then(invalidateView).then(beginResume(2)).then(commitResume).then(check)
  run sameExtentTest=init.then(captureFull).then(beginResume(2)).then(commitResume)
    .then(all{s.trace==[],s'=s}).then(check)
  run orderedWindingTest=init.then(captureFull).then(switchToSibling).then(commitResume)
    .then(all{s.trace==[-2,-1,3],s'=s}).then(check)
  run hookMutationTest=init.then(captureFull).then(beginResume(1)).then(beginHook)
    .then(invalidateView).then(returnHook(1)).then(reloadView).then(commitResume).then(check)
  run hookGcTest=init.then(captureFull).then(beginResume(1)).then(beginHook)
    .then(collect).then(returnHook(1)).then(commitResume).then(check)
  run hookTakeoverTest=init.then(captureFull).then(beginResume(3)).then(beginHook)
    .then(hookTakeover(1)).then(commitResume).then(check)
  run rootedMaterializationTest=init.then(captureFull).then(collect)
    .then(beginResume(2)).then(commitResume).then(check)
  run explicitMaterializationTest=init.then(captureFull).then(materialize).then(check)
  run staleTicketRefusalTest=init.then(captureFull).then(beginResume(1)).then(beginHook)
    .then(invalidateView).then(returnHook(1)).then(refuseStaleTicket).then(reloadView)
    .then(commitResume).then(check)
  run expiredOriginRefusalTest=init.then(captureFull).then(needNative).then(closeNative)
    .then(beginResume(2)).then(refuseDeadOrigin).then(check)
  run promptAdmissionTest=init.then(installPrompt).then(captureDelimited).then(collect)
    .then(beginResume(2)).then(commitResume).then(check)
  run escapeWithoutImageTest=init.then(installPrompt).then(chooseEscapeOnly).then(escape).then(check)
  run borrowBeforeCutTest=init.then(captureFull).then(borrowNative).then(releaseBorrow)
    .then(collect).then(check)
  action badConsume={s'={...empty,captured:true,imageRoot:1,denvRoot:1}}
  action badRootGap={s'={...empty,captured:true,available:true}}
  action badStalePermit={s'={...empty,lastVersion:0,lastImageVersion:1}}
  action badDeadOrigin={s'={...empty,acceptedDeadOrigin:true}}
  action badRememberedEdge={s'={...empty,oldImage:true,youngEdge:true}}
  action badLateHook={s'={...empty,staleHook:true}}
  action badGcBorrow={s'={...empty,borrow:true,frozen:true}}
  action badEscapeImage={s'={...empty,escaped:true,captured:true,available:true,imageRoot:1,denvRoot:1}}
}
