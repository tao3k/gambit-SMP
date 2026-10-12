module gc_recursive_queue_induction {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"

  // Symbolic states, not new protocol transitions or a reachable-state sample.
  // This broad domain deliberately admits unreachable states: failed closure
  // identifies missing induction premises, not a Gambit native failure.
  action initSafetyCandidate = {
    nondet policy = Set("source", "combined").oneOf()
    nondet mode = workers.setOfMaps(Set("active", "probe", "claim-locked", "scanning",
      "probed", "recheck", "pre-wait", "waiting", "woken", "done")).oneOf()
    nondet work = objects.setOfMaps((-1).to(3)).oneOf()
    nondet owner = objects.setOfMaps((-1).to(3)).oneOf()
    nondet copied = objects.setOfMaps(0.to(2)).oneOf()
    nondet visible = objects.setOfMaps(0.to(2)).oneOf()
    nondet pub = objects.setOfMaps(0.to(5)).oneOf()
    nondet queueOf = objects.setOfMaps((-1).to(3)).oneOf()
    nondet route = objects.setOfMaps(Set("", "local", "queue")).oneOf()
    nondet queueOwner = queues.setOfMaps((-1).to(3)).oneOf()
    nondet scans = objects.setOfMaps(0.to(1)).oneOf()
    nondet target = workers.setOfMaps((-1).to(3)).oneOf()
    nondet probeIndex = workers.setOfMaps(0.to(4)).oneOf()
    nondet remaining = workers.setOfMaps(queues.powerset()).oneOf()
    nondet found = workers.setOfMaps(Set(false, true)).oneOf()
    nondet headDone = objects.powerset().oneOf()
    nondet tailDone = objects.powerset().oneOf()
    nondet headVisits = objects.setOfMaps(0.to(1)).oneOf()
    nondet mutex = (-1).to(3).oneOf()
    nondet count = 0.to(4).oneOf()
    nondet spuriousUsed = workers.powerset().oneOf()
    nondet terminated = Set(false, true).oneOf()
    val candidate = { policy: policy, fault: "none", mode: mode, work: work, owner: owner,
      copied: copied, visible: visible, pub: pub, queueOf: queueOf, route: route,
      queueOwner: queueOwner, scans: scans, target: target, probeIndex: probeIndex,
      remaining: remaining, found: found, headDone: headDone, tailDone: tailDone,
      headVisits: headVisits, foreignHeadWrite: false, mutex: mutex, count: count,
      spuriousUsed: spuriousUsed, staleRead: false, terminated: terminated }
    all { safeOf(candidate), s' = candidate }
  }

  // The closure target must include the entire generated domain; a real step
  // leaving a bound is a failure, not a successor silently filtered away.
  val shape = s.policy.in(Set("source", "combined")) and s.fault == "none" and
    s.mode.keys() == workers and workers.forall(w => s.mode.get(w).in(Set("active", "probe",
      "claim-locked", "scanning", "probed", "recheck", "pre-wait", "waiting", "woken", "done"))) and
    s.work.keys() == objects and objects.forall(o => s.work.get(o).in((-1).to(3))) and
    s.owner.keys() == objects and objects.forall(o => s.owner.get(o).in((-1).to(3))) and
    s.copied.keys() == objects and objects.forall(o => s.copied.get(o).in(0.to(2))) and
    s.visible.keys() == objects and objects.forall(o => s.visible.get(o).in(0.to(2))) and
    s.pub.keys() == objects and objects.forall(o => s.pub.get(o).in(0.to(5))) and
    s.queueOf.keys() == objects and objects.forall(o => s.queueOf.get(o).in((-1).to(3))) and
    s.route.keys() == objects and objects.forall(o => s.route.get(o).in(Set("", "local", "queue"))) and
    s.queueOwner.keys() == queues and queues.forall(q => s.queueOwner.get(q).in((-1).to(3))) and
    s.scans.keys() == objects and objects.forall(o => s.scans.get(o).in(0.to(1))) and
    s.target.keys() == workers and workers.forall(w => s.target.get(w).in((-1).to(3))) and
    s.probeIndex.keys() == workers and workers.forall(w => s.probeIndex.get(w).in(0.to(4))) and
    s.remaining.keys() == workers and workers.forall(w => s.remaining.get(w).subseteq(queues)) and
    s.found.keys() == workers and s.headDone.subseteq(objects) and s.tailDone.subseteq(objects) and
    s.headVisits.keys() == objects and objects.forall(o => s.headVisits.get(o).in(0.to(1))) and
    s.mutex.in((-1).to(3)) and s.count.in(0.to(4)) and s.spuriousUsed.subseteq(workers) and
    not(s.foreignHeadWrite) and not(s.staleRead)
  val candidateInvariant = shape and safe
}
