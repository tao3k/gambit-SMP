import WorkAccounting
open GambitSMP.WorkAccounting
example : ServiceReady true false := by unfold ServiceReady; decide
