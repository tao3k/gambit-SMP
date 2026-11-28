module async_destruction_composition {
  // Asynchronous owner conversion interleaves with close and two moving GCs.
  // The native service/reader and full-key ABA refinements remain separate.
  type S={mode:int,bug:int,producer:bool,outer:bool,tail:bool,
    queued:bool,handler:bool,reply:bool,published:bool,consumed:bool,
    units:int,closed:bool,destroying:bool,freed:bool,
    gc:int,rootVersion:int,locked:bool,pstateDestructs:int,vmDestructs:int,
    postFreeAccess:bool,escaped:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,producer:true,outer:true,
    tail:true,queued:false,handler:false,reply:false,published:false,
    consumed:false,units:2,closed:false,destroying:false,freed:false,
    gc:0,rootVersion:0,locked:false,pstateDestructs:0,vmDestructs:0,
    postFreeAccess:false,escaped:false}
  action initNormal=s'=initial(0,0)
  action initEscape=s'=initial(1,0)
  action initRetained=s'=initial(2,0)
  action initQueueGap=s'=initial(0,1)
  action initHandlerRelease=s'=initial(0,2)
  action initOuterEarly=s'=initial(0,3)
  action initMissingWriteback=s'=initial(0,4)
  action initLockedCallback=s'=initial(0,5)
  action initPostReleaseAccess=s'=initial(0,6)
  action initDuplicateP0=s'=initial(0,7)
  action initEscapeDrop=s'=initial(1,8)
  action initDestructorCallback=s'=initial(0,9)
  def owners=(if(s.producer) 1 else 0)+(if(s.outer) 1 else 0)+
    (if(s.queued) 1 else 0)+(if(s.handler) 1 else 0)+(if(s.reply) 1 else 0)
  def livePayload=s.queued or s.handler or s.reply
  action publish=all {s.producer,not(s.published),not(s.closed),
    s'={...s,published:true,queued:true,units:s.units+1}}
  action releaseProducer=all {s.producer,s.published or s.closed,
    s'={...s,producer:false,units:s.units-1}}
  action close=all {not(s.closed),s'={...s,closed:true}}
  action dequeue=all {s.queued,not(s.handler),
    s'={...s,queued:false,handler:true}}
  action completeCallback=all {s.handler,s.mode!=2,not(s.locked),
    s'={...s,handler:false,reply:true,escaped:s.mode==1}}
  action consume=all {s.reply,not(s.producer),
    s'={...s,reply:false,consumed:true,units:s.units-1}}
  action returnOuter=all {s.outer,not(s.producer),not(livePayload),
    s.consumed or not(s.published),
    s'={...s,tail:false,outer:false,units:s.units-1}}
  action moveGc=all {s.gc<2,not(s.destroying),s.outer or livePayload,
    s'={...s,gc:s.gc+1,rootVersion:s.gc+1}}
  action beginDestroy=all {s.closed,s.units==0,not(s.destroying),
    s'={...s,destroying:true}}
  action destroyP0=all {s.destroying,s.pstateDestructs==0,
    s'={...s,pstateDestructs:1}}
  action destroyVm=all {s.destroying,s.pstateDestructs==1,s.vmDestructs==0,
    s'={...s,vmDestructs:1}}
  action freeBacking=all {s.destroying,s.vmDestructs==1,not(s.freed),
    s'={...s,freed:true}}
  action mutant=any {
    all {s.bug==1,s.producer,not(s.published),not(s.closed),
      s'={...s,published:true,queued:true}},
    all {s.bug==2,s.handler,s'={...s,units:s.units-1}},
    all {s.bug==3,s.outer,s'={...s,outer:false,units:s.units-1}},
    all {s.bug==4,livePayload,s.gc<2,s'={...s,gc:s.gc+1}},
    all {s.bug==5,s.handler,s'={...s,locked:true}},
    all {s.bug==6,s.freed,s'={...s,postFreeAccess:true}},
    all {s.bug==7,s.destroying,s.pstateDestructs==1,
      s'={...s,pstateDestructs:2}},
    all {s.bug==8,s.handler,
      s'={...s,handler:false,reply:true,escaped:true,units:s.units-1}},
    all {s.bug==9,s.destroying,not(s.freed),
      s'={...s,handler:true,units:s.units+1}}
  }
  action step=any {publish,releaseProducer,close,dequeue,completeCallback,
    consume,returnOuter,moveGc,beginDestroy,destroyP0,destroyVm,freeBacking,mutant}
  val safe=all {s.units==owners,s.units>=0,not(s.tail) or s.outer,
    not(livePayload) or s.rootVersion==s.gc,
    not(s.handler) or (not(s.locked) and not(s.destroying)),
    not(s.destroying) or s.units==0,
    not(s.freed) or s.units==0,not(s.postFreeAccess),
    s.pstateDestructs<=1,s.vmDestructs<=1}
}
