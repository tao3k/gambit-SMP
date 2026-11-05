module finalizer_registry_composition {
  // Two VMs deliberately use the same numeric worker slot. The abstract
  // closed+refs is ONE CAS word counting reservation/resource/derived units.
  // Entries have true join0 as an input premise; no native join is simulated.
  type Key={vm:int,vmGen:int,epoch:int,slot:int,inc:int,handle:int,laneGen:int}
  type State={mode:int,bug:int,epoch:int->int,stage:int->int,
    closed:int->bool,refs:int->int,held:int->bool,granted:int->bool,live:int->int,pin:int->bool,
    key:int->Key,used:int->Key,rxVm:int->int,rxGen:int->int,ready:int->bool,
    writers:int->int,readers:int->int,complete:int->bool,freed:int->bool,
    window:bool,selected:int,checked:bool,defer:bool,acks:Set[int],
    tried:bool,replayRejected:bool,blockingUsed:bool,
    earlyReturn:bool,waiting:bool}
  val vms=Set(1,2)
  pure def makeKey(v:int,e:int):Key={vm:v,vmGen:v*10,epoch:e,slot:1,
    inc:e,handle:v*100+e,laneGen:e}
  var s:State
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,
    epoch:Map(1->1,2->1),stage:Map(1->0,2->0),closed:Map(1->false,2->false),
    refs:Map(1->0,2->0),held:Map(1->false,2->false),granted:Map(1->false,2->false),live:Map(1->0,2->0),
    pin:Map(1->false,2->false),key:Map(1->makeKey(1,1),2->makeKey(2,1)),
    used:Map(1->makeKey(1,1),2->makeKey(2,1)),rxVm:Map(1->0,2->0),
    rxGen:Map(1->0,2->0),ready:Map(1->false,2->false),writers:Map(1->0,2->0),
    readers:Map(1->0,2->0),complete:Map(1->false,2->false),freed:Map(1->false,2->false),
    window:false,selected:0,checked:false,defer:false,acks:Set(),
    tried:false,replayRejected:false,blockingUsed:false,
    earlyReturn:false,waiting:false}
  action initNormal=s'=initial(0,0)
  action initGuardBusy=s'=initial(1,0)
  action initSlotBusy=s'=initial(2,0)
  action initMiscBusy=s'=initial(3,0)
  action initSealRace=s'=initial(4,0)
  action initRepeatedEpoch=s'=initial(5,0)
  action initReaderGrace=s'=initial(6,0)
  action initRetryBusyOnce=s'=initial(7,0)
  action initEnrollmentAbort=s'=initial(8,0)
  action initServiceOutlivesResource=s'=initial(9,0)
  action initCrossVm=s'=initial(0,1)
  action initWrongVmGeneration=s'=initial(0,2)
  action initOldEpoch=s'=initial(5,3)
  action initWrongSlot=s'=initial(0,4)
  action initOldIncarnation=s'=initial(5,5)
  action initReusedHandle=s'=initial(5,6)
  action initOldLaneGeneration=s'=initial(5,7)
  action initEnrollAfterSeal=s'=initial(4,8)
  action initReleaseBeforePublish=s'=initial(4,9)
  action initCompleteIgnoresPin=s'=initial(6,10)
  action initOwnedBeforeReceiver=s'=initial(0,11)
  action initCompetingWriter=s'=initial(0,12)
  action initBlockingBorrowCheck=s'=initial(1,13)
  action initMemberEarlyReturn=s'=initial(2,14)
  action initResetLiveReader=s'=initial(6,15)
  action initDropServiceUnit=s'=initial(0,16)
  action initDeriveAfterDestroy=s'=initial(0,17)
  action initWaitInsideWindow=s'=initial(1,18)
  def lastEpoch(v:int):bool=not(s.mode==5 and v==1) or s.epoch.get(v)==2
  action reserve(v:int):bool=all {s.stage.get(v)==0,not(s.held.get(v)),
    not(s.closed.get(v)),s'={...s,held:s.held.set(v,true),granted:s.granted.set(v,true),refs:s.refs.set(v,1)}}
  action enroll(v:int):bool=all {s.stage.get(v)==0,s.held.get(v),s.mode!=8,
    s'={...s,stage:s.stage.set(v,1),live:s.live.set(v,1),pin:s.pin.set(v,true),
      key:s.key.set(v,makeKey(v,s.epoch.get(v))),used:s.used.set(v,makeKey(v,s.epoch.get(v))),
      readers:s.readers.set(v,if(s.mode==6 and v==1) 1 else 0),
      refs:s.refs.set(v,if(s.mode==6 and v==1) 2 else 1)}}
  action abort(v:int):bool=all {s.mode==8,s.stage.get(v)==0,s.held.get(v),
    s'={...s,stage:s.stage.set(v,8)}}
  action releaseReservation(v:int):bool=all {s.held.get(v),s.stage.get(v)!=0,
    s'={...s,held:s.held.set(v,false),refs:s.refs.set(v,if(s.pin.get(v)) s.refs.get(v) else s.refs.get(v)-1)}}
  action seal(v:int):bool=all {not(s.closed.get(v)),lastEpoch(v),
    s.mode==4 or s.stage.get(v)>0,
    s'={...s,closed:s.closed.set(v,true)}}
  action reject(v:int):bool=all {s.stage.get(v)==0,s.closed.get(v),not(s.held.get(v)),
    s'={...s,stage:s.stage.set(v,8)}}
  action claim(v:int):bool=all {s.stage.get(v)==1,not(s.held.get(v)),
    s'={...s,stage:s.stage.set(v,2),writers:s.writers.set(v,1)}}
  action initReceiver(v:int):bool=all {s.stage.get(v)==2,not(s.ready.get(v)),
    s'={...s,rxVm:s.rxVm.set(v,v),rxGen:s.rxGen.set(v,s.epoch.get(v)),ready:s.ready.set(v,true)}}
  action publishOwned(v:int):bool=all {s.stage.get(v)==2,s.ready.get(v),
    s'={...s,stage:s.stage.set(v,3)}}
  action beginWindow(v:int):bool=all {not(s.window),s.stage.get(v)==3,
    s.pin.get(v),
    s'={...s,window:true,selected:v,checked:false,defer:false,acks:Set(),refs:s.refs.set(v,s.refs.get(v)+1)}}
  action tryCheck=all {s.window,not(s.checked),not(s.waiting),
    val busy=s.selected==1 and (Set(1,2,3).contains(s.mode) or (s.mode==7 and not(s.tried)))
    s'={...s,checked:true,defer:busy,tried:s.tried or busy}}
  action ack(p:int):bool=all {s.window,s.checked,not(s.acks.contains(p)),
    s'={...s,acks:s.acks.union(Set(p))}}
  action endWindow=all {s.window,s.acks==vms,
    s.mode!=9 or not(s.pin.get(s.selected)),
    s'={...s,window:false,refs:s.refs.set(s.selected,s.refs.get(s.selected)-1),stage:s.stage.set(s.selected,if(s.defer) 7 else if(s.pin.get(s.selected)) 4 else 6),
      complete:s.complete.set(s.selected,not(s.defer)),selected:0}}
  action retry(v:int):bool=all {s.mode==7,s.stage.get(v)==7,
    s'={...s,stage:s.stage.set(v,3)}}
  action retireResourceInWindow=all {s.window,s.checked,not(s.defer),
    s.pin.get(s.selected),s.readers.get(s.selected)==0,
    s'={...s,stage:s.stage.set(s.selected,5),pin:s.pin.set(s.selected,false),
      live:s.live.set(s.selected,0),refs:s.refs.set(s.selected,s.refs.get(s.selected)-1),
      complete:s.complete.set(s.selected,true)}}
  action readerExit=all {s.readers.get(1)==1,s'={...s,readers:s.readers.set(1,0),refs:s.refs.set(1,s.refs.get(1)-1)}}
  action releaseEntry(v:int):bool=all {s.stage.get(v)==4,s.readers.get(v)==0,
    s'={...s,stage:s.stage.set(v,6),pin:s.pin.set(v,false),live:s.live.set(v,0),refs:s.refs.set(v,s.refs.get(v)-1)}}
  action renew=all {s.mode==5,s.epoch.get(1)==1,s.stage.get(1)==6,not(s.closed.get(1)),
    s'={...s,epoch:s.epoch.set(1,2),stage:s.stage.set(1,0),
      rxVm:s.rxVm.set(1,0),rxGen:s.rxGen.set(1,0),ready:s.ready.set(1,false),
      writers:s.writers.set(1,0),granted:s.granted.set(1,false),complete:s.complete.set(1,false)}}
  action rejectReplay=all {s.mode==5,s.epoch.get(1)==2,s.stage.get(1)>=1,
    not(s.replayRejected),s.key.get(1)!=makeKey(1,1),s'={...s,replayRejected:true}}
  action destroy(v:int):bool=all {s.closed.get(v),s.refs.get(v)==0,
    s.live.get(v)==0,not(s.pin.get(v)),s.readers.get(v)==0,
    Set(6,8).contains(s.stage.get(v)),not(s.freed.get(v)),
    s'={...s,freed:s.freed.set(v,true)}}
  action badKey=all {s.bug>=1,s.bug<=7,s.stage.get(1)==3,
    val k=s.used.get(1)
    val wrong=if(s.bug==1) {...k,vm:2} else if(s.bug==2) {...k,vmGen:0}
      else if(s.bug==3) {...k,epoch:0} else if(s.bug==4) {...k,slot:2}
      else if(s.bug==5) {...k,inc:0} else if(s.bug==6) {...k,handle:0}
      else {...k,laneGen:0}
    s'={...s,used:s.used.set(1,wrong)}}
  action bad=any {badKey,
    all {s.bug==8,s.closed.get(1),s.stage.get(1)==0,not(s.held.get(1)),not(s.granted.get(1)),s'={...s,stage:s.stage.set(1,1),live:s.live.set(1,1),pin:s.pin.set(1,true)}},
    all {s.bug==9,s.held.get(1),s.stage.get(1)==0,s'={...s,refs:s.refs.set(1,0)}},
    all {s.bug==10,s.complete.get(1),s.pin.get(1),s'={...s,freed:s.freed.set(1,true)}},
    all {s.bug==11,s.stage.get(1)==2,not(s.ready.get(1)),s'={...s,stage:s.stage.set(1,3)}},
    all {s.bug==12,s.stage.get(1)==2,s'={...s,writers:s.writers.set(1,2)}},
    all {s.bug==13,s.window,s.selected==1,s'={...s,blockingUsed:true}},
    all {s.bug==14,s.window,s'={...s,earlyReturn:true}},
    all {s.bug==15,s.stage.get(1)==4,s.readers.get(1)==1,
      s'={...s,live:s.live.set(1,0),pin:s.pin.set(1,false)}},
    all {s.bug==16,s.window,s'={...s,refs:s.refs.set(s.selected,s.refs.get(s.selected)-1)}},
    all {s.bug==17,s.freed.get(1),s'={...s,refs:s.refs.set(1,s.refs.get(1)+1)}}}
  action waitBroken=all {s.bug==18,s.window,s.selected==1,not(s.checked),
    s'={...s,waiting:true}}
  val safe=all {not(s.blockingUsed),not(s.earlyReturn),
    vms.forall(v=>s.refs.get(v)==
      (if(s.held.get(v) or s.pin.get(v)) 1 else 0)+s.readers.get(v)+
      (if(s.window and s.selected==v) 1 else 0)),
    vms.forall(v=>s.pin.get(v)==(s.live.get(v)==1)),
    vms.forall(v=>not(s.pin.get(v)) or s.granted.get(v)),
    vms.forall(v=>s.readers.get(v)==0 or s.pin.get(v)),
    vms.forall(v=>s.stage.get(v)==0 or s.stage.get(v)==8 or s.key.get(v)==makeKey(v,s.epoch.get(v))),
    vms.forall(v=>not(Set(2,3,4,5,7).contains(s.stage.get(v))) or s.used.get(v)==s.key.get(v)),
    vms.forall(v=>not(Set(3,4,5,7).contains(s.stage.get(v))) or
      (s.ready.get(v) and s.rxVm.get(v)==v and s.rxGen.get(v)==s.epoch.get(v))),
    vms.forall(v=>s.writers.get(v)<=1),
    vms.forall(v=>not(s.freed.get(v)) or
      (s.closed.get(v) and s.refs.get(v)==0 and s.live.get(v)==0 and not(s.pin.get(v)) and s.readers.get(v)==0))}
  val goal=if(Set(1,2,3).contains(s.mode)) s.stage.get(1)==7 and s.freed.get(2)
    else s.freed.get(1) and s.freed.get(2) and (s.mode!=5 or s.replayRejected)
  action idle=s'=s
  action step=any {reserve(1),reserve(2),enroll(1),enroll(2),abort(1),abort(2),
    releaseReservation(1),releaseReservation(2),seal(1),seal(2),reject(1),reject(2),
    claim(1),claim(2),initReceiver(1),initReceiver(2),publishOwned(1),publishOwned(2),
    beginWindow(1),beginWindow(2),tryCheck,ack(1),ack(2),endWindow,retry(1),retry(2),
    readerExit,retireResourceInWindow,releaseEntry(1),releaseEntry(2),renew,rejectReplay,destroy(1),destroy(2),bad,waitBroken,idle}
  temporal fair=weakFair(reserve(1),Set(s)).and(weakFair(reserve(2),Set(s)))
    .and(weakFair(enroll(1),Set(s))).and(weakFair(enroll(2),Set(s)))
    .and(weakFair(abort(1),Set(s))).and(weakFair(abort(2),Set(s)))
    .and(weakFair(releaseReservation(1),Set(s))).and(weakFair(releaseReservation(2),Set(s)))
    .and(weakFair(seal(1),Set(s))).and(weakFair(seal(2),Set(s)))
    .and(weakFair(reject(1),Set(s))).and(weakFair(reject(2),Set(s)))
    .and(weakFair(claim(1),Set(s))).and(weakFair(claim(2),Set(s)))
    .and(weakFair(initReceiver(1),Set(s))).and(weakFair(initReceiver(2),Set(s)))
    .and(weakFair(publishOwned(1),Set(s))).and(weakFair(publishOwned(2),Set(s)))
    .and(weakFair(beginWindow(1),Set(s))).and(weakFair(beginWindow(2),Set(s)))
    .and(weakFair(tryCheck,Set(s))).and(weakFair(ack(1),Set(s))).and(weakFair(ack(2),Set(s)))
    .and(weakFair(endWindow,Set(s))).and(weakFair(retry(1),Set(s))).and(weakFair(retry(2),Set(s)))
    .and(weakFair(retireResourceInWindow,Set(s))).and(weakFair(readerExit,Set(s))).and(weakFair(releaseEntry(1),Set(s)))
    .and(weakFair(releaseEntry(2),Set(s))).and(weakFair(renew,Set(s)))
    .and(weakFair(rejectReplay,Set(s))).and(weakFair(destroy(1),Set(s))).and(weakFair(destroy(2),Set(s)))
  temporal completion=fair.implies(eventually(goal))
}
