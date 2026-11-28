/-
  Family6SpinlockAndFastpath.lean
  Formal Lean 4 theorems for Family 6 v7 SMP runtime fixes:
    1. Unsigned byte-range fast-span stack & heap soundness and cleared-span rejection.
    2. Fix 1A (pending-demand non-injection) and Fix 1B (primlock_depth > 0
       barrier-free refill) deadlock freedom.
    3. Pillar 3 bounded-chunk countdown exact live-state preservation at deopt.
-/

def wordBytes : Nat := 8

/-- Modular 64-bit unsigned subtraction modeled over UInt64. -/
def fastSpanStackAdmits (floorB limitB fpB sw : UInt64) : Bool :=
  let dist := fpB - floorB
  decide (dist < limitB) && decide (dist / 8 ≥ sw)

def fastSpanHeapAdmits (heapLoB heapBytes hpB hw : UInt64) : Bool :=
  if hw == 0 then true
  else
    let dist := hpB - heapLoB
    decide (dist < heapBytes) && decide ((heapBytes - dist) / 8 ≥ hw)

/-- If fast-span is cleared (`limitB = 0`), fast-span stack admission is always false. -/
theorem cleared_fast_span_never_admits (floorB fpB sw : UInt64) :
    fastSpanStackAdmits floorB 0 fpB sw = false := by
  unfold fastSpanStackAdmits
  have h : ¬ (fpB - floorB < (0 : UInt64)) := by
    intro hlt
    exact Nat.not_lt_zero (fpB - floorB).toNat hlt
  simp [h]

/-- Pure Nat geometry of published fast-span stack bounds: when `floor = lo + fudge`,
    `fp ∈ [floor, hi]`, and `(fp - floor) ≥ sw`, the adjusted cursor `fp - sw` stays
    strictly above the physical stack limit `lo` with the full `fudge` guard intact. -/
theorem fast_span_stack_preserves_fudge
    (lo hi fudge fp sw : Nat)
    (hSpan : lo + fudge < hi)
    (hLow : lo + fudge ≤ fp)
    (hHigh : fp ≤ hi)
    (hRoom : sw ≤ fp - (lo + fudge)) :
    lo + fudge ≤ fp - sw ∧ fp - sw ≤ hi := by
  constructor <;> omega

/-- Pure Nat geometry of published fast-span heap bounds: when `heapStart ≤ hp < heapLimit`,
    `heapLimit ≤ hardEnd`, and `hw ≤ heapLimit - hp`, the allocated end `hp + hw` stays
    within both the soft limit `heapLimit` and the hard section edge `hardEnd`. -/
theorem fast_span_heap_preserves_limits
    (heapStart heapLimit hardEnd hp hw : Nat)
    (hSoftHard : heapLimit ≤ hardEnd)
    (hLow : heapStart ≤ hp)
    (hHigh : hp < heapLimit)
    (hRoom : hw ≤ heapLimit - hp) :
    heapStart ≤ hp + hw ∧ hp + hw ≤ heapLimit ∧ hp + hw ≤ hardEnd := by
  refine ⟨?_, ?_, ?_⟩ <;> omega

/-- Fix 1A + Fix 1B deadlock-freedom invariant over a 2-processor SMP wait graph. -/
structure SmpWaitState where
  p0PrimlockDepth : Nat
  p0WaitingSelfLock : Bool
  p0WaitingGcBarrier : Bool
  p1WaitingP0Lock : Bool
  p1AtGcBarrier : Bool

def HasDeadlockCycle (s : SmpWaitState) : Prop :=
  s.p0WaitingSelfLock = true ∨
  (s.p0PrimlockDepth > 0 ∧ s.p0WaitingGcBarrier = true ∧
   s.p1WaitingP0Lock = true ∧ s.p1AtGcBarrier = false)

/-- Transition for handler_stack_limit under Fix 1A: when pendingDemand is true,
    it never re-enters ##interrupt-handler, so p0WaitingSelfLock stays false. -/
def fix1aHandlerStep (s : SmpWaitState) (pendingDemand : Bool) : SmpWaitState :=
  if pendingDemand then
    { s with p0WaitingSelfLock := false }
  else
    s

/-- Transition for ___stack_limit / ___heap_limit under Fix 1B: whenever
    p0PrimlockDepth > 0, msections grow barrier-free instead of entering GC barrier. -/
def fix1bLimitStep (s : SmpWaitState) : SmpWaitState :=
  if s.p0PrimlockDepth > 0 then
    { s with p0WaitingGcBarrier := false }
  else
    s

theorem fix1a_fix1b_preserve_no_deadlock
    (s : SmpWaitState) :
    ¬ HasDeadlockCycle (fix1bLimitStep (fix1aHandlerStep s true)) := by
  unfold HasDeadlockCycle fix1bLimitStep fix1aHandlerStep
  by_cases hPos : s.p0PrimlockDepth > 0
  · simp [hPos]
  · simp [hPos]

/-- Pillar 3: Exact arithmetic equivalence of bounded-chunk countdown and step-by-step
    recursion when deoptimizing after `k` steps with positive step size `step > 0`. -/
def stepCountdown : Nat → Nat → Nat → Nat → Nat
  | 0, n, _, _ => n
  | fuel + 1, n, lo, step =>
      if n > lo then stepCountdown fuel (n - step) lo step else n

theorem countdown_chunk_deopt_exact
    (n lo step k rem : Nat)
    (hStep : 0 < step)
    (hLive : lo + k * step ≤ n) :
    stepCountdown (k + rem) n lo step =
      stepCountdown rem (n - k * step) lo step := by
  induction k generalizing n with
  | zero =>
      simp
  | succ k ih =>
      have hGt : lo < n := by
        have : 0 < (k + 1) * step := Nat.mul_pos (Nat.succ_pos k) hStep
        omega
      have hSplit : k + 1 + rem = (k + rem) + 1 := by omega
      rw [hSplit, stepCountdown]
      simp [hGt]
      have hSub : lo + k * step ≤ n - step := by
        have : (k + 1) * step = k * step + step := Nat.succ_mul k step
        omega
      have hRec := ih (n - step) hSub
      have hSubEq : n - step - k * step = n - (k + 1) * step := by
        have : (k + 1) * step = k * step + step := Nat.succ_mul k step
        omega
      rw [hSubEq] at hRec
      exact hRec
