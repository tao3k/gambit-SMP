module induction_function_domain {
  var values: int -> int
  pure val domainKeys = Set(0, 1)
  pure val domain = domainKeys.setOfMaps(0.to(2))
  action init = values' = Map(0 -> 0, 1 -> 0)
  action step = {
    nondet key = domainKeys.oneOf()
    values' = values.set(key, if (values.get(key) < 2) values.get(key) + 1 else 2)
  }
  action escape = values' = values.set(0, 3)
  action omitKey = values' = Map(0 -> 0)
  val inductive = values.in(domain)
  val safe = values.keys() == domainKeys and domainKeys.forall(k => values.get(k) >= 0 and values.get(k) <= 2)
}
