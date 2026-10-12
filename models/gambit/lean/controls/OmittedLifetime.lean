import WorkAccounting

open GambitSMP.WorkAccounting

-- Expected elaboration failure: the uncounted producer retains private work.
example : uncountedProducer.privateWork = false := by
  decide
