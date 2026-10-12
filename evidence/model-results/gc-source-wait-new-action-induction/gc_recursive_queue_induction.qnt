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
    all { safeOf(candidate), discoveryShapeOf(candidate), lockShapeOf(candidate),
      phaseShapeOf(candidate), s' = candidate }
  }

  // Derived from the original discovery/copy/claim transitions. These are
  // induction premises to prove closed, not extra guards on the real step.
  pure def discoveryShapeOf(st: State): bool =
    st.work.get(0) != -1 and st.work.get(2) != -1 and
    objects.forall(o => and {
      (st.work.get(o) == -1).implies(and { st.owner.get(o) == -1,
        st.copied.get(o) == 0, st.visible.get(o) == 0, st.pub.get(o) == 0,
        st.scans.get(o) == 0, not(st.headDone.contains(o)), not(st.tailDone.contains(o)),
        st.route.get(o) == "", st.queueOf.get(o) == -1 }),
      (st.work.get(o) >= 0 and st.work.get(o) < 3).implies(workers.contains(st.owner.get(o))),
      (st.work.get(o) >= 1).implies(st.copied.get(o) == 2),
      (st.work.get(o) <= 1).implies(st.scans.get(o) == 0),
      (st.work.get(o) >= 2).implies(st.scans.get(o) == 1),
      st.headDone.contains(o).implies(st.copied.get(o) == 2 and st.work.get(o) >= 0),
      (st.headDone.contains(o) or st.tailDone.contains(o)).implies(st.work.get(edge.get(o)) != -1),
      (st.headVisits.get(o) == 1) == st.headDone.contains(o),
      st.tailDone.contains(o).implies(st.work.get(o) >= 2),
      (st.work.get(o) == 3).implies(st.tailDone.contains(o)),
      (st.work.get(o) == 3).implies(st.queueOf.get(o) == -1),
      (st.work.get(o) == 3 and (st.pub.get(o) == 0 or st.pub.get(o) == 5))
        .implies(st.pub.get(o) == 0 and st.queueOf.get(o) == -1 and st.visible.get(o) == 0),
      (st.work.get(o) == 3 and st.pub.get(o) == 0 and st.headDone.contains(o))
        .implies(st.owner.get(o) == -1),
      (st.pub.get(o) == 1).implies(st.work.get(o) == 0 and st.copied.get(o) == 2),
      (st.pub.get(o) == 2).implies(st.work.get(o) == 1),
      (st.pub.get(o) >= 3).implies(st.work.get(o) >= 1),
      (st.work.get(o) == 1).implies(st.pub.get(o) >= 2 and st.visible.get(o) == 2),
      (st.work.get(o) < 2 or st.work.get(o) == 3).implies(st.route.get(o) == ""),
      (st.work.get(o) == 2).implies(st.route.get(o).in(Set("local", "queue"))),
      (st.pub.get(o) > 0 and st.work.get(o) < 3).implies(st.queueOf.get(o) == st.owner.get(o)),
      (st.policy == "source").implies(st.pub.get(o) != 4)
    }) and workers.forall(w => and {
      (st.mode.get(w) == "scanning").implies(objects.contains(st.target.get(w)) and
        st.work.get(st.target.get(w)) == 2),
      (st.mode.get(w) == "claim-locked").implies(objects.contains(st.target.get(w)) and
        st.work.get(st.target.get(w)) == 1),
      (st.mode.get(w) != "scanning" and st.mode.get(w) != "claim-locked").implies(st.target.get(w) == -1),
      (st.mode.get(w) == "done").implies(st.terminated)
    })

  pure def lockShapeOf(st: State): bool = queues.forall(q => {
    val publishing = objects.filter(o => (st.pub.get(o) == 1 or st.pub.get(o) == 2) and
      st.queueOf.get(o) == q)
    val claiming = workers.filter(w => st.mode.get(w) == "claim-locked" and
      st.queueOf.get(st.target.get(w)) == q)
    and { publishing.size() + claiming.size() <= 1,
      (st.queueOwner.get(q) == -1) == (publishing.size() + claiming.size() == 0),
      publishing.forall(o => st.queueOwner.get(q) == st.owner.get(o)),
      claiming.forall(w => st.queueOwner.get(q) == w) }
  }) and {
    val signalling = objects.filter(o => st.pub.get(o) == 4)
    val counting = workers.filter(w => st.mode.get(w) == "recheck" or st.mode.get(w) == "pre-wait")
    and { signalling.size() + counting.size() <= 1,
      (st.mutex == -1) == (signalling.size() + counting.size() == 0),
      signalling.forall(o => st.mutex == st.owner.get(o)),
      counting.forall(w => st.mutex == w) }
  }

  // The only zero-count transition also publishes termination and broadcasts.
  pure def phaseShapeOf(st: State): bool = (st.count == 0) == st.terminated and
    st.terminated.implies(st.mutex == -1 and workers.forall(w =>
      st.mode.get(w) == "woken" or st.mode.get(w) == "done"))

  // The closure target must include the entire generated domain; a real step
  // leaving a bound is a failure, not a successor silently filtered away.
  // Exact Cartesian component domains also appear in initSafetyCandidate.
  // The IR contract checks their identity, all record fields and pure filters.
  val shape = s.policy.in(Set("source", "combined")) and s.fault == "none" and
    s.mode.in(workers.setOfMaps(Set("active", "probe", "claim-locked", "scanning",
      "probed", "recheck", "pre-wait", "waiting", "woken", "done"))) and
    s.work.in(objects.setOfMaps((-1).to(3))) and
    s.owner.in(objects.setOfMaps((-1).to(3))) and
    s.copied.in(objects.setOfMaps(0.to(2))) and
    s.visible.in(objects.setOfMaps(0.to(2))) and
    s.pub.in(objects.setOfMaps(0.to(5))) and
    s.queueOf.in(objects.setOfMaps((-1).to(3))) and
    s.route.in(objects.setOfMaps(Set("", "local", "queue"))) and
    s.queueOwner.in(queues.setOfMaps((-1).to(3))) and
    s.scans.in(objects.setOfMaps(0.to(1))) and
    s.target.in(workers.setOfMaps((-1).to(3))) and
    s.probeIndex.in(workers.setOfMaps(0.to(4))) and
    s.remaining.in(workers.setOfMaps(queues.powerset())) and
    s.found.in(workers.setOfMaps(Set(false, true))) and
    s.headDone.in(objects.powerset()) and s.tailDone.in(objects.powerset()) and
    s.headVisits.in(objects.setOfMaps(0.to(1))) and
    s.mutex.in((-1).to(3)) and s.count.in(0.to(4)) and
    s.spuriousUsed.in(workers.powerset()) and
    s.foreignHeadWrite == false and s.staleRead == false and
    s.terminated.in(Set(false, true))
  val candidateInvariant = shape and safeOf(s) and discoveryShapeOf(s) and lockShapeOf(s) and phaseShapeOf(s)
}
