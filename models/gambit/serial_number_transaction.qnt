module serial_number_transaction {
  var repair: bool
  var chosen: bool
  var sameObject: bool
  var owner: int
  var counter: int
  var forwardA: int
  var forwardB: int
  var stage0: int
  var stage1: int
  var pending0: int
  var pending1: int
  var result0: int
  var result1: int

  action initOld = all {
    repair' = false, chosen' = false, sameObject' = false, owner' = -1,
    counter' = 0, forwardA' = 0, forwardB' = 0,
    stage0' = 0, stage1' = 0, pending0' = 0, pending1' = 0,
    result0' = 0, result1' = 0,
  }
  action initFixed = all {
    repair' = true, chosen' = false, sameObject' = false, owner' = -1,
    counter' = 0, forwardA' = 0, forwardB' = 0,
    stage0' = 0, stage1' = 0, pending0' = 0, pending1' = 0,
    result0' = 0, result1' = 0,
  }
  action choose(same: bool): bool = all {
    not(chosen), chosen' = true, sameObject' = same, repair' = repair,
    owner' = owner, counter' = counter, forwardA' = forwardA, forwardB' = forwardB,
    stage0' = stage0, stage1' = stage1, pending0' = pending0, pending1' = pending1,
    result0' = result0, result1' = result1,
  }
  // Every lookup is already atomic: per-operation table locking is insufficient.
  action lookup(w: int): bool = {
    val stage = if (w == 0) stage0 else stage1
    val existing = if (w == 0 or sameObject) forwardA else forwardB
    all {
      chosen, stage == 0, (not(repair) or owner == -1),
      owner' = if (repair and existing == 0) w else owner,
      stage0' = if (w == 0) (if (existing == 0) 1 else 3) else stage0,
      stage1' = if (w == 1) (if (existing == 0) 1 else 3) else stage1,
      result0' = if (w == 0) existing else result0,
      result1' = if (w == 1) existing else result1,
      pending0' = pending0, pending1' = pending1, counter' = counter,
      forwardA' = forwardA, forwardB' = forwardB,
      chosen' = chosen, sameObject' = sameObject, repair' = repair,
    }
  }
  // Stronger than the unprotected source increment: even atomic numbering alone
  // cannot stabilize two simultaneous lookups of the same object.
  action allocate(w: int): bool = all {
    (if (w == 0) stage0 else stage1) == 1,
    counter' = counter + 1,
    pending0' = if (w == 0) counter + 1 else pending0,
    pending1' = if (w == 1) counter + 1 else pending1,
    stage0' = if (w == 0) 2 else stage0,
    stage1' = if (w == 1) 2 else stage1,
    result0' = result0, result1' = result1, owner' = owner,
    forwardA' = forwardA, forwardB' = forwardB,
    chosen' = chosen, sameObject' = sameObject, repair' = repair,
  }
  action publish(w: int): bool = {
    val number = if (w == 0) pending0 else pending1
    all {
      (if (w == 0) stage0 else stage1) == 2,
      forwardA' = if (w == 0 or sameObject) number else forwardA,
      forwardB' = if (w == 1 and not(sameObject)) number else forwardB,
      result0' = if (w == 0) number else result0,
      result1' = if (w == 1) number else result1,
      stage0' = if (w == 0) 3 else stage0,
      stage1' = if (w == 1) 3 else stage1,
      owner' = if (repair) -1 else owner,
      pending0' = pending0, pending1' = pending1, counter' = counter,
      chosen' = chosen, sameObject' = sameObject, repair' = repair,
    }
  }
  action idle = all {
    stage0 == 3, stage1 == 3, stage0' = stage0, stage1' = stage1,
    result0' = result0, result1' = result1, pending0' = pending0, pending1' = pending1,
    counter' = counter, forwardA' = forwardA, forwardB' = forwardB, owner' = owner,
    chosen' = chosen, sameObject' = sameObject, repair' = repair,
  }
  action step = any { choose(true), choose(false), lookup(0), lookup(1),
                      allocate(0), allocate(1), publish(0), publish(1), idle }
  val safe = (result0 == 0 or result1 == 0) or
             (if (sameObject) result0 == result1 else result0 != result1)
}
