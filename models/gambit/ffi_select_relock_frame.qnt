module ffi_select_relock_frame {
  import ffi_gc_frame_protocol as F from "./ffi_gc_frame_protocol"

  // Conditional wait-cycle composition, not a claim that current device_select
  // executes GC. Reuse the caller protocol; add physical slots and a C root.
  type Physical = { policy: int, fp: int, publishedFP: int, boundary: int,
    words: int -> int, borrowed: int, held: bool, ordinary: bool }
  var p: Physical
  pure def initial(policy: int, ordinary: bool): Physical = {
    policy: policy, fp: if (ordinary) 0 else 2,
    publishedFP: if (ordinary) 0 else 2, boundary: 2,
    words: 0.to(9).mapBy(_ => -44), borrowed: 7,
    held: true, ordinary: ordinary,
  }
  // 0: required closed-root protocol; 1: C spin cannot join; 2: join with
  // unrooted C local; 3: omit the ordinary return slot from stack copying.
  action initClosed = {
    nondet ordinary = Set(false, true).oneOf()
    all { F::s' = F::initial(0), p' = initial(0, ordinary) }
  }
  action initSpin = {
    nondet ordinary = Set(false, true).oneOf()
    all { F::s' = F::initial(0), p' = initial(1, ordinary) }
  }
  action initUnrooted = {
    nondet ordinary = Set(false, true).oneOf()
    all { F::s' = F::initial(0), p' = initial(2, ordinary) }
  }
  action initMissingReturnSlot = {
    nondet ordinary = Set(false, true).oneOf()
    all { F::s' = F::initial(0), p' = initial(3, ordinary) }
  }
  action storeRA = all {
    F::saveReturnAddress,
    p' = { ...p, words: if (p.fp != p.boundary) p.words.set(p.fp, 9) else p.words },
  }
  action publish = all {
    F::publishRegisters, p' = { ...p, publishedFP: p.fp },
  }
  action call = all { F::enterForeignCall, p' = p }
  action request = all {
    p.held, F::s.epoch == 0, F::requestGC, p' = p,
  }
  action join = all {
    p.policy != 1, F::waitingProcessorJoins, p' = p,
  }
  action relocate = all {
    F::relocateRoots,
    {
      // move_continuation: source [publishedFP, boundary + breakSpace),
      // copy backwards to alloc_stack_ptr=10, then prepare_mem_pstate FP.
      val wordCount = p.boundary + 2 - p.publishedFP
      val nextFP = 10 - wordCount
      val moved = 0.to(wordCount - 1).fold(p.words, (words, i) => {
        val destination = 9 - i
        if (p.policy == 3 and p.ordinary and destination == nextFP) words
        else words.set(destination, p.words.get(p.boundary + 1 - i))
      })
      p' = { ...p, publishedFP: nextFP, boundary: 8, words: moved,
        borrowed: if (p.policy == 2) p.borrowed else p.borrowed + 1 }
    },
  }
  action ownerReleases = all {
    p.held, F::s.gc == 0,
    p' = { ...p, held: false }, F::s' = F::s,
  }
  action returnFromC = all {
    not(p.held), F::foreignCallReturns, p' = p,
  }
  action reload = all {
    F::reloadRegisters, p' = { ...p, fp: p.publishedFP },
  }
  action fetchRA = all {
    F::s.phase == 5,
    F::s' = { ...F::s, phase: 6,
      returnedRA: if (p.fp == p.boundary) 9 else p.words.get(p.fp) },
    p' = p,
  }
  action returnToHost = all { F::hostFunctionReturns, p' = p }
  action advance = any { storeRA, publish, call, request, join, relocate,
    ownerReleases, returnFromC, reload, fetchRA, returnToHost }
  action step = any { advance, all { F::finished, p' = p } }
  val noWaitCycle = not(F::s.phase == 3 and F::s.gc == 1 and p.held and p.policy == 1)
  val cRootSafe = F::s.phase < 4 or p.borrowed == 7 + F::s.epoch
  val safe = F::safe and noWaitCycle and cRootSafe
  temporal completion = weakFair(advance, (F::s, p)).implies(eventually(F::s.phase == 7))
}
