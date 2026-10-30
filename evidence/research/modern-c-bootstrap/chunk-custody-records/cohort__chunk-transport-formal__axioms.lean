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
-- Destination identity ledger: repeated task delivery must not grant another
-- field writer. This is a ghost-list abstraction of packed C state, not a
-- proof of the packed CAS implementation or the chunk/frontier mapping.
def claimIdentity (seen : List Nat) (object : Nat) : List Nat :=
  if object ∈ seen then seen else object :: seen
theorem claimPreservesUniqueIdentities (seen : List Nat) (object : Nat)
    (h : seen.Nodup) : (claimIdentity seen object).Nodup := by
  unfold claimIdentity
  split
  · exact h
  · exact List.nodup_cons.mpr ⟨‹object ∉ seen›, h⟩
theorem duplicateTaskDoesNotCreateWriter (seen : List Nat) (object : Nat) :
    claimIdentity (claimIdentity seen object) object = claimIdentity seen object := by
  unfold claimIdentity
  split <;> simp_all
-- No theorem here claims
-- Local frontier selection and FIFO publication must consume the same private
-- identity. Physical interval disjointness is a separate refinement premise.
theorem localChunkCannotBeQueued (localChunks queued : List Nat) (c : Nat)
    (partition : ∀ x, x ∈ localChunks → x ∉ queued) (owned : c ∈ localChunks) :
    c ∉ queued := partition c owned
theorem chunkCompletionDoesNotPayTail (tail : Nat) (pending : 0 < tail) :
    ¬ (tail = 0) := by omega
theorem sourceChargePlusPacking (copied source markers terminal capacity : Nat)
    (sourceBound : copied ≤ source)
    (physicalGrant : source + markers + terminal ≤ capacity) :
    copied + markers + terminal ≤ capacity := by omega
-- This is not a derivation of sourceBound or of the physicalGrant.
-- No theorem here claims
-- C-memory-model refinement, worker liveness,
-- destination packing, or a bound on arbitrary native retained resources.
end Gambit.CopyCustody

#print axioms Gambit.CopyCustody.copyBoundNeedsUniqueSources
#print axioms Gambit.CopyCustody.isolationDoesNotRequireJoin
#print axioms Gambit.CopyCustody.nativeReuseStillNeedsJoin
#print axioms Gambit.CopyCustody.unknownCreateCannotIsolate
#print axioms Gambit.CopyCustody.allocatedCapacityIsNotCopyBound
#print axioms Gambit.CopyCustody.claimPreservesUniqueIdentities
#print axioms Gambit.CopyCustody.duplicateTaskDoesNotCreateWriter
#print axioms Gambit.CopyCustody.localChunkCannotBeQueued
#print axioms Gambit.CopyCustody.chunkCompletionDoesNotPayTail
#print axioms Gambit.CopyCustody.sourceChargePlusPacking
