import WorkAccounting
open GambitSMP.WorkAccounting
example : activeCount [⟨true, true, false⟩] = 0 := by decide
