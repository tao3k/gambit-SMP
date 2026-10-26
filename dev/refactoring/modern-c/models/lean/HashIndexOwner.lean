import Std
namespace Gambit.HashIndexOwner
-- Key positions are preserved under a GC relocation only when the chosen
-- hash is stable for that semantic key. This premise excludes address hashing.
def Valid (hash : Nat → Nat) (keys positions : Nat → Nat) : Prop :=
  ∀ i, positions i = hash (keys i)

theorem semanticTransport (hash before after positions : Nat → Nat)
    (valid : Valid hash before positions)
    (stable : ∀ i, hash (after i) = hash (before i)) : Valid hash after positions := by
  intro i
  rw [stable i]
  exact valid i

theorem nativeRebuild (hash keys : Nat → Nat) :
    Valid hash keys (fun i => hash (keys i)) := by
  intro i
  rfl

theorem differentAlgorithmCannotPreserve (scheme native keys positions : Nat → Nat)
    (rebuilt : Valid native keys positions) (i : Nat)
    (different : native (keys i) ≠ scheme (keys i)) : ¬ Valid scheme keys positions := by
  intro hs
  exact different ((rebuilt i).symm.trans (hs i))

-- Read-only use after relocation requires no new mutator-side reconstruction;
-- unrelated pre-existing reconstruction debt must still be discharged.
theorem admissionNeedsDebtClosure (lookup debt : Prop)
    (guard : lookup → ¬ debt) (read : lookup) : ¬ debt := guard read
end Gambit.HashIndexOwner
