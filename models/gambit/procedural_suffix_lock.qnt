// Source-shaped finite callback error/escape controls; not native or FIFO proof.
module procedural_suffix_lock {
  type State={mode:int,bug:int,phase:int,held:bool,active:bool,pin:bool,
    q:Set[int],appended:bool,freed:bool,readFreed:bool,badUnlock:bool,
    lost:bool,other:bool,returned:bool,retained:bool}
  var s:State
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,phase:0,
    held:true,active:false,pin:false,q:Set(1,2),appended:false,freed:false,
    readFreed:false,badUnlock:false,lost:false,other:true,returned:false,retained:false}
  action initError=s'=initial(0,0)
  action initEscape=s'=initial(1,0)
  action initSelfFree=s'=initial(2,0)
  action initDoubleUnlock=s'=initial(0,1)
  action initClearSuffix=s'=initial(0,2)
  action initEarlyPin=s'=initial(0,3)
  action initReadFreed=s'=initial(2,4)
  action detach=all{s.phase==0,s'=s.with("phase",1).with("q",Set(2)).with("active",true).with("pin",true)}
  action unlock=all{s.phase==1,s.held,s'=s.with("held",false).with("phase",2)}
  action enqueue=all{Set(2,3).contains(s.phase),not(s.appended),not(s.held),s'=s.with("q",s.q.union(Set(3))).with("appended",true)}
  action early=all{s.phase==2,s.bug==3,s'=s.with("pin",false).with("phase",3)}
  action callback=all{s.phase==2,s.bug!=3,s'=s.with("phase",3).with("freed",s.mode==2)}
  action finish=all{s.phase==3,s.mode!=1,
    s'=s.with("phase",4).with("returned",true).with("active",false).with("pin",false)
       .with("badUnlock",s.bug==1).with("lost",s.bug==2)
       .with("q",if(s.bug==2) Set() else s.q)
       .with("readFreed",s.freed and s.bug==4)}
  action escape=all{s.phase==3,s.mode==1,s'=s.with("phase",4).with("retained",true)}
  action done=all{s.phase==4,s'=s}
  action step=any{detach,unlock,enqueue,early,callback,finish,escape,done}
  val safe=not(s.badUnlock) and not(s.lost) and not(s.readFreed)
    and (s.active implies s.pin)
    and (s.phase>0 implies s.q.contains(2))
    and (s.appended implies s.q.contains(3))
    and (s.returned implies (not(s.held) and not(s.active) and s.other))
    and (s.retained implies (s.pin and s.active and not(s.returned)))
}
