module continuation_chunk_publication {
  // Two complete frames, two abstract words each, chunk threshold three.
  // Publication granularity only: not a collector safety or speedup claim.
  type State = { fixed: bool, local: int, committed: int,
                 boundary: int, frames: int, phase: int, closed: int }
  var s: State
  pure def initialState(fixed: bool): State = {
    fixed: fixed, local: 0, committed: 0, boundary: 3,
    frames: 0, phase: 0, closed: 0,
  }
  action initOld = s' = initialState(false)
  action initFixed = s' = initialState(true)
  action copyFrame = all {
    s.phase == 0, s.frames < 2,
    s' = { ...s, local: s.local + 2, frames: s.frames + 1, phase: 1 },
  }
  action checkpoint = {
    val close = (if (s.fixed) s.local else s.committed) >= s.boundary
    all {
      s.phase == 1,
      s' = { ...s, phase: 0,
        committed: if (close) s.local else s.committed,
        boundary: if (close) s.local + 3 else s.boundary,
        closed: if (close) s.closed + 1 else s.closed },
    }
  }
  // The original function eventually commits its local pointer on return.
  action finish = all {
    s.phase == 0, s.frames == 2,
    s' = { ...s, committed: s.local, phase: 2 },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { copyFrame, checkpoint, finish, finished }
  val safe = s.phase != 0 or s.local < s.boundary
}
