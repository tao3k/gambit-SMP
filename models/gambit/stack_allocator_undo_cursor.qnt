module stack_allocator_undo_cursor {
  import stack_allocator_frame_lifetime as A from "./stack_allocator_frame_lifetime"
  // Compose the real allocator undo transition with one break-handler NEXT
  // advance. Cursor coordinates are frames, not native addresses or CPU counts.
  type Cursor = { phase: int, snapshot: int, next: int, resumed: int, stale: bool }
  var cursor: Cursor
  pure def ownedSection = {
    val base = A::initial(0)
    { ...base, stack: 2, virgin: Set(3), eligible: Set(2),
      previous: base.previous.set(2, 0),
      payloadPrevious: base.payloadPrevious.set(2, 0) }
  }
  action init = all {
    A::s' = ownedSection,
    cursor' = { phase: 0, snapshot: 0, next: 0, resumed: -1, stale: false }
  }
  action initStaleSnapshot = all {
    A::s' = ownedSection,
    cursor' = { phase: 0, snapshot: 0, next: 0, resumed: -1, stale: true }
  }
  // _kernel.scm handler_break advances BREAK_FRAME_NEXT after copying a frame.
  action copyCallerFrame = all {
    cursor.phase == 0, A::s' = A::s,
    cursor' = { ...cursor, phase: 1, next: cursor.next + 1 }
  }
  action restorePreviousSection = all {
    cursor.phase == 1, A::undo,
    cursor' = { ...cursor, phase: 2,
      resumed: if (cursor.stale) cursor.snapshot else cursor.next }
  }
  action step = any { copyCallerFrame, restorePreviousSection,
    all { cursor.phase == 2, cursor' = cursor, A::s' = A::s } }
  val safe = A::safe and (cursor.phase == 2).implies(cursor.resumed == cursor.next)
  // This bounded witness does not identify the writer of the native bad section.
}
