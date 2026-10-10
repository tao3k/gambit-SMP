module rehash_lock_ownership {
  // PR988 removes the outer lock because source/destination stripes can alias.
  // The no-outer-lock protocol additionally REQUIRES source ownership until
  // publication. Fixed is that obligation, not an implemented runtime lock.
  var nested: bool
  var exclusive: bool
  var alias: bool
  var held: bool
  var stage: int
  var sourceValue: int
  var copied: int
  var destinationValue: int
  var writerDone: bool

  action initOld = all {
    nested' = true, exclusive' = true, alias' = false, held' = false, stage' = -1,
    sourceValue' = 1, copied' = 0, destinationValue' = 0, writerDone' = false,
  }
  action initUnlockedSource = all {
    nested' = false, exclusive' = false, alias' = false, held' = false, stage' = -1,
    sourceValue' = 1, copied' = 0, destinationValue' = 0, writerDone' = false,
  }
  action initFixed = all {
    nested' = false, exclusive' = true, alias' = false, held' = false, stage' = -1,
    sourceValue' = 1, copied' = 0, destinationValue' = 0, writerDone' = false,
  }
  action change(pc: int, src: int, saved: int, dst: int, done: bool, owner: bool): bool = all {
    stage' = pc, sourceValue' = src, copied' = saved, destinationValue' = dst,
    writerDone' = done, held' = owner,
    nested' = nested, exclusive' = exclusive, alias' = alias,
  }
  action choose(collides: bool): bool = all {
    stage == -1, stage' = 0, alias' = collides,
    nested' = nested, exclusive' = exclusive, held' = held,
    sourceValue' = sourceValue, copied' = copied,
    destinationValue' = destinationValue, writerDone' = writerDone,
  }
  action beginCopy = all { stage == 0,
    change(1, sourceValue, copied, destinationValue, writerDone, nested or exclusive) }
  action readSource = all { stage == 1,
    change(2, sourceValue, sourceValue, destinationValue, writerDone, held) }
  action insertDestination = all { stage == 2, not(nested and alias),
    change(3, sourceValue, copied, copied, writerDone, held) }
  action publish = all { stage == 3,
    change(4, sourceValue, copied, destinationValue, writerDone, false) }
  // Abstract one complete writer operation, not just a transient slot write.
  // Before publication the logical table is the source; afterwards it is dst.
  action writer = all { stage >= 0, not(held), not(writerDone),
    change(stage, if (stage < 4) 2 else sourceValue, copied,
           if (stage == 4) 2 else destinationValue, true, held) }
  action idle = all { stage == 4, writerDone,
    change(stage, sourceValue, copied, destinationValue, writerDone, held) }
  action step = any { choose(false), choose(true), beginCopy, readSource,
                      insertDestination, publish, writer, idle }
  val lockSafe = not(stage == 2 and nested and alias)
  val ownershipSafe = stage != 4 or not(writerDone) or destinationValue == 2
  val safe = lockSafe and ownershipSafe
}
