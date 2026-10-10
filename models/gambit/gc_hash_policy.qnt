module gc_hash_policy {
  var repair: bool
  var phase: int
  var pointerLayout: bool
  var needRehash: bool
  var found: bool
  action initOld = all {
    repair' = false, phase' = 0, pointerLayout' = false,
    needRehash' = false, found' = true,
  }
  action initFixed = all {
    repair' = true, phase' = 0, pointerLayout' = false,
    needRehash' = false, found' = true,
  }
  // Uniform allocation tags do not imply a pointer-hash table.
  action collectorRehash = all {
    phase == 0, phase' = 1, pointerLayout' = true, needRehash' = repair,
    found' = found, repair' = repair,
  }
  // ##table-access uses NEED_REHASH to rebuild with its Scheme hash function.
  action lookup = all {
    phase == 1, phase' = 2, found' = (not(pointerLayout) or needRehash),
    pointerLayout' = pointerLayout, needRehash' = needRehash, repair' = repair,
  }
  action idle = all {
    phase == 2, phase' = phase, found' = found,
    pointerLayout' = pointerLayout, needRehash' = needRehash, repair' = repair,
  }
  action step = any { collectorRehash, lookup, idle }
  val safe = found
}
