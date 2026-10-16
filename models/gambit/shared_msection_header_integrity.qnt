module shared_msection_header_integrity {
  import stack_allocator_frame_lifetime as A from "./stack_allocator_frame_lifetime"
  // Logical allocation order and address-order positions are distinct.
  type Header = { index: int, pos: int, next: int }
  type Arena = { phase: str, cursor: int, headers: int -> Header, observed: bool }
  var arena: Arena
  pure def initial(observed: bool): Arena = {
    phase: "inspect", cursor: 1, observed: observed,
    headers: Map(0 -> { index: 0, pos: 2, next: 1 },
      1 -> { index: 1, pos: 0, next: 2 },
      2 -> { index: 2, pos: 3, next: 3 },
      3 -> { index: 3, pos: 1, next: -1 }) }
  action init = all { A::s' = A::initial(0), arena' = initial(false) }
  action initObservedHeaderDamage = all {
    A::s' = A::initial(0), arena' = initial(true)
  }
  // Import the observed member header, not a hypothetical legal writing action.
  action observeHeader = all {
    arena.phase == "inspect", arena.observed,
    arena' = { ...arena, phase: "done", headers: arena.headers.set(arena.cursor,
      { index: -44, pos: -1, next: A::nonSection }) }, A::s' = A::s
  }
  action inspectLegalHeader = all {
    arena.phase == "inspect", not(arena.observed),
    arena' = { ...arena, phase: "done" }, A::s' = A::s
  }
  action step = any { observeHeader, inspectLegalHeader,
    all { arena.phase == "done", arena' = arena, A::s' = A::s } }
  val headerIntegrity = A::sections.forall(id => {
    val header = arena.headers.get(id)
    header.index == id and A::sections.contains(header.pos) and
      (header.next == -1 or A::sections.contains(header.next)) })
  val safe = A::safe and headerIntegrity
  // Membership alone does not prove lifetime; writer/retirement refinement is open.
}
