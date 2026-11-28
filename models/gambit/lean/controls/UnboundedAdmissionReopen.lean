import LeanPoo.Functional.TransformationResources

-- A fourth gate operation cannot be hidden in a two-member 2*N gate budget.
example : (2 : Nat) + 2 + 2 + 1 ≤ 2 + 2 * 2 := by
  decide
