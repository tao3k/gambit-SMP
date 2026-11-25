// Temporal loader protocol only. C refinement and cross-VM serialization OPEN.
module module_image_setup {
  var accepted: bool
  var phase: int
  var hydrated: bool
  var relocated: bool
  var borrowed: bool
  action init = all { accepted' = false, phase' = 0, hydrated' = false, relocated' = false, borrowed' = false }
  action validate = all { phase == 0, accepted' = true, phase' = 1, hydrated' = hydrated, relocated' = relocated, borrowed' = borrowed }
  action reject = all { not(accepted), phase' = phase, accepted' = accepted, hydrated' = hydrated, relocated' = relocated, borrowed' = borrowed }
  action hydrate = all { accepted, phase == 1, phase' = 2, hydrated' = true, accepted' = accepted, relocated' = relocated, borrowed' = borrowed }
  action fixup = all { phase == 2, phase' = 3, relocated' = true, hydrated' = hydrated, accepted' = accepted, borrowed' = borrowed }
  action repeatLoad = all { accepted, phase == 3, phase' = phase, relocated' = relocated, hydrated' = hydrated, accepted' = accepted, borrowed' = borrowed }
  action borrow = all { phase == 3, not(borrowed), borrowed' = true, phase' = phase, accepted' = accepted, hydrated' = hydrated, relocated' = relocated }
  action consume = all { borrowed, borrowed' = false, phase' = phase, accepted' = accepted, hydrated' = hydrated, relocated' = relocated }
  val safe = (not(hydrated) or accepted) and (not(relocated) or (hydrated and phase == 3))
  run refusalTest = init.then(reject).expect(safe and not(hydrated))
  run setupTest = init.then(validate).then(hydrate).then(fixup).expect(safe and relocated)
  run reloadTest = init.then(validate).then(hydrate).then(fixup).then(repeatLoad).expect(safe and relocated)
  run sameOwnerBorrowTest = init.then(validate).then(hydrate).then(fixup).then(borrow).then(consume).expect(safe and not(borrowed))
}
