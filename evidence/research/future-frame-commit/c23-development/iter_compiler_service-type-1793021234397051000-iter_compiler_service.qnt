module iter_compiler_service {
  import iter_compiler_parameters.* from "./iter_compiler_parameters"
  pure val C = 0.to(ConsumerCount-1)
  type State = { epoch: int, support: int, binding: int, interfaceReady: bool, supportReady: bool,
    stage: int->int, observed: int->int, born: int->int, owner: int->int, generation: int->int,
    token: int->int, ctx: int->int, status: int->int, roots: Set[int], cpu: Set[int],
    detached: Set[int], published: Set[int], sealed: Set[int], settled: Set[int], sequenceSeen: Set[int],
    guardChanged: bool, forbiddenTouched: bool }
  pure val initial: State = { epoch:0,support:0,binding:0,interfaceReady:false,supportReady:false,
    stage:C.mapBy(_=>0),observed:C.mapBy(_=>-1),born:C.mapBy(_=>-1),owner:C.mapBy(_=>-1),
    generation:C.mapBy(_=>0),token:C.mapBy(_=>-1),ctx:C.mapBy(_=>-1),status:C.mapBy(_=>0),
    roots:Set(),cpu:Set(),detached:Set(),published:Set(),sealed:Set(),settled:Set(),sequenceSeen:Set(),
    guardChanged:false,forbiddenTouched:false }
  var s: State
  action init = s'=initial
    action interfaceComplete = all { not(s.interfaceReady),s'={...s,interfaceReady:true} }
  action supportComplete = all { s.interfaceReady,not(s.supportReady),s'={...s,supportReady:true} }
  action scheme(n) = all { s.interfaceReady,s.supportReady,s.stage.get(n)==0,
    s'={...s,stage:s.stage.set(n,1),observed:s.observed.set(n,s.support),born:s.born.set(n,s.epoch)} }
  def live(n) = s.ctx.get(n)>=0 and s.owner.get(s.ctx.get(n))==n and
    s.generation.get(s.ctx.get(n))==s.token.get(n)
  action acquire(n,k) = all { s.stage.get(n)>=1,s.stage.get(n)<LastStage,s.status.get(n)==0,
    s.owner.get(k)==-1,s.born.get(n)==s.epoch,s.cpu.size()<Capacity,
    s'={...s,owner:s.owner.set(k,n),generation:s.generation.set(k,s.generation.get(k)+1),
      ctx:s.ctx.set(n,k),token:s.token.set(n,s.generation.get(k)+1),status:s.status.set(n,1),
      roots:s.roots.union(Set(n)),cpu:s.cpu.union(Set(n))} }
  def canAdvance(n) = s.status.get(n)==1 and s.cpu.contains(n) and live(n) and
    s.stage.get(n)<LastStage and s.born.get(n)==s.epoch and s.observed.get(n)==s.support
  action advance(n) = all { canAdvance(n), s'={...s,stage:s.stage.set(n,s.stage.get(n)+1)} }
  action pause(n) = all { s.status.get(n)==1,live(n),s'={...s,status:s.status.set(n,2),cpu:s.cpu.exclude(Set(n))} }
  def canResume(n,t) = s.status.get(n)==2 and live(n) and t==s.token.get(n) and
    s.born.get(n)==s.epoch and s.cpu.size()<Capacity
  action resume(n,t) = all { canResume(n,t),s'={...s,status:s.status.set(n,1),cpu:s.cpu.union(Set(n))} }
  action seal(n) = all { s.status.get(n)==1,live(n),s.stage.get(n)==LastStage,
    s.born.get(n)==s.epoch,s.observed.get(n)==s.support,s'={...s,detached:s.detached.union(Set(n))} }
  action close(n) = all { s.status.get(n)==1,live(n),s.detached.contains(n),
    s'={...s,owner:s.owner.set(s.ctx.get(n),-1),status:s.status.set(n,4),roots:s.roots.exclude(Set(n)),cpu:s.cpu.exclude(Set(n))} }
  action failAttempt(n) = all { Set(1,2).contains(s.status.get(n)),live(n),
    s'={...s,status:s.status.set(n,3),cpu:s.cpu.exclude(Set(n))} }
  action unknownOutcome(n) = all { Set(1,2).contains(s.status.get(n)),live(n),
    s'={...s,status:s.status.set(n,6),cpu:s.cpu.exclude(Set(n))} }
  action settle(n) = all { s.status.get(n)==3,live(n),s'={...s,settled:s.settled.union(Set(n))} }
  action acknowledge(n) = all { s.status.get(n)==6,live(n),s'={...s,status:s.status.set(n,3),settled:s.settled.union(Set(n))} }
  action drain(n) = all { s.status.get(n)==3,live(n),s.settled.contains(n),
    s'={...s,owner:s.owner.set(s.ctx.get(n),-1),status:s.status.set(n,5),roots:s.roots.exclude(Set(n))} }
  def canPublish(n) = s.status.get(n)==4 and s.detached.contains(n) and s.stage.get(n)==LastStage and
    s.born.get(n)==s.epoch and s.observed.get(n)==s.support
  action publish(n) = all { canPublish(n),s'={...s,published:s.published.union(Set(n)),sealed:s.sealed.union(Set(n))} }
  action editSupport = all { s.epoch==0,s'={...s,epoch:1,support:1,published:Set(),sealed:Set()} }
  action sequenceFirst = all { not(s.sequenceSeen.contains(0)),s'={...s,sequenceSeen:s.sequenceSeen.union(Set(0)),guardChanged:true} }
  action sequenceSecond = all { s.sequenceSeen.contains(0),not(s.guardChanged),s'={...s,sequenceSeen:s.sequenceSeen.union(Set(1))} }
  def safe = s.cpu.size()<=Capacity and C.forall(n=>
    (Set(1,2,3,6).contains(s.status.get(n)) implies live(n) and s.roots.contains(n)) and
    (s.published.contains(n) implies s.sealed.contains(n) and canPublish(n))) and
    not(s.forbiddenTouched)
  action step = {
    nondet n=C.oneOf()
    nondet k=C.oneOf()
    any {interfaceComplete,supportComplete,scheme(n),acquire(n,k),advance(n),pause(n),resume(n,s.token.get(n)),
      seal(n),close(n),failAttempt(n),settle(n),unknownOutcome(n),acknowledge(n),drain(n),publish(n),editSupport,sequenceFirst,sequenceSecond,s'=s}
  }
  action borrowBusy(n,k) = s'={...s,owner:s.owner.set(k,n),ctx:s.ctx.set(n,k),token:s.token.set(n,s.generation.get(k)),status:s.status.set(n,1),roots:s.roots.union(Set(n))}
  action dropRoots(n) = s'={...s,roots:s.roots.exclude(Set(n))}
  action publishEarly(n) = s'={...s,published:s.published.union(Set(n))}
  action unorderedSecond = s'={...s,sequenceSeen:s.sequenceSeen.union(Set(1)),forbiddenTouched:true}
  run interfaceNotSupportTest = init.then(interfaceComplete).expect(safe and not(s.supportReady) and s.stage.get(0)==0)
  run distinctContextsTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(scheme(1)).then(acquire(0,0)).then(acquire(1,1)).expect(safe and s.cpu.size()==2 and s.ctx.get(0)!=s.ctx.get(1))
  run orderedStagesTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(advance(0)).then(advance(0)).then(advance(0)).then(seal(0)).then(close(0)).then(publish(0)).expect(safe and s.published.contains(0))
  run suspensionRetainsTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(pause(0)).expect(safe and s.roots.contains(0) and not(s.cpu.contains(0)) and live(0))
  run resumeTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(pause(0)).then(resume(0,1)).expect(safe and s.cpu.contains(0) and not(canResume(0,1)))
  run failedDrainTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(failAttempt(0)).then(settle(0)).then(drain(0)).expect(safe and s.owner.get(0)==-1 and not(s.roots.contains(0)) and not(canPublish(0)))
  run epochRejectTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(editSupport).expect(safe and not(canAdvance(0)) and not(canPublish(0)))
  run contextReuseGenerationTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(scheme(1)).then(acquire(0,0)).then(failAttempt(0)).then(settle(0)).then(drain(0)).then(acquire(1,0)).then(pause(1)).expect(safe and s.token.get(1)==2 and not(canResume(1,1)))
  run sequentialCutoffTest = init.then(sequenceFirst).expect(safe and not(s.sequenceSeen.contains(1)))
  run macroSignatureStableTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(editSupport).expect(safe and s.binding==0 and s.observed.get(0)!=s.support)
  run duplicateContextControlTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(scheme(1)).then(acquire(0,0)).then(borrowBusy(1,0)).expect(not(safe))
  run prematureRootDropControlTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(pause(0)).then(dropRoots(0)).expect(not(safe))
  run partialPublishControlTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(publishEarly(0)).expect(not(safe))
  run stalePublishControlTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(advance(0)).then(advance(0)).then(advance(0)).then(seal(0)).then(close(0)).then(editSupport).then(publishEarly(0)).expect(not(safe))
  run failedPublishControlTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(failAttempt(0)).then(settle(0)).then(drain(0)).then(publishEarly(0)).expect(not(safe))
  run unorderedProbeControlTest = init.then(unorderedSecond).expect(not(safe))
  run unknownRetainsTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(unknownOutcome(0)).expect(safe and s.roots.contains(0) and live(0) and not(s.settled.contains(0)) and not(canPublish(0)))
  run unknownSettlesTest = init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(acquire(0,0)).then(unknownOutcome(0)).then(acknowledge(0)).then(drain(0)).expect(safe and s.owner.get(0)==-1 and not(s.roots.contains(0)))
}
