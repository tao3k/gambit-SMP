/-
  SmpMigrationAndWillsRefinement.lean

  Standalone 0-sorry Lean 4 inductive proof verifying our two Gambit SMP fixes:
    1. Bug #1B + #1C (`lib/_thread.scm`: `##thread-migrate-to!` temporary target
       pinning + `lib/_kernel.scm`: `handler_return_to_c` / `##c-return-on-other-processor`
       `R1` return-value preservation):
         - Prevents peer work-stealing from pulling a migrating thread back off
           its target processor's `btq` (eliminating the `p4` 4.0 GiB livelock).
         - Preserves the exact `c-define` Scheme return value `R1` (`___SFUN_RESULT`)
           across cross-core migration back to the C stack owner processor.
    2. Bug #2A (`lib/_kernel.scm`: `##gc-finalize!` per-thread non-reentrancy guard):
         - Prevents a nested `___INTR_GC` from re-entering `##will-execute!` on
           a thread already holding a non-reentrant SRFI-18 mutex (eliminating
           deterministic will-executor self-deadlock under concurrent GC).
-/

namespace GambitSmpMigrationAndWills

-- ============================================================================
-- Part 1: Pinned Cross-Core C-Return Migration & R1 Preservation
-- ============================================================================

inductive ThreadLoc where
  | running
  | queued
  deriving DecidableEq, Repr

structure MigrationState where
  cFrameOwner   : Nat
  curProc       : Nat
  loc           : ThreadLoc
  pinnedProc    : Option Nat
  r1Val         : Nat
  savedRetVal   : Option Nat
  expectedRet   : Nat
  cReturned     : Bool
  observedCRet  : Nat
  selfSteals    : Nat
  deriving DecidableEq, Repr

def MigrationSafe (s : MigrationState) : Prop :=
  s.selfSteals = 0 ∧
  (s.loc = .queued → s.pinnedProc = some s.cFrameOwner ∧ s.curProc = s.cFrameOwner) ∧
  (s.loc = .queued → s.savedRetVal = some s.expectedRet) ∧
  (s.loc = .running ∧ s.cReturned = false → s.r1Val = s.expectedRet) ∧
  (s.cReturned = true → s.observedCRet = s.expectedRet)

def initMigration (owner cur retVal : Nat) : MigrationState :=
  { cFrameOwner  := owner
    curProc      := cur
    loc          := .running
    pinnedProc   := none
    r1Val        := retVal
    savedRetVal  := none
    expectedRet  := retVal
    cReturned    := false
    observedCRet := retVal
    selfSteals   := 0 }

theorem initMigration_safe (owner cur retVal : Nat) :
    MigrationSafe (initMigration owner cur retVal) := by
  refine ⟨rfl, ?_, ?_, ?_, ?_⟩
  · intro h; cases h
  · intro h; cases h
  · intro _; rfl
  · intro h; cases h

inductive MigrationStep where
  /-- Fixed `handler_return_to_c` + `##thread-migrate-to!`: preserve R1 and pin to owner! -/
  | beginPinnedMigrate
  /-- Peer work-stealer (`lib/_thread.scm:3013`): only steals if `pinnedProc = none`. -/
  | peerWorkSteal (stealer : Nat)
  /-- Owner processor dequeues its own queue, unpins, restores R1, returns to C. -/
  | ownerDequeueAndReturn

def evalMigration (s : MigrationState) : MigrationStep → MigrationState
  | .beginPinnedMigrate =>
      if s.cReturned = false ∧ s.loc = .running ∧ s.curProc ≠ s.cFrameOwner then
        { s with
          savedRetVal := some s.r1Val
          pinnedProc  := some s.cFrameOwner
          curProc     := s.cFrameOwner
          loc         := .queued }
      else s
  | .peerWorkSteal stealer =>
      if s.cReturned = false ∧ s.loc = .queued ∧ stealer ≠ s.curProc ∧ s.pinnedProc = none then
        { s with
          curProc    := stealer
          loc        := .running
          selfSteals := s.selfSteals + 1 }
      else s
  | .ownerDequeueAndReturn =>
      if s.cReturned = false ∧ s.loc = .queued ∧ s.curProc = s.cFrameOwner then
        let ret := s.savedRetVal.getD s.r1Val
        { s with
          loc          := .running
          pinnedProc   := none
          r1Val        := ret
          savedRetVal  := none
          cReturned    := true
          observedCRet := ret }
      else s

theorem evalMigration_expectedRet (s : MigrationState) (act : MigrationStep) :
    (evalMigration s act).expectedRet = s.expectedRet := by
  cases act <;> simp only [evalMigration] <;> split <;> rfl

theorem evalMigration_preserves (s : MigrationState) (act : MigrationStep)
    (h : MigrationSafe s) : MigrationSafe (evalMigration s act) := by
  rcases h with ⟨hSteals, hQueuePin, hQueueRet, hRunR1, hCRet⟩
  cases act with
  | beginPinnedMigrate =>
    simp only [evalMigration]
    split
    · rename_i hc
      have hR1 : s.r1Val = s.expectedRet := hRunR1 ⟨hc.2.1, hc.1⟩
      refine ⟨hSteals, ?_, ?_, ?_, ?_⟩
      · intro _; exact ⟨rfl, rfl⟩
      · intro _; exact congrArg some hR1
      · intro h; cases h.1
      · intro h; rw [hc.1] at h; cases h
    · exact ⟨hSteals, hQueuePin, hQueueRet, hRunR1, hCRet⟩
  | peerWorkSteal stealer =>
    simp only [evalMigration]
    split
    · rename_i hc
      -- Impossible! Queued thread is always pinned to `some s.cFrameOwner`, never `none`!
      have hPin := (hQueuePin hc.2.1).1
      rw [hc.2.2.2] at hPin
      cases hPin
    · exact ⟨hSteals, hQueuePin, hQueueRet, hRunR1, hCRet⟩
  | ownerDequeueAndReturn =>
    simp only [evalMigration]
    split
    · rename_i hc
      have hSaved := hQueueRet hc.2.1
      refine ⟨hSteals, ?_, ?_, ?_, ?_⟩
      · intro h; cases h
      · intro h; cases h
      · intro h; cases h.2
      · intro _
        simp only [hSaved, Option.getD_some]
    · exact ⟨hSteals, hQueuePin, hQueueRet, hRunR1, hCRet⟩

def evalMigrationTrace (s : MigrationState) : List MigrationStep → MigrationState
  | [] => s
  | a :: rest => evalMigrationTrace (evalMigration s a) rest

theorem evalMigrationTrace_expectedRet (s : MigrationState) (trace : List MigrationStep) :
    (evalMigrationTrace s trace).expectedRet = s.expectedRet := by
  induction trace generalizing s with
  | nil => rfl
  | cons a rest ih =>
    simp only [evalMigrationTrace]
    rw [ih, evalMigration_expectedRet]

theorem pinned_migration_always_safe (owner cur retVal : Nat) (trace : List MigrationStep) :
    let sf := evalMigrationTrace (initMigration owner cur retVal) trace
    sf.selfSteals = 0 ∧ (sf.cReturned = true → sf.observedCRet = retVal) := by
  suffices h : ∀ s, MigrationSafe s → MigrationSafe (evalMigrationTrace s trace) by
    have hEnd := h (initMigration owner cur retVal) (initMigration_safe owner cur retVal)
    have hExp := evalMigrationTrace_expectedRet (initMigration owner cur retVal) trace
    refine ⟨hEnd.1, fun hRet => ?_⟩
    rw [hEnd.2.2.2.2 hRet, hExp]
    rfl
  induction trace with
  | nil => intro s hs; exact hs
  | cons a rest ih =>
    intro s hs
    exact ih (evalMigration s a) (evalMigration_preserves s a hs)

-- ============================================================================
-- Part 2: Non-Reentrant Per-Thread `##gc-finalize!` (Zero Mutex Self-Deadlock)
-- ============================================================================

structure WillState where
  inFinalizeThreads : Bool   -- whether `self` is in `##gc-finalizing-threads`
  willMtxHeld       : Bool   -- whether `self` currently holds user SRFI-18 mutex
  selfDeadlocked    : Bool   -- becomes true iff `self` tries to re-lock while holding
  willsDone         : Nat
  deriving DecidableEq, Repr

def WillSafe (w : WillState) : Prop :=
  (w.willMtxHeld = true → w.inFinalizeThreads = true) ∧
  w.selfDeadlocked = false

def initWillState : WillState :=
  { inFinalizeThreads := false
    willMtxHeld       := false
    selfDeadlocked    := false
    willsDone         := 0 }

inductive WillStep where
  /-- Outer `___INTR_GC` enters `##gc-finalize!`: guarded by `inFinalizeThreads = false`. -/
  | gcInterruptEnterWill
  /-- Will action finishes, unlocks `will-mtx`, and leaves `##gc-finalizing-threads`. -/
  | finishWillAndUnlock

def evalWill (w : WillState) : WillStep → WillState
  | .gcInterruptEnterWill =>
      if w.inFinalizeThreads = false then
        if w.willMtxHeld = true then
          { w with selfDeadlocked := true }
        else
          { w with inFinalizeThreads := true, willMtxHeld := true }
      else
        -- Re-entrant ___INTR_GC skipped cleanly!
        w
  | .finishWillAndUnlock =>
      if w.inFinalizeThreads = true then
        { w with
          inFinalizeThreads := false
          willMtxHeld       := false
          willsDone         := w.willsDone + 1 }
      else w

theorem evalWill_preserves (w : WillState) (act : WillStep) (h : WillSafe w) :
    WillSafe (evalWill w act) := by
  rcases h with ⟨hHold, hDead⟩
  cases act with
  | gcInterruptEnterWill =>
    simp only [evalWill]
    by_cases hIn : w.inFinalizeThreads = false
    · simp only [hIn, ↓reduceIte]
      by_cases hMtx : w.willMtxHeld = true
      · have hContr := hHold hMtx
        rw [hIn] at hContr
        cases hContr
      · simp only [hMtx]
        exact ⟨fun _ => rfl, hDead⟩
    · simp only [hIn]
      exact ⟨hHold, hDead⟩
  | finishWillAndUnlock =>
    simp only [evalWill]
    by_cases hIn : w.inFinalizeThreads = true
    · simp only [hIn, ↓reduceIte]
      refine ⟨?_, hDead⟩
      intro hc; cases hc
    · simp only [hIn]
      exact ⟨hHold, hDead⟩

def evalWillTrace (w : WillState) : List WillStep → WillState
  | [] => w
  | a :: rest => evalWillTrace (evalWill w a) rest

theorem initWillState_safe : WillSafe initWillState := by
  refine ⟨?_, rfl⟩
  intro hc; cases hc

theorem nonreentrant_gc_finalize_never_self_deadlocks (trace : List WillStep) :
    (evalWillTrace initWillState trace).selfDeadlocked = false := by
  suffices h : ∀ w, WillSafe w → WillSafe (evalWillTrace w trace) by
    exact (h initWillState initWillState_safe).2
  induction trace with
  | nil => intro w hw; exact hw
  | cons a rest ih =>
    intro w hw
    exact ih (evalWill w a) (evalWill_preserves w a hw)

end GambitSmpMigrationAndWills
