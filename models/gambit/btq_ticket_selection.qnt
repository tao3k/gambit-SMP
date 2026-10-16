module btq_ticket_selection {
  import btq_operations as B from "./btq_operations"
  import ticket_queue_handoff as H from "./ticket_queue_handoff"

  // Compose the existing visibility abstraction with real sentinel/minimum
  // and cleared-link writes. This is not a C/ARM memory-model refinement.
  var invalidSelection: bool
  var queueTree: B::Tree
  pure val tree = {
    val a = B::insertBelow(B::initial(0).t, 2, false)
    val b = B::color(a, 2, false)
    B::insertBelow(b, 1, false)
  }
  // Keep initializer bodies separate for Quint's TLA+ conversion.
  action initAllocatorOnly = all {
    queueTree' = tree,
    H::s' = H::initialState(false), invalidSelection' = false,
  }
  // ALLOC-only does not supply acquire ordering to primitive BTQ locks.
  action initQueueAcquire = all {
    queueTree' = tree,
    H::s' = H::initialState(true), invalidSelection' = false,
  }
  action reserve = all {
    H::reserveTicket, queueTree' = queueTree, invalidSelection' = invalidSelection,
  }
  action prefetch = all {
    H::prefetchHead, queueTree' = queueTree, invalidSelection' = invalidSelection,
  }
  action removeMinimum = all {
    H::firstClaim,
    {
      val t = queueTree
      val n = t.r.get(0)
      val p = t.p.get(n)
      // Red minimum leaf: the source needs no black-height fix-up.
      val cleared = { ...t, p: t.p.set(n, -1).set(0, p),
        l: t.l.set(n, -1), r: t.r.set(n, -1).set(0, p),
        members: t.members.exclude(Set(n)), container: t.container.set(n, -1) }
      queueTree' = B::finish(B::replace(cleared, p, n, 0))
    },
    invalidSelection' = invalidSelection,
  }
  action release = all {
    H::releaseTicket, queueTree' = queueTree, invalidSelection' = invalidSelection,
  }
  action observe = all {
    H::observeTicket, queueTree' = queueTree, invalidSelection' = invalidSelection,
  }
  action callerSelect = all {
    H::consumeHead, queueTree' = queueTree,
    // Do not choose nondeterministically from valid members: that would
    // exclude a stale caller-selected node before removal even begins.
    invalidSelection' = not(queueTree.members.contains(H::s.cached + 1)),
  }
  action idle = all {
    H::idle, queueTree' = queueTree, invalidSelection' = invalidSelection,
  }
  action step = any { reserve, prefetch, removeMinimum, release, observe, callerSelect, idle }
  val safe = not(invalidSelection) and
    queueTree.members.contains(queueTree.r.get(0))
}
