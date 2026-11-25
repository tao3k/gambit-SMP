// Synchronous collective projection: copying/queue termination is a premise,
// not proved by this root-publication/result-consumption model.
module runtime_roles {
  type Round = { frozen:Set[int], scanned:Set[int], visited:Set[int],
    strong:Set[int], weak:Set[int], cleaned:Set[int], consumed:Set[int],
    prepared:Set[int], resumed:Set[int], closed:bool, published:bool,
    outcome:bool, localTrue:Set[int] }
  var s:Round
  val members=Set(0,1)
  pure def empty(outcome:bool):Round={frozen:Set(),scanned:Set(),visited:Set(),
    strong:Set(),weak:Set(),cleaned:Set(),consumed:Set(),prepared:Set(),
    resumed:Set(),closed:false,published:false,outcome:outcome,localTrue:Set()}
  action init={nondet b=Set(false,true).oneOf();s'=empty(b)}
  action freeze={nondet i=members.oneOf();all{not(s.closed),not(s.frozen.contains(i)),
    s'={...s,frozen:s.frozen.union(Set(i))}}}
  action close=all{s.frozen==members,not(s.closed),s'={...s,closed:true}}
  action scan={nondet i=members.oneOf();all{s.closed,not(s.scanned.contains(i)),
    s'={...s,scanned:s.scanned.union(Set(i)),visited:s.visited.union(Set(i))}}}
  action strong={nondet i=members.oneOf();all{s.scanned==members,
    not(s.strong.contains(i)),s'={...s,strong:s.strong.union(Set(i))}}}
  action weak={nondet i=members.oneOf();all{s.strong==members,
    not(s.weak.contains(i)),s'={...s,weak:s.weak.union(Set(i))}}}
  action cleanup={nondet i=members.oneOf();all{s.weak==members,
    not(s.cleaned.contains(i)),s'={...s,cleaned:s.cleaned.union(Set(i))}}}
  action publish=all{s.cleaned==members,not(s.published),s'={...s,published:true}}
  action consume={nondet i=members.oneOf();all{s.published,not(s.consumed.contains(i)),
    s'={...s,consumed:s.consumed.union(Set(i)),
      localTrue:if(s.outcome) s.localTrue.union(Set(i)) else s.localTrue}}}
  action prepare={nondet i=members.oneOf();all{s.consumed.contains(i),
    not(s.prepared.contains(i)),s'={...s,prepared:s.prepared.union(Set(i))}}}
  action resume={nondet i=members.oneOf();all{s.prepared==members,
    not(s.resumed.contains(i)),s'={...s,resumed:s.resumed.union(Set(i))}}}
  action step=any{freeze,close,scan,strong,weak,cleanup,publish,consume,prepare,resume,s'=s}
  val safe=all{
    not(s.closed) or s.frozen==members,
    s.scanned.subseteq(s.frozen),s.visited==s.scanned,
    s.strong.size()==0 or s.scanned==members,
    s.weak.size()==0 or s.strong==members,
    s.cleaned.size()==0 or s.weak==members,
    not(s.published) or s.cleaned==members,
    s.consumed.size()==0 or s.published,
    s.localTrue==(if(s.outcome) s.consumed else Set()),
    s.prepared.subseteq(s.consumed),
    s.resumed.size()==0 or s.prepared==members
  }
  action check=all{safe,s'=s}
  pure def ready(b:bool):Round={...empty(b),frozen:members,scanned:members,
    visited:members,strong:members,weak:members,cleaned:members,
    closed:true,published:true}
  run successDeliveryTest=(s'=ready(false)).then(consume).then(consume)
    .then(prepare).then(prepare).then(resume).then(check)
  run overflowDeliveryTest=(s'=ready(true)).then(consume).then(consume)
    .then(prepare).then(prepare).then(resume).then(check)
  run fullRoundTest=(s'=empty(true)).then(freeze).then(freeze).then(close)
    .then(scan).then(scan).then(strong).then(strong).then(weak).then(weak)
    .then(cleanup).then(cleanup).then(publish).then(consume).then(consume)
    .then(prepare).then(prepare).then(resume).then(resume).then(check)
  action earlyClose=all{s'= {...s,closed:true}}
  action wrongOrigin=all{s'={...s,closed:true,frozen:members,scanned:members,visited:Set(0)}}
  action overwriteResult=all{s.published,s.consumed.size()==1,s'={...s,outcome:not(s.outcome)}}
  action earlyResume=all{s'={...s,resumed:Set(0)}}
  action initConsumed={s'={...ready(true),consumed:Set(0),localTrue:Set(0)}}
}

// Root-task protocol, a separate component from collective phase/result delivery.
// Bounded control: two root origins, two executors, two non-wrapping epochs.
// Source adapters, physical writer-stop, release/acquire and whole-round GC
// termination are explicit external premises, not proved by this state machine.
module root_dispatch {
  val origins=Set(0,1)
  val workers=Set(0,1)
  type Dispatch={epoch:int, phase:str, writers:Set[int], frozen:Set[int],
    status:int->str, owner:int->int, entries:int->int, visits:int->int,
    unknown:Set[int], seal:bool, pinned:bool}
  var d:Dispatch
  pure def fresh(e:int):Dispatch={epoch:e,phase:"collecting",writers:Set(),
    frozen:Set(),status:origins.mapBy(_=>"ready"),owner:origins.mapBy(_=>-1),
    entries:origins.mapBy(_=>0),visits:origins.mapBy(_=>0),
    unknown:Set(),seal:false,pinned:false}
  action init={d'=fresh(0)}
  action beginWrite(i:int):bool=all{d.phase=="collecting",not(d.frozen.contains(i)),
    not(d.writers.contains(i)),d'={...d,writers:d.writers.union(Set(i))}}
  action endWrite(i:int):bool=all{d.writers.contains(i),
    d'={...d,writers:d.writers.exclude(Set(i))}}
  action freezeOrigin(i:int):bool=all{d.phase=="collecting",not(d.writers.contains(i)),
    d'={...d,frozen:d.frozen.union(Set(i))}}
  action publish=all{d.phase=="collecting",d.frozen==origins,
    d'={...d,phase:"published",pinned:true}}
  def claimEnabled(i:int,w:int,key:int):bool=all{d.phase=="published",key==d.epoch,
    d.status.get(i)=="ready",not(d.unknown.contains(w))}
  action claim(i:int,w:int,key:int):bool=all{claimEnabled(i,w,key),
    d'={...d,status:d.status.set(i,"claimed"),owner:d.owner.set(i,w)}}
  action enter(i:int,w:int,key:int):bool=all{d.phase=="published",key==d.epoch,
    d.status.get(i)=="claimed",d.owner.get(i)==w,not(d.unknown.contains(w)),
    d'={...d,status:d.status.set(i,"scanning"),entries:d.entries.set(i,d.entries.get(i)+1)}}
  action finish(i:int,w:int,key:int):bool=all{d.phase=="published",key==d.epoch,
    d.status.get(i)=="scanning",d.owner.get(i)==w,
    d'={...d,status:d.status.set(i,"done"),visits:d.visits.set(i,d.visits.get(i)+1)}}
  // This observation does NOT establish stop; the original executor may finish.
  action loseResult(w:int):bool=all{d.phase=="published",
    d'={...d,unknown:d.unknown.union(Set(w))}}
  // Requires a real stop/entry-exclusion certificate, not a join error.
  action returnUnstarted(i:int):bool=all{d.phase=="published",d.status.get(i)=="claimed",
    d'={...d,status:d.status.set(i,"ready"),owner:d.owner.set(i,-1)}}
  action queryDone(i:int,key:int):bool=all{key==d.epoch,d.status.get(i)=="done",d'=d}
  // An input from the round component, NOT a receipt inferred from root counts.
  // Its real issuer must establish strong/weak/copy/cleanup closure separately.
  action acceptRoundSeal(qualified:bool):bool=all{qualified,d.phase=="published",
    origins.forall(i=>d.status.get(i)=="done"),d'={...d,seal:true}}
  action drain=all{d.phase=="published",d.seal,d.writers==Set(),
    origins.forall(i=>d.status.get(i)=="done"),d'={...d,phase:"drained",pinned:false}}
  action certifyStopped(w:int):bool=all{d.unknown.contains(w),
    origins.forall(i=>d.owner.get(i)!=w or d.status.get(i)=="done" or d.status.get(i)=="ready"),
    d'={...d,unknown:d.unknown.exclude(Set(w))}}
  action recycle=all{d.phase=="drained",d.unknown==Set(),d.epoch<1,d'=fresh(d.epoch+1)}
  action step={nondet i=origins.oneOf();nondet w=workers.oneOf();
    nondet key=Set(0,1).oneOf();any{beginWrite(i),endWrite(i),freezeOrigin(i),publish,
      claim(i,w,key),enter(i,w,key),finish(i,w,key),loseResult(w),returnUnstarted(i),
      queryDone(i,key),acceptRoundSeal(true),drain,certifyStopped(w),recycle,d'=d}}
  val taskSafe=all{
    d.writers.intersect(d.frozen)==Set(),
    d.phase=="collecting" or d.frozen==origins,
    d.phase!="published" or d.pinned,
    d.phase!="drained" or (d.seal and not(d.pinned)),
    origins.forall(i=>all{d.visits.get(i)<=1,d.entries.get(i)<=1,
      (d.status.get(i)=="done")== (d.visits.get(i)==1),
      d.entries.get(i)==0 or d.status.get(i)=="scanning" or d.status.get(i)=="done",
      d.status.get(i)!="ready" or d.owner.get(i)==-1,
      d.status.get(i)=="ready" or workers.contains(d.owner.get(i))}),
    not(d.seal) or origins.forall(i=>d.status.get(i)=="done")
  }
  action check=all{taskSafe,d'=d}
  pure def published(e:int):Dispatch={...fresh(e),phase:"published",frozen:origins,pinned:true}
  run lostAckTest=(d'=published(0)).then(claim(0,1,0)).then(enter(0,1,0))
    .then(finish(0,1,0)).then(queryDone(0,0)).then(queryDone(0,0)).then(check)
  run unknownCustodyTest=(d'=published(0)).then(claim(0,1,0)).then(enter(0,1,0))
    .then(loseResult(1)).then(check).then(finish(0,1,0)).then(check)
  run stoppedBeforeEntryTest=(d'=published(0)).then(claim(0,1,0))
    .then(loseResult(1)).then(returnUnstarted(0)).then(claim(0,0,0)).then(check)
  run writerFreezeTest=(d'=fresh(0)).then(beginWrite(1)).then(endWrite(1))
    .then(freezeOrigin(1)).then(freezeOrigin(0)).then(publish).then(check)
  run staleKeyTest=(d'=published(1)).then(all{not(claimEnabled(0,0,0)),d'=d}).then(check)
  run duplicateClaimTest=(d'=published(0)).then(claim(0,0,0))
    .then(all{not(claimEnabled(0,1,0)),d'=d}).then(check)
  run epochDrainTest=(d'=published(0)).then(claim(0,0,0)).then(enter(0,0,0))
    .then(finish(0,0,0)).then(claim(1,1,0)).then(enter(1,1,0)).then(finish(1,1,0))
    .then(acceptRoundSeal(true)).then(drain).then(recycle).then(check)
  // Deliberately unsafe variants preserve the rejected design histories.
  action drainWithoutRoundSeal=all{d'={...d,phase:"drained",pinned:false}}
  action freezeWithWriter=all{d'={...d,frozen:d.frozen.union(Set(1))}}
  action requeueEntered=all{d.status.get(0)=="scanning",
    d'={...d,status:d.status.set(0,"ready"),owner:d.owner.set(0,-1)}}
  run prematureDrainRejectedTest=(d'=published(0)).then(drainWithoutRoundSeal)
    .then(all{not(taskSafe),d'=d})
  run liveWriterRejectedTest=(d'=fresh(0)).then(beginWrite(1)).then(freezeWithWriter)
    .then(all{not(taskSafe),d'=d})
  run unknownReplayRejectedTest=(d'=published(0)).then(claim(0,1,0))
    .then(enter(0,1,0)).then(loseResult(1)).then(requeueEntered)
    .then(all{not(taskSafe),d'=d})
}
