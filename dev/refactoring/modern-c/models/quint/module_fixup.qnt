module module_fixup {
  // Only the new shared fixup protocol. Owner/winner are ghost call identities,
  // not proposed C fields or an identity registry. Existing entry/unload models
  // retain their separate lifetime duties; Lean representation laws are reused.
  type State = {phase:int, owner:int, winner:int, published:bool,
                retained:bool, refused:Set[int]}
  var s:State
  pure val initial:State = {phase:0,owner:-1,winner:-1,published:false,
                            retained:false,refused:Set()}
  action init = s'=initial
  val safe = all {
    s.phase>=0, s.phase<=3,
    s.phase==0 implies (s.owner == -1 and s.winner == -1),
    s.phase>0 implies (s.owner==s.winner and Set(0,1).contains(s.owner)),
    s.published implies s.phase==2,
    s.retained implies (s.phase==1 and not(s.published))
  }
  action claim(actor:int):bool = all {s.phase==0,
    s'={...s,phase:1,owner:actor,winner:actor}}
  action reject(actor:int):bool = all {s.phase==1 or s.phase==3,
    s'={...s,refused:s.refused.union(Set(actor))}}
  action complete(actor:int):bool = all {s.phase==1,s.owner==actor,not(s.retained),
    s'={...s,phase:2}}
  action refuseFixup(actor:int):bool = all {s.phase==1,s.owner==actor,not(s.retained),
    s'={...s,phase:3}}
  action unknown = all {s.phase==1,s'={...s,retained:true}}
  action publish = all {s.phase==2,s'={...s,published:true}}
  action step = any {claim(0),claim(1),reject(0),reject(1),complete(0),
    complete(1),refuseFixup(0),refuseFixup(1),unknown,publish,all {s'=s}}
  run readyTest = init.then(claim(0)).then(complete(0)).then(publish)
    .then(all {assert(safe and s.published),s'=s})
  run competingTest = init.then(claim(0)).then(reject(1)).then(complete(0))
    .then(publish).then(all {assert(safe and s.refused.contains(1)),s'=s})
  run failedTest = init.then(claim(1)).then(refuseFixup(1)).then(reject(0))
    .then(all {assert(safe and not(s.published) and s.phase==3),s'=s})
  run unknownTest = init.then(claim(0)).then(unknown).then(reject(1))
    .then(all {assert(safe and s.retained and not(s.published)),s'=s})
  // Counterexamples preserve the old early-DONE and stolen-owner mistakes.
  run earlyDoneControlTest = init.then(claim(0))
    .then(all {s'={...s,published:true}})
    .then(all {assert(not(safe)),s'=s})
  run stolenOwnerControlTest = init.then(claim(0))
    .then(all {s'={...s,owner:1}})
    .then(all {assert(not(safe)),s'=s})
}
