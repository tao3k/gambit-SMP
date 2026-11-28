// Proposed safety envelope. No C refinement, callback termination or native admission claim.
module delivery_shrink_release {
  type State={mode:int,bug:int,gate:int,n:int,target:int,pending:bool,
    refs:int,count:int,req:int,qdom:int,hint:int,hroot:bool,hdest:bool,
    callerLive:bool,senderLive:bool,executorLive:bool,linked:bool,partial:bool,
    owner:int,observed:int,cleanup:bool,abandoned:bool,
    badAbandon:bool,checked:bool,allowed:bool,common:bool,refused:bool,
    returned:bool,committed:bool,released:bool,lateAccess:bool,gcBad:bool,
    done:bool}
  var s:State
  // req:0 none,1 queued,2 active,3 prepared,4 transferred,5 consumed,6 abandoned.
  // hint:0 none,1 publisher frame,2 donor queue,3 receiver queue,4 dispatch frame,5 done.
  // owner:0 no owner,1 target,2 sender. qdom:0 survivor,1 donor.
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,gate:0,n:2,
    target:2,pending:false,refs:if(mode==4) 0 else if(Set(2,3,7).contains(mode)) 1 else 2,
    count:if(mode==4) 0 else if(Set(2,3,7).contains(mode)) 1 else 2,
    req:if(mode==4) 0 else if(Set(2,7).contains(mode)) 2 else if(mode==3) 4 else 1,
    qdom:if(mode==5) 0 else 1,
    hint:if(mode==4 or Set(2,3,7).contains(mode)) 0 else if(mode==0) 1 else 2,
    hroot:true,hdest:false,callerLive:mode==0,senderLive:mode!=4,
    executorLive:Set(2,3,7,8).contains(mode),linked:mode!=4,partial:false,
    owner:if(mode==4) 0 else if(mode==3) 2 else 1,
    observed:0,cleanup:false,abandoned:false,badAbandon:false,
    checked:false,allowed:false,common:false,refused:false,returned:false,
    committed:false,released:false,lateAccess:false,gcBad:false,done:false}
  action initPendingPub=s'=initial(0,0)
  action initQueued=s'=initial(1,0)
  action initActive=s'=initial(2,0)
  action initPostTransfer=s'=initial(3,0)
  action initEmpty=s'=initial(4,0)
  action initHandoff=s'=initial(5,0)
  action initUnsafeHandoff=s'=initial(6,0)
  action initBlocked=s'=initial(7,0)
  action initPartial=s'={...initial(8,0),req:2,hint:0,refs:1,count:1}
  action initOwnerOnly=s'={...initial(8,11),req:2,hint:0,refs:1,count:1}
  action initReleaseBeforeSender=s'=initial(3,12)
  action initUnregistered=s'={...initial(0,1),count:0}
  action initOpenCheck=s'=initial(4,2)
  action initLocalReject=s'=initial(1,3)
  action initLateMutation=s'=initial(1,4)
  action initDropRoot=s'=initial(5,5)
  action initRawCarrier=s'=initial(5,6)
  action initBlindAbandon=s'=initial(3,7)
  action initStaleOwner=s'=initial(2,8)
  action initEarlyDrop=s'=initial(2,9)
  action initLateAccess=s'=initial(3,10)

  val hintNeedsRoot=Set(1,2,3,4).contains(s.hint)
  val hintCovered=not(hintNeedsRoot) or (s.hroot and (s.hint==3 or s.n==2))
  val reqCovered=not(Set(1,2,3).contains(s.req) or s.senderLive or s.executorLive) or (s.qdom==0 or s.n==2)
  val donorDebt=(Set(1,2,3,4).contains(s.hint) and s.hint!=3) or
    ((Set(1,2,3).contains(s.req) or s.senderLive or s.executorLive) and s.qdom==1) or s.callerLive
  val safe=all {hintCovered,reqCovered,not(s.gcBad),not(s.badAbandon),
    not(s.lateAccess),not(s.n==1 and donorDebt),
    not(s.refused and s.returned) or (s.n==2 and s.target==2 and not(s.pending))}
  action freeze=all {not(s.checked),s.gate==0,not(s.done),
    s'={...s,gate:if(s.bug==2) 0 else 1,checked:true,
      target:if(s.bug==4) 1 else s.target,
      allowed:s.count==0 or (s.mode==5 and s.bug!=1)}}
  // A deliberately modeled allowed new publisher after a non-atomic open check.
  action latePublish=all {s.bug==2,s.checked,s.gate==0,s.refs==0,
    s'={...s,refs:2,count:2,req:1,hint:1,hroot:true,callerLive:true}}
  action commonResult=all {s.checked,not(s.common),
    not(s.bug==2) or s.refs>0,
    s'={...s,common:true,refused:not(s.allowed)}}
  action reject=all {s.common,s.refused,not(s.returned),
    s'={...s,gate:0,returned:true,done:true,
      n:if(s.bug==3) 1 else s.n}}
  // Only queued hint for a surviving logical target; no active donor frame/lock.
  action installReceiverRoot=all {s.mode==5,s.common,s.allowed,s.hint==2,not(s.hdest),
    s'={...s,hdest:true}}
  action handoff=all {s.mode==5,s.common,s.allowed,s.hdest,s.hint==2,
    s'={...s,hint:3,hroot:if(Set(5,6).contains(s.bug)) false else true}}
  action recoverBadHandoff=all {s.mode==5,s.hint==3,not(s.hroot),
    s'={...s,hroot:true}}
  action gc=all {
    s'={...s,gcBad:s.gcBad or not(hintCovered and reqCovered)}}
  action commit=all {s.common,s.allowed,not(s.committed),
    not(s.bug==2) or s.refs>0,
    (s.mode!=5 or s.hint==3),
    s'={...s,n:1,target:1,pending:true,committed:true,gate:0,done:true}}

  // Release tests are independent of shrink preflight; owner transfer can occur
  // before cleanup resumes. Correct cleanup checks current owner, not a snapshot.
  action prepareResult=all {Set(2,3).contains(s.mode),s.req==2,
    s'={...s,req:3}}
  action snapshotOwner=all {s.bug==8,s.owner==1,s.observed==0,
    s'={...s,observed:1}}
  action physicalUnlock=all {Set(2,3).contains(s.mode),Set(2,3).contains(s.req),
    s'={...s,owner:2,req:4,linked:true}}
  action consumeSender=all {Set(2,3).contains(s.mode),s.owner==2,s.req==4,
    s'={...s,owner:0,req:5,senderLive:false,linked:false}}
  action observeAbandon=all {s.req==6,s.senderLive,
    s'={...s,senderLive:false}}
  action partialUnlink=all {s.mode==8,s.req==2,s.owner==1,
    s'={...s,req:3,linked:false,partial:true}}
  action prematureDrop=all {s.bug==9,s.req==2,s.refs==1,
    s'={...s,refs:0,count:0,req:2}}
  action cleanup=all {Set(2,3,8).contains(s.mode),not(s.cleanup),
    s.mode!=8 or s.partial,
    not(s.bug==8) or (s.observed==1 and s.owner==2),
    s'={...s,cleanup:true,
      abandoned:(s.owner==1 and s.linked) or s.bug==7 or s.bug==11 or (s.bug==8 and s.observed==1),
      badAbandon:(s.owner!=1 and (s.bug==7 or s.bug==8)) or (s.owner==1 and not(s.linked) and s.bug==11),
      req:if(s.owner==1 and s.linked) 6 else s.req,
      executorLive:if(s.partial) true else false,
      linked:if(s.owner==1 and s.linked) false else s.linked,
      owner:if(s.owner==1 and s.linked) 0 else s.owner}}
  action lastRelease=all {Set(2,3).contains(s.mode),s.cleanup,
    Set(4,5,6).contains(s.req),not(s.released),not(s.senderLive),not(s.executorLive),
    s'={...s,refs:0,count:0,released:true}}
  action dropBeforeSender=all {s.bug==12,s.cleanup,s.senderLive,not(s.released),
    s'={...s,refs:0,count:0,released:true}}
  action staleAccess=all {s.bug==10,s.released,
    s'={...s,lateAccess:true}}
  action finishRelease=all {Set(2,3).contains(s.mode),s.released,
    s'={...s,done:true}}
  action idle=s'=s
  action step=any {freeze,latePublish,commonResult,reject,installReceiverRoot,
    handoff,recoverBadHandoff,gc,commit,prepareResult,snapshotOwner,
    physicalUnlock,consumeSender,observeAbandon,partialUnlink,prematureDrop,cleanup,
    lastRelease,dropBeforeSender,staleAccess,finishRelease,idle}
}
