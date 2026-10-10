module table_decode {
  var repair: bool
  var lazy: bool
  var mixed: bool
  var phase: int
  var ordered: bool
  var needRehash: bool
  var keyMoved: bool
  var invalidRehasher: bool
  var lookupOK: bool

  action initOld = all {
    repair' = false, lazy' = false, mixed' = false, phase' = 0,
    ordered' = true, needRehash' = false, keyMoved' = false,
    invalidRehasher' = false, lookupOK' = true,
  }
  action initFixed = all {
    repair' = true, lazy' = false, mixed' = false, phase' = 0,
    ordered' = true, needRehash' = false, keyMoved' = false,
    invalidRehasher' = false, lookupOK' = true,
  }

  // Decode installs entries in serialization order, not hash-probe order.
  action decode(l: bool, m: bool): bool = all {
    phase == 0, phase' = 1, lazy' = l, mixed' = m,
    ordered' = false, needRehash' = true, keyMoved' = true,
    repair' = repair, invalidRehasher' = invalidRehasher, lookupOK' = lookupOK,
  }
  // PR 1038: uniform keys use the in-place rehasher; mixed keys defer
  // to the Scheme table's own hash function with NEED_REHASH preserved.
  action publish = all {
    phase == 1, phase' = 2,
    ordered' = (repair and not(mixed)),
    keyMoved' = if (repair) false else keyMoved,
    needRehash' = if (repair and not(mixed)) false else needRehash,
    invalidRehasher' = invalidRehasher,
    repair' = repair, lazy' = lazy, mixed' = mixed, lookupOK' = lookupOK,
  }
  action lookup = all {
    phase == 2, phase' = 3,
    lookupOK' = or { ordered, lazy and keyMoved, mixed and needRehash and not(keyMoved) },
    invalidRehasher' = (invalidRehasher or (mixed and lazy and keyMoved)),
    ordered' = ordered, needRehash' = needRehash, keyMoved' = keyMoved,
    repair' = repair, lazy' = lazy, mixed' = mixed,
  }
  action idle = all {
    phase == 3, phase' = phase, repair' = repair, lazy' = lazy, mixed' = mixed,
    ordered' = ordered, needRehash' = needRehash, keyMoved' = keyMoved,
    invalidRehasher' = invalidRehasher, lookupOK' = lookupOK,
  }
  action step = any {
    decode(false, false), decode(false, true), decode(true, false), decode(true, true),
    publish, lookup, idle,
  }
  val safe = lookupOK and not(invalidRehasher)
}
