import Std.Tactic
namespace GcDrainRetirementCut
structure Roots where
  r1 : Bool
  r2 : Bool
  cache : Bool
  bank : Bool
  saved : Bool
  snapshot : Bool
  deriving DecidableEq
def voidEpilogue (r : Roots) : Roots := { r with r1 := false }
theorem voidLeavesR4 (r : Roots) : (voidEpilogue r).cache = r.cache := rfl
def registry (r : Roots) : Roots := { r with r1 := false, r2 := false }
theorem registryLeavesR4 (r : Roots) : (registry r).bank = r.bank := rfl
def clearBank (r : Roots) : Roots := { r with bank := false }
def clearCache (r : Roots) : Roots := { r with cache := false }
def sync (r : Roots) : Roots := { r with bank := r.cache }
theorem bankClearNotEnough (r : Roots) (h : r.cache = true) :
    (sync (clearBank r)).bank = true := h
theorem cacheClearNotEnough (r : Roots) (h : r.bank = true) :
    (clearCache r).bank = true := h
def restore (r : Roots) : Roots := { r with saved := false, cache := r.cache || r.saved }
theorem restoreTransfers (r : Roots) (h : r.saved = true) :
    (restore r).saved = false ∧ (restore r).cache = true := by simp [restore, h]
def absent (r : Roots) : Prop := r.r1 = false ∧ r.r2 = false ∧ r.cache = false ∧
  r.bank = false ∧ r.saved = false ∧ r.snapshot = false
def ready (r : Roots) (normal bound clean matched : Bool) : Prop :=
  absent r ∧ normal = true ∧ bound = true ∧ clean = true ∧ matched = true
theorem readyExcludesRestore (r : Roots) (n b c m : Bool) (h : ready r n b c m) :
    r.saved = false ∧ r.snapshot = false := h.1.2.2.2.2
theorem readyNeedsIdentity (r : Roots) (n b c m : Bool) (h : ready r n b c m) : m = true := h.2.2.2.2
def retire (r : Roots) : Roots := { r with r1 := false, r2 := false, cache := false, bank := false }
-- Only dead target-bearing locations are eligible; live-register/effect proof is a source premise.
theorem retireSyncClosed (r : Roots) (s : r.saved = false) (p : r.snapshot = false) :
    absent (sync (retire r)) := by simp [absent, sync, retire, s, p]
end GcDrainRetirementCut
