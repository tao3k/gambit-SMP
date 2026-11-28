namespace Gambit.CollectorCapacity

-- Value arithmetic only. QNT owns waiting/claim order; neither proves native
-- alias freedom, compiler memory ordering or completion of a package build.
theorem member_sections_do_not_imply_progress :
    12 ≥ 2 * 6 ∧
    (12 * 131072 - 12 * 131072 - 204808 : Int) < 131072 := by decide

theorem assigned_and_future_reserve_fit
    (assigned pending reserveSections reserveWords quantum : Nat)
    (reserveCovered : reserveWords ≤ reserveSections * quantum) :
    assigned * quantum + pending * quantum + reserveWords + quantum ≤
      (assigned + pending + reserveSections + 1) * quantum := by
  calc
    assigned * quantum + pending * quantum + reserveWords + quantum ≤
        assigned * quantum + pending * quantum + reserveSections * quantum + quantum :=
      Nat.add_le_add_right (Nat.add_le_add_left reserveCovered _) quantum
    _ = (assigned + pending + reserveSections + 1) * quantum := by
      simp only [Nat.add_mul, Nat.one_mul]

theorem observed_budget_repair_supplies_one_quantum :
    (15 * 131072 - 12 * 131072 - 204808 : Int) = 188408 ∧
    (188408 : Int) ≥ 131072 := by decide

-- Even a positive post-GC budget does not prove that a chunk has one consumer.
theorem arithmetic_is_not_unique_work :
    ((188408 : Int) ≥ 131072) ∧ ([0, 0] : List Nat) ≠ [0, 1] := by decide

end Gambit.CollectorCapacity
