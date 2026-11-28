/- Conditional modern-C control laws. Prefix reachability below is a small abstract refinement,
   not a simulation of the whole Quint model or Gambit/C weak memory. -/
import Std
namespace GambitSMP.RequestRetirement
structure Frontier where
  low : Nat
  next : Nat
  done : Nat → Bool

def PrefixSafe (f : Frontier) := ∀ i, i < f.low → f.done i = true
def mark (f : Frontier) (k : Nat) : Frontier := {f with done := fun i => if i=k then true else f.done i}
def advance (f : Frontier) : Frontier := {f with low := f.low+1}
theorem markPreservesPrefix (f : Frontier) (k : Nat) (h : PrefixSafe f) : PrefixSafe (mark f k) := by
  intro i hi
  simp only [mark]
  split
  · rfl
  · exact h i hi
theorem advanceNeedsExactHead (f : Frontier) (h : PrefixSafe f) (head : f.done f.low=true) : PrefixSafe (advance f) := by
  intro i hi
  have cut : i < f.low ∨ i=f.low := by simp only [advance] at hi; omega
  rcases cut with less | eq
  · exact h i less
  · simpa [advance,eq] using head
inductive Step : Frontier → Frontier → Prop where
 | settle (f : Frontier) (k : Nat) : Step f (mark f k)
 | compress (f : Frontier) (head : f.done f.low=true) : Step f (advance f)
theorem stepPreservesPrefix {f g : Frontier} (h : PrefixSafe f) (s : Step f g) : PrefixSafe g := by
  cases s with
  | settle k => exact markPreservesPrefix f k h
  | compress head => exact advanceNeedsExactHead f h head
inductive Reach (f : Frontier) : Frontier → Prop where
 | refl : Reach f f
 | tail {g h : Frontier} : Reach f g → Step g h → Reach f h
theorem reachablePrefix {f g : Frontier} (h : PrefixSafe f) (r : Reach f g) : PrefixSafe g := by
  induction r with
  | refl => exact h
  | tail _ step ih => exact stepPreservesPrefix ih step

theorem maxSeenCannotSkipHole : ∃ f : Frontier, f.done 1=true ∧ ¬ PrefixSafe {f with low:=2} := by
  refine ⟨⟨0,2,fun i=>i==1⟩,by decide,?_⟩
  intro h
  have bad := h 0 (by decide)
  contradiction

def Admission (low next width limit : Nat) := low≤next ∧ next-low<width ∧ next<limit
theorem reserveBoundsWindow (low next width limit : Nat) (h : Admission low next width limit) : next+1-low≤width := by
  simp only [Admission] at h; omega
theorem reserveNeverWraps (low next width limit : Nat) (h : Admission low next width limit) : next+1≤limit := by
  simp only [Admission] at h; omega
theorem exhaustedRefuses (low width limit : Nat) : ¬ Admission low limit width limit := by simp [Admission]
theorem byteProductCheck (w h max : Nat) (nz : h>0) (fits : w≤max/h) : w*h≤max := (Nat.le_div_iff_mul_le nz).mp fits
structure Key where
  vm : Nat
  generation : Nat
  sequence : Nat
  deriving DecidableEq
theorem nextGenerationRejectsOld (vm generation sequence : Nat) :
 (Key.mk vm generation sequence) ≠ (Key.mk vm (generation+1) sequence) := by
  intro h
  have := congrArg Key.generation h
  simp at this
theorem expiredKeyRejects (low sequence : Nat) (old : sequence<low) : ¬ low≤sequence := by omega
structure Custody where
  source : Bool
  descriptor : Bool
  needed : Bool
  owner : Bool
  vmEscrow : Bool
  published : Bool
  resultAck : Bool
  queryPin : Bool
  deliveryPin : Bool
  sourceScan : Bool
  deriving DecidableEq
def Covered (c : Custody) := c.needed=true → c.source=true ∨ c.descriptor=true
def PreflightOOM (c : Custody) := c
-- OOM is identity only in the proposed allocation-free published protocol, not existing malloc behavior.
theorem oomRetainsCoverage (c : Custody) (h : Covered c) : Covered (PreflightOOM c) := h
theorem oomDoesNotInventPublication (c : Custody) : (PreflightOOM c).published=c.published := rfl
def ExitSafe (c : Custody) := c.owner=false → c.vmEscrow=true
def leave (c : Custody) := {c with owner:=false}
theorem exitRequiresReservedCustody (c : Custody) (e : c.vmEscrow=true) : ExitSafe (leave c) := by simp [ExitSafe,leave,e]
def Reclaimable (c : Custody) := c.resultAck=true ∧ c.source=false ∧ c.descriptor=false ∧ c.queryPin=false ∧ c.deliveryPin=false ∧ c.sourceScan=false
theorem resultUnknownKeepsRecord (c : Custody) (h : c.resultAck=false) : ¬ Reclaimable c := by simp [Reclaimable,h]
theorem queryPinKeepsRecord (c : Custody) (h : c.queryPin=true) : ¬ Reclaimable c := by simp [Reclaimable,h]
theorem deliveryPinKeepsRecord (c : Custody) (h : c.deliveryPin=true) : ¬ Reclaimable c := by simp [Reclaimable,h]
theorem sourceScanKeepsRecord (c : Custody) (h : c.sourceScan=true) : ¬ Reclaimable c := by simp [Reclaimable,h]
def releaseSource (c : Custody) := {c with source:=false}
theorem releasingSourceNeedsOtherCustody (c : Custody) (h : c.descriptor=true ∨ c.needed=false) : Covered (releaseSource c) := by
  rcases h with root | unused
  · simp [Covered,releaseSource,root]
  · simp [Covered,releaseSource,unused]
theorem fixedPoolNotHistorySized (window perRecord bitmap domain : Nat) :
 window*perRecord+bitmap+domain = domain+bitmap+window*perRecord := by omega
end GambitSMP.RequestRetirement
