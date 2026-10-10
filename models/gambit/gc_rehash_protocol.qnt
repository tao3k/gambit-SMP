module gc_rehash_protocol {
  var repair: bool
  var phase: int
  var kind: int
  var decoding: bool
  var decoderRepair: bool
  var decoderPending: bool
  var gcRounds: int
  var unordered: bool
  var pointerLayout: bool
  var needRehash: bool
  var keyIntact: bool
  var found: bool
  action initOld = all {
    repair' = false, phase' = 0, kind' = -1, decoding' = false, unordered' = false,
    decoderRepair' = false, decoderPending' = false, gcRounds' = 0,
    pointerLayout' = false, needRehash' = false, keyIntact' = true, found' = true,
  }
  action initFixed = all {
    repair' = true, phase' = 0, kind' = -1, decoding' = false, unordered' = false,
    decoderRepair' = true, decoderPending' = false, gcRounds' = 0,
    pointerLayout' = false, needRehash' = false, keyIntact' = true, found' = true,
  }
  // Negative control: decoder repair alone does not repair later GC callers.
  action initDecodedOld = all {
    repair' = false, decoderRepair' = true, decoderPending' = false, gcRounds' = 0,
    phase' = 0, kind' = -1, decoding' = false, unordered' = false,
    pointerLayout' = false, needRehash' = false, keyIntact' = true, found' = true,
  }
  // C eq? tables partition immediate/allocated keys, so mixed C keys are
  // deliberately excluded. 1/2 are Scheme hash tables with uniform/mixed keys.
  action choose(k: int, decode: bool): bool = all {
    phase == 0, phase' = 1, kind' = k, decoding' = decode,
    unordered' = decode,
    decoderRepair' = decoderRepair, decoderPending' = decode, gcRounds' = gcRounds,
    repair' = repair, pointerLayout' = (k == 0), needRehash' = false,
    keyIntact' = keyIntact, found' = found,
  }
  action relocate = all {
    phase == 1, phase' = 2, kind' = kind, decoding' = decoding,
    unordered' = unordered,
    decoderRepair' = decoderRepair, decoderPending' = decoderPending, gcRounds' = gcRounds,
    repair' = repair, pointerLayout' = pointerLayout,
    needRehash' = needRehash, keyIntact' = keyIntact, found' = found,
  }
  // Abstracts a completed pointer rehash, not its probe/collision algorithm.
  // Decoder must invoke the same repair protocol before publishing the table.
  val activeRepair = if (decoderPending) decoderRepair else repair
  action rehash = all {
    phase == 2, phase' = 3, kind' = kind, decoding' = decoding, repair' = repair,
    decoderRepair' = decoderRepair, decoderPending' = false, gcRounds' = gcRounds,
    pointerLayout' = if (decoderPending and not(activeRepair)) pointerLayout else (if (activeRepair and kind == 2) false else true),
    unordered' = if ((not(decoderPending) or activeRepair) and kind != 2) false else unordered,
    needRehash' = (activeRepair and kind != 0),
    keyIntact' = (keyIntact and (kind != 2 or activeRepair or decoderPending)), found' = found,
  }
  action access = all {
    phase == 3, phase' = 4, kind' = kind, decoding' = decoding, repair' = repair,
    pointerLayout' = if (kind != 0 and needRehash) false else pointerLayout,
    found' = (keyIntact and (needRehash or (not(unordered) and (if (kind == 0) pointerLayout else not(pointerLayout))))),
    unordered' = if (needRehash) false else unordered,
    needRehash' = false, keyIntact' = keyIntact,
    decoderRepair' = decoderRepair, decoderPending' = decoderPending, gcRounds' = gcRounds,
  }
  // A successfully published table can move again. Bound this to two cycles;
  // native tests force five GCs, rather than claiming unbounded verification.
  action forceGc = all {
    phase == 4, found, keyIntact, gcRounds < 2,
    phase' = 2, gcRounds' = gcRounds + 1, decoderPending' = false,
    decoderRepair' = decoderRepair, repair' = repair, kind' = kind,
    decoding' = decoding, unordered' = unordered, pointerLayout' = pointerLayout,
    needRehash' = needRehash, keyIntact' = keyIntact, found' = found,
  }
  action idle = all {
    phase == 4, phase' = phase, kind' = kind, decoding' = decoding,
    unordered' = unordered,
    repair' = repair, pointerLayout' = pointerLayout, needRehash' = needRehash,
    keyIntact' = keyIntact, found' = found,
    decoderRepair' = decoderRepair, decoderPending' = decoderPending, gcRounds' = gcRounds,
  }
  action step = any { choose(0, false), choose(0, true), choose(1, false),
                      choose(1, true), choose(2, false), choose(2, true),
                      relocate, rehash, access, forceGc, idle }
  val safe = keyIntact and found
  val decodeSafe = not(decoding) or safe
  val uniformSafe = kind != 1 or safe
  val gcSafe = gcRounds == 0 or safe
}
