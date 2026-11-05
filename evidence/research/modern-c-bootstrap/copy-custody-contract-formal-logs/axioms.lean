import Std
import Std
namespace Gambit.CopyCustody
-- Abstract source-count law; injective source identity and physical packing
-- are explicit hypotheses, not consequences of a fromspace range test.
theorem copyBoundNeedsUniqueSources (wins sources copied capacity : Nat)
    (unique : wins ≤ sources) (charge : copied = wins)
    (packing : sources ≤ capacity) : copied ≤ capacity := by omega
structure AbortDomain where
  abortPublished : Bool
  knownCreate : Bool
  entered : Bool
  empty : Bool
  nativeStable : Bool
  joined : Bool
def Isolated (d : AbortDomain) : Prop :=
  d.abortPublished = true ∧ d.knownCreate = true ∧ d.entered = false ∧
  d.empty = true ∧ d.nativeStable = true
def NativeReusable (d : AbortDomain) : Prop := d.joined = true
theorem isolationDoesNotRequireJoin (d : AbortDomain) (h : Isolated d) :
    Isolated { d with joined := false } := h
theorem nativeReuseStillNeedsJoin (d : AbortDomain)
    (h : NativeReusable d) : d.joined = true := h
theorem unknownCreateCannotIsolate (d : AbortDomain)
    (h : d.knownCreate = false) : ¬Isolated d := by
  intro hi
  have hc := hi.2.1
  simp [h] at hc
theorem allocatedCapacityIsNotCopyBound : ¬(24 ≥ 22 → 2 ≥ 3) := by decide
-- No theorem here claims C-memory-model refinement, worker liveness,
-- destination packing, or a bound on arbitrary native retained resources.
end Gambit.CopyCustody
#print axioms Gambit.CopyCustody.copyBoundNeedsUniqueSources
#print axioms Gambit.CopyCustody.isolationDoesNotRequireJoin
#print axioms Gambit.CopyCustody.nativeReuseStillNeedsJoin
#print axioms Gambit.CopyCustody.unknownCreateCannotIsolate
#print axioms Gambit.CopyCustody.allocatedCapacityIsNotCopyBound
