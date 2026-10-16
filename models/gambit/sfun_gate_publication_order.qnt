module sfun_gate_publication_order {
  import foreign_origin_retirement_admission as A from "./foreign_origin_retirement_admission"
  // Reuse the lifecycle/rollback model. Split its publish into the two actual
  // atomic updates; phase 7 holds a published lease and temporary gate reader.
  var policy: int
  action init = all { A::init, policy'=0 }
  action initEarlyRelease = all {
    A::s'=A::initial("origin-gate",1,0,0,0), policy'=1 }
  action initMissingCount = all {
    A::s'=A::initial("origin-gate",1,0,0,0), policy'=2 }
  action initDoubleGateRelease = all {
    A::s'=A::initial("origin-gate",1,0,0,0), policy'=3 }

  action publishCount(t: int): bool = all {
    A::s.call.get(t)==2,
    if (not(A::s.alive.contains(A::s.origin.get(t))) or
        A::s.captured.get(t)!=A::s.generation.get(A::s.origin.get(t)))
      A::publish(t)
    else if (policy==1)
      A::s'={ ...A::s, gate:A::s.gate-2, call:A::s.call.set(t,8) }
    else
      A::s'={ ...A::s, call:A::s.call.set(t,7),
        count:if (policy==2) A::s.count else
          A::s.count.set(A::s.origin.get(t),A::s.count.get(A::s.origin.get(t))+1) },
    policy'=policy
  }
  action releaseGate(t: int): bool = all {
    A::s.call.get(t)==7,
    A::s'={ ...A::s, call:A::s.call.set(t,3),
      gate:A::s.gate-(if (policy==3) 4 else 2) }, policy'=policy
  }
  // Negative control: the closer can inspect zero between these two writes.
  action lateCount(t: int): bool = all {
    A::s.call.get(t)==8,
    A::s'={ ...A::s, call:A::s.call.set(t,3),
      count:A::s.count.set(A::s.origin.get(t),A::s.count.get(A::s.origin.get(t))+1) },
    policy'=policy
  }
  action callStep = {
    nondet t=A::tokens.oneOf()
    any {
      all { any { A::lookup(t), A::reserve(t), A::allocate(t), A::outcome(t), A::release(t) }, policy'=policy },
      publishCount(t), releaseGate(t), lateCount(t)
    }
  }
  action lifecycleStep = all {
    any { A::close, A::inspect, A::retire, A::reuse, A::finished }, policy'=policy
  }
  action step = any { callStep, lifecycleStep }

  val published=A::tokens.filter(t=>A::s.call.get(t)==7)
  val reservations=A::tokens.filter(t=>Set(2,7).contains(A::s.call.get(t)))
  val physicalHolders=A::holders.union(published)
  val countExact=Set(0,1).forall(p=>
    A::s.count.get(p)==physicalHolders.filter(t=>A::s.origin.get(t)==p).size())
  val gateExact=A::s.gate/2==reservations.size() and A::s.gate>=0
  val originAlive=physicalHolders.union(A::tokens.filter(t=>A::s.call.get(t)==8))
    .forall(t=>A::s.alive.contains(A::s.origin.get(t)) and
      A::s.captured.get(t)==A::s.generation.get(A::s.origin.get(t)))
  // The abstract old model commits publication at gate release. Subtract the
  // intermediate visible count to obtain its unchanged holder population.
  val abstractCountExact=Set(0,1).forall(p=>
    A::s.count.get(p)-published.filter(t=>A::s.origin.get(t)==p).size()
      ==A::holders.filter(t=>A::s.origin.get(t)==p).size())
  val safe=countExact and gateExact and originAlive and abstractCountExact and
    A::closedPublication and A::markerOwned and not(A::s.badRelease) and not(A::s.badRejection)

  action observe = all { A::s'=A::s, policy'=policy }
  run reservedCloseBusyTest = (all { A::s'=A::initial("origin-gate",1,0,0,0),policy'=0 })
    .then(all { A::lookup(0),policy'=policy })
    .then(all { A::reserve(0),policy'=policy }).then(publishCount(0))
    .then(all { A::close,policy'=policy })
    .then(all { assert(safe),assert(A::s.phase=="busy"),observe })
  run publishedCloseBusyTest = (all { A::s'=A::initial("origin-gate",1,0,0,0),policy'=0 })
    .then(all { A::lookup(0),policy'=policy })
    .then(all { A::reserve(0),policy'=policy }).then(publishCount(0)).then(releaseGate(0))
    .then(all { A::close,policy'=policy }).then(all { A::inspect,policy'=policy })
    .then(all { assert(safe),assert(A::s.phase=="busy"),observe })
}
