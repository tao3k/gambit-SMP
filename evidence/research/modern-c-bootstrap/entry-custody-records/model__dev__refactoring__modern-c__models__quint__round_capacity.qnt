// Target pre-flip layout. Current C per-copy allocation does not implement it.
module round_capacity {
  type Placement={object:int,region:int,begin:int,past:int}
  pure val objects=Set(0,1,2)
  pure def objectWords(o:int):int=if(o==0)3 else if(o==1)2 else 4
  type S={frozen:bool,positions:Set[Placement],reserved:Set[int],ack:Set[int],
    plan:bool,flipped:bool,unknown:bool,retained:bool,roots:bool,
    active:int,cancelled:int,sectionWaste:int}
  var s:S
  pure val empty:S={frozen:false,positions:Set(),reserved:Set(),ack:Set(),plan:false,
    flipped:false,unknown:false,retained:false,roots:true,active:3,cancelled:0,sectionWaste:2}
  pure def disjoint(a:Placement,b:Placement):bool=
    a.region!=b.region or a.begin>=b.past or b.begin>=a.past
  action init={s'=empty}
  action freeze=all{not(s.frozen),s'={...s,frozen:true}}
  action reserveAt(o:int,r:int,b:int):bool={
    val p:Placement={object:o,region:r,begin:b,past:b+objectWords(o)};
    all{s.frozen,not(s.plan),not(s.unknown),
    not(o.in(s.reserved)),o.in(objects),r.in(Set(0,1)),b>=1,
    p.past<=6, // each 8-word region retains link word + two terminal words
    r==1 implies p.past<=5, // restoration [5,6) in region 1 is not copy space
    s.positions.forall(old=>disjoint(p,old)),
    s'={...s,positions:s.positions.union(Set(p)),reserved:s.reserved.union(Set(o))}}}
  action reserve={nondet o=objects.oneOf();nondet r=Set(0,1).oneOf();
    nondet b=1.to(5).oneOf();reserveAt(o,r,b)}
  action acknowledge=all{s.reserved!=s.ack,not(s.unknown),
    nondet o=s.reserved.exclude(s.ack).oneOf();s'={...s,ack:s.ack.union(Set(o))}}
  action publishPlan=all{s.frozen,s.reserved==objects,s.ack==objects,not(s.unknown),
    s'={...s,plan:true}}
  action flip=all{s.plan,not(s.unknown),s'={...s,flipped:true}}
  action unknownResult=all{not(s.plan),s.reserved!=Set(),s'={...s,unknown:true}}
  action retain=all{s.unknown,not(s.flipped),s'={...s,retained:true}}
  action cancelPrivate=all{s.active>0,s'={...s,cancelled:s.cancelled+s.active,active:0}}
  val safe=all{
    s.positions.forall(p=>all{p.begin>=1,p.past<=6,p.past-p.begin==objectWords(p.object),
      p.region==1 implies p.past<=5}),
    s.positions.forall(a=>s.positions.forall(b=>a==b or disjoint(a,b))),
    s.positions.size()==s.reserved.size(),s.ack.subseteq(s.reserved),
    s.plan implies all{s.frozen,s.reserved==objects,s.ack==objects,not(s.unknown)},
    s.flipped implies s.plan,
    s.unknown implies all{s.roots,not(s.flipped)},
    s.active+s.cancelled==3,s.sectionWaste==2
  }
  action check=all{safe,s'=s}
  action step=any{freeze,reserve,acknowledge,publishPlan,flip,unknownResult,retain,cancelPrivate,s'=s}
  run layoutTest=init.then(freeze).then(reserveAt(0,0,1)).then(acknowledge)
    .then(reserveAt(1,0,4)).then(acknowledge).then(reserveAt(2,1,1))
    .then(acknowledge).then(publishPlan).then(flip).then(check)
  run unknownRetainTest=init.then(freeze).then(reserveAt(0,0,1)).then(unknownResult)
    .then(retain).then(check)
  run cancellationTest=init.then(cancelPrivate).then(check)
  action badFlipPending={s'={...empty,flipped:true}}
  action badRefundSection={s'={...empty,active:0,cancelled:3,sectionWaste:0}}
  action badOverlap={s'={...empty,positions:Set({object:0,region:0,begin:1,past:4},
    {object:1,region:0,begin:2,past:4}),reserved:Set(0,1)}}
  action badUnknownFlip={s'={...empty,unknown:true,flipped:true}}
}
