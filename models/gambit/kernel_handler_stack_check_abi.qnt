module kernel_handler_stack_check_abi {
  // Measured on lock 3ffea79b…, bootstrap-generated lib/_kernel.c
  // sha256 12d447d0…, not a captured fault PC.
  // ##kernel-handlers has 14 entry labels when no stack-only poll is
  // inserted. Thirteen (not warnings) nontail calls, one before each
  // ##c-code entry after the first, each inserted one ___CHECK_STACK
  // continuation. That made 27 labels. The stack handler comment
  // ___LBL(2) is preceded by two of those calls and landed on
  // ___DEF_SLBL(4). setup.c still assigns handler_stack_limit = ___LBL(2).
  // The repaired rule does not allocate those anchor labels. An ordinary
  // disabled call keeps warnings enabled, so it still receives a check,
  // and that check is not an extra kernel-handler entry.
  // Processor-probe SIGSEGV is a separate observation.

  pure val manualEntries = 14
  pure val anchorCalls = 13
  pure val observedEntries = 27
  pure val manualLabel = 2
  pure val anchorsBeforeStackHandler = 2
  pure val observedLabel = 4
  pure val entryRelation = observedEntries == manualEntries + anchorCalls
  pure val labelRelation =
    observedLabel == manualLabel + anchorsBeforeStackHandler

  type State = {
    phase: str,
    mode: str,
    label: int,
    ordinaryChecked: bool
  }
  var s: State

  action initOld = s' = {
    phase: "open", mode: "split-anchors", label: manualLabel,
    ordinaryChecked: false
  }
  action initFixed = s' = {
    phase: "open", mode: "keep-anchors", label: manualLabel,
    ordinaryChecked: false
  }

  action place = all {
    s.phase == "open",
    s' = {
      phase: "done",
      mode: s.mode,
      label: if (s.mode == "split-anchors") s.label + anchorsBeforeStackHandler
              else s.label,
      ordinaryChecked: true
    }
  }
  action hold = all { s.phase == "done", s' = s }
  action step = any { place, hold }

  val abiHeld = entryRelation and labelRelation and
    (s.phase == "done" implies
      s.mode == "keep-anchors" and s.label == manualLabel and s.ordinaryChecked)
  val oldMatches = s.label == manualLabel
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.phase == "done"))
}
