-- Value algebra, not a second scheduler or proof of native signal safety.
namespace Gambit.NativeDeviceMonitor
def word (locked pending closed : Bool) : Nat :=
  (if locked then 1 else 0) + (if pending then 2 else 0) + (if closed then 4 else 0)
theorem word_bounded (l p c : Bool) : word l p c < 8 := by
  cases l <;> cases p <;> cases c <;> decide
theorem pending_not_lock (c : Bool) : word false true c ≠ word true false c := by
  cases c <;> decide
theorem pending_survives_unlock (c : Bool) : word true true c - 1 = word false true c := by
  cases c <;> decide
theorem close_preserves_pending (l p : Bool) : word l p true = word l p false + 4 := by
  cases l <;> cases p <;> decide
theorem no_counter_overflow : ∀ l p c, word l p c ≤ 7 := by
  intro l p c
  exact Nat.le_of_lt_succ (word_bounded l p c)
end Gambit.NativeDeviceMonitor
