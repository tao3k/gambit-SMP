// Two bounded origins abstract all fixed VM slots; addresses stand for moved roots.
// This is finite safety, not C memory order, arbitrary owner death or GC fairness.
module resize_sources {
  type S={phase:int->int,serial:int->int,root:int->bool,address:int->int,
    token:int->int,transport:int->bool,loaded:int->int,member:int->bool,
    frozen:bool,selected:int,epoch:int,rejected:int}
  var s:S
  pure val ids=Set(0,1)
  pure val empty:S={phase:ids.mapBy(i=>0),serial:ids.mapBy(i=>0),
    root:ids.mapBy(i=>false),address:ids.mapBy(i=>0),token:ids.mapBy(i=>0),
    transport:ids.mapBy(i=>false),loaded:ids.mapBy(i=>0),member:ids.mapBy(i=>true),
    frozen:false,selected:-1,epoch:0,rejected:0}
  action init={s'=empty}
  action register(i:int):bool=all{not(s.frozen),s.member.get(i),s.phase.get(i)==0,s.serial.get(i)<3,
    s'={...s,phase:s.phase.set(i,1),serial:s.serial.set(i,s.serial.get(i)+1),
      root:s.root.set(i,true),address:s.address.set(i,s.epoch),
      token:s.token.set(i,2*(s.serial.get(i)+1)+i),transport:s.transport.set(i,true)}}
  action freeze=all{not(s.frozen),s'={...s,frozen:true}}
  action collect=all{s.frozen,s'={...s,epoch:s.epoch+1,
    address:ids.mapBy(i=>if(s.root.get(i))s.epoch+1 else s.address.get(i)),
    loaded:ids.mapBy(i=>if(s.phase.get(i)==3)s.epoch+1 else s.loaded.get(i))}}
  action thaw=all{s.frozen,s'={...s,frozen:false}}
  action selectRequest(i:int):bool=all{not(s.frozen),s.selected== -1,s.phase.get(i)==1,
    s.token.get(i)==2*s.serial.get(i)+i,
    s'={...s,selected:i,phase:s.phase.set(i,2)}}
  action reload=all{s.selected>=0,s.phase.get(s.selected)==2,
    s'={...s,phase:s.phase.set(s.selected,3),
      loaded:s.loaded.set(s.selected,s.address.get(s.selected))}}
  action complete=all{s.selected>=0,s.phase.get(s.selected)==3,
    s'={...s,phase:s.phase.set(s.selected,4),selected:-1}}
  action drain=all{s.selected== -1,
    s'={...s,transport:ids.mapBy(i=>if(s.phase.get(i)==4)false else s.transport.get(i))}}
  action ack(i:int):bool=all{not(s.frozen),s.phase.get(i)==4,not(s.transport.get(i)),
    s'={...s,phase:s.phase.set(i,0),root:s.root.set(i,false)}}
  action unknown(i:int):bool=all{s.phase.get(i).in(Set(1,2)),
    s'={...s,phase:s.phase.set(i,5),selected:if(s.selected==i)-1 else s.selected}}
  action retire(i:int):bool=all{s.phase.get(i)==0,s'={...s,member:s.member.set(i,false)}}
  action rejectReentry(i:int):bool=all{s.phase.get(i)!=0,s'={...s,rejected:s.rejected+1}}
  action rejectLate(i:int):bool=all{s.serial.get(i)>1,s'={...s,rejected:s.rejected+1}}
  val safe=all{
    ids.forall(i=>s.phase.get(i)!=0 implies s.root.get(i)),
    ids.forall(i=>s.transport.get(i) implies s.root.get(i)),
    ids.forall(i=>s.phase.get(i)==3 implies s.loaded.get(i)==s.address.get(i)),
    ids.forall(i=>s.root.get(i) implies s.address.get(i)==s.epoch),
    ids.forall(i=>not(s.member.get(i)) implies s.phase.get(i)==0),
    ids.forall(i=>s.serial.get(i)<=3),
    ids.forall(i=>s.phase.get(i)!=0 implies s.token.get(i)==2*s.serial.get(i)+i)
  }
  action check=all{safe,s'=s}
  action step=any{register(0),register(1),freeze,collect,thaw,selectRequest(0),selectRequest(1),
    reload,complete,drain,ack(0),ack(1),unknown(0),unknown(1),
    retire(0),retire(1),rejectReentry(0),rejectReentry(1),rejectLate(0),rejectLate(1),s'=s}
  run competingGCTest=init.then(register(0)).then(register(1)).then(freeze)
    .then(collect).then(thaw).then(selectRequest(0)).then(reload).then(complete)
    .then(selectRequest(1)).then(reload).then(complete).then(drain).then(ack(0)).then(ack(1)).then(check)
  run nestedRejectTest=init.then(register(0)).then(rejectReentry(0)).then(check)
  run unknownKeepsRootTest=init.then(register(1)).then(unknown(1)).then(freeze).then(collect).then(thaw).then(check)
  run reuseRejectsLateTest=init.then(register(0)).then(selectRequest(0)).then(reload)
    .then(complete).then(drain).then(ack(0)).then(register(0)).then(rejectLate(0)).then(check)
  run ledgerMovesTest=init.then(register(0)).then(selectRequest(0)).then(reload)
    .then(freeze).then(collect).then(thaw).then(complete).then(drain).then(ack(0)).then(check)
  action badDrop={s'={...empty,phase:empty.phase.set(0,5),serial:empty.serial.set(0,1),token:empty.token.set(0,2)}}
  action badStaleCopy={s'={...empty,epoch:1,phase:empty.phase.set(0,3),root:empty.root.set(0,true),address:empty.address.set(0,1),serial:empty.serial.set(0,1),token:empty.token.set(0,2)}}
  action badRetire={s'={...empty,phase:empty.phase.set(0,1),root:empty.root.set(0,true),member:empty.member.set(0,false),serial:empty.serial.set(0,1),token:empty.token.set(0,2)}}
  action badEarlyAck={s'={...empty,transport:empty.transport.set(0,true)}}
  action badWrap={s'={...empty,serial:empty.serial.set(0,4)}}
}
