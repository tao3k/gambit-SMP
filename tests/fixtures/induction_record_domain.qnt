module induction_record_domain {
  type DomainState = { values: int -> int, count: int }
  var s: DomainState
  pure val domainKeys = Set(0, 1)
  pure val domain = domainKeys.setOfMaps(0.to(2))
  action init = s' = { values: Map(0 -> 0, 1 -> 0), count: 0 }
  action step = {
    nondet key = domainKeys.oneOf()
    s' = s.with("values", s.values.set(key, if (s.values.get(key) < 2) s.values.get(key) + 1 else 2))
  }
  val inductive = s.values.in(domain) and s.count.in(0.to(2))
  val safe = s.values.keys() == domainKeys and domainKeys.forall(k => s.values.get(k) >= 0 and s.values.get(k) <= 2)
}
