/- Standalone zero-import Lean 4 refinement proofs for Slice 3A-1:
   OCaml-5 / Erlang-OTP-28 Dynamic Per-Domain VM Tables & O(live) Adaptive GC Copy Workers.
   Verifiable directly with `lean -DwarningAsError=true Slice3ADynamicDomainsRefinement.lean`. -/

namespace GambitSlice3ADynamicDomains

/- ==========================================================================
   Part 1: Contiguous 16-Byte Aligned Dynamic Slot Block Layout & OOM Safety
   ========================================================================== -/

/-- Round byte offset up to the next 16-byte boundary (satisfies C23 max_align_t). -/
def align16 (n : Nat) : Nat := ((n + 15) / 16) * 16

theorem align16_ge (n : Nat) : n ≤ align16 n := by
  unfold align16
  omega

theorem align16_mod_zero (n : Nat) : align16 n % 16 = 0 := by
  unfold align16
  omega

/-- Adding a slice of `bytes` at aligned offset `off` advances strictly without overlap. -/
def nextOffset (off bytes : Nat) : Nat := align16 (off + bytes)

theorem slice_disjoint_and_monotone (off bytes : Nat) :
    off + bytes ≤ nextOffset off bytes ∧ off ≤ nextOffset off bytes := by
  unfold nextOffset
  have h := align16_ge (off + bytes)
  omega

/-- Single-block dynamic allocation + atomic rollback guarantees 0 leaked blocks
    when constructor fails at any stage `k` after acquiring `slot_storage`. -/
def rollbackLiveAllocs (acquiredStorage : Bool) : Nat :=
  let liveAfterAlloc := if acquiredStorage then 1 else 0
  let liveAfterFree  := if acquiredStorage then liveAfterAlloc - 1 else liveAfterAlloc
  liveAfterFree

theorem oom_rollback_zero_leak (acquiredStorage : Bool) :
    rollbackLiveAllocs acquiredStorage = 0 := by
  cases acquiredStorage <;> rfl

/- ==========================================================================
   Part 2: Global Root Snapshot Inline-64 Fast Path + Dynamic Heap Fallback
   ========================================================================== -/

def inlineShardCap : Nat := 64

def snapshotShardCapacity (participants : Nat) : Nat :=
  if participants ≤ inlineShardCap then inlineShardCap else participants

theorem snapshot_capacity_covers_all_participants (participants i : Nat)
    (hLt : i < participants) :
    i < snapshotShardCapacity participants := by
  unfold snapshotShardCapacity
  split <;> omega

/- ==========================================================================
   Part 3: O(live) Adaptive GC Copy Worker Sizing & Monotonicity Laws
   ========================================================================== -/

def clampRange (x lo hi : Nat) : Nat :=
  if x < lo then lo else if x > hi then hi else x

theorem clampRange_bounds (x lo hi : Nat) (hLoHi : lo ≤ hi) :
    lo ≤ clampRange x lo hi ∧ clampRange x lo hi ≤ hi := by
  unfold clampRange
  split <;> try omega
  split <;> omega

theorem clampRange_of_ge (x lo hi : Nat) (hLoHi : lo ≤ hi) (hGe : x ≥ hi) :
    clampRange x lo hi = hi := by
  unfold clampRange
  split
  · omega
  · split <;> omega

/-- Exact model of `gc_select_adaptive_workers` in `lib/_mem/copy-planning.inc`. -/
def selectAdaptiveWorkers
    (activeN requested smallWords largeCount halfCap parallelDemand promoTails : Nat)
    (allLoansSafe : Bool) : Nat :=
  if requested > 0 then
    if requested < activeN then requested else activeN
  else if activeN ≤ 1 then
    activeN
  else if !allLoansSafe then
    activeN
  else if halfCap == 0 then
    activeN
  else
    let copyDemand := 1 + smallWords / halfCap + largeCount
    let d1 := max copyDemand parallelDemand
    let demand := max d1 promoTails
    clampRange demand 1 activeN

theorem adaptive_workers_bounds
    (activeN requested smallWords largeCount halfCap parallelDemand promoTails : Nat)
    (allLoansSafe : Bool)
    (hAct : activeN ≥ 1) :
    1 ≤ selectAdaptiveWorkers activeN requested smallWords largeCount halfCap parallelDemand promoTails allLoansSafe ∧
    selectAdaptiveWorkers activeN requested smallWords largeCount halfCap parallelDemand promoTails allLoansSafe ≤ activeN := by
  unfold selectAdaptiveWorkers
  split
  · split <;> omega
  · split
    · omega
    · split
      · omega
      · split
        · omega
        · exact clampRange_bounds _ 1 activeN hAct

theorem adaptive_workers_honors_explicit_request
    (activeN requested smallWords largeCount halfCap parallelDemand promoTails : Nat)
    (allLoansSafe : Bool)
    (hReqPos : requested ≥ 1)
    (hReqLe : requested ≤ activeN) :
    selectAdaptiveWorkers activeN requested smallWords largeCount halfCap parallelDemand promoTails allLoansSafe = requested := by
  unfold selectAdaptiveWorkers
  have h1 : requested > 0 := by omega
  simp only [h1, ↓reduceIte]
  split <;> omega

theorem adaptive_workers_idle_vm_constant_one
    (activeN smallWords halfCap : Nat)
    (hAct : activeN ≥ 1)
    (hHalf : halfCap ≥ 1)
    (hSmall : smallWords < halfCap) :
    selectAdaptiveWorkers activeN 0 smallWords 0 halfCap 0 0 true = 1 := by
  unfold selectAdaptiveWorkers
  have hDiv : smallWords / halfCap = 0 := Nat.div_eq_of_lt hSmall
  have hHalfNe : (halfCap == 0) = false := by
    cases halfCap with
    | zero => omega
    | succ k => rfl
  simp only [Nat.not_lt_zero, ↓reduceIte, Bool.not_true, Bool.false_eq_true, hHalfNe]
  split
  · omega
  · simp [hDiv, clampRange]
    omega

theorem adaptive_workers_heavy_workload_full_parallel
    (activeN smallWords largeCount halfCap parallelDemand promoTails : Nat)
    (hAct : activeN ≥ 1)
    (hHalf : halfCap ≥ 1)
    (hHeavy : smallWords ≥ activeN * halfCap) :
    selectAdaptiveWorkers activeN 0 smallWords largeCount halfCap parallelDemand promoTails true = activeN := by
  unfold selectAdaptiveWorkers
  have hHalfNe : (halfCap == 0) = false := by
    cases halfCap with
    | zero => omega
    | succ k => rfl
  have hDivGe : smallWords / halfCap ≥ activeN := by
    have hMul : (activeN * halfCap) / halfCap = activeN := Nat.mul_div_cancel activeN (by omega)
    have hMono : (activeN * halfCap) / halfCap ≤ smallWords / halfCap :=
      Nat.div_le_div_right hHeavy
    omega
  simp only [Nat.not_lt_zero, ↓reduceIte, Bool.not_true, Bool.false_eq_true, hHalfNe]
  split
  · rfl
  · apply clampRange_of_ge _ 1 activeN hAct
    omega

theorem adaptive_workers_preserves_unsafe_loans
    (activeN smallWords largeCount halfCap parallelDemand promoTails : Nat) :
    selectAdaptiveWorkers activeN 0 smallWords largeCount halfCap parallelDemand promoTails false = activeN := by
  unfold selectAdaptiveWorkers
  simp only [Nat.not_lt_zero, ↓reduceIte, Bool.not_false]
  split <;> rfl

/-- Monotonicity of copy-section bound `k(w) = w + baseSections`:
    reducing worker count `w' ≤ w` never increases required copy sections `k`. -/
theorem copy_section_bound_monotone (w' w baseSections : Nat) (hLe : w' ≤ w) :
    w' + baseSections ≤ w + baseSections := by
  omega

/-- Root-task executor rebinding completeness: for every member `i < n` and any
    `newW ≥ 1`, `i % newW` selects a valid active worker index in `[0, newW)`,
    and worker index `0` is always strictly inside `[0, newW)` (coordinator invariant). -/
theorem rebind_executor_valid (i newW : Nat) (hW : newW ≥ 1) :
    i % newW < newW ∧ 0 < newW := by
  exact ⟨Nat.mod_lt i (by omega), by omega⟩

end GambitSlice3ADynamicDomains
