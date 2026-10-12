module definedness_checks {
  import guard_definedness_controls.* from "./guard_definedness_controls"
  val necessary_mapGood = exists(Set(0), ((index) => true))
  val necessary_mapBad = exists(Set(1), ((index) => true))
  val necessary_setBad = exists(Set(1), ((index) => true))
  val necessary_listBad = exists(Set(1), ((index) => true))
  val necessary_emptyChoice = exists(Set(), ((index) => true))
  val defined_mapGood = exists(Set(0), ((index) => contains(keys(values), index)))
  val defined_mapBad = exists(Set(1), ((index) => contains(keys(values), index)))
  val defined_setBad = exists(Set(1), ((index) => ite(contains(keys(values), index), contains(keys(set(values, index, 7)), 0), false)))
  val defined_listBad = exists(Set(1), ((index) => ite(igte(index, 0), ilt(index, length(slots)), false)))
  val defined_emptyChoice = exists(Set(), ((index) => contains(keys(values), index)))
}
