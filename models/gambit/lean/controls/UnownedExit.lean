import WorkAccounting
open GambitSMP.WorkAccounting
example : EntryBalanced 0 1 7 7 := by unfold EntryBalanced; decide
