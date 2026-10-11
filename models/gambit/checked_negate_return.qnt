module checked_negate_return {
  // Abstract fixnums [-4,3]; -9 represents the non-fixnum failure sentinel.
  // A checked constant multiplication by -1 must report overflow, not success.
  type State = { fixed: bool, phase: int, input: int, value: int, success: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, input: 0, value: 0, success: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action choose(input: int, alias: bool): bool = all {
    s.phase == 0,
    s' = { ...s, phase: 1, input: input, value: if (alias) input else 2 },
  }
  action negate = all {
    s.phase == 1,
    val overflow = s.input == -4
    s' = { ...s, phase: 2,
      success: not(s.fixed) or not(overflow),
      value: if (overflow) (if (s.fixed) s.value else -9) else -s.input },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any {
    choose(-4, false), choose(-4, true), choose(-1, false), choose(-1, true),
    choose(0, false), choose(0, true), choose(1, false), choose(1, true),
    choose(3, false), choose(3, true), negate, finished,
  }
  val safe = s.phase != 2 or (s.success == (s.input != -4)
    and (not(s.success) or (s.value >= -4 and s.value <= 3 and s.value == -s.input)))
}
