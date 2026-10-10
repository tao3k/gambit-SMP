module gc_key_tags {
  var repair: bool
  var phase: int
  var keyTag: bool
  var needRehash: bool
  var keyMoved: bool
  var fallback: bool
  action initOld = all {
    repair' = false, phase' = 0, keyTag' = false,
    needRehash' = false, keyMoved' = false, fallback' = false,
  }
  action initFixed = all {
    repair' = true, phase' = 0, keyTag' = false,
    needRehash' = false, keyMoved' = false, fallback' = false,
  }
  // A general table may contain an immediate key despite MEM_ALLOC_KEYS.
  action moveHeapKey = all {
    phase == 0, phase' = 1, keyMoved' = true, keyTag' = keyTag,
    needRehash' = needRehash, fallback' = fallback, repair' = repair,
  }
  // The old in-situ algorithm uses allocation tags as temporary markers.
  // Applying its allocated-key path to an immediate key changes its encoding.
  action rehash = all {
    phase == 1, phase' = 2, keyTag' = not(repair), keyMoved' = false,
    needRehash' = repair, fallback' = repair, repair' = repair,
  }
  action idle = all {
    phase == 2, phase' = phase, keyTag' = keyTag, keyMoved' = keyMoved,
    needRehash' = needRehash, fallback' = fallback, repair' = repair,
  }
  action step = any { moveHeapKey, rehash, idle }
  val safe = not(keyTag) and ((phase < 2) or (needRehash and fallback))
}
