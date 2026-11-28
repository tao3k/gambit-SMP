// Conditional activation/root/cleanup refinement; not C memory-model or callback termination proof.
module activation_roots_cleanup {
  type State={mode:int,bug:int,phase:int,rc:bool,dataRoot:bool,parent:bool,
    child:bool,childRoot:bool,closed:bool,q:Set[int],appended:bool,
    held:bool,called:bool,escaped:bool,retained:bool,done:bool,
    rootLost:bool,stale:bool,destroyed:bool,version:int,cached:int,
    callerOwns:bool,unwound:bool,lastUse:bool,ownerAlive:bool}
  var s:State
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,phase:0,
    rc:false,dataRoot:false,parent:false,child:false,childRoot:false,closed:false,
    q:Set(1,2),appended:false,held:false,called:false,escaped:false,retained:false,
    done:false,rootLost:false,stale:false,destroyed:false,version:0,cached:0,
    callerOwns:true,unwound:false,lastUse:false,ownerAlive:true}
  action initReturn=s'=initial(0,0)
  action initCaught=s'=initial(1,0)
  action initRetained=s'=initial(2,0)
  action initCleanup=s'=initial(3,0)
  action initOpaquePayload=s'=initial(0,1)
  action initNestedDropsOuter=s'=initial(0,2)
  action initEscapeDrop=s'=initial(2,3)
  action initLockedCallback=s'=initial(3,4)
  action initSuffixDrop=s'=initial(3,5)
  action initDestroyRetained=s'=initial(3,6)
  action initStaleCarrier=s'=initial(0,7)
  action initRemoteRelease=s'=initial(0,8)
  action register=all{s.phase==0,s'=s.with("phase",1).with("rc",true).with("parent",true).with("dataRoot",s.bug!=1)}
  action prepare=all{s.phase==1,s'=s.with("phase",2).with("cached",s.version)}
  action enqueueSuffix=all{not(s.closed),not(s.appended),s.phase<3,s'=s.with("q",s.q.union(Set(3))).with("appended",true)}
  action close=all{s.phase==2,s.mode==3,not(s.closed),s'=s.with("closed",true)}
  action detach=all{s.phase==2,(s.mode!=3 or s.closed),s'=s.with("phase",3).with("q",s.q.exclude(Set(1))).with("callerOwns",false).with("held",s.bug==4)}
  action callback=all{s.phase==3,s'=s.with("phase",4).with("called",true).with("child",true).with("childRoot",true)}
  action gc=all{s.phase>=3,s.phase<=6,s.version==0,
    s'=s.with("version",1).with("rootLost",not(s.rc and s.dataRoot) or (s.child and not(s.childRoot)))}
  action childReturn=all{s.phase==4,s'=s.with("phase",5).with("child",false).with("childRoot",false).with("parent",s.bug!=2)}
  action result=all{s.phase==5,s'=s.with("phase",6).with("escaped",Set(1,2).contains(s.mode)).with("unwound",s.mode==1)}
  action retain=all{s.phase==6,Set(2,3).contains(s.mode),
    s'=s.with("phase",7).with("retained",true)
      .with("rc",s.bug!=3).with("parent",s.bug!=3)
      .with("q",if(s.bug==5) Set() else s.q).with("destroyed",s.bug==6)}
  action finalUse=all{s.phase==6,Set(0,1).contains(s.mode),
    s'=s.with("phase",7).with("lastUse",true)
      .with("stale",s.bug==7 and s.cached!=s.version)}
  action release=all{s.phase==7,s.lastUse,not(s.retained),
    s'=s.with("phase",8).with("parent",false).with("rc",false).with("done",true)}
  action remote=all{s.phase==4,s.bug==8,s'=s.with("rc",false).with("ownerAlive",false).with("phase",5)}
  action stable=all{s.phase>=7,s'=s}
  action step=any{register,prepare,enqueueSuffix,close,detach,callback,gc,childReturn,result,retain,finalUse,release,remote,stable}
  val safe=not(s.rootLost) and not(s.stale)
    and (s.called implies not(s.held))
    and (s.phase>=1 and not(s.done) implies (s.parent and s.rc and s.ownerAlive))
    and (s.phase>=3 implies s.q.contains(2))
    and (s.appended implies s.q.contains(3))
    and (s.retained implies (s.parent and s.rc and not(s.destroyed)))
    and (s.done implies (s.lastUse and not(s.child) and (not(s.escaped) or s.unwound)))
}
