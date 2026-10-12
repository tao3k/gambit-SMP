module rank_composition {
  var oldPrimary: int
  var newPrimary: int
  var oldWorkers: int -> int
  var newWorkers: int -> int
  pure val roles = Set(0, 1, 2, 3)
  pure def secondary(values: int -> int): int =
    values.get(0) + values.get(1) + values.get(2) + values.get(3) + 24
  pure def lex(p0: int, p1: int, w0: int -> int, w1: int -> int): bool =
    p1 > p0 or (p1 == p0 and roles.forall(w => w1.get(w) >= w0.get(w)) and
      roles.exists(w => w1.get(w) > w0.get(w)))
  action init = {
    nondet p0 = 0.to(201).oneOf()
    nondet p1 = 0.to(201).oneOf()
    nondet w0 = roles.setOfMaps((-6).to(27)).oneOf()
    nondet w1 = roles.setOfMaps((-6).to(27)).oneOf()
    all { lex(p0, p1, w0, w1), oldPrimary' = p0, newPrimary' = p1,
      oldWorkers' = w0, newWorkers' = w1 }
  }
  action step = all { oldPrimary' = oldPrimary, newPrimary' = newPrimary,
    oldWorkers' = oldWorkers, newWorkers' = newWorkers }
  val boundedAndStrict = 256 * newPrimary + secondary(newWorkers) >
    256 * oldPrimary + secondary(oldWorkers) and
    256 * oldPrimary + secondary(oldWorkers) >= 0 and
    256 * newPrimary + secondary(newWorkers) <= 51588
  val rejectsInsufficientWeight = newPrimary + secondary(newWorkers) >
    oldPrimary + secondary(oldWorkers)
}
