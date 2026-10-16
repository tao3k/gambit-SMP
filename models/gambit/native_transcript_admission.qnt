module native_transcript_admission {
  // Three cells abstract enter, return and completion; positions preserve order.
  // The decoder and Evidence joins require independent native qualification.
  var observed: int -> str
  var used: bool
  var bypass: bool
  val expected = Map(0 -> "enter", 1 -> "return", 2 -> "complete")
  action init = all { observed' = expected, used' = false, bypass' = false }
  action initBypass = all { observed' = expected, used' = false, bypass' = true }
  action alter = {
    nondet cell = Set(0, 1, 2, 3).oneOf()
    nondet token = Set("enter", "return", "complete", "missing", "invalid").oneOf()
    all { not(used), observed' = observed.set(cell, token), used' = used, bypass' = bypass }
  }
  val missing = expected.keys().exists(cell => not(observed.keys().contains(cell)) or
    observed.get(cell) == "missing")
  val unexpected = observed.keys().exists(cell => if (expected.keys().contains(cell))
    observed.get(cell) != expected.get(cell) else true)
  val complete = not(missing) and not(unexpected)
  action admit = all { not(used), complete or bypass,
    observed' = observed, used' = true, bypass' = bypass }
  action hold = all { observed' = observed, used' = used, bypass' = bypass }
  action step = any { alter, admit, hold }
  val safe = not(used) or complete
}
