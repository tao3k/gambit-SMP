// Finite safety schedule for the actual registry admission/acknowledgement cut.
// Two VMs, two nested signal readers; no liveness, arbitrary native-stop,
// constructor rollback completeness, weak-memory or raw-pointer ABA theorem.
module vm_registry {
  type State={gate:str,readers:Set[int],view:Set[int],registered:Set[int],
    initializing:bool,retained:Set[int],published:bool,acked:bool,
    pending:bool,delivered:bool,freed:bool,refused:bool}
  var s:State
  pure val initial:State={gate:"open",readers:Set(),view:Set(),registered:Set(0),
    initializing:false,retained:Set(),published:false,acked:false,
    pending:false,delivered:false,freed:false,refused:false}
  action init=s'=initial
  action borrow={nondet i=Set(0,1).oneOf();all{s.gate=="open",not(s.readers.contains(i)),
    s'={...s,readers:s.readers.union(Set(i)),
      view:if(s.registered.contains(1))s.view.union(Set(i))else s.view}}}
  action returnReader={nondet i=s.readers.oneOf();s'={...s,
    readers:s.readers.exclude(Set(i)),view:s.view.exclude(Set(i))}}
  action acquire=all{s.gate=="open",s.readers.size()==0,s'={...s,gate:"writer"}}
  action release=all{s.gate=="writer",not(s.initializing),s'={...s,gate:"open"}}
  action beginSetup=all{s.gate=="writer",not(s.published),not(s.initializing),
    s'={...s,initializing:true}}
  action publish=all{s.gate=="writer",s.initializing,s'={...s,initializing:false,
    published:true,registered:s.registered.union(Set(1))}}
  action failKnown=all{s.gate=="writer",s.initializing,s'={...s,initializing:false}}
  action failUnknown=all{s.gate=="writer",s.initializing,s'={...s,
    initializing:false,published:true,registered:s.registered.union(Set(1)),retained:Set(1)}}
  action retire=all{s.gate=="writer",s.registered.contains(1),s.retained.size()==0,
    s'={...s,registered:Set(0),acked:true}}
  action releaseUnknown=all{s.gate=="writer",s.registered.contains(1),
    s'={...s,retained:Set(1)}}
  action refuse=all{s.gate=="writer",s.registered.contains(1),s'={...s,refused:true}}
  action reclaim=all{s.gate=="writer",s.registered==Set(0),not(s.initializing),
    s.retained.size()==0,s'={...s,gate:"closed",registered:Set(),freed:true}}
  action signal=s'={...s,pending:true}
  action deliver=all{s.gate=="open",s.readers.size()>0,s.pending,
    s'={...s,pending:false,delivered:true}}
  action step=any{borrow,returnReader,acquire,release,beginSetup,publish,failKnown,
    failUnknown,retire,releaseUnknown,refuse,reclaim,signal,deliver,s'=s}
  val safe=all{
    s.gate!="writer" or s.readers.size()==0,
    s.view==(if(s.registered.contains(1))s.readers else Set()),
    not(s.initializing)or(s.gate=="writer"and not(s.registered.contains(1))),
    s.retained.subseteq(s.registered),
    not(s.acked)or not(s.registered.contains(1)),
    not(s.freed)or all{s.gate=="closed",s.registered.size()==0,
      s.readers.size()==0,s.retained.size()==0,not(s.published)or s.acked}
  }
  action check=all{safe,s'=s}
  run retirementAckTest=init.then(acquire).then(beginSetup).then(publish)
    .then(release).then(acquire).then(refuse).then(release).then(acquire)
    .then(retire).then(release).then(acquire).then(reclaim).then(check)
  run pendingSignalTest=init.then(acquire).then(signal).then(release)
    .then(borrow).then(deliver).then(returnReader).then(check)
  run unknownCustodyTest=init.then(acquire).then(beginSetup).then(failUnknown)
    .then(refuse).then(release).then(check)
  action retainedInit=s'={...initial,gate:"writer",registered:Set(0,1),
    published:true,retained:Set(1)}
  action borrowedInit=s'={...initial,readers:Set(0)}
  action badGlobalFree=s'={...s,gate:"closed",freed:true}
  action badLatePublish=s'={...s,registered:Set(0,1),published:true}
}
