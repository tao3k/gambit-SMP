module msection_header_page_guard {
  // Word geometry, not an OS page size or a processor-count configuration.
  pure val headerWords = 3
  type State = { phase: str, page: int, container: int, prefix: int,
    base: int, allocationEnd: int, target: int, writable: bool,
    mutatorsParked: bool, trapped: bool, unauthorizedWrite: bool, skipReprotect: bool }
  var s: State
  action init = {
    nondet page = Set(8, 16, 32).oneOf()
    nondet container = 0.to(page - 1).oneOf()
    val prefix = if (container == 0) 0 else page
    s' = { phase: "mutator", page: page, container: container, prefix: prefix,
      base: prefix + page, allocationEnd: container + 4 * page - 1,
      target: -1, writable: false, mutatorsParked: false,
      trapped: false, unauthorizedWrite: false, skipReprotect: false }
  }
  action initMissingReprotect = s' = {
    phase: "mutator", page: 8, container: 1, prefix: 8, base: 16,
    allocationEnd: 32, target: -1, writable: false, mutatorsParked: false,
    trapped: false, unauthorizedWrite: false, skipReprotect: true }
  action write = {
    nondet target = s.prefix.to(s.base + 2 * s.page - 1).oneOf()
    val protected = target < s.base
    all { s.phase == "mutator",
      s' = { ...s, phase: "done", target: target,
        trapped: protected and not(s.writable),
        unauthorizedWrite: protected and s.writable } }
  }
  action park = all { s.phase == "mutator",
    s' = { ...s, phase: "parked", mutatorsParked: true } }
  action openAdmin = all { s.phase == "parked", s.mutatorsParked,
    s' = { ...s, phase: "admin", writable: true } }
  action adminWrite = all { s.phase == "admin", s.mutatorsParked, s.writable,
    s' = { ...s, phase: "reprotect", target: s.base - 1 } }
  action reprotect = all { s.phase == "reprotect",
    s' = { ...s, phase: "resume", writable: s.skipReprotect } }
  action resume = all { s.phase == "resume",
    s' = { ...s, phase: "mutator", mutatorsParked: false, target: -1 } }
  action step = any { write, park, openAdmin, adminWrite, reprotect, resume,
    all { s.phase == "done", s' = s } }
  val geometry = s.base % s.page == 0 and
    s.prefix >= s.container and s.base + 2 * s.page <= s.allocationEnd and
    s.base - headerWords >= s.prefix
  val exclusivity = s.writable.implies(s.mutatorsParked)
  val transparentPayload = (s.phase == "done" and s.target >= s.base)
    .implies(not(s.trapped))
  val safe = geometry and exclusivity and transparentPayload and not(s.unauthorizedWrite)
  // A trap is diagnostic failure, not native correctness or release admission.
}
