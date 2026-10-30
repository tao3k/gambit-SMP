import WorkAccounting
open GambitSMP.WorkAccounting
example : InactiveRootsReady true true := by unfold InactiveRootsReady; decide
