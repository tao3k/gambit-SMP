module shared_header_write_boundary {
  // Logical word coordinates; the C check uses offsetof, not these constants.
  pure val starts = Set(0, 16, 40, 72)
  pure def administrative(target: int): bool =
    starts.exists(start => target >= start and target < start + 3)
  type Header = { index: int, pos: int, member: int, sections: int, nextAligned: bool }
  type State = { phase: str, target: int, guarded: bool, intact: bool,
    denied: bool, header: Header, observation: int }
  var s: State
  pure val legalHeader = { index: 3195, pos: 1495, member: 1495,
    sections: 4691, nextAligned: true }
  pure def initial(target: int, guarded: bool, observation: int): State = {
    phase: "write", target: target, guarded: guarded, intact: true,
    denied: false, header: legalHeader, observation: observation }
  action init = {
    nondet target = 0.to(95).oneOf()
    s' = initial(target, true, 0)
  }
  action initUnguardedWrite = {
    nondet target = 0.to(95).oneOf()
    s' = initial(target, false, 0)
  }
  action initNativeHeader = s' = { ...initial(3, true, 1), phase: "observe" }
  action initInRangeWrongCatalogPosition =
    s' = { ...initial(3, true, 2), phase: "observe" }
  action write = all { s.phase == "write",
    s' = if (s.guarded and administrative(s.target))
      { ...s, phase: "done", denied: true }
    else { ...s, phase: "done", intact: not(administrative(s.target)) } }
  // Import measured values; neither action identifies the earlier writer.
  action observe = all { s.phase == "observe",
    s' = { ...s, phase: "done", header: if (s.observation == 1)
      { ...legalHeader, index: -1368899887, pos: 9, nextAligned: false }
      else { ...legalHeader, pos: 9 } } }
  action step = any { write, observe, all { s.phase == "done", s' = s } }
  val metadataValid = s.header.index >= 0 and s.header.nextAligned and
    s.header.pos >= 0 and s.header.pos < s.header.sections and
    s.header.pos == s.header.member
  val exactGuard = (s.phase == "done" and s.observation == 0 and s.guarded)
    .implies(s.denied == administrative(s.target))
  val safe = s.intact and metadataValid and exactGuard
}
