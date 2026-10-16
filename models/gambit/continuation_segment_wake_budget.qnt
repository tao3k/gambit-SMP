module continuation_segment_wake_budget {
  // Finite roles; runtime derives the limit from the current VM cohort.
  type State = { single: bool, processors: int, chunks: int, budget: int,
    sleeping: Set[int], notified: Set[int], remaining: int, published: bool }
  var s: State
  action initOld = {
    nondet processors = 2.to(4).oneOf()
    nondet chunks = 1.to(5).oneOf()
    s' = { single: true, processors: processors, chunks: chunks, budget: 1,
      sleeping: 1.to(processors - 1), notified: Set(), remaining: 1, published: false }
  }
  action init = {
    nondet processors = 2.to(4).oneOf()
    nondet chunks = 1.to(5).oneOf()
    val budget = if (chunks < processors) chunks else processors - 1
    s' = { single: false, processors: processors, chunks: chunks, budget: budget,
      sleeping: 1.to(processors - 1), notified: Set(), remaining: budget, published: false }
  }
  // Notification under the wait-registration mutex removes one registered
  // sleeper. Reacquisition is later; no fairness or actual scheduling speed
  // of the operating system is inferred from this abstract notification.
  action signal = {
    nondet worker = s.sleeping.oneOf()
    all { s.remaining > 0,
      s' = { ...s, sleeping: s.sleeping.exclude(Set(worker)),
        notified: s.notified.union(Set(worker)), remaining: s.remaining - 1 } }
  }
  action finish = all {
    s.remaining == 0, not(s.published), s' = { ...s, published: true } }
  action finished = all { s.published, s' = s }
  action step = any { signal, finish, finished }
  val quota = if (s.chunks < s.processors) s.chunks else s.processors - 1
  val capacity = s.published.implies(s.notified.size() >= quota)
  val bounded = s.notified.size() + s.remaining == s.budget and
    s.budget <= s.processors - 1 and s.budget <= s.chunks
  val ownership = s.sleeping.intersect(s.notified).size() == 0 and
    s.sleeping.union(s.notified) == 1.to(s.processors - 1)
  val safe = capacity and bounded and ownership
  val noStall = s.published or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.published))
}
