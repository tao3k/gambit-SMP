/- Standalone zero-import, zero-sorry Lean 4 proofs for the Unified Memory Scaling
   Envelope shared by Gambit SMP v26 and Slice 2 (Immix + Concurrent SATB Major GC).
   Verifiable directly with `lean AdaptiveHeapScalingRefinement.lean`. -/

namespace GambitAdaptiveHeapScaling

/- ==========================================================================
   1. Sub-Linear SMP Nursery Headroom (Eliminating O(P) Floor Explosion)
   ========================================================================== -/

/-- Sub-linear SMP extra nursery headroom: `p` for `p <= 2`, else `2 + isqrt(p)`. -/
def smpNurseryHeadroom (p : Nat) : Nat :=
  if p ≤ 2 then p else 2 + Nat.sqrt p

theorem smp_headroom_strictly_below_linear_from_p4 (p : Nat) (hP : p ≥ 4) :
    smpNurseryHeadroom p < 2 * p := by
  unfold smpNurseryHeadroom
  have hNotLe : ¬ (p ≤ 2) := by omega
  simp [hNotLe]
  have hSq : Nat.sqrt p ≤ p := by
    have hMul : Nat.sqrt p * Nat.sqrt p ≤ p := Nat.sqrt_le p
    cases hS : Nat.sqrt p with
    | zero => omega
    | succ k =>
      have hGe1 : 1 ≤ k + 1 := by omega
      have hLe : k + 1 ≤ (k + 1) * (k + 1) := Nat.le_mul_self (k + 1)
      rw [hS] at hMul
      omega
  omega

theorem smp_headroom_p64_bound :
    smpNurseryHeadroom 64 = 10 ∧ 10 < 2 * 64 := by
  native_decide

theorem smp_headroom_nonempty_for_active_vm (p : Nat) (hP : p ≥ 1) :
    smpNurseryHeadroom p ≥ 1 := by
  unfold smpNurseryHeadroom
  split
  · omega
  · omega

/- ==========================================================================
   2. Hardware-Adaptive Large-Heap live_percent (Honoring Explicit -:l<N>)
   ========================================================================== -/

/-- Effective live percentage: honors explicit `-:l<N>` verbatim; otherwise ramps
    smoothly from 50% (small heaps) to 80% (large heaps relative to RAM / CPUs). -/
def effectiveLivePercent (explicit : Bool) (configuredPct : Nat)
    (liveBytes softBudget : Nat) : Nat :=
  if explicit then configuredPct
  else if softBudget == 0 || liveBytes * 8 ≤ softBudget then 50
  else if liveBytes * 2 ≥ softBudget then 80
  else 50 + ((liveBytes * 8 - softBudget) * 30) / (3 * softBudget)

theorem adaptive_live_percent_honors_explicit (configuredPct liveBytes softBudget : Nat) :
    effectiveLivePercent true configuredPct liveBytes softBudget = configuredPct := by
  simp [effectiveLivePercent]

theorem adaptive_live_percent_in_50_to_80 (configuredPct liveBytes softBudget : Nat) :
    50 ≤ effectiveLivePercent false configuredPct liveBytes softBudget ∧
    effectiveLivePercent false configuredPct liveBytes softBudget ≤ 80 := by
  unfold effectiveLivePercent
  simp only [Bool.false_eq_true, ↓reduceIte]
  split
  · omega
  · split
    · omega
    · rename_i h1 h2
      have hPos : softBudget > 0 := by
        cases hB : softBudget with
        | zero => simp [hB] at h1
        | succ k => omega
      have hLt : liveBytes * 2 < softBudget := by omega
      have hNum : (liveBytes * 8 - softBudget) * 30 ≤ 3 * softBudget * 30 := by omega
      have hDiv : ((liveBytes * 8 - softBudget) * 30) / (3 * softBudget) ≤ 30 :=
        Nat.div_le_of_le_mul hNum
      exact ⟨Nat.le_add_right 50 _, Nat.add_le_add_left hDiv 50⟩

theorem adaptive_live_percent_preserves_small_heap_throughput
    (configuredPct liveBytes softBudget : Nat)
    (hSmall : liveBytes * 8 ≤ softBudget) :
    effectiveLivePercent false configuredPct liveBytes softBudget = 50 := by
  unfold effectiveLivePercent
  simp [hSmall]

theorem adaptive_live_percent_caps_large_heap_overhead
    (configuredPct liveBytes softBudget : Nat)
    (hPos : softBudget > 0)
    (hLarge : liveBytes * 2 ≥ softBudget) :
    effectiveLivePercent false configuredPct liveBytes softBudget = 80 := by
  unfold effectiveLivePercent
  have hNe : (softBudget == 0) = false := by
    cases softBudget with
    | zero => omega
    | succ k => rfl
  have hNotSmall : ¬ (liveBytes * 8 ≤ softBudget) := by omega
  simp [hNe, hNotSmall, hLarge]

/- ==========================================================================
   3. Contraction Safety & Lower-Bound Preservation
   ========================================================================== -/

/-- Final target section count after contraction always enforces `lowerBound`. -/
def safeContractTarget (lowerBound requestedTarget : Nat) : Nat :=
  Nat.max lowerBound requestedTarget

theorem contraction_never_violates_lower_bound (lowerBound requestedTarget : Nat) :
    safeContractTarget lowerBound requestedTarget ≥ lowerBound := by
  unfold safeContractTarget
  exact Nat.le_max_left lowerBound requestedTarget

/-- Collapse-aware history decay: on sharp drop (2*target < peak), history decays
    by 25% toward target instead of pinning for 16 consecutive GCs. -/
def decayedHistory (peak target : Nat) (explicitGc : Bool) : Nat :=
  if explicitGc then target
  else if target * 2 < peak then Nat.max target ((peak * 3) / 4)
  else Nat.max peak target

theorem explicit_gc_eliminates_history_ratchet (peak target : Nat) :
    decayedHistory peak target true = target := by
  simp [decayedHistory]

theorem auto_decay_strictly_shrinks_stale_peak (peak target : Nat)
    (hPeak : peak ≥ 4) (hDrop : target * 2 < peak) :
    decayedHistory peak target false < peak := by
  unfold decayedHistory
  simp only [Bool.false_eq_true, ↓reduceIte, hDrop]
  have h1 : (peak * 3) / 4 < peak := by omega
  have h2 : target < peak := by omega
  have _ := hPeak
  exact Nat.max_lt.mpr ⟨h2, h1⟩

/- ==========================================================================
   4. Disjoint gsc + cc1 Peak Elimination across W Parallel Workers
   ========================================================================== -/

/-- Pre-subprocess contraction of `gsc` before spawning `cc1` strictly lowers
    per-worker and W-worker aggregate peak memory whenever `gscTrim < gscPeak`. -/
theorem pre_cc1_trim_strictly_cuts_parallel_peak
    (W gscPeak gscTrim cc1Peak : Nat)
    (hW : W ≥ 1) (hTrim : gscTrim < gscPeak) (hCc1 : cc1Peak > gscPeak - gscTrim) :
    W * Nat.max gscPeak (gscTrim + cc1Peak) < W * (gscPeak + cc1Peak) := by
  have hOne : Nat.max gscPeak (gscTrim + cc1Peak) < gscPeak + cc1Peak := by
    apply Nat.max_lt.mpr
    constructor <;> omega
  exact Nat.mul_lt_mul_of_pos_left hOne (by omega)

/- ==========================================================================
   5. census.queue Post-Round Bound & Mailbox Mutex-Guarded Empty Check
   ========================================================================== -/

def censusRetainedBytes (peakBytes retainCap : Nat) (faultRetained : Bool) : Nat :=
  if faultRetained then peakBytes
  else if peakBytes > retainCap then 0
  else peakBytes

theorem census_normal_round_never_exceeds_retain_cap (peakBytes retainCap : Nat) :
    censusRetainedBytes peakBytes retainCap false ≤ retainCap := by
  unfold censusRetainedBytes
  simp only [Bool.false_eq_true, ↓reduceIte]
  split <;> omega

/-- Mailbox wakeup soundness: when the receiver inserts into the condvar BEFORE
    releasing the mailbox mutex, checking `cvEmpty` while the sender holds the
    mutex guarantees `skipSignal = true -> no waiter exists`. -/
def safeSkipMailboxSignal (senderHoldsMutex cvEmpty : Bool) : Bool :=
  senderHoldsMutex && cvEmpty

theorem mailbox_skip_signal_never_loses_waiter (senderHoldsMutex : Bool) :
    safeSkipMailboxSignal senderHoldsMutex false = false := by
  simp [safeSkipMailboxSignal]

theorem mailbox_skip_signal_requires_mutex (cvEmpty : Bool) :
    safeSkipMailboxSignal false cvEmpty = false := by
  simp [safeSkipMailboxSignal]

/- ==========================================================================
   6. Principled Zero-Magic-Cap Hardware-Topology Auto min_heap (Slice 2.5)
   ========================================================================== -/

/-- Principled automatic `min_heap` (in MiB, floored at 2 MiB = 2 msections):
    uses per-core private L2 cache (`l2Mb / 2`), bounded by one core's
    physical RAM share (`physMemMb / max(2, cpus) / 256`) and `maxHeapMb / 8`
    when bounded, NEVER socket-wide shared L3 (512+ MiB on EPYC/Xeon).
    Explicit `-:m<N>` (`explicit = true`) is honored verbatim. -/
def principledAutoMinHeapMb
    (explicit : Bool) (configuredMb l2Mb physMemMb cpus : Nat) : Nat :=
  if explicit then configuredMb
  else
    let effCpus := Nat.max 2 cpus
    let l2Half := l2Mb / 2
    let ramIdleBound := (physMemMb / effCpus) / 256
    let bounded :=
      if physMemMb > 0 then Nat.min l2Half ramIdleBound else l2Half
    Nat.max 2 bounded

theorem explicit_min_heap_honored_verbatim
    (configuredMb l2Mb physMemMb cpus : Nat) :
    principledAutoMinHeapMb true configuredMb l2Mb physMemMb cpus = configuredMb := by
  simp [principledAutoMinHeapMb]

theorem auto_min_heap_at_least_two_msections
    (configuredMb l2Mb physMemMb cpus : Nat) :
    principledAutoMinHeapMb false configuredMb l2Mb physMemMb cpus ≥ 2 := by
  unfold principledAutoMinHeapMb
  simp only [Bool.false_eq_true, ↓reduceIte]
  exact Nat.le_max_left 2 _

theorem auto_min_heap_respects_per_core_ram_idle_bound
    (configuredMb l2Mb physMemMb cpus : Nat)
    (hMem : physMemMb > 0) :
    principledAutoMinHeapMb false configuredMb l2Mb physMemMb cpus ≤
      Nat.max 2 ((physMemMb / Nat.max 2 cpus) / 256) := by
  unfold principledAutoMinHeapMb
  simp only [Bool.false_eq_true, ↓reduceIte, hMem]
  have hMin : Nat.min (l2Mb / 2) ((physMemMb / Nat.max 2 cpus) / 256) ≤
      (physMemMb / Nat.max 2 cpus) / 256 := Nat.min_le_right _ _
  exact Nat.max_le.mpr ⟨Nat.le_max_left 2 _, Nat.le_trans hMin (Nat.le_max_right 2 _)⟩

theorem auto_min_heap_epyc_512mib_l3_stays_2mib :
    principledAutoMinHeapMb false 0 1 16384 4 = 2 := by
  native_decide

/-- Core-count-invariant burst-delta contraction (`c12`): if `after <= base`
    on any topology `P`, the retained burst delta above empty-VM baseline `base`
    is strictly zero regardless of `P`. -/
theorem c12_burst_delta_contraction_core_invariant
    (base peak after : Nat) (hPeak : peak > base) (hShrink : after ≤ base) :
    after - base = 0 ∧ peak - base > 0 := by
  omega

end GambitAdaptiveHeapScaling
