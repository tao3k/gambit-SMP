import RuntimeEntryContracts

-- Drained native activations do not imply no retained Scheme consumers.
example : (0 : Nat) = 0 → (1 : Nat) = 0 := by decide

example : (fun _ : Nat => 2) 0 = 1 := by decide

example : (some 1 : Option Nat).getD 2 = 2 := by decide
example : (2 : Nat) ∈ ([0, 1] : List Nat) := by decide

open GambitSMP.RuntimeEntryContracts

example : Disjoint (0, 2) (0, 1) := by
  unfold Disjoint
  decide
example : Compatible ⟨0, 0, true⟩ ⟨1, 0, true⟩ := by
  unfold Compatible
  decide
example : reachesB 0 none = true := by
  unfold reachesB
  decide
example : Disjoint (2, 1) (0, 3) := by
  unfold Disjoint
  decide
example : (3 : Nat) < 2 := by
  decide
example : (([1, 7] : List Nat).map (fun n => n + 1)).tail = [7] := by
  decide
example : (true, false).1 = true → (true, false).2 = true := by
  decide
example : (0 : Nat) < 1 ∧ (1 : Nat) < 0 := by
  decide
example : Disjoint (0, 2) (1, 1) := by
  unfold Disjoint
  decide
-- Locally ready slot 0 says nothing about visible binding to slot 1.
example : ((0 : Nat) = 0 → (0 : Nat) = 0) ∧ (1 : Nat) = 0 := by
  decide
example : (3 : Nat) % 2 = (3 : Nat) % 4 := by
  decide
example : List.Nodup (([0, 1] : List Nat) ++ [1]) := by
  decide
