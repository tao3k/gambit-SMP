import WorkAccounting

namespace GambitSMP.SavedStackRootClosure

inductive Reaches {Node : Type} (root : Node → Prop) (edge : Node → Node → Prop) : Node → Prop
  | root {node} : root node → Reaches root edge node
  | step {source target} : Reaches root edge source → edge source target → Reaches root edge target

-- Root identity alone is insufficient: each traversed payload edge must also
-- belong to the collector's actual scan relation.
theorem explicitEdgesPreserveReachability {Node : Type}
    (roots admitted : Node → Prop) (edges scanned : Node → Node → Prop)
    (rootCoverage : ∀ n, roots n → admitted n)
    (edgeCoverage : ∀ a b, edges a b → scanned a b)
    {node : Node} (path : Reaches roots edges node) : Reaches admitted scanned node := by
  induction path with
  | root h => exact .root (rootCoverage _ h)
  | step _ e ih => exact .step ih (edgeCoverage _ _ e)

inductive Role | survivor | permanent | frame
  deriving DecidableEq

def Roots (n : Role) : Prop := n = .survivor
def Ordinary (a b : Role) : Prop := a = .survivor ∧ b = .permanent
def Payload (a b : Role) : Prop := Ordinary a b ∨ (a = .permanent ∧ b = .frame)

theorem pointerToPermanentIsNotPayloadScan :
    Reaches Roots Payload .frame ∧ ¬ Reaches Roots Ordinary .frame := by
  constructor
  · exact .step (.step (.root rfl) (Or.inl ⟨rfl, rfl⟩)) (Or.inr ⟨rfl, rfl⟩)
  · intro path
    have bound : ∀ n, Reaches Roots Ordinary n → n = .survivor ∨ n = .permanent := by
      intro n p
      cases p with
      | root h => exact Or.inl h
      | step _ e => exact Or.inr e.2
    rcases bound _ path with impossible | impossible <;> cases impossible

-- Completeness is a premise with an explicit range, not a nonempty-list test.
-- A legitimately empty actual consumer set also satisfies this theorem.
theorem declaredClosureCoversActualConsumers {Consumer : Type}
    (actual declared finished : Consumer → Prop)
    (complete : ∀ c, actual c → declared c)
    (closed : ∀ c, declared c → finished c) :
    ∀ c, actual c → finished c := by
  intro c pending
  exact closed c (complete c pending)

theorem headClosureDoesNotCloseTail {Consumer : Type}
    (actual finished : Consumer → Prop) (tail : Consumer)
    (existsTail : actual tail) (pendingTail : ¬ finished tail) :
    ¬ (∀ c, actual c → finished c) := by
  intro closed
  exact pendingTail (closed tail existsTail)

-- Two half flips can restore an address/half parity, not an incarnation.
theorem twoCyclesDoNotRestoreIdentity (epoch : Nat) :
    ¬ WorkAccounting.SameGeneration epoch (epoch + 2) := by
  unfold WorkAccounting.SameGeneration
  exact Nat.ne_of_lt (Nat.lt_trans (Nat.lt_succ_self epoch)
    (Nat.lt_succ_self (epoch + 1)))

#print axioms explicitEdgesPreserveReachability
#print axioms pointerToPermanentIsNotPayloadScan
#print axioms declaredClosureCoversActualConsumers
#print axioms headClosureDoesNotCloseTail
#print axioms twoCyclesDoNotRestoreIdentity

end GambitSMP.SavedStackRootClosure
