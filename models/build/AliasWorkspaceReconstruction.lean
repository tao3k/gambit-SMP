import Std.Tactic
namespace AliasWorkspaceReconstruction
def addr (w n : Nat) := 100+10*w+n
theorem relocationInjective (w v i j : Nat) (hi : i<10) (hj : j<10)
    (h : addr w i = addr v j) : w=v ∧ i=j := by unfold addr at h; omega
theorem tagIsCanonical (w : Nat) : addr w 0 ≠ 7 := by unfold addr; omega
theorem privateDistinct (w v : Nat) (h : w ≠ v) : addr w 1 ≠ addr v 1 := by unfold addr; omega
structure Provider where
  self : Nat
  target : Nat
def rebuild (w : Nat) : Provider := ⟨addr w 1,addr w 0⟩
theorem selfCycle (w : Nat) : (rebuild w).self = addr w 1 := rfl
structure Observation where
  decl : List Nat
  identity : Nat
  origin : Nat
  deriving DecidableEq
theorem originDistinct : Observation.mk [1,2] 0 0 ≠ Observation.mk [1,2] 0 1 := by decide
theorem declarationDistinct : Observation.mk [1,2] 0 0 ≠ Observation.mk [2,1] 0 0 := by decide
theorem unknownHolds (known live : Bool) (h : known=false → live=true) (u : known=false) : live=true := h u
theorem costPositive (oldWork newWork saved freeze reconstruct validate : Nat)
    (h : newWork+saved=oldWork+freeze+reconstruct+validate)
    (p : freeze+reconstruct+validate<saved) : newWork<oldWork := by omega
end AliasWorkspaceReconstruction
