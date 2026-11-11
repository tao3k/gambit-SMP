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
