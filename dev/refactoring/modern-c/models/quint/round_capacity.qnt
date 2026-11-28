// Distributed pre-flip protocol. Lean owns numeric packing/coverage, not this history.
module round_capacity {
  type Placement={object:int,region:int,begin:int,past:int}
  pure val objects=Set(0,1,2)
  pure def objectWords(o:int):int=if(o==0)3 else if(o==1)2 else 4
  type S={frozen:bool,positions:Set[Placement],reserved:Set[int],ack:Set[int],
    plan:bool,flipped:bool,unknown:bool,retained:bool,roots:bool,
    active:int,cancelled:int,sectionWaste:int,census:Set[int],censusClosed:bool,
    decision:int,observed:Set[int],returned:bool}
  var s:S
  pure val empty:S={frozen:false,positions:Set(),reserved:Set(),ack:Set(),plan:false,
    flipped:false,unknown:false,retained:false,roots:true,active:3,cancelled:0,sectionWaste:2,
    census:Set(),censusClosed:false,decision:0,observed:Set(),returned:false}
  pure val participants=Set(0,1,2)
  pure def disjoint(a:Placement,b:Placement):bool=
    a.region!=b.region or a.begin>=b.past or b.begin>=a.past
  action init={s'=empty}
  action freeze=all{not(s.frozen),not(s.returned),s.decision==0,s'={...s,frozen:true}}
  action discover(o:int):bool=all{s.frozen,not(s.censusClosed),s.decision==0,
    o.in(objects),s'={...s,census:s.census.union(Set(o))}}
  action closeCensus=all{s.frozen,s.census==objects,s.decision==0,
    s'={...s,censusClosed:true}}
  // Test shorthand for a completed census, not an atomic implementation claim.
  action completeCensus=all{s.frozen,s.decision==0,
    s'={...s,census:objects,censusClosed:true}}
  action reserveAt(o:int,r:int,b:int):bool={
    val p:Placement={object:o,region:r,begin:b,past:b+objectWords(o)};
    all{s.frozen,s.censusClosed,s.decision==0,not(s.plan),not(s.unknown),
    not(o.in(s.reserved)),o.in(objects),r.in(Set(0,1)),b>=1,
    p.past<=6, // each 8-word region retains link word + two terminal words
    r==1 implies p.past<=5, // restoration [5,6) in region 1 is not copy space
    s.positions.forall(old=>disjoint(p,old)),
    s'={...s,positions:s.positions.union(Set(p)),reserved:s.reserved.union(Set(o))}}}
  action reserve={nondet o=objects.oneOf();nondet r=Set(0,1).oneOf();
    nondet b=1.to(5).oneOf();reserveAt(o,r,b)}
  action acknowledge=all{s.reserved!=s.ack,not(s.unknown),
    nondet o=s.reserved.exclude(s.ack).oneOf();s'={...s,ack:s.ack.union(Set(o))}}
  action publishPlan=all{s.frozen,s.censusClosed,s.census==objects,
    s.reserved==objects,s.ack==objects,s.decision==0,not(s.unknown),
    s'={...s,plan:true,decision:1}}
  action refuse=all{s.frozen,s.decision==0,not(s.unknown),not(s.flipped),
    s'={...s,decision:2,positions:Set(),reserved:Set(),ack:Set()}}
  action observe(p:int):bool=all{p.in(participants),s.decision!=0,
    s'={...s,observed:s.observed.union(Set(p))}}
  action returnRefused=all{s.decision==2,s.observed==participants,not(s.unknown),
    not(s.flipped),s.roots,s'={...s,frozen:false,returned:true}}
  action flip=all{s.plan,s.observed==participants,not(s.unknown),s'={...s,flipped:true}}
  action unknownResult=all{not(s.plan),s.reserved!=Set(),s'={...s,unknown:true}}
  action retain=all{s.unknown,not(s.flipped),s'={...s,retained:true}}
  action cancelPrivate=all{s.active>0,s'={...s,cancelled:s.cancelled+s.active,active:0}}
  val safe=all{
    s.positions.forall(p=>all{p.begin>=1,p.past<=6,p.past-p.begin==objectWords(p.object),
      p.region==1 implies p.past<=5}),
    s.positions.forall(a=>s.positions.forall(b=>a==b or disjoint(a,b))),
    s.positions.size()==s.reserved.size(),s.ack.subseteq(s.reserved),
    s.plan implies all{s.frozen,s.censusClosed,s.census==objects,
      s.reserved==objects,s.ack==objects,s.decision==1,not(s.unknown)},
    s.flipped implies (s.plan and s.observed==participants),
    s.unknown implies all{s.roots,not(s.flipped)},
    s.active+s.cancelled==3,s.sectionWaste==2,
    s.observed.subseteq(participants),s.census.subseteq(objects),
    s.censusClosed implies s.census==objects,
    s.decision==2 implies all{not(s.flipped),not(s.plan),s.roots},
    s.returned implies all{s.decision==2,s.observed==participants,not(s.frozen)}
  }
  action check=all{safe,s'=s}
  action step=any{freeze,reserve,acknowledge,publishPlan,flip,unknownResult,retain,cancelPrivate,
    nondet o=objects.oneOf();discover(o),closeCensus,refuse,
    nondet p=participants.oneOf();observe(p),returnRefused,s'=s}
  run layoutTest=init.then(freeze).then(completeCensus).then(reserveAt(0,0,1)).then(acknowledge)
    .then(reserveAt(1,0,4)).then(acknowledge).then(reserveAt(2,1,1))
    .then(acknowledge).then(publishPlan).then(observe(0)).then(observe(2))
    .then(observe(1)).then(flip).then(check)
  run unknownRetainTest=init.then(freeze).then(completeCensus).then(reserveAt(0,0,1)).then(unknownResult)
    .then(retain).then(check)
  run cancellationTest=init.then(cancelPrivate).then(check)
  run refusalDeliveryTest=init.then(freeze).then(discover(0)).then(refuse)
    .then(observe(2)).then(observe(0)).then(observe(1)).then(returnRefused)
    .expect(safe and s.returned and s.roots and not(s.flipped))
  run duplicateCensusTest=init.then(freeze).then(discover(0)).then(discover(0))
    .then(discover(1)).then(discover(2)).then(closeCensus)
    .expect(safe and s.census.size()==3)
  run earlyReturnControlTest=init.then(freeze).then(refuse).then(observe(0))
    .then(all{s'={...s,returned:true,frozen:false}}).expect(not(safe))
  run incompleteCensusControlTest=init.then(freeze).then(discover(0))
    .then(all{s'={...s,censusClosed:true}}).expect(not(safe))
  run splitDecisionControlTest=init.then(freeze).then(completeCensus)
    .then(reserveAt(0,0,1)).then(acknowledge).then(reserveAt(1,0,4))
    .then(acknowledge).then(reserveAt(2,1,1)).then(acknowledge)
    .then(publishPlan).then(observe(0)).then(all{s'={...s,flipped:true}})
    .expect(not(safe))
  run unknownSourceReleaseControlTest=init.then(freeze).then(completeCensus)
    .then(reserveAt(0,0,1)).then(unknownResult)
    .then(all{s'={...s,roots:false}}).expect(not(safe))
  action badFlipPending={s'={...empty,flipped:true}}
  action badRefundSection={s'={...empty,active:0,cancelled:3,sectionWaste:0}}
  action badOverlap={s'={...empty,positions:Set({object:0,region:0,begin:1,past:4},
    {object:1,region:0,begin:2,past:4}),reserved:Set(0,1)}}
  action badUnknownFlip={s'={...empty,unknown:true,flipped:true}}
}

// Actual online allocator refinement of a pre-flip capacity certificate.
// The earlier module models a concrete offline placement witness. This module
// owns a different duty: a sealed physical PREFIX plus private online grants.
// It does not repeat forwarding/Tail histories (copy_custody) or prove the
// integer bound (RoundCapacity.lean). Unique successful source requests and
// immutable census input are explicit premises of grant().
module copy_pool {
  pure val roots=Set(0,1,2)
  pure val objects=Set(0,1,2,3)
  pure def objectSize(o:int):int=if(o==0)3 else if(o==1)2 else if(o==2)9 else 4
  pure val smallCapacity=7 // H12 - execution fudge2 - first/terminal links3
  pure val fullCapacity=9 // H12 - first/terminal links3
  pure val chunk=3
  pure val smallWords=9
  pure val smallMax=4
  pure val large=1
  pure val budget=smallWords+smallWords/chunk
  pure val gain=smallCapacity-smallMax+1
  pure def closed(b:int,g:int,c:int):int=if(b/g<2*b/c)b/g else 2*b/c
  pure def needed(w:int):int=w+2*large+closed(budget,gain,smallCapacity)
  type Pool={workers:int,sections:int,decision:int,seen:Set[int],flipped:bool,
    census:bool,done:Set[int],next:int,tip:int->int,chunkStart:int->int,
    big:Set[int],finished:Set[int],unknown:bool,retained:bool,returned:bool}
  pure def fresh(w:int,n:int):Pool={workers:w,sections:n,decision:0,seen:Set(),flipped:false,
    census:false,done:Set(),next:w,tip:Map(0->0,1->0,2->0),
    chunkStart:Map(0->0,1->0,2->0),big:Set(),finished:Set(),
    unknown:false,retained:false,returned:false}
  var p:Pool
  action init={nondet w=Set(1,2,3).oneOf();nondet n=Set(8,9,10,11).oneOf();p'=fresh(w,n)}
  action census=all{not(p.census),p.decision==0,p'={...p,census:true}}
  action decide=all{p.census,p.decision==0,not(p.unknown),
    p'={...p,decision:if(roots.size()+needed(p.workers)<=p.sections)1 else 2}}
  action observe(i:int):bool=all{i.in(roots),p.decision>0,
    p'={...p,seen:p.seen.union(Set(i))}}
  action flip=all{p.decision==1,p.seen==roots,not(p.unknown),p'={...p,flipped:true}}
  action refuse=all{p.decision==2,p.seen==roots,not(p.unknown),not(p.flipped),
    p'={...p,returned:true}}
  action grant(w:int,o:int):bool={
    val words=objectSize(o);
    val limit=if(p.big.contains(w))fullCapacity else smallCapacity;
    val refill=(words>smallCapacity and not(p.big.contains(w))) or p.tip.get(w)+words>limit;
    val big=if(refill)words>smallCapacity else p.big.contains(w);
    val base=if(refill)0 else p.tip.get(w);
    val start=if(refill)0 else p.chunkStart.get(w);
    val close=base+words-start>=chunk;
    val end=base+words+(if(close)1 else 0);
    all{p.flipped,not(p.unknown),w>=0,w<p.workers,o.in(objects),not(p.done.contains(o)),
      not(p.finished.contains(w)),
      p'={...p,done:p.done.union(Set(o)),next:p.next+(if(refill)1 else 0),
        tip:p.tip.set(w,end),chunkStart:p.chunkStart.set(w,if(close)end else start),
        big:if(big)p.big.union(Set(w))else p.big.exclude(Set(w))}}}
  action finish(w:int):bool=all{p.flipped,p.done==objects,not(p.unknown),
    w>=0,w<p.workers,not(p.finished.contains(w)),
    p'={...p,next:p.next+(if(p.big.contains(w))1 else 0),
      tip:if(p.big.contains(w))p.tip.set(w,0)else p.tip,
      big:p.big.exclude(Set(w)),finished:p.finished.union(Set(w))}}
  action unknown=all{not(p.returned),p'={...p,unknown:true,retained:true}}
  val safe=all{
    p.next<=needed(p.workers),
    p.flipped implies (p.census and p.decision==1 and p.seen==roots),
    p.decision==1 implies roots.size()+needed(p.workers)<=p.sections,
    p.returned implies (p.decision==2 and p.seen==roots and not(p.flipped) and p.done==Set()),
    p.unknown implies (p.retained and not(p.returned)),
    0.to(p.workers-1).forall(w=>p.tip.get(w)<=(if(p.big.contains(w))fullCapacity else smallCapacity)+1),
    p.finished.forall(w=>not(p.big.contains(w)) and p.tip.get(w)<=smallCapacity+1)
  }
  action step=any{census,decide,flip,refuse,unknown,
    nondet i=roots.oneOf();observe(i),
    nondet w=0.to(p.workers-1).oneOf();nondet o=objects.oneOf();grant(w,o),
    nondet w=0.to(p.workers-1).oneOf();finish(w),p'=p}
  run nearCapacityCertificateTest=init.expect(closed(9,1,7)==2)
  run oneWorkerLargeTest=(p'=fresh(1,9)).then(census).then(decide)
    .then(observe(0)).then(observe(1)).then(observe(2)).then(flip)
    .then(grant(0,0)).then(grant(0,2)).then(grant(0,1)).then(grant(0,3)).then(finish(0))
    .expect(safe and p.done==objects and p.finished==Set(0))
  run threeWorkersLastLargeTest=(p'=fresh(3,11)).then(census).then(decide)
    .then(observe(2)).then(observe(0)).then(observe(1)).then(flip)
    .then(grant(0,0)).then(grant(1,1)).then(grant(2,3)).then(grant(0,2))
    .then(finish(0)).then(finish(1)).then(finish(2)).expect(safe and p.big==Set())
  run noHeapGrowthRefusalTest=(p'=fresh(3,8)).then(census).then(decide)
    .then(observe(0)).then(observe(2)).then(observe(1)).then(refuse)
    .expect(safe and p.returned and p.sections==8)
  run unknownCannotReplayTest=(p'=fresh(1,9)).then(census).then(unknown)
    .expect(safe and p.retained and not(p.flipped))
  run earlyFlipControlTest=(p'=fresh(1,9)).then(census).then(decide).then(observe(0))
    .then(all{p'={...p,flipped:true}}).expect(not(safe))
  run largeTailWithoutFudgeControlTest=(p'=fresh(1,9)).then(census).then(decide)
    .then(observe(0)).then(observe(1)).then(observe(2)).then(flip)
    .then(grant(0,0)).then(grant(0,1)).then(grant(0,3)).then(grant(0,2))
    .then(all{p'={...p,finished:Set(0)}}).expect(not(safe))
  run unbudgetedRefillControlTest=(p'=fresh(1,9)).then(census).then(decide)
    .then(all{p'={...p,next:needed(1)+1}}).expect(not(safe))
}
