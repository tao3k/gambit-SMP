// Finite safety schedule for the actual registry admission/acknowledgement cut.
// Two VMs, two nested signal readers; no liveness, arbitrary native-stop,
// constructor rollback completeness, weak-memory or raw-pointer ABA theorem.
// resizes counts primary cleanup preparation, not ordinary VM resize generations.
module vm_registry {
  type State={gate:str,readers:Set[int],view:Set[int],registered:Set[int],
    initializing:bool,retained:Set[int],published:bool,acked:bool,
    pending:bool,delivered:bool,freed:bool,refused:bool,drained:bool,resizes:int}
  var s:State
  pure val initial:State={gate:"open",readers:Set(),view:Set(),registered:Set(0),
    initializing:false,retained:Set(),published:false,acked:false,
    pending:false,delivered:false,freed:false,refused:false,drained:false,resizes:0}
  action init=s'=initial
  action borrow={nondet i=Set(0,1).oneOf();all{s.gate=="open",not(s.readers.contains(i)),
    s'={...s,readers:s.readers.union(Set(i)),
      view:if(s.registered.contains(1))s.view.union(Set(i))else s.view}}}
  action returnReader={nondet i=s.readers.oneOf();s'={...s,
    readers:s.readers.exclude(Set(i)),view:s.view.exclude(Set(i))}}
  action acquire=all{s.gate=="open",s.readers.size()==0,s'={...s,gate:"writer"}}
  action release=all{s.gate=="writer",not(s.initializing),s'={...s,gate:"open"}}
  action beginSetup=all{s.gate=="writer",not(s.published),not(s.initializing),not(s.drained),
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
  // The owner drains outside the registry writer. A callback may retain a
  // topology pin; final writer refusal preserves DRAINED for a pure retry.
  action drainPrimary=all{s.gate=="open",s.registered==Set(0),
    s.retained.size()==0,not(s.initializing),not(s.drained),
    s'={...s,drained:true,resizes:s.resizes+1}}
  action reclaim=all{s.drained,s.gate=="writer",s.registered==Set(0),not(s.initializing),
    s.retained.size()==0,s'={...s,gate:"closed",registered:Set(),freed:true}}
  action signal=s'={...s,pending:true}
  action deliver=all{s.gate=="open",s.readers.size()>0,s.pending,
    s'={...s,pending:false,delivered:true}}
  action step=any{borrow,returnReader,acquire,release,beginSetup,publish,failKnown,
    failUnknown,retire,releaseUnknown,refuse,drainPrimary,reclaim,signal,deliver,s'=s}
  val safe=all{
    s.resizes<=1,
    s.drained implies all{s.registered.subseteq(Set(0)),not(s.initializing)},
    s.gate!="writer" or s.readers.size()==0,
    s.view==(if(s.registered.contains(1))s.readers else Set()),
    not(s.initializing)or(s.gate=="writer"and not(s.registered.contains(1))),
    s.retained.subseteq(s.registered),
    not(s.acked)or not(s.registered.contains(1)),
    not(s.freed)or all{s.gate=="closed",s.registered.size()==0,
      s.readers.size()==0,s.retained.size()==0,s.drained,not(s.published)or s.acked}
  }
  action check=all{safe,s'=s}
  run retirementAckTest=init.then(acquire).then(beginSetup).then(publish)
    .then(release).then(acquire).then(refuse).then(release).then(acquire)
    .then(retire).then(release).then(drainPrimary).then(acquire).then(reclaim).then(check)
  run pendingSignalTest=init.then(acquire).then(signal).then(release)
    .then(borrow).then(deliver).then(returnReader).then(check)
  run unknownCustodyTest=init.then(acquire).then(beginSetup).then(failUnknown)
    .then(refuse).then(release).then(check)
  run drainedRetryTest=init.then(borrow).then(drainPrimary)
    .then(all{assert(s.readers.size()>0),assert(s.drained),s'=s})
    .then(returnReader).then(acquire).then(reclaim).then(check)
  action badResizeDrained=s'={...s,resizes:s.resizes+1}
  run drainedRetryNegativeTest=init.then(borrow).then(drainPrimary)
    .then(returnReader).then(acquire).then(badResizeDrained)
    .then(all{assert(not(safe)),s'=s})
  action retainedInit=s'={...initial,gate:"writer",registered:Set(0,1),
    published:true,retained:Set(1)}
  action borrowedInit=s'={...initial,readers:Set(0)}
  action badGlobalFree=s'={...s,gate:"closed",freed:true}
  action badLatePublish=s'={...s,registered:Set(0,1),published:true}
}
