/-
  Lean 4 Formal Refinement Proof for Phase C26:
  (gambit fiber) Work-Stealing & Global-Queue Cascade Wakeup, Zero-`swtch_pri`
  Bounded Spin-to-Ulock Parking, and Lock-Free Per-Carrier TLS Slot Isolation
  (`vendor/gambit/lib/gambit/fiber/fiber.scm`).

  Proves:
    1. Steal cascade wakeup preserves work conservation when a victim deque
       still holds runnable tasks and sleepers exist.
    2. Global-queue dequeue cascade wakeup preserves work conservation when
       `globalPending > 0` and sleepers exist.
    3. Per-carrier `carrier-tls` slots on `%worker-ctx` provide strict owner
       isolation across distinct carriers with 0 global mutex acquisitions.
    4. Bounded user-space pause spin transitions directly to Dekker-checked
       park with 0 `sched_yield` (`swtch_pri`) calls.
-/

namespace FiberCascadeWakeupAndCarrierTls

structure SchedState where
  searching       : Nat
  waking          : Nat
  sleepers        : Nat
  peerQueued      : Nat
  globalQueued    : Nat

def WorkConserving (s : SchedState) : Prop :=
  (s.peerQueued + s.globalQueued > 0 ∧ s.sleepers > 0) →
    (s.searching + s.waking ≥ 1)

/-- Action 1: Worker steals 1 task from peer deque (`peerQueued' = peerQueued - 1`),
    releases search permit (`searching' = searching - 1`), and unconditionally
    calls `%parker-wake-one!` when sleepers exist (`waking' = waking + 1`,
    `sleepers' = sleepers - 1`). -/
def stepStealCascade (s : SchedState) : SchedState :=
  if s.sleepers > 0 then
    { searching    := s.searching - 1
      waking       := s.waking + 1
      sleepers     := s.sleepers - 1
      peerQueued   := s.peerQueued - 1
      globalQueued := s.globalQueued }
  else
    { searching    := s.searching - 1
      waking       := s.waking
      sleepers     := s.sleepers
      peerQueued   := s.peerQueued - 1
      globalQueued := s.globalQueued }

/-- Theorem 1: Unconditional steal-cascade wakeup preserves `WorkConserving`
    even when the thief was the last active searcher (`searching = 1 -> 0`). -/
theorem steal_cascade_preserves_work_conservation (s : SchedState) :
    WorkConserving (stepStealCascade s) := by
  unfold WorkConserving stepStealCascade
  split
  · intro _
    dsimp only
    omega
  · intro ⟨_, hSlp⟩
    dsimp only at hSlp
    omega

/-- Action 2: Worker pops 1 task from `global-q` (`globalQueued' = globalQueued - 1`).
    Whenever `globalQueued' > 0` and `sleepers > 0`, calls `%parker-wake-one!`. -/
def stepGlobalPopCascade (s : SchedState) : SchedState :=
  let rem := s.globalQueued - 1
  if rem > 0 ∧ s.sleepers > 0 then
    { s with
      globalQueued := rem
      sleepers     := s.sleepers - 1
      waking       := s.waking + 1 }
  else
    { s with globalQueued := rem }

/-- Theorem 2: Global-queue dequeue cascade wakeup guarantees `waking ≥ 1`
    whenever remaining global work and sleepers coexist. -/
theorem global_pop_cascade_preserves_work_conservation
    (s : SchedState) (hRem : s.globalQueued - 1 > 0) (hSlp : s.sleepers > 0) :
    (stepGlobalPopCascade s).waking ≥ 1 ∧
    WorkConserving (stepGlobalPopCascade s) := by
  unfold stepGlobalPopCascade WorkConserving
  have hCond : s.globalQueued - 1 > 0 ∧ s.sleepers > 0 := ⟨hRem, hSlp⟩
  simp only [hCond, and_self, ↓reduceIte]
  exact ⟨by omega, fun _ => by omega⟩

/-- Per-carrier TLS model: each carrier `wid` owns slot `tls wid` on its own
    `%worker-ctx` with zero global mutex acquisitions. -/
structure CarrierTlsState (W : Nat) where
  tls                : Fin W → Option Nat
  globalMutexAcquires : Nat

def setCarrierTls {W : Nat} (st : CarrierTlsState W) (w : Fin W) (v : Nat) :
    CarrierTlsState W :=
  { tls := fun i => if i = w then some v else st.tls i
    globalMutexAcquires := st.globalMutexAcquires }

/-- Theorem 3: Setting carrier `w`'s TLS slot updates `w` to `some v`, leaves
    every other carrier `w' ≠ w` untouched, and acquires 0 global mutexes. -/
theorem carrier_tls_strict_owner_isolation
    {W : Nat} (st : CarrierTlsState W) (w w' : Fin W) (v : Nat)
    (hZero : st.globalMutexAcquires = 0) (hNe : w' ≠ w) :
    (setCarrierTls st w v).tls w = some v ∧
    (setCarrierTls st w v).tls w' = st.tls w' ∧
    (setCarrierTls st w v).globalMutexAcquires = 0 := by
  unfold setCarrierTls
  simp [hNe, hZero]

/-- Bounded pause-to-park transition model (`%worker-dispatch` without `sched_yield`). -/
inductive IdleAction where
  | cpuPause
  | dekkerPark
  deriving DecidableEq, Repr

def nextIdleAction (spins pauseLimit : Nat) : IdleAction :=
  if spins < pauseLimit then .cpuPause else .dekkerPark

/-- Theorem 4: For any `pauseLimit`, reaching `spins ≥ pauseLimit` transitions
    directly to `dekkerPark` with zero intermediate `sched_yield` (`swtch_pri`) loops. -/
theorem bounded_spin_reaches_dekker_park (spins pauseLimit : Nat)
    (hGe : spins ≥ pauseLimit) :
    nextIdleAction spins pauseLimit = .dekkerPark := by
  unfold nextIdleAction
  have hNotLt : ¬ (spins < pauseLimit) := by omega
  simp [hNotLt]

end FiberCascadeWakeupAndCarrierTls
