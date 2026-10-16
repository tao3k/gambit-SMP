module checkpoint_budget_consumption {
  import checkpoint_budget_ledger as L from "./checkpoint_budget_ledger"
  // The imported actors are producer and consumer, not hardware workers.
  type Cache = { bypass: bool, sameLedger: bool, receiptMatch: bool,
    loaded: bool, receiptAtLoad: bool, chargedAtLoad: bool, heldAtLoad: bool }
  var cacheState: Cache
  pure def initial(bypass: bool, sameLedger: bool, receiptMatch: bool): Cache = {
    bypass: bypass, sameLedger: sameLedger, receiptMatch: receiptMatch,
    loaded: false, receiptAtLoad: false, chargedAtLoad: false, heldAtLoad: false }
  action init = all { L::s' = L::initial("atomic"), cacheState' = initial(false, true, true) }
  action initWrongReceipt = all { L::s' = L::initial("atomic"), cacheState' = initial(true, true, false) }
  action initUncharged = all { L::s' = L::initial("atomic"), cacheState' = initial(true, true, true) }
  action initOtherLedger = all { L::s' = L::initial("atomic"), cacheState' = initial(true, false, true) }
  val producerCharged = L::s.phase.get(0) == "done" and L::s.quiescent.get(0) and
    L::s.charged.get(0) >= L::s.used.get(0)
  val consumerHeld = L::s.phase.get(1) == "running" and L::s.reserved.get(1) > 0
  val boundReceipt = cacheState.sameLedger and cacheState.receiptMatch
  val ready = producerCharged and consumerHeld and boundReceipt
  action load = all { not(cacheState.loaded), ready or cacheState.bypass,
    L::s' = L::s, cacheState' = { ...cacheState, loaded: true,
      receiptAtLoad: boundReceipt, chargedAtLoad: producerCharged, heldAtLoad: consumerHeld } }
  action ledgerStep = all { L::step, cacheState' = cacheState }
  action step = any { load, ledgerStep }
  val receiptSafe = cacheState.loaded.implies(cacheState.receiptAtLoad)
  val chargeSafe = cacheState.loaded.implies(cacheState.chargedAtLoad)
  val holdSafe = cacheState.loaded.implies(cacheState.heldAtLoad)
  val safe = L::safe and receiptSafe and chargeSafe and holdSafe
  // A hold may be terminated or settled before reading. This proves progress
  // only while eligibility remains enabled; no successful build is inferred.
  temporal progress = weakFair(load, Set((L::s, cacheState)))
    .implies(always(ready.implies(eventually(cacheState.loaded or not(ready)))))
  run chargedHandoffTest = init
    .then(all { L::reserve(0, 2), cacheState' = cacheState })
    .then(all { L::consume(0), cacheState' = cacheState })
    .then(all { L::terminate(0), cacheState' = cacheState })
    .then(all { L::settle(0), cacheState' = cacheState })
    .then(all { L::reserve(1, 2), cacheState' = cacheState }).then(load)
    .then(all { assert(safe), assert(cacheState.loaded), L::s' = L::s, cacheState' = cacheState })
  run wrongReceiptControlTest = initWrongReceipt.then(load)
    .then(all { assert(not(receiptSafe)), L::s' = L::s, cacheState' = cacheState })
  run unchargedProducerControlTest = initUncharged.then(load)
    .then(all { assert(not(chargeSafe)), L::s' = L::s, cacheState' = cacheState })
  run wrongLedgerControlTest = initOtherLedger.then(load)
    .then(all { assert(not(receiptSafe)), L::s' = L::s, cacheState' = cacheState })
}
