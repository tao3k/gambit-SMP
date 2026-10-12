module guard_definedness_controls {
  var s: int
  val values = Map(0 -> 5)
  val slots = [5]
  action init = s' = 0
  action mapGood = {
    nondet index = Set(0).oneOf()
    s' = values.get(index)
  }
  action mapBad = {
    nondet index = Set(1).oneOf()
    s' = values.get(index)
  }
  action setBad = {
    nondet index = Set(1).oneOf()
    s' = values.set(index, 7).get(0)
  }
  action listBad = {
    nondet index = Set(1).oneOf()
    s' = slots.nth(index)
  }
  action emptyChoice = {
    nondet index = Set().oneOf()
    s' = values.get(index)
  }
  action conflictingAssignments = all { s' = 0, s' = 1 }
  action step = any { mapGood, mapBad, setBad, listBad, emptyChoice }
}
